extends GutTest

## Batch 1 of docs/COMBAT_INFO_ACCESS_PLAN.md: sidebar and pending-decision
## reveal, plus focus stability across combat refreshes.
##
## Failing-first evidence. These tests were written and run against the tree at
## `78956f9` before any implementation, and the logs are kept in
## `builds/qa/combat_info_batch1_red/`. They must fail there for behaviour
## reasons, not fixture, import or parse reasons.
##
## What is pinned here, and what is deliberately not:
## - fixture: an open 12x9 map, the fighter at (1,4) and enough zombies that the
##   target list overflows its inner scroller and sits below the outer sidebar
##   fold; the initiative pointer is forced onto the fighter with the engine's own
##   `_begin_turn`, and pending Cleave state is seeded for the decision tests.
## - behaviour: focus is moved with `grab_focus()` where a test needs a known
##   starting owner, and every traversal or activation after that goes through
##   real key events pushed to the viewport.
## - not here: the combat log (batch 2), the grid cursor path, mouse targeting,
##   pause handling, rules, 32-control layout and the rules/content suites.
##
## Action controls stay 32: this file never adds a focusable control of its own,
## and the count test uses the same predicate as `Main._layout_interactive`.

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

var combat: CombatScreen
var e: Encounter
var actor: Character
var enemies: Array = []


func after_each() -> void:
	if combat != null and is_instance_valid(combat):
		combat.main = null
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


