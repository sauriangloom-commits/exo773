extends GutTest

## Conservative save recovery: a missing or unreadable primary falls back to the
## backup and then the temp file of an interrupted write, every candidate passes
## the same validation as a normal load, selecting one changes no file and no live
## state, and a later save keeps leftovers it did not create.

const SLOT := "recovery_probe"
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
	SaveSystem.delete_save(SLOT)
	var directory := SaveSystem.path_for(SLOT, CAMPAIGN)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


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


## A complete, valid payload with a chosen gold value, written nowhere.
func _payload(gold: int, campaign := CAMPAIGN) -> Dictionary:
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var payload: Dictionary = JSON.parse_string(_text(_path()))
	payload["gold"] = gold
	if campaign != CAMPAIGN:
		payload["campaign_id"] = campaign
	SaveSystem.delete_save(SLOT)
	return payload


func test_a_missing_primary_is_recovered_from_the_backup() -> void:
	var payload := _payload(123)
	_write(_path(".bak"), payload)
	var before := _text(_path(".bak"))
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(String(loaded.get("recovered_from", "")), "backup")
	assert_string_contains(String(loaded.get("message", "")), "backup")
	assert_eq(Game.gold, 123, "the recovered state is live")
	assert_eq(_text(_path(".bak")), before, "the backup keeps its bytes")
	assert_false(FileAccess.file_exists(_path()), "loading does not promote the backup")


func test_a_corrupt_primary_falls_back_to_the_backup() -> void:
	var payload := _payload(77)
	_write(_path(".bak"), payload)
	_write_text(_path(), "{\"save_version\":1,")
	var corrupt_before := _text(_path())
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(String(loaded.get("recovered_from", "")), "backup")
	assert_eq(Game.gold, 77)
	assert_eq(_text(_path()), corrupt_before, "the damaged primary is left exactly as it is")


func test_the_temp_is_used_when_no_backup_reads() -> void:
	var payload := _payload(55)
	_write(_path(".tmp"), payload)
	var before := _text(_path(".tmp"))
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(String(loaded.get("recovered_from", "")), "temp")
	assert_string_contains(String(loaded.get("message", "")), "unfinished write")
	assert_eq(Game.gold, 55)
	assert_eq(_text(_path(".tmp")), before)


func test_an_incompatible_primary_stops_the_search() -> void:
	var payload := _payload(41)
	_write(_path(".bak"), payload)
	var backup_before := _text(_path(".bak"))
	var primary := payload.duplicate(true)
	primary["save_version"] = 99
	_write(_path(), primary)
	var gold_before := Game.gold
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)), "a newer primary is a refusal, not a downgrade")
	assert_string_contains(String(loaded.get("message", "")), "incompatible version")
	assert_eq(Game.gold, gold_before, "no live state changes")
	assert_eq(_text(_path(".bak")), backup_before, "the backup is not used or touched")


func test_a_valid_primary_wins_over_leftovers() -> void:
	var payload := _payload(10)
	_write(_path(), payload)
	var backup := payload.duplicate(true)
	backup["gold"] = 20
	_write(_path(".bak"), backup)
	var temp := payload.duplicate(true)
	temp["gold"] = 30
	_write(_path(".tmp"), temp)
	var before := [_text(_path()), _text(_path(".bak")), _text(_path(".tmp"))]
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(String(loaded.get("recovered_from", "")), "", "a valid primary is not a recovery")
	assert_eq(Game.gold, 10)
	assert_eq([_text(_path()), _text(_path(".bak")), _text(_path(".tmp"))], before, "no file is touched")


func test_leftovers_from_another_campaign_are_not_loaded() -> void:
	var payload := _payload(88, "some_other_campaign")
	_write(_path(".bak"), payload)
	var before := _text(_path(".bak"))
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)), "a foreign recovery copy is refused")
	assert_eq(Game.campaign_id, CAMPAIGN, "the campaign is not switched for a leftover")
	assert_eq(_text(_path(".bak")), before)


func test_no_valid_candidate_keeps_the_files_and_the_refusal() -> void:
	_write_text(_path(".tmp"), "not json")
	var before := _text(_path(".tmp"))
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_string_contains(String(loaded.get("message", "")), "No save in")
	assert_eq(_text(_path(".tmp")), before)


