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
	# write takes the next free working name (`.tmp.2`, `.bak.2`, ...) and only
	# cleans up its own files, so every earlier crash copy stays readable even if
	# this write fails or the process dies partway through it. Repeated interrupted
	# writes therefore accumulate copies instead of overwriting the last one.
	var temp_path := _free_working_name(final_path + ".tmp")
	var backup_path := _free_working_name(final_path + ".bak")
	if temp_path == "" or backup_path == "":
		return {"ok": false, "message": "Too many interrupted saves in %s; nothing was written." % slot}
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


## The three canonical files of a slot. Prefer `slot_files` for discovery: a
## working copy carries a numbered suffix (`.bak.2`, `.tmp.2`) or the older
## `.bak.w` / `.tmp.w` spelling, and any of them can be the only surviving copy.
static func artifact_paths(slot: String, campaign_id := "") -> Array:
	var final_path := path_for(slot, campaign_id)
	return [final_path, final_path + ".bak", final_path + ".tmp"]


## The first name of this family this write can own, or "" when the slot already
## holds so many interrupted-save copies that writing would have to destroy one.
static func _free_working_name(base: String) -> String:
	if not FileAccess.file_exists(base):
		return base
	for index in range(2, 101):
		var candidate := "%s.%d" % [base, index]
		if not FileAccess.file_exists(candidate):
			return candidate
	return ""


## The role of one file name in a slot's directory, or `{}` when the name is not
## one this build writes for that slot. This is the single definition used by
## discovery, classification and deletion, so a hand-made archive or an editor
## backup can neither masquerade as recovery nor be deleted with the slot.
##
## Accepted:
##   <slot>.json                          primary
##   <slot>.json.bak                      backup
##   <slot>.json.bak.<n>   n = 2..100     backup
##   <slot>.json.bak.w                    backup (previous release's working name)
##   <slot>.json.tmp                      temp
##   <slot>.json.tmp.<n>   n = 2..100     temp
##   <slot>.json.tmp.w                    temp (previous release's working name)
##
## Names are matched case-insensitively because the save filesystem is
## case-insensitive on Windows and macOS and `path_for` already resolves a
## differently cased primary there. The caller keeps each directory entry's own
## spelling, so two names that differ only by case remain two files on a
## case-sensitive filesystem.
static func parse_slot_file(name: String, slot: String) -> Dictionary:
	var lowered := name.to_lower()
	var base := ("%s.json" % slot).to_lower()
	if lowered == base:
		return {"role": "primary", "suffix": ""}
	for family in ["bak", "tmp"]:
		var role := "backup" if family == "bak" else "temp"
		var prefix := "%s.%s" % [base, family]
		if lowered == prefix:
			return {"role": role, "suffix": ""}
		if not lowered.begins_with(prefix + "."):
			continue
		var tail := lowered.substr(prefix.length() + 1)
		if tail == "w":
			return {"role": role, "suffix": "w"}
		# Only the exact spellings the writer produces: no leading zeros, no sign,
		# nothing beyond the numbered range _free_working_name can create.
		if tail.is_valid_int() and str(int(tail)) == tail:
			var number := int(tail)
			if number >= 2 and number <= 100:
				return {"role": role, "suffix": tail}
	return {}


## Raw directory entries that could belong to the slot. The exact pattern is
## applied by `_classify_names`; this only avoids parsing every file in the
## directory.
static func _slot_file_names(slot: String, campaign_id := "") -> PackedStringArray:
	var names := PackedStringArray()
	var directory := DirAccess.open(_target_dir(campaign_id))
	if directory == null:
		return names
	var prefix := (slot + ".json").to_lower()
	for name in directory.get_files():
		if String(name).to_lower().begins_with(prefix):
			names.append(name)
	return names


