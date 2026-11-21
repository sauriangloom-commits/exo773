extends GutTest

## Dialogue keyboard focus: Tab and Shift+Tab walk the choices in content order,
## unavailable rows are skipped, and the body scroller reveals the new owner. The
## gated silence epilogue row is the far case: at 160 % it sits below the fold.

const ASHWICK := "ashwick_ferry"
const PARTY := ["kaelen", "sera", "aldric", "ysolde"]
const EPILOGUE := "Tell me what the silence means for the ferry."

var main: Control = null
var original_scale := 1.0


func before_each() -> void:
	original_scale = float(Game.settings.get("text_scale", 1.0))
	Game.settings["text_scale"] = 1.6
	Game.load_campaign(ASHWICK)
	main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(3)


func after_each() -> void:
	if Game.dialogue != null:
		Game.dialogue.finish_now()
	Game.settings["text_scale"] = original_scale
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")
	main = null


func _open_silence() -> DialoguePanel:
	Game.new_game(PARTY, 4242)
	Game.flags["maela_decision"] = true
	Game.flags["maela_mercy"] = true
	Game.flags["drowned_cleared"] = true
	Game.flags["bell_resolved"] = true
	Game.flags["bell_silenced"] = true
	var opened := Game.start_dialogue("maela_vey")
	assert_true(bool(opened.get("ok", false)), String(opened.get("message", "")))
	await wait_frames(4)
	var screen := main.get("current_screen") as ExplorationScreen
	assert_true(screen != null, "exploration owns the conversation")
	var panel: DialoguePanel = screen.dialogue_panel
	assert_true(panel != null, "the dialogue panel is built")
	await wait_frames(2)
	return panel


func _epilogue_button(panel: DialoguePanel) -> Button:
	for button in panel.choice_buttons:
		if is_instance_valid(button) and button.text.begins_with(EPILOGUE):
			return button
	return null


func _visible_in_body(panel: DialoguePanel, control: Control) -> bool:
	if control == null or panel.scroll == null:
		return false
	var body := panel.scroll.get_global_rect()
	var rect := control.get_global_rect()
	return rect.position.y >= body.position.y - 1.0 and rect.end.y <= body.end.y + 1.0


func _send_key(code: int, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = true
	main.get_viewport().push_input(event)


func _press_enter() -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = pressed
		main.get_viewport().push_input(event)
		await wait_frames(1)


func _tab_until(panel: DialoguePanel, target: Button) -> bool:
	for i in panel.choice_buttons.size() + 2:
		_send_key(KEY_TAB)
		await wait_frames(2)
		if panel.get_viewport().gui_get_focus_owner() == target:
			return true
	return false


func test_choices_keep_content_order_and_availability() -> void:
	var panel: DialoguePanel = await _open_silence()
	var choices := Game.dialogue_choices()
	assert_eq(panel.choice_buttons.size(), choices.size(), "one button per choice")
	assert_eq(choices.size(), 13, "the root page is the overflowing one")
	for i in choices.size():
		var entry: Dictionary = choices[i]
		var button := panel.choice_buttons[i]
		assert_true(
			button.text.begins_with(String(entry["text"])),
			"row %d keeps its content order" % i,
		)
		assert_eq(
			button.disabled,
			not bool(entry.get("available", true)),
			"row %d keeps its availability" % i,
		)
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_false(epilogue.disabled, "bell_resolved + bell_silenced unlock the row")
	var unavailable := 0
	for button in panel.choice_buttons:
		if button.disabled:
			unavailable += 1
	assert_gt(unavailable, 0, "gated rows stay visible as unavailable")


func test_tab_reveals_the_gated_silence_epilogue_row() -> void:
	var panel: DialoguePanel = await _open_silence()
	assert_true(panel.scroll.follow_focus, "the conversation body follows focus")
	var bar := panel.scroll.get_v_scroll_bar()
	assert_gt(bar.max_value, panel.scroll.size.y, "the choice list overflows the body")
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_true(await _tab_until(panel, epilogue), "Tab reaches the epilogue row")
	assert_gt(panel.scroll.scroll_vertical, 0, "the body scrolled to the focused row")
	assert_true(_visible_in_body(panel, epilogue), "the row is inside the visible body")


func test_shift_tab_walks_back_and_stays_visible() -> void:
	var panel: DialoguePanel = await _open_silence()
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_true(await _tab_until(panel, epilogue), "Tab reaches the epilogue row")
	var reached := panel.scroll.scroll_vertical
	_send_key(KEY_TAB, true)
	await wait_frames(2)
	var owner_control := panel.get_viewport().gui_get_focus_owner() as Control
	assert_true(owner_control != null, "Shift+Tab keeps a focus owner")
	assert_true(owner_control != epilogue, "Shift+Tab moves off the last choice")
	assert_true(_visible_in_body(panel, owner_control), "the previous choice is visible")
	assert_lte(panel.scroll.scroll_vertical, reached, "walking back does not scroll down")


func test_enter_activates_the_focused_epilogue_row() -> void:
	var panel: DialoguePanel = await _open_silence()
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_true(await _tab_until(panel, epilogue), "Tab reaches the epilogue row")
	await _press_enter()
	await wait_frames(4)
	assert_eq(Game.dialogue.node_id, "epilogue_silent", "Enter opens the silence epilogue")
	assert_true(Game.dialogue.text().contains("The token is broken"), "the silence text is shown")
