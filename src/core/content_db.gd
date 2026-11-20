class_name ContentDB
extends RefCounted

## Loads and validates authored JSON content for one campaign at a time.
##
## Shared rules content (items, spells, characters, monsters) lives in
## `content/shared` and is loaded for every campaign. Story content comes from
## the campaign package named by the manifest's `content_root`. Nothing in a
## campaign package may redefine shared rules content; a stray local rules
## table is a validation error rather than a silent override.
##
## Validation errors are collected rather than thrown so the game can report
## them precisely.

const CONTENT_ROOT := "res://content"
const SHARED_ROOT := "res://content/shared"
const CAMPAIGNS_ROOT := "res://content/campaigns"
const CAMPAIGN_FORMAT_VERSION := 1
## Format version of the optional `journal.json` notes file. A journal written by
## a newer format is refused rather than half-read.
const JOURNAL_FORMAT_VERSION := 1
const SUPPORTED_CAPABILITIES := [
	"exploration",
	"dialogue",
	"combat",
	"quests",
	"saves",
	"skills",
	"feats",
	"travel",
	"narration",
]

var items: Dictionary = {}
var spells: Dictionary = {}
var characters: Dictionary = {}
var monsters: Dictionary = {}
var quests: Dictionary = {}
var encounters: Dictionary = {}
var dialogues: Dictionary = {}
var dungeon_data: Dictionary = {}
var areas: Dictionary = {}
var area_manifest: Dictionary = {}
var narration: Dictionary = {}
## Optional authored Journal notes: facts tied to flags, open questions with
## reveal/resolve conditions, and bookkeeping flags that must never surface.
## Empty means the campaign has no `journal.json`; the Journal then shows only
## the quest log.
var journal: Dictionary = {}
var campaign: Dictionary = {}
var campaign_id := ""
var content_version := 1
## Provenance of campaign-local instance ids, for diagnostics and tests.
var local_instances: Dictionary = {"item": {}, "monster": {}, "character": {}}

var errors: Array[String] = []
var warnings: Array[String] = []
## Structured form of the same load problems. Codes, source file and parser line
## are recorded where the reader knows them; semantic errors stay descriptor-only.
var diagnostics: Array[Dictionary] = []


## Loads the registry's default campaign. Retained for tools and tests that need
## a content database without choosing a campaign.
func load_all() -> void:
	var campaign_id_default := _registry_default()
	if campaign_id_default == "":
		errors.clear()
		errors.append("Campaign registry is missing, invalid or empty.")
		return
	var manifest := _read_campaign_manifest(campaign_id_default)
	if manifest.is_empty():
		errors.clear()
		errors.append("Default campaign '%s' could not be loaded." % campaign_id_default)
		return
	load_campaign(manifest)


func load_campaign(manifest: Dictionary) -> void:
	campaign = manifest.duplicate(true)
	campaign_id = String(campaign.get("id", ""))
	content_version = int(campaign.get("version", 1))
	errors.clear()
	warnings.clear()
	diagnostics.clear()
	items = {}
	spells = {}
	characters = {}
	monsters = {}
	quests = {}
	encounters = {}
	dialogues = {}
	dungeon_data = {}
	areas = {}
	area_manifest = {}
	narration = {}
	local_instances = {"item": {}, "monster": {}, "character": {}}
	_load_rules(SHARED_ROOT)
	_load_story(String(campaign.get("content_root", CAMPAIGNS_ROOT.path_join(campaign_id))))
	_validate_campaign()
	validate()


func _registry_default() -> String:
	var registry_path := CAMPAIGNS_ROOT.path_join("_registry.json")
	if not FileAccess.file_exists(registry_path):
		return ""
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
	if not parsed is Dictionary:
		return ""
	var registry: Dictionary = parsed
	var listed: Variant = registry.get("campaigns", [])
	var default_id := String(registry.get("default", ""))
	if default_id != "":
		return default_id
	return String(Array(listed)[0]) if listed is Array and not Array(listed).is_empty() else ""


func _read_campaign_manifest(campaign_id_value: String) -> Dictionary:
	var path := CAMPAIGNS_ROOT.path_join(campaign_id_value).path_join("campaign.json")
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	return Dictionary(parsed).duplicate(true)


## Shared rules tables. These identifiers are global to the platform.
func _load_rules(root: String) -> void:
	items = _load_index(root.path_join("items.json"), "id")
	spells = _load_index(root.path_join("spells.json"), "id")
	characters = _load_index(root.path_join("characters.json"), "id")
	monsters = _load_index(root.path_join("monsters.json"), "id")


