class_name CampaignStore
extends RefCounted

## Player-authored campaigns live under `user://campaigns/<id>/`.
##
## The same package contract as bundled campaigns applies, but user packages are
## writable and are discovered by scanning this directory, so no compiled
## registry or engine edit is needed to add one. Bundled campaigns remain
## read-only; creating from a template is the only way to start editing.
##
## Every write is validated before it replaces anything and is staged through a
## temporary file, so an interrupted save cannot leave a half-written package.

const USER_ROOT := "user://campaigns"
const FORMAT_VERSION := 1
const MAX_ID_LENGTH := 40
const MAX_TITLE_LENGTH := 80
const MAX_FLAG_LENGTH := 64
const MAX_OBJECTIVES := 12
const MAX_ENCOUNTER_MONSTERS := 4
const AREA_WIDTH := 9
const AREA_HEIGHT := 9
const PLAYTEST_ROOT := "user://playtest"

const ENCOUNTER_TEMPLATES := {
	"room_7x5": {
		"label": "Small room (7x5)",
		"rows": ["#######", "#.....#", "#.....#", "#.....#", "#######"],
		"party_cells": [[1, 3], [2, 3], [3, 3], [4, 3]],
		"monster_cells": [[1, 1], [2, 1], [3, 1], [4, 1]],
	},
	"hall_9x5": {
		"label": "Wide hall (9x5)",
		"rows": ["#########", "#.......#", "#.......#", "#.......#", "#########"],
		"party_cells": [[1, 3], [2, 3], [3, 3], [4, 3]],
		"monster_cells": [[5, 1], [6, 1], [7, 1], [8, 1]],
	},
	"crypt_9x7": {
		"label": "Open crypt (9x7)",
		"rows": ["#########", "#.......#", "#.......#", "#.......#", "#.......#", "#.......#", "#########"],
		"party_cells": [[1, 5], [2, 5], [3, 5], [4, 5]],
		"monster_cells": [[5, 1], [6, 1], [7, 1], [5, 2]],
	},
}

# ------------------------------------------------------------------ discovery

## Problems found while scanning `user://campaigns`. A package that cannot be
## read is not listed, so without this a typo in `campaign.json` would make the
## author's campaign silently disappear from every campaign list. Callers append
## these to their own error lists; the campaign selector, the validator and the
## creator all inherit the explanation from here.
static var scan_errors: Array[String] = []


static func list_user_campaigns() -> Array:
	var result: Array = []
	scan_errors.clear()
	if not DirAccess.dir_exists_absolute(USER_ROOT):
		return result
	for raw_dir in DirAccess.get_directories_at(USER_ROOT):
		var campaign_id := String(raw_dir)
		if not is_valid_id(campaign_id):
			scan_errors.append(
				"User campaign folder '%s' is not a valid campaign id (2-%d lowercase letters, digits or underscores, starting with a letter); it is not listed."
				% [campaign_id, MAX_ID_LENGTH]
			)
			continue
		var package_dir := USER_ROOT.path_join(campaign_id)
		var manifest_path := package_dir.path_join("campaign.json")
		if not FileAccess.file_exists(manifest_path):
			scan_errors.append(
				"User campaign '%s' has no campaign.json in its folder; it is not listed."
				% campaign_id
			)
			continue
		var text := FileAccess.get_file_as_string(manifest_path)
		var parser := JSON.new()
		if parser.parse(text) != OK:
			scan_errors.append(
				"User campaign '%s': campaign.json is not valid JSON: %s (line %d). Fix the file; the campaign is not listed until it parses."
				% [campaign_id, parser.get_error_message(), (parser.get_error_line() + 1)]
			)
			continue
		if not parser.data is Dictionary:
			scan_errors.append(
				"User campaign '%s': campaign.json is valid JSON but not an object; it is not listed."
				% campaign_id
			)
			continue
		var manifest: Dictionary = Dictionary(parser.data).duplicate(true)
		if String(manifest.get("id", "")) != campaign_id:
			scan_errors.append(
				"User campaign '%s': campaign.json declares id '%s', which does not match its folder. Rename the folder or fix the id; the campaign is not listed."
				% [campaign_id, String(manifest.get("id", ""))]
			)
			continue
		manifest["source"] = "user"
		manifest["package_dir"] = package_dir
		manifest["writable"] = true
		result.append(manifest)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return result


static func is_valid_id(campaign_id: String) -> bool:
	if campaign_id.length() < 2 or campaign_id.length() > MAX_ID_LENGTH:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*$")
	return pattern.search(campaign_id) != null