func _setup_fixture(enemy_count := 5) -> void:
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
		# Adjacent to the fighter so ordinary attacks and Cleave targets are legal;
		# five rows still overflow the 96 px target list.
		cells.append([Vector2i(2, 4), Vector2i(1, 3), Vector2i(1, 5), Vector2i(2, 3), Vector2i(2, 5)][i])
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	e = Encounter.new()
	e.setup(
		[actor],
		enemies,
		BattleMap.from_rows(OPEN_ROWS, "focus_fixture"),
		rng,
		[ACTOR_CELL],
		cells,
		content.spells,
		"Focus fixture"
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


func _force_turn(ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


## The inner target scroller, found structurally so the test compiles before the
## implementation stores it as a member.
func _target_scroll() -> ScrollContainer:
	return combat.target_box.get_parent() as ScrollContainer


func _sidebar_rect() -> Rect2:
	return combat.sidebar_panel.get_global_rect()


func _inside_sidebar(control: Control) -> bool:
	return _sidebar_rect().encloses(control.get_global_rect())


## Enemy rows are the ones that carry an Attack control; the party row and the
## Ground heading do not.
func _enemy_rows() -> Array:
	var rows: Array = []
	for row in combat.target_box.get_children():
		if row is HBoxContainer and _buttons_in(row, "Attack").size() == 1:
			rows.append(row)
	return rows


func _row_button(row: Node, text: String) -> Button:
	var found := _buttons_in(row, text)
	return found[0] as Button if not found.is_empty() else null


func _buttons_in(root: Node, text: String) -> Array:
	var found: Array = []
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == text and button.is_visible_in_tree():
			found.append(button)
	return found


func _focus_key(control: Control) -> String:
	if control == null:
		return ""
	return String(control.get_meta("combat_focus_key", ""))


func _control_with_key(root: Node, key: String) -> Control:
	for node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control != null and String(control.get_meta("combat_focus_key", "")) == key:
			return control
	return null


## One press and release, like a player tapping the key.
func _push_key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		get_viewport().push_input(event)
	await wait_frames(2)


## Tabs with real key events until `control` owns the ring. Bounded so a broken
## order fails as an assertion instead of hanging the suite.
func _tab_until(control: Control, limit := 80) -> bool:
	for step in limit:
		if get_viewport().gui_get_focus_owner() == control:
			return true
		await _push_key(KEY_TAB)
	return get_viewport().gui_get_focus_owner() == control


func _seed_cleave(dropped_index := -1) -> void:
	var actor_index := int(e.entry_for(actor)["index"])
	e.pending_cleave = {
		"type": "cleave_attack",
		"actor_index": actor_index,
		"dropped_index": dropped_index,
		"weapon": e._primary_weapon(actor),
		"attack_mode": "",
		"attack_base": 0,
		"label": "",
		"off_turn": false,
	}
	combat.refresh_screen()


## Engineering assumption 1, through the production widgets: a focused indirect
## child must be revealed through BOTH nested scrollers without any key press.
## Fails at `78956f9` because neither scroller sets `follow_focus`.
func test_off_screen_target_is_revealed_through_both_nested_scrollers() -> void:
	await _setup_fixture(5)
	var inner := _target_scroll()
	var rows := _enemy_rows()
	assert_eq(rows.size(), 5, "fixture: five enemy rows exist")
	if rows.size() < 5:
		return
	var target := _row_button(rows[rows.size() - 1], "Inspect")
	assert_not_null(target, "fixture: the last enemy row has an Inspect control")
	assert_false(_inside_sidebar(target), "fixture: the last row starts outside the sidebar viewport")
	target.grab_focus()
	await wait_frames(4)
	assert_true(combat.sidebar_panel.follow_focus, "the outer sidebar follows focus")
	assert_true(inner.follow_focus, "the inner target list follows focus")
	assert_gt(combat.sidebar_panel.scroll_vertical, 0, "the outer sidebar scrolled")
	assert_gt(inner.scroll_vertical, 0, "the inner target list scrolled")
	assert_true(_inside_sidebar(target), "the focused row is inside the visible sidebar")
	assert_eq(get_viewport().gui_get_focus_owner(), target, "focus stayed on the row")


## Engineering assumption 2: real Tab traversal reaches the off-screen row and
## Enter activates the same path a click uses. No helper moves the focus or
## activates the control.
func test_tab_reveals_off_screen_attack_and_enter_activates_it() -> void:
	await _setup_fixture(5)
	var rows := _enemy_rows()
	assert_eq(rows.size(), 5, "fixture: five enemy rows exist")
	if rows.size() < 5:
		return
	var target := _row_button(rows[rows.size() - 1], "Attack")
	assert_not_null(target, "fixture: the last enemy row has an Attack control")
	assert_false(target.disabled, "fixture: the standard action is free")
	assert_false(_inside_sidebar(target), "fixture: the last Attack starts outside the sidebar viewport")
	var move := _buttons_in(combat.button_box, "Move")[0] as Button
	move.grab_focus()
	await wait_frames(1)
	var reached := await _tab_until(target)
	assert_true(reached, "Tab reached the off-screen Attack control")
	assert_true(_inside_sidebar(target), "the row was revealed before activation")
	var lines := e.log_lines.size()
	await _push_key(KEY_ENTER)
	await wait_frames(6)
	assert_true(bool(e.turn_state["standard_used"]), "Enter spent the standard action")
	assert_true(
		"\n".join(e.log_lines.slice(lines)).contains("attacks"),
		"Enter resolved the attack through the ordinary path",
	)


## A refresh with no visible change must not destroy the focused control or move
## either scroller. Fails at `78956f9` because every refresh frees the rows.
func test_refresh_keeps_the_same_focused_control_and_scroll_offsets() -> void:
	await _setup_fixture(5)
	var rows := _enemy_rows()
	var target := _row_button(rows[rows.size() - 1], "Inspect")
	target.grab_focus()
	await wait_frames(4)
	var inner := _target_scroll()
	var outer_offset := combat.sidebar_panel.scroll_vertical
	var inner_offset := inner.scroll_vertical
	combat.refresh_screen()
	await wait_frames(4)
	assert_true(is_instance_valid(target), "the row was not rebuilt")
	assert_eq(get_viewport().gui_get_focus_owner(), target, "the same control still owns focus")
	assert_eq(combat.sidebar_panel.scroll_vertical, outer_offset, "the outer offset did not move")
	assert_eq(inner.scroll_vertical, inner_offset, "the inner offset did not move")


## A disabled flag that changes with no HP change must still rebuild the row, and
## the focused control must survive as the rebuilt instance. A signature that
## hashed only labels and HP would leave a stale enabled Attack here.
func test_spent_action_rebuilds_rows_and_restores_focus_by_key() -> void:
	await _setup_fixture(5)
	var rows := _enemy_rows()
	var target := _row_button(rows[rows.size() - 1], "Inspect")
	target.grab_focus()
	await wait_frames(4)
	var key := _focus_key(target)
	assert_true(key.begins_with("target:") and key.ends_with(":inspect"), "fixture: the row carries a stable focus key")
	var instance := target.get_instance_id()
	e.turn_state["standard_used"] = true
	combat.refresh_screen()
	await wait_frames(5)
	var rebuilt := _control_with_key(combat.target_box, key) as Button
	assert_not_null(rebuilt, "the row was rebuilt and found by its key")
	if rebuilt == null:
		return
	assert_ne(rebuilt.get_instance_id(), instance, "the changed flag rebuilt the row")
	var rebuilt_attack := _row_button(rebuilt.get_parent(), "Attack")
	assert_not_null(rebuilt_attack, "the rebuilt row still offers Attack")
	assert_true(rebuilt_attack != null and rebuilt_attack.disabled, "Attack is disabled once the standard action is spent")
	assert_eq(get_viewport().gui_get_focus_owner(), rebuilt, "focus followed the key to the new control")


## A decision arriving must not take the ring from a still-enabled owner; it only
## has to be reachable by Tab.
func test_pending_decision_leaves_an_enabled_target_owner_alone() -> void:
	await _setup_fixture(5)
	var rows := _enemy_rows()
	var owner_button := _row_button(rows[rows.size() - 1], "Inspect")
	owner_button.grab_focus()
	await wait_frames(4)
	var key := _focus_key(owner_button)
	_seed_cleave()
	await wait_frames(5)
	assert_eq(_focus_key(get_viewport().gui_get_focus_owner() as Control), key, "focus stayed on the Inspect control")
	var decision := combat.decision_box.find_children("*", "Button", true, false)
	assert_gt(decision.size(), 1, "fixture: the decision offers choices plus decline")
	var first := decision[0] as Button
	var reached := await _tab_until(first, 140)
	assert_true(reached, "the decision is reachable by Tab from the kept owner")
	assert_true(_inside_sidebar(first), "the decision control is revealed when focused")


## With the grid owning the keyboard there is no valid sidebar owner left: the
## grid must release and the first decision control must take the ring.
func test_pending_decision_from_active_grid_seats_first_decision_control() -> void:
	await _setup_fixture(5)
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await wait_frames(2)
	assert_true(combat.view.keyboard_cursor_active, "fixture: the grid owns the keyboard")
	_seed_cleave()
	await wait_frames(5)
	assert_false(combat.view.keyboard_cursor_active, "the grid released the keyboard")
	var choices := combat.decision_box.find_children("*", "Button", true, false)
	assert_gt(choices.size(), 0, "fixture: the decision has controls")
	if choices.is_empty():
		return
	var first := choices[0] as Button
	assert_eq(get_viewport().gui_get_focus_owner(), first, "the first decision control took the ring")
	assert_true(_inside_sidebar(first), "the seated decision control is revealed")


## Resolving the decision that owns the ring returns focus to an action control,
## never to the grid, and leaves only the ordinary sidebar reachable.
func test_resolution_returns_focus_to_an_action_control() -> void:
	await _setup_fixture(5)
	_seed_cleave()
	await wait_frames(4)
	var decline := _buttons_in(combat.decision_box, "Decline extra attack")
	assert_eq(decline.size(), 1, "fixture: Cleave offers Decline")
	if decline.is_empty():
		return
	var button: Button = decline[0]
	button.grab_focus()
	await wait_frames(2)
	await _push_key(KEY_ENTER)
	await wait_frames(8)
	assert_false(e.has_pending_decision(), "Enter resolved the pending decision")
	var owner := get_viewport().gui_get_focus_owner()
	assert_true(owner is Button, "focus returned to a button")
	assert_true(owner != null and combat.button_box.is_ancestor_of(owner), "focus returned to the action controls")
	assert_false(combat.view.keyboard_cursor_active, "focus did not return to the grid")


## Guards: a modal and an off-turn refresh neither seat a decision control nor
## move the current owner.
func test_modal_and_off_turn_guards_leave_focus_alone() -> void:
	await _setup_fixture(5)
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	var modal_control := Control.new()
	main.add_child(modal_control)
	main.set("modal", modal_control)
	combat.main = main
	var end_turn := _buttons_in(combat.button_box, "End turn")[0] as Button
	end_turn.grab_focus()
	await wait_frames(2)
	_seed_cleave()
	await wait_frames(4)
	assert_eq(get_viewport().gui_get_focus_owner(), end_turn, "an open modal leaves the owner alone")
	combat.main = null
	main.free()
	e.pending_cleave = {}
	_force_turn(enemies[0])
	combat.refresh_screen()
	await wait_frames(2)
	var inspect := _row_button(_enemy_rows()[0], "Inspect")
	inspect.grab_focus()
	await wait_frames(2)
	combat.refresh_screen()
	await wait_frames(4)
	assert_eq(get_viewport().gui_get_focus_owner(), inspect, "an off-turn refresh keeps the owner")


## The batch adds no control of any kind: the action grid keeps its 19 buttons, and
## each rebuilt subtree keeps exactly the buttons it already had. The 32 action
## control layout number for the demo fixture is checked by `--layout-probe` at both
## scales, not reconstructed here.
func test_batch_adds_no_control() -> void:
	await _setup_fixture(5)
	assert_eq(combat.button_box.get_child_count(), 19, "the action grid keeps its 19 buttons")
	var rows := _enemy_rows()
	assert_eq(rows.size(), 5, "five enemy rows")
	for row in rows:
		assert_eq(_buttons_in(row, "Inspect").size(), 1, "one Inspect per enemy row")
		assert_eq(_buttons_in(row, "Attack").size(), 1, "one Attack per enemy row")
	_seed_cleave()
	await wait_frames(4)
	var decisions := combat.decision_box.find_children("*", "Button", true, false)
	assert_eq(decisions.size(), 6, "five Cleave targets plus Decline, no extra control")
