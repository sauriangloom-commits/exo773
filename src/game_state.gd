extends Node

## Autoload "Game": the single persistent game session.
##
## Presentation never mutates rules state directly. Screens call these methods
## and react to signals. Content is loaded once from res://content.

signal log_added(text: String)
signal state_changed
signal mode_changed(new_mode: String)
signal narration_requested(lines: Array)
signal combat_finished(result: String)
signal dialogue_finished(dialogue_id: String)

const DEFAULT_PARTY := ["kaelen", "sera", "aldric", "ysolde"]
## The platform's party-size ceiling and the authored fallbacks for a campaign
## that omits party limits. ContentDB validation accepts only 1..4 and min <= max,
## so these are the same values validation and the UI must agree on.
const PARTY_DEFAULT_MIN := 1
const PARTY_DEFAULT_MAX := 4
## Saves written before campaign packages existed belong to this campaign.
const LEGACY_CAMPAIGN_ID := "ravenloft_demo"
const SETTINGS_PATH := "user://settings.cfg"
## The settings file format this build writes. A file without a `[meta] version`
## is version 1 (everything written before versioning), and a file from a newer
## build is read with the same clamps but never rewritten, so its unknown keys
## and sections survive a downgrade. Redirected by tests like SaveSystem.save_dir.
const SETTINGS_VERSION := 1
const TEXT_SCALE_MIN := 0.8
const TEXT_SCALE_MAX := 1.6
const MAX_LOG := 400

var content: ContentDB
var campaigns: CampaignDB
var campaign: Dictionary = {}
var campaign_id := ""
var content_version := 1
var party: Array = []
var dungeon: Dungeon
var area_id := "old_gatehouse"
var area_states: Dictionary = {}
var quests: QuestLog
var flags: Dictionary = {}
var gold := 0
var rng := RandomNumberGenerator.new()
var seed_value := 0
var mode := "menu"
var position := Vector2i.ZERO
var facing := Dungeon.NORTH
var encounter: Encounter = null
var active_encounter_id := ""
var active_encounter_data: Dictionary = {}
var dialogue: DialogueRunner = null
var active_dialogue_id := ""
var log_lines: Array[String] = []
var victory_pending := false
var last_combat_log: Array[String] = []
var last_combat_result := ""
var content_ready := false
var settings: Dictionary = {}
var settings_path := SETTINGS_PATH
## True when the file on disk was written by a newer build: known keys are read
## (and clamped) but `save_settings` holds back so the newer file is not damaged.
var settings_newer := false
var last_ui_message := ""
var _encounter_resolved := false
## A playtest runs the ordinary campaign systems but may never write a save.
var playtest_mode := false
## Temporary package root for the current playtest; deleted when it ends.
var playtest_root := ""


func _ready() -> void:
	# A headless CI process has no window manager, so the dummy window starts at a
	# handful of pixels while the real game refuses to run below 1280x720. Since
	# the logical layout surface now follows the client, pin the minimum here so
	# headless layout checks measure the same surface a player gets.
	if DisplayServer.get_name() == "headless":
		var headless_window := get_window()
		headless_window.size = Vector2i(
			maxi(headless_window.size.x, 1280),
			maxi(headless_window.size.y, 720)
		)
	campaigns = CampaignDB.new()
	campaigns.load_registry()
	for campaign_error in campaigns.errors:
		push_warning("CAMPAIGN REGISTRY: " + campaign_error)
	content = ContentDB.new()
	content.load_all()
	campaign_id = content.campaign_id
	campaign = content.campaign.duplicate(true)
	content_version = content.content_version
	content_ready = content.errors.is_empty()
	settings = default_settings()
	load_settings()
	for error in content.errors:
		push_warning("CONTENT: " + error)
	call_deferred("_apply_settings")


func default_settings() -> Dictionary:
	return {
		"master": 0.9,
		"music": 0.55,
		"sfx": 0.8,
		"ambience": 0.6,
		"text_scale": 1.0,
		"fullscreen": false,
		"keybinds": {},
	}


# ---------------------------------------------------------------- new / load

## The single interpretation of a campaign's declared party limits, shared by
## party selection and new_game. `source` is a campaign manifest; an empty
## dictionary means the loaded campaign. ContentDB already rejects out-of-range
## authored values, so the clamps only keep a malformed manifest from producing
## a different answer here than it did in validation.
func party_limits(source: Dictionary = {}) -> Dictionary:
	var manifest: Dictionary = campaign if source.is_empty() else source
	var cfg: Dictionary = manifest.get("party", {})
	var max_party := clampi(int(cfg.get("max", PARTY_DEFAULT_MAX)), 1, PARTY_DEFAULT_MAX)
	var min_party := clampi(int(cfg.get("min", PARTY_DEFAULT_MIN)), 1, max_party)
	return {"min": min_party, "max": max_party}


## "" when the size is allowed; otherwise the reason the campaign's own range
## gives. Presentation and new_game use this one wording.
func party_size_error(count: int, source: Dictionary = {}) -> String:
	var limits := party_limits(source)
	var minimum := int(limits["min"])
	var maximum := int(limits["max"])
	if count < minimum:
		return "Choose at least %s adventurer%s." % [_party_count_word(minimum), "" if minimum == 1 else "s"]
	if count > maximum:
		return "Choose at most %s adventurers." % _party_count_word(maximum)
	return ""


## The declared range as prose: "one to four", or "three" for a fixed size.
func party_range_text(source: Dictionary = {}) -> String:
	var limits := party_limits(source)
	var minimum := int(limits["min"])
	var maximum := int(limits["max"])
	if minimum == maximum:
		return _party_count_word(minimum)
	return "%s to %s" % [_party_count_word(minimum), _party_count_word(maximum)]


func _party_count_word(value: int) -> String:
	match value:
		1:
			return "one"
		2:
			return "two"
		3:
			return "three"
		4:
			return "four"
	return str(value)


## Authoritative new-game entry point.
##
## Everything that can refuse the request is checked before any live state is
## replaced, so a refused request cannot change the current session, campaign,
## quests or save slots. A campaign switch is resolved from the registry and
## validated against the requested party first, then committed.
func new_game(character_ids: Array = [], forced_seed := -1, campaign_key := "") -> Dictionary:
	training_mode = false
	var switching := campaign_key != "" and campaign_key != campaign_id
	var target: Dictionary = campaign
	if switching:
		if campaigns == null:
			campaigns = CampaignDB.new()
			campaigns.load_registry()
		if not campaigns.has(campaign_key):
			# A campaign created in this session may not be in the cached registry.
			campaigns.load_registry()
		if not campaigns.has(campaign_key):
			var missing := "Campaign '%s' is not installed." % campaign_key
			return {"ok": false, "message": missing, "errors": [missing]}
		target = campaigns.get_campaign(campaign_key)
	if not character_ids.is_empty():
		var refused := party_size_error(character_ids.size(), target)
		if refused != "":
			return {"ok": false, "message": refused}
	if switching:
		var switched := load_campaign(campaign_key)
		if not bool(switched.get("ok", false)):
			return switched
	if campaign.is_empty() or campaign_id == "":
		return {"ok": false, "message": "No campaign is loaded."}
	if not content_ready:
		return {"ok": false, "message": "Content failed validation; see the log for details."}
	var party_cfg: Dictionary = campaign.get("party", {})
	var defaults: Array = Array(party_cfg.get("default", DEFAULT_PARTY))
	var ids: Array = character_ids if not character_ids.is_empty() else defaults
	var refused_size := party_size_error(ids.size())
	if refused_size != "":
		return {"ok": false, "message": refused_size}
	var built: Array = []
	for id in ids:
		var data := content.get_character(String(id))
		if data.is_empty():
			return {"ok": false, "message": "Unknown character '%s'." % id}
		built.append(Character.from_content(data, content.items))
	var entry: Dictionary = campaign.get("entry", {})
	var entry_area := String(entry.get("area", ""))
	if built.is_empty() or entry_area == "" or content.get_area(entry_area).is_empty():
		return {"ok": false, "message": "Campaign '%s' has no valid entry area." % campaign_id}
	# Checks are complete. Only now does the live session change.
	party = built
	seed_value = forced_seed if forced_seed >= 0 else randi()
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	area_id = entry_area
	area_states = {}
	dungeon = _new_dungeon(area_id)
	quests = QuestLog.new()
	quests.setup(content.quests)
	var start_quest := String(campaign.get("start_quest", ""))
	if start_quest != "":
		quests.start(start_quest)
	flags = {}
	gold = 0
	log_lines.clear()
	encounter = null
	dialogue = null
	active_encounter_id = ""
	active_dialogue_id = ""
	victory_pending = false
	last_combat_log.clear()
	last_combat_result = ""
	_encounter_resolved = false
	var entry_pos: Array = entry.get("pos", [])
	if entry_pos.size() == 2:
		position = Vector2i(int(entry_pos[0]), int(entry_pos[1]))
	else:
		position = dungeon.start_pos
	facing = int(entry.get("facing", dungeon.start_facing)) % 4
	dungeon.visit(position)
	_set_mode("explore")
	var intro: Array = content.narration.get("intro", [])
	for line in intro:
		_log(String(line))
	_log("Party: " + _party_names())
	_log(String(content.narration.get("controls_hint", "")))
	_log("Seed: %d (used for all rolls in this run)." % seed_value)
	emit_signal("narration_requested", intro)
	emit_signal("state_changed")
	return {"ok": true, "message": "New game started."}