static func is_bundled_id(campaign_id: String) -> bool:
	var registry_path := "res://content/campaigns/_registry.json"
	if FileAccess.file_exists(registry_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
		if parsed is Dictionary:
			for raw_id in Array(Dictionary(parsed).get("campaigns", [])):
				if String(raw_id) == campaign_id:
					return true
	return DirAccess.dir_exists_absolute("res://content/campaigns".path_join(campaign_id))


static func package_dir(campaign_id: String) -> String:
	return USER_ROOT.path_join(campaign_id)


# ------------------------------------------------------------------ creation

static func create(title: String, campaign_id: String) -> Dictionary:
	var clean_title := title.strip_edges()
	if clean_title == "":
		return {"ok": false, "message": "Enter a campaign title."}
	if clean_title.length() > MAX_TITLE_LENGTH:
		return {"ok": false, "message": "Titles are limited to %d characters." % MAX_TITLE_LENGTH}
	if not is_valid_id(campaign_id):
		return {
			"ok": false,
			"message": "Campaign id must be 2-%d lowercase letters, digits or underscores, starting with a letter." % MAX_ID_LENGTH,
		}
	if is_bundled_id(campaign_id):
		return {"ok": false, "message": "Campaign id '%s' belongs to a bundled campaign. Choose a different id." % campaign_id}
	if DirAccess.dir_exists_absolute(package_dir(campaign_id)):
		return {"ok": false, "message": "A user campaign with id '%s' already exists. Open it instead." % campaign_id}
	var draft := make_draft(clean_title, campaign_id)
	var written := write_package(draft)
	if bool(written.get("ok", false)):
		written["draft"] = draft
		written["id"] = campaign_id
	return written


static func make_draft(title: String, campaign_id: String) -> Dictionary:
	var area_id := "area_01"
	var quest_id := campaign_id + "_quest"
	var rows: Array[String] = []
	for y in AREA_HEIGHT:
		var line := ""
		for x in AREA_WIDTH:
			var border := x == 0 or y == 0 or x == AREA_WIDTH - 1 or y == AREA_HEIGHT - 1
			line += "#" if border else "."
		rows.append(line)
	var area := {
		"id": area_id,
		"name": "Starting Area",
		"ambient": "(USER CAMPAIGN — PLACEHOLDER PROSE) An empty room waiting to be described.",
		"tracker_quest": quest_id,
		"rows": rows,
		"start": {"pos": [4, 4], "facing": 0},
		"doors": [],
		"npcs": [],
		"objects": [],
		"triggers": [],
	}
	return {
		"format_version": FORMAT_VERSION,
		"id": campaign_id,
		"title": title,
		"description": "(USER CAMPAIGN — PLACEHOLDER PROSE) Created in the campaign creator. Replace this description.",
		"status": "user",
		"version": 1,
		"content_root": package_dir(campaign_id),
		"start_quest": quest_id,
		"completion_quest": "",
		"entry": {"area": area_id, "pos": [4, 4], "facing": 0},
		"party": {"default": ["kaelen", "sera", "aldric", "ysolde"], "min": 1, "max": 4},
		"requires": {"capabilities": ["exploration", "travel", "quests", "saves", "narration"]},
		"areas": [area],
		"quests": {
			quest_id: {
				"id": quest_id,
				"title": title,
				"summary": "(USER CAMPAIGN) Look around the starting area.",
				"objectives": [
					{"id": "look_around", "text": "Look around the area.", "flag": "looked_around"},
				],
			},
		},
		"encounters": {},
		"dialogues": {},
		"narration": {
			"intro": ["(USER CAMPAIGN) %s begins here. This placeholder text can be edited later." % title],
			"defeat": ["(USER CAMPAIGN) The party falls."],
			"victory": ["(USER CAMPAIGN) Objective complete."],
			"controls_hint": "",
		},
	}


# ------------------------------------------------------------------ loading

static func load_package(campaign_id: String) -> Dictionary:
	if not is_valid_id(campaign_id):
		return {"ok": false, "message": "Invalid campaign id."}
	if is_bundled_id(campaign_id):
		return {"ok": false, "message": "Bundled campaigns are read-only. Create a user campaign to edit content."}
	var dir := package_dir(campaign_id)
	var manifest_path := dir.path_join("campaign.json")
	if not FileAccess.file_exists(manifest_path):
		return {"ok": false, "message": "No user campaign with id '%s'." % campaign_id}
	var manifest_read := _read_json_object_checked(manifest_path)
	if not bool(manifest_read.get("ok", false)):
		return _package_failure(manifest_read, "campaign.json")
	var parsed: Variant = manifest_read.get("data", {})
	var draft: Dictionary = Dictionary(parsed).duplicate(true)
	if String(draft.get("id", "")) != campaign_id:
		return {"ok": false, "message": "The campaign manifest id does not match its folder."}
	if int(draft.get("format_version", FORMAT_VERSION)) > FORMAT_VERSION:
		return {
			"ok": false,
			"message": "This campaign uses format version %s; this creator supports version %d and will not risk rewriting it." % [str(draft.get("format_version")), FORMAT_VERSION],
		}
	# The creator writes split files only. Content kept inline in campaign.json
	# would be dropped by the first save, so editing is refused with instructions
	# instead of silently narrowing the package.
	for inline_key in ["areas", "quests", "encounters", "narration", "dialogues"]:
		var inline_value: Variant = draft.get(inline_key, null)
		var inline_size := 0
		if inline_value is Array:
			inline_size = Array(inline_value).size()
		elif inline_value is Dictionary:
			inline_size = Dictionary(inline_value).size()
		if inline_size > 0:
			return {
				"ok": false,
				"message": "Campaign '%s' stores '%s' inline in campaign.json. The creator edits split files and will not rewrite this package; move that content into its own file first." % [campaign_id, inline_key],
			}
	draft["areas"] = []
	var area_dir := dir.path_join("areas")
	if DirAccess.dir_exists_absolute(area_dir):
		var files := DirAccess.get_files_at(area_dir)
		files.sort()
		var seen_areas := {}
		for file_name in files:
			var file_string := String(file_name)
			if file_string.begins_with("_") or not file_string.ends_with(".json"):
				continue
			var area_read := _read_json_object_checked(area_dir.path_join(file_string))
			if not bool(area_read.get("ok", false)):
				var failure := _package_failure(area_read, "areas/%s" % file_string)
				failure["source"] = "areas/%s" % file_string
				failure["entity_type"] = "area"
				failure["entity_id"] = file_string.get_basename()
				return failure
			var area: Dictionary = Dictionary(area_read.get("data", {})).duplicate(true)
			var area_id := String(area.get("id", ""))
			if area_id == "":
				return {
					"ok": false,
					"message": "Area file '%s' has no id. The creator will not rewrite a package it cannot read." % file_string,
				}
			if seen_areas.has(area_id):
				return {
					"ok": false,
					"message": "Two area files declare id '%s'. Remove the duplicate before editing." % area_id,
				}
			seen_areas[area_id] = true
			draft["areas"].append(area)
	var dialogue_read := _read_dialogue_dir(dir.path_join("dialogue"))
	var dialogue_errors: Array = dialogue_read.get("errors", [])
	if not dialogue_errors.is_empty():
		return {
			"ok": false,
			"message": String(dialogue_errors[0]),
			"diagnostics": Array(dialogue_read.get("diagnostics", [])),
		}
	draft["dialogues"] = Dictionary(dialogue_read.get("dialogues", {}))
	for table in [["quests", "quests.json"], ["encounters", "encounters.json"], ["narration", "narration.json"]]:
		var read := _read_json_object_checked(dir.path_join(String(table[1])))
		if not bool(read.get("ok", false)):
			var failure := _package_failure(read, String(table[1]))
			failure["entity_type"] = String(table[0])
			return failure
		draft[String(table[0])] = Dictionary(read.get("data", {}))
	return {"ok": true, "message": "Opened '%s'." % campaign_id, "draft": draft}


static func _read_dialogue_dir(dialogue_dir: String) -> Dictionary:
	var result := {}
	var errors: Array[String] = []
	var diagnostics: Array = []
	if not DirAccess.dir_exists_absolute(dialogue_dir):
		return {"dialogues": result, "errors": errors, "diagnostics": diagnostics}
	var files := DirAccess.get_files_at(dialogue_dir)
	files.sort()
	for file_name in files:
		var file_string := String(file_name)
		if file_string.begins_with("_") or not file_string.ends_with(".json"):
			continue
		var path := dialogue_dir.path_join(file_string)
		var parser := JSON.new()
		var parse_error := parser.parse(FileAccess.get_file_as_string(path))
		if parse_error != OK:
			var message := "Dialogue file '%s' is not valid JSON: %s (line %d). The creator will not rewrite a package it cannot read." % [
				file_string, parser.get_error_message(), (parser.get_error_line() + 1)
			]
			errors.append(message)
			diagnostics.append(ContentDiagnostics.make("package.dialogue.syntax", ContentDiagnostics.ERROR, message, {
				"source": file_string,
				"entity_type": "dialogue",
				"entity_id": file_string.get_basename(),
				"line": (parser.get_error_line() + 1),
				"section": "advanced",
				"advanced": true,
			}))
			continue
		var parsed: Variant = parser.data
		if not parsed is Dictionary:
			var message := "Dialogue file '%s' is valid JSON but not a JSON object. The creator will not rewrite a package it cannot read." % file_string
			errors.append(message)
			diagnostics.append(ContentDiagnostics.make("package.dialogue.shape", ContentDiagnostics.ERROR, message, {
				"source": file_string,
				"entity_type": "dialogue",
				"entity_id": file_string.get_basename(),
				"section": "advanced",
				"advanced": true,
			}))
			continue
		var dialogue: Dictionary = Dictionary(parsed).duplicate(true)
		var dialogue_id := String(dialogue.get("id", file_string.get_basename()))
		if dialogue_id == "":
			errors.append("Dialogue file '%s' has no id." % file_string)
			continue
		if result.has(dialogue_id):
			errors.append("Two dialogue files declare id '%s'. Remove the duplicate before editing." % dialogue_id)
			continue
		result[dialogue_id] = dialogue
	return {"dialogues": result, "errors": errors, "diagnostics": diagnostics}


static func _read_json_object(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed).duplicate(true) if parsed is Dictionary else {}


## Strict variant for content the creator rewrites: a malformed existing file is
## an error, never an empty table that would be saved over the original.
## One failed package read as a structured diagnostic. The code, source and line
## come from the reader; nothing here invents a location for a semantic error.
static func _package_failure(read: Dictionary, fallback_source: String) -> Dictionary:
	var diagnostic := ContentDiagnostics.make(
		String(read.get("code", "package.load")),
		ContentDiagnostics.ERROR,
		String(read.get("message", "The package file could not be read.")),
		{
			"source": String(read.get("source", fallback_source)),
			"line": int(read.get("line", 0)),
			"section": "advanced",
			"advanced": true,
		}
	)
	return {"ok": false, "message": String(diagnostic["message"]), "diagnostics": [diagnostic]}


static func _read_json_object_checked(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": true, "data": {}}
	var parser := JSON.new()
	var parse_error := parser.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK:
		return {
			"ok": false,
			"code": "package.json.syntax",
			"source": path.get_file(),
			"line": (parser.get_error_line() + 1),
			"message": "File '%s' is not valid JSON: %s (line %d). The creator will not rewrite a package it cannot read." % [
				path.get_file(), parser.get_error_message(), (parser.get_error_line() + 1)
			],
		}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {
			"ok": false,
			"code": "package.json.shape",
			"source": path.get_file(),
			"message": "File '%s' is valid JSON but not a JSON object. The creator will not rewrite a package it cannot read." % path.get_file(),
		}
	return {"ok": true, "data": Dictionary(parsed).duplicate(true)}


# ------------------------------------------------------------------ validation

## Structural checks that do not need the content loader. These produce the
## messages the creator shows immediately while the player edits.
## Structured draft diagnostics used by the creator and developer tools. The
## legacy shape validator remains authoritative for save/playtest; this pass
## attaches stable codes and explicit locations for the errors a creator can
## resolve. Unmapped legacy errors are wrapped by the consumer, never parsed.
static func diagnose_draft(draft: Dictionary) -> Array:
	var diags: Array = []
	var campaign := String(draft.get("id", ""))
	var areas: Array = Array(draft.get("areas", []))
	var area_ids := {}
	var npc_ids := {}
	var dialogues := Dictionary(draft.get("dialogues", {}))
	for raw_area in areas:
		if raw_area is Dictionary:
			var listed_id := String(Dictionary(raw_area).get("id", ""))
			if listed_id != "":
				if area_ids.has(listed_id):
					_add_diag(diags, "area.id.duplicate", "error", "Duplicate area id '%s'." % listed_id, "area", "area", listed_id, "id", listed_id)
				area_ids[listed_id] = true

	if not is_valid_id(campaign):
		_add_diag(diags, "campaign.id.invalid", "error", "Campaign id is missing or invalid.", "metadata", "campaign", campaign, "id")
	elif is_bundled_id(campaign):
		_add_diag(diags, "campaign.id.bundled", "error", "Campaign id '%s' belongs to a bundled campaign." % campaign, "metadata", "campaign", campaign, "id")
	if String(draft.get("title", "")).strip_edges() == "":
		_add_diag(diags, "campaign.title.empty", "error", "Campaign title is empty.", "metadata", "campaign", campaign, "title")
	if areas.is_empty():
		_add_diag(diags, "campaign.areas.empty", "error", "The campaign has no areas.", "area", "campaign", campaign, "areas")

	for raw_area in areas:
		if not raw_area is Dictionary:
			_add_diag(diags, "area.malformed", "error", "An area entry is malformed.", "area", "area", "", "areas")
			continue
		var area: Dictionary = raw_area
		var area_id := String(area.get("id", ""))
		if area_id == "":
			_add_diag(diags, "area.id.empty", "error", "An area has no id.", "area", "area", "", "id")
			continue
		var rows: Array = Array(area.get("rows", []))
		if rows.is_empty():
			_add_diag(diags, "area.rows.empty", "error", "Area '%s' has no rows." % area_id, "area", "area", area_id, "rows", area_id)
			continue
		var width := String(rows[0]).length()
		for y in rows.size():
			if String(rows[y]).length() != width:
				_add_diag(diags, "area.rows.width", "error", "Area '%s' row %d is not %d cells wide." % [area_id, y, width], "area", "area", area_id, "rows", area_id)
				break
		var start: Dictionary = area.get("start", {})
		var start_pos: Array = Array(start.get("pos", []))
		if start_pos.size() != 2 or not _in_bounds(start_pos, width, rows.size()) or not _is_floor(rows, start_pos):
			_add_diag(diags, "area.start.wall", "error", "Area '%s' start position is not walkable." % area_id, "area", "area", area_id, "start.pos", area_id)
		for raw_obj in Array(area.get("objects", [])):
			if not raw_obj is Dictionary:
				continue
			var obj: Dictionary = raw_obj
			var obj_id := String(obj.get("id", "?"))
			var obj_pos: Array = Array(obj.get("pos", []))
			if obj_pos.size() != 2 or not _in_bounds(obj_pos, width, rows.size()):
				_add_diag(diags, "object.pos.outside", "error", "Area '%s' object '%s' is outside the map." % [area_id, obj_id], "area", "object", obj_id, "pos", area_id)
			var is_travel := false
			for raw_interaction in Array(obj.get("interactions", [])):
				if not raw_interaction is Dictionary:
					continue
				for raw_effect in Array(Dictionary(raw_interaction).get("effects", [])):
					if not raw_effect is Dictionary or String(Dictionary(raw_effect).get("type", "")) != "travel":
						continue
					is_travel = true
					var target_area := String(Dictionary(raw_effect).get("area", ""))
					if target_area == "" or not area_ids.has(target_area):
						_add_diag(diags, "transition.target.missing", "error", "Area '%s' links to missing area '%s'." % [area_id, target_area], "passage", "object", obj_id, "effects.area", area_id, "", -1, [target_area])
						continue
					var target_rows := _rows_for(areas, target_area)
					var target_width := String(target_rows[0]).length() if not target_rows.is_empty() else 0
					var target_pos: Array = Array(Dictionary(raw_effect).get("pos", []))
					if target_pos.size() != 2 or not _in_bounds(target_pos, target_width, target_rows.size()) or not _is_floor(target_rows, target_pos):
						_add_diag(diags, "transition.target.wall", "error", "Area '%s' travel target in '%s' is not walkable." % [area_id, target_area], "passage", "object", obj_id, "effects.pos", area_id, "", -1, [target_area])
			if not is_travel:
				_add_diag(diags, "content.advanced.object", "warning", "Object '%s' uses file-only interactions; edit its JSON for advanced effects." % obj_id, "advanced", "object", obj_id, "interactions", area_id, "", -1, [], true)
		for raw_npc in Array(area.get("npcs", [])):
			if not raw_npc is Dictionary:
				_add_diag(diags, "npc.malformed", "error", "Area '%s' has a malformed NPC." % area_id, "npc", "npc", "", "npcs", area_id)
				continue
			var npc: Dictionary = raw_npc
			var npc_id := String(npc.get("id", ""))
			if not is_valid_id(npc_id):
				_add_diag(diags, "npc.id.invalid", "error", "NPC id '%s' is invalid; use lowercase letters, digits and underscores." % npc_id, "npc", "npc", npc_id, "id", area_id)
			elif npc_ids.has(npc_id):
				_add_diag(diags, "npc.id.duplicate", "error", "Duplicate NPC id '%s' (already placed in '%s')." % [npc_id, npc_ids[npc_id]], "npc", "npc", npc_id, "id", area_id)
			npc_ids[npc_id] = area_id
			if String(npc.get("name", "")).strip_edges() == "":
				_add_diag(diags, "npc.name.empty", "error", "NPC '%s' has no display name." % npc_id, "npc", "npc", npc_id, "name", area_id)
			var npc_pos: Array = Array(npc.get("pos", []))
			if npc_pos.size() != 2 or not _in_bounds(npc_pos, width, rows.size()) or not _is_floor(rows, npc_pos):
				_add_diag(diags, "npc.pos.wall", "error", "NPC '%s' does not stand on a floor cell." % npc_id, "npc", "npc", npc_id, "pos", area_id)
			elif _area_feature_at(area, npc_pos):
				_add_diag(diags, "npc.pos.blocked", "error", "NPC '%s' stands on a cell already used by the start, an object, a door or a trigger." % npc_id, "npc", "npc", npc_id, "pos", area_id)
			var npc_dialogue := String(npc.get("dialogue", ""))
			if npc_dialogue != "" and not dialogues.has(npc_dialogue):
				_add_diag(diags, "npc.dialogue.missing", "error", "NPC '%s' references missing dialogue '%s'." % [npc_id, npc_dialogue], "npc", "npc", npc_id, "dialogue", area_id, "", -1, [npc_dialogue])
		if not Array(area.get("doors", [])).is_empty():
			_add_diag(diags, "content.advanced.doors", "warning", "Area '%s' has doors; door locks and transitions are edited in area JSON." % area_id, "advanced", "area", area_id, "doors", area_id, "", -1, [], true)

	var entry: Dictionary = draft.get("entry", {})
	var entry_area := String(entry.get("area", ""))
	var entry_pos: Array = Array(entry.get("pos", []))
	if entry_area == "":
		_add_diag(diags, "entry.area.missing", "error", "Set an entry area.", "entry", "campaign", campaign, "entry.area")
	elif not area_ids.has(entry_area):
		_add_diag(diags, "entry.area.missing", "error", "Entry area '%s' does not exist." % entry_area, "entry", "campaign", campaign, "entry.area", "", "", -1, [entry_area])
	else:
		var entry_rows := _rows_for(areas, entry_area)
		var entry_width := String(entry_rows[0]).length() if not entry_rows.is_empty() else 0
		if entry_pos.size() != 2 or not _in_bounds(entry_pos, entry_width, entry_rows.size()) or not _is_floor(entry_rows, entry_pos):
			_add_diag(diags, "entry.pos.wall", "error", "Entry position in '%s' is not walkable." % entry_area, "entry", "campaign", campaign, "entry.pos", entry_area)
		for raw_npc in Array(area_by_id(draft, entry_area).get("npcs", [])):
			if raw_npc is Dictionary and _same_cell(Array(Dictionary(raw_npc).get("pos", [])), entry_pos):
				_add_diag(diags, "entry.npc.overlap", "error", "NPC '%s' stands on the campaign entry cell." % Dictionary(raw_npc).get("id", "?"), "npc", "npc", String(Dictionary(raw_npc).get("id", "?")), "pos", entry_area)
	if int(entry.get("facing", 0)) < 0 or int(entry.get("facing", 0)) > 3:
		_add_diag(diags, "entry.facing.invalid", "error", "Entry facing must be north, east, south or west.", "entry", "campaign", campaign, "entry.facing", entry_area)

	var npc_targets := {}
	for raw_area in areas:
		if raw_area is Dictionary:
			for raw_npc in Array(Dictionary(raw_area).get("npcs", [])):
				if raw_npc is Dictionary:
					npc_targets[String(Dictionary(raw_npc).get("id", ""))] = true
	for raw_dialogue_id in dialogues.keys():
		var dialogue_id := String(raw_dialogue_id)
		if not dialogues[raw_dialogue_id] is Dictionary:
			_add_diag(diags, "dialogue.malformed", "error", "Dialogue '%s' is malformed." % dialogue_id, "dialogue", "dialogue", dialogue_id, "dialogues")
			continue
		var dialogue: Dictionary = Dictionary(dialogues[raw_dialogue_id])
		if not is_valid_id(dialogue_id):
			_add_diag(diags, "dialogue.id.invalid", "error", "Dialogue id '%s' is invalid." % dialogue_id, "dialogue", "dialogue", dialogue_id, "id")
		if String(dialogue.get("speaker", "")).strip_edges() == "":
			_add_diag(diags, "dialogue.speaker.empty", "error", "Dialogue '%s' has no speaker name." % dialogue_id, "dialogue", "dialogue", dialogue_id, "speaker")
		var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
		if nodes.is_empty():
			_add_diag(diags, "dialogue.nodes.empty", "error", "Dialogue '%s' has no nodes." % dialogue_id, "dialogue", "dialogue", dialogue_id, "nodes")
			continue
		var start_node := String(dialogue.get("start", ""))
		if start_node == "":
			_add_diag(diags, "dialogue.start.missing", "error", "Dialogue '%s' has no start node." % dialogue_id, "dialogue", "dialogue", dialogue_id, "start")
		elif not nodes.has(start_node):
			_add_diag(diags, "dialogue.start.missing", "error", "Dialogue '%s' start node '%s' does not exist." % [dialogue_id, start_node], "dialogue", "dialogue", dialogue_id, "start", "", start_node, -1, [start_node])
		var allowed_actors := {"best": true}
		for raw_actor in Array(Dictionary(draft.get("party", {})).get("default", [])):
			allowed_actors[String(raw_actor)] = true
		for raw_node_id in nodes.keys():
			var node_id := String(raw_node_id)
			if not nodes[raw_node_id] is Dictionary:
				_add_diag(diags, "dialogue.node.malformed", "error", "Dialogue '%s' node '%s' is malformed." % [dialogue_id, node_id], "node", "node", node_id, "nodes", "", node_id)
				continue
			var node: Dictionary = Dictionary(nodes[raw_node_id])
			if String(node.get("text", "")).strip_edges() == "":
				_add_diag(diags, "dialogue.node.text", "error", "Dialogue '%s' node '%s' has no text." % [dialogue_id, node_id], "node", "node", node_id, "text", "", node_id)
			var next_id := String(node.get("next", ""))
			if next_id != "" and not nodes.has(next_id):
				_add_diag(diags, "dialogue.node.destination", "error", "Dialogue '%s' node '%s' links to missing node '%s'." % [dialogue_id, node_id, next_id], "node", "node", node_id, "next", "", node_id, -1, [next_id])
			var choices: Array = Array(node.get("choices", []))
			for i in choices.size():
				if not choices[i] is Dictionary:
					_add_diag(diags, "dialogue.choice.malformed", "error", "Dialogue '%s' node '%s' choice %d is malformed." % [dialogue_id, node_id, i + 1], "choice", "choice", node_id, "choices", "", node_id, i)
					continue
				var choice: Dictionary = Dictionary(choices[i])
				if String(choice.get("text", "")).strip_edges() == "":
					_add_diag(diags, "dialogue.choice.text", "error", "Dialogue '%s' node '%s' choice %d has no text." % [dialogue_id, node_id, i + 1], "choice", "choice", node_id, "text", "", node_id, i)
				if choice.get("check") is Dictionary:
					var check: Dictionary = choice["check"]
					var skill := String(check.get("skill", ""))
					if not Skills.exists(skill):
						_add_diag(diags, "dialogue.check.skill", "error", "Dialogue '%s' node '%s' choice %d uses unknown skill '%s'." % [dialogue_id, node_id, i + 1, skill], "choice", "choice", node_id, "check.skill", "", node_id, i)
					var dc := int(check.get("dc", 0))
					if dc < 1 or dc > 60:
						_add_diag(diags, "dialogue.check.dc", "error", "Dialogue '%s' node '%s' choice %d DC must be between 1 and 60." % [dialogue_id, node_id, i + 1], "choice", "choice", node_id, "check.dc", "", node_id, i)
					var actor := String(check.get("actor", "best"))
					if not allowed_actors.has(actor):
						_add_diag(diags, "dialogue.check.actor", "error", "Dialogue '%s' node '%s' choice %d rolls as '%s', which is not in the campaign party." % [dialogue_id, node_id, i + 1, actor], "choice", "choice", node_id, "check.actor", "", node_id, i, [actor])
					for branch in ["success", "failure"]:
						var dest := String(check.get(branch, ""))
						if dest == "" or not nodes.has(dest):
							_add_diag(diags, "dialogue.check.destination", "error", "Dialogue '%s' node '%s' choice %d %s destination '%s' does not exist." % [dialogue_id, node_id, i + 1, branch, dest], "choice", "choice", node_id, "check.%s" % branch, "", node_id, i, [dest])
				elif String(choice.get("next", "")) != "" and not nodes.has(String(choice.get("next", ""))):
					_add_diag(diags, "dialogue.choice.destination", "error", "Dialogue '%s' node '%s' choice %d links to missing node '%s'." % [dialogue_id, node_id, i + 1, String(choice.get("next", ""))], "choice", "choice", node_id, "next", "", node_id, i, [String(choice.get("next", ""))])
		if nodes.has(start_node):
			var reachable := {start_node: true}
			var queue: Array[String] = [start_node]
			while not queue.is_empty():
				var current: String = queue.pop_front()
				var current_node: Dictionary = Dictionary(nodes[current])
				var targets: Array[String] = [String(current_node.get("next", ""))]
				for raw_choice in Array(current_node.get("choices", [])):
					if not raw_choice is Dictionary:
						continue
					var choice: Dictionary = Dictionary(raw_choice)
					if choice.get("check") is Dictionary:
						targets.append(String(Dictionary(choice["check"]).get("success", "")))
						targets.append(String(Dictionary(choice["check"]).get("failure", "")))
					else:
						targets.append(String(choice.get("next", "")))
				for target in targets:
					if target != "" and nodes.has(target) and not reachable.has(target):
						reachable[target] = true
						queue.append(target)
			var orphans: Array[String] = []
			for raw_node_id in nodes.keys():
				if not reachable.has(String(raw_node_id)):
					orphans.append(String(raw_node_id))
			if not orphans.is_empty():
				orphans.sort()
				_add_diag(diags, "dialogue.node.unreachable", "error", "Dialogue '%s' has unreachable node(s): %s." % [dialogue_id, ", ".join(orphans)], "dialogue", "dialogue", dialogue_id, "start", "", "", -1, orphans)

	var flag_defs := flags_of(draft)
	for raw_flag in flag_defs.keys():
		if not is_valid_flag(String(raw_flag)):
			_add_diag(diags, "flag.definition.invalid", "error", "Flag definition '%s' is invalid." % raw_flag, "flag", "flag", String(raw_flag), "flags")
	var quests := quests_of(draft)
	for raw_quest_id in quests.keys():
		var quest_id := String(raw_quest_id)
		var quest: Dictionary = _as_dict(quests[raw_quest_id])
		if not is_valid_id(quest_id):
			_add_diag(diags, "quest.id.invalid", "error", "Quest id '%s' is invalid." % quest_id, "quest", "quest", quest_id, "id")
		if String(quest.get("title", "")).strip_edges() == "":
			_add_diag(diags, "quest.title.empty", "error", "Quest '%s' has no title." % quest_id, "quest", "quest", quest_id, "title")
		var objectives: Array = Array(quest.get("objectives", []))
		if objectives.is_empty():
			_add_diag(diags, "quest.objectives.empty", "error", "Quest '%s' has no objectives." % quest_id, "quest", "quest", quest_id, "objectives")
		var objective_ids := {}
		for raw_objective in objectives:
			if not raw_objective is Dictionary:
				_add_diag(diags, "quest.objective.malformed", "error", "Quest '%s' has a malformed objective." % quest_id, "objective", "objective", "", "objectives")
				continue
			var objective: Dictionary = Dictionary(raw_objective)
			var objective_id := String(objective.get("id", ""))
			if not is_valid_id(objective_id):
				_add_diag(diags, "quest.objective.id", "error", "Quest '%s' objective id '%s' is invalid." % [quest_id, objective_id], "objective", "objective", objective_id, "id")
			elif objective_ids.has(objective_id):
				_add_diag(diags, "quest.objective.duplicate", "error", "Quest '%s' has duplicate objective id '%s'." % [quest_id, objective_id], "objective", "objective", objective_id, "id")
			objective_ids[objective_id] = true
			if String(objective.get("text", "")).strip_edges() == "":
				_add_diag(diags, "quest.objective.text", "error", "Quest '%s' objective '%s' has no text." % [quest_id, objective_id], "objective", "objective", objective_id, "text")
			var objective_flag := String(objective.get("flag", ""))
			if not is_valid_flag(objective_flag):
				_add_diag(diags, "quest.objective.flag", "error", "Quest '%s' objective '%s' has invalid flag '%s'." % [quest_id, objective_id, objective_flag], "objective", "objective", objective_id, "flag", "", "", -1, [objective_flag])
	var start_quest := String(draft.get("start_quest", ""))
	if start_quest == "" or not quests.has(start_quest):
		_add_diag(diags, "quest.start.missing", "error", "Campaign start quest '%s' does not exist." % start_quest, "quest", "campaign", campaign, "start_quest", "", "", -1, [start_quest])
	var completion_quest := String(draft.get("completion_quest", ""))
	if completion_quest != "" and not quests.has(completion_quest):
		_add_diag(diags, "quest.completion.missing", "error", "Campaign completion quest '%s' does not exist." % completion_quest, "quest", "campaign", campaign, "completion_quest", "", "", -1, [completion_quest])

	var encounters := encounters_of(draft)
	for raw_encounter_id in encounters.keys():
		var encounter_id := String(raw_encounter_id)
		var encounter: Dictionary = _as_dict(encounters[raw_encounter_id])
		if String(encounter.get("name", "")).strip_edges() == "":
			_add_diag(diags, "encounter.name.empty", "error", "Encounter '%s' has no name." % encounter_id, "encounter", "encounter", encounter_id, "name")
		var rows: Array = Array(encounter.get("rows", []))
		if rows.is_empty():
			_add_diag(diags, "encounter.rows.empty", "error", "Encounter '%s' has no battle map." % encounter_id, "encounter", "encounter", encounter_id, "rows")
			continue
		var width := String(rows[0]).length()
		var party_cells: Array = Array(encounter.get("party_cells", []))
		var monster_cells: Array = Array(encounter.get("monster_cells", []))
		if party_cells.size() < 4:
			_add_diag(diags, "encounter.party.cells", "error", "Encounter '%s' needs at least 4 party cells." % encounter_id, "encounter", "encounter", encounter_id, "party_cells")
		if monster_cells.size() < 1:
			_add_diag(diags, "encounter.monster.cells", "error", "Encounter '%s' has no monster cells." % encounter_id, "encounter", "encounter", encounter_id, "monster_cells")
		var monsters: Array = Array(encounter.get("monsters", []))
		if monsters.is_empty():
			_add_diag(diags, "encounter.monsters.empty", "error", "Encounter '%s' has no monsters." % encounter_id, "encounter", "encounter", encounter_id, "monsters")
		elif monsters.size() > MAX_ENCOUNTER_MONSTERS or monsters.size() > monster_cells.size():
			_add_diag(diags, "encounter.monsters.count", "error", "Encounter '%s' has more monsters than its layout allows." % encounter_id, "encounter", "encounter", encounter_id, "monsters")
		var used_cells := {}
		for pair in ["party_cells", "monster_cells"]:
			for raw_cell in Array(encounter.get(pair, [])):
				if not raw_cell is Array or Array(raw_cell).size() != 2:
					_add_diag(diags, "encounter.cell.malformed", "error", "Encounter '%s' %s has a malformed cell." % [encounter_id, pair], "encounter", "encounter", encounter_id, pair)
					continue
				var cell: Array = Array(raw_cell)
				if not _in_bounds(cell, width, rows.size()) or not _is_floor(rows, cell):
					_add_diag(diags, "encounter.cell.wall", "error", "Encounter '%s' %s cell %s is not walkable." % [encounter_id, pair, str(cell)], "encounter", "encounter", encounter_id, pair)
				var key := "%d,%d" % [int(cell[0]), int(cell[1])]
				if used_cells.has(key):
					_add_diag(diags, "encounter.cell.duplicate", "error", "Encounter '%s' uses cell %s more than once." % [encounter_id, str(cell)], "encounter", "encounter", encounter_id, pair)
				used_cells[key] = true
		if int(encounter.get("xp", 0)) < 0:
			_add_diag(diags, "encounter.xp.negative", "error", "Encounter '%s' has negative XP." % encounter_id, "encounter", "encounter", encounter_id, "xp")

	for raw_area in areas:
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		var area_id := String(area.get("id", "?"))
		var rows: Array = Array(area.get("rows", []))
		var width := String(rows[0]).length() if not rows.is_empty() else 0
		var occupied := {}
		var start_pos: Array = Array(Dictionary(area.get("start", {})).get("pos", []))
		if start_pos.size() == 2:
			occupied["%d,%d" % [int(start_pos[0]), int(start_pos[1])]] = "start"
		for key in ["objects", "doors", "npcs"]:
			for raw_entry in Array(area.get(key, [])):
				if raw_entry is Dictionary:
					var pos: Array = Array(Dictionary(raw_entry).get("pos", []))
					if pos.size() == 2:
						occupied["%d,%d" % [int(pos[0]), int(pos[1])]] = key
		var trigger_ids := {}
		for raw_trigger in Array(area.get("triggers", [])):
			if not raw_trigger is Dictionary:
				_add_diag(diags, "trigger.malformed", "error", "Area '%s' has a malformed trigger." % area_id, "trigger", "trigger", "", "triggers", area_id)
				continue
			var trigger: Dictionary = raw_trigger
			var trigger_id := String(trigger.get("id", ""))
			if not is_valid_id(trigger_id):
				_add_diag(diags, "trigger.id.invalid", "error", "Area '%s' trigger id '%s' is invalid." % [area_id, trigger_id], "trigger", "trigger", trigger_id, "id", area_id)
			elif trigger_ids.has(trigger_id):
				_add_diag(diags, "trigger.id.duplicate", "error", "Area '%s' has duplicate trigger id '%s'." % [area_id, trigger_id], "trigger", "trigger", trigger_id, "id", area_id)
			trigger_ids[trigger_id] = true
			var pos: Array = Array(trigger.get("pos", []))
			if pos.size() != 2 or not _in_bounds(pos, width, rows.size()) or not _is_floor(rows, pos):
				_add_diag(diags, "trigger.pos.wall", "error", "Area '%s' trigger '%s' is not on a floor cell." % [area_id, trigger_id], "trigger", "trigger", trigger_id, "pos", area_id)
				continue
			var key := "%d,%d" % [int(pos[0]), int(pos[1])]
			if occupied.has(key):
				_add_diag(diags, "trigger.pos.blocked", "error", "Area '%s' trigger '%s' overlaps %s." % [area_id, trigger_id, occupied[key]], "trigger", "trigger", trigger_id, "pos", area_id)
			occupied[key] = "trigger '%s'" % trigger_id
			var encounter_id := String(trigger.get("encounter", ""))
			if encounter_id != "" and not encounters.has(encounter_id):
				_add_diag(diags, "trigger.encounter.missing", "error", "Area '%s' trigger '%s' references missing encounter '%s'." % [area_id, trigger_id, encounter_id], "trigger", "trigger", trigger_id, "encounter", area_id, "", -1, [encounter_id])
			for key_name in ["requires_flag", "requires_flag_not"]:
				var guard := String(trigger.get(key_name, ""))
				if guard != "" and not is_valid_flag(guard):
					_add_diag(diags, "trigger.guard.invalid", "error", "Area '%s' trigger '%s' has invalid %s '%s'." % [area_id, trigger_id, key_name, guard], "trigger", "trigger", trigger_id, key_name, area_id, "", -1, [guard])
				elif guard != "" and not flag_defs.has(guard):
					_add_diag(diags, "trigger.guard.undeclared", "warning", "Trigger '%s' waits for undeclared flag '%s'; declared flags make the guard discoverable." % [trigger_id, guard], "trigger", "trigger", trigger_id, key_name, area_id, "", -1, [guard])
	var referenced_flags := _collect_flag_refs(draft)
	for raw_flag in flag_defs.keys():
		if not referenced_flags.has(String(raw_flag)):
			_add_diag(diags, "flag.unused", "warning", "Flag '%s' is declared but not referenced; unused declarations are allowed." % raw_flag, "flag", "flag", String(raw_flag), "flags")
	for key in ["items", "characters", "monsters"]:
		if not Array(draft.get(key, [])).is_empty():
			_add_diag(diags, "content.advanced.%s" % key, "warning", "%s are file-only content in this creator; edit the package JSON." % key.capitalize(), "advanced", key.trim_suffix("s"), "", key, "", "", -1, [], true)
	# Link context for navigation. Node/choice results carry their owning
	# dialogue first; objectives carry their owning quest first.
	for raw_dialogue_id in dialogues.keys():
		var dialogue_id := String(raw_dialogue_id)
		if not dialogues[raw_dialogue_id] is Dictionary:
			continue
		var nodes := Dictionary(Dictionary(dialogues[raw_dialogue_id]).get("nodes", {}))
		for diag in diags:
			var section := String(diag.get("section", ""))
			if section in ["node", "choice"] and nodes.has(String(diag.get("entity_id", ""))):
				Array(diag["refs"]).push_front(dialogue_id)
	for raw_quest_id in quests_of(draft).keys():
		var quest_id := String(raw_quest_id)
		var objective_ids := {}
		for raw_objective in Array(_as_dict(quests_of(draft)[raw_quest_id]).get("objectives", [])):
			if raw_objective is Dictionary:
				objective_ids[String(Dictionary(raw_objective).get("id", ""))] = true
		for diag in diags:
			if String(diag.get("section", "")) == "objective" and objective_ids.has(String(diag.get("entity_id", ""))):
				Array(diag["refs"]).push_front(quest_id)
	for diag in diags:
		diag["campaign"] = campaign
		if String(diag.get("source", "")) == "":
			diag["source"] = "user://campaigns/%s" % campaign
	return diags


static func _add_diag(
	diags: Array, code: String, severity: String, message: String, section: String,
	entity_type := "", entity_id := "", field := "", area_id := "", node_id := "",
	choice_index := -1, refs: Array = [], advanced := false
) -> void:
	diags.append(ContentDiagnostics.make(code, severity, message, {
		"entity_type": entity_type,
		"entity_id": entity_id,
		"field": field,
		"area_id": area_id,
		"node_id": node_id,
		"choice_index": choice_index,
		"section": section,
		"refs": refs,
		"advanced": advanced,
	}))


static func _collect_flag_refs(node: Variant, found := {}) -> Dictionary:
	if node is Dictionary:
		for key in Dictionary(node).keys():
			var key_name := String(key)
			if key_name in ["flag", "requires_flag", "requires_flag_not"]:
				found[String(Dictionary(node)[key])] = true
			else:
				_collect_flag_refs(Dictionary(node)[key], found)
	elif node is Array:
		for child in Array(node):
			_collect_flag_refs(child, found)
	return found


static func validate_draft_shape(draft: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var campaign_id := String(draft.get("id", ""))
	if not is_valid_id(campaign_id):
		errors.append("Campaign id is missing or invalid.")
	if is_bundled_id(campaign_id):
		errors.append("Campaign id '%s' belongs to a bundled campaign." % campaign_id)
	if String(draft.get("title", "")).strip_edges() == "":
		errors.append("Campaign title is empty.")
	var areas: Array = Array(draft.get("areas", []))
	if areas.is_empty():
		errors.append("The campaign has no areas.")
	# Collect every area id before checking travel targets: a passage may point
	# forward to an area that appears later in the list or was just added.
	var ids := {}
	var npc_ids := {}
	for raw_area in areas:
		if not raw_area is Dictionary:
			continue
		var listed_id := String(Dictionary(raw_area).get("id", ""))
		if listed_id == "":
			continue
		if ids.has(listed_id):
			errors.append("Duplicate area id '%s'." % listed_id)
		ids[listed_id] = true
	for raw_area in areas:
		if not raw_area is Dictionary:
			errors.append("An area entry is malformed.")
			continue
		var area: Dictionary = raw_area
		var area_id := String(area.get("id", ""))
		if area_id == "":
			errors.append("An area has no id.")
			continue
		var rows: Array = Array(area.get("rows", []))
		if rows.is_empty():
			errors.append("Area '%s' has no rows." % area_id)
			continue
		var width := String(rows[0]).length()
		for y in rows.size():
			if String(rows[y]).length() != width:
				errors.append("Area '%s' row %d is not %d cells wide." % [area_id, y, width])
				break
		var start: Dictionary = area.get("start", {})
		var pos: Array = Array(start.get("pos", []))
		if pos.size() != 2 or not _in_bounds(pos, width, rows.size()) or not _is_floor(rows, pos):
			errors.append("Area '%s' start position is not walkable." % area_id)
		for obj in Array(area.get("objects", [])):
			if not obj is Dictionary:
				continue
			var obj_pos: Array = Array(Dictionary(obj).get("pos", []))
			if obj_pos.size() != 2 or not _in_bounds(obj_pos, width, rows.size()):
				errors.append("Area '%s' object '%s' is outside the map." % [area_id, Dictionary(obj).get("id", "?")])
			for interaction in Array(Dictionary(obj).get("interactions", [])):
				for effect in Array(Dictionary(interaction).get("effects", [])):
					if not effect is Dictionary:
						continue
					if String(Dictionary(effect).get("type", "")) != "travel":
						continue
					var target_area := String(Dictionary(effect).get("area", ""))
					if target_area == "" or not ids.has(target_area):
						errors.append("Area '%s' links to missing area '%s'." % [area_id, target_area])
						continue
					var target_pos: Array = Array(Dictionary(effect).get("pos", []))
					var target_rows := _rows_for(areas, target_area)
					var target_width := String(target_rows[0]).length() if not target_rows.is_empty() else 0
					if target_pos.size() != 2 or not _in_bounds(target_pos, target_width, target_rows.size()) or not _is_floor(target_rows, target_pos):
						errors.append("Area '%s' travel target in '%s' is not walkable." % [area_id, target_area])
		for raw_npc in Array(area.get("npcs", [])):
			if not raw_npc is Dictionary:
				errors.append("Area '%s' has a malformed NPC." % area_id)
				continue
			var npc: Dictionary = raw_npc
			var npc_id := String(npc.get("id", ""))
			if not is_valid_id(npc_id):
				errors.append("NPC id '%s' is invalid; use lowercase letters, digits and underscores." % npc_id)
			elif npc_ids.has(npc_id):
				errors.append("Duplicate NPC id '%s' (already placed in '%s')." % [npc_id, npc_ids[npc_id]])
			npc_ids[npc_id] = area_id
			if String(npc.get("name", "")).strip_edges() == "":
				errors.append("NPC '%s' has no display name." % npc_id)
			var npc_pos: Array = Array(npc.get("pos", []))
			if npc_pos.size() != 2 or not _in_bounds(npc_pos, width, rows.size()) or not _is_floor(rows, npc_pos):
				errors.append("NPC '%s' does not stand on a floor cell." % npc_id)
			elif _area_feature_at(area, npc_pos):
				errors.append("NPC '%s' stands on a cell already used by the start, an object, a door or a trigger." % npc_id)
			var npc_dialogue := String(npc.get("dialogue", ""))
			if npc_dialogue != "" and not Dictionary(draft.get("dialogues", {})).has(npc_dialogue):
				errors.append("NPC '%s' references missing dialogue '%s'." % [npc_id, npc_dialogue])
	var entry: Dictionary = draft.get("entry", {})
	var entry_area := String(entry.get("area", ""))
	if entry_area == "":
		errors.append("Set an entry area.")
	elif not ids.has(entry_area):
		errors.append("Entry area '%s' does not exist." % entry_area)
	else:
		var entry_rows := _rows_for(areas, entry_area)
		var entry_width := String(entry_rows[0]).length() if not entry_rows.is_empty() else 0
		var entry_pos: Array = Array(entry.get("pos", []))
		if entry_pos.size() != 2 or not _in_bounds(entry_pos, entry_width, entry_rows.size()) or not _is_floor(entry_rows, entry_pos):
			errors.append("Entry position in '%s' is not walkable." % entry_area)
	var facing := int(entry.get("facing", 0))
	if facing < 0 or facing > 3:
		errors.append("Entry facing must be north, east, south or west.")
	if String(draft.get("start_quest", "")) == "":
		errors.append("The campaign has no starting quest.")
	var entry_cell: Array = Array(entry.get("pos", []))
	if ids.has(entry_area):
		for raw_npc in Array(area_by_id(draft, entry_area).get("npcs", [])):
			if raw_npc is Dictionary and _same_cell(Array(Dictionary(raw_npc).get("pos", [])), entry_cell):
				errors.append("NPC '%s' stands on the campaign entry cell." % Dictionary(raw_npc).get("id", "?"))
	var dialogues: Dictionary = Dictionary(draft.get("dialogues", {}))
	for raw_dialogue_id in dialogues.keys():
		var dialogue_key := String(raw_dialogue_id)
		var raw_dialogue: Variant = dialogues[raw_dialogue_id]
		if not raw_dialogue is Dictionary:
			errors.append("Dialogue '%s' is malformed." % dialogue_key)
			continue
		_validate_dialogue_shape(Dictionary(raw_dialogue), dialogue_key, draft, errors)
	_validate_quest_and_encounter_shape(draft, errors)
	return errors


## Structural dialogue checks used by the creator and by every save. They allow
## cycles but report orphaned nodes so a broken conversation cannot be saved.
static func _validate_dialogue_shape(
	dialogue: Dictionary, dialogue_id: String, draft: Dictionary, errors: Array[String]
) -> void:
	if not is_valid_id(dialogue_id):
		errors.append("Dialogue id '%s' is invalid." % dialogue_id)
	if String(dialogue.get("speaker", "")).strip_edges() == "":
		errors.append("Dialogue '%s' has no speaker name." % dialogue_id)
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	if nodes.is_empty():
		errors.append("Dialogue '%s' has no nodes." % dialogue_id)
		return
	var start := String(dialogue.get("start", ""))
	if start == "":
		errors.append("Dialogue '%s' has no start node." % dialogue_id)
	elif not nodes.has(start):
		errors.append("Dialogue '%s' start node '%s' does not exist." % [dialogue_id, start])
	var allowed_actors := {"best": true}
	for raw_actor in Array(Dictionary(draft.get("party", {})).get("default", [])):
		allowed_actors[String(raw_actor)] = true
	for raw_node_id in nodes.keys():
		var node_id := String(raw_node_id)
		var raw_node: Variant = nodes[raw_node_id]
		if not raw_node is Dictionary:
			errors.append("Dialogue '%s' node '%s' is malformed." % [dialogue_id, node_id])
			continue
		var node: Dictionary = raw_node
		var label := "Dialogue '%s' node '%s'" % [dialogue_id, node_id]
		if not is_valid_id(node_id):
			errors.append("%s has an invalid id." % label)
		if String(node.get("text", "")).strip_edges() == "":
			errors.append("%s has no text." % label)
		var next_id := String(node.get("next", ""))
		if next_id != "" and not nodes.has(next_id):
			errors.append("%s links to missing node '%s'." % [label, next_id])
		errors.append_array(_prefixed(label, ContentSpec.validate_effect_list(Array(node.get("effects", [])), null)))
		var choices: Array = Array(node.get("choices", []))
		for i in choices.size():
			var raw_choice: Variant = choices[i]
			if not raw_choice is Dictionary:
				errors.append("%s choice %d is malformed." % [label, i + 1])
				continue
			var choice: Dictionary = raw_choice
			var choice_label := "%s choice %d" % [label, i + 1]
			if String(choice.get("text", "")).strip_edges() == "":
				errors.append("%s has no text." % choice_label)
			errors.append_array(
				_prefixed(choice_label, ContentSpec.validate_condition_list(Array(choice.get("conditions", [])), null))
			)
			errors.append_array(_prefixed(choice_label, ContentSpec.validate_effect_list(Array(choice.get("effects", [])), null)))
			if choice.has("check"):
				if not choice["check"] is Dictionary:
					errors.append("%s check is malformed." % choice_label)
					continue
				var check: Dictionary = choice["check"]
				var skill := String(check.get("skill", ""))
				if not Skills.exists(skill):
					errors.append("%s uses unknown skill '%s'." % [choice_label, skill])
				var dc := int(check.get("dc", 0))
				if dc < 1 or dc > 60:
					errors.append("%s DC must be between 1 and 60." % choice_label)
				var actor := String(check.get("actor", "best"))
				if not allowed_actors.has(actor):
					errors.append("%s rolls as '%s', which is not in the campaign party." % [choice_label, actor])
				for branch in ["success", "failure"]:
					var dest := String(check.get(branch, ""))
					if dest == "" or not nodes.has(dest):
						errors.append("%s %s destination '%s' does not exist." % [choice_label, branch, dest])
			else:
				var dest := String(choice.get("next", ""))
				if dest != "" and not nodes.has(dest):
					errors.append("%s links to missing node '%s'." % [choice_label, dest])
	# Cycles are legitimate conversation loops; only nodes that cannot be reached
	# from the start at all are reported.
	if nodes.has(start):
		var reachable := {start: true}
		var queue: Array[String] = [start]
		while not queue.is_empty():
			var current: String = queue.pop_front()
			var node: Dictionary = nodes[current]
			var targets: Array[String] = [String(node.get("next", ""))]
			for raw_choice in Array(node.get("choices", [])):
				if not raw_choice is Dictionary:
					continue
				var choice: Dictionary = raw_choice
				if choice.get("check") is Dictionary:
					var check: Dictionary = choice["check"]
					targets.append(String(check.get("success", "")))
					targets.append(String(check.get("failure", "")))
				else:
					targets.append(String(choice.get("next", "")))
			for target in targets:
				if target != "" and nodes.has(target) and not reachable.has(target):
					reachable[target] = true
					queue.append(target)
		var orphans: Array[String] = []
		for raw_node_id in nodes.keys():
			if not reachable.has(String(raw_node_id)):
				orphans.append(String(raw_node_id))
		if not orphans.is_empty():
			orphans.sort()
			errors.append("Dialogue '%s' has unreachable node(s): %s." % [dialogue_id, ", ".join(orphans)])


static func _prefixed(label: String, messages: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for message in messages:
		result.append("%s %s" % [label, message])
	return result


static func _same_cell(a: Array, b: Array) -> bool:
	return a.size() == 2 and b.size() == 2 and int(a[0]) == int(b[0]) and int(a[1]) == int(b[1])


static func _area_feature_at(area: Dictionary, pos: Array) -> bool:
	var start: Dictionary = area.get("start", {})
	if _same_cell(Array(start.get("pos", [])), pos):
		return true
	for key in ["objects", "doors", "triggers"]:
		for raw_entry in Array(area.get(key, [])):
			if raw_entry is Dictionary and _same_cell(Array(Dictionary(raw_entry).get("pos", [])), pos):
				return true
	return false


static func _rows_for(areas: Array, area_id: String) -> Array:
	for raw_area in areas:
		if raw_area is Dictionary and String(Dictionary(raw_area).get("id", "")) == area_id:
			return Array(Dictionary(raw_area).get("rows", []))
	return []


static func _in_bounds(pos: Array, width: int, height: int) -> bool:
	return int(pos[0]) >= 0 and int(pos[1]) >= 0 and int(pos[0]) < width and int(pos[1]) < height


static func _is_floor(rows: Array, pos: Array) -> bool:
	if rows.is_empty() or pos.size() != 2:
		return false
	var y := int(pos[1])
	var x := int(pos[0])
	if y < 0 or y >= rows.size():
		return false
	var row := String(rows[y])
	return x >= 0 and x < row.length() and row[x] != "#"


## Full validation: shape first, then a temporary copy is written outside the
## real package and loaded through the same ContentDB the game uses. The real
## draft files are not touched.
static func validate_draft(draft: Dictionary) -> Dictionary:
	var shape_errors := validate_draft_shape(draft)
	if not shape_errors.is_empty():
		return {"ok": false, "errors": shape_errors}
	var campaign_id := String(draft.get("id", ""))
	var temp_dir := USER_ROOT.path_join(".draft_" + campaign_id)
	_remove_tree(temp_dir)
	var manifest: Dictionary = draft.duplicate(true)
	manifest.erase("areas")
	manifest.erase("quests")
	manifest.erase("encounters")
	manifest.erase("narration")
	manifest.erase("dialogues")
	manifest["content_root"] = temp_dir
	var write_errors := _write_files(draft, temp_dir, manifest)
	if not write_errors.is_empty():
		_remove_tree(temp_dir)
		return {"ok": false, "errors": write_errors}
	var db := ContentDB.new()
	db.load_campaign(manifest)
	var errors: Array[String] = db.errors.duplicate()
	_remove_tree(temp_dir)
	return {"ok": errors.is_empty(), "errors": errors}


# ------------------------------------------------------------------ writing

static func write_package(draft: Dictionary) -> Dictionary:
	var shape_errors := validate_draft_shape(draft)
	if not shape_errors.is_empty():
		return {"ok": false, "message": shape_errors[0], "errors": shape_errors}
	var full := validate_draft(draft)
	if not bool(full.get("ok", false)):
		var errors: Array = full.get("errors", [])
		return {
			"ok": false,
			"message": String(errors[0]) if not errors.is_empty() else "The draft is invalid.",
			"errors": errors,
		}
	var campaign_id := String(draft.get("id", ""))
	var dir := package_dir(campaign_id)
	if not DirAccess.make_dir_recursive_absolute(dir.path_join("areas")) == OK:
		return {"ok": false, "message": "Could not create the campaign directory.", "errors": ["Could not create %s." % dir]}
	var manifest: Dictionary = draft.duplicate(true)
	manifest.erase("areas")
	manifest.erase("quests")
	manifest.erase("encounters")
	manifest.erase("narration")
	manifest.erase("dialogues")
	manifest["content_root"] = dir
	var errors := _write_files(draft, dir, manifest)
	if not errors.is_empty():
		return {"ok": false, "message": errors[0], "errors": errors}
	return {"ok": true, "message": "Saved campaign '%s'." % campaign_id, "errors": []}


static func _write_files(draft: Dictionary, dir: String, manifest: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not DirAccess.make_dir_recursive_absolute(dir.path_join("areas")) == OK:
		return ["Could not create %s." % dir.path_join("areas")]
	errors.append_array(_write_json(dir.path_join("campaign.json"), manifest))
	errors.append_array(_write_json(dir.path_join("quests.json"), Dictionary(draft.get("quests", {}))))
	errors.append_array(_write_json(dir.path_join("encounters.json"), Dictionary(draft.get("encounters", {}))))
	errors.append_array(_write_json(dir.path_join("narration.json"), Dictionary(draft.get("narration", {}))))
	errors.append_array(_write_dialogue_files(draft, dir))
	var kept := {}
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		var area_id := String(area.get("id", ""))
		if area_id == "":
			continue
		kept[area_id] = true
		errors.append_array(_write_json(dir.path_join("areas").path_join(area_id + ".json"), area))
	# Remove area files that are no longer part of the draft. Only files directly
	# inside this package's areas directory are considered.
	var area_dir := dir.path_join("areas")
	if DirAccess.dir_exists_absolute(area_dir):
		for file_name in DirAccess.get_files_at(area_dir):
			var file_string := String(file_name)
			if not file_string.ends_with(".json"):
				continue
			if not kept.has(file_string.get_basename()):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(area_dir.path_join(file_string)))
	return errors


static func _write_json(path: String, data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var text := JSON.stringify(data, "\t")
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return ["Refusing to write malformed JSON to %s." % path]
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return ["Could not open %s for writing." % temp_path]
	file.store_string(text)
	file.close()
	var had_existing := FileAccess.file_exists(path)
	if had_existing:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path)) != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			return ["Could not stage %s for replacement." % path]
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		if had_existing and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path))
		return ["Could not commit %s; the previous file was restored." % path]
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	return errors


# ------------------------------------------------------------------ draft edits
#
# The creator screen and the automated probe both call these; they contain no
# presentation state, so the workflow can be exercised without a window.

static func delete_user_campaign(campaign_id: String) -> void:
	if is_valid_id(campaign_id) and not is_bundled_id(campaign_id):
		_remove_tree(package_dir(campaign_id))


static func next_area_id(draft: Dictionary) -> String:
	var used := {}
	for raw_area in Array(draft.get("areas", [])):
		if raw_area is Dictionary:
			used[String(Dictionary(raw_area).get("id", ""))] = true
	var index := 1
	while used.has("area_%02d" % index):
		index += 1
	return "area_%02d" % index


static func add_area(draft: Dictionary, name := "New Area") -> Dictionary:
	var area_id := next_area_id(draft)
	var rows: Array[String] = []
	for y in AREA_HEIGHT:
		var line := ""
		for x in AREA_WIDTH:
			var border := x == 0 or y == 0 or x == AREA_WIDTH - 1 or y == AREA_HEIGHT - 1
			line += "#" if border else "."
		rows.append(line)
	var area := {
		"id": area_id,
		"name": name,
		"ambient": "(USER CAMPAIGN — PLACEHOLDER PROSE)",
		"tracker_quest": String(draft.get("start_quest", "")),
		"rows": rows,
		"start": {"pos": [4, 4], "facing": 0},
		"doors": [],
		"npcs": [],
		"objects": [],
		"triggers": [],
	}
	var areas: Array = Array(draft.get("areas", []))
	areas.append(area)
	draft["areas"] = areas
	return area


static func area_by_id(draft: Dictionary, area_id: String) -> Dictionary:
	for raw_area in Array(draft.get("areas", [])):
		if raw_area is Dictionary and String(Dictionary(raw_area).get("id", "")) == area_id:
			return Dictionary(raw_area)
	return {}


static func set_area_cell(draft: Dictionary, area_id: String, pos: Vector2i, wall: bool) -> bool:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return false
	var rows: Array = Array(area.get("rows", []))
	if pos.y < 0 or pos.y >= rows.size():
		return false
	var row := String(rows[pos.y])
	if pos.x < 0 or pos.x >= row.length():
		return false
	var width := row.length()
	var border := pos.x == 0 or pos.y == 0 or pos.x == width - 1 or pos.y == rows.size() - 1
	if border:
		return false
	rows[pos.y] = row.substr(0, pos.x) + ("#" if wall else ".") + row.substr(pos.x + 1)
	area["rows"] = rows
	return true


static func set_entry(draft: Dictionary, area_id: String, pos: Vector2i, facing: int) -> Dictionary:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return {"ok": false, "message": "Unknown area."}
	var rows: Array = Array(area.get("rows", []))
	if rows.is_empty() or pos.y < 0 or pos.y >= rows.size():
		return {"ok": false, "message": "Entry cell is outside the area."}
	var row := String(rows[pos.y])
	if pos.x < 0 or pos.x >= row.length() or row[pos.x] == "#":
		return {"ok": false, "message": "Entry cell must be a floor cell."}
	draft["entry"] = {"area": area_id, "pos": [pos.x, pos.y], "facing": clampi(facing, 0, 3)}
	area["start"] = {"pos": [pos.x, pos.y], "facing": clampi(facing, 0, 3)}
	return {"ok": true, "message": "Entry set to %s (%d, %d)." % [area_id, pos.x, pos.y]}


static func add_transition(draft: Dictionary, from_area_id: String, pos: Vector2i, to_area_id: String) -> Dictionary:
	var source := area_by_id(draft, from_area_id)
	var target := area_by_id(draft, to_area_id)
	if source.is_empty() or target.is_empty():
		return {"ok": false, "message": "Both areas must exist."}
	if from_area_id == to_area_id:
		return {"ok": false, "message": "Choose a different destination area."}
	var rows: Array = Array(source.get("rows", []))
	if rows.is_empty() or pos.y < 0 or pos.y >= rows.size():
		return {"ok": false, "message": "Choose a floor cell for the passage."}
	var row := String(rows[pos.y])
	if pos.x < 0 or pos.x >= row.length() or row[pos.x] == "#":
		return {"ok": false, "message": "A wall cannot hold a passage; choose a floor cell."}
	var target_start: Dictionary = target.get("start", {})
	var target_pos: Array = Array(target_start.get("pos", [4, 4]))
	var target_facing := int(target_start.get("facing", 0))
	var objects: Array = Array(source.get("objects", []))
	for i in objects.size():
		var obj: Dictionary = objects[i]
		var obj_pos: Array = Array(obj.get("pos", []))
		if obj_pos.size() != 2 or int(obj_pos[0]) != pos.x or int(obj_pos[1]) != pos.y:
			continue
		if not _is_travel_object(obj):
			return {"ok": false, "message": "That cell already holds a non-travel object."}
		objects[i] = _make_transition_object(source, target, pos, target_pos, target_facing, i + 1)
		source["objects"] = objects
		return {"ok": true, "message": "Passage updated to %s." % target.get("name", to_area_id)}
	objects.append(_make_transition_object(source, target, pos, target_pos, target_facing, objects.size() + 1))
	source["objects"] = objects
	return {"ok": true, "message": "Passage added to %s." % target.get("name", to_area_id)}


static func _is_travel_object(obj: Dictionary) -> bool:
	for raw_interaction in Array(obj.get("interactions", [])):
		if not raw_interaction is Dictionary:
			continue
		for raw_effect in Array(Dictionary(raw_interaction).get("effects", [])):
			if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "travel":
				return true
	return false


static func _make_transition_object(
	source: Dictionary, target: Dictionary, pos: Vector2i, target_pos: Array, target_facing: int, index: int
) -> Dictionary:
	var object_id := "link_%02d" % index
	var target_name := String(target.get("name", target.get("id", "area")))
	# Keep ids unique even if an earlier passage was removed by hand.
	var used := {}
	for raw_object in Array(source.get("objects", [])):
		if raw_object is Dictionary:
			used[String(Dictionary(raw_object).get("id", ""))] = true
	var suffix := index
	while used.has(object_id) and object_id != "link_%02d" % index:
		suffix += 1
		object_id = "link_%02d" % suffix
	return {
		"id": object_id,
		"name": "Passage to %s" % target_name,
		"pos": [pos.x, pos.y],
		"look": "(USER CAMPAIGN) A marked passage toward %s." % target_name,
		"interactions": [
			{
				"id": "travel",
				"label": "Travel to %s" % target_name,
				"success_text": "You travel to %s." % target_name,
				"effects": [
					{"type": "travel", "area": String(target.get("id", "")), "pos": target_pos, "facing": target_facing}
				],
			}
		],
	}


# ------------------------------------------------------------------ NPCs

static func npcs_of(draft: Dictionary, area_id: String) -> Array:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return []
	return Array(area.get("npcs", []))


static func find_npc(draft: Dictionary, area_id: String, npc_id: String) -> Dictionary:
	for raw_npc in npcs_of(draft, area_id):
		if raw_npc is Dictionary and String(Dictionary(raw_npc).get("id", "")) == npc_id:
			return Dictionary(raw_npc)
	return {}


static func npc_id_taken(draft: Dictionary, npc_id: String) -> bool:
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		for raw_npc in Array(Dictionary(raw_area).get("npcs", [])):
			if raw_npc is Dictionary and String(Dictionary(raw_npc).get("id", "")) == npc_id:
				return true
	return false


static func next_npc_id(draft: Dictionary) -> String:
	var index := 1
	while npc_id_taken(draft, "npc_%02d" % index):
		index += 1
	return "npc_%02d" % index


static func _cell_blocked(draft: Dictionary, area: Dictionary, pos: Array, ignore_npc: String = "") -> bool:
	var entry: Dictionary = draft.get("entry", {})
	if String(entry.get("area", "")) == String(area.get("id", "")) and _same_cell(Array(entry.get("pos", [])), pos):
		return true
	if _area_feature_at(area, pos):
		return true
	for raw_npc in Array(area.get("npcs", [])):
		if not raw_npc is Dictionary:
			continue
		var npc: Dictionary = raw_npc
		if String(npc.get("id", "")) != ignore_npc and _same_cell(Array(npc.get("pos", [])), pos):
			return true
	return false


static func place_npc(
	draft: Dictionary,
	area_id: String,
	pos: Vector2i,
	npc_id: String,
	display_name: String,
	look: String,
	dialogue_id: String
) -> Dictionary:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return {"ok": false, "message": "Select an existing area first."}
	if not is_valid_id(npc_id):
		return {"ok": false, "message": "NPC id must be 2-%d lowercase letters, digits or underscores, starting with a letter." % MAX_ID_LENGTH}
	if npc_id_taken(draft, npc_id):
		return {"ok": false, "message": "NPC id '%s' is already used in this campaign." % npc_id}
	if display_name.strip_edges() == "":
		return {"ok": false, "message": "Enter a display name for the NPC."}
	var cell := [pos.x, pos.y]
	var rows: Array = Array(area.get("rows", []))
	if rows.is_empty() or not _in_bounds(cell, String(rows[0]).length(), rows.size()) or not _is_floor(rows, cell):
		return {"ok": false, "message": "Choose a floor cell inside the area."}
	if _cell_blocked(draft, area, cell):
		return {"ok": false, "message": "That cell already holds the entry, an NPC, an object, a door or a trigger."}
	if dialogue_id != "" and not Dictionary(draft.get("dialogues", {})).has(dialogue_id):
		return {"ok": false, "message": "Dialogue '%s' does not exist." % dialogue_id}
	var npcs: Array = Array(area.get("npcs", []))
	npcs.append({
		"id": npc_id,
		"name": display_name.strip_edges(),
		"pos": cell,
		"look": look.strip_edges(),
		"dialogue": dialogue_id,
		"sprite": "npc",
	})
	area["npcs"] = npcs
	return {"ok": true, "message": "Placed NPC '%s' at (%d, %d)." % [npc_id, pos.x, pos.y], "id": npc_id}


static func move_npc(draft: Dictionary, area_id: String, npc_id: String, pos: Vector2i) -> Dictionary:
	var area := area_by_id(draft, area_id)
	var npc := find_npc(draft, area_id, npc_id)
	if area.is_empty() or npc.is_empty():
		return {"ok": false, "message": "Select an NPC first."}
	var cell := [pos.x, pos.y]
	var rows: Array = Array(area.get("rows", []))
	if rows.is_empty() or not _in_bounds(cell, String(rows[0]).length(), rows.size()) or not _is_floor(rows, cell):
		return {"ok": false, "message": "Choose a floor cell inside the area."}
	if _cell_blocked(draft, area, cell, npc_id):
		return {"ok": false, "message": "That cell already holds the entry, an NPC, an object, a door or a trigger."}
	var npcs: Array = Array(area.get("npcs", []))
	for i in npcs.size():
		if npcs[i] is Dictionary and String(Dictionary(npcs[i]).get("id", "")) == npc_id:
			var updated: Dictionary = Dictionary(npcs[i]).duplicate(true)
			updated["pos"] = cell
			npcs[i] = updated
			area["npcs"] = npcs
			return {"ok": true, "message": "Moved '%s' to (%d, %d)." % [npc_id, pos.x, pos.y]}
	return {"ok": false, "message": "NPC '%s' is not in this area." % npc_id}


static func update_npc(
	draft: Dictionary, area_id: String, npc_id: String, display_name: String, look: String, dialogue_id: String
) -> Dictionary:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return {"ok": false, "message": "Select an existing area first."}
	if display_name.strip_edges() == "":
		return {"ok": false, "message": "Enter a display name for the NPC."}
	var npcs: Array = Array(area.get("npcs", []))
	var existing_dialogue := ""
	var found := false
	for raw_npc in npcs:
		if raw_npc is Dictionary and String(Dictionary(raw_npc).get("id", "")) == npc_id:
			existing_dialogue = String(Dictionary(raw_npc).get("dialogue", ""))
			found = true
			break
	if not found:
		return {"ok": false, "message": "NPC '%s' is not in this area." % npc_id}
	# Preserve an already-invalid stored reference while editing unrelated fields;
	# only an intentional new missing id is refused.
	if dialogue_id != "" and not Dictionary(draft.get("dialogues", {})).has(dialogue_id) and dialogue_id != existing_dialogue:
		return {"ok": false, "message": "Dialogue '%s' does not exist." % dialogue_id}
	for i in npcs.size():
		if not npcs[i] is Dictionary or String(Dictionary(npcs[i]).get("id", "")) != npc_id:
			continue
		var updated: Dictionary = Dictionary(npcs[i]).duplicate(true)
		updated["name"] = display_name.strip_edges()
		updated["look"] = look.strip_edges()
		updated["dialogue"] = dialogue_id
		npcs[i] = updated
		area["npcs"] = npcs
		return {"ok": true, "message": "Updated NPC '%s'." % npc_id}
	return {"ok": false, "message": "NPC '%s' is not in this area." % npc_id}


static func rename_npc(draft: Dictionary, area_id: String, old_id: String, new_id: String) -> Dictionary:
	if not is_valid_id(new_id):
		return {"ok": false, "message": "NPC id must be 2-%d lowercase letters, digits or underscores." % MAX_ID_LENGTH}
	if new_id == old_id:
		return {"ok": true, "message": "NPC id unchanged."}
	if npc_id_taken(draft, new_id):
		return {"ok": false, "message": "NPC id '%s' is already used in this campaign." % new_id}
	var area := area_by_id(draft, area_id)
	var npcs: Array = Array(area.get("npcs", []))
	for i in npcs.size():
		if not npcs[i] is Dictionary or String(Dictionary(npcs[i]).get("id", "")) != old_id:
			continue
		var updated: Dictionary = Dictionary(npcs[i]).duplicate(true)
		updated["id"] = new_id
		npcs[i] = updated
		area["npcs"] = npcs
		return {"ok": true, "message": "Renamed NPC '%s' to '%s'." % [old_id, new_id], "id": new_id}
	return {"ok": false, "message": "NPC '%s' is not in this area." % old_id}


## Removing a placement never removes the conversation. The message says what
## was kept so the player can delete the dialogue separately if they want to.
static func remove_npc(draft: Dictionary, area_id: String, npc_id: String) -> Dictionary:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return {"ok": false, "message": "Select an existing area first."}
	var npcs: Array = Array(area.get("npcs", []))
	for i in npcs.size():
		if not npcs[i] is Dictionary or String(Dictionary(npcs[i]).get("id", "")) != npc_id:
			continue
		var dialogue_id := String(Dictionary(npcs[i]).get("dialogue", ""))
		npcs.remove_at(i)
		area["npcs"] = npcs
		var kept := ""
		if dialogue_id != "" and Dictionary(draft.get("dialogues", {})).has(dialogue_id):
			kept = " Its dialogue '%s' was kept." % dialogue_id
		return {"ok": true, "message": "Removed NPC '%s'.%s" % [npc_id, kept]}
	return {"ok": false, "message": "NPC '%s' is not in this area." % npc_id}


# ------------------------------------------------------------------ dialogues

static func dialogues_of(draft: Dictionary) -> Dictionary:
	return Dictionary(draft.get("dialogues", {}))


static func dialogue_by_id(draft: Dictionary, dialogue_id: String) -> Dictionary:
	return Dictionary(dialogues_of(draft).get(dialogue_id, {}))


static func next_dialogue_id(draft: Dictionary) -> String:
	var index := 1
	while dialogues_of(draft).has("dialogue_%02d" % index):
		index += 1
	return "dialogue_%02d" % index


static func add_dialogue(draft: Dictionary, dialogue_id: String, speaker_name: String) -> Dictionary:
	if not is_valid_id(dialogue_id):
		return {"ok": false, "message": "Dialogue id must be 2-%d lowercase letters, digits or underscores." % MAX_ID_LENGTH}
	var dialogues := dialogues_of(draft)
	if dialogues.has(dialogue_id):
		return {"ok": false, "message": "Dialogue '%s' already exists." % dialogue_id}
	var clean_speaker := speaker_name.strip_edges()
	if clean_speaker == "":
		return {"ok": false, "message": "Enter a speaker name."}
	dialogues[dialogue_id] = {
		"id": dialogue_id,
		"speaker": clean_speaker,
		"start": "start",
		"nodes": {
			"start": {
				"speaker": "npc",
				"speaker_name": clean_speaker,
				"text": "(USER CAMPAIGN) %s looks at you, waiting for you to speak." % clean_speaker,
				"next": "",
			},
		},
	}
	draft["dialogues"] = dialogues
	return {"ok": true, "message": "Created dialogue '%s'." % dialogue_id, "id": dialogue_id}


static func dialogue_references(draft: Dictionary, dialogue_id: String) -> Array[String]:
	var result: Array[String] = []
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		for raw_npc in Array(area.get("npcs", [])):
			if raw_npc is Dictionary and String(Dictionary(raw_npc).get("dialogue", "")) == dialogue_id:
				result.append("area '%s' NPC '%s'" % [area.get("id", "?"), Dictionary(raw_npc).get("id", "?")])
	return result


static func rename_dialogue(draft: Dictionary, old_id: String, new_id: String) -> Dictionary:
	if not is_valid_id(new_id):
		return {"ok": false, "message": "Dialogue id must be 2-%d lowercase letters, digits or underscores." % MAX_ID_LENGTH}
	if new_id == old_id:
		return {"ok": true, "message": "Dialogue id unchanged."}
	var dialogues := dialogues_of(draft)
	if not dialogues.has(old_id):
		return {"ok": false, "message": "Dialogue '%s' does not exist." % old_id}
	if dialogues.has(new_id):
		return {"ok": false, "message": "Dialogue '%s' already exists." % new_id}
	var moved: Dictionary = Dictionary(dialogues[old_id]).duplicate(true)
	moved["id"] = new_id
	dialogues.erase(old_id)
	dialogues[new_id] = moved
	draft["dialogues"] = dialogues
	var updated := 0
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		var npcs: Array = Array(area.get("npcs", []))
		var changed := false
		for i in npcs.size():
			if not npcs[i] is Dictionary:
				continue
			var npc: Dictionary = Dictionary(npcs[i]).duplicate(true)
			if String(npc.get("dialogue", "")) != old_id:
				continue
			npc["dialogue"] = new_id
			npcs[i] = npc
			changed = true
			updated += 1
		if changed:
			area["npcs"] = npcs
	var note := ""
	if updated > 0:
		note = " Updated %d NPC reference(s)." % updated
	return {"ok": true, "message": "Renamed dialogue '%s' to '%s'.%s" % [old_id, new_id, note], "id": new_id}


static func delete_dialogue(draft: Dictionary, dialogue_id: String) -> Dictionary:
	var dialogues := dialogues_of(draft)
	if not dialogues.has(dialogue_id):
		return {"ok": false, "message": "Dialogue '%s' does not exist." % dialogue_id}
	var refs := dialogue_references(draft, dialogue_id)
	if not refs.is_empty():
		return {
			"ok": false,
			"message": "Cannot delete dialogue '%s'; still referenced by %s." % [dialogue_id, ", ".join(refs)],
			"references": refs,
		}
	dialogues.erase(dialogue_id)
	draft["dialogues"] = dialogues
	return {"ok": true, "message": "Deleted dialogue '%s'." % dialogue_id}


static func next_node_id(dialogue: Dictionary) -> String:
	var nodes := Dictionary(dialogue.get("nodes", {}))
	var index := 1
	while nodes.has("node_%02d" % index):
		index += 1
	return "node_%02d" % index


static func set_dialogue_start(draft: Dictionary, dialogue_id: String, node_id: String) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	if dialogue.is_empty():
		return {"ok": false, "message": "Dialogue '%s' does not exist." % dialogue_id}
	if not Dictionary(dialogue.get("nodes", {})).has(node_id):
		return {"ok": false, "message": "Node '%s' does not exist." % node_id}
	dialogue["start"] = node_id
	return {"ok": true, "message": "Start node is now '%s'." % node_id}


static func add_dialogue_node(draft: Dictionary, dialogue_id: String) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	if dialogue.is_empty():
		return {"ok": false, "message": "Select a dialogue first."}
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	var node_id := next_node_id(dialogue)
	var speaker := String(dialogue.get("speaker", "the speaker"))
	nodes[node_id] = {
		"speaker": "npc",
		"speaker_name": speaker,
		"text": "(USER CAMPAIGN) %s says something new." % speaker,
		"next": "",
	}
	dialogue["nodes"] = nodes
	return {"ok": true, "message": "Added node '%s'." % node_id, "id": node_id}


static func node_references(dialogue: Dictionary, node_id: String) -> Array[String]:
	var result: Array[String] = []
	if String(dialogue.get("start", "")) == node_id:
		result.append("the start node")
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	for raw_node_id in nodes.keys():
		var source_id := String(raw_node_id)
		var node: Dictionary = Dictionary(nodes[raw_node_id])
		if String(node.get("next", "")) == node_id:
			result.append("node '%s' next" % source_id)
		var choices: Array = Array(node.get("choices", []))
		for i in choices.size():
			if not choices[i] is Dictionary:
				continue
			var choice: Dictionary = choices[i]
			if String(choice.get("next", "")) == node_id:
				result.append("node '%s' choice %d" % [source_id, i + 1])
			var check: Dictionary = Dictionary(choice.get("check", {}))
			for branch in ["success", "failure"]:
				if String(check.get(branch, "")) == node_id:
					result.append("node '%s' choice %d %s" % [source_id, i + 1, branch])
	return result


static func rename_dialogue_node(draft: Dictionary, dialogue_id: String, old_id: String, new_id: String) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	if dialogue.is_empty():
		return {"ok": false, "message": "Dialogue '%s' does not exist." % dialogue_id}
	if not is_valid_id(new_id):
		return {"ok": false, "message": "Node id must be 2-%d lowercase letters, digits or underscores." % MAX_ID_LENGTH}
	if new_id == old_id:
		return {"ok": true, "message": "Node id unchanged."}
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	if not nodes.has(old_id):
		return {"ok": false, "message": "Node '%s' does not exist." % old_id}
	if nodes.has(new_id):
		return {"ok": false, "message": "Node '%s' already exists." % new_id}
	var node: Dictionary = Dictionary(nodes[old_id]).duplicate(true)
	nodes.erase(old_id)
	nodes[new_id] = node
	var updated := 0
	if String(dialogue.get("start", "")) == old_id:
		dialogue["start"] = new_id
		updated += 1
	for raw_node_id in nodes.keys():
		var current: Dictionary = Dictionary(nodes[raw_node_id])
		if String(current.get("next", "")) == old_id:
			current["next"] = new_id
			updated += 1
		var choices: Array = Array(current.get("choices", []))
		for i in choices.size():
			if not choices[i] is Dictionary:
				continue
			var choice: Dictionary = Dictionary(choices[i]).duplicate(true)
			if String(choice.get("next", "")) == old_id:
				choice["next"] = new_id
				updated += 1
			if choice.get("check") is Dictionary:
				var check: Dictionary = Dictionary(choice["check"]).duplicate(true)
				for branch in ["success", "failure"]:
					if String(check.get(branch, "")) == old_id:
						check[branch] = new_id
						updated += 1
				choice["check"] = check
			choices[i] = choice
		current["choices"] = choices
		nodes[raw_node_id] = current
	dialogue["nodes"] = nodes
	return {"ok": true, "message": "Renamed node '%s' to '%s' and updated %d reference(s)." % [old_id, new_id, updated], "id": new_id}


static func delete_dialogue_node(draft: Dictionary, dialogue_id: String, node_id: String) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	if dialogue.is_empty():
		return {"ok": false, "message": "Dialogue '%s' does not exist." % dialogue_id}
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	if not nodes.has(node_id):
		return {"ok": false, "message": "Node '%s' does not exist." % node_id}
	if nodes.size() <= 1:
		return {"ok": false, "message": "A dialogue must keep at least one node."}
	var refs := node_references(dialogue, node_id)
	if not refs.is_empty():
		return {
			"ok": false,
			"message": "Cannot delete node '%s'; still referenced by %s. Point those links elsewhere first." % [node_id, ", ".join(refs)],
			"references": refs,
		}
	nodes.erase(node_id)
	dialogue["nodes"] = nodes
	return {"ok": true, "message": "Deleted node '%s'." % node_id}


## Replaces the editable parts of a node while preserving effects the simple
## palette does not expose, so hand-authored content is not silently stripped.
static func set_dialogue_node(
	draft: Dictionary,
	dialogue_id: String,
	node_id: String,
	text: String,
	speaker_name: String,
	next_id: String,
	narration: String,
	set_flag: String
) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {})) if not dialogue.is_empty() else {}
	if not nodes.has(node_id):
		return {"ok": false, "message": "Node '%s' does not exist." % node_id}
	if text.strip_edges() == "":
		return {"ok": false, "message": "Node text cannot be empty."}
	if next_id != "" and not nodes.has(next_id):
		return {"ok": false, "message": "Next node '%s' does not exist." % next_id}
	if next_id == node_id:
		return {"ok": false, "message": "A node cannot lead to itself; add a choice or use another node for loops."}
	var node: Dictionary = Dictionary(nodes[node_id]).duplicate(true)
	node["text"] = text.strip_edges()
	if speaker_name.strip_edges() != "":
		node["speaker_name"] = speaker_name.strip_edges()
		dialogue["speaker"] = speaker_name.strip_edges()
	node["next"] = next_id
	var kept: Array = []
	for raw_effect in Array(node.get("effects", [])):
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) in ["narration", "set_flag"]:
			continue
		kept.append(raw_effect)
	if narration.strip_edges() != "":
		kept.append({"type": "narration", "text": narration.strip_edges()})
	if set_flag.strip_edges() != "":
		kept.append({"type": "set_flag", "flag": set_flag.strip_edges()})
	node["effects"] = kept
	nodes[node_id] = node
	dialogue["nodes"] = nodes
	return {"ok": true, "message": "Updated node '%s'." % node_id}