func test_legacy_fallback_is_blocked_by_campaign_artifacts() -> void:
	var payload := _payload(5)
	var legacy := payload.duplicate(true)
	legacy.erase("campaign_id")
	legacy["gold"] = 999
	_write(SaveSystem.path_for(SLOT), legacy)
	_write(_path(".bak"), payload)
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(String(loaded.get("recovered_from", "")), "backup")
	assert_eq(Game.gold, 5, "the campaign backup stands in, not an older legacy save")


func test_legacy_fallback_still_serves_an_empty_campaign_slot() -> void:
	var payload := _payload(999)
	var legacy := payload.duplicate(true)
	legacy.erase("campaign_id")
	_write(SaveSystem.path_for(SLOT), legacy)
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(String(loaded.get("recovered_from", "")), "", "a legacy load is not a recovery")
	assert_eq(Game.gold, 999)
	SaveSystem.delete_save(SLOT)


func test_a_successful_save_keeps_the_recovery_artifacts() -> void:
	var crashed := _payload(111)
	_write(_path(".bak"), crashed)
	var uncommitted := crashed.duplicate(true)
	uncommitted["gold"] = 222
	_write(_path(".tmp"), uncommitted)
	var backup_before := _text(_path(".bak"))
	var temp_before := _text(_path(".tmp"))
	Game.gold = 7
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	assert_eq(_text(_path(".bak")), backup_before, "the crashed backup survives the save")
	assert_eq(_text(_path(".tmp")), temp_before, "the crashed temp survives the save")
	assert_false(FileAccess.file_exists(_path(".bak.w")), "no working backup is left behind")
	assert_false(FileAccess.file_exists(_path(".tmp.w")), "no working temp is left behind")
	assert_eq(int(JSON.parse_string(_text(_path())).get("gold", 0)), 7, "the new primary holds the new save")


func test_a_save_over_another_campaigns_leftovers_is_refused() -> void:
	var crashed := _payload(50, "someone_else")
	_write(_path(".bak"), crashed)
	var before := _text(_path(".bak"))
	Game.gold = 3
	var saved := Game.save_game(SLOT)
	assert_false(bool(saved.get("ok", false)), "a foreign crashed slot is not overwritten")
	assert_string_contains(String(saved.get("message", "")), "was not overwritten")
	assert_eq(_text(_path(".bak")), before)
	assert_false(FileAccess.file_exists(_path()), "no primary is written")


func test_a_failed_write_leaves_the_recovery_files_alone() -> void:
	var crashed := _payload(64)
	_write(_path(".bak"), crashed)
	_write(_path(".tmp"), crashed)
	var backup_before := _text(_path(".bak"))
	var temp_before := _text(_path(".tmp"))
	# A directory on the primary path makes the final rename fail.
	var blocked := ProjectSettings.globalize_path(_path())
	DirAccess.make_dir_recursive_absolute(blocked)
	Game.gold = 3
	var saved := Game.save_game(SLOT)
	assert_false(bool(saved.get("ok", false)), "the write reports its failure")
	assert_eq(_text(_path(".bak")), backup_before, "the failed write keeps the backup")
	assert_eq(_text(_path(".tmp")), temp_before, "the failed write keeps the temp")
	assert_false(FileAccess.file_exists(_path(".tmp.w")), "its own working temp is cleaned up")
	DirAccess.remove_absolute(blocked)


func test_selection_changes_nothing_until_the_load_is_accepted() -> void:
	var payload := _payload(90)
	_write(_path(".bak"), payload)
	_write_text(_path(), "broken")
	Game.gold = 12
	var position_before := Game.position
	var broken_backup := payload.duplicate(true)
	broken_backup["party"] = []
	_write(_path(".bak"), broken_backup)
	var damaged_before := _text(_path(".bak"))
	var refused := Game.load_game(SLOT)
	assert_false(bool(refused.get("ok", false)), "no candidate validates")
	assert_eq(Game.gold, 12, "live gold is untouched")
	assert_eq(Game.position, position_before, "live position is untouched")
	assert_eq(_text(_path(".bak")), damaged_before, "the invalid candidate is left alone")
	_write(_path(".bak"), payload)
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.gold, 90)
