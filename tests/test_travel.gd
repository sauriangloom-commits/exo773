extends GutTest

## Persistent travel between the example gatehouse and the canonical Village of
## Barovia east gate. These tests use the same interaction and save paths as play.

func before_each() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)


func after_each() -> void:
	SaveSystem.delete_save_everywhere("slot1")


func test_gatehouse_road_travels_to_the_village() -> void:
	# The road object is directly west of the authored start position.
	var result := Game.interact()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(Game.area_id, "barovia_east_gate")
	assert_eq(Game.dungeon.id, "barovia_east_gate")
	assert_eq(Game.position, Vector2i(4, 7))
	assert_eq(Game.facing, Dungeon.NORTH)
	assert_eq(Game.mode, "explore")


func test_village_road_returns_to_the_gatehouse() -> void:
	Game.travel_to("barovia_east_gate", Vector2i(4, 7), Dungeon.NORTH)
	# The return object is directly north of the village arrival cell.
	var result := Game.interact()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(Game.area_id, "old_gatehouse")
	assert_eq(Game.dungeon.id, "old_gatehouse")
	assert_eq(Game.position, Vector2i(5, 10))
	assert_eq(Game.facing, Dungeon.WEST)


func test_area_state_survives_round_trip() -> void:
	Game.travel_to("barovia_east_gate", Vector2i(4, 7), Dungeon.NORTH)
	Game.dungeon.mark_removed("barovia_gate")
	Game.travel_to("old_gatehouse", Vector2i(5, 10), Dungeon.WEST)
	Game.travel_to("barovia_east_gate", Vector2i(4, 7), Dungeon.NORTH)
	assert_true(Game.dungeon.is_removed("barovia_gate"), "village state must persist between visits")
	assert_eq(Game.area_id, "barovia_east_gate")


func test_save_load_preserves_area_and_village_state() -> void:
	Game.travel_to("barovia_east_gate", Vector2i(4, 7), Dungeon.NORTH)
	Game.dungeon.mark_removed("barovia_gate")
	Game.position = Vector2i(7, 5)
	Game.facing = Dungeon.WEST
	var saved := Game.save_game("slot1")
	assert_true(bool(saved["ok"]), String(saved.get("message", "")))
	Game.new_game(["kaelen"], 1)
	assert_eq(Game.area_id, "old_gatehouse")
	var loaded := Game.load_game("slot1")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_eq(Game.area_id, "barovia_east_gate")
	assert_eq(Game.dungeon.id, "barovia_east_gate")
	assert_eq(Game.position, Vector2i(7, 5))
	assert_eq(Game.facing, Dungeon.WEST)
	assert_true(Game.dungeon.is_removed("barovia_gate"), "saved area state must restore")


func test_travel_is_refused_during_dialogue() -> void:
	Game.start_dialogue("miruna")
	var result := Game.travel_to("barovia_east_gate", Vector2i(4, 7), Dungeon.NORTH)
	assert_false(bool(result["ok"]))
	assert_eq(Game.area_id, "old_gatehouse")
	assert_eq(Game.mode, "dialogue")