static func add_dialogue_choice(draft: Dictionary, dialogue_id: String, node_id: String) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {})) if not dialogue.is_empty() else {}
	if not nodes.has(node_id):
		return {"ok": false, "message": "Select a node first."}
	var node: Dictionary = Dictionary(nodes[node_id]).duplicate(true)
	var choices: Array = Array(node.get("choices", []))
	choices.append({"text": "(USER CAMPAIGN) New response.", "next": ""})
	node["choices"] = choices
	node["next"] = ""
	nodes[node_id] = node
	dialogue["nodes"] = nodes
	return {"ok": true, "message": "Added response %d." % choices.size(), "index": choices.size() - 1}


static func remove_dialogue_choice(draft: Dictionary, dialogue_id: String, node_id: String, index: int) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {})) if not dialogue.is_empty() else {}
	if not nodes.has(node_id):
		return {"ok": false, "message": "Select a node first."}
	var node: Dictionary = Dictionary(nodes[node_id]).duplicate(true)
	var choices: Array = Array(node.get("choices", []))
	if index < 0 or index >= choices.size():
		return {"ok": false, "message": "Select a response first."}
	choices.remove_at(index)
	node["choices"] = choices
	nodes[node_id] = node
	dialogue["nodes"] = nodes
	return {"ok": true, "message": "Removed response %d." % (index + 1)}


