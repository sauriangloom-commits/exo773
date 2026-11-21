extends GutTest

## Phase 3: source-grounded Village of Barovia town square (ECR E3), explicit
## demo routing, persistent area state, encounter persistence and save/load.

func before_each() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 424242)


func after_each() -> void:
	for slot in ["slot1", "slot2"]:
		SaveSystem.delete_save_everywhere(slot)


func _force_victory() -> void:
	var e := Game.encounter
	assert_not_null(e)
	for entry in e.combatants:
		if int(entry["team"]) == 1:
			entry["char"].take_damage(9999)
	e._check_end()
	assert_eq(Game.mode, "explore", "victory should return to exploration")


func _travel_to_square() -> void:
	var result := Game.travel_to("barovia_town_square", Vector2i(5, 9), Dungeon.NORTH)
	assert_true(bool(result["ok"]), String(result.get("message", "")))


func test_area_registry_lists_the_source_area_and_demo_staging() -> void:
	assert_eq(Game.content.errors.size(), 0, "\n".join(Game.content.errors))
	assert_false(Game.content.get_area("barovia_town_square").is_empty())
	assert_eq(String(Game.content.area_manifest.get("default", "")), "old_gatehouse")
	assert_true(Array(Game.content.area_manifest.get("source_grounded", [])).has("barovia_town_square"))
	assert_true(Array(Game.content.area_manifest.get("demo_only", [])).has("barovia_east_gate"))


func test_entry_activates_the_source_lead_and_features_it_in_the_tracker() -> void:
	assert_true(Game.quest_tracker_text().contains("The Drowned Bell"))
	_travel_to_square()
	assert_true(Game.quests.is_active("lightbringers"))
	assert_true(Game.quest_tracker_text().contains("The Lightbringers"))
	assert_false(Game.quest_tracker_text().contains("The Drowned Bell"))


func test_developer_route_reaches_the_source_area_and_returns() -> void:
	var first := Game.interact()  # East-road/demo object west of the gatehouse start.
	assert_true(bool(first["ok"]), String(first.get("message", "")))
	assert_eq(Game.area_id, "barovia_east_gate")

	# The staging area's forward waystone is north of the arrival point.
	Game.position = Vector2i(4, 3)
	Game.facing = Dungeon.NORTH
	var second := Game.interact()
	assert_true(bool(second["ok"]), String(second.get("message", "")))
	assert_eq(Game.area_id, "barovia_town_square")
	assert_eq(Game.position, Vector2i(5, 9))
	assert_eq(Game.facing, Dungeon.NORTH)

	# The return waystone is at the southeast corner of the square.
	Game.position = Vector2i(9, 8)
	Game.facing = Dungeon.SOUTH
	var back := Game.interact()
	assert_true(bool(back["ok"]), String(back.get("message", "")))
	assert_eq(Game.area_id, "barovia_east_gate")
	assert_eq(Game.position, Vector2i(4, 7))


func test_square_breach_starts_the_source_encounter_once() -> void:
	_travel_to_square()
	assert_eq(Game.area_id, "barovia_town_square")
	assert_eq(Game.position, Vector2i(5, 9))
	Game.facing = Dungeon.NORTH
	var entered := Game.move_forward()
	assert_true(bool(entered["ok"]), String(entered.get("message", "")))
	assert_eq(Game.mode, "combat")
	assert_eq(Game.active_encounter_id, "town_square_zombies")
	assert_eq(Game.encounter.enemies().size(), 2)
	var zombie: Character = Game.encounter.enemies()[0]
	assert_eq(zombie.max_hp, 42)
	assert_true(zombie.single_actions_only)
	assert_eq(int(zombie.damage_reduction.get("amount", 0)), 5)
	_force_victory()
	assert_true(bool(Game.flags.get("town_square_saved", false)))
	assert_true(bool(Game.flags.get("ashlyn_survived", false)))
	assert_true(Game.quests.is_active("lightbringers"))
	assert_false(Game.quests.is_complete("lightbringers"))

	# The trigger must not restart a resolved encounter.
	Game.position = Vector2i(5, 7)
	Game.facing = Dungeon.SOUTH
	Game.move_forward()
	assert_eq(Game.mode, "explore")


