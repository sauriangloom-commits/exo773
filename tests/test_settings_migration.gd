extends GutTest

## Settings file versioning: missing keys keep the compiled defaults, hand-edited
## values are clamped on load, unknown sections, keys and bindings survive a write,
## and a file written by a newer build is read but never rewritten.

const TEST_PATH := "user://test_settings_migration.cfg"


func before_each() -> void:
	Game.settings_path = TEST_PATH
	Game.settings_newer = false
	Game.settings = Game.default_settings()
	_remove()
	InputMap.load_from_project_settings()


func after_each() -> void:
	_remove()
	Game.settings_path = "user://settings.cfg"
	Game.settings_newer = false
	Game.settings = Game.default_settings()
	InputMap.load_from_project_settings()


func _remove() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func _write(sections: Dictionary) -> void:
	var config := ConfigFile.new()
	for section in sections.keys():
		for key in Dictionary(sections[section]).keys():
			config.set_value(section, key, Dictionary(sections[section])[key])
	config.save(TEST_PATH)


func _read() -> ConfigFile:
	var config := ConfigFile.new()
	assert_eq(config.load(TEST_PATH), OK, "the settings file is readable")
	return config


func _text() -> String:
	return FileAccess.get_file_as_string(TEST_PATH)


func test_a_missing_file_keeps_the_compiled_defaults() -> void:
	Game.load_settings()
	assert_false(Game.settings_newer, "a missing file is not a newer file")
	assert_almost_eq(float(Game.settings["master"]), 0.9, 0.001)
	assert_almost_eq(float(Game.settings["text_scale"]), 1.0, 0.001)
	assert_false(bool(Game.settings["fullscreen"]))


func test_load_clamps_hand_edited_values() -> void:
	_write({
		"meta": {"version": 1},
		"audio": {"master": 5.0, "music": -2.0, "sfx": 0.5},
		"display": {"text_scale": 9.0, "fullscreen": "yes"},
	})
	Game.load_settings()
	assert_almost_eq(float(Game.settings["master"]), 1.0, 0.001, "a volume above 1 is clamped")
	assert_almost_eq(float(Game.settings["music"]), 0.0, 0.001, "a negative volume is clamped")
	assert_almost_eq(float(Game.settings["sfx"]), 0.5, 0.001, "a valid volume is kept")
	assert_almost_eq(float(Game.settings["text_scale"]), 1.6, 0.001, "text scale is clamped to the slider's range")
	assert_true(bool(Game.settings["fullscreen"]), "a non-empty string becomes true")


func test_unknown_keys_and_sections_survive_a_write() -> void:
	_write({
		"meta": {"version": 1},
		"future": {"token": "keep", "count": 3},
		"audio": {"master": 0.4},
	})
	Game.load_settings()
	assert_almost_eq(float(Game.settings["master"]), 0.4, 0.001)
	Game.set_fullscreen(true)
	var config := _read()
	assert_eq(String(config.get_value("future", "token", "")), "keep", "an unknown section survives")
	assert_eq(int(config.get_value("future", "count", 0)), 3, "an unknown key survives")
	assert_eq(int(config.get_value("meta", "version", 0)), 1, "the file records its version")
	assert_almost_eq(float(config.get_value("audio", "master", 0.0)), 0.4, 0.001, "known values are rewritten")
	assert_true(bool(config.get_value("display", "fullscreen", false)), "the changed value is written")


func test_a_newer_file_is_read_but_never_written() -> void:
	_write({
		"meta": {"version": 99},
		"audio": {"master": 0.33},
		"future": {"x": 1},
	})
	var before := _text()
	Game.load_settings()
	assert_true(Game.settings_newer, "the file is marked as written by a newer build")
	assert_almost_eq(float(Game.settings["master"]), 0.33, 0.001, "its known values are still read")
	Game.set_volume("music", 0.1)
	assert_almost_eq(float(Game.settings["music"]), 0.1, 0.001, "the change applies in memory")
	assert_eq(_text(), before, "the newer file is not rewritten")
	assert_true(Game.settings_newer, "the block stays in place")


func test_a_legacy_file_without_a_version_is_current() -> void:
	_write({"audio": {"master": 0.4}})
	Game.load_settings()
	assert_false(Game.settings_newer, "an unversioned file is version 1")
	assert_almost_eq(float(Game.settings["master"]), 0.4, 0.001)
	Game.set_volume("music", 0.2)
	var config := _read()
	assert_eq(int(config.get_value("meta", "version", 0)), 1, "the next write records a version")
	assert_almost_eq(float(config.get_value("audio", "master", 0.0)), 0.4, 0.001, "values it did not touch are kept")


func test_unknown_keybind_actions_are_kept_but_not_applied() -> void:
	_write({
		"meta": {"version": 1},
		"input": {"keybinds": {"move_forward": 87, "not_an_action": 65}},
	})
	Game.load_settings()
	var binds: Dictionary = Game.settings["keybinds"]
	assert_eq(int(binds.get("move_forward", 0)), 87, "a known binding is kept")
	assert_eq(int(binds.get("not_an_action", -1)), 65, "an unknown action is kept for a later build")
	assert_false(InputMap.has_action("not_an_action"), "an unknown action is not applied")
	var events := InputMap.action_get_events("move_forward")
	assert_false(events.is_empty(), "the known action has an event")
	if not events.is_empty():
		assert_eq((events[0] as InputEventKey).physical_keycode, 87, "the known binding is applied")
	Game.set_volume("music", 0.2)
	var config := _read()
	var saved: Dictionary = config.get_value("input", "keybinds", {})
	assert_eq(int(saved.get("not_an_action", -1)), 65, "the unknown binding survives the write")
	assert_eq(int(saved.get("move_forward", 0)), 87, "the known binding survives the write")