## Updates the bounded choice form. A check replaces the plain `next`; a guard
## flag is stored as a `not_flag` condition and a consequence as `set_flag`.
static func update_dialogue_choice(
	draft: Dictionary, dialogue_id: String, node_id: String, index: int, fields: Dictionary
) -> Dictionary:
	var dialogue := dialogue_by_id(draft, dialogue_id)
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {})) if not dialogue.is_empty() else {}
	if not nodes.has(node_id):
		return {"ok": false, "message": "Select a node first."}
	var node: Dictionary = Dictionary(nodes[node_id]).duplicate(true)
	var choices: Array = Array(node.get("choices", []))
	if index < 0 or index >= choices.size():
		return {"ok": false, "message": "Select a response first."}
	var choice: Dictionary = Dictionary(choices[index]).duplicate(true)
	var text := String(fields.get("text", "")).strip_edges()
	if text == "":
		return {"ok": false, "message": "Response text cannot be empty."}
	choice["text"] = text
	var check: Dictionary = Dictionary(fields.get("check", {}))
	var guard := String(fields.get("guard_flag", "")).strip_edges()
	var require_flag := String(fields.get("require_flag", "")).strip_edges()
	var flag := String(fields.get("effect_flag", "")).strip_edges()
	var quest_id := String(fields.get("quest_id", "")).strip_edges()
	var encounter_id := String(fields.get("encounter_id", "")).strip_edges()
	if quest_id != "" and not quests_of(draft).has(quest_id):
		return {"ok": false, "message": "Choose an existing quest to start."}
	if encounter_id != "" and not encounters_of(draft).has(encounter_id):
		return {"ok": false, "message": "Choose an existing encounter to start."}
	if check.is_empty():
		var next_id := String(fields.get("next", ""))
		if next_id != "" and not nodes.has(next_id):
			return {"ok": false, "message": "Destination '%s' does not exist." % next_id}
		choice["next"] = next_id
		choice.erase("check")
	else:
		var skill := String(check.get("skill", ""))
		if not Skills.exists(skill):
			return {"ok": false, "message": "Choose a supported skill for the check."}
		var dc := int(check.get("dc", 10))
		if dc < 1 or dc > 60:
			return {"ok": false, "message": "DC must be between 1 and 60."}
		var actor := String(check.get("actor", "best"))
		if actor != "best" and not Array(Dictionary(draft.get("party", {})).get("default", [])).has(actor):
			return {"ok": false, "message": "Actor '%s' is not in the campaign party." % actor}
		for branch in ["success", "failure"]:
			var dest := String(check.get(branch, ""))
			if dest == "" or not nodes.has(dest):
				return {"ok": false, "message": "Choose a %s destination node." % branch}
		choice["check"] = {
			"skill": skill,
			"dc": dc,
			"actor": actor,
			"success": String(check.get("success", "")),
			"failure": String(check.get("failure", "")),
		}
		choice.erase("next")
	var kept_conditions: Array = []
	for raw_condition in Array(choice.get("conditions", [])):
		if raw_condition is Dictionary and String(Dictionary(raw_condition).get("type", "")) in ["not_flag", "flag"]:
			continue
		kept_conditions.append(raw_condition)
	if guard != "":
		kept_conditions.append({"type": "not_flag", "flag": guard})
	if require_flag != "":
		kept_conditions.append({"type": "flag", "flag": require_flag, "value": true})
	choice["conditions"] = kept_conditions
	var kept_effects: Array = []
	for raw_effect in Array(choice.get("effects", [])):
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) in ["set_flag", "quest_start", "start_combat"]:
			continue
		kept_effects.append(raw_effect)
	if flag != "":
		kept_effects.append({"type": "set_flag", "flag": flag, "value": true})
	if quest_id != "":
		kept_effects.append({"type": "quest_start", "quest": quest_id})
	if encounter_id != "":
		kept_effects.append({"type": "start_combat", "encounter": encounter_id})
	choice["effects"] = kept_effects
	choices[index] = choice
	node["choices"] = choices
	node["next"] = ""
	nodes[node_id] = node
	dialogue["nodes"] = nodes
	return {"ok": true, "message": "Updated response %d." % (index + 1)}