func _new_dungeon(id: String) -> Dungeon:
	var data := content.get_area(id)
	if data.is_empty():
		data = content.dungeon_data
	var result := Dungeon.new()
	result.setup(data)
	return result


func _party_names() -> String:
	var names: Array[String] = []
	for ch in party:
		names.append(ch.display_name)
	return ", ".join(names)


# ---------------------------------------------------------------- campaigns

## Loads one campaign package into a fresh ContentDB. Live session state is only
## replaced after the whole package validates, so a broken package cannot leave
## the game half-switched.
func load_campaign(id: String) -> Dictionary:
	if campaigns == null:
		campaigns = CampaignDB.new()
		campaigns.load_registry()
	if not campaigns.has(id):
		# A campaign created in this session may not be in the cached registry.
		campaigns.load_registry()
	if not campaigns.has(id):
		return {"ok": false, "message": "Campaign '%s' is not installed." % id, "errors": ["Campaign '%s' is not installed." % id]}
	var manifest := campaigns.get_campaign(id)
	var db := ContentDB.new()
	db.load_campaign(manifest)
	if not db.errors.is_empty():
		return {
			"ok": false,
			"message": "Campaign '%s' failed validation: %s" % [id, db.errors[0]],
			"errors": db.errors.duplicate(),
		}
	content = db
	campaign = manifest
	campaign_id = id
	content_version = content.content_version
	content_ready = true
	return {"ok": true, "message": "Loaded campaign '%s'." % id, "errors": []}


## Loads a staged creator snapshot. Unlike load_campaign(), this never reads or
## writes the deliberately saved user package; the caller owns the temporary
## root and Game.abandon_playtest() removes it.
func load_campaign_snapshot(manifest: Dictionary) -> Dictionary:
	var snapshot_id := String(manifest.get("id", ""))
	if snapshot_id == "":
		return {"ok": false, "message": "Playtest snapshot has no campaign id."}
	var db := ContentDB.new()
	db.load_campaign(manifest)
	if not db.errors.is_empty():
		return {"ok": false, "message": "Playtest snapshot failed validation: %s" % db.errors[0], "errors": db.errors.duplicate()}
	content = db
	campaign = manifest
	campaign_id = snapshot_id
	content_version = content.content_version
	content_ready = true
	return {"ok": true, "message": "Loaded playtest snapshot '%s'." % snapshot_id, "errors": []}


## Validates a campaign without switching to it. Used by the campaign screen and
## by the command-line validator.
func refresh_campaigns() -> void:
	campaigns = CampaignDB.new()
	campaigns.load_registry()


## Validates an unsaved creator draft through a temporary package copy.
func validate_campaign_draft(draft: Dictionary) -> Dictionary:
	return CampaignStore.validate_draft(draft)


## Structured companion to validate_campaign_draft. Legacy errors that have no
## rich location are wrapped as advanced diagnostics rather than parsed.
func validate_campaign_draft_diagnostics(draft: Dictionary) -> Dictionary:
	var result := validate_campaign_draft(draft)
	var diagnostics := CampaignStore.diagnose_draft(draft)
	var seen := {}
	for raw in diagnostics:
		seen[String(Dictionary(raw).get("message", ""))] = true
	for raw_error in Array(result.get("errors", [])):
		var message := String(raw_error)
		if not seen.has(message):
			diagnostics.append(ContentDiagnostics.wrap_legacy(message, String(draft.get("id", "")), "draft"))
			seen[message] = true
	return {
		"ok": bool(result.get("ok", false)),
		"errors": Array(result.get("errors", [])).duplicate(),
		"diagnostics": diagnostics,
	}


## Structured diagnostics for an installed campaign, used by command-line tools.
func diagnose_campaign(id: String) -> Dictionary:
	if campaigns == null:
		campaigns = CampaignDB.new()
		campaigns.load_registry()
	if not campaigns.has(id):
		var missing := [ContentDiagnostics.wrap_legacy("Campaign '%s' is not installed." % id, id)]
		return {"ok": false, "diagnostics": missing}
	if CampaignStore.is_bundled_id(id):
		return _diagnostics_from_validation(id, validate_campaign(id), "res://content/campaigns/%s" % id)
	# Validate through the same content loader as the CLI first. Its structured
	# diagnostics carry the damaged file and parser line, and an invalid package
	# must not reach the creator draft path at all.
	var validation := validate_campaign(id)
	if not bool(validation.get("ok", true)):
		return _diagnostics_from_validation(id, validation, "user://campaigns/%s" % id)
	var loaded := CampaignStore.load_package(id)
	if not bool(loaded.get("ok", false)):
		var load_diags := []
		# The package reader knows the damaged file, its parser line and a stable
		# code; keep them instead of flattening the refusal to one generic rule.
		for raw in Array(loaded.get("diagnostics", [])):
			var entry := Dictionary(raw).duplicate(true)
			entry["campaign"] = id
			load_diags.append(entry)
		if load_diags.is_empty():
			for raw_error in Array(loaded.get("errors", [loaded.get("message", "Campaign could not be loaded.")])):
				load_diags.append(ContentDiagnostics.make("package.load", "error", String(raw_error), {
					"campaign": id,
					"source": "user://campaigns/%s" % id,
					"section": "advanced",
					"advanced": true,
				}))
		return {"ok": false, "diagnostics": load_diags}
	var diagnostics := CampaignStore.diagnose_draft(Dictionary(loaded.get("draft", {})))
	var seen := {}
	for raw in diagnostics:
		seen[String(Dictionary(raw).get("message", ""))] = true
	# The package reader records file, parser line and stable code; carry those
	# through instead of re-wrapping the same message as a location-less rule.
	for raw in Array(validation.get("diagnostics", [])):
		var message := String(Dictionary(raw).get("message", ""))
		if not seen.has(message):
			diagnostics.append(raw)
			seen[message] = true
	for raw_error in Array(validation.get("errors", [])):
		var message := String(raw_error)
		if not seen.has(message):
			diagnostics.append(ContentDiagnostics.wrap_legacy(message, id, id))
			seen[message] = true
	return {"ok": bool(validation.get("ok", false)), "diagnostics": diagnostics}


## Ends a creator playtest without touching campaign progress or saves. The
## caller returns to the creator screen with its in-memory draft.
func abandon_playtest() -> void:
	playtest_mode = false
	if playtest_root != "":
		CampaignStore.cleanup_playtest(campaign_id)
		playtest_root = ""
	encounter = null
	dialogue = null
	active_encounter_id = ""
	active_dialogue_id = ""
	area_states = {}
	flags = {}
	quests = null
	party = []
	log_lines.clear()
	victory_pending = false
	mode = "menu"


func validate_campaign(id: String) -> Dictionary:
	if campaigns == null:
		campaigns = CampaignDB.new()
		campaigns.load_registry()
	if not campaigns.has(id):
		return {"ok": false, "errors": ["Campaign '%s' is not installed." % id], "diagnostics": []}
	var db := ContentDB.new()
	db.load_campaign(campaigns.get_campaign(id))
	return {
		"ok": db.errors.is_empty(),
		"errors": db.errors.duplicate(),
		"diagnostics": db.diagnostics.duplicate(),
		"title": String(campaigns.get_campaign(id).get("title", id)),
	}


## Structured form of one validation result. Source-recorded diagnostics keep
## their file, code and line; semantic errors with no reliable source mapping are
## wrapped as advanced rules rather than given an invented location.
func _diagnostics_from_validation(id: String, validation: Dictionary, source: String) -> Dictionary:
	var diagnostics := []
	var seen := {}
	for raw in Array(validation.get("diagnostics", [])):
		var message := String(Dictionary(raw).get("message", ""))
		diagnostics.append(raw)
		seen[message] = true
	for raw_error in Array(validation.get("errors", [])):
		var message := String(raw_error)
		if not seen.has(message):
			diagnostics.append(ContentDiagnostics.wrap_legacy(message, id, source))
			seen[message] = true
	return {"ok": bool(validation.get("ok", false)), "diagnostics": diagnostics}


