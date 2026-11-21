extends GutTest

## Exploration: grid movement, facing, doors, objects, skill checks and
## encounter triggers.


func before_each() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 90210)


func test_starts_at_authored_position_facing_west() -> void:
	assert_eq(Game.position, Vector2i(5, 10))
	assert_eq(Game.facing, Dungeon.WEST)
	assert_eq(Game.mode, "explore")


func test_movement_and_turning_are_grid_based() -> void:
	var start := Game.position
	Game.move_forward()
	assert_eq(Game.position, start + Vector2i(-1, 0))
	Game.turn_right()
	assert_eq(Game.facing, Dungeon.NORTH)
	Game.move_forward()
	assert_eq(Game.position, start + Vector2i(-1, -1))


func test_walls_block_movement() -> void:
	Game.position = Vector2i(1, 9)
	Game.facing = Dungeon.WEST
	var result := Game.move_forward()
	assert_false(bool(result["ok"]))
	assert_eq(Game.position, Vector2i(1, 9))


func test_occupied_npc_cell_blocks_movement() -> void:
	Game.position = Vector2i(2, 10)
	Game.facing = Dungeon.NORTH
	var result := Game.move_forward()
	assert_false(bool(result["ok"]), String(result.get("message", "")))
	assert_true(String(result["message"]).contains("Miruna"))
	assert_eq(Game.position, Vector2i(2, 10))


func test_closed_door_blocks_movement_until_opened() -> void:
	Game.position = Vector2i(5, 4)
	Game.facing = Dungeon.NORTH
	var blocked := Game.move_forward()
	assert_false(bool(blocked["ok"]))
	assert_true(String(blocked["message"]).contains("closed"))
	# The key is in the storeroom; grant it directly for this unit test.
	Game.party[0].add_to_inventory(Game.content.get_item("gatehouse_key"), 1)
	var opened := Game.interact()
	assert_true(bool(opened["ok"]), String(opened.get("message", "")))
	assert_true(bool(Game.dungeon.open_doors.get("crypt_door", false)))
	var moved := Game.move_forward()
	assert_true(bool(moved["ok"]), String(moved.get("message", "")))


func test_lockpick_check_is_logged() -> void:
	Game.position = Vector2i(5, 4)
	Game.facing = Dungeon.NORTH
	Game.rng.seed = 3
	var result := Game.interact()
	var text := "\n".join(Game.log_lines)
	assert_true(text.contains("works the lock"), "the Open Lock roll is auditable")
	assert_true(text.contains("DC 15"))
	assert_eq(typeof(result), TYPE_DICTIONARY)


func test_search_check_grants_clapper_and_removes_object() -> void:
	var found := false
	for seed_value in range(1, 30):
		Game.rng.seed = seed_value
		Game.position = Vector2i(8, 7)
		Game.facing = Dungeon.NORTH
		Game.interact()
		if bool(Game.flags.get("found_clapper", false)):
			found = true
			break
	assert_true(found, "Sera's Search check eventually beats DC 12")
	var party_clappers := 0
	for ch in Game.party:
		party_clappers += ch.inventory_count("bell_clapper")
	assert_eq(party_clappers, 1, "the clapper goes into party inventory")
	assert_true(Game.dungeon.is_removed("supply_crate"), "one-time search removes the object")
	var again := Game.interact()
	assert_false(bool(again["ok"]))


func test_shrine_rest_restores_party() -> void:
	Game.party[0].take_damage(10)
	Game.position = Vector2i(2, 7)
	Game.facing = Dungeon.NORTH
	Game.interact()
	assert_eq(Game.party[0].hp, Game.party[0].max_hp)
	assert_true(bool(Game.flags.get("rested_at_shrine", false)))


func test_entering_storeroom_triggers_encounter() -> void:
	Game.dungeon.set_door_open("store_door", true)
	Game.position = Vector2i(6, 7)
	Game.facing = Dungeon.EAST
	Game.move_forward()
	assert_eq(Game.position, Vector2i(7, 7))
	assert_eq(Game.mode, "combat")
	assert_eq(Game.active_encounter_id, "storeroom_dead")
	assert_eq(Game.encounter.enemies().size(), 2)


func test_bell_without_clapper_is_blocked_with_explanation() -> void:
	Game.position = Vector2i(7, 3)
	Game.facing = Dungeon.NORTH
	var result := Game.interact()
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("no clapper"), String(result["message"]))
	assert_false(bool(Game.flags.get("bell_rung", false)))


func test_bell_with_clapper_completes_the_objective() -> void:
	Game.party[0].add_to_inventory(Game.content.get_item("bell_clapper"), 1)
	Game.flags["met_miruna"] = true
	Game.flags["found_clapper"] = true
	Game.flags["warden_resolved"] = true
	Game.position = Vector2i(7, 3)
	Game.facing = Dungeon.NORTH
	var result := Game.interact()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(Game.flags.get("bell_rung", false)))
	assert_true(Game.quests.is_complete("drowned_bell"))
	assert_true(Game.victory_pending)


func test_look_describes_facing_and_contents() -> void:
	Game.position = Vector2i(2, 10)
	Game.facing = Dungeon.NORTH
	var description := Game.look()
	assert_true(description.contains("north"))
	assert_true(description.contains("Miruna"), description)