func test_barricade_repair_is_one_time_and_survives_reload() -> void:
	_travel_to_square()
	Game.flags["town_square_saved"] = true
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	var repaired := Game.interact()
	assert_true(bool(repaired["ok"]), String(repaired.get("message", "")))
	assert_true(bool(Game.flags.get("barricade_repaired", false)))
	assert_true(Game.dungeon.is_removed("breach"))
	var again := Game.interact()
	assert_false(bool(again["ok"]))
	var saved := Game.save_game("slot1")
	assert_true(bool(saved["ok"]), String(saved.get("message", "")))
	Game.new_game(["kaelen"], 1)
	var loaded := Game.load_game("slot1")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_true(Game.dungeon.is_removed("breach"))
	assert_true(bool(Game.flags.get("barricade_repaired", false)))


func test_ashlyn_dialogue_starts_and_completes_the_lightbringer_lead() -> void:
	_travel_to_square()
	Game.flags["town_square_saved"] = true
	Game.position = Vector2i(5, 4)
	Game.facing = Dungeon.NORTH
	var talked := Game.interact()
	assert_true(bool(talked["ok"]), String(talked.get("message", "")))
	assert_eq(Game.mode, "dialogue")
	assert_true(bool(Game.flags.get("ashlyn_met", false)))
	var choices := Game.dialogue_choices()
	var index := -1
	for i in choices.size():
		if String(choices[i]["text"]).contains("What happened here?"):
			index = i
	var picked := Game.dialogue_choose(index)
	assert_true(bool(picked["ok"]), String(picked.get("message", "")))
	var exits := Game.dialogue_choices()
	Game.dialogue_choose(exits.size() - 1)
	assert_eq(Game.mode, "explore")
	assert_true(Game.quests.is_complete("lightbringers"))


func test_invalid_and_blocked_transitions_leave_area_unchanged() -> void:
	var before := Game.area_id
	var missing := Game.travel_to("no_such_area", Vector2i(1, 1), Dungeon.NORTH)
	assert_false(bool(missing["ok"]))
	assert_eq(Game.area_id, before)
	var blocked := Game.travel_to("barovia_town_square", Vector2i(0, 0), Dungeon.NORTH)
	assert_false(bool(blocked["ok"]))
	assert_eq(Game.area_id, before)


func test_complete_loop_save_quit_load_and_return_without_repeating_rewards() -> void:
	_travel_to_square()
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	Game.move_forward()
	assert_eq(Game.active_encounter_id, "town_square_zombies")
	_force_victory()
	var xp_after_victory: int = Game.party[0].xp

	# Speak to Ashlyn and close the Lightbringer lead.
	Game.position = Vector2i(5, 4)
	Game.facing = Dungeon.NORTH
	assert_true(bool(Game.interact()["ok"]))
	var choices := Game.dialogue_choices()
	var index := -1
	for i in choices.size():
		if String(choices[i]["text"]).contains("We will hold the square"):
			index = i
	assert_gte(index, 0)
	assert_true(bool(Game.dialogue_choose(index)["ok"]))
	var exits := Game.dialogue_choices()
	Game.dialogue_choose(exits.size() - 1)
	assert_eq(Game.mode, "explore")
	assert_true(bool(Game.flags.get("ashlyn_met", false)))

	# Repair the barricade, then save, quit and load through the player save API.
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	assert_true(bool(Game.interact()["ok"]))
	var saved := Game.save_game("slot1")
	assert_true(bool(saved["ok"]), String(saved.get("message", "")))
	Game.new_game(["kaelen"], 1)
	var loaded := Game.load_game("slot1")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_eq(Game.area_id, "barovia_town_square")
	assert_eq(Game.position, Vector2i(5, 9))
	assert_true(bool(Game.flags.get("town_square_saved", false)))
	assert_true(bool(Game.flags.get("ashlyn_met", false)))
	assert_true(bool(Game.flags.get("barricade_repaired", false)))
	assert_true(Game.quests.is_complete("lightbringers"))
	assert_true(Game.dungeon.is_removed("breach"))

	# Leave to the staging map and return; no second encounter or XP award.
	Game.position = Vector2i(9, 8)
	Game.facing = Dungeon.SOUTH
	assert_true(bool(Game.interact()["ok"]))
	assert_eq(Game.area_id, "barovia_east_gate")
	Game.position = Vector2i(4, 3)
	Game.facing = Dungeon.NORTH
	assert_true(bool(Game.interact()["ok"]))
	assert_eq(Game.area_id, "barovia_town_square")
	assert_eq(Game.party[0].xp, xp_after_victory)
	assert_eq(Game.mode, "explore")


