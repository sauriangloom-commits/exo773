extends GutTest

## Every refusal family reaches the exploration log now, and a repeated identical
## refusal does not stack. Before this, eight paths set `last_ui_message` and
## returned, and no UI reads that variable, so nothing appeared anywhere.

const DEMO := "ravenloft_demo"
const WALL_LINE := "Cold stone blocks the way."


func before_each() -> void:
	Game.reset_to_menu()
	var loaded := Game.load_campaign(DEMO)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	var started := Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))


func after_each() -> void:
	Game.reset_to_menu()
	Game.load_campaign(DEMO)


func _count(line: String) -> int:
	var total := 0
	for entry in Game.log_lines:
		if String(entry) == line:
			total += 1
	return total


func _kill_party() -> void:
	for ch in Game.party:
		if not ch.has_condition("dead"):
			ch.add_effect("dead", "Dead", 0, "condition")


## A cell the party can stand on whose step leads to `target` from `facing`.
func _stand_and_face(target: Vector2i) -> Dictionary:
	for facing in [Dungeon.NORTH, Dungeon.EAST, Dungeon.SOUTH, Dungeon.WEST]:
		var from: Vector2i = target - Dungeon.DIRS[facing]
		if not Game.dungeon.in_bounds(from) or Game.dungeon.is_wall(from):
			continue
		if not Game.dungeon.door_at(from).is_empty():
			continue
		Game.position = from
		Game.facing = facing
		return {"from": from, "facing": facing}
	return {}


func test_blocked_step_refuses_and_logs_once() -> void:
	Game.position = Vector2i(0, 0)
	Game.facing = Dungeon.WEST
	var before := Game.log_lines.size()
	var result := Game.move_forward()
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), WALL_LINE)
	assert_eq(Game.last_ui_message, WALL_LINE)
	assert_eq(Game.log_lines.size(), before + 1, "the refusal adds one log line")
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), WALL_LINE)


func test_repeated_blocked_step_does_not_duplicate_the_line() -> void:
	Game.position = Vector2i(0, 0)
	Game.facing = Dungeon.WEST
	Game.move_forward()
	var after_first := Game.log_lines.size()
	var second := Game.move_forward()
	assert_false(bool(second.get("ok", true)))
	assert_eq(String(second.get("message", "")), WALL_LINE, "the message is still returned")
	assert_eq(Game.log_lines.size(), after_first, "a consecutive duplicate is suppressed")
	assert_eq(_count(WALL_LINE), 1)


func test_a_different_line_between_refusals_logs_again() -> void:
	Game.position = Vector2i(0, 0)
	Game.facing = Dungeon.WEST
	Game.move_forward()
	Game.log("You listen at the wall.")
	Game.move_forward()
	assert_eq(_count(WALL_LINE), 2, "only consecutive duplicates are suppressed")


func test_closed_door_refusal() -> void:
	var setup := {}
	for cell in Game.dungeon.doors.keys():
		if Game.dungeon.is_door_open(cell):
			continue
		setup = _stand_and_face(cell)
		if not setup.is_empty():
			break
	assert_false(setup.is_empty(), "the demo has a closed door the party can reach")
	if setup.is_empty():
		return
	var door := Game.dungeon.door_at(Vector2i(Game.position) + Dungeon.DIRS[Game.facing])
	var expected := "%s is closed. Press F to open it." % String(door.get("name", "The door"))
	var result := Game.move_forward()
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), expected)
	assert_eq(Game.last_ui_message, expected)
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), expected)


func test_npc_in_the_way_refusal() -> void:
	var setup := {}
	var npc := {}
	for npc_id in Game.dungeon.npcs.keys():
		if Game.dungeon.is_removed(npc_id):
			continue
		npc = Game.dungeon.npcs[npc_id]
		setup = _stand_and_face(npc["pos"])
		if not setup.is_empty():
			break
	assert_false(setup.is_empty(), "an NPC stands somewhere the party can step into")
	if setup.is_empty():
		return
	var expected := "%s is in the way." % String(npc.get("name", "Someone"))
	var result := Game.move_forward()
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), expected)
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), expected)


func test_nothing_within_reach_refusal() -> void:
	var spot := {}
	for y in 12:
		for x in 12:
			var cell := Vector2i(x, y)
			if not Game.dungeon.in_bounds(cell) or Game.dungeon.is_wall(cell):
				continue
			for facing in [Dungeon.NORTH, Dungeon.EAST, Dungeon.SOUTH, Dungeon.WEST]:
				var target := Game.dungeon.front_target(cell, facing)
				if String(target.get("kind", "")) == "floor":
					spot = {"cell": cell, "facing": facing}
					break
			if not spot.is_empty():
				break
		if not spot.is_empty():
			break
	assert_false(spot.is_empty(), "the demo has open floor to look at")
	if spot.is_empty():
		return
	Game.position = spot["cell"]
	Game.facing = spot["facing"]
	var result := Game.interact()
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), "There is nothing within reach.")
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), "There is nothing within reach.")


func test_no_lockpicker_refusal() -> void:
	_kill_party()
	var result := Game._try_open_door({"id": "qa_locked", "name": "QA door", "locked": true, "lock_dc": 15}, 0)
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), "No one can pick the lock.")
	assert_eq(Game.last_ui_message, "No one can pick the lock.")
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), "No one can pick the lock.")


func test_removed_object_refusal() -> void:
	Game.dungeon.mark_removed("qa_ghost")
	var result := Game._interact_object({"id": "qa_ghost", "look": "A shelf."}, 0)
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), "There is nothing left here.")
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), "There is nothing left here.")


func test_no_usable_interaction_refusal() -> void:
	var before := Game.log_lines.size()
	var result := Game._interact_object({"id": "qa_bare_shelf", "look": "A bare shelf.", "interactions": []}, 0)
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), "You find nothing you can use.")
	assert_eq(Game.log_lines.size(), before + 2, "the look and the refusal both log")
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), "You find nothing you can use.")


func test_no_conscious_adventurer_refusal() -> void:
	_kill_party()
	var result := Game._run_interaction({"id": "qa_box"}, {"skill": "search", "dc": 10, "label": "the shelf"}, 0)
	assert_false(bool(result.get("ok", true)))
	assert_eq(String(result.get("message", "")), "No conscious adventurer can attempt that.")
	assert_eq(String(Game.log_lines[Game.log_lines.size() - 1]), "No conscious adventurer can attempt that.")


func test_refusal_returns_the_failure_shape() -> void:
	Game.position = Vector2i(0, 0)
	Game.facing = Dungeon.WEST
	var result := Game.move_forward()
	assert_false(bool(result["ok"]))
	assert_true(result.has("message"))
	assert_eq(result.size(), 2, "the dictionary keeps exactly its two keys")
	assert_eq(String(result["message"]), Game.last_ui_message)


func test_both_input_paths_share_one_log_line() -> void:
	var screen := ExplorationScreen.new()
	add_child_autofree(screen)
	await wait_frames(2)
	Game.position = Vector2i(0, 0)
	Game.facing = Dungeon.WEST
	# Keyboard: the handler calls Game.move_forward() and drops the result.
	Game.move_forward()
	var after_keyboard := Game.log_lines.size()
	# Action bar: the handler calls the same function and hands the result to
	# _do(), which refreshes the screen and must not log the refusal twice.
	var result := Game.move_forward()
	screen._do(result)
	await wait_frames(1)
	assert_eq(Game.log_lines.size(), after_keyboard, "the action path adds no duplicate")
	assert_eq(_count(WALL_LINE), 1)
	assert_true(screen.log_label.text.contains(WALL_LINE), "the log widget shows the refusal")