static func _write_dialogue_files(draft: Dictionary, dir: String) -> Array[String]:
	var errors: Array[String] = []
	var dialogue_dir := dir.path_join("dialogue")
	if not DirAccess.make_dir_recursive_absolute(dialogue_dir) == OK:
		return ["Could not create %s." % dialogue_dir]
	var kept := {}
	var dialogues := dialogues_of(draft)
	for raw_dialogue_id in dialogues.keys():
		var dialogue_id := String(raw_dialogue_id)
		if not dialogues[raw_dialogue_id] is Dictionary:
			errors.append("Dialogue '%s' is malformed." % dialogue_id)
			continue
		kept[dialogue_id] = true
		errors.append_array(_write_json(dialogue_dir.path_join(dialogue_id + ".json"), Dictionary(dialogues[raw_dialogue_id])))
	if DirAccess.dir_exists_absolute(dialogue_dir):
		for file_name in DirAccess.get_files_at(dialogue_dir):
			var file_string := String(file_name)
			if not file_string.ends_with(".json"):
				continue
			if not kept.has(file_string.get_basename()):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(dialogue_dir.path_join(file_string)))
	return errors


static func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(String(file_name))))
	for dir_name in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(String(dir_name)))
	# Remove the now-empty directory: callers check existence to decide whether a
	# campaign is installed, so leaving an empty folder behind would block reuse.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ------------------------------------------------------- quests, flags, encounters