## Campaign-owned story tables. These identifiers are local to the campaign.
##
## Campaigns may also define *instances* of supported mechanics: named items,
## monster variants and NPC/character stat blocks. They use the shared schemas
## and are merged into this campaign's tables, but they may never reuse a
## shared id. Spells are mechanics, not instances, and stay shared-only.
func _load_story(root: String) -> void:
	if FileAccess.file_exists(root.path_join("spells.json")):
		errors.append(
			"Campaign '%s' defines spells.json; spell definitions are shared mechanics. Add shared content in content/shared instead."
			% campaign_id
		)
	items = _merge_local_instances(items, root.path_join("items.json"), "item")
	monsters = _merge_local_instances(monsters, root.path_join("monsters.json"), "monster")
	characters = _merge_local_instances(characters, root.path_join("characters.json"), "character")
	quests = _load_index(root.path_join("quests.json"), "id")
	encounters = _load_index(root.path_join("encounters.json"), "id")
	var dungeon_variant = _read_json(root.path_join("dungeon.json"), false)
	dungeon_data = dungeon_variant if dungeon_variant is Dictionary else {}
	if not dungeon_data.is_empty():
		var dungeon_id := String(dungeon_data.get("id", campaign_id))
		if areas.has(dungeon_id):
			errors.append("Duplicate area id '%s'." % dungeon_id)
		else:
			areas[dungeon_id] = dungeon_data
	_load_area_dir(root.path_join("areas"))
	_load_dialogue_dir(root.path_join("dialogue"))
	var narration_variant = _read_json(root.path_join("narration.json"), false)
	narration = narration_variant if narration_variant is Dictionary else {}
	# Notes are optional so campaigns written before this file existed still load.
	var journal_variant = _read_json(root.path_join("journal.json"), false)
	if journal_variant == null:
		journal = {}
	elif journal_variant is Dictionary:
		journal = journal_variant
	else:
		journal = {}
		errors.append("journal.json must be a JSON object.")


