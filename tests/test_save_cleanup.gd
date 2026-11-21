extends GutTest

## `SaveSystem.delete_save_everywhere` is test/QA cleanup, not a player action.
## These tests pin its full scope, its per-file failure report, and the fact that
## no UI reaches it.

const SLOT := "slot1"
const CAMPAIGN_A := "cleanup_a"
const CAMPAIGN_B := "cleanup_b"

var _held: FileAccess = null


func before_each() -> void:
	_wipe()


func after_each() -> void:
	if _held != null:
		_held.close()
		_held = null
	_wipe()


func _wipe() -> void:
	SaveSystem.delete_save_everywhere(SLOT)
	_remove_dir(SaveSystem.campaign_dir(CAMPAIGN_A))
	_remove_dir(SaveSystem.campaign_dir(CAMPAIGN_B))


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(file_name)))
	for dir_name in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(dir_name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file, "could not write %s" % path)
	if file == null:
		return
	file.store_string(text)
	file.close()


func _slot_path(campaign_id: String, suffix := "") -> String:
	return SaveSystem.path_for(SLOT, campaign_id) + suffix


func test_removes_the_slot_from_every_campaign_and_the_legacy_directory() -> void:
	_write_text(_slot_path(CAMPAIGN_A), "a")
	_write_text(_slot_path(CAMPAIGN_A, ".bak"), "a-bak")
	_write_text(_slot_path(CAMPAIGN_A, ".bak.2"), "a-bak2")
	_write_text(_slot_path(CAMPAIGN_B), "b")
	_write_text(_slot_path(CAMPAIGN_B, ".tmp"), "b-tmp")
	_write_text(_slot_path(""), "legacy")
	var result := SaveSystem.delete_save_everywhere(SLOT)
	assert_true(bool(result["ok"]))
	assert_eq(int(result["removed"].size()), 6, "every accepted file is reported removed")
	assert_eq(int(result["failed"].size()), 0)
	for path in [_slot_path(CAMPAIGN_A), _slot_path(CAMPAIGN_A, ".bak"),
			_slot_path(CAMPAIGN_A, ".bak.2"), _slot_path(CAMPAIGN_B),
			_slot_path(CAMPAIGN_B, ".tmp"), _slot_path("")]:
		assert_false(FileAccess.file_exists(String(path)), "%s is gone" % path)


func test_preserves_unrelated_files() -> void:
	_write_text(_slot_path(CAMPAIGN_A), "payload")
	var archive := _slot_path(CAMPAIGN_A, ".2026-11-20")
	var notes := _slot_path(CAMPAIGN_A, ".notes")
	var other := SaveSystem.campaign_dir(CAMPAIGN_A).path_join("other.txt")
	_write_text(archive, "archive")
	_write_text(notes, "notes")
	_write_text(other, "other")
	var result := SaveSystem.delete_save_everywhere(SLOT)
	assert_true(bool(result["ok"]))
	assert_eq(int(result["removed"].size()), 1, "only the slot's own file is removed")
	assert_false(FileAccess.file_exists(_slot_path(CAMPAIGN_A)))
	assert_eq(FileAccess.get_file_as_string(archive), "archive")
	assert_eq(FileAccess.get_file_as_string(notes), "notes")
	assert_eq(FileAccess.get_file_as_string(other), "other")


func test_no_files_is_a_successful_no_op() -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.campaign_dir(CAMPAIGN_A))
	var result := SaveSystem.delete_save_everywhere(SLOT)
	assert_true(bool(result["ok"]), "nothing to remove is not a failure")
	assert_eq(int(result["removed"].size()), 0)
	assert_eq(int(result["failed"].size()), 0)


func test_a_locked_copy_is_reported_per_file_and_the_rest_still_go() -> void:
	var primary := _slot_path(CAMPAIGN_A)
	var held_path := _slot_path(CAMPAIGN_A, ".bak")
	var other := _slot_path(CAMPAIGN_A, ".bak.2")
	_write_text(primary, "primary")
	_write_text(held_path, "held")
	_write_text(other, "other")
	_held = FileAccess.open(held_path, FileAccess.READ)
	assert_not_null(_held, "the test needs an open handle to the backup")
	if _held == null:
		return
	var result := SaveSystem.delete_save_everywhere(SLOT)
	if result["failed"].is_empty():
		# Some hosts unlink an open file; the failure path cannot be exercised
		# there, so only the success contract is checked.
		assert_true(bool(result["ok"]))
		assert_eq(int(result["removed"].size()), 3)
		return
	assert_false(bool(result["ok"]), "a remaining file is never reported as success")
	assert_eq(int(result["failed"].size()), 1, "one failure per remaining file")
	var failure: Dictionary = result["failed"][0]
	assert_eq(String(failure["path"]), held_path, "the failure names the locked file")
	assert_ne(int(failure["error"]), OK, "the filesystem error is reported")
	assert_true(FileAccess.file_exists(held_path), "the locked file really is still there")
	assert_false(FileAccess.file_exists(primary), "other copies are still removed")
	assert_false(FileAccess.file_exists(other), "other copies are still removed")
	for path_value in result["removed"]:
		assert_ne(String(path_value), held_path, "a remaining file is not listed as removed")
	_held.close()
	_held = null
	var retry := SaveSystem.delete_save_everywhere(SLOT)
	assert_true(bool(retry["ok"]), "closing the handle lets the retry finish the job")


func test_no_player_ui_file_calls_the_cleanup_helper() -> void:
	for file_name in DirAccess.get_files_at("res://src/ui"):
		if not String(file_name).ends_with(".gd"):
			continue
		var text := FileAccess.get_file_as_string("res://src/ui/%s" % file_name)
		assert_false(text.contains("delete_save"),
			"src/ui/%s must not reach the all-campaign cleanup helper" % file_name)


func test_main_calls_the_helper_only_from_probes() -> void:
	var text := FileAccess.get_file_as_string("res://src/main.gd")
	var current := ""
	var offenders: Array = []
	for line in text.split("\n"):
		var trimmed := String(line).strip_edges()
		if trimmed.begins_with("func "):
			current = trimmed.substr(5).split("(")[0]
		if not trimmed.contains("delete_save_everywhere("):
			continue
		# Probe entry points and the fixture they share; nothing a button,
		# key or menu handler can call.
		if current.contains("probe") or current == "_compat_ui_fixture":
			continue
		offenders.append("%s: %s" % [current, trimmed])
	assert_eq(offenders, [], "only probe functions may call the cleanup helper")
