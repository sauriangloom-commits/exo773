extends GutTest

## Interruption states of the save write sequence, including working copies.
##
## write_save stages a temp, moves the primary to a backup, renames the temp into
## place and only then removes its own backup. A process that dies at any of those
## points leaves some subset of `slot.json`, `.bak`, `.tmp`, and - when earlier
## crash copies already occupied those names - `.bak.N` / `.tmp.N` (or the older
## `.bak.w` / `.tmp.w`). These tests build each state directly and assert what the
## loader chooses, that it never calls a slot empty while a copy parses, and that
## nothing on disk changes during selection.

const SLOT := "slot2"
const CAMPAIGN := "ravenloft_demo"


func before_each() -> void:
	Game.load_campaign(CAMPAIGN)
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)
	_clean()


func after_each() -> void:
	_clean()
	Game.reset_to_menu()
	Game.load_campaign(CAMPAIGN)


func _clean() -> void:
	SaveSystem.delete_save_everywhere(SLOT)
	var directory := ProjectSettings.globalize_path(SaveSystem.path_for(SLOT, CAMPAIGN))
	if DirAccess.dir_exists_absolute(directory):
		DirAccess.remove_absolute(directory)


func _path(suffix := "") -> String:
	return SaveSystem.path_for(SLOT, CAMPAIGN) + suffix


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _write(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## A complete, valid payload with a chosen gold value, saved_unix and identity.
func _payload(gold: int, unix := 1000, campaign := CAMPAIGN, content := 1, version := 0) -> Dictionary:
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var payload: Dictionary = JSON.parse_string(_text(_path()))
	payload["gold"] = gold
	payload["saved_unix"] = unix
	payload["saved_at"] = "2026-11-20 12:%02d:00" % (gold % 60)
	if campaign != CAMPAIGN:
		payload["campaign_id"] = campaign
	if content != 1:
		payload["content_version"] = content
	if version > 0:
		payload["save_version"] = version
	SaveSystem.delete_save_everywhere(SLOT)
	return payload


func _snapshot() -> Dictionary:
	var bytes := {}
	for entry in SaveSystem.slot_files(SLOT, CAMPAIGN):
		var path := String(entry["path"])
		bytes[path.get_file()] = _text(path)
	return bytes


## Writes one interruption state, loads it, and asserts the outcome and that the
## selection left every file byte-identical.
func _run_state(files: Dictionary, expected_ok: bool, expected_gold := 0, expected_source := "", expected_text := "") -> void:
	for suffix in files.keys():
		var value: Variant = files[suffix]
		if value is Dictionary:
			_write(String(_path(String(suffix))), Dictionary(value))
		else:
			_write_text(String(_path(String(suffix))), String(value))
	var before := _snapshot()
	var gold_before := Game.gold
	var label := "state %s" % str(files.keys())
	var loaded := Game.load_game(SLOT)
	assert_eq(bool(loaded.get("ok", false)), expected_ok, label)
	if expected_ok:
		assert_eq(Game.gold, expected_gold, label)
		assert_eq(String(loaded.get("recovered_from", "")), expected_source, label)
		if expected_source != "":
			var stated := "unfinished write" if expected_source == "temp" else expected_source
			assert_string_contains(String(loaded.get("message", "")), stated, label)
	else:
		assert_eq(Game.gold, gold_before, label + " leaves live state alone")
		assert_eq(Game.campaign_id, CAMPAIGN, label + " leaves the campaign alone")
		if expected_text != "":
			assert_string_contains(String(loaded.get("message", "")), expected_text, label)
	assert_eq(_snapshot(), before, label + " leaves every file byte-identical")
	_clean()


func test_every_single_file_state_is_discovered() -> void:
	_run_state({"": _payload(10, 100)}, true, 10, "")
	_run_state({".bak": _payload(20, 200)}, true, 20, "backup")
	_run_state({".tmp": _payload(30, 300)}, true, 30, "temp")
	_run_state({".bak.w": _payload(40, 400)}, true, 40, "backup")
	_run_state({".tmp.w": _payload(50, 500)}, true, 50, "temp")
	_run_state({".bak.2": _payload(60, 600)}, true, 60, "backup")
	_run_state({".tmp.2": _payload(70, 700)}, true, 70, "temp")


func test_the_tier_order_is_primary_then_backup_then_temp() -> void:
	_run_state({"": _payload(10, 100), ".bak": _payload(20, 200), ".tmp": _payload(30, 300)}, true, 10, "")
	_run_state({".bak": _payload(20, 200), ".tmp": _payload(30, 300)}, true, 20, "backup")
	_run_state({".bak.w": _payload(40, 400), ".tmp.2": _payload(70, 700)}, true, 40, "backup")
	# Same-second copies tie on saved_unix; the canonical name is the tie-break.
	_run_state({".bak": _payload(20, 900), ".bak.2": _payload(60, 900)}, true, 20, "backup")


func test_the_newest_copy_in_a_tier_is_used() -> void:
	_run_state({".bak": _payload(10, 100), ".bak.2": _payload(60, 600)}, true, 60, "backup")
	_run_state({".tmp": _payload(30, 300), ".tmp.w": _payload(50, 500)}, true, 50, "temp")
	_run_state({".bak": _payload(10, 800), ".bak.w": _payload(40, 400)}, true, 10, "backup")


func test_a_working_copy_is_used_when_the_canonical_copies_are_damaged() -> void:
	_write_text(_path(".bak"), "not json")
	_run_state({".bak.2": _payload(80, 800)}, true, 80, "backup")
	_write_text(_path(".tmp"), "{\"save_version\":1,")
	_run_state({".tmp": "{\"save_version\":1,", ".tmp.2": _payload(70, 700)}, true, 70, "temp")


func test_an_empty_slot_still_refuses() -> void:
	_run_state({}, false, 0, "", "No save in")


func test_damaged_copies_with_no_survivor_refuse_and_keep_their_bytes() -> void:
	_run_state({".bak": "broken", ".tmp.2": "also broken", "": "{\"save_version\":1,"}, false, 0, "", "corrupt")


func test_an_incompatible_primary_keeps_its_refusal_with_a_working_backup() -> void:
	_run_state({"": _payload(10, 100, CAMPAIGN, 1, 99), ".bak.w": _payload(40, 400)}, false, 0, "", "incompatible version")


func test_a_foreign_working_copy_is_skipped_without_switching_campaign() -> void:
	_run_state({".bak.2": _payload(90, 900, "some_other_campaign")}, false, 0, "", "belongs to campaign")


func test_a_working_copy_for_other_content_is_skipped() -> void:
	_run_state({".tmp.w": _payload(50, 500, CAMPAIGN, 2)}, false, 0, "", "content version")


func test_legacy_fallback_is_blocked_by_a_working_copy() -> void:
	var legacy := _payload(999, 100)
	legacy.erase("campaign_id")
	_write(SaveSystem.path_for(SLOT), legacy)
	_run_state({".bak.2": _payload(60, 600)}, true, 60, "backup")


func test_a_working_copy_is_listed_and_never_called_empty() -> void:
	_write(_path(".bak.2"), _payload(60, 600))
	var row: Dictionary = {}
	for entry in Game.list_saves():
		if String(entry["slot"]) == SLOT:
			row = entry
	assert_false(row.is_empty(), "the slot is listed")
	assert_eq(String(row.get("source", "")), "backup")
	assert_true(Game.has_save(SLOT), "Continue is offered for a recoverable slot")
	assert_string_contains(Panels._save_info(SLOT), "interrupted")
	assert_false(Panels._save_info(SLOT) == "empty", "the slot is not reported empty")


func test_a_save_beside_working_copies_takes_free_names_and_keeps_theirs() -> void:
	var first := _payload(10, 100)
	_write(_path(".bak"), first)
	_write(_path(".tmp"), _payload(20, 200))
	_write(_path(".bak.w"), _payload(30, 300))
	_write(_path(".tmp.w"), _payload(40, 400))
	var before := _snapshot()
	Game.gold = 7
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var after := _snapshot()
	for name in before.keys():
		assert_eq(after.get(name), before[name], "%s survives the save" % name)
	assert_eq(int(JSON.parse_string(after[_path().get_file()]).get("gold", -1)), 7)
	assert_false(after.has(_path(".tmp.2").get_file()), "the write cleans its own temp")
	assert_false(after.has(_path(".bak.2").get_file()), "the write cleans its own backup")


func test_repeated_interruptions_accumulate_and_the_greatest_saved_unix_is_used() -> void:
	_write(_path(".bak"), _payload(10, 100))
	_write(_path(".bak.2"), _payload(20, 200))
	_write(_path(".bak.3"), _payload(30, 300))
	var before := _snapshot()
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.gold, 30, "the newest committed copy is the recovery")
	assert_eq(String(loaded.get("recovered_from", "")), "backup")
	assert_eq(_snapshot(), before, "every accumulated copy is left alone")