## Campaign-local instance table merged onto the shared table. A local entry may
## use any supported field, but it may not replace a shared id: shared mechanics
## stay authoritative and references never change meaning per campaign.
func _merge_local_instances(shared: Dictionary, path: String, label: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return shared
	var local := _load_index(path, "id")
	for key in local.keys():
		var instance_id := String(key)
		if shared.has(instance_id):
			errors.append(
				"Campaign '%s' may not redefine shared %s '%s'; choose a campaign-local id."
				% [campaign_id, label, instance_id]
			)
			continue
		local_instances[label][instance_id] = true
		shared[instance_id] = local[key]
	return shared


func _load_area_dir(area_dir: String) -> void:
	if not DirAccess.dir_exists_absolute(area_dir):
		return
	var manifest_path := area_dir.path_join("_manifest.json")
	if FileAccess.file_exists(manifest_path):
		var manifest_read := _parse_json_file(manifest_path)
		if not bool(manifest_read.get("ok", false)):
			if bool(manifest_read.get("missing", false)):
				_diag("content.area_manifest.missing", "Area manifest is missing: %s." % _relative_source(manifest_path), manifest_path)
			else:
				_diag(
					"content.area_manifest.syntax",
					"Area manifest %s is not valid JSON: %s (line %d)." % [
						_relative_source(manifest_path),
						String(manifest_read.get("message", "")),
						int(manifest_read.get("line", 0)),
					],
					manifest_path,
					"",
					"",
					int(manifest_read.get("line", 0))
				)
			return
		if not manifest_read.get("data") is Dictionary:
			_diag("content.area_manifest.shape", "Area manifest %s is valid JSON but not an object." % _relative_source(manifest_path), manifest_path)
			return
		area_manifest = Dictionary(manifest_read["data"]).duplicate(true)
		var listed_areas: Variant = area_manifest.get("areas", [])
		if not listed_areas is Array:
			_diag("content.area_manifest.shape", "Area manifest %s has an 'areas' field that is not an array." % _relative_source(manifest_path), manifest_path, "area_manifest", "", 0)
			return
		for raw_area_id in Array(listed_areas):
			_load_area_file(area_dir, String(raw_area_id))
		return
	var area_files := DirAccess.get_files_at(area_dir)
	area_files.sort()
	for file_name in area_files:
		var file_string := String(file_name)
		if file_string.begins_with("_") or not file_string.ends_with(".json"):
			continue
		_load_area_file(area_dir, file_string.get_basename())


func _load_area_file(area_dir: String, expected_id: String) -> void:
	var path := area_dir.path_join(expected_id + ".json")
	var read := _parse_json_file(path)
	if bool(read.get("missing", false)):
		_diag(
			"content.area.missing",
			"Area file %s is missing (area '%s' is referenced but has no file)." % [_relative_source(path), expected_id],
			path,
			"area",
			expected_id
		)
		return
	if not bool(read.get("ok", false)):
		_diag(
			"content.area.syntax",
			"Area file %s is not valid JSON: %s (line %d)." % [
				_relative_source(path),
				String(read.get("message", "")),
				int(read.get("line", 0)),
			],
			path,
			"area",
			expected_id,
			int(read.get("line", 0))
		)
		return
	if not read.get("data") is Dictionary:
		_diag(
			"content.area.shape",
			"Area file %s is valid JSON but not an object; the loader cannot read an area from it." % _relative_source(path),
			path,
			"area",
			expected_id
		)
		return
	var area_data: Dictionary = Dictionary(read["data"]).duplicate(true)
	var area_id := String(area_data.get("id", ""))
	if area_id == "":
		_diag("content.area.shape", "Area file %s has no id." % _relative_source(path), path, "area", expected_id)
	elif area_id != expected_id:
		_diag(
			"content.area.id_mismatch",
			"Area file %s declares id '%s', which does not match its filename." % [_relative_source(path), area_id],
			path,
			"area",
			area_id
		)
	elif areas.has(area_id):
		_diag("content.area.duplicate", "Duplicate area id '%s'." % area_id, path, "area", area_id)
	else:
		areas[area_id] = area_data


func _load_dialogue_dir(dialogue_dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dialogue_dir):
		return
	var files := DirAccess.get_files_at(dialogue_dir)
	files.sort()
	for file_name in files:
		if not String(file_name).ends_with(".json"):
			continue
		var path := dialogue_dir.path_join(String(file_name))
		var read := _parse_json_file(path)
		if bool(read.get("missing", false)):
			continue
		if not bool(read.get("ok", false)):
			_diag(
				"content.dialogue.syntax",
				"Dialogue file %s is not valid JSON: %s (line %d)." % [
					_relative_source(path),
					String(read.get("message", "")),
					int(read.get("line", 0)),
				],
				path,
				"dialogue",
				String(file_name).get_basename(),
				int(read.get("line", 0))
			)
			continue
		if not read.get("data") is Dictionary:
			_diag(
				"content.dialogue.shape",
				"Dialogue file %s is valid JSON but not an object; a dialogue needs a top-level object." % _relative_source(path),
				path,
				"dialogue",
				String(file_name).get_basename()
			)
			continue
		var parsed: Dictionary = Dictionary(read["data"])
		var dialogue_id := String(parsed.get("id", String(file_name).get_basename()))
		if dialogues.has(dialogue_id):
			_diag("content.dialogue.duplicate", "Duplicate dialogue id '%s'." % dialogue_id, path, "dialogue", dialogue_id)
			continue
		dialogues[dialogue_id] = parsed


func _load_index(path: String, id_key: String) -> Dictionary:
	var result := {}
	var parsed = _read_json(path)
	if not parsed is Dictionary:
		if parsed != null:
			_diag(
				"content.index.shape",
				"Content file %s is valid JSON but not an object; expected a table keyed by %s id." % [_relative_source(path), id_key],
				path
			)
		return result
	for key in parsed.keys():
		var entry: Dictionary = Dictionary(parsed[key]).duplicate(true)
		if not entry.has(id_key):
			entry[id_key] = String(key)
		var entry_id := String(entry[id_key])
		if result.has(entry_id):
			errors.append("Duplicate %s id '%s' in %s." % [id_key, entry_id, path])
			continue
		result[entry_id] = entry
	return result


## Reads one JSON file and records missing-file or syntax problems separately.
## Shape is the caller's concern: a file can parse and still not be the object the
## loader needs, and that must not be reported as a syntax error with a line.
func _parse_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"missing": true, "ok": false, "data": null, "message": "", "line": 0}
	var text := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK:
		return {
			"missing": false,
			"ok": false,
			"data": null,
			"message": parser.get_error_message(),
			"line": (parser.get_error_line() + 1),
		}
	return {"missing": false, "ok": true, "data": parser.data, "message": "", "line": 0}


func _read_json(path: String, required := true) -> Variant:
	var read := _parse_json_file(path)
	if bool(read.get("missing", false)):
		if required:
			_diag("content.file.missing", "Missing content file: %s." % _relative_source(path), path)
		return null
	if not bool(read.get("ok", false)):
		_diag(
			"content.json.syntax",
			"Invalid JSON in %s: %s (line %d)." % [
				_relative_source(path),
				String(read.get("message", "")),
				int(read.get("line", 0)),
			],
			path,
			"",
			"",
			int(read.get("line", 0))
		)
		return null
	return read["data"]


## Package-relative name for a diagnostic source. A user package root is a
## virtual user:// path; only the part inside the package is useful to an author.
func _relative_source(path: String) -> String:
	var root := String(campaign.get("content_root", CAMPAIGNS_ROOT.path_join(campaign_id))).trim_suffix("/")
	if path.begins_with(root + "/"):
		return path.substr(root.length() + 1)
	return path


