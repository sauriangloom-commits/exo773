extends GutTest

## Save/content compatibility for supported package edits.
##
## A save pins the campaign id, content_version and saved area/position. Edits that
## leave those references valid must still load; edits that removed the saved area,
## blocked the saved cell, moved it out of bounds, removed a quest/objective the
## save recorded, or changed content_version must refuse before any live state is
## replaced. Harmless edits (prose, entry move, flag-declaration removal) must load.

const ID := "qa_content_compat"
var SIDE := ""

var pkg: String
var area_path: String
var save_path: String
var original_save: String
var draft: Dictionary


func before_each() -> void:
	CampaignStore.delete_user_campaign(ID)
	Game.refresh_campaigns()
	SaveSystem.delete_save_everywhere("slot2")
	var made := CampaignStore.create("Content compatibility", ID)
	assert_true(bool(made.get("ok", false)), String(made.get("message", "")))
	Game.refresh_campaigns()
	draft = Dictionary(CampaignStore.load_package(ID).get("draft", {}))
	CampaignStore.add_area(draft, "Second Area")
	var added: Dictionary = CampaignStore.add_quest(draft, "Side Quest")
	SIDE = String(added.get("id", ""))
	CampaignStore.add_flag_definition(draft, "compat_flag", "compat")
	var written := CampaignStore.write_package(draft)
	assert_true(bool(written.get("ok", false)), String(written.get("message", "")))
	Game.refresh_campaigns()
	var loaded := Game.load_campaign(ID)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	Game.new_game(["kaelen"], 4242)
	Game.quests.start(ID + "_quest")
	Game.quests.start(SIDE)
	Game.flags["compat_flag"] = true
	Game.flags[ID + "_quest_objective_01"] = true
	Game.flags[SIDE + "_done"] = true
	var travel := Game.travel_to("area_02", Vector2i(2, 3), 2)
	assert_true(bool(travel.get("ok", false)), String(travel.get("message", "")))
	var saved := Game.save_game("slot2")
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	pkg = CampaignStore.package_dir(ID)
	area_path = pkg.path_join("areas").path_join("area_02.json")
	save_path = SaveSystem.path_for("slot2", ID)
	original_save = FileAccess.get_file_as_string(save_path)


func after_each() -> void:
	CampaignStore.delete_user_campaign(ID)
	Game.refresh_campaigns()
	SaveSystem.delete_save_everywhere("slot2")
	Game.load_campaign("ravenloft_demo")


func _json(path: String) -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(path)))


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _reload() -> Dictionary:
	Game.refresh_campaigns()
	var loaded := Game.load_campaign(ID)
	if not bool(loaded.get("ok", false)):
		return {"ok": false, "message": String(loaded.get("message", ""))}
	return Game.load_game("slot2")


func _area_rows() -> Array:
	return Array(_json(area_path).get("rows", []))


func _write_area_rows(rows: Array) -> void:
	var area := _json(area_path)
	area["rows"] = rows
	_write_json(area_path, area)


func test_a_prose_only_edit_still_loads_the_save() -> void:
	var manifest := _json(pkg.path_join("campaign.json"))
	manifest["description"] = "Changed prose only."
	_write_json(pkg.path_join("campaign.json"), manifest)
	var loaded := _reload()
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.position, Vector2i(2, 3), "the saved location is restored")
	assert_eq(Game.quests.status(SIDE), "active", "quest progress survives a prose edit")


func test_moving_the_campaign_entry_does_not_relocate_the_save() -> void:
	var manifest := _json(pkg.path_join("campaign.json"))
	manifest["entry"] = {"area": "area_01", "pos": [2, 2], "facing": 1}
	_write_json(pkg.path_join("campaign.json"), manifest)
	var loaded := _reload()
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.position, Vector2i(2, 3), "existing saves stay at their saved cell")


func test_a_saved_cell_that_became_a_wall_is_refused_and_keeps_the_save() -> void:
	var rows := _area_rows()
	var row := String(rows[3])
	rows[3] = row.substr(0, 2) + "#" + row.substr(3)
	_write_area_rows(rows)
	var before_bytes := FileAccess.get_file_as_string(save_path)
	var before_position := Game.position
	var before_campaign := Game.campaign_id
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)), "a save inside a wall is refused")
	assert_string_contains(String(loaded.get("message", "")), "blocked")
	assert_string_contains(String(loaded.get("message", "")), "area_02")
	assert_eq(FileAccess.get_file_as_string(save_path), before_bytes, "the save is not rewritten")
	assert_eq(Game.position, before_position, "the live session is unchanged")
	assert_eq(Game.campaign_id, before_campaign, "the active campaign is unchanged")
	# Restoring compatible content allows recovery.
	rows[3] = row
	_write_area_rows(rows)
	var recovered := _reload()
	assert_true(bool(recovered.get("ok", false)), String(recovered.get("message", "")))
	assert_eq(Game.position, Vector2i(2, 3))


