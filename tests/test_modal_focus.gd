extends GutTest

## Shared modal focus rules: Tab and Shift+Tab stay inside the open modal, the
## world behind it cannot be acted on, and closing returns focus to the opener
## (or a usable fallback). These cover the shared path every modal uses.

var main: Control = null


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)
	main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(3)


func after_each() -> void:
	if main != null:
		main.queue_free()
		main = null
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


func _focus_owner() -> Control:
	return main.get_viewport().gui_get_focus_owner() as Control


func _modal() -> Control:
	return main.get("modal") as Control


func _send_key(code: int, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = true
	main.get_viewport().push_input(event)


func _opener(text := "QA opener") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 36)
	main.add_child(button)
	await wait_frames(1)
	button.grab_focus()
	return button


func _open_modal() -> void:
	main.call("open_modal", "QA Focus", func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(600, 320)
		for index in 3:
			var button := Button.new()
			button.text = "QA button %d" % index
			button.custom_minimum_size = Vector2(0, 40)
			box.add_child(button)
		return box
	, 660, 380)
	await wait_frames(2)


func _outside_controls() -> Array[Control]:
	var out: Array[Control] = []
	var modal := _modal()
	for node in main.find_children("*", "Control", true, false):
		var control := node as Control
		if control.focus_mode == Control.FOCUS_NONE:
			continue
		if not control.is_visible_in_tree():
			continue
		if modal != null and modal.is_ancestor_of(control):
			continue
		out.append(control)
	return out


func test_opening_a_modal_focuses_inside_it() -> void:
	await _open_modal()
	var owner := _focus_owner()
	assert_not_null(owner, "the modal takes focus")
	assert_true(_modal().is_ancestor_of(owner), "focus starts inside the modal")


func test_tab_and_shift_tab_never_leave_the_modal() -> void:
	await _open_modal()
	var outside := _outside_controls()
	assert_gt(outside.size(), 0, "the screen behind has focusable controls")
	for step in 6:
		_send_key(KEY_TAB)
		await wait_frames(1)
		var owner := _focus_owner()
		assert_not_null(owner, "Tab stop %d has focus" % step)
		assert_true(_modal().is_ancestor_of(owner), "Tab stop %d stays inside the modal" % step)
		assert_false(outside.has(owner), "Tab stop %d is not a background control" % step)
	for step in 4:
		_send_key(KEY_TAB, true)
		await wait_frames(1)
		assert_true(_modal().is_ancestor_of(_focus_owner()), "Shift+Tab stop %d stays inside" % step)


## The trap itself is asserted by calling the handler directly; going through
## the viewport would also run Godot's own traversal in the same frame.
func test_tab_wraps_from_the_last_control_to_the_first() -> void:
	await _open_modal()
	var focusables: Array = main.call("_modal_focusables")
	assert_gt(focusables.size(), 1, "the modal has more than one stop")
	focusables[focusables.size() - 1].grab_focus()
	main.call("_cycle_modal_focus", 1)
	assert_eq(_focus_owner(), focusables[0], "Tab on the last stop wraps to the first")


func test_a_shift_tab_event_moves_focus_backwards() -> void:
	await _open_modal()
	var focusables: Array = main.call("_modal_focusables")
	focusables[2].grab_focus()
	var event := InputEventKey.new()
	event.keycode = KEY_TAB
	event.physical_keycode = KEY_TAB
	event.shift_pressed = true
	event.pressed = true
	main._input(event)
	assert_eq(_focus_owner(), focusables[1], "a Shift+Tab event moves focus backwards")


func test_shift_tab_wraps_from_the_first_control_to_the_last() -> void:
	await _open_modal()
	var focusables: Array = main.call("_modal_focusables")
	focusables[0].grab_focus()
	main.call("_cycle_modal_focus", -1)
	assert_eq(_focus_owner(), focusables[focusables.size() - 1], "Shift+Tab on the first stop wraps to the last")


func test_the_reported_tab_twice_then_enter_sequence_acts_on_nothing() -> void:
	await _open_modal()
	var facing := Game.facing
	var position := Game.position
	_send_key(KEY_TAB)
	_send_key(KEY_TAB)
	await wait_frames(1)
	assert_true(_modal().is_ancestor_of(_focus_owner()), "two Tabs keep focus in the modal")
	_send_key(KEY_ENTER)
	await wait_frames(2)
	assert_eq(Game.facing, facing, "Enter did not turn the party behind the modal")
	assert_eq(Game.position, position, "Enter did not move the party behind the modal")
	assert_not_null(_modal(), "the modal is still open")


func test_world_keys_do_not_move_while_a_modal_is_open() -> void:
	await _open_modal()
	var position := Game.position
	var facing := Game.facing
	_send_key(KEY_W)
	_send_key(KEY_Q)
	await wait_frames(2)
	assert_eq(Game.position, position, "W did not move the party")
	assert_eq(Game.facing, facing, "Q did not turn the party")


func test_closing_restores_focus_to_the_opener() -> void:
	var opener := await _opener()
	assert_eq(_focus_owner(), opener, "the opener holds focus before opening")
	await _open_modal()
	main.call("close_modal")
	await wait_frames(2)
	assert_eq(_focus_owner(), opener, "focus returns to the control that opened the modal")
	opener.queue_free()


func test_closing_falls_back_when_the_opener_is_gone() -> void:
	var opener := await _opener()
	await _open_modal()
	main.remove_child(opener)
	opener.queue_free()
	main.call("close_modal")
	await wait_frames(2)
	var owner := _focus_owner()
	assert_not_null(owner, "a fallback control takes focus")
	assert_true(owner.is_inside_tree(), "the fallback is live")
	assert_not_null(main.current_screen)
	assert_true(main.current_screen.is_ancestor_of(owner), "focus lands on the current screen")


func test_refresh_keeps_the_original_opener() -> void:
	var opener := await _opener()
	await _open_modal()
	main.call("refresh_modal")
	await wait_frames(2)
	assert_not_null(_modal(), "the refreshed modal is open")
	main.call("close_modal")
	await wait_frames(2)
	assert_eq(_focus_owner(), opener, "focus returns to the opener, not a freed modal button")
	opener.queue_free()


func test_escape_closes_the_modal_and_restores_focus() -> void:
	var opener := await _opener()
	await _open_modal()
	_send_key(KEY_ESCAPE)
	await wait_frames(2)
	assert_null(_modal(), "Escape closed the modal")
	assert_eq(_focus_owner(), opener, "Escape returns focus to the opener")
	opener.queue_free()




func test_rebind_capture_keeps_priority_over_the_focus_trap() -> void:
	await _open_modal()
	main.set("awaiting_rebind", "not_a_real_action")
	_send_key(KEY_TAB)
	await wait_frames(1)
	assert_eq(String(main.get("awaiting_rebind")), "", "the capture consumed the key instead of Tab moving focus")
	assert_not_null(_modal(), "the modal is still open after the capture")
