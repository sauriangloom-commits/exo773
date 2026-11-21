class_name SaveSystem
extends RefCounted

## JSON save slots under user://saves, namespaced by campaign id.
##
## A save written by the campaign system lives at
## `user://saves/<campaign>/<slot>.json`. Files written before campaigns existed
## live directly in `user://saves/` and are only ever read, never rewritten, so
## an older install's saves survive the transition. Saves are versioned and
## validated on load so a corrupt or outdated file produces a clear message,
## not a crash.

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const TEST_SAVE_DIR := "user://test_saves"
const SLOTS := ["auto", "slot1", "slot2", "slot3"]

## Redirected for automated runs so GUT never writes into a player's slots.
static var save_dir := SAVE_DIR


static func _static_init() -> void:
	for arg in OS.get_cmdline_args():
		if arg.contains("gut_cmdln.gd"):
			save_dir = TEST_SAVE_DIR
			break


static func campaign_dir(campaign_id: String) -> String:
	return save_dir.path_join(campaign_id)


## `campaign_id == ""` addresses the pre-campaign legacy directory. New writes
## from Game always pass a campaign id.
static func path_for(slot: String, campaign_id := "") -> String:
	if campaign_id == "":
		return save_dir.path_join("%s.json" % slot)
	return campaign_dir(campaign_id).path_join("%s.json" % slot)


static func _target_dir(campaign_id: String) -> String:
	return campaign_dir(campaign_id) if campaign_id != "" else save_dir


static func _ensure_dir(target: String) -> bool:
	if DirAccess.dir_exists_absolute(target):
		return true
	# A parent that is a regular file makes make_dir_recursive print an engine
	# error. Detect that case and fail quietly; callers report the failure.
	var parent := target.get_base_dir()
	if FileAccess.file_exists(parent) and not DirAccess.dir_exists_absolute(parent):
		return false
	return DirAccess.make_dir_recursive_absolute(target) == OK


static func exists(slot: String, campaign_id := "") -> bool:
	if not DirAccess.dir_exists_absolute(_target_dir(campaign_id)):
		return false
	return FileAccess.file_exists(path_for(slot, campaign_id))


static func _global(path: String) -> String:
	return ProjectSettings.globalize_path(path)


static func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(_global(path))


## Write through a temporary file and keep the previous save as a backup until
## the replacement is committed. This prevents an interrupted write from
## truncating the only copy of a player's save.
static func write_save(slot: String, payload: Dictionary, campaign_id := "") -> Dictionary:
	var target_dir := campaign_dir(campaign_id) if campaign_id != "" else save_dir
	if not _ensure_dir(target_dir):
		return {"ok": false, "message": "Could not create the save directory."}
	var data := payload.duplicate(true)
	data["save_version"] = SAVE_VERSION
	data["slot"] = slot
	data["campaign_id"] = campaign_id
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	data["saved_unix"] = int(Time.get_unix_time_from_system())
	var final_path := path_for(slot, campaign_id)
	# A file already sitting on a working path is a leftover from an interrupted
	# save, not this write's file. It is never truncated, renamed or removed: this
	# write works beside it (`.tmp.w` / `.bak.w`) and only cleans up its own files,
	# so a crash's recovery copy survives even if this write fails.
	var temp_path := final_path + ".tmp"
	if FileAccess.file_exists(temp_path):
		temp_path = final_path + ".tmp.w"
	var backup_path := final_path + ".bak"
	if FileAccess.file_exists(backup_path):
		backup_path = final_path + ".bak.w"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Could not open %s for writing." % temp_path}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if not JSON.parse_string(FileAccess.get_file_as_string(temp_path)) is Dictionary:
		_remove_file(temp_path)
		return {"ok": false, "message": "Save verification failed; the existing save was not changed."}
	var had_existing := FileAccess.file_exists(final_path)
	if had_existing:
		if DirAccess.rename_absolute(_global(final_path), _global(backup_path)) != OK:
			_remove_file(temp_path)
			return {"ok": false, "message": "Could not stage the existing save for replacement."}
	if DirAccess.rename_absolute(_global(temp_path), _global(final_path)) != OK:
		_remove_file(temp_path)
		if had_existing and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(_global(backup_path), _global(final_path))
		return {"ok": false, "message": "Could not commit the save; the previous save was restored."}
	_remove_file(backup_path)
	return {"ok": true, "message": "Saved to %s." % slot, "data": data}


## Every file a slot can be recovered from, in preference order. A load looks at
## the primary first and only then at the interrupted write's leftovers.
static func artifact_paths(slot: String, campaign_id := "") -> Array:
	var final_path := path_for(slot, campaign_id)
	return [final_path, final_path + ".bak", final_path + ".tmp"]