## Records one load problem in both forms: the human message keeps the CLI text
## compatible, the structured entry carries the stable code, package identity,
## relative source, entity and parser line.
func _diag(code: String, message: String, source: String, entity_type := "", entity_id := "", line := 0) -> void:
	errors.append(message)
	diagnostics.append(ContentDiagnostics.make(code, ContentDiagnostics.ERROR, message, {
		"campaign": campaign_id,
		"source": _relative_source(source),
		"entity_type": entity_type,
		"entity_id": entity_id,
		"line": line,
		"section": "advanced",
		"advanced": true,
	}))


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_area(area_id: String) -> Dictionary:
	return areas.get(area_id, {})


func get_spell(spell_id: String) -> Dictionary:
	return spells.get(spell_id, {})


func get_character(character_id: String) -> Dictionary:
	return characters.get(character_id, {})


func get_monster(monster_id: String) -> Dictionary:
	return monsters.get(monster_id, {})


func get_encounter(encounter_id: String) -> Dictionary:
	return encounters.get(encounter_id, {})


func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})


func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})


func character_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in characters.keys():
		ids.append(String(key))
	ids.sort()
	return ids


## Named NPCs authored by a campaign are not party options unless they opt in
## with `"playable": true`; shared pregens default to playable.
func playable_character_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in characters.keys():
		if bool(Dictionary(characters[key]).get("playable", true)):
			ids.append(String(key))
	ids.sort()
	return ids


func is_local_instance(table: String, id: String) -> bool:
	var entries: Dictionary = local_instances.get(table, {})
	return entries.has(id)


# ------------------------------------------------------------------ campaign

## Checks the manifest against the content that was actually loaded. This runs
## on every load so a package can never start half-valid.
func _validate_campaign() -> void:
	if campaign.is_empty():
		return
	if int(campaign.get("format_version", 0)) != CAMPAIGN_FORMAT_VERSION:
		errors.append(
			"Campaign '%s' uses format version %s; this build supports %d."
			% [campaign_id, campaign.get("format_version", "?"), CAMPAIGN_FORMAT_VERSION]
		)
	if campaign_id == "":
		errors.append("Campaign manifest has no id.")
	else:
		var pattern := RegEx.new()
		pattern.compile("^[a-z][a-z0-9_]*$")
		if pattern.search(campaign_id) == null:
			errors.append(
				"Campaign id '%s' must be lowercase letters, digits and underscores, starting with a letter."
				% campaign_id
			)
	if int(campaign.get("version", 0)) < 1:
		errors.append("Campaign '%s' has no positive content version." % campaign_id)
	var entry: Dictionary = campaign.get("entry", {})
	var entry_area := String(entry.get("area", ""))
	if entry_area == "":
		errors.append("Campaign '%s' has no entry area." % campaign_id)
	elif not areas.has(entry_area):
		errors.append("Campaign '%s' entry area '%s' does not exist." % [campaign_id, entry_area])
	else:
		var entry_dungeon := Dungeon.new()
		entry_dungeon.setup(Dictionary(areas[entry_area]))
		for area_error in entry_dungeon.errors:
			errors.append("Campaign '%s' entry area '%s': %s" % [campaign_id, entry_area, area_error])
		var pos_data: Variant = entry.get("pos", [])
		if not pos_data is Array or Array(pos_data).size() != 2:
			errors.append("Campaign '%s' entry position is malformed." % campaign_id)
		else:
			var entry_pos := Vector2i(int(Array(pos_data)[0]), int(Array(pos_data)[1]))
			if not entry_dungeon.in_bounds(entry_pos) or not entry_dungeon.is_walkable(entry_pos):
				errors.append(
					"Campaign '%s' entry position %s is not walkable."
					% [campaign_id, str(entry_pos)]
				)
		var entry_facing := int(entry.get("facing", 0))
		if entry_facing < 0 or entry_facing > 3:
			errors.append("Campaign '%s' entry facing must be 0-3." % campaign_id)
	var start_quest := String(campaign.get("start_quest", ""))
	if start_quest == "":
		errors.append("Campaign '%s' has no start_quest." % campaign_id)
	elif not quests.has(start_quest):
		errors.append("Campaign '%s' start quest '%s' does not exist." % [campaign_id, start_quest])
	var completion_quest := String(campaign.get("completion_quest", ""))
	if completion_quest != "" and not quests.has(completion_quest):
		errors.append(
			"Campaign '%s' completion quest '%s' does not exist." % [campaign_id, completion_quest]
		)
	var party_cfg: Dictionary = campaign.get("party", {})
	var defaults: Variant = party_cfg.get("default", [])
	if not defaults is Array or Array(defaults).is_empty():
		errors.append("Campaign '%s' has no default party." % campaign_id)
	else:
		for raw_character in Array(defaults):
			if not characters.has(String(raw_character)):
				errors.append(
					"Campaign '%s' default party references missing character '%s'."
					% [campaign_id, raw_character]
				)
	var max_party := int(party_cfg.get("max", 4))
	var min_party := int(party_cfg.get("min", 1))
	if max_party < 1 or max_party > 4:
		errors.append("Campaign '%s' party max must be 1-4." % campaign_id)
	if min_party < 1 or min_party > max_party:
		errors.append("Campaign '%s' party min must be between 1 and party max." % campaign_id)
	var requires: Dictionary = campaign.get("requires", {})
	var capabilities: Variant = requires.get("capabilities", [])
	if not capabilities is Array:
		errors.append("Campaign '%s' requires.capabilities must be an array." % campaign_id)
	else:
		for raw_capability in Array(capabilities):
			var capability := String(raw_capability)
			if not SUPPORTED_CAPABILITIES.has(capability):
				errors.append(
					"Campaign '%s' requires unsupported platform capability '%s'."
					% [campaign_id, capability]
				)


