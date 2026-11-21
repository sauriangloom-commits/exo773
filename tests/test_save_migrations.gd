extends GutTest

## Save migrations: the shipped table is empty, a version this build cannot reach
## is refused with the same message as before, and a synthetically upgraded
## payload reaches live state without ever being written back on load.

const SLOT := "migration_probe"
const CAMPAIGN := "ravenloft_demo"

var original_steps: Dictionary = {}
var original_target := 0


func before_each() -> void:
	original_steps = SaveMigrations.steps.duplicate()
	original_target = SaveMigrations.target_override
	SaveMigrations.steps = {}
	SaveMigrations.target_override = 0
	Game.load_campaign(CAMPAIGN)
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)
	_remove_slot()


func after_each() -> void:
	SaveMigrations.steps = original_steps
	SaveMigrations.target_override = original_target
	_remove_slot()
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


## This test writes raw bytes at the campaign path, so it removes that save and
## anything a failed write could have left beside it itself.
func _remove_slot() -> void:
	var path := SaveSystem.path_for(SLOT, CAMPAIGN)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))


func _write_raw(version: int, extra: Dictionary = {}) -> String:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(SaveSystem.campaign_dir(CAMPAIGN))
	)
	var path := SaveSystem.path_for(SLOT, CAMPAIGN)
	var payload := {"slot": SLOT, "campaign_id": CAMPAIGN, "save_version": version, "gold": 5}
	payload.merge(extra, true)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return path


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_the_shipped_table_has_no_step_and_refuses_other_versions() -> void:
	assert_eq(SaveSystem.SAVE_VERSION, 1, "this foundation does not bump the version")
	assert_eq(SaveMigrations.target_override, 0, "production reads the shipped version")
	assert_true(SaveMigrations.steps.is_empty(), "no production migration step exists")
	var current: Variant = SaveMigrations.upgrade({"gold": 5}, 1, 1)
	assert_true(current is Dictionary, "a current payload comes back")
	assert_eq(int(Dictionary(current).get("gold", 0)), 5)
	assert_null(SaveMigrations.upgrade({"gold": 5}, 2, 1), "a newer payload is refused")
	assert_null(SaveMigrations.upgrade({"gold": 5}, 0, 1), "a payload below the floor is refused")


func test_synthetic_steps_chain_and_preserve_unknown_fields() -> void:
	var step_one := func(data: Dictionary) -> Dictionary:
		data["added_v2"] = true
		return data
	var step_two := func(data: Dictionary) -> Dictionary:
		data["copied_v3"] = data.get("future", "missing")
		return data
	SaveMigrations.steps = {1: step_one, 2: step_two}
	var upgraded: Variant = SaveMigrations.upgrade({"gold": 5, "future": {"deep": [1, 2]}}, 1, 3)
	assert_true(upgraded is Dictionary, "the chain completes")
	if not upgraded is Dictionary:
		return
	var data: Dictionary = upgraded
	assert_eq(int(data.get("gold", 0)), 5, "existing fields survive")
	assert_eq(data.get("future"), {"deep": [1, 2]}, "unknown fields survive")
	assert_true(bool(data.get("added_v2", false)), "the first step ran")
	assert_eq(data.get("copied_v3"), {"deep": [1, 2]}, "the second step saw the first one's work")


func test_a_missing_step_refuses_the_whole_chain() -> void:
	var step_one := func(data: Dictionary) -> Dictionary:
		data["added_v2"] = true
		return data
	SaveMigrations.steps = {1: step_one}
	assert_null(SaveMigrations.upgrade({"gold": 5}, 1, 3), "no step for version 2 means no partial upgrade")


func test_a_step_that_cannot_upgrade_refuses_and_never_mutates_the_caller() -> void:
	var refusing := func(_data: Dictionary) -> Variant:
		return null
	SaveMigrations.steps = {1: refusing}
	assert_null(SaveMigrations.upgrade({"gold": 5}, 1, 2), "a null step is a refusal")
	var mutating := func(data: Dictionary) -> Dictionary:
		data["mutated"] = true
		return data
	SaveMigrations.steps = {1: mutating}
	var source := {"gold": 5}
	var result: Variant = SaveMigrations.upgrade(source, 1, 2)
	assert_false(source.has("mutated"), "the caller's payload is never mutated")
	assert_true(result is Dictionary and bool(Dictionary(result).get("mutated", false)), "the copy was upgraded")