## True when any artifact of the slot exists, valid or not. A crashed save leaves
## a backup or temp behind, and that is what stops the pre-campaign fallback from
## standing in for the slot.
static func has_artifacts(slot: String, campaign_id := "") -> bool:
	for path in artifact_paths(slot, campaign_id):
		if FileAccess.file_exists(String(path)):
			return true
	return false


## Reads one save file and applies the version rules, without touching the file.
## `reason` separates damage (missing/corrupt), which a load may recover from, from
## an incompatible version, which is a refusal and never a downgrade.
static func read_payload(slot: String, path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "No save in %s." % slot, "reason": "missing"}
	# JSON.parse_string() logs an engine error for damaged bytes; the recovery path
	# expects those, so parse through an object and read the error code instead.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {"ok": false, "message": "Save %s is corrupt (invalid JSON)." % slot, "reason": "corrupt"}
	var parsed: Variant = json.data
	var from := int(Dictionary(parsed).get("save_version", -1))
	# Tests raise the target so synthetic steps can exercise this path while the
	# shipped version stays 1; in production the target is SAVE_VERSION itself.
	var target := SAVE_VERSION if SaveMigrations.target_override <= 0 else SaveMigrations.target_override
	var payload: Dictionary = parsed
	if from != target:
		# Upgraded in memory only. The file keeps its bytes until the player saves
		# again, so a refused or interrupted load can never rewrite player data.
		var upgraded: Variant = SaveMigrations.upgrade(payload, from, target)
		if not upgraded is Dictionary:
			return {
				"ok": false,
				"message": "Save %s was written by an incompatible version (%s)." % [slot, payload.get("save_version", "?")],
				"reason": "unsupported_version",
			}
		payload = upgraded
	return {
		"ok": true,
		"message": "Loaded %s." % slot,
		"data": payload,
		"migrated_from": from if from != target else 0,
	}


static func read_save(slot: String, campaign_id := "") -> Dictionary:
	return read_payload(slot, path_for(slot, campaign_id))


## One row per slot that can be offered, including a slot whose primary is gone
## but whose backup or temp survived: hiding those would make an interrupted save
## look like an empty slot. `source` says which file the row describes.
static func list_saves(campaign_id := "") -> Array:
	var saves: Array = []
	for slot in SLOTS:
		if not has_artifacts(slot, campaign_id):
			continue
		var info := {
			"slot": slot,
			"saved_at": "",
			"saved_unix": 0,
			"summary": "",
			"campaign_id": campaign_id,
			"source": "primary",
		}
		var sources := ["primary", "backup", "temp"]
		var paths := artifact_paths(slot, campaign_id)
		for index in paths.size():
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(String(paths[index]))) != OK or not json.data is Dictionary:
				continue
			var parsed: Variant = json.data
			info["saved_at"] = String(Dictionary(parsed).get("saved_at", ""))
			info["saved_unix"] = int(Dictionary(parsed).get("saved_unix", 0))
			info["summary"] = String(Dictionary(parsed).get("summary", ""))
			info["campaign_id"] = String(Dictionary(parsed).get("campaign_id", campaign_id))
			info["source"] = String(sources[index])
			break
		saves.append(info)
	saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("saved_unix", 0)) > int(b.get("saved_unix", 0))
	)
	return saves


static func latest_slot(campaign_id := "") -> String:
	var saves := list_saves(campaign_id)
	return String(saves[0]["slot"]) if not saves.is_empty() else ""


static func has_saves(campaign_id: String) -> bool:
	for slot in SLOTS:
		if has_artifacts(slot, campaign_id):
			return true
	return false


static func any_legacy_save() -> bool:
	return has_saves("")


## Deletes a slot wherever it exists: the legacy directory and every campaign
## directory. Used by tests and by explicit player deletion.
static func delete_save(slot: String) -> bool:
	var removed := false
	for suffix in ["", ".bak", ".tmp"]:
		var legacy_path: String = path_for(slot) + String(suffix)
		if FileAccess.file_exists(legacy_path):
			_remove_file(legacy_path)
			removed = true
	if DirAccess.dir_exists_absolute(save_dir):
		for campaign_id in DirAccess.get_directories_at(save_dir):
			for suffix in ["", ".bak", ".tmp"]:
				var path: String = path_for(slot, String(campaign_id)) + String(suffix)
				if FileAccess.file_exists(path):
					_remove_file(path)
					removed = true
	return removed