## Classifies raw names into canonical order: the primary spelling first, then
## backups (`.bak`, then numbered/legacy extras in name order), then temps. Every
## accepted entry keeps its own spelling; a name that differs only in case from
## another is a separate entry. Pure, so ordering and case handling are testable
## without depending on the host filesystem.
static func _classify_names(names: Array, slot: String) -> Array:
	var exact := "%s.json" % slot
	var primary_names: Array = []
	var backup_names: Array = []
	var temp_names: Array = []
	for raw in names:
		var name := String(raw)
		var parsed := parse_slot_file(name, slot)
		if parsed.is_empty():
			continue
		match String(parsed["role"]):
			"primary":
				primary_names.append(name)
			"backup":
				backup_names.append(name)
			_:
				temp_names.append(name)
	var ordered: Array = []
	for tier in [[primary_names, exact, "primary"], [backup_names, exact + ".bak", "backup"], [temp_names, exact + ".tmp", "temp"]]:
		for name in _tier_order(Array(tier[0]), String(tier[1])):
			ordered.append({
				"name": String(name),
				"source": String(tier[2]),
				"suffix": String(parse_slot_file(String(name), slot).get("suffix", "")),
			})
	return ordered


## Canonical name first, then the rest in name order. This is the order ties in
## `saved_unix` resolve to, so it is part of the selection contract.
static func _tier_order(names: Array, canonical: String) -> Array:
	names.sort()
	if names.has(canonical):
		names.erase(canonical)
		names.insert(0, canonical)
	return names


## Every file of a slot that exists, with the role a load gives it: the primary
## first, then committed backups, then staged temps. Working copies sit in the
## same tier as their family. This order is what ties resolve to: the loader
## takes the greatest `saved_unix` in a tier and keeps the first candidate when
## two copies share one, so the canonical name wins a tie and otherwise the
## lexicographically first extra name does.
static func slot_files(slot: String, campaign_id := "") -> Array:
	var names: Array = []
	for name in _slot_file_names(slot, campaign_id):
		names.append(String(name))
	var directory := _target_dir(campaign_id)
	var files: Array = []
	for entry in _classify_names(names, slot):
		files.append({
			"path": directory.path_join(String(entry["name"])),
			"source": String(entry["source"]),
		})
	return files


## True when any file of the slot exists, valid or not. A crashed save leaves a
## backup or temp behind, and that is what stops the pre-campaign fallback from
## standing in for the slot. A stray file that is not one of the slot's accepted
## names does not count.
static func has_artifacts(slot: String, campaign_id := "") -> bool:
	return not slot_files(slot, campaign_id).is_empty()


## The first artifact of the slot that parses, in canonical order. Used by list
## rows and by the overwrite guard, which must know a crashed slot still holds a
## save. `{}` when no file of the slot reads.
static func first_readable(slot: String, campaign_id := "") -> Dictionary:
	for entry in slot_files(slot, campaign_id):
		var read := read_payload(slot, String(entry["path"]))
		if bool(read.get("ok", false)):
			var data: Dictionary = read["data"]
			return {"path": entry["path"], "source": entry["source"], "data": data}
	return {}


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
		var files := slot_files(slot, campaign_id)
		var info := {
			"slot": slot,
			"saved_at": "",
			"saved_unix": 0,
			"summary": "",
			"campaign_id": campaign_id,
			"source": String(files[0]["source"]),
			"readable": false,
		}
		var found := first_readable(slot, campaign_id)
		if not found.is_empty():
			var parsed: Dictionary = found["data"]
			info["saved_at"] = String(parsed.get("saved_at", ""))
			info["saved_unix"] = int(parsed.get("saved_unix", 0))
			info["summary"] = String(parsed.get("summary", ""))
			info["campaign_id"] = String(parsed.get("campaign_id", campaign_id))
			info["source"] = String(found["source"])
			info["readable"] = true
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
	# Every file of the slot, including working copies, so a deleted slot cannot
	# leave a recoverable copy behind. That is what the player asked for.
	var campaign_ids: Array = [""]
	if DirAccess.dir_exists_absolute(save_dir):
		for campaign_id in DirAccess.get_directories_at(save_dir):
			campaign_ids.append(String(campaign_id))
	for campaign_id in campaign_ids:
		for entry in slot_files(slot, String(campaign_id)):
			var path := String(entry["path"])
			if FileAccess.file_exists(path):
				_remove_file(path)
				removed = true
	return removed