func serialize() -> Dictionary:
	var party_data: Array = []
	for ch in party:
		party_data.append(ch.to_dict())
	var saved_areas := area_states.duplicate(true)
	if dungeon != null:
		saved_areas[area_id] = dungeon.serialize()
	return {
		"summary": "%s — %d gold — %s" % [dungeon.display_name, gold, _party_names()],
		"campaign_id": campaign_id,
		"content_version": content_version,
		"seed": seed_value,
		"rng_state": str(rng.state),
		"party": party_data,
		"area_id": area_id,
		"areas": saved_areas,
		"dungeon": dungeon.serialize(),
		"position": [position.x, position.y],
		"facing": facing,
		"flags": flags.duplicate(true),
		"quests": quests.serialize(),
		"gold": gold,
		"log": log_lines.slice(maxi(0, log_lines.size() - 80)),
		"mode": "explore",
	}


func save_game(slot := "slot1") -> Dictionary:
	if not content_ready:
		return {"ok": false, "message": "Content is not loaded."}
	if campaign_id == "":
		return {"ok": false, "message": "No campaign is loaded."}
	if playtest_mode:
		return {"ok": false, "message": "Saving is disabled during a campaign playtest.", "playtest": true}
	if mode != "explore":
		return {"ok": false, "message": "You can only save while exploring — not in combat or dialogue."}
	# Never overwrite a save that belongs to another campaign or to a different
	# content version. Refusing is recoverable; a silent overwrite is not.
	var existing := SaveSystem.read_save(slot, campaign_id)
	if bool(existing.get("ok", false)):
		var existing_data: Dictionary = existing["data"]
		var existing_campaign := String(existing_data.get("campaign_id", ""))
		if existing_campaign != campaign_id:
			return {
				"ok": false,
				"message": "Save '%s' belongs to campaign '%s' and was not overwritten." % [slot, existing_campaign],
			}
		if int(existing_data.get("content_version", 0)) != content_version:
			return {
				"ok": false,
				"message": "Save '%s' was made for content version %s; this campaign is version %d. The older save was not overwritten." % [slot, existing_data.get("content_version", "?"), content_version],
			}
	var result := SaveSystem.write_save(slot, serialize(), campaign_id)
	if bool(result["ok"]):
		if slot == "auto":
			_log("Autosaved.")
		else:
			_log("Game saved to %s." % slot)
	return result


func load_game(slot: String) -> Dictionary:
	var read := SaveSystem.read_save(slot, campaign_id)
	if not bool(read.get("ok", false)) and campaign_id != "" and not SaveSystem.exists(slot, campaign_id):
		# Pre-campaign saves live in the legacy directory. They are read as
		# Ravenloft demo saves and never rewritten in place. Only a missing
		# namespaced file falls back; a corrupt or unsupported save must keep its
		# own explanation.
		read = SaveSystem.read_save(slot)
	if not bool(read.get("ok", false)):
		return read
	var data: Dictionary = read["data"]
	var saved_campaign := String(data.get("campaign_id", ""))
	if saved_campaign == "":
		saved_campaign = LEGACY_CAMPAIGN_ID
	if saved_campaign != campaign_id:
		var switched := load_campaign(saved_campaign)
		if not bool(switched.get("ok", false)):
			return {
				"ok": false,
				"message": "Save '%s' belongs to campaign '%s', which is not installed or invalid: %s" % [slot, saved_campaign, switched.get("message", "")],
			}
	if int(data.get("content_version", 1)) != content_version:
		return {
			"ok": false,
			"message": "Save '%s' was made for campaign content version %s; the installed campaign is version %d. The save was not modified." % [slot, data.get("content_version", "?"), content_version],
		}
	if not content_ready:
		return {"ok": false, "message": "Content failed validation; cannot load."}

	# Validate the complete payload before replacing any live session state.
	var party_data: Variant = data.get("party", [])
	if not party_data is Array or Array(party_data).is_empty():
		return {"ok": false, "message": "Save contains no valid party members."}
	var loaded_party: Array = []
	for raw_entry in Array(party_data):
		if not raw_entry is Dictionary:
			return {"ok": false, "message": "Save contains an invalid party entry."}
		var entry: Dictionary = raw_entry
		var character_id: String = str(entry.get("id", ""))
		if character_id == "" or content.get_character(character_id).is_empty():
			return {"ok": false, "message": "Save references missing character '%s'." % character_id}
		var equipment: Variant = entry.get("equipment", {})
		if not equipment is Dictionary:
			return {"ok": false, "message": "Save contains invalid equipment data."}
		for slot_name in Dictionary(equipment).keys():
			var item_id: String = str(Dictionary(equipment)[slot_name])
			if content.get_item(item_id).is_empty():
				return {"ok": false, "message": "Save references missing item '%s'." % item_id}
		var inventory: Variant = entry.get("inventory", [])
		if not inventory is Array:
			return {"ok": false, "message": "Save contains invalid inventory data."}
		for raw_item in Array(inventory):
			if not raw_item is Dictionary:
				return {"ok": false, "message": "Save contains an invalid inventory entry."}
			var item_id: String = str(Dictionary(raw_item).get("id", ""))
			if content.get_item(item_id).is_empty():
				return {"ok": false, "message": "Save references missing item '%s'." % item_id}
		loaded_party.append(Character.from_dict(entry, content.items))

	var dungeon_data: Variant = data.get("dungeon", {})
	if not dungeon_data is Dictionary:
		return {"ok": false, "message": "Save contains invalid dungeon state."}
	for key in ["open_doors", "searched"]:
		if not Dictionary(dungeon_data).get(key, {}) is Dictionary:
			return {"ok": false, "message": "Save contains invalid dungeon state."}
	for key in ["removed", "visited"]:
		if not Dictionary(dungeon_data).get(key, []) is Array:
			return {"ok": false, "message": "Save contains invalid dungeon state."}
	var quest_data: Variant = data.get("quests", {})
	if not quest_data is Dictionary:
		return {"ok": false, "message": "Save contains invalid quest state."}
	var saved_flags: Variant = data.get("flags", {})
	if not saved_flags is Dictionary:
		return {"ok": false, "message": "Save contains invalid flag state."}
	var pos_data: Variant = data.get("position", [])
	if not pos_data is Array or Array(pos_data).size() < 2:
		return {"ok": false, "message": "Save contains an invalid position."}
	var px: String = str(Array(pos_data)[0])
	var py: String = str(Array(pos_data)[1])
	# JSON numbers are parsed as floats; accept "3" and "3.0" alike, then convert
	# explicitly to the integer grid coordinate used by the dungeon.
	if not px.is_valid_float() or not py.is_valid_float():
		return {"ok": false, "message": "Save contains a non-numeric position."}
	var seed_text: String = str(data.get("seed", "0"))
	var rng_text: String = str(data.get("rng_state", "0"))
	var gold_text: String = str(data.get("gold", "0"))
	var facing_text: String = str(data.get("facing", "0"))
	if not seed_text.is_valid_float() or not rng_text.is_valid_int() or not gold_text.is_valid_float() or not facing_text.is_valid_float():
		return {"ok": false, "message": "Save contains invalid numeric state."}
	var facing_value := int(float(facing_text))
	if facing_value < 0 or facing_value > 3:
		return {"ok": false, "message": "Save contains an invalid facing."}
	var log_data: Variant = data.get("log", [])
	if not log_data is Array:
		return {"ok": false, "message": "Save contains an invalid log."}

	var default_entry: Dictionary = campaign.get("entry", {})
	var loaded_area_id := String(data.get("area_id", default_entry.get("area", "")))
	if loaded_area_id == "" and not content.areas.is_empty():
		loaded_area_id = String(content.areas.keys()[0])
	if content.get_area(loaded_area_id).is_empty():
		return {"ok": false, "message": "Save references missing area '%s'." % loaded_area_id}
	var loaded_areas: Dictionary = {}
	var raw_areas: Variant = data.get("areas", {})
	if not raw_areas is Dictionary:
		return {"ok": false, "message": "Save contains invalid area state."}
	for saved_area_key in Dictionary(raw_areas).keys():
		var saved_area_id := String(saved_area_key)
		if content.get_area(saved_area_id).is_empty():
			return {"ok": false, "message": "Save references missing area '%s'." % saved_area_id}
		if not Dictionary(raw_areas)[saved_area_key] is Dictionary:
			return {"ok": false, "message": "Save contains invalid state for area '%s'." % saved_area_id}
		loaded_areas[saved_area_id] = Dictionary(Dictionary(raw_areas)[saved_area_key]).duplicate(true)
	var current_area_state: Dictionary = Dictionary(dungeon_data)
	if loaded_areas.has(loaded_area_id):
		current_area_state = Dictionary(loaded_areas[loaded_area_id])
	var new_dungeon := _new_dungeon(loaded_area_id)
	new_dungeon.apply_state(current_area_state)
	# Saved progress is only restorable against quests this package still defines.
	# Dropping an unknown quest or objective would silently erase progress, so the
	# load is refused before any live state changes.
	for raw_quest_id in Dictionary(quest_data).keys():
		var saved_quest_id := String(raw_quest_id)
		var quest_definition := content.get_quest(saved_quest_id)
		if quest_definition.is_empty():
			return {"ok": false, "message": "Save references quest '%s', which this campaign no longer defines. The save was not modified." % saved_quest_id}
		var saved_quest: Variant = Dictionary(quest_data)[raw_quest_id]
		if saved_quest is Dictionary and Dictionary(saved_quest).get("objectives", {}) is Dictionary:
			var known_objectives := {}
			for raw_objective in Array(quest_definition.get("objectives", [])):
				if raw_objective is Dictionary:
					known_objectives[String(Dictionary(raw_objective).get("id", ""))] = true
			for raw_objective_id in Dictionary(Dictionary(saved_quest)["objectives"]).keys():
				var objective_id := String(raw_objective_id)
				if not known_objectives.has(objective_id):
					return {"ok": false, "message": "Save references objective '%s' of quest '%s', which this campaign no longer defines. The save was not modified." % [objective_id, saved_quest_id]}
	var new_quests := QuestLog.new()
	new_quests.setup(content.quests)
	new_quests.apply_state(Dictionary(quest_data))
	var loaded_position := Vector2i(int(float(px)), int(float(py)))
	# Never guess at a saved location. A content edit that moved a wall or shrank
	# the area must refuse the load, not teleport the party or leave it in a wall.
	if not new_dungeon.in_bounds(loaded_position):
		return {"ok": false, "message": "Save position (%d, %d) is outside area '%s'; the area changed since the save. The save was not modified." % [loaded_position.x, loaded_position.y, loaded_area_id]}
	if not new_dungeon.is_walkable(loaded_position):
		return {"ok": false, "message": "Save position (%d, %d) is blocked in area '%s'; the area changed since the save. The save was not modified." % [loaded_position.x, loaded_position.y, loaded_area_id]}
	var loaded_rng := RandomNumberGenerator.new()
	loaded_rng.seed = int(float(seed_text))
	loaded_rng.state = int(rng_text)

	party = loaded_party
	seed_value = int(float(seed_text))
	rng = loaded_rng
	area_id = loaded_area_id
	area_states = loaded_areas
	dungeon = new_dungeon
	quests = new_quests
	flags = Dictionary(saved_flags).duplicate(true)
	gold = int(float(gold_text))
	position = loaded_position
	facing = facing_value
	encounter = null
	dialogue = null
	active_encounter_id = ""
	active_dialogue_id = ""
	victory_pending = false
	last_combat_log.clear()
	last_combat_result = ""
	_encounter_resolved = false
	log_lines.clear()
	for line in Array(log_data):
		log_lines.append(str(line))
	_set_mode("explore")
	_log("Loaded %s (%s)." % [slot, str(data.get("saved_at", ""))])
	emit_signal("state_changed")
	return {"ok": true, "message": "Loaded %s." % slot}