func test_old_save_without_area_keys_still_loads_the_gatehouse() -> void:
	var legacy := Game.serialize()
	legacy.erase("area_id")
	legacy.erase("areas")
	var written := SaveSystem.write_save("slot2", legacy, Game.campaign_id)
	assert_true(bool(written["ok"]), String(written.get("message", "")))
	var loaded := Game.load_game("slot2")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_eq(Game.area_id, "old_gatehouse")
	assert_eq(Game.dungeon.id, "old_gatehouse")


func test_barricade_repair_autosaves_through_the_interaction_path() -> void:
	_travel_to_square()
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	Game.move_forward()
	assert_eq(Game.mode, "combat")
	_force_victory()

	# The victory autosave exists already and must not yet know about the repair.
	var before := SaveSystem.read_save("auto", Game.campaign_id)
	assert_true(bool(before["ok"]), String(before.get("message", "")))
	assert_false(bool(Dictionary(before["data"]["flags"]).get("barricade_repaired", false)))

	# Repair by interacting; no explicit save call anywhere in this test.
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	var repaired := Game.interact()
	assert_true(bool(repaired["ok"]), String(repaired.get("message", "")))
	assert_true(bool(Game.flags.get("barricade_repaired", false)))
	assert_true(Game.dungeon.is_removed("breach"))

	# The interaction itself must have written the autosave, with flag and object.
	var written := SaveSystem.read_save("auto", Game.campaign_id)
	assert_true(bool(written["ok"]), String(written.get("message", "")))
	assert_true(
		bool(Dictionary(written["data"]["flags"]).get("barricade_repaired", false)),
		"autosave payload must carry the repair flag"
	)
	assert_true(
		Array(Dictionary(written["data"]["dungeon"])["removed"]).has("breach"),
		"autosave payload must carry the removed barricade"
	)

	Game.new_game(["kaelen"], 1)
	var loaded := Game.load_game("auto")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_true(bool(Game.flags.get("barricade_repaired", false)))
	assert_true(Game.dungeon.is_removed("breach"))


func test_barricade_repair_survives_a_manual_save_from_the_save_panel() -> void:
	_travel_to_square()
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	Game.move_forward()
	_force_victory()
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	assert_true(bool(Game.interact()["ok"]))
	assert_true(bool(Game.flags.get("barricade_repaired", false)))

	# Save through the real Save Game panel rather than the save API.
	SaveSystem.delete_save_everywhere("slot1")
	var panel := Panels.saves("save", func() -> void: pass)
	add_child_autofree(panel)
	await wait_frames(2)
	var rows: Array = []
	for node in panel.find_children("*", "Button", true, false):
		if (node as Button).text == "Save here":
			rows.append(node)
	assert_eq(rows.size(), 3, "one save button per named slot")
	(rows[0] as Button).emit_signal("pressed")
	await wait_frames(1)
	assert_true(SaveSystem.exists("slot1", Game.campaign_id), "the panel wrote slot1")

	Game.new_game(["kaelen"], 1)
	var loaded := Game.load_game("slot1")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_true(bool(Game.flags.get("barricade_repaired", false)))
	assert_true(Game.dungeon.is_removed("breach"))


func test_failed_interaction_autosave_never_reports_success() -> void:
	_travel_to_square()
	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	Game.move_forward()
	_force_victory()

	# Point the save directory at a regular file so every write must fail.
	var blocker := "user://test_saves/blocked_by_a_file"
	var handle := FileAccess.open(blocker, FileAccess.WRITE)
	assert_not_null(handle)
	handle.store_string("blocker")
	handle.close()
	var previous_dir := SaveSystem.save_dir
	SaveSystem.save_dir = blocker

	Game.position = Vector2i(5, 9)
	Game.facing = Dungeon.NORTH
	var before := Game.log_lines.size()
	var repaired := Game.interact()

	SaveSystem.save_dir = previous_dir
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker))

	assert_true(bool(repaired["ok"]), "the repair still applies in memory")
	assert_true(bool(Game.flags.get("barricade_repaired", false)))
	var written := "\n".join(Game.log_lines.slice(before))
	assert_true(written.contains("Autosave failed"), written)
	assert_false(written.contains("Autosaved."), "a failed write must not be reported as saved")
