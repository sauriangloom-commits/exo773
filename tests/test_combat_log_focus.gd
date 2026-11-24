extends GutTest

## Batch 2 of docs/COMBAT_INFO_ACCESS_PLAN.md: keyboard focus and scrolling for
## the combat log.
##
## Failing-first evidence. These tests were written and run against the tree at
## `7941d1e` before any implementation; the logs are kept in
## `builds/qa/combat_info_batch2_red/`. They must fail for behaviour reasons, not
## fixture, import or parse reasons.
##
## What is pinned here:
## - engine assumptions first: whether `RichTextLabel` is a Tab stop at all, and
##   which keys a focused log consumes when its scrollbar is visible;
## - the batch contract: one focus stop, none while the grid cursor is active,
##   built-in scrolling keys, frozen text with a counted indicator, End resuming
##   through the existing `CombatScreen._input` guard, and the modal/off-turn rules;
## - the route from grid targeting to the log, and that no action control is added.
##
## Not here: batch 1 behaviour (already closed), rendered readability, a human
## keyboard-only fight or screen-reader use.

const OPEN_ROWS := [
	"############",
	"#..........#",
	"#..........#",
	"#..........#",
	"#..........#",
	"#..........#",
	"#..........#",
	"#..........#",
	"############",
]
const ACTOR_CELL := Vector2i(1, 4)
const FILLER_LINES := 40

var combat: CombatScreen
var e: Encounter
var actor: Character
var enemies: Array = []


func after_each() -> void:
	if combat != null and is_instance_valid(combat):
		combat.main = null
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


func _setup_fixture(enemy_count := 2) -> void:
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")
	var content = Game.content
	actor = Character.from_content(content.get_character("kaelen"), content.items)
	actor.hp = actor.max_hp
	enemies = []
	var cells: Array = []
	for i in enemy_count:
		var zombie := Character.from_content(content.get_monster("zombie"), content.items)
		zombie.hp = zombie.max_hp
		enemies.append(zombie)
		cells.append(Vector2i(2 + i, 4))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	e = Encounter.new()
	e.setup(
		[actor],
		enemies,
		BattleMap.from_rows(OPEN_ROWS, "log_focus_fixture"),
		rng,
		[ACTOR_CELL],
		cells,
		content.spells,
		"Log focus fixture"
	)
	e.begin()
	Game.party = [actor]
	Game.encounter = e
	Game.mode = "combat"
	Game.last_ui_message = ""
	_force_turn(actor)
	combat = CombatScreen.new()
	add_child_autofree(combat)
	combat.set_anchors_preset(Control.PRESET_TOP_LEFT)
	combat.position = Vector2.ZERO
	combat.size = Vector2(1280, 720)
	await wait_frames(4)
	_seed_log_lines(FILLER_LINES)
	combat.refresh_screen()
	await wait_frames(4)