func has_save(slot := "auto") -> bool:
	if SaveSystem.exists(slot, campaign_id):
		return true
	return campaign_id == LEGACY_CAMPAIGN_ID and SaveSystem.exists(slot)


func has_campaign_save(id: String) -> bool:
	return SaveSystem.has_saves(id)


func has_any_save() -> bool:
	if campaigns != null:
		for id in campaigns.order:
			if SaveSystem.has_saves(String(id)):
				return true
	return SaveSystem.any_legacy_save()


## Saves for the loaded campaign; legacy files are included for the campaign
## they belong to, so an older install's progress stays visible.
func list_saves() -> Array:
	var saves := SaveSystem.list_saves(campaign_id)
	if campaign_id == LEGACY_CAMPAIGN_ID:
		for legacy in SaveSystem.list_saves(""):
			var legacy_slot := String(Dictionary(legacy)["slot"])
			var duplicate := false
			for entry in saves:
				if String(Dictionary(entry)["slot"]) == legacy_slot:
					duplicate = true
					break
			if not duplicate:
				saves.append(legacy)
	saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("saved_unix", 0)) > int(b.get("saved_unix", 0))
	)
	return saves


## Newest save across every installed campaign; loading it switches campaigns
## explicitly rather than mixing two packages in one session.
func continue_latest() -> Dictionary:
	var best_campaign := ""
	var best_slot := ""
	var best_time := -1
	if campaigns != null:
		for id in campaigns.order:
			var saves := SaveSystem.list_saves(String(id))
			if saves.is_empty():
				continue
			var newest: Dictionary = saves[0]
			if int(newest.get("saved_unix", 0)) > best_time:
				best_time = int(newest.get("saved_unix", 0))
				best_campaign = String(id)
				best_slot = String(newest["slot"])
	if best_slot == "":
		var legacy := SaveSystem.list_saves("")
		if legacy.is_empty():
			return {"ok": false, "message": "No saves found."}
		best_campaign = LEGACY_CAMPAIGN_ID
		best_slot = String(Dictionary(legacy[0])["slot"])
	if best_campaign != campaign_id:
		var switched := load_campaign(best_campaign)
		if not bool(switched.get("ok", false)):
			return switched
	return load_game(best_slot)


func _log(text: String) -> void:
	if text == "":
		return
	log_lines.append(text)
	if log_lines.size() > MAX_LOG:
		log_lines = log_lines.slice(log_lines.size() - MAX_LOG)
	emit_signal("log_added", text)


func log(text: String) -> void:
	_log(text)


## A refusal with one player-visible home: the returned dictionary, the last-UI
## message and the exploration log.
##
## Refusals used to set `last_ui_message` and return without logging, and no UI
## reads that variable, so a blocked step into a wall produced no feedback at
## all. A consecutive identical line is not logged twice: walking into the same
## wall should not bury the log under duplicates. The return shape is unchanged
## for every caller (`{"ok": false, "message": text}`).
func _refuse(text: String) -> Dictionary:
	last_ui_message = text
	if log_lines.is_empty() or String(log_lines[log_lines.size() - 1]) != text:
		_log(text)
	return {"ok": false, "message": text}


func _set_mode(new_mode: String) -> void:
	if mode == new_mode:
		return
	mode = new_mode
	emit_signal("mode_changed", mode)


# ---------------------------------------------------------------- exploration

func turn_left() -> void:
	if mode != "explore":
		return
	facing = (facing + 3) % 4
	emit_signal("state_changed")


func turn_right() -> void:
	if mode != "explore":
		return
	facing = (facing + 1) % 4
	emit_signal("state_changed")


func move_forward() -> Dictionary:
	return _step(Dungeon.DIRS[facing])


func move_back() -> Dictionary:
	return _step(-Dungeon.DIRS[facing])


func strafe_left() -> Dictionary:
	return _step(Dungeon.DIRS[(facing + 3) % 4])


func strafe_right() -> Dictionary:
	return _step(Dungeon.DIRS[(facing + 1) % 4])


func _step(delta: Vector2i) -> Dictionary:
	if mode != "explore":
		return {"ok": false, "message": "You cannot move right now."}
	var dest := position + delta
	if not dungeon.in_bounds(dest) or dungeon.is_wall(dest):
		return _refuse("Cold stone blocks the way.")
	var door := dungeon.door_at(dest)
	if not door.is_empty() and not dungeon.is_door_open(dest):
		return _refuse("%s is closed. Press F to open it." % String(door.get("name", "The door")))
	var npc := dungeon.npc_at(dest)
	if not npc.is_empty():
		return _refuse("%s is in the way." % String(npc.get("name", "Someone")))
	var first_visit := not dungeon.visited.has(dest)
	position = dest
	dungeon.visit(position)
	if first_visit:
		_log(dungeon.describe_view(position, facing))
	_play("step")
	_process_triggers()
	emit_signal("state_changed")
	return {"ok": true, "message": ""}


func look() -> String:
	if dungeon == null:
		return ""
	return dungeon.describe_view(position, facing)


func interact() -> Dictionary:
	if mode != "explore":
		return {"ok": false, "message": "Nothing to interact with right now."}
	var target := dungeon.front_target(position, facing)
	match String(target.get("kind", "")):
		"npc":
			var npc: Dictionary = target["data"]
			var dialogue_id := String(npc.get("dialogue", ""))
			_log(String(npc.get("look", "")))
			return start_dialogue(dialogue_id)
		"object":
			return _interact_object(Dictionary(target["data"]))
		"door":
			return _try_open_door(Dictionary(target["data"]))
		"wall":
			last_ui_message = "A cold stone wall. Nothing here but mortar and damp."
			_log(last_ui_message)
		_:
			return _refuse("There is nothing within reach.")
	return {"ok": false, "message": last_ui_message}