static func is_valid_flag(flag: String) -> bool:
	if flag.length() < 2 or flag.length() > MAX_FLAG_LENGTH:
		return false
	var pattern := RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*$")
	return pattern.search(flag) != null


static func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func flags_of(draft: Dictionary) -> Dictionary:
	return _as_dict(draft.get("flag_definitions", {})).duplicate(true)


static func add_flag_definition(draft: Dictionary, flag: String, description := "") -> Dictionary:
	var clean := flag.strip_edges()
	if not is_valid_flag(clean):
		return {"ok": false, "message": "Flag names must be lowercase letters, digits or underscores, starting with a letter (2-%d characters)." % MAX_FLAG_LENGTH}
	var defs := flags_of(draft)
	defs[clean] = description.strip_edges()
	draft["flag_definitions"] = defs
	return {"ok": true, "message": "Defined flag '%s'." % clean, "flag": clean}


## The flag a quest's first objective watches. Used by the creator to offer a
## sensible once-only guard without hiding the value it writes.
static func first_objective_flag(draft: Dictionary, quest_id: String) -> String:
	for raw_objective in Array(quest_by_id(draft, quest_id).get("objectives", [])):
		if raw_objective is Dictionary and String(Dictionary(raw_objective).get("flag", "")) != "":
			return String(Dictionary(raw_objective).get("flag", ""))
	return ""


## Removes a declared flag only when nothing uses it. The definition itself is
## not a live reference, so a deliberate, unused flag can be cleaned up.
static func remove_flag_definition(draft: Dictionary, flag: String) -> Dictionary:
	var defs := flags_of(draft)
	if not defs.has(flag):
		return {"ok": false, "message": "Flag '%s' is not defined." % flag}
	var live: Array[String] = []
	for reference in flag_references(draft, flag):
		if String(reference) != "flag definition":
			live.append(String(reference))
	if not live.is_empty():
		return {"ok": false, "message": "Flag '%s' is still used by %s." % [flag, ", ".join(live)], "references": live}
	defs.erase(flag)
	draft["flag_definitions"] = defs
	return {"ok": true, "message": "Removed the definition of unused flag '%s'." % flag}


static func known_flags(draft: Dictionary) -> Array[String]:
	var found := {}
	for raw_flag in flags_of(draft).keys():
		found[String(raw_flag)] = true
	for raw_quest in quests_of(draft).values():
		if raw_quest is Dictionary:
			for objective in Array(Dictionary(raw_quest).get("objectives", [])):
				if objective is Dictionary:
					var flag := String(Dictionary(objective).get("flag", ""))
					if flag != "":
						found[flag] = true
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		if String(area.get("tracker_quest", "")) != "":
			pass
		_collect_flags_from_effects(Array(area.get("entry_effects", [])), found)
		for raw_trigger in Array(area.get("triggers", [])):
			if not raw_trigger is Dictionary:
				continue
			var trigger: Dictionary = raw_trigger
			for key in ["requires_flag", "requires_flag_not"]:
				var value := String(trigger.get(key, ""))
				if value != "":
					found[value] = true
			_collect_flags_from_effects(Array(trigger.get("effects", [])), found)
		for raw_object in Array(area.get("objects", [])):
			if not raw_object is Dictionary:
				continue
			var obj: Dictionary = raw_object
			for raw_interaction in Array(obj.get("interactions", [])):
				if not raw_interaction is Dictionary:
					continue
				var interaction: Dictionary = raw_interaction
				for key in ["requires_flag", "requires_flag_not"]:
					var value := String(interaction.get(key, ""))
					if value != "":
						found[value] = true
				_collect_flags_from_effects(Array(interaction.get("effects", [])), found)
				_collect_flags_from_effects(Array(interaction.get("success_effects", [])), found)
	for raw_dialogue in dialogues_of(draft).values():
		if not raw_dialogue is Dictionary:
			continue
		var nodes: Dictionary = _as_dict(Dictionary(raw_dialogue).get("nodes", {}))
		for raw_node in nodes.values():
			if not raw_node is Dictionary:
				continue
			var node: Dictionary = raw_node
			_collect_flags_from_effects(Array(node.get("effects", [])), found)
			for raw_choice in Array(node.get("choices", [])):
				if not raw_choice is Dictionary:
					continue
				var choice: Dictionary = raw_choice
				_collect_flags_from_conditions(Array(choice.get("conditions", [])), found)
				_collect_flags_from_effects(Array(choice.get("effects", [])), found)
	for raw_encounter in encounters_of(draft).values():
		if raw_encounter is Dictionary:
			_collect_flags_from_effects(Array(Dictionary(raw_encounter).get("victory_effects", [])), found)
	var result: Array[String] = []
	for raw_flag in found.keys():
		result.append(String(raw_flag))
	result.sort()
	return result


static func _collect_flags_from_effects(effects: Array, found: Dictionary) -> void:
	for raw_effect in effects:
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		if String(effect.get("type", "")) in ["set_flag", "clear_flag"]:
			var flag := String(effect.get("flag", ""))
			if flag != "":
				found[flag] = true


static func _collect_flags_from_conditions(conditions: Array, found: Dictionary) -> void:
	for raw_condition in conditions:
		if raw_condition is Dictionary and String(Dictionary(raw_condition).get("type", "")) in ["flag", "not_flag"]:
			var flag := String(Dictionary(raw_condition).get("flag", ""))
			if flag != "":
				found[flag] = true


static func flag_references(draft: Dictionary, flag: String) -> Array[String]:
	var result: Array[String] = []
	if flags_of(draft).has(flag):
		result.append("flag definition")
	for raw_quest_id in quests_of(draft).keys():
		var quest_id := String(raw_quest_id)
		var quest: Dictionary = _as_dict(quests_of(draft)[raw_quest_id])
		for objective in Array(quest.get("objectives", [])):
			if objective is Dictionary and String(Dictionary(objective).get("flag", "")) == flag:
				_append_unique(result, "quest '%s' objective '%s'" % [quest_id, Dictionary(objective).get("id", "?")])
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		var area_label := "area '%s'" % String(area.get("id", "?"))
		if String(area.get("tracker_quest", "")) == flag:
			_append_unique(result, area_label + " tracker")
		_collect_flag_effect_refs(Array(area.get("entry_effects", [])), flag, area_label + " entry", result)
		for raw_object in Array(area.get("objects", [])):
			if not raw_object is Dictionary:
				continue
			var obj: Dictionary = raw_object
			for raw_interaction in Array(obj.get("interactions", [])):
				if not raw_interaction is Dictionary:
					continue
				var interaction: Dictionary = raw_interaction
				var label := "%s object '%s' interaction '%s'" % [area_label, obj.get("id", "?"), interaction.get("id", "?")]
				for key in ["requires_flag", "requires_flag_not"]:
					if String(interaction.get(key, "")) == flag:
						_append_unique(result, label + " " + key)
				_collect_flag_effect_refs(Array(interaction.get("effects", [])), flag, label, result)
				_collect_flag_effect_refs(Array(interaction.get("success_effects", [])), flag, label, result)
		for raw_trigger in Array(area.get("triggers", [])):
			if not raw_trigger is Dictionary:
				continue
			var trigger: Dictionary = raw_trigger
			var label := "%s trigger '%s'" % [area_label, trigger.get("id", "?")]
			for key in ["requires_flag", "requires_flag_not"]:
				if String(trigger.get(key, "")) == flag:
					_append_unique(result, label + " " + key)
			_collect_flag_effect_refs(Array(trigger.get("effects", [])), flag, label, result)
	for raw_dialogue_id in dialogues_of(draft).keys():
		var dialogue: Dictionary = _as_dict(dialogues_of(draft)[raw_dialogue_id])
		var nodes: Dictionary = _as_dict(dialogue.get("nodes", {}))
		for raw_node_id in nodes.keys():
			var node: Dictionary = _as_dict(nodes[raw_node_id])
			var label := "dialogue '%s' node '%s'" % [raw_dialogue_id, raw_node_id]
			_collect_flag_effect_refs(Array(node.get("effects", [])), flag, label, result)
			for i in Array(node.get("choices", [])).size():
				var choice: Dictionary = _as_dict(Array(node.get("choices", []))[i])
				var choice_label := "%s choice %d" % [label, i + 1]
				for raw_condition in Array(choice.get("conditions", [])):
					if raw_condition is Dictionary and String(Dictionary(raw_condition).get("flag", "")) == flag:
						_append_unique(result, choice_label + " condition")
				_collect_flag_effect_refs(Array(choice.get("effects", [])), flag, choice_label, result)
	for raw_encounter_id in encounters_of(draft).keys():
		var encounter: Dictionary = _as_dict(encounters_of(draft)[raw_encounter_id])
		_collect_flag_effect_refs(
			Array(encounter.get("victory_effects", [])), flag, "encounter '%s' victory" % raw_encounter_id, result
		)
	return result


static func _collect_flag_effect_refs(effects: Array, flag: String, label: String, result: Array[String]) -> void:
	for raw_effect in effects:
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("flag", "")) == flag:
			_append_unique(result, label)


static func _append_unique(result: Array[String], value: String) -> void:
	if not result.has(value):
		result.append(value)


static func quests_of(draft: Dictionary) -> Dictionary:
	return _as_dict(draft.get("quests", {}))


static func quest_by_id(draft: Dictionary, quest_id: String) -> Dictionary:
	return _as_dict(quests_of(draft).get(quest_id, {}))


static func next_quest_id(draft: Dictionary) -> String:
	var index := 1
	while quests_of(draft).has("quest_%02d" % index):
		index += 1
	return "quest_%02d" % index


static func add_quest(draft: Dictionary, title := "New Quest") -> Dictionary:
	var quest_id := next_quest_id(draft)
	var clean_title := title.strip_edges()
	if clean_title == "":
		clean_title = "New Quest"
	var objective_id := "objective_01"
	var objective_flag := quest_id + "_done"
	var quests := quests_of(draft)
	quests[quest_id] = {
		"id": quest_id,
		"title": clean_title,
		"summary": "(USER CAMPAIGN) A placeholder quest description.",
		"objectives": [
			{"id": objective_id, "text": "Complete the placeholder objective.", "flag": objective_flag},
		],
	}
	draft["quests"] = quests
	return {"ok": true, "message": "Created quest '%s'." % quest_id, "id": quest_id}


static func set_quest_fields(
	draft: Dictionary, quest_id: String, title: String, summary: String, start_quest: String, completion_quest: String
) -> Dictionary:
	var quests := quests_of(draft)
	if not quests.has(quest_id):
		return {"ok": false, "message": "Select a quest first."}
	var clean_title := title.strip_edges()
	if clean_title == "":
		return {"ok": false, "message": "Quest title cannot be empty."}
	if not quests.has(start_quest):
		return {"ok": false, "message": "The campaign start quest must be an existing quest."}
	if completion_quest != "" and not quests.has(completion_quest):
		return {"ok": false, "message": "The completion quest must exist or be empty."}
	var quest: Dictionary = Dictionary(quests[quest_id]).duplicate(true)
	quest["title"] = clean_title
	quest["summary"] = summary.strip_edges()
	quests[quest_id] = quest
	draft["quests"] = quests
	draft["start_quest"] = start_quest
	draft["completion_quest"] = completion_quest
	return {"ok": true, "message": "Updated quest '%s' and campaign completion settings." % quest_id}