func _force_turn(ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


## Seeded fixture state: enough log lines that the label must scroll. The text is
## deliberate filler, not combat output.
func _seed_log_lines(count: int) -> void:
	var first := e.log_lines.size()
	for i in count:
		e.log_lines.append("fixture log line %d" % (first + i))


func _bar() -> VScrollBar:
	return combat.log_label.get_v_scroll_bar()


## The widget parks "following the newest line" at the start of the last line, not
## at max_value, so the screen records that position and the tests read it.
func _at_bottom() -> bool:
	var raw = combat.get("_log_bottom")
	if raw == null:
		return false
	return absf(_bar().value - float(raw)) <= float(ThemeBuilder.fs(12))


## The indicator is looked up dynamically so this file compiles before the batch
## adds it: a missing member must fail as behaviour, not as a parse error.
func _hint_text() -> String:
	var label := combat.get("log_hint") as Label
	return label.text if label != null else ""


func _buttons_in(root: Node, text: String) -> Array:
	var found: Array = []
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == text and button.is_visible_in_tree():
			found.append(button)
	return found


func _push_key(code: int, shift := false) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.shift_pressed = shift
		event.pressed = pressed
		get_viewport().push_input(event)
	await wait_frames(2)


func _tab_until(control: Control, limit := 60) -> bool:
	for step in limit:
		if get_viewport().gui_get_focus_owner() == control:
			return true
		await _push_key(KEY_TAB)
	return get_viewport().gui_get_focus_owner() == control


## Fixture: the widget is switched to FOCUS_ALL before it can take the ring,
## because the production contract that makes it a Tab stop does not exist yet.
## With only FOCUS_ACCESSIBILITY the engine refuses grab_focus() unless a screen
## reader is active, which is exactly why the batch has to set the mode. Once the
## batch lands this line is a no-op.
func _focus_log() -> void:
	combat.log_label.focus_mode = Control.FOCUS_ALL
	combat.log_label.grab_focus()
	await wait_frames(2)


func _seed_cleave(dropped_index := -1) -> void:
	e.pending_cleave = {
		"type": "cleave_attack",
		"actor_index": int(e.entry_for(actor)["index"]),
		"dropped_index": dropped_index,
		"weapon": e._primary_weapon(actor),
		"attack_mode": "",
		"attack_base": 0,
		"label": "",
		"off_turn": false,
	}
	combat.refresh_screen()


## ENGINE ASSUMPTION 1: the log is one Tab stop. Before the batch the widget kept
## `FOCUS_ACCESSIBILITY`, so this failed at the traversal step.
func test_the_log_is_a_tab_stop_and_page_up_scrolls_it() -> void:
	await _setup_fixture()
	assert_true(_bar().max_value > _bar().page, "fixture: the log overflows its visible height")
	assert_true(_at_bottom(), "fixture: the log starts at the newest line")
	var move := _buttons_in(combat.button_box, "Move")[0] as Button
	move.grab_focus()
	await wait_frames(1)
	var reached := await _tab_until(combat.log_label, 60)
	assert_true(reached, "Tab reached the combat log")
	if not reached:
		return
	await _push_key(KEY_PAGEUP)
	assert_false(_at_bottom(), "PageUp scrolled the log away from the newest line")


## ENGINE ASSUMPTION 2: a focused log consumes Up/Down/PageUp/PageDown/Home when
## its scrollbar is visible, and consumes none of Enter, Space, Escape or Tab.
## This is the pin that must hold before the contract is built on it.
func test_a_focused_log_owns_only_its_scroll_keys() -> void:
	await _setup_fixture()
	await _focus_log()
	assert_eq(get_viewport().gui_get_focus_owner(), combat.log_label, "fixture: the log holds the ring")
	var start := _bar().value
	await _push_key(KEY_UP)
	assert_lt(_bar().value, start + 0.5, "Up moved the log's own scrollbar")
	await _push_key(KEY_DOWN)
	await _push_key(KEY_PAGEUP)
	assert_false(_at_bottom(), "PageUp moved the log's own scrollbar")
	await _push_key(KEY_HOME)
	assert_eq(_bar().value, 0.0, "Home reached the oldest retained line")
	await _push_key(KEY_PAGEDOWN)
	assert_gt(_bar().value, 0.0, "PageDown moved back down")
	var standard := bool(e.turn_state["standard_used"])
	var move_used := bool(e.turn_state["move_used"])
	await _push_key(KEY_ENTER)
	await _push_key(KEY_SPACE)
	assert_eq(bool(e.turn_state["standard_used"]), standard, "Enter and Space spent no action")
	assert_eq(bool(e.turn_state["move_used"]), move_used, "Enter and Space spent no movement")
	assert_eq(get_viewport().gui_get_focus_owner(), combat.log_label, "Enter and Space keep the ring on the log")
	await _push_key(KEY_ESCAPE)
	assert_eq(get_viewport().gui_get_focus_owner(), combat.log_label, "Escape is not consumed by the log widget")
	await _push_key(KEY_TAB)
	assert_ne(get_viewport().gui_get_focus_owner(), combat.log_label, "Tab leaves the log")


## The grid keeps its accepted path: while its cursor is active the log cannot be
## focused at all, and Tab still lands on the first sidebar control.
func test_the_log_is_not_focusable_while_the_grid_cursor_is_active() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await wait_frames(2)
	assert_true(combat.view.keyboard_cursor_active, "fixture: the grid owns the keyboard")
	assert_eq(combat.log_label.focus_mode, Control.FOCUS_NONE, "the log is not a focus stop while the grid is active")
	await _push_key(KEY_TAB)
	var owner := get_viewport().gui_get_focus_owner()
	assert_false(owner == combat.log_label, "Tab from the grid did not land on the log")
	assert_true(owner is Button and combat.button_box.is_ancestor_of(owner), "Tab from the grid landed on the first sidebar control")
	assert_eq(combat.log_label.focus_mode, Control.FOCUS_ALL, "the log is focusable again once the grid released the ring")


## Reading history freezes what is rendered: a refresh must not rewrite the text,
## jump the offset or clear the reader's place, and the indicator must count what
## arrived.
func test_scrolling_up_freezes_the_text_and_counts_new_lines() -> void:
	await _setup_fixture()
	await _focus_log()
	await _push_key(KEY_PAGEUP)
	assert_false(_at_bottom(), "fixture: the reader left the newest line")
	var frozen_text := combat.log_label.text
	var frozen_offset := _bar().value
	_seed_log_lines(3)
	combat.refresh_screen()
	await wait_frames(4)
	assert_eq(combat.log_label.text, frozen_text, "the rendered log text did not change while frozen")
	assert_eq(_bar().value, frozen_offset, "the scroll offset did not move while frozen")
	assert_true(_hint_text().contains("3 new"), "the indicator counts the three new messages")
	assert_true(_hint_text().contains("End"), "the indicator says how to return")


## End returns to the newest line and resumes following.
func test_end_resumes_following_at_the_newest_line() -> void:
	await _setup_fixture()
	await _focus_log()
	await _push_key(KEY_PAGEUP)
	_seed_log_lines(2)
	combat.refresh_screen()
	await wait_frames(4)
	await _push_key(KEY_END)
	assert_true(_at_bottom(), "End returned to the newest line")
	assert_true(combat.log_label.text.contains(String(e.log_lines[e.log_lines.size() - 1])), "the newest line is rendered after End")
	assert_true(_hint_text().begins_with("Combat log — Tab"), "the indicator is back to the resting instruction")
	_seed_log_lines(1)
	combat.refresh_screen()
	await wait_frames(3)
	assert_true(_at_bottom(), "following resumed: a new line stays at the bottom")


## A pending decision arriving while the reader is frozen changes neither the
## snapshot nor the owner, and stays reachable by Tab.
func test_a_pending_decision_while_frozen_keeps_the_snapshot_and_the_log() -> void:
	await _setup_fixture()
	await _focus_log()
	await _push_key(KEY_PAGEUP)
	var frozen_text := combat.log_label.text
	var frozen_offset := _bar().value
	_seed_cleave()
	await wait_frames(4)
	assert_eq(combat.log_label.text, frozen_text, "the snapshot survived the decision")
	assert_eq(_bar().value, frozen_offset, "the offset survived the decision")
	assert_eq(get_viewport().gui_get_focus_owner(), combat.log_label, "the log kept the ring")
	var choices := combat.decision_box.find_children("*", "Button", true, false)
	assert_gt(choices.size(), 0, "fixture: the decision has controls")
	if choices.is_empty():
		return
	var reached := await _tab_until(choices[0], 40)
	assert_true(reached, "the decision is reachable by Tab from the log")


## A turn change while frozen also leaves the snapshot alone, and reading still
## works off turn.
func test_a_turn_change_while_frozen_keeps_the_snapshot_and_end_still_works() -> void:
	await _setup_fixture()
	await _focus_log()
	await _push_key(KEY_PAGEUP)
	var frozen_text := combat.log_label.text
	_force_turn(enemies[0])
	combat.refresh_screen()
	await wait_frames(4)
	assert_eq(combat.log_label.text, frozen_text, "the snapshot survived the turn change")
	assert_eq(get_viewport().gui_get_focus_owner(), combat.log_label, "the log kept the ring off turn")
	await _push_key(KEY_END)
	assert_true(_at_bottom(), "End still works off turn")


## A modal owns the keyboard: End must not unfreeze or rewrite the log behind it.
func test_a_modal_blocks_end_and_leaves_the_snapshot_alone() -> void:
	await _setup_fixture()
	await _focus_log()
	await _push_key(KEY_PAGEUP)
	var frozen_text := combat.log_label.text
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	var modal_control := Control.new()
	main.add_child(modal_control)
	main.set("modal", modal_control)
	combat.main = main
	_seed_log_lines(2)
	combat.refresh_screen()
	await wait_frames(3)
	await _push_key(KEY_END)
	assert_eq(combat.log_label.text, frozen_text, "End behind a modal did not rewrite the log")
	assert_true(_hint_text().contains("new"), "the indicator still reports the frozen state")
	combat.main = null
	main.free()


## The accepted grid route is unchanged, and forward Tab from the control the grid
## leaves the player on reaches the log.
func test_the_route_from_grid_targeting_to_the_log() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await wait_frames(2)
	await _push_key(KEY_TAB)
	var owner := get_viewport().gui_get_focus_owner()
	assert_true(owner is Button and combat.button_box.is_ancestor_of(owner), "Tab from the grid still lands on the first sidebar control")
	# Forward traversal from the control the grid leaves the player on is the route
	# to the log; the target rows above it do not have to be walked backwards.
	var steps := 0
	while steps < 60 and get_viewport().gui_get_focus_owner() != combat.log_label:
		await _push_key(KEY_TAB)
		steps += 1
	assert_eq(
		get_viewport().gui_get_focus_owner(),
		combat.log_label,
		"Tab continues from the grid's landing control to the log"
	)


## The batch adds one focusable element, not an action control: the layout
## predicate still refuses the log, and the action grid keeps its 19 buttons.
func test_the_log_is_not_an_action_control() -> void:
	await _setup_fixture()
	assert_eq(combat.button_box.get_child_count(), 19, "the action grid keeps its 19 buttons")
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	assert_false(bool(main.call("_layout_interactive", combat.log_label)), "the log is not counted as an action control")
	main.free()