## Take 10/20 on the skill check offered by the object or door ahead. Like the
## tabletop action, it uses the best available party member and reports the
## reason when no check is possible (PHB p.65).
func interact_with_take(take: int) -> Dictionary:
	if mode != "explore":
		return {"ok": false, "message": "Take 10 or 20 is only available while exploring."}
	if take != 10 and take != 20:
		return {"ok": false, "message": "Take must be 10 or 20."}
	var target := dungeon.front_target(position, facing)
	match String(target.get("kind", "")):
		"object":
			return _interact_object(Dictionary(target["data"]), take)
		"door":
			return _try_open_door(Dictionary(target["data"]), take)
		_:
			last_ui_message = "Nothing ahead calls for a careful skill check."
			_log(last_ui_message)
			return {"ok": false, "message": last_ui_message}


func _try_open_door(door: Dictionary, take := 0) -> Dictionary:
	if not bool(door.get("locked", false)):
		_open_door(door, "The %s opens." % String(door.get("name", "door")).to_lower())
		return {"ok": true, "message": "Door opened."}
	var key_item := String(door.get("key_item", ""))
	if key_item != "" and _party_item_count(key_item) > 0:
		_open_door(door, "You fit the %s and turn it. The lock gives." % key_item.replace("_", " "))
		return {"ok": true, "message": "Door unlocked with key."}
	var actor := _best_skill_actor("open_lock")
	if actor == null:
		return _refuse("No one can pick the lock.")
	var dc := int(door.get("lock_dc", 15))
	var check := Rules.skill_check(rng, actor, "open_lock", dc, {"take": take})
	if not bool(check.get("available", true)):
		last_ui_message = String(check.get("reason", "No one can pick the lock."))
		_log(last_ui_message)
		return {"ok": false, "message": last_ui_message}
	var roll_text := "d20(%d)" % int(check["roll"])
	if take != 0:
		roll_text = "take %d → %d" % [take, int(check["roll"])]
	var text := "%s works the lock: %s%+d = %d vs DC %d — %s" % [
		actor.display_name,
		roll_text,
		int(check["bonus"]),
		int(check["total"]),
		dc,
		"success" if bool(check["success"]) else "failure",
	]
	_log(text)
	last_ui_message = text
	if bool(check["success"]):
		_open_door(door, "The lock clicks open.")
		_play("door")
		return {"ok": true, "message": text}
	_play("miss")
	return {"ok": false, "message": text}


func _open_door(door: Dictionary, message: String) -> void:
	var door_id := String(door.get("id", ""))
	dungeon.set_door_open(door_id, true)
	var open_flag := String(door.get("open_flag", ""))
	if open_flag != "":
		flags[open_flag] = true
	_log(message)
	_play("door")
	_sync_quests()
	emit_signal("state_changed")


func _interact_object(obj: Dictionary, take := 0) -> Dictionary:
	var obj_id := String(obj.get("id", ""))
	if dungeon.is_removed(obj_id):
		return _refuse("There is nothing left here.")
	_log(String(obj.get("look", "")))
	for interaction in Array(obj.get("interactions", [])):
		var i: Dictionary = interaction
		var required_item := String(i.get("requires_item", ""))
		if required_item != "" and _party_item_count(required_item) <= 0:
			var blocked := String(i.get("blocked_text", "You lack what that requires."))
			last_ui_message = blocked
			_log(blocked)
			return {"ok": false, "message": blocked}
		var required_flag := String(i.get("requires_flag", ""))
		if required_flag != "" and not bool(flags.get(required_flag, false)):
			continue
		var forbidden_flag := String(i.get("requires_flag_not", ""))
		if forbidden_flag != "" and bool(flags.get(forbidden_flag, false)):
			continue
		return _run_interaction(obj, i, take)
	return _refuse("You find nothing you can use.")


func _run_interaction(obj: Dictionary, interaction: Dictionary, take := 0) -> Dictionary:
	var skill := String(interaction.get("skill", ""))
	var success := true
	if skill != "":
		var actor := _best_skill_actor(skill)
		if actor == null:
			return _refuse("No conscious adventurer can attempt that.")
		var dc := int(interaction.get("dc", 10))
		var check := Rules.skill_check(
			rng,
			actor,
			skill,
			dc,
			{"take": take, "failure_penalty": bool(interaction.get("failure_penalty", false))}
		)
		if not bool(check.get("available", true)):
			last_ui_message = String(check.get("reason", "That check is unavailable."))
			_log(last_ui_message)
			return {"ok": false, "message": last_ui_message}
		var roll_text := "d20(%d)" % int(check["roll"])
		if take != 0:
			roll_text = "take %d → %d" % [take, int(check["roll"])]
		var text := "%s attempts %s: %s%+d = %d vs DC %d — %s" % [
			actor.display_name,
			String(interaction.get("label", "the check")),
			roll_text,
			int(check["bonus"]),
			int(check["total"]),
			dc,
			"success" if bool(check["success"]) else "failure",
		]
		_log(text)
		last_ui_message = text
		success = bool(check["success"])
	if success:
		var success_text := String(interaction.get("success_text", ""))
		if success_text != "":
			_log(success_text)
		var effects := Array(interaction.get("success_effects", []))
		if effects.is_empty():
			effects = Array(interaction.get("effects", []))
		apply_effects(effects, "object:%s" % obj.get("id", ""))
		var one_time := bool(interaction.get("once", false))
		if one_time:
			dungeon.mark_removed(String(obj.get("id", "")))
		_play("ui")
		emit_signal("state_changed")
		_autosave_after_interaction(one_time or _effects_change_world(effects))
		return {"ok": true, "message": success_text}
	var failure_text := String(interaction.get("failure_text", "Nothing happens."))
	_log(failure_text)
	_play("miss")
	emit_signal("state_changed")
	return {"ok": false, "message": failure_text}


## Autosave boundary for object interactions. The write happens only after every
## effect and the once-only removal have been applied, so a partially resolved
## interaction can never reach disk. An interaction that hands control to combat
## or dialogue is left to those systems' own save boundaries.
func _autosave_after_interaction(state_changed: bool) -> void:
	if not state_changed or not content_ready or mode != "explore" or playtest_mode:
		return
	var result := save_game("auto")
	if bool(result.get("ok", false)):
		return
	# Never let a failed write look like a successful one.
	last_ui_message = "Autosave failed: %s" % String(result.get("message", "Autosave failed."))
	_log(last_ui_message)


## Narration is presentation, not world state. Every other effect type changes
## something that has to survive a reload.
func _effects_change_world(effects: Array) -> bool:
	for effect in effects:
		if effect is Dictionary and String(Dictionary(effect).get("type", "")) != "narration":
			return true
	return false


func travel_to(target_area: String, target_pos: Vector2i, target_facing: int) -> Dictionary:
	if mode != "explore":
		return {"ok": false, "message": "You cannot travel right now."}
	var target_data := content.get_area(target_area)
	if target_area == "" or target_data.is_empty():
		return {"ok": false, "message": "That road does not lead anywhere."}
	if target_area == area_id:
		return {"ok": false, "message": "You are already there."}
	var next := _new_dungeon(target_area)
	if area_states.has(target_area):
		next.apply_state(Dictionary(area_states[target_area]))
	if not next.in_bounds(target_pos) or not next.is_walkable(target_pos):
		return {"ok": false, "message": "The way is blocked."}
	area_states[area_id] = dungeon.serialize()
	area_id = target_area
	dungeon = next
	position = target_pos
	facing = posmod(target_facing, 4)
	dungeon.visit(position)
	last_ui_message = "You travel to %s." % dungeon.display_name
	_log(last_ui_message)
	if dungeon.ambient != "":
		_log(dungeon.ambient)
	var entry_effects := Array(target_data.get("entry_effects", []))
	if not entry_effects.is_empty():
		apply_effects(entry_effects, "area:" + target_area)
	_play("ui")
	emit_signal("state_changed")
	return {"ok": true, "message": last_ui_message}


func _process_triggers() -> void:
	var trigger := dungeon.trigger_at(position)
	if trigger.is_empty():
		return
	var trigger_id := String(trigger.get("id", ""))
	if bool(flags.get("trigger_" + trigger_id, false)):
		return
	var require_flag := String(trigger.get("requires_flag", ""))
	if require_flag != "" and not bool(flags.get(require_flag, false)):
		return
	var forbid_flag := String(trigger.get("requires_flag_not", ""))
	if forbid_flag != "" and bool(flags.get(forbid_flag, false)):
		return
	flags["trigger_" + trigger_id] = true
	apply_effects(Array(trigger.get("effects", [])), "trigger:" + trigger_id)
	var encounter_id := String(trigger.get("encounter", ""))
	if encounter_id != "":
		start_encounter(encounter_id)


func rest_party(log_message := true) -> void:
	for ch in party:
		ch.rest()
	if log_message:
		_log("The party rests. Hit points and prepared spells are restored.")
	_play("heal")
	emit_signal("state_changed")


# ---------------------------------------------------------------- effects