func test_a_saved_position_that_became_out_of_bounds_is_refused_not_teleported() -> void:
	var data := _json(save_path)
	data["position"] = [99, 99]
	_write_json(save_path, data)
	var tampered := FileAccess.get_file_as_string(save_path)
	var before_position := Game.position
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)), "an out-of-bounds save is refused")
	assert_string_contains(String(loaded.get("message", "")), "outside")
	assert_eq(FileAccess.get_file_as_string(save_path), tampered, "the save is not rewritten")
	assert_eq(Game.position, before_position, "the party is not silently moved to the area start")
	# The untouched original save still loads.
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(original_save)
	file.close()
	assert_true(bool(_reload().get("ok", false)))


func test_a_removed_quest_referenced_by_the_save_is_refused() -> void:
	var quests := _json(pkg.path_join("quests.json"))
	quests.erase(SIDE)
	_write_json(pkg.path_join("quests.json"), quests)
	var before_bytes := FileAccess.get_file_as_string(save_path)
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)), "missing saved quest is a refusal, not silent loss")
	assert_string_contains(String(loaded.get("message", "")), SIDE)
	assert_eq(Game.quests.status(SIDE), "active", "the live quest state is unchanged")
	assert_eq(FileAccess.get_file_as_string(save_path), before_bytes, "the save is not rewritten")
	_write_json(pkg.path_join("quests.json"), Dictionary(draft.get("quests", {})))
	var recovered := _reload()
	assert_true(bool(recovered.get("ok", false)))
	assert_eq(Game.quests.status(SIDE), "active", "restoring the quest recovers progress")


func test_a_removed_objective_referenced_by_the_save_is_refused() -> void:
	var quests := _json(pkg.path_join("quests.json"))
	var side: Dictionary = Dictionary(quests[SIDE])
	side["objectives"] = []
	quests[SIDE] = side
	_write_json(pkg.path_join("quests.json"), quests)
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)), "missing saved objective is refused")
	assert_string_contains(String(loaded.get("message", "")), "objective")
	assert_string_contains(String(loaded.get("message", "")), SIDE)


func test_removing_a_flag_declaration_does_not_invalidate_saved_flags() -> void:
	var manifest := _json(pkg.path_join("campaign.json"))
	manifest.erase("flag_definitions")
	_write_json(pkg.path_join("campaign.json"), manifest)
	var loaded := _reload()
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_true(bool(Game.flags.get("compat_flag", false)), "a stored flag value survives its declaration")


func test_removing_the_saved_area_is_refused_before_activation() -> void:
	var before_bytes := FileAccess.get_file_as_string(save_path)
	var before_position := Game.position
	DirAccess.remove_absolute(ProjectSettings.globalize_path(area_path))
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)))
	assert_string_contains(String(loaded.get("message", "")), "missing area")
	assert_eq(FileAccess.get_file_as_string(save_path), before_bytes)
	assert_eq(Game.position, before_position)


func test_a_content_version_change_is_enforced_by_the_existing_contract() -> void:
	var manifest := _json(pkg.path_join("campaign.json"))
	manifest["version"] = 2
	_write_json(pkg.path_join("campaign.json"), manifest)
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)))
	assert_string_contains(String(loaded.get("message", "")), "content version")


func test_an_unsupported_save_format_is_refused() -> void:
	var data := _json(save_path)
	data["save_version"] = 99
	_write_json(save_path, data)
	var before_position := Game.position
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)))
	assert_string_contains(String(loaded.get("message", "")), "incompatible version")
	assert_eq(Game.position, before_position, "the live session is unchanged")


func test_a_save_for_an_uninstalled_campaign_is_refused() -> void:
	var data := _json(save_path)
	data["campaign_id"] = "campaign_that_is_not_installed"
	_write_json(save_path, data)
	var before_campaign := Game.campaign_id
	var loaded := _reload()
	assert_false(bool(loaded.get("ok", false)))
	assert_string_contains(String(loaded.get("message", "")), "not installed")
	assert_eq(Game.campaign_id, before_campaign, "the current campaign is not switched")