# ------------------------------------------------------------------ validation

func validate() -> void:
	for item_id in items.keys():
		var item: Dictionary = items[item_id]
		if String(item.get("name", "")) == "":
			errors.append("Item '%s' has no name." % item_id)
		var kind := String(item.get("kind", ""))
		if not ["weapon", "armor", "shield", "consumable", "quest", "gear", "focus"].has(kind):
			errors.append("Item '%s' has unknown kind '%s'." % [item_id, kind])
		if kind == "weapon":
			if not ["simple", "martial", "exotic"].has(String(item.get("category", ""))):
				errors.append("Weapon '%s' has unknown proficiency category '%s'." % [item_id, item.get("category", "")])
			if not item.has("damage"):
				errors.append("Weapon '%s' has no damage expression." % item_id)
			if int(item.get("crit_range", 20)) < 2 or int(item.get("crit_range", 20)) > 20:
				errors.append("Weapon '%s' has invalid crit_range." % item_id)
		elif kind == "armor":
			if not ["light_armor", "medium_armor", "heavy_armor"].has(
				String(item.get("armor_category", ""))
			):
				errors.append("Armor '%s' has unknown armor_category '%s'." % [item_id, item.get("armor_category", "")])
		elif kind == "shield":
			if not ["shield", "tower_shield"].has(String(item.get("proficiency", ""))):
				errors.append("Shield '%s' has unknown proficiency '%s'." % [item_id, item.get("proficiency", "")])
	for spell_id in spells.keys():
		var spell: Dictionary = spells[spell_id]
		if String(spell.get("name", "")) == "":
			errors.append("Spell '%s' has no name." % spell_id)
		if not ["magic_missile", "scorching_ray", "cure_light_wounds", "bless", "mage_armor", "aid"].has(
			String(spell.get("resolve", ""))
		):
			errors.append("Spell '%s' uses unimplemented resolver '%s'." % [spell_id, spell.get("resolve", "")])
	for char_id in characters.keys():
		_validate_actor(characters[char_id], "character '%s'" % char_id, true)
	for monster_id in monsters.keys():
		_validate_actor(monsters[monster_id], "monster '%s'" % monster_id, false)
		var monster: Dictionary = monsters[monster_id]
		if Array(monster.get("attacks", [])).is_empty():
			errors.append("Monster '%s' has no attacks." % monster_id)
	for encounter_id in encounters.keys():
		var encounter: Dictionary = encounters[encounter_id]
		var rows := Array(encounter.get("rows", []))
		if rows.is_empty():
			errors.append("Encounter '%s' has no battle map rows." % encounter_id)
		var map := BattleMap.from_rows(rows)
		for monster_id in Array(encounter.get("monsters", [])):
			if not monsters.has(String(monster_id)):
				errors.append("Encounter '%s' references unknown monster '%s'." % [encounter_id, monster_id])
		for cell in Array(encounter.get("party_cells", [])):
			_validate_cell(map, cell, "encounter '%s' party cell" % encounter_id)
		for cell in Array(encounter.get("monster_cells", [])):
			_validate_cell(map, cell, "encounter '%s' monster cell" % encounter_id)
		if Array(encounter.get("party_cells", [])).size() < 4:
			errors.append("Encounter '%s' needs at least 4 party cells." % encounter_id)
	for quest_id in quests.keys():
		var quest: Dictionary = quests[quest_id]
		if String(quest.get("title", "")) == "":
			errors.append("Quest '%s' has no title." % quest_id)
		if Array(quest.get("objectives", [])).is_empty():
			errors.append("Quest '%s' has no objectives." % quest_id)
		for objective in Array(quest.get("objectives", [])):
			if String(objective.get("id", "")) == "":
				errors.append("Quest '%s' has an objective with no id." % quest_id)
	for area_id in areas.keys():
		var area_label := "area '%s'" % area_id
		var dungeon := Dungeon.new()
		dungeon.setup(Dictionary(areas[area_id]))
		for area_error in dungeon.errors:
			errors.append("%s: %s" % [area_label, area_error])
		for npc in dungeon.npcs.values():
			var dialogue_id := String(npc.get("dialogue", ""))
			if dialogue_id != "" and not dialogues.has(dialogue_id):
				errors.append("%s NPC '%s' references missing dialogue '%s'." % [area_label, npc.get("id", "?"), dialogue_id])
		for obj in dungeon.objects.values():
			_validate_effect_list(Array(obj.get("success_effects", [])), "%s object '%s'" % [area_label, obj.get("id", "?")])
			for interaction in Array(obj.get("interactions", [])):
				_validate_effect_list(
					Array(interaction.get("effects", [])), "%s interaction '%s'" % [area_label, interaction.get("id", "?")]
				)
				_validate_effect_list(
					Array(interaction.get("success_effects", [])),
					"%s interaction '%s'" % [area_label, interaction.get("id", "?")]
				)
		for trigger in dungeon.triggers:
			var enc := String(trigger.get("encounter", ""))
			if enc != "" and not encounters.has(enc):
				errors.append("%s trigger '%s' references missing encounter '%s'." % [area_label, trigger.get("id", "?"), enc])
			_validate_effect_list(Array(trigger.get("effects", [])), "%s trigger '%s'" % [area_label, trigger.get("id", "?")])
		var tracker_quest := String(areas[area_id].get("tracker_quest", ""))
		if tracker_quest != "" and not quests.has(tracker_quest):
			errors.append("%s features missing quest '%s'." % [area_label, tracker_quest])
		_validate_effect_list(Array(areas[area_id].get("entry_effects", [])), "%s entry" % area_label)
	for encounter_id in encounters.keys():
		_validate_effect_list(
			Array(encounters[encounter_id].get("victory_effects", [])), "encounter '%s'" % encounter_id
		)
	for dialogue_id in dialogues.keys():
		_validate_dialogue(dialogues[dialogue_id], dialogue_id)
	_validate_journal()