func check_conditions(conditions: Array) -> Dictionary:
	for condition in conditions:
		var c: Dictionary = condition
		var ctype := String(c.get("type", ""))
		# The authored condition vocabulary lives in ContentSpec; this method only
		# implements the handlers. An unknown type is a content error, never a
		# silent pass.
		if not ContentSpec.has_condition_type(ctype):
			return {"ok": false, "reason": "Unknown condition '%s'." % ctype}
		match ctype:
			"flag":
				var expected := bool(c.get("value", true))
				if bool(flags.get(String(c.get("flag", "")), false)) != expected:
					return {"ok": false, "reason": "Requires flag %s." % c.get("flag", "")}
			"not_flag":
				if bool(flags.get(String(c.get("flag", "")), false)):
					return {"ok": false, "reason": "Not available yet."}
			"quest_active":
				if not quests.is_active(String(c.get("quest", ""))):
					return {"ok": false, "reason": "That quest is not active."}
			"quest_complete":
				if not quests.is_complete(String(c.get("quest", ""))):
					return {"ok": false, "reason": "That quest is not complete."}
			"has_item":
				if _party_item_count(String(c.get("item", ""))) <= 0:
					return {"ok": false, "reason": "You do not have that item."}
			"skill_at_least":
				if _best_skill_value(String(c.get("skill", ""))) < int(c.get("value", 0)):
					return {"ok": false, "reason": "No one has that expertise."}
			_:
				return {"ok": false, "reason": "Unknown condition '%s'." % ctype}
	return {"ok": true, "reason": ""}


func apply_effects(effects: Array, source := "content") -> Array[String]:
	var messages: Array[String] = []
	for effect in effects:
		var e: Dictionary = effect
		var etype := String(e.get("type", ""))
		# ContentSpec owns the vocabulary and its validation; this match owns the
		# handlers. Keep the two in step (tests/test_extensibility.gd).
		if not ContentSpec.has_effect_type(etype):
			var unknown := "Content error: unknown effect '%s'." % etype
			messages.append(unknown)
			_log(unknown)
			continue
		match etype:
			"set_flag":
				var flag_name := String(e.get("flag", ""))
				if flag_name == "":
					continue
				flags[flag_name] = e.get("value", true)
			"clear_flag":
				flags.erase(String(e.get("flag", "")))
			"quest_start":
				var quest_id := String(e.get("quest", ""))
				if quests.start(quest_id):
					var title := String(content.get_quest(quest_id).get("title", quest_id))
					messages.append("New quest: %s" % title)
					_log("New quest: %s" % title)
					_play("ui")
			"give_item":
				var item_id := String(e.get("item", ""))
				var item := content.get_item(item_id)
				if item.is_empty():
					messages.append("Content error: item '%s' does not exist." % item_id)
					continue
				if bool(e.get("only_if_missing", false)) and _party_item_count(item_id) > 0:
					continue
				var recipient := _first_conscious()
				if recipient == null and not party.is_empty():
					recipient = party[0]
				if recipient != null:
					recipient.add_to_inventory(item, int(e.get("qty", 1)))
					var line := "%s receives %s." % [recipient.display_name, String(item.get("name", item_id))]
					messages.append(line)
					_log(line)
					_play("ui")
			"remove_item":
				var item_id := String(e.get("item", ""))
				var qty := int(e.get("qty", 1))
				for ch in party:
					while qty > 0 and ch.inventory_count(item_id) > 0:
						ch.remove_from_inventory(item_id, 1)
						qty -= 1
			"xp":
				var amount := int(e.get("amount", 0))
				for ch in party:
					ch.xp += amount
				var line := "Each adventurer gains %d XP." % amount
				messages.append(line)
				_log(line)
			"gold":
				var amount := int(e.get("amount", 0))
				gold += amount
				var line := "The party gains %d gp." % amount
				messages.append(line)
				_log(line)
			"narration":
				var text := String(e.get("text", ""))
				messages.append(text)
				_log(text)
			"heal_party":
				var amount := int(e.get("amount", 9999))
				for ch in party:
					ch.magical_heal(amount)
				_log("A wave of healing passes over the party.")
			"start_combat":
				var enc := String(e.get("encounter", ""))
				if dialogue != null:
					dialogue.finished = true
				if mode == "explore" or mode == "dialogue":
					start_encounter(enc)
				messages.append("Combat begins.")
			"open_door":
				var door_id := String(e.get("door", ""))
				var door := dungeon.door_by_id(door_id)
				if not door.is_empty():
					dungeon.set_door_open(door_id, true)
					var open_flag := String(door.get("open_flag", ""))
					if open_flag != "":
						flags[open_flag] = true
			"remove_object":
				dungeon.mark_removed(String(e.get("object", "")))
			"travel":
				var travel_pos: Array = e.get("pos", [])
				if travel_pos.size() == 2:
					var traveled := travel_to(
						String(e.get("area", "")),
						Vector2i(int(travel_pos[0]), int(travel_pos[1])),
						int(e.get("facing", 0))
					)
					if bool(traveled["ok"]):
						messages.append(String(traveled["message"]))
					else:
						_log("Travel failed: %s" % String(traveled["message"]))
				else:
					_log("Content error: travel effect has no destination position.")
			"rest":
				rest_party(false)
			_:
				messages.append("Content error: unknown effect '%s'." % etype)
				_log("Content error: unknown effect '%s'." % etype)
	_sync_quests()
	emit_signal("state_changed")
	return messages


func _sync_quests() -> void:
	if quests == null:
		return
	var changes := quests.sync_flags(flags)
	for change in changes:
		_log(change)
	var completion_quest := String(campaign.get("completion_quest", ""))
	if (
		completion_quest != ""
		and quests.is_complete(completion_quest)
		and not bool(flags.get("victory_shown", false))
	):
		flags["victory_shown"] = true
		victory_pending = true
		for line in Array(content.narration.get("victory", [])):
			_log(String(line))
		_play("victory")
		_log("You can continue exploring or save your progress.")


func quest_tracker_text() -> String:
	if quests == null:
		return ""
	var area := content.get_area(area_id)
	return quests.compact_text(String(area.get("tracker_quest", "")))


func take_victory_pending() -> bool:
	var value := victory_pending
	victory_pending = false
	return value


# ---------------------------------------------------------------- party helpers

func _first_conscious() -> Character:
	for ch in party:
		if ch.can_act():
			return ch
	return null


func _best_skill_actor(skill: String) -> Character:
	var best: Character = null
	var best_value := -999
	for ch in party:
		if not ch.can_act():
			continue
		var value := Rules.skill_total(ch, skill)
		if value > best_value:
			best_value = value
			best = ch
	return best


func _best_skill_value(skill: String) -> int:
	var actor := _best_skill_actor(skill)
	return Rules.skill_total(actor, skill) if actor != null else -999


func _party_item_count(item_id: String) -> int:
	if item_id == "":
		return 0
	var total := 0
	for ch in party:
		total += ch.inventory_count(item_id)
		for slot in ch.equipment.keys():
			if String(ch.equipment[slot].get("id", "")) == item_id:
				total += 1
	return total


func equip_item(character_index: int, inventory_index: int) -> Dictionary:
	if encounter != null and encounter.has_pending_decision():
		return {"ok": false, "message": "Resolve the pending combat decision first."}
	if character_index < 0 or character_index >= party.size():
		return {"ok": false, "message": "No such party member."}
	var ch: Character = party[character_index]
	if inventory_index < 0 or inventory_index >= ch.inventory.size():
		return {"ok": false, "message": "No such inventory item."}
	var entry: Dictionary = ch.inventory[inventory_index]
	var item: Dictionary = entry.get("item", {})
	var kind := String(item.get("kind", ""))
	var slot := ""
	match kind:
		"weapon":
			slot = "weapon"
		"armor":
			slot = "armor"
		"shield":
			slot = "shield"
		_:
			return {"ok": false, "message": "%s is not equipment." % item.get("name", "That")}
	var previous: Dictionary = ch.equipment.get(slot, {})
	ch.equip(slot, item)
	ch.remove_from_inventory(String(item.get("id", "")), 1)
	if not previous.is_empty():
		ch.add_to_inventory(previous, 1)
	_log("%s equips %s." % [ch.display_name, item.get("name", "the item")])
	_play("ui")
	emit_signal("state_changed")
	return {"ok": true, "message": "Equipped %s." % item.get("name", "")}


