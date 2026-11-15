extends GutTest

## End-to-end vertical-slice test: talk, loot, fight, parley/fight, ring the
## bell, save and reload — all through the public GameSession API.

func before_each() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 777)


func after_each() -> void:
	SaveSystem.delete_save("slot3")


func _find_choice(needle: String) -> int:
	var choices := Game.dialogue_choices()
	for i in choices.size():
		if String(choices[i]["text"]).contains(needle):
			return i
	return -1


func _force_victory() -> void:
	var e := Game.encounter
	assert_not_null(e)
	for entry in e.combatants:
		if int(entry["team"]) == 1:
			entry["char"].hp = 1
	var guard := 0
	while Game.mode == "combat" and guard < 80:
		guard += 1
		e = Game.encounter
		if e == null or e.finished:
			break
		if e.is_player_turn():
			var pc: Character = e.active_character()
			var target_index := -1
			for entry in e.combatants:
				if int(entry["team"]) == 1 and not entry["char"].has_condition("dead"):
					target_index = int(entry["index"])
					break
			if target_index < 0:
				break
			var pc_entry: Dictionary = e.entry_for(pc)
			var target_cell: Vector2i = e.combatants[target_index]["cell"]
			var candidates := [
				target_cell + Vector2i(0, 1),
				target_cell + Vector2i(0, -1),
				target_cell + Vector2i(1, 0),
				target_cell + Vector2i(-1, 0),
			]
			for candidate in candidates:
				if (
					e.map.in_bounds(candidate)
					and not e.map.is_blocked(candidate)
					and not e.occupied_except(int(pc_entry["index"])).has(candidate)
				):
					pc_entry["cell"] = candidate
					break
			Game.combat_attack(target_index)
			if Game.mode == "combat" and not e.finished:
				Game.combat_end_turn()
		else:
			e.auto_advance()
	assert_eq(Game.mode, "explore", "combat should resolve back to exploration")


func test_full_demonstration_loop() -> void:
	# 1. Meet Miruna and accept the example quest.
	Game.position = Vector2i(2, 10)
	Game.facing = Dungeon.NORTH
	var talked := Game.interact()
	assert_true(bool(talked["ok"]), String(talked.get("message", "")))
	assert_eq(Game.mode, "dialogue")
	assert_gte(_find_choice("find the clapper"), 0)
	Game.dialogue_choose(_find_choice("find the clapper"))
	Game.dialogue_choose(_find_choice("Stay here"))
	assert_eq(Game.mode, "explore")
	assert_true(bool(Game.flags.get("met_miruna", false)))

	# 2. Enter the storeroom through its door and fight the example encounter.
	Game.dungeon.set_door_open("store_door", true)
	Game.position = Vector2i(6, 7)
	Game.facing = Dungeon.EAST
	Game.move_forward()
	assert_eq(Game.mode, "combat")
	assert_eq(Game.encounter.enemies().size(), 2)
	_force_victory()
	assert_true(bool(Game.flags.get("storeroom_cleared", false)))
	assert_true(Game.party[0].xp > 3000, "combat awards XP")

	# 3. Loot the storeroom (seeded until the Search check passes).
	var found := false
	for seed_value in range(1, 40):
		Game.rng.seed = seed_value
		Game.position = Vector2i(8, 7)
		Game.facing = Dungeon.NORTH
		Game.interact()
		if bool(Game.flags.get("found_clapper", false)):
			found = true
			break
	assert_true(found, "the clapper is obtainable through the authored Search check")

	# 4. Open the crypt door with the gatehouse key.
	Game.position = Vector2i(5, 4)
	Game.facing = Dungeon.NORTH
	var opened := Game.interact()
	assert_true(bool(opened["ok"]), String(opened.get("message", "")))
	assert_true(bool(Game.flags.get("crypt_door_open", false)))

	# 5. Confront Corvin; choose violence, then win.
	Game.position = Vector2i(2, 2)
	Game.facing = Dungeon.NORTH
	var met := Game.interact()
	assert_true(bool(met["ok"]), String(met.get("message", "")))
	assert_eq(Game.mode, "dialogue")
	assert_gte(_find_choice("Destroy it"), 0)
	Game.dialogue_choose(_find_choice("Destroy it"))
	assert_eq(Game.mode, "combat")
	_force_victory()
	assert_true(bool(Game.flags.get("warden_resolved", false)))

	# 6. Ring the bell and complete the quest.
	Game.position = Vector2i(7, 3)
	Game.facing = Dungeon.NORTH
	var rang := Game.interact()
	assert_true(bool(rang["ok"]), String(rang.get("message", "")))
	assert_true(bool(Game.flags.get("bell_rung", false)))
	assert_true(Game.quests.is_complete("drowned_bell"))
	assert_true(Game.victory_pending)

	# 7. Save and reload the finished slice.
	var position_before := Game.position
	var saved := Game.save_game("slot3")
	assert_true(bool(saved["ok"]), String(saved.get("message", "")))
	var loaded := Game.load_game("slot3")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_true(Game.quests.is_complete("drowned_bell"))
	assert_eq(Game.position, position_before)
	assert_true(bool(Game.flags.get("storeroom_cleared", false)))
	assert_true(bool(Game.flags.get("warden_resolved", false)))
	assert_eq(Game.mode, "explore")