static func quest_references(draft: Dictionary, quest_id: String) -> Array[String]:
	var result: Array[String] = []
	if String(draft.get("start_quest", "")) == quest_id:
		result.append("campaign start quest")
	if String(draft.get("completion_quest", "")) == quest_id:
		result.append("campaign completion quest")
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		var label := "area '%s'" % area.get("id", "?")
		if String(area.get("tracker_quest", "")) == quest_id:
			_append_unique(result, label + " tracker")
		_collect_quest_refs_in_effects(Array(area.get("entry_effects", [])), quest_id, label + " entry", result)
		for raw_object in Array(area.get("objects", [])):
			if not raw_object is Dictionary:
				continue
			var obj: Dictionary = raw_object
			for raw_interaction in Array(obj.get("interactions", [])):
				if raw_interaction is Dictionary:
					var ilabel := "%s object '%s'" % [label, obj.get("id", "?")]
					_collect_quest_refs_in_effects(Array(Dictionary(raw_interaction).get("effects", [])), quest_id, ilabel, result)
					_collect_quest_refs_in_effects(Array(Dictionary(raw_interaction).get("success_effects", [])), quest_id, ilabel, result)
		for raw_trigger in Array(area.get("triggers", [])):
			if raw_trigger is Dictionary:
				_collect_quest_refs_in_effects(
					Array(Dictionary(raw_trigger).get("effects", [])), quest_id,
					"%s trigger '%s'" % [label, Dictionary(raw_trigger).get("id", "?")], result
				)
	for raw_dialogue_id in dialogues_of(draft).keys():
		var dialogue: Dictionary = _as_dict(dialogues_of(draft)[raw_dialogue_id])
		var nodes: Dictionary = _as_dict(dialogue.get("nodes", {}))
		for raw_node_id in nodes.keys():
			var node: Dictionary = _as_dict(nodes[raw_node_id])
			var label := "dialogue '%s' node '%s'" % [raw_dialogue_id, raw_node_id]
			_collect_quest_refs_in_effects(Array(node.get("effects", [])), quest_id, label, result)
			for i in Array(node.get("choices", [])).size():
				var choice: Dictionary = _as_dict(Array(node.get("choices", []))[i])
				var choice_label := "%s choice %d" % [label, i + 1]
				_collect_quest_refs_in_effects(Array(choice.get("effects", [])), quest_id, choice_label, result)
				for raw_condition in Array(choice.get("conditions", [])):
					if raw_condition is Dictionary and String(Dictionary(raw_condition).get("quest", "")) == quest_id:
						_append_unique(result, choice_label + " condition")
	for raw_encounter_id in encounters_of(draft).keys():
		var encounter: Dictionary = _as_dict(encounters_of(draft)[raw_encounter_id])
		_collect_quest_refs_in_effects(
			Array(encounter.get("victory_effects", [])), quest_id,
			"encounter '%s' victory" % raw_encounter_id, result
		)
	return result


static func _collect_quest_refs_in_effects(effects: Array, quest_id: String, label: String, result: Array[String]) -> void:
	for raw_effect in effects:
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "quest_start" and String(Dictionary(raw_effect).get("quest", "")) == quest_id:
			_append_unique(result, label)


static func rename_quest(draft: Dictionary, old_id: String, new_id: String) -> Dictionary:
	if not is_valid_id(new_id):
		return {"ok": false, "message": "Quest id must be 2-%d lowercase letters, digits or underscores." % MAX_ID_LENGTH}
	if new_id == old_id:
		return {"ok": true, "message": "Quest id unchanged."}
	var quests := quests_of(draft)
	if not quests.has(old_id):
		return {"ok": false, "message": "Quest '%s' does not exist." % old_id}
	if quests.has(new_id):
		return {"ok": false, "message": "Quest '%s' already exists." % new_id}
	var moved: Dictionary = Dictionary(quests[old_id]).duplicate(true)
	moved["id"] = new_id
	quests.erase(old_id)
	quests[new_id] = moved
	draft["quests"] = quests
	var updated := 0
	if String(draft.get("start_quest", "")) == old_id:
		draft["start_quest"] = new_id
		updated += 1
	if String(draft.get("completion_quest", "")) == old_id:
		draft["completion_quest"] = new_id
		updated += 1
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		if String(area.get("tracker_quest", "")) == old_id:
			area["tracker_quest"] = new_id
			updated += 1
		updated += _rename_quest_in_effects(Array(area.get("entry_effects", [])), old_id, new_id)
		for raw_object in Array(area.get("objects", [])):
			if not raw_object is Dictionary:
				continue
			var obj: Dictionary = raw_object
			for raw_interaction in Array(obj.get("interactions", [])):
				if raw_interaction is Dictionary:
					updated += _rename_quest_in_effects(Array(Dictionary(raw_interaction).get("effects", [])), old_id, new_id)
					updated += _rename_quest_in_effects(Array(Dictionary(raw_interaction).get("success_effects", [])), old_id, new_id)
		for raw_trigger in Array(area.get("triggers", [])):
			if raw_trigger is Dictionary:
				updated += _rename_quest_in_effects(Array(Dictionary(raw_trigger).get("effects", [])), old_id, new_id)
	for raw_dialogue_id in dialogues_of(draft).keys():
		var dialogue: Dictionary = _as_dict(dialogues_of(draft)[raw_dialogue_id])
		var nodes: Dictionary = _as_dict(dialogue.get("nodes", {}))
		for raw_node_id in nodes.keys():
			var node: Dictionary = _as_dict(nodes[raw_node_id])
			updated += _rename_quest_in_effects(Array(node.get("effects", [])), old_id, new_id)
			for raw_choice in Array(node.get("choices", [])):
				if not raw_choice is Dictionary:
					continue
				var choice: Dictionary = raw_choice
				updated += _rename_quest_in_effects(Array(choice.get("effects", [])), old_id, new_id)
				for raw_condition in Array(choice.get("conditions", [])):
					if raw_condition is Dictionary and String(Dictionary(raw_condition).get("quest", "")) == old_id:
						Dictionary(raw_condition)["quest"] = new_id
						updated += 1
	for raw_encounter_id in encounters_of(draft).keys():
		var encounter: Dictionary = _as_dict(encounters_of(draft)[raw_encounter_id])
		updated += _rename_quest_in_effects(Array(encounter.get("victory_effects", [])), old_id, new_id)
	return {"ok": true, "message": "Renamed quest '%s' to '%s' and updated %d reference(s)." % [old_id, new_id, updated], "id": new_id}


static func _rename_quest_in_effects(effects: Array, old_id: String, new_id: String) -> int:
	var updated := 0
	for raw_effect in effects:
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "quest_start" and String(Dictionary(raw_effect).get("quest", "")) == old_id:
			Dictionary(raw_effect)["quest"] = new_id
			updated += 1
	return updated


static func delete_quest(draft: Dictionary, quest_id: String) -> Dictionary:
	var quests := quests_of(draft)
	if not quests.has(quest_id):
		return {"ok": false, "message": "Quest '%s' does not exist." % quest_id}
	var refs := quest_references(draft, quest_id)
	if not refs.is_empty():
		return {"ok": false, "message": "Cannot delete quest '%s'; still referenced by %s." % [quest_id, ", ".join(refs)], "references": refs}
	quests.erase(quest_id)
	draft["quests"] = quests
	return {"ok": true, "message": "Deleted quest '%s'." % quest_id}


static func add_objective(draft: Dictionary, quest_id: String) -> Dictionary:
	var quests := quests_of(draft)
	if not quests.has(quest_id):
		return {"ok": false, "message": "Select a quest first."}
	var quest: Dictionary = Dictionary(quests[quest_id]).duplicate(true)
	var objectives: Array = Array(quest.get("objectives", []))
	if objectives.size() >= MAX_OBJECTIVES:
		return {"ok": false, "message": "This slice supports at most %d objectives per quest." % MAX_OBJECTIVES}
	var used := {}
	for raw_objective in objectives:
		if raw_objective is Dictionary:
			used[String(Dictionary(raw_objective).get("id", ""))] = true
	var index := 1
	while used.has("objective_%02d" % index):
		index += 1
	var objective_id := "objective_%02d" % index
	var flag := "%s_%s" % [quest_id, objective_id]
	if not is_valid_flag(flag):
		flag = "%s_done" % quest_id
	objectives.append({"id": objective_id, "text": "(USER CAMPAIGN) New objective.", "flag": flag})
	quest["objectives"] = objectives
	quests[quest_id] = quest
	draft["quests"] = quests
	return {"ok": true, "message": "Added objective '%s'." % objective_id, "id": objective_id}


static func update_objective(
	draft: Dictionary, quest_id: String, old_id: String, new_id: String, text: String, flag: String
) -> Dictionary:
	var quests := quests_of(draft)
	if not quests.has(quest_id):
		return {"ok": false, "message": "Select a quest first."}
	if not is_valid_id(new_id):
		return {"ok": false, "message": "Objective id must be lowercase letters, digits or underscores."}
	var clean_flag := flag.strip_edges()
	if not is_valid_flag(clean_flag):
		return {"ok": false, "message": "Objective flag must be a valid lowercase flag name (2-%d characters)." % MAX_FLAG_LENGTH}
	if text.strip_edges() == "":
		return {"ok": false, "message": "Objective text cannot be empty."}
	var quest: Dictionary = Dictionary(quests[quest_id]).duplicate(true)
	var objectives: Array = Array(quest.get("objectives", []))
	var seen := {}
	for raw_objective in objectives:
		if not raw_objective is Dictionary:
			continue
		var objective: Dictionary = raw_objective
		var objective_id := String(objective.get("id", ""))
		if objective_id == new_id and objective_id != old_id:
			return {"ok": false, "message": "Objective id '%s' already exists in this quest." % new_id}
		seen[objective_id] = true
	if not seen.has(old_id):
		return {"ok": false, "message": "Objective '%s' does not exist." % old_id}
	for i in objectives.size():
		var objective: Dictionary = Dictionary(objectives[i]).duplicate(true)
		if String(objective.get("id", "")) != old_id:
			continue
		objective["id"] = new_id
		objective["text"] = text.strip_edges()
		objective["flag"] = clean_flag
		objectives[i] = objective
	quest["objectives"] = objectives
	quests[quest_id] = quest
	draft["quests"] = quests
	return {"ok": true, "message": "Updated objective '%s'." % new_id, "id": new_id}


static func remove_objective(draft: Dictionary, quest_id: String, objective_id: String) -> Dictionary:
	var quests := quests_of(draft)
	if not quests.has(quest_id):
		return {"ok": false, "message": "Select a quest first."}
	var quest: Dictionary = Dictionary(quests[quest_id]).duplicate(true)
	var objectives: Array = Array(quest.get("objectives", []))
	if objectives.size() <= 1:
		return {"ok": false, "message": "A quest must keep at least one objective."}
	for i in objectives.size():
		if objectives[i] is Dictionary and String(Dictionary(objectives[i]).get("id", "")) == objective_id:
			objectives.remove_at(i)
			quest["objectives"] = objectives
			quests[quest_id] = quest
			draft["quests"] = quests
			return {"ok": true, "message": "Removed objective '%s'." % objective_id}
	return {"ok": false, "message": "Objective '%s' does not exist." % objective_id}


static func encounters_of(draft: Dictionary) -> Dictionary:
	return _as_dict(draft.get("encounters", {}))


static func encounter_by_id(draft: Dictionary, encounter_id: String) -> Dictionary:
	return _as_dict(encounters_of(draft).get(encounter_id, {}))


static func next_encounter_id(draft: Dictionary) -> String:
	var index := 1
	while encounters_of(draft).has("encounter_%02d" % index):
		index += 1
	return "encounter_%02d" % index


static func add_encounter(draft: Dictionary, template_id := "room_7x5") -> Dictionary:
	if not ENCOUNTER_TEMPLATES.has(template_id):
		return {"ok": false, "message": "Choose a supported encounter layout."}
	var encounter_id := next_encounter_id(draft)
	var template: Dictionary = ENCOUNTER_TEMPLATES[template_id]
	var encounters := encounters_of(draft)
	encounters[encounter_id] = {
		"id": encounter_id,
		"name": "New Encounter",
		"rows": Array(template.get("rows", [])).duplicate(),
		"party_cells": Array(template.get("party_cells", [])).duplicate(true),
		"monsters": ["zombie"],
		"monster_cells": Array(template.get("monster_cells", [])).duplicate(true),
		"xp": 100,
		"intro": "(USER CAMPAIGN) A placeholder encounter begins.",
		"victory_effects": [],
	}
	draft["encounters"] = encounters
	return {"ok": true, "message": "Created encounter '%s'." % encounter_id, "id": encounter_id}


static func set_encounter_fields(draft: Dictionary, encounter_id: String, name: String, xp: int, intro: String) -> Dictionary:
	var encounters := encounters_of(draft)
	if not encounters.has(encounter_id):
		return {"ok": false, "message": "Select an encounter first."}
	if name.strip_edges() == "":
		return {"ok": false, "message": "Encounter name cannot be empty."}
	if xp < 0 or xp > 100000:
		return {"ok": false, "message": "Encounter XP must be between 0 and 100000."}
	var encounter: Dictionary = Dictionary(encounters[encounter_id]).duplicate(true)
	encounter["name"] = name.strip_edges()
	encounter["xp"] = xp
	encounter["intro"] = intro.strip_edges()
	encounters[encounter_id] = encounter
	draft["encounters"] = encounters
	return {"ok": true, "message": "Updated encounter '%s'." % encounter_id}


static func set_encounter_template(draft: Dictionary, encounter_id: String, template_id: String) -> Dictionary:
	if not ENCOUNTER_TEMPLATES.has(template_id):
		return {"ok": false, "message": "Choose a supported encounter layout."}
	var encounters := encounters_of(draft)
	if not encounters.has(encounter_id):
		return {"ok": false, "message": "Select an encounter first."}
	var template: Dictionary = ENCOUNTER_TEMPLATES[template_id]
	var encounter: Dictionary = Dictionary(encounters[encounter_id]).duplicate(true)
	encounter["rows"] = Array(template.get("rows", [])).duplicate()
	encounter["party_cells"] = Array(template.get("party_cells", [])).duplicate(true)
	encounter["monster_cells"] = Array(template.get("monster_cells", [])).duplicate(true)
	var monsters: Array = Array(encounter.get("monsters", []))
	while monsters.size() > Array(encounter["monster_cells"]).size():
		monsters.pop_back()
	encounter["monsters"] = monsters
	encounters[encounter_id] = encounter
	draft["encounters"] = encounters
	return {"ok": true, "message": "Applied layout '%s'." % template.get("label", template_id)}


static func add_encounter_monster(draft: Dictionary, encounter_id: String, monster_id: String) -> Dictionary:
	var encounters := encounters_of(draft)
	if not encounters.has(encounter_id):
		return {"ok": false, "message": "Select an encounter first."}
	if monster_id.strip_edges() == "":
		return {"ok": false, "message": "Choose a monster."}
	var encounter: Dictionary = Dictionary(encounters[encounter_id]).duplicate(true)
	var monsters: Array = Array(encounter.get("monsters", []))
	if monsters.size() >= MAX_ENCOUNTER_MONSTERS or monsters.size() >= Array(encounter.get("monster_cells", [])).size():
		return {"ok": false, "message": "This layout holds at most %d monsters." % mini(MAX_ENCOUNTER_MONSTERS, Array(encounter.get("monster_cells", [])).size())}
	monsters.append(monster_id.strip_edges())
	encounter["monsters"] = monsters
	encounters[encounter_id] = encounter
	draft["encounters"] = encounters
	return {"ok": true, "message": "Added monster '%s'." % monster_id}


static func remove_encounter_monster(draft: Dictionary, encounter_id: String, index: int) -> Dictionary:
	var encounters := encounters_of(draft)
	if not encounters.has(encounter_id):
		return {"ok": false, "message": "Select an encounter first."}
	var encounter: Dictionary = Dictionary(encounters[encounter_id]).duplicate(true)
	var monsters: Array = Array(encounter.get("monsters", []))
	if index < 0 or index >= monsters.size():
		return {"ok": false, "message": "Choose a monster first."}
	if monsters.size() <= 1:
		return {"ok": false, "message": "An encounter must keep at least one monster."}
	monsters.remove_at(index)
	encounter["monsters"] = monsters
	encounters[encounter_id] = encounter
	draft["encounters"] = encounters
	return {"ok": true, "message": "Removed monster %d." % (index + 1)}


static func set_encounter_victory(
	draft: Dictionary, encounter_id: String, flag: String, narration: String, quest_id := ""
) -> Dictionary:
	var encounters := encounters_of(draft)
	if not encounters.has(encounter_id):
		return {"ok": false, "message": "Select an encounter first."}
	var clean_flag := flag.strip_edges()
	if clean_flag != "" and not is_valid_flag(clean_flag):
		return {"ok": false, "message": "Victory flag must be a valid lowercase flag name."}
	if quest_id != "" and not quests_of(draft).has(quest_id):
		return {"ok": false, "message": "Victory quest must exist."}
	var encounter: Dictionary = Dictionary(encounters[encounter_id]).duplicate(true)
	var kept: Array = []
	for raw_effect in Array(encounter.get("victory_effects", [])):
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) in ["set_flag", "narration", "quest_start"]:
			continue
		kept.append(raw_effect)
	if clean_flag != "":
		kept.append({"type": "set_flag", "flag": clean_flag, "value": true})
	if narration.strip_edges() != "":
		kept.append({"type": "narration", "text": narration.strip_edges()})
	if quest_id != "":
		kept.append({"type": "quest_start", "quest": quest_id})
	encounter["victory_effects"] = kept
	encounters[encounter_id] = encounter
	draft["encounters"] = encounters
	return {"ok": true, "message": "Updated victory consequences."}