## Every flag this campaign's own content can set, as a set for reference checks.
## Dialogue choices, object interactions, triggers, entry effects, encounter
## victory effects and openable doors all count. Engine-generated flags
## (`trigger_<id>`, quest-objective counters) are deliberately not content and
## are not listed here.
func authored_flags() -> Dictionary:
	var flags: Dictionary = {}
	_collect_authored_flags(dialogues, flags)
	_collect_authored_flags(areas, flags)
	_collect_authored_flags(encounters, flags)
	return flags


func _collect_authored_flags(node: Variant, out: Dictionary) -> void:
	if node is Dictionary:
		var entry: Dictionary = node
		if String(entry.get("type", "")) == "set_flag":
			var named := String(entry.get("flag", ""))
			if named != "":
				out[named] = true
		var door_flag := String(entry.get("open_flag", ""))
		if door_flag != "":
			out[door_flag] = true
		for key in entry.keys():
			_collect_authored_flags(entry[key], out)
	elif node is Array:
		for item in Array(node):
			_collect_authored_flags(item, out)


## Journal notes are presentation, but a broken note is still a content error:
## a typo in a flag name would silently drop a fact the player earned.
func _validate_journal() -> void:
	if journal.is_empty():
		return
	var version: Variant = journal.get("format_version", null)
	if not (version is int or version is float):
		errors.append("journal.json has no numeric format_version.")
	elif int(version) != JOURNAL_FORMAT_VERSION:
		errors.append(
			"journal.json format_version %d is not supported (expected %d)."
			% [int(version), JOURNAL_FORMAT_VERSION]
		)
	var authored := authored_flags()
	var internal := {}
	for raw in _journal_entries("internal"):
		if not raw is String or String(raw).strip_edges() == "":
			errors.append("journal.json internal entries must be non-empty strings.")
			continue
		var internal_flag := String(raw)
		if internal.has(internal_flag):
			errors.append("journal.json lists flag '%s' as internal twice." % internal_flag)
		internal[internal_flag] = true
		if not authored.has(internal_flag):
			errors.append(
				"journal.json internal flag '%s' is not set anywhere in the campaign." % internal_flag
			)
	var seen_facts := {}
	var facts := _journal_entries("facts")
	for raw in facts:
		if not raw is Dictionary:
			errors.append("journal.json facts entries must be objects.")
			continue
		var fact: Dictionary = raw
		var flag := String(fact.get("flag", ""))
		var text_value := String(fact.get("text", ""))
		if flag == "":
			errors.append("journal.json fact is missing 'flag'.")
		if text_value.strip_edges() == "":
			errors.append("journal.json fact '%s' has no text." % flag)
		if flag != "":
			if seen_facts.has(flag):
				errors.append("journal.json records flag '%s' as a fact twice." % flag)
			seen_facts[flag] = true
			if not authored.has(flag):
				errors.append("journal.json fact flag '%s' is not set anywhere in the campaign." % flag)
			if internal.has(flag):
				errors.append("journal.json flag '%s' is both a fact and internal." % flag)
		var conflicts: Variant = fact.get("conflicts_with", [])
		if not conflicts is Array:
			errors.append("journal.json fact '%s' conflicts_with must be an array." % flag)
			continue
		for other in Array(conflicts):
			var other_flag := String(other)
			if other_flag == "" or other_flag == flag:
				errors.append("journal.json fact '%s' conflicts with itself." % flag)
			elif not authored.has(other_flag):
				errors.append(
					"journal.json fact '%s' conflicts with unknown flag '%s'." % [flag, other_flag]
				)
	var questions := _journal_entries("questions")
	for raw in questions:
		if not raw is Dictionary:
			errors.append("journal.json questions entries must be objects.")
			continue
		var question: Dictionary = raw
		var question_text := String(question.get("text", ""))
		if question_text.strip_edges() == "":
			errors.append("journal.json question has no text.")
		var reveal := String(question.get("revealed_by", ""))
		var resolve := String(question.get("resolved_by", ""))
		for key in ["revealed_by", "resolved_by"]:
			var reference := String(question.get(key, ""))
			if reference == "":
				continue
			if not authored.has(reference):
				errors.append(
					"journal.json question '%s' has %s flag '%s' that the campaign never sets."
					% [question_text.left(40), key, reference]
				)
		if reveal != "" and reveal == resolve:
			errors.append(
				"journal.json question '%s' is revealed and resolved by the same flag." % question_text.left(40)
			)