func test_an_unsupported_version_is_refused_and_the_file_is_untouched() -> void:
	var path := _write_raw(99)
	var before := _text(path)
	var read := SaveSystem.read_save(SLOT, CAMPAIGN)
	assert_false(bool(read.get("ok", false)), "the load is refused")
	assert_eq(
		String(read.get("message", "")),
		"Save %s was written by an incompatible version (99.0)." % SLOT,
		"the refusal message is unchanged (JSON reads the version as a float)"
	)
	assert_eq(String(read.get("reason", "")), "unsupported_version")
	assert_eq(_text(path), before, "the file keeps its bytes")
	assert_false(FileAccess.file_exists(path + ".tmp"), "no temp file is left behind")
	assert_false(FileAccess.file_exists(path + ".bak"), "no backup is left behind")


func test_a_version_below_the_floor_is_refused_even_with_steps() -> void:
	var step_zero := func(data: Dictionary) -> Dictionary:
		data["guessed"] = true
		return data
	SaveMigrations.steps = {0: step_zero}
	SaveMigrations.target_override = 2
	var path := _write_raw(0)
	var before := _text(path)
	var read := SaveSystem.read_save(SLOT, CAMPAIGN)
	assert_false(bool(read.get("ok", false)), "a pre-version-1 payload is not guessed at")
	assert_eq(_text(path), before, "the file keeps its bytes")


func test_a_synthetic_upgrade_is_read_without_writing_the_file() -> void:
	var step_one := func(data: Dictionary) -> Dictionary:
		data["added_v2"] = true
		return data
	SaveMigrations.steps = {1: step_one}
	SaveMigrations.target_override = 2
	var path := _write_raw(1, {"future": "keep"})
	var before := _text(path)
	var read := SaveSystem.read_save(SLOT, CAMPAIGN)
	assert_true(bool(read.get("ok", false)), String(read.get("message", "")))
	assert_eq(int(read.get("migrated_from", -1)), 1, "the read reports where it came from")
	var data: Dictionary = read["data"]
	assert_true(bool(data.get("added_v2", false)), "the step's field is present")
	assert_eq(String(data.get("future", "")), "keep", "unknown fields survive the read")
	assert_eq(_text(path), before, "reading a migrated save does not rewrite it")


func test_a_refused_load_leaves_live_state_and_the_file_alone() -> void:
	assert_true(bool(Game.save_game(SLOT).get("ok", false)), "the fixture save is written")
	var path := SaveSystem.path_for(SLOT, CAMPAIGN)
	var payload: Dictionary = JSON.parse_string(_text(path))
	payload["save_version"] = 99
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	var before := _text(path)
	Game.gold += 7
	var gold_before := Game.gold
	var position_before := Game.position
	var area_before := Game.area_id
	var party_before := Game.party.size()
	var read := Game.load_game(SLOT)
	assert_false(bool(read.get("ok", false)), "the load is refused")
	assert_string_contains(String(read.get("message", "")), "incompatible version")
	assert_eq(Game.gold, gold_before, "live gold is untouched")
	assert_eq(Game.position, position_before, "live position is untouched")
	assert_eq(Game.area_id, area_before, "live area is untouched")
	assert_eq(Game.party.size(), party_before, "the live party is untouched")
	assert_eq(_text(path), before, "the save keeps its bytes")


func test_a_synthetic_upgrade_reaches_live_state() -> void:
	assert_true(bool(Game.save_game(SLOT).get("ok", false)), "the fixture save is written")
	var path := SaveSystem.path_for(SLOT, CAMPAIGN)
	var payload: Dictionary = JSON.parse_string(_text(path))
	var saved_gold := int(payload.get("gold", 0))
	payload["save_version"] = 1
	var step_one := func(data: Dictionary) -> Dictionary:
		data["gold"] = int(data.get("gold", 0)) + 100
		return data
	SaveMigrations.steps = {1: step_one}
	SaveMigrations.target_override = 2
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	var before := _text(path)
	var read := Game.load_game(SLOT)
	assert_true(bool(read.get("ok", false)), String(read.get("message", "")))
	assert_eq(Game.gold, saved_gold + 100, "the migrated value reaches live state")
	assert_eq(_text(path), before, "loading a migrated save does not rewrite it")