static func encounter_references(draft: Dictionary, encounter_id: String) -> Array[String]:
	var result: Array[String] = []
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		for raw_trigger in Array(area.get("triggers", [])):
			if raw_trigger is Dictionary and String(Dictionary(raw_trigger).get("encounter", "")) == encounter_id:
				_append_unique(result, "area '%s' trigger '%s'" % [area.get("id", "?"), Dictionary(raw_trigger).get("id", "?")])
	for raw_dialogue_id in dialogues_of(draft).keys():
		var dialogue: Dictionary = _as_dict(dialogues_of(draft)[raw_dialogue_id])
		var nodes: Dictionary = _as_dict(dialogue.get("nodes", {}))
		for raw_node_id in nodes.keys():
			var node: Dictionary = _as_dict(nodes[raw_node_id])
			var label := "dialogue '%s' node '%s'" % [raw_dialogue_id, raw_node_id]
			_collect_encounter_refs_in_effects(Array(node.get("effects", [])), encounter_id, label, result)
			for i in Array(node.get("choices", [])).size():
				var choice: Dictionary = _as_dict(Array(node.get("choices", []))[i])
				_collect_encounter_refs_in_effects(Array(choice.get("effects", [])), encounter_id, "%s choice %d" % [label, i + 1], result)
	return result


static func _collect_encounter_refs_in_effects(effects: Array, encounter_id: String, label: String, result: Array[String]) -> void:
	for raw_effect in effects:
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "start_combat" and String(Dictionary(raw_effect).get("encounter", "")) == encounter_id:
			_append_unique(result, label)


static func rename_encounter(draft: Dictionary, old_id: String, new_id: String) -> Dictionary:
	if not is_valid_id(new_id):
		return {"ok": false, "message": "Encounter id must be 2-%d lowercase letters, digits or underscores." % MAX_ID_LENGTH}
	if new_id == old_id:
		return {"ok": true, "message": "Encounter id unchanged."}
	var encounters := encounters_of(draft)
	if not encounters.has(old_id):
		return {"ok": false, "message": "Encounter '%s' does not exist." % old_id}
	if encounters.has(new_id):
		return {"ok": false, "message": "Encounter '%s' already exists." % new_id}
	var moved: Dictionary = Dictionary(encounters[old_id]).duplicate(true)
	moved["id"] = new_id
	encounters.erase(old_id)
	encounters[new_id] = moved
	draft["encounters"] = encounters
	var updated := 0
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		for raw_trigger in Array(Dictionary(raw_area).get("triggers", [])):
			if raw_trigger is Dictionary and String(Dictionary(raw_trigger).get("encounter", "")) == old_id:
				Dictionary(raw_trigger)["encounter"] = new_id
				updated += 1
	for raw_dialogue_id in dialogues_of(draft).keys():
		var dialogue: Dictionary = _as_dict(dialogues_of(draft)[raw_dialogue_id])
		var nodes: Dictionary = _as_dict(dialogue.get("nodes", {}))
		for raw_node_id in nodes.keys():
			var node: Dictionary = _as_dict(nodes[raw_node_id])
			updated += _rename_encounter_in_effects(Array(node.get("effects", [])), old_id, new_id)
			for raw_choice in Array(node.get("choices", [])):
				if raw_choice is Dictionary:
					updated += _rename_encounter_in_effects(Array(Dictionary(raw_choice).get("effects", [])), old_id, new_id)
	return {"ok": true, "message": "Renamed encounter '%s' to '%s' and updated %d reference(s)." % [old_id, new_id, updated], "id": new_id}


static func _rename_encounter_in_effects(effects: Array, old_id: String, new_id: String) -> int:
	var updated := 0
	for raw_effect in effects:
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "start_combat" and String(Dictionary(raw_effect).get("encounter", "")) == old_id:
			Dictionary(raw_effect)["encounter"] = new_id
			updated += 1
	return updated


static func delete_encounter(draft: Dictionary, encounter_id: String) -> Dictionary:
	var encounters := encounters_of(draft)
	if not encounters.has(encounter_id):
		return {"ok": false, "message": "Encounter '%s' does not exist." % encounter_id}
	var refs := encounter_references(draft, encounter_id)
	if not refs.is_empty():
		return {"ok": false, "message": "Cannot delete encounter '%s'; still referenced by %s." % [encounter_id, ", ".join(refs)], "references": refs}
	encounters.erase(encounter_id)
	draft["encounters"] = encounters
	return {"ok": true, "message": "Deleted encounter '%s'." % encounter_id}


static func triggers_of(draft: Dictionary, area_id: String) -> Array:
	return Array(area_by_id(draft, area_id).get("triggers", []))


static func find_trigger(draft: Dictionary, area_id: String, trigger_id: String) -> Dictionary:
	for raw_trigger in triggers_of(draft, area_id):
		if raw_trigger is Dictionary and String(Dictionary(raw_trigger).get("id", "")) == trigger_id:
			return Dictionary(raw_trigger)
	return {}


static func next_trigger_id(draft: Dictionary, area_id: String) -> String:
	var index := 1
	while not find_trigger(draft, area_id, "trigger_%02d" % index).is_empty():
		index += 1
	return "trigger_%02d" % index


static func add_encounter_trigger(
	draft: Dictionary, area_id: String, pos: Vector2i, encounter_id: String, guard_flag: String, narration: String
) -> Dictionary:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return {"ok": false, "message": "Select an area first."}
	if not encounters_of(draft).has(encounter_id):
		return {"ok": false, "message": "Choose an existing encounter."}
	var clean_guard := guard_flag.strip_edges()
	if clean_guard != "" and not is_valid_flag(clean_guard):
		return {"ok": false, "message": "Guard flag must be a valid lowercase flag name."}
	var cell := [pos.x, pos.y]
	var rows: Array = Array(area.get("rows", []))
	if rows.is_empty() or not _in_bounds(cell, String(rows[0]).length(), rows.size()) or not _is_floor(rows, cell):
		return {"ok": false, "message": "Choose a floor cell inside this area."}
	if _cell_blocked(draft, area, cell):
		return {"ok": false, "message": "That cell already holds the entry, an NPC, an object, a door or a trigger."}
	var trigger_id := next_trigger_id(draft, area_id)
	var trigger := {
		"id": trigger_id,
		"pos": cell,
		"encounter": encounter_id,
	}
	if clean_guard != "":
		trigger["requires_flag_not"] = clean_guard
	var effects: Array = []
	if narration.strip_edges() != "":
		effects.append({"type": "narration", "text": narration.strip_edges()})
	if not effects.is_empty():
		trigger["effects"] = effects
	var triggers: Array = Array(area.get("triggers", []))
	triggers.append(trigger)
	area["triggers"] = triggers
	return {"ok": true, "message": "Placed trigger '%s' at (%d, %d)." % [trigger_id, pos.x, pos.y], "id": trigger_id}


static func update_encounter_trigger(
	draft: Dictionary, area_id: String, trigger_id: String, encounter_id: String, guard_flag: String, narration: String
) -> Dictionary:
	var area := area_by_id(draft, area_id)
	if area.is_empty():
		return {"ok": false, "message": "Select an area first."}
	if not encounters_of(draft).has(encounter_id):
		return {"ok": false, "message": "Choose an existing encounter."}
	var clean_guard := guard_flag.strip_edges()
	if clean_guard != "" and not is_valid_flag(clean_guard):
		return {"ok": false, "message": "Guard flag must be a valid lowercase flag name."}
	var triggers: Array = Array(area.get("triggers", []))
	for i in triggers.size():
		if not triggers[i] is Dictionary or String(Dictionary(triggers[i]).get("id", "")) != trigger_id:
			continue
		var trigger: Dictionary = Dictionary(triggers[i]).duplicate(true)
		trigger["encounter"] = encounter_id
		if clean_guard == "":
			trigger.erase("requires_flag_not")
		else:
			trigger["requires_flag_not"] = clean_guard
		var effects: Array = []
		for raw_effect in Array(trigger.get("effects", [])):
			if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "narration":
				continue
			effects.append(raw_effect)
		if narration.strip_edges() != "":
			effects.append({"type": "narration", "text": narration.strip_edges()})
		trigger["effects"] = effects
		triggers[i] = trigger
		area["triggers"] = triggers
		return {"ok": true, "message": "Updated trigger '%s'." % trigger_id}
	return {"ok": false, "message": "Trigger '%s' does not exist in this area." % trigger_id}


static func remove_encounter_trigger(draft: Dictionary, area_id: String, trigger_id: String) -> Dictionary:
	var area := area_by_id(draft, area_id)
	var triggers: Array = Array(area.get("triggers", []))
	for i in triggers.size():
		if triggers[i] is Dictionary and String(Dictionary(triggers[i]).get("id", "")) == trigger_id:
			triggers.remove_at(i)
			area["triggers"] = triggers
			return {"ok": true, "message": "Removed trigger '%s'." % trigger_id}
	return {"ok": false, "message": "Trigger '%s' does not exist." % trigger_id}


static func _validate_quest_and_encounter_shape(draft: Dictionary, errors: Array[String]) -> void:
	var defs := flags_of(draft)
	for raw_flag in defs.keys():
		if not is_valid_flag(String(raw_flag)):
			errors.append("Flag definition '%s' is invalid." % raw_flag)
	var quests := quests_of(draft)
	for raw_quest_id in quests.keys():
		var quest_id := String(raw_quest_id)
		var quest: Dictionary = _as_dict(quests[raw_quest_id])
		if not is_valid_id(quest_id):
			errors.append("Quest id '%s' is invalid." % quest_id)
		if String(quest.get("title", "")).strip_edges() == "":
			errors.append("Quest '%s' has no title." % quest_id)
		var objectives: Array = Array(quest.get("objectives", []))
		if objectives.is_empty():
			errors.append("Quest '%s' has no objectives." % quest_id)
		if objectives.size() > MAX_OBJECTIVES:
			errors.append("Quest '%s' has more than %d objectives." % [quest_id, MAX_OBJECTIVES])
		var objective_ids := {}
		for raw_objective in objectives:
			if not raw_objective is Dictionary:
				errors.append("Quest '%s' has a malformed objective." % quest_id)
				continue
			var objective: Dictionary = raw_objective
			var objective_id := String(objective.get("id", ""))
			if not is_valid_id(objective_id):
				errors.append("Quest '%s' objective id '%s' is invalid." % [quest_id, objective_id])
			elif objective_ids.has(objective_id):
				errors.append("Quest '%s' has duplicate objective id '%s'." % [quest_id, objective_id])
			objective_ids[objective_id] = true
			if String(objective.get("text", "")).strip_edges() == "":
				errors.append("Quest '%s' objective '%s' has no text." % [quest_id, objective_id])
			var flag := String(objective.get("flag", ""))
			if not is_valid_flag(flag):
				errors.append("Quest '%s' objective '%s' has invalid flag '%s'." % [quest_id, objective_id, flag])
	var start_quest := String(draft.get("start_quest", ""))
	if start_quest == "" or not quests.has(start_quest):
		errors.append("Campaign start quest '%s' does not exist." % start_quest)
	var completion_quest := String(draft.get("completion_quest", ""))
	if completion_quest != "" and not quests.has(completion_quest):
		errors.append("Campaign completion quest '%s' does not exist." % completion_quest)
	var encounters := encounters_of(draft)
	for raw_encounter_id in encounters.keys():
		var encounter_id := String(raw_encounter_id)
		var encounter: Dictionary = _as_dict(encounters[raw_encounter_id])
		if not is_valid_id(encounter_id):
			errors.append("Encounter id '%s' is invalid." % encounter_id)
		if String(encounter.get("name", "")).strip_edges() == "":
			errors.append("Encounter '%s' has no name." % encounter_id)
		var rows: Array = Array(encounter.get("rows", []))
		if rows.is_empty():
			errors.append("Encounter '%s' has no battle map." % encounter_id)
			continue
		var width := String(rows[0]).length()
		for y in rows.size():
			if String(rows[y]).length() != width:
				errors.append("Encounter '%s' row %d is not %d cells wide." % [encounter_id, y, width])
				break
		var party_cells: Array = Array(encounter.get("party_cells", []))
		var monster_cells: Array = Array(encounter.get("monster_cells", []))
		if party_cells.size() < 4:
			errors.append("Encounter '%s' needs at least 4 party cells." % encounter_id)
		if monster_cells.size() < 1:
			errors.append("Encounter '%s' has no monster cells." % encounter_id)
		var monsters: Array = Array(encounter.get("monsters", []))
		if monsters.is_empty():
			errors.append("Encounter '%s' has no monsters." % encounter_id)
		elif monsters.size() > MAX_ENCOUNTER_MONSTERS or monsters.size() > monster_cells.size():
			errors.append("Encounter '%s' has more monsters than its layout allows." % encounter_id)
		var used_cells := {}
		for pair in ["party_cells", "monster_cells"]:
			for cell in Array(encounter.get(pair, [])):
				if not cell is Array or Array(cell).size() != 2:
					errors.append("Encounter '%s' %s has a malformed cell." % [encounter_id, pair])
					continue
				var pos: Array = Array(cell)
				if not _in_bounds(pos, width, rows.size()) or not _is_floor(rows, pos):
					errors.append("Encounter '%s' %s cell %s is not walkable." % [encounter_id, pair, str(pos)])
				var key := "%d,%d" % [int(pos[0]), int(pos[1])]
				if used_cells.has(key):
					errors.append("Encounter '%s' uses cell %s more than once." % [encounter_id, str(pos)])
				used_cells[key] = true
		if int(encounter.get("xp", 0)) < 0:
			errors.append("Encounter '%s' has negative XP." % encounter_id)
	for raw_area in Array(draft.get("areas", [])):
		if not raw_area is Dictionary:
			continue
		var area: Dictionary = raw_area
		var area_id := String(area.get("id", "?"))
		var rows: Array = Array(area.get("rows", []))
		var width := String(rows[0]).length() if not rows.is_empty() else 0
		var occupied := {}
		var start: Dictionary = area.get("start", {})
		var start_pos: Array = Array(start.get("pos", []))
		if start_pos.size() == 2:
			occupied["%d,%d" % [int(start_pos[0]), int(start_pos[1])]] = "start"
		for key in ["objects", "doors", "npcs"]:
			for raw_entry in Array(area.get(key, [])):
				if raw_entry is Dictionary:
					var pos: Array = Array(Dictionary(raw_entry).get("pos", []))
					if pos.size() == 2:
						occupied["%d,%d" % [int(pos[0]), int(pos[1])]] = key
		var trigger_ids := {}
		for raw_trigger in Array(area.get("triggers", [])):
			if not raw_trigger is Dictionary:
				errors.append("Area '%s' has a malformed trigger." % area_id)
				continue
			var trigger: Dictionary = raw_trigger
			var trigger_id := String(trigger.get("id", ""))
			if not is_valid_id(trigger_id):
				errors.append("Area '%s' trigger id '%s' is invalid." % [area_id, trigger_id])
			elif trigger_ids.has(trigger_id):
				errors.append("Area '%s' has duplicate trigger id '%s'." % [area_id, trigger_id])
			trigger_ids[trigger_id] = true
			var pos: Array = Array(trigger.get("pos", []))
			if pos.size() != 2 or not _in_bounds(pos, width, rows.size()) or not _is_floor(rows, pos):
				errors.append("Area '%s' trigger '%s' is not on a floor cell." % [area_id, trigger_id])
				continue
			var key := "%d,%d" % [int(pos[0]), int(pos[1])]
			if occupied.has(key):
				errors.append("Area '%s' trigger '%s' overlaps %s." % [area_id, trigger_id, occupied[key]])
			occupied[key] = "trigger '%s'" % trigger_id
			var enc := String(trigger.get("encounter", ""))
			if enc != "" and not encounters.has(enc):
				errors.append("Area '%s' trigger '%s' references missing encounter '%s'." % [area_id, trigger_id, enc])
			for key_name in ["requires_flag", "requires_flag_not"]:
				var flag := String(trigger.get(key_name, ""))
				if flag != "" and not is_valid_flag(flag):
					errors.append("Area '%s' trigger '%s' has invalid %s '%s'." % [area_id, trigger_id, key_name, flag])


# ---------------------------------------------------------------- playtest staging

static func stage_playtest(draft: Dictionary) -> Dictionary:
	var campaign_id := String(draft.get("id", ""))
	if not is_valid_id(campaign_id):
		return {"ok": false, "message": "The campaign id is invalid; playtest cannot stage."}
	var root := PLAYTEST_ROOT.path_join(campaign_id)
	_remove_tree(root)
	var manifest: Dictionary = draft.duplicate(true)
	manifest.erase("areas")
	manifest.erase("quests")
	manifest.erase("encounters")
	manifest.erase("narration")
	manifest.erase("dialogues")
	manifest["content_root"] = root
	var errors := _write_files(draft, root, manifest)
	if not errors.is_empty():
		_remove_tree(root)
		return {"ok": false, "message": errors[0], "errors": errors}
	return {"ok": true, "message": "Staged playtest snapshot.", "root": root, "manifest": manifest}


static func cleanup_playtest(campaign_id: String) -> void:
	if is_valid_id(campaign_id):
		_remove_tree(PLAYTEST_ROOT.path_join(campaign_id))