func _journal_entries(key: String) -> Array:
	var value: Variant = journal.get(key, [])
	if value == null:
		return []
	if not value is Array:
		errors.append("journal.json '%s' must be an array." % key)
		return []
	return Array(value)


func _validate_actor(actor: Dictionary, label: String, is_character: bool) -> void:
	for ability in Rules.ABILITIES:
		if not Dictionary(actor.get("abilities", {})).has(ability):
			errors.append("%s is missing ability '%s'." % [label, ability])
	if int(actor.get("max_hp", 0)) <= 0:
		errors.append("%s has non-positive max_hp." % label)
	# Size category is authoritative; an authored size_ac must agree with it so
	# the two can never drift into conflicting sources of truth.
	var size_category := String(actor.get("size_category", "")).to_lower()
	if size_category != "":
		if not Rules.is_valid_size_category(size_category):
			errors.append("%s has unknown size category '%s'." % [label, size_category])
		elif int(actor.get("size_ac", 0)) != Rules.size_modifier(size_category):
			errors.append(
				"%s size_ac %d disagrees with size category '%s' (%d)."
				% [label, int(actor.get("size_ac", 0)), size_category, Rules.size_modifier(size_category)]
			)
	var equipment: Dictionary = actor.get("equipment", {})
	for slot in equipment.keys():
		if not Character.SLOTS.has(String(slot)):
			errors.append("%s uses unknown equipment slot '%s'." % [label, slot])
		elif not items.has(String(equipment[slot])):
			errors.append("%s references missing item '%s'." % [label, equipment[slot]])
	for entry in Array(actor.get("inventory", [])):
		if not items.has(String(entry.get("id", ""))):
			errors.append("%s inventory references missing item '%s'." % [label, entry.get("id", "")])
	var spells: Dictionary = actor.get("spells", {})
	for level_key in Dictionary(spells.get("slots", {})).keys():
		for spell_id in Array(Dictionary(spells.get("daily_prepared", {})).get(level_key, [])):
			if not self.spells.has(String(spell_id)):
				errors.append("%s prepares missing spell '%s'." % [label, spell_id])
			else:
				var level := int(self.spells[String(spell_id)].get("level", 1))
				if level != int(level_key):
					errors.append(
						"%s prepares '%s' (level %d) in level %s slots."
						% [label, spell_id, level, level_key]
					)
	for known_id in Array(spells.get("known", [])):
		if not self.spells.has(String(known_id)):
			errors.append("%s knows missing spell '%s'." % [label, known_id])
	if is_character:
		for skill in Dictionary(actor.get("skill_ranks", {})).keys():
			if not Skills.exists(String(skill)):
				errors.append("%s has ranks in unknown skill '%s'." % [label, skill])
	# Feats are authoritative only when implemented and their prerequisites
	# still hold; unknown or unmet feat names are content errors.
	var built := Character.from_content(actor, items)
	errors.append_array(Feats.validate_for_character(built))


