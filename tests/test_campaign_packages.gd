extends GutTest

## Campaign package contract: registry, validation, isolation and persistence.
##
## These tests cover the platform outcome, not a feat or encounter: a second
## campaign must load, play and save through the same systems as the first,
## without leaking ids or saves between them.

const RAVENLOFT := "ravenloft_demo"
const HOLLOW := "hollow_lantern"


func before_each() -> void:
	_clear_saves()
	Game.load_campaign(RAVENLOFT)


func after_each() -> void:
	_clear_saves()


func _clear_saves() -> void:
	for slot in ["slot1", "slot2", "slot3", "auto", "campaign_probe"]:
		SaveSystem.delete_save_everywhere(slot)


func _find_choice(choices: Array, needle: String) -> int:
	for i in choices.size():
		if String(Dictionary(choices[i]).get("text", "")).contains(needle):
			return i
	return -1


func _contains(lines: Array, needle: String) -> bool:
	for line in lines:
		if String(line).contains(needle):
			return true
	return false


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file, "could not write %s" % path)
	if file != null:
		file.store_string(text)
		file.close()


func _cleanup_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(String(file_name))))
	for dir_name in DirAccess.get_directories_at(path):
		_cleanup_dir(path.path_join(String(dir_name)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_registry_installs_two_campaigns() -> void:
	assert_eq(Game.campaigns.errors, [], "registry loads without errors")
	assert_true(Game.campaigns.order.has(RAVENLOFT))
	assert_true(Game.campaigns.order.has(HOLLOW))
	assert_eq(Game.campaigns.default_id, RAVENLOFT)


func test_each_campaign_validates_cleanly() -> void:
	for id in [RAVENLOFT, HOLLOW]:
		var result := Game.validate_campaign(String(id))
		assert_true(bool(result.get("ok", false)), "%s:\n%s" % [id, "\n".join(result.get("errors", []))])


func test_campaigns_share_rules_but_not_story() -> void:
	Game.load_campaign(RAVENLOFT)
	assert_false(Game.content.get_item("bell_clapper").is_empty(), "shared items load")
	assert_false(Game.content.get_area("old_gatehouse").is_empty(), "Ravenloft area loads")
	Game.load_campaign(HOLLOW)
	assert_false(Game.content.get_item("bell_clapper").is_empty(), "shared item is still available")
	assert_false(Game.content.get_area("lantern_yard").is_empty(), "campaign-local area loads")
	assert_true(Game.content.get_area("old_gatehouse").is_empty(), "another campaign's area cannot leak in")
	assert_true(Game.content.get_quest("drowned_bell").is_empty(), "another campaign's quest cannot leak in")


func test_manifest_rejects_unsupported_capability_and_bad_entry() -> void:
	Game.load_campaign(HOLLOW)
	var before := Game.content.errors.size()
	Game.content.campaign["requires"] = {"capabilities": ["time_travel"]}
	Game.content._validate_campaign()
	assert_gt(Game.content.errors.size(), before)
	assert_true(_contains(Game.content.errors, "unsupported platform capability"))
	Game.content.campaign["requires"] = {"capabilities": ["exploration"]}
	before = Game.content.errors.size()
	Game.content.campaign["entry"] = {"area": "nowhere", "pos": [0, 0]}
	Game.content._validate_campaign()
	assert_gt(Game.content.errors.size(), before)
	assert_true(_contains(Game.content.errors, "entry area 'nowhere' does not exist"))
	Game.load_campaign(HOLLOW)


func test_duplicate_area_and_local_spells_are_rejected() -> void:
	var root := "user://campaign_contract_test"
	_cleanup_dir(root)
	DirAccess.make_dir_recursive_absolute(root.path_join("areas"))
	_write_text(root.path_join("quests.json"), "{}")
	_write_text(root.path_join("encounters.json"), "{}")
	_write_text(root.path_join("items.json"), "{}")
	_write_text(root.path_join("spells.json"), "{}")
	_write_text(
		root.path_join("dungeon.json"),
		"{\"id\":\"dup_area\",\"name\":\"Dup\",\"rows\":[\"###\",\"#.#\",\"###\"],\"start\":{\"pos\":[1,1]}}"
	)
	_write_text(
		root.path_join("areas/dup_area.json"),
		"{\"id\":\"dup_area\",\"name\":\"Dup\",\"rows\":[\"###\",\"#.#\",\"###\"],\"start\":{\"pos\":[1,1]}}"
	)
	var db := ContentDB.new()
	db.load_campaign({
		"format_version": 1,
		"id": "contract_test",
		"title": "Contract test",
		"description": "Temporary package used by the test suite.",
		"version": 1,
		"content_root": root,
		"start_quest": "",
		"entry": {"area": "dup_area", "pos": [1, 1]},
		"party": {"default": ["kaelen"], "min": 1, "max": 4},
	})
	assert_true(_contains(db.errors, "Duplicate area id"), "\n".join(db.errors))
	assert_true(_contains(db.errors, "spell definitions are shared mechanics"), "\n".join(db.errors))
	_cleanup_dir(root)


func test_new_game_starts_at_the_campaign_entry() -> void:
	Game.load_campaign(HOLLOW)
	var result := Game.new_game([], 999)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	assert_eq(Game.campaign_id, HOLLOW)
	assert_eq(Game.area_id, "lantern_yard")
	assert_eq(Game.position, Vector2i(4, 7))
	assert_eq(Game.mode, "explore")
	assert_eq(Game.quests.status("lantern_watch"), "active")


func test_campaign_consequence_persists_through_save_and_reload() -> void:
	Game.load_campaign(HOLLOW)
	Game.new_game([], 4242)
	Game.position = Vector2i(3, 7)
	Game.facing = Dungeon.NORTH
	var read := Game.interact()
	assert_true(bool(read.get("ok", false)), String(read.get("message", "")))
	assert_true(bool(Game.flags.get("lantern_notice_read", false)))
	var talk := Game.start_dialogue("keeper_ivy")
	assert_true(bool(talk.get("ok", false)), String(talk.get("message", "")))
	var index := _find_choice(Game.dialogue_choices(), "take the watch")
	assert_gte(index, 0, "the watch-taking choice is offered")
	Game.dialogue_choose(index)
	assert_true(bool(Game.flags.get("lantern_met_keeper", false)))
	assert_eq(Game.quests.status("lantern_watch"), "active")
	if Game.mode == "dialogue":
		Game.dialogue_choose(_find_choice(Game.dialogue_choices(), "come back"))
	assert_eq(Game.mode, "explore")
	var saved := Game.save_game("slot1")
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	Game.new_game([], 99)
	var loaded := Game.load_game("slot1")
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_true(bool(Game.flags.get("lantern_notice_read", false)))
	assert_true(bool(Game.flags.get("lantern_met_keeper", false)))
	assert_eq(Game.campaign_id, HOLLOW)


func test_save_identity_is_per_campaign() -> void:
	Game.load_campaign(RAVENLOFT)
	Game.new_game([], 111)
	Game.flags["ravenloft_probe"] = true
	var saved := Game.save_game("slot1")
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	assert_true(SaveSystem.exists("slot1", RAVENLOFT))
	Game.load_campaign(HOLLOW)
	assert_false(SaveSystem.exists("slot1", HOLLOW))
	assert_false(bool(Game.load_game("slot1").get("ok", false)), "another campaign's slot is not visible")
	Game.new_game([], 222)
	Game.flags["hollow_probe"] = true
	var hollow_saved := Game.save_game("slot1")
	assert_true(bool(hollow_saved.get("ok", false)), String(hollow_saved.get("message", "")))
	assert_true(SaveSystem.exists("slot1", RAVENLOFT), "the other campaign's save is untouched")
	Game.load_campaign(RAVENLOFT)
	var loaded := Game.load_game("slot1")
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_true(bool(Game.flags.get("ravenloft_probe", false)))
	assert_false(bool(Game.flags.get("hollow_probe", false)))
	assert_eq(Game.campaign_id, RAVENLOFT)


func test_save_refuses_to_overwrite_a_newer_content_version() -> void:
	Game.load_campaign(HOLLOW)
	Game.new_game([], 5)
	var payload := Game.serialize()
	payload["content_version"] = Game.content_version + 1
	SaveSystem.write_save("slot2", payload, HOLLOW)
	var path := SaveSystem.path_for("slot2", HOLLOW)
	var before := FileAccess.get_file_as_string(path)
	var result := Game.save_game("slot2")
	assert_false(bool(result.get("ok", false)))
	assert_true(String(result.get("message", "")).contains("content version"))
	assert_eq(FileAccess.get_file_as_string(path), before, "incompatible save is not overwritten")
	assert_false(bool(Game.load_game("slot2").get("ok", false)))


func test_legacy_save_is_read_and_never_rewritten() -> void:
	Game.load_campaign(RAVENLOFT)
	Game.new_game([], 11)
	SaveSystem.write_save("slot3", Game.serialize(), "")
	var legacy_path := SaveSystem.path_for("slot3")
	var before := FileAccess.get_file_as_string(legacy_path)
	Game.flags["legacy_probe"] = true
	var saved := Game.save_game("slot3")
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	assert_eq(FileAccess.get_file_as_string(legacy_path), before, "legacy file is read-only")
	assert_true(SaveSystem.exists("slot3", RAVENLOFT), "new writes go to the campaign directory")
	Game.new_game([], 12)
	var loaded := Game.load_game("slot3")
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.campaign_id, RAVENLOFT)