func use_item(character_index: int, inventory_index: int) -> Dictionary:
	if encounter != null and encounter.has_pending_decision():
		return {"ok": false, "message": "Resolve the pending combat decision first."}
	if character_index < 0 or character_index >= party.size():
		return {"ok": false, "message": "No such party member."}
	var ch: Character = party[character_index]
	if inventory_index < 0 or inventory_index >= ch.inventory.size():
		return {"ok": false, "message": "No such inventory item."}
	var entry: Dictionary = ch.inventory[inventory_index]
	var item: Dictionary = entry.get("item", {})
	if String(item.get("kind", "")) != "consumable":
		return {"ok": false, "message": "%s cannot be used from the inventory." % item.get("name", "That item")}
	if ch.has_condition("dead"):
		return {"ok": false, "message": "%s is dead." % ch.display_name}
	var parsed := Dice.parse(rng, String(item.get("heal", "1d8")))
	var healed := ch.magical_heal(int(parsed["total"]))
	ch.remove_from_inventory(String(item.get("id", "")), 1)
	_log(
		"%s drinks %s: %s = %d; regains %d HP (now %d/%d)."
		% [
			ch.display_name,
			item.get("name", "a potion"),
			Dice.describe(parsed),
			int(parsed["total"]),
			int(healed["healed"]),
			ch.hp,
			ch.max_hp,
		]
	)
	if int(healed["nonlethal_removed"]) > 0:
		_log(
			"  magical healing also removes %d nonlethal damage (PHB p.147)."
			% int(healed["nonlethal_removed"])
		)
	_play("heal")
	emit_signal("state_changed")
	return {"ok": true, "message": "Healed %d HP." % healed}


# ---------------------------------------------------------------- dialogue

func start_dialogue(dialogue_id: String) -> Dictionary:
	if mode != "explore":
		return {"ok": false, "message": "You cannot talk right now."}
	var data := content.get_dialogue(dialogue_id)
	if data.is_empty():
		last_ui_message = "Missing dialogue '%s'." % dialogue_id
		_log("CONTENT ERROR: missing dialogue '%s'." % dialogue_id)
		return {"ok": false, "message": last_ui_message}
	dialogue = DialogueRunner.new()
	dialogue.setup(data, self, rng)
	active_dialogue_id = dialogue_id
	if not dialogue.start():
		var message := "Dialogue '%s' could not start: %s" % [dialogue_id, ", ".join(dialogue.errors)]
		_log(message)
		dialogue = null
		active_dialogue_id = ""
		return {"ok": false, "message": message}
	if mode == "combat":
		# An on-enter effect started a fight instead of a conversation.
		return {"ok": true, "message": "Combat started."}
	_set_mode("dialogue")
	_play("ui")
	emit_signal("state_changed")
	if dialogue != null and dialogue.finished and mode == "dialogue":
		_set_mode("explore")
	return {"ok": true, "message": ""}


func dialogue_choices() -> Array:
	if dialogue == null:
		return []
	return dialogue.available_choices()


func dialogue_choose(index: int) -> Dictionary:
	if dialogue == null or mode != "dialogue":
		return {"ok": false, "message": "No dialogue is active."}
	var result := dialogue.choose(index)
	for message in Array(result.get("messages", [])):
		_log(String(message))
	if not bool(result.get("ok", false)):
		last_ui_message = String(result.get("message", "That choice is unavailable."))
		_log(last_ui_message)
	_play("ui")
	if dialogue != null and dialogue.finished and mode == "dialogue":
		_set_mode("explore")
		emit_signal("dialogue_finished", active_dialogue_id)
	emit_signal("state_changed")
	return result


func on_dialogue_finished(data: Dictionary) -> void:
	var dialogue_id := String(data.get("id", active_dialogue_id))
	if mode == "dialogue":
		_set_mode("explore")
	emit_signal("dialogue_finished", dialogue_id)
	dialogue = null
	active_dialogue_id = ""
	emit_signal("state_changed")
	if mode == "explore" and content_ready and not playtest_mode:
		save_game("auto")


# ---------------------------------------------------------------- combat

func start_encounter(encounter_id: String) -> Dictionary:
	if mode == "combat":
		return {"ok": false, "message": "A combat is already running."}
	var def := content.get_encounter(encounter_id)
	if def.is_empty():
		_log("CONTENT ERROR: missing encounter '%s'." % encounter_id)
		return {"ok": false, "message": "Missing encounter '%s'." % encounter_id}
	var map := BattleMap.from_rows(Array(def.get("rows", [])), String(def.get("name", encounter_id)))
	var monsters: Array = []
	for monster_id in Array(def.get("monsters", [])):
		var data := content.get_monster(String(monster_id))
		if data.is_empty():
			_log("CONTENT ERROR: missing monster '%s'." % monster_id)
			continue
		monsters.append(Character.from_content(data, content.items))
	if monsters.is_empty():
		return {"ok": false, "message": "Encounter has no valid monsters."}
	var party_cells: Array = []
	for cell in Array(def.get("party_cells", [])):
		party_cells.append(Vector2i(int(cell[0]), int(cell[1])))
	var monster_cells: Array = []
	for cell in Array(def.get("monster_cells", [])):
		monster_cells.append(Vector2i(int(cell[0]), int(cell[1])))
	encounter = Encounter.new()
	encounter.encounter_id = encounter_id
	encounter.xp_award = int(def.get("xp", 0))
	encounter.setup(party, monsters, map, rng, party_cells, monster_cells, content.spells, String(def.get("name", "Encounter")))
	encounter.changed.connect(_on_encounter_changed)
	active_encounter_id = encounter_id
	active_encounter_data = def
	_encounter_resolved = false
	_set_mode("combat")
	_log("— Combat: %s —" % String(def.get("name", encounter_id)))
	var intro := String(def.get("intro", ""))
	if intro != "":
		_log(intro)
	_play("combat")
	encounter.begin()
	emit_signal("state_changed")
	encounter.auto_advance()
	emit_signal("state_changed")
	return {"ok": true, "message": "Combat started."}


func _on_encounter_changed() -> void:
	if encounter == null:
		return
	if encounter.finished and mode == "combat" and not _encounter_resolved:
		_resolve_encounter()
	else:
		emit_signal("state_changed")


## Combat Training demonstrations run the real engine but are not campaign
## content: they grant no XP, apply no victory effects and never write a save.
var training_mode := false


func _resolve_encounter() -> void:
	_encounter_resolved = true
	last_combat_result = encounter.outcome
	last_combat_log = encounter.log_lines.duplicate()
	var outcome := encounter.outcome
	if outcome == "victory":
		var def := active_encounter_data
		_log("Combat over: victory after %d rounds." % encounter.round_number)
		for line in encounter.log_lines.slice(maxi(0, encounter.log_lines.size() - 10)):
			_log(line)
		if not training_mode:
			apply_effects(Array(def.get("victory_effects", [])), "encounter:" + active_encounter_id)
		var xp := int(encounter.xp_award)
		if xp > 0 and not training_mode:
			for ch in party:
				ch.xp += xp
			_log("Each adventurer gains %d XP." % xp)
		# Postcombat recovery: anything left on the ground is collected by the
		# party rather than silently lost or duplicated.
		var leftover := encounter.collect_ground_items()
		if not leftover.is_empty() and not party.is_empty():
			var carrier: Character = party[0]
			for ground in leftover:
				carrier.add_to_inventory(Dictionary(ground["item"]), 1)
			_log(
				"%d item(s) left on the battlefield are recovered by %s."
				% [leftover.size(), carrier.display_name]
			)
		elif not leftover.is_empty():
			encounter.ground_items = leftover
		_set_mode("explore")
		_play("victory")
		emit_signal("combat_finished", "victory")
		if not training_mode and not playtest_mode:
			save_game("auto")
	else:
		# Defeat is not a recovery path: items dropped in combat stay on the
		# battlefield. They are not granted, copied, or silently deleted.
		if not encounter.ground_items.is_empty():
			_log(
				"%d item(s) dropped in this fight are lost with the defeat."
				% encounter.ground_items.size()
			)
		_set_mode("defeat")
		for line in Array(content.narration.get("defeat", [])):
			_log(String(line))
		_play("defeat")
		emit_signal("combat_finished", "defeat")
	emit_signal("state_changed")


func combat_move(dest: Vector2i, five_foot := false) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.move_active_to(dest, five_foot)
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_attack(target_index: int, attack_mode := "", unarmed_damage := "") -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.attack_active(target_index, attack_mode, unarmed_damage)
	if not bool(result.get("ok", false)):
		last_ui_message = String(result.get("message", "You cannot attack that target."))
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


## PHB p.142: readying a carried weapon costs a move action; the encounter
## validates it and explains refusals without changing anything.
func combat_draw_weapon(item_id: String) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.draw_weapon(item_id)
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


## PHB p.142: readying or loosing a shield is a move action; loosing drops it.
func combat_ready_shield(item_id: String) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.ready_shield(item_id)
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_loose_shield() -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.loose_shield()
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


## PHB p.142: putting a weapon away is its own move action.
func combat_sheathe_weapon() -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.sheathe_weapon()
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


## PHB p.115: loading a crossbow is a move action that provokes.
func combat_load_weapon() -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.load_weapon()
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_trip(target_index: int, use_weapon := false) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.trip_active(target_index, {"use_weapon": use_weapon})
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_resolve_trip(release_weapon: bool) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.resolve_trip_decision(release_weapon)
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_resolve_improved_trip(take_attack: bool, choice := "") -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.resolve_improved_trip_attack(take_attack, choice)
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_resolve_cleave(target_index: int) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.resolve_cleave_attack(target_index)
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	_resume_after_cleave()
	emit_signal("state_changed")
	return result