func _validate_cell(map: BattleMap, cell: Variant, label: String) -> void:
	if not (cell is Array) or Array(cell).size() != 2:
		errors.append("%s is malformed." % label)
		return
	var pos := Vector2i(int(Array(cell)[0]), int(Array(cell)[1]))
	if not map.in_bounds(pos):
		errors.append("%s %s is outside the battle map." % [label, str(pos)])
	elif map.is_blocked(pos):
		errors.append("%s %s is inside a wall." % [label, str(pos)])


func _validate_effect_list(effects: Array, label: String) -> void:
	for effect in effects:
		if not effect is Dictionary:
			errors.append("%s has a malformed effect." % label)
			continue
		# The effect vocabulary, required fields and id references live in
		# ContentSpec, the same registry GameSession's runtime guard consults.
		for error in ContentSpec.validate_effect(effect, self):
			errors.append("%s %s" % [label, error])
		# Walkability needs the target area's own map, so it stays here.
		if String(effect.get("type", "")) == "travel" and areas.has(String(effect.get("area", ""))):
			var target_pos: Variant = effect.get("pos", [])
			if target_pos is Array and Array(target_pos).size() == 2:
				var target_dungeon := Dungeon.new()
				target_dungeon.setup(Dictionary(areas[String(effect["area"])]))
				var pos := Vector2i(int(Array(target_pos)[0]), int(Array(target_pos)[1]))
				if not target_dungeon.in_bounds(pos) or not target_dungeon.is_walkable(pos):
					errors.append("%s travel target %s is not walkable." % [label, str(pos)])


func _validate_dialogue(dialogue: Dictionary, dialogue_id: String) -> void:
	var nodes: Dictionary = dialogue.get("nodes", {})
	if nodes.is_empty():
		errors.append("Dialogue '%s' has no nodes." % dialogue_id)
		return
	var start := String(dialogue.get("start", ""))
	if not nodes.has(start):
		errors.append("Dialogue '%s' start node '%s' does not exist." % [dialogue_id, start])
	for node_key in nodes.keys():
		var node: Dictionary = nodes[node_key]
		if String(node.get("text", "")) == "":
			errors.append("Dialogue '%s' node '%s' has no text." % [dialogue_id, node_key])
		_validate_effect_list(Array(node.get("effects", [])), "dialogue '%s' node '%s'" % [dialogue_id, node_key])
		var next := String(node.get("next", ""))
		if next != "" and not nodes.has(next):
			errors.append("Dialogue '%s' node '%s' links to missing node '%s'." % [dialogue_id, node_key, next])
		for choice in Array(node.get("choices", [])):
			var target := String(choice.get("next", ""))
			if target != "" and not nodes.has(target):
				errors.append(
					"Dialogue '%s' node '%s' choice links to missing node '%s'."
					% [dialogue_id, node_key, target]
				)
			var check: Dictionary = choice.get("check", {})
			if not check.is_empty():
				for branch in ["success", "failure"]:
					var branch_node := String(check.get(branch, ""))
					if branch_node == "" or not nodes.has(branch_node):
						errors.append(
							"Dialogue '%s' node '%s' check has invalid %s node '%s'."
							% [dialogue_id, node_key, branch, branch_node]
						)
				var skill := String(check.get("skill", ""))
				if skill != "" and not Skills.exists(skill):
					errors.append("Dialogue '%s' uses unknown skill '%s'." % [dialogue_id, skill])
			_validate_effect_list(
				Array(choice.get("effects", [])), "dialogue '%s' node '%s' choice" % [dialogue_id, node_key]
			)
			for condition in Array(choice.get("conditions", [])):
				if not condition is Dictionary:
					errors.append(
						"Dialogue '%s' node '%s' has a malformed condition." % [dialogue_id, node_key]
					)
					continue
				for error in ContentSpec.validate_condition(condition, self):
					errors.append("Dialogue '%s' node '%s' %s" % [dialogue_id, node_key, error])


func summary() -> String:
	return "Campaign '%s': %d items, %d spells, %d characters, %d monsters, %d encounters, %d dialogues, %d quests, %d areas." % [
		campaign_id,
		items.size(),
		spells.size(),
		characters.size(),
		monsters.size(),
		encounters.size(),
		dialogues.size(),
		quests.size(),
		areas.size(),
	]