func test_a_partial_working_temp_does_not_hide_a_valid_backup() -> void:
	_write(_path(".bak"), _payload(10, 100))
	_write_text(_path(".tmp.2"), "{\"gold\":")
	var before := _snapshot()
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.gold, 10)
	assert_eq(_snapshot(), before)


func test_a_failed_write_never_truncates_a_working_copy() -> void:
	_write(_path(".bak"), _payload(10, 100))
	_write(_path(".tmp"), _payload(20, 200))
	_write(_path(".tmp.w"), _payload(50, 500))
	var before := _snapshot()
	# A directory on the primary path makes the commit rename fail.
	var blocked := ProjectSettings.globalize_path(_path())
	DirAccess.make_dir_recursive_absolute(blocked)
	Game.gold = 3
	var saved := Game.save_game(SLOT)
	assert_false(bool(saved.get("ok", false)), "the write reports its failure")
	var after := _snapshot()
	for name in before.keys():
		assert_eq(after.get(name), before[name], "%s survives the failed write" % name)
	assert_false(after.has(_path(".tmp.2").get_file()), "its own temp is cleaned up")
	DirAccess.remove_absolute(blocked)


func test_the_campaign_guard_still_refuses_a_foreign_working_copy() -> void:
	_write(_path(".bak.2"), _payload(40, 400, "someone_else"))
	var before := _snapshot()
	Game.gold = 3
	var saved := Game.save_game(SLOT)
	assert_false(bool(saved.get("ok", false)))
	assert_string_contains(String(saved.get("message", "")), "was not overwritten")
	assert_eq(_snapshot(), before)
	assert_false(FileAccess.file_exists(_path()))


func test_delete_removes_working_copies_too() -> void:
	# Payloads are built first: _payload() saves and deletes the slot, which
	# would otherwise wipe the working copies written before it.
	var primary := _payload(10, 100)
	var backup := _payload(20, 200)
	var second := _payload(30, 300)
	var legacy := _payload(40, 400)
	_write(_path(), primary)
	_write(_path(".bak"), backup)
	_write(_path(".bak.2"), second)
	_write(_path(".tmp.w"), legacy)
	var cleared := SaveSystem.delete_save_everywhere(SLOT)
	assert_true(bool(cleared["ok"]))
	assert_eq(int(cleared["removed"].size()), 4, "every working copy is reported removed")
	assert_false(FileAccess.file_exists(_path()), "the primary is gone")
	assert_false(FileAccess.file_exists(_path(".bak")), "the canonical backup is gone")
	assert_false(FileAccess.file_exists(_path(".bak.2")), "the numbered backup is gone")
	assert_false(FileAccess.file_exists(_path(".tmp.w")), "the legacy temp name is gone")
	assert_false(SaveSystem.has_artifacts(SLOT, CAMPAIGN), "no recoverable copy is left behind")
	assert_eq(_snapshot(), {})