func combat_decline_cleave() -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.decline_cleave()
	last_ui_message = String(result.get("message", ""))
	_resume_after_cleave()
	emit_signal("state_changed")
	return result


## After a Cleave decision, continue the action it interrupted (if any) and then
## the rest of the enemy sequence. The turn never moved while the decision was
## pending, so this resumes from the same turn pointer.
func _resume_after_cleave() -> void:
	if encounter == null or encounter.finished:
		return
	if encounter.has_pending_decision():
		return
	if not encounter.off_turn_resume.is_empty():
		encounter.resume_interrupted()
		if encounter == null or encounter.finished or mode != "combat":
			return
	if encounter.has_pending_decision():
		return
	encounter.auto_advance()


func combat_stand_up() -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.stand_up_active()
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_pick_up(ground_index: int) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.pick_up_active(ground_index)
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_set_power_attack(amount: int) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.set_active_power_attack(amount)
	last_ui_message = String(result.get("message", "Power Attack unchanged."))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_set_combat_expertise(amount: int) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.set_active_combat_expertise(amount)
	last_ui_message = String(result.get("message", "Combat Expertise unchanged."))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


## `defensive` is the player's explicit choice in the spell list: it trades the
## attack of opportunity for a Concentration check (PHB p. 140). It is never
## inferred from the situation.
func combat_cast(spell_id: String, target_index: int, defensive := false) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.cast_active_spell(
		spell_id, target_index, {"defensive": defensive}
	)
	if not bool(result.get("ok", false)):
		last_ui_message = String(result.get("message", "The spell cannot be cast."))
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_item(item_id: String, target_index: int) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.use_potion_active(item_id, target_index)
	if not bool(result.get("ok", false)):
		last_ui_message = String(result.get("message", "The item cannot be used."))
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_stabilize(target_index: int) -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.stabilize_active(target_index)
	if not bool(result.get("ok", false)):
		last_ui_message = String(result.get("message", "Cannot attempt first aid."))
		_log(last_ui_message)
	emit_signal("state_changed")
	return result


func combat_can_turn_undead() -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "reason": "No combat is running."}
	return encounter.can_active_turn_undead()


func combat_turn_undead() -> Dictionary:
	if encounter == null or mode != "combat":
		return {"ok": false, "message": "No combat is running."}
	var result := encounter.turn_undead()
	last_ui_message = String(result.get("message", ""))
	if not bool(result.get("ok", false)):
		_log(last_ui_message)
	if encounter != null and not encounter.finished:
		encounter.auto_advance()
	emit_signal("state_changed")
	return result


func combat_end_turn() -> void:
	if encounter == null or mode != "combat":
		return
	encounter.end_turn()
	encounter.auto_advance()
	emit_signal("state_changed")


func combat_spells_for_active() -> Array:
	var result: Array = []
	if encounter == null:
		return result
	var ch := encounter.active_character()
	if ch == null:
		return result
	var slots: Dictionary = ch.spells.get("slots", {})
	for level_key in slots.keys():
		var level := int(level_key)
		if ch.spell_slots_remaining(level) <= 0:
			continue
		if bool(ch.spells.get("spontaneous", false)):
			for spell_id in Array(ch.spells.get("known", [])):
				var spell := content.get_spell(String(spell_id))
				if not spell.is_empty() and int(spell.get("level", 1)) == level:
					result.append({"spell": spell, "remaining": ch.spell_slots_remaining(level)})
		else:
			var prepared: Array = ch.spells.get("prepared", {}).get(level_key, [])
			var seen := {}
			for spell_id in prepared:
				var key := "%s:%d" % [spell_id, level]
				var count := 0
				for other in prepared:
					if String(other) == String(spell_id):
						count += 1
				count -= int(seen.get(key, 0))
				if int(seen.get(key, 0)) == 0:
					var spell := content.get_spell(String(spell_id))
					if not spell.is_empty():
						result.append({"spell": spell, "remaining": count})
				seen[key] = 1
	return result


func reset_to_menu() -> void:
	if encounter != null and encounter.has_pending_decision():
		_log("Leaving combat abandons the pending Trip decision.")
	encounter = null
	dialogue = null
	active_encounter_id = ""
	active_dialogue_id = ""
	_set_mode("menu")
	emit_signal("state_changed")


# ---------------------------------------------------------------- settings

## Reads the settings file, clamping everything a hand-edited or older file can
## get wrong. Missing sections and keys keep the compiled defaults, unknown
## sections and keys are left on disk, and a newer file is marked read-only.
func load_settings() -> void:
	settings_newer = false
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var file_version := int(config.get_value("meta", "version", SETTINGS_VERSION))
	settings_newer = file_version > SETTINGS_VERSION
	for key in ["master", "music", "sfx", "ambience"]:
		settings[key] = clampf(float(config.get_value("audio", key, settings.get(key, 0.8))), 0.0, 1.0)
	settings["text_scale"] = clampf(
		float(config.get_value("display", "text_scale", settings.get("text_scale", 1.0))),
		TEXT_SCALE_MIN,
		TEXT_SCALE_MAX
	)
	settings["fullscreen"] = _flag_from(config.get_value("display", "fullscreen", false))
	var binds: Variant = config.get_value("input", "keybinds", {})
	if not binds is Dictionary:
		return
	for action in Dictionary(binds).keys():
		var raw: Variant = Dictionary(binds)[action]
		if not raw is int and not raw is float:
			continue
		var keycode := int(raw)
		# Kept even when this build no longer knows the action, so a downgrade and
		# a later upgrade do not lose a binding; only known actions are applied.
		settings["keybinds"][String(action)] = keycode
		if not InputMap.has_action(String(action)):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_erase_events(String(action))
		InputMap.action_add_event(String(action), event)


## Accepts the shapes a hand-edited file can produce for a flag: a real bool, a
## number, or one of the usual words. `bool("yes")` is an error in GDScript, which
## is why this is explicit rather than a cast.
func _flag_from(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return float(value) != 0.0
	return String(value).strip_edges().to_lower() in ["true", "yes", "1", "on"]


## Writes the known sections and keys back into the existing file, so anything a
## newer build added (or a future section) survives. A file from a newer build is
## never written at all: the policy is to refuse the write rather than drop data.
func save_settings() -> void:
	if settings_newer:
		return
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value("meta", "version", SETTINGS_VERSION)
	for key in ["master", "music", "sfx", "ambience"]:
		config.set_value("audio", key, clampf(float(settings.get(key, 0.8)), 0.0, 1.0))
	config.set_value("display", "text_scale", clampf(float(settings.get("text_scale", 1.0)), TEXT_SCALE_MIN, TEXT_SCALE_MAX))
	config.set_value("display", "fullscreen", bool(settings.get("fullscreen", false)))
	config.set_value("input", "keybinds", settings.get("keybinds", {}))
	config.save(settings_path)


func _apply_settings() -> void:
	if Sfx != null:
		Sfx.set_bus_volume("Master", float(settings.get("master", 0.9)))
		Sfx.set_bus_volume("Music", float(settings.get("music", 0.55)))
		Sfx.set_bus_volume("SFX", float(settings.get("sfx", 0.8)))
		Sfx.set_bus_volume("Ambience", float(settings.get("ambience", 0.6)))
	if DisplayServer.get_name() != "headless":
		var want_fullscreen := bool(settings.get("fullscreen", false))
		var current := DisplayServer.window_get_mode()
		if want_fullscreen and current != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not want_fullscreen and current == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_volume(bus_key: String, value: float) -> void:
	if not settings.has(bus_key):
		return
	settings[bus_key] = clampf(value, 0.0, 1.0)
	_apply_settings()
	save_settings()


func set_text_scale(value: float) -> void:
	settings["text_scale"] = clampf(value, TEXT_SCALE_MIN, TEXT_SCALE_MAX)
	save_settings()
	emit_signal("state_changed")


func set_fullscreen(value: bool) -> void:
	settings["fullscreen"] = value
	_apply_settings()
	save_settings()


func rebind(action: String, keycode: int) -> Dictionary:
	if not InputMap.has_action(action):
		return {"ok": false, "message": "Unknown action '%s'." % action}
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	settings["keybinds"][action] = keycode
	save_settings()
	emit_signal("state_changed")
	return {"ok": true, "message": "%s bound to %s." % [action, OS.get_keycode_string(keycode)]}


func reset_default_controls() -> Dictionary:
	# Reloading the project input map restores the shipped bindings and discards
	# every per-action override. Settings for audio, display and saves are untouched.
	InputMap.load_from_project_settings()
	settings["keybinds"] = {}
	save_settings()
	emit_signal("state_changed")
	return {"ok": true, "message": "Default controls restored."}


func _play(sound_id: String) -> void:
	if Sfx != null:
		Sfx.play(sound_id)
