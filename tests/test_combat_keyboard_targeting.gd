extends GutTest

## Keyboard battle-grid targeting (roadmap candidate 1 after batch 8b-1).
##
## This pins the input contract only; combat rules, range/line-of-sight/occupancy
## validation and the 32 action controls stay where they were. Every activation
## below goes through the same CombatScreen._on_cell_clicked path a mouse click
## uses, and every key here is pushed through the viewport, not a cursor helper.
##
## Split between fixture setup and behaviour under test:
## - fixture: an open 9x7 map, the fighter at (2,3), one zombie at (3,3), and the
##   initiative pointer forced onto the fighter (the engine's own _begin_turn).
## - behaviour: arrows, Enter/Space, Escape and focus are driven as real events.

const OPEN_ROWS := [
	"#########",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#########",
]
const ACTOR_CELL := Vector2i(2, 3)
const ENEMY_CELL := Vector2i(3, 3)
const EMPTY_CELL := Vector2i(2, 4)

var combat: CombatScreen
var e: Encounter
var actor: Character
var enemy: Character


func after_each() -> void:
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


func _force_turn(ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _setup_fixture() -> void:
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")
	var content = Game.content
	actor = Character.from_content(content.get_character("kaelen"), content.items)
	actor.hp = actor.max_hp
	enemy = Character.from_content(content.get_monster("zombie"), content.items)
	enemy.hp = enemy.max_hp
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	e = Encounter.new()
	e.setup(
		[actor],
		[enemy],
		BattleMap.from_rows(OPEN_ROWS, "keyboard_grid"),
		rng,
		[ACTOR_CELL],
		[ENEMY_CELL],
		content.spells,
		"Keyboard grid"
	)
	e.begin()
	Game.party = [actor]
	Game.encounter = e
	Game.mode = "combat"
	Game.last_ui_message = ""
	_force_turn(actor)
	combat = CombatScreen.new()
	add_child_autofree(combat)
	# GUT's test node is not a sized Control: without an explicit frame the screen
	# lays out a few pixels wide and the grid has no clickable cells. This is the
	# documented 1280x720 minimum client, not a combat rule.
	combat.set_anchors_preset(Control.PRESET_TOP_LEFT)
	combat.position = Vector2.ZERO
	combat.size = Vector2(1280, 720)
	await wait_frames(4)


func _action_button(text: String) -> Button:
	for child in combat.button_box.get_children():
		var button := child as Button
		if button != null and button.text == text:
			return button
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


## A held key repeats; Godot marks the repeats with echo.
func _push_echo(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = true
	get_viewport().push_input(event)
	await wait_frames(2)


func _click_cell(cell: Vector2i) -> void:
	var view := combat.view
	var at: Vector2 = (
		view.get_global_rect().position
		+ view.origin
		+ Vector2(cell.x + 0.5, cell.y + 0.5) * float(view.cell_size)
	)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	get_viewport().push_input(motion)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		get_viewport().push_input(click)
	await wait_frames(3)


func _new_log(from: int) -> String:
	return "\n".join(e.log_lines.slice(from))


## An action button activated by Enter must only open its mode. The same release
## that pressed the button would otherwise reach the newly focused grid and
## confirm the cursor's cell a second time.
func test_action_button_key_activation_does_not_also_confirm_a_target() -> void:
	await _setup_fixture()
	var attack := _action_button("Attack")
	assert_not_null(attack, "the Attack control exists")
	attack.grab_focus()
	await wait_frames(1)
	var before := e.log_lines.size()
	await _push_key(KEY_ENTER)
	assert_eq(combat.mode, "attack", "the focused Attack button opened its mode")
	assert_true(combat.view.has_focus(), "the battle grid took the keyboard for the mode")
	assert_false(bool(e.turn_state["standard_used"]), "no action was spent by the activating keypress")
	assert_eq(e.log_lines.size(), before, "the same keypress produced no combat line")
	assert_eq(combat.view.keyboard_cursor, ACTOR_CELL, "the cursor starts on the active creature")


func test_arrows_move_a_bounded_cursor() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await wait_frames(2)
	assert_eq(combat.view.keyboard_cursor, ACTOR_CELL, "the mode starts on the active creature")
	await _push_key(KEY_RIGHT)
	assert_eq(combat.view.keyboard_cursor, ENEMY_CELL, "right moves one cell")
	for i in 10:
		await _push_key(KEY_LEFT)
	assert_eq(combat.view.keyboard_cursor, Vector2i(0, 3), "the cursor stops at the west edge")
	for i in 10:
		await _push_key(KEY_UP)
	assert_eq(combat.view.keyboard_cursor, Vector2i(0, 0), "the cursor stops at the north edge")
	for i in 10:
		await _push_key(KEY_DOWN)
	assert_eq(combat.view.keyboard_cursor, Vector2i(0, 6), "the cursor stops at the south edge")


func test_a_mode_change_reseats_the_cursor_on_the_active_creature() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await _push_key(KEY_RIGHT)
	assert_eq(combat.view.keyboard_cursor, ENEMY_CELL)
	combat._set_mode("trip", "Click an enemy within reach to Trip.")
	await wait_frames(2)
	assert_eq(combat.view.keyboard_cursor, ACTOR_CELL, "a new mode starts from the actor again")
	assert_eq(combat.view.keyboard_cursor, Vector2i(e.active_entry()["cell"]), "the start is the live active cell")


func test_an_actor_change_releases_the_grid_and_focus() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await wait_frames(1)
	assert_true(combat.view.keyboard_cursor_active, "the grid owns the keyboard on the player's turn")
	_force_turn(enemy)
	combat.refresh_screen()
	await wait_frames(2)
	assert_false(combat.view.keyboard_cursor_active, "an enemy turn takes the grid keyboard away")
	assert_false(combat.view.has_focus(), "focus left the grid for the sidebar")
	await _push_key(KEY_RIGHT)
	assert_eq(combat.view.keyboard_cursor, Vector2i(-1, -1), "arrows do not move a released cursor")


func test_escape_cancels_targeting_without_spending_an_action() -> void:
	await _setup_fixture()
	var attack := _action_button("Attack")
	attack.grab_focus()
	await wait_frames(1)
	await _push_key(KEY_ENTER)
	await _push_key(KEY_RIGHT)
	combat.pending_action = {"type": "item", "id": "potion_of_cure_light_wounds"}
	await _push_key(KEY_ESCAPE)
	assert_eq(combat.mode, "move", "cancelling returns the resting mode")
	assert_true(combat.pending_action.is_empty(), "a selected spell or item is dropped")
	assert_false(bool(e.turn_state["standard_used"]), "cancelling spends no standard action")
	assert_false(bool(e.turn_state["move_used"]), "cancelling spends no move action")
	assert_false(combat.view.keyboard_cursor_active, "the cursor is gone")
	assert_false(combat.view.has_focus(), "the grid no longer owns the keyboard")
	assert_true(get_viewport().gui_get_focus_owner() is Button, "focus returned to a sidebar control")
	assert_eq(Game.last_ui_message, "Targeting cancelled.", "the cancellation is reported")


func test_an_invalid_target_is_refused_by_the_click_path_and_keeps_the_cursor() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await _push_key(KEY_DOWN)
	assert_eq(combat.view.keyboard_cursor, EMPTY_CELL)
	await _push_key(KEY_ENTER)
	assert_eq(Game.last_ui_message, "Choose an enemy to attack.", "the existing refusal message is used")
	assert_false(bool(e.turn_state["standard_used"]), "a refused target spends nothing")
	assert_eq(e.cell_of(actor), ACTOR_CELL, "the actor did not move")
	assert_eq(combat.view.keyboard_cursor, EMPTY_CELL, "the cursor stays where the player aimed")


func test_enter_activates_the_target_once_through_the_click_path() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await _push_key(KEY_RIGHT)
	var before := e.log_lines.size()
	await _push_key(KEY_ENTER)
	assert_true(bool(e.turn_state["standard_used"]), "the attack spent the standard action")
	var attack_log := _new_log(before)
	assert_true(attack_log.contains("attacks"), "the ordinary attack is declared: " + attack_log)
	assert_false(attack_log.contains("You cannot attack that target."), "the target was legal")
	var after := e.log_lines.size()
	await _push_key(KEY_ENTER)
	assert_false(_new_log(after).contains("attacks"), "a second confirmation starts no second attack")
	assert_true(bool(e.turn_state["standard_used"]), "the standard action stays spent")


func test_key_repeat_does_not_repeat_an_activation() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await _push_key(KEY_RIGHT)
	var before := e.log_lines.size()
	await _push_echo(KEY_ENTER)
	assert_false(bool(e.turn_state["standard_used"]), "an echoed Enter does not confirm the target")
	assert_eq(e.log_lines.size(), before, "an echoed Enter resolves nothing")


func test_keyboard_movement_uses_the_ordinary_move_path() -> void:
	await _setup_fixture()
	combat._set_mode("move", "Click an empty square within your movement.")
	await _push_key(KEY_LEFT)
	assert_eq(combat.view.keyboard_cursor, Vector2i(1, 3), "the cursor moved one cell west")
	await _push_key(KEY_ENTER)
	assert_eq(e.cell_of(actor), Vector2i(1, 3), "Enter moved the active creature through combat_move")
	assert_eq(combat.view.keyboard_cursor, e.cell_of(actor), "the cursor follows the moved creature")
	assert_true(bool(e.turn_state["move_used"]), "the ordinary move cost is paid")


func test_an_open_modal_deactivates_the_grid_and_escape_still_closes_it() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await wait_frames(1)
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	main.set("modal", Control.new())
	combat.main = main
	assert_false(combat._grid_keyboard_allowed(), "an open modal forbids grid keyboard input")
	await _push_key(KEY_ESCAPE)
	assert_eq(combat.mode, "attack", "Escape is left to the modal, not used to cancel targeting")
	combat.refresh_screen()
	await wait_frames(2)
	assert_false(combat.view.keyboard_cursor_active, "the modal refresh releases the grid")
	await _push_key(KEY_RIGHT)
	assert_eq(combat.view.keyboard_cursor, Vector2i(-1, -1), "arrows do not move a released cursor")
	combat.main = null
	main.free()


func test_a_finished_encounter_releases_the_grid() -> void:
	await _setup_fixture()
	combat._set_mode("attack", "Click an enemy within reach or range.")
	await wait_frames(1)
	e.finish("victory")
	combat.refresh_screen()
	await wait_frames(2)
	assert_false(combat.view.keyboard_cursor_active, "a finished encounter owns no grid keyboard")
	await _push_key(KEY_RIGHT)
	assert_eq(combat.view.keyboard_cursor, Vector2i(-1, -1), "arrows are ignored after the fight")


func test_a_mouse_click_repositions_the_cursor_so_enter_is_never_stale() -> void:
	await _setup_fixture()
	combat._set_mode("move", "Click an empty square within your movement.")
	await _push_key(KEY_RIGHT)
	assert_eq(combat.view.keyboard_cursor, ENEMY_CELL)
	await _click_cell(Vector2i(2, 2))
	assert_eq(e.cell_of(actor), Vector2i(2, 2), "the mouse move resolved as before")
	assert_eq(combat.view.keyboard_cursor, e.cell_of(actor), "the cursor follows the last pointer target")
	assert_ne(combat.view.keyboard_cursor, ENEMY_CELL, "no stale keyboard cell survives the click")
