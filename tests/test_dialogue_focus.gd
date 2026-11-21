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


func test_shift_tab_walks_back_through_earlier_choices() -> void:
	var panel: DialoguePanel = await _open_silence()
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_true(await _tab_until(panel, epilogue), "Tab reaches the epilogue row")
	var available: Array[Button] = []
	for button in panel.choice_buttons:
		if not button.disabled:
			available.append(button)
	var index := available.find(epilogue)
	assert_gt(index, 0, "earlier available choices exist above the epilogue")
	for step in range(1, index + 1):
		_send_key(KEY_TAB, true)
		await wait_frames(2)
		var owner_control := panel.get_viewport().gui_get_focus_owner()
		assert_eq(owner_control, available[index - step], "Shift+Tab walks back in content order")
		assert_true(_visible_in_body(panel, owner_control), "the earlier choice is visible")
	_send_key(KEY_TAB, true)
	await wait_frames(2)
	assert_eq(
		panel.get_viewport().gui_get_focus_owner(),
		available[available.size() - 1],
		"Shift+Tab wraps from the first choice to the last",
	)


func test_page_keys_scroll_without_moving_focus() -> void:
	var panel: DialoguePanel = await _open_silence()
	_send_key(KEY_TAB)
	await wait_frames(2)
	var owner_control := panel.get_viewport().gui_get_focus_owner()
	assert_not_null(owner_control, "a choice holds focus")
	var bar := panel.scroll.get_v_scroll_bar()
	var travel := maxi(0, int(bar.max_value - bar.page))
	assert_gt(travel, 0, "the body overflows and can travel")
	_send_key(KEY_PAGEDOWN)
	await wait_frames(2)
	assert_gt(panel.scroll.scroll_vertical, 0, "PageDown moves the body down")
	assert_eq(
		panel.get_viewport().gui_get_focus_owner(),
		owner_control,
		"the focus ring stays on the same choice",
	)
	assert_lte(
		absi(panel.scroll.scroll_vertical - int(round(bar.page * 0.9))),
		2,
		"one page is 90 % of the visible height",
	)
	for i in 8:
		_send_key(KEY_PAGEDOWN)
	await wait_frames(2)
	assert_eq(panel.scroll.scroll_vertical, travel, "PageDown clamps at the bottom")
	assert_eq(panel.get_viewport().gui_get_focus_owner(), owner_control, "focus never moves while paging")
	for i in 8:
		_send_key(KEY_PAGEUP)
	await wait_frames(2)
	assert_eq(panel.scroll.scroll_vertical, 0, "PageUp clamps at the top")


func test_page_scroll_keeps_tab_and_enter_working() -> void:
	var panel: DialoguePanel = await _open_silence()
	_send_key(KEY_PAGEDOWN)
	_send_key(KEY_PAGEDOWN)
	await wait_frames(2)
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_true(await _tab_until(panel, epilogue), "Tab still reaches the epilogue after paging")
	assert_true(_visible_in_body(panel, epilogue), "the row is revealed again")
	await _press_enter()
	await wait_frames(4)
	assert_eq(Game.dialogue.node_id, "epilogue_silent", "Enter still activates the row")


func test_manual_scroll_persists_until_focus_moves() -> void:
	var panel: DialoguePanel = await _open_silence()
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_true(await _tab_until(panel, epilogue), "Tab reaches the epilogue row")
	panel.scroll.scroll_vertical = 0
	await wait_frames(4)
	assert_eq(panel.scroll.scroll_vertical, 0, "follow_focus does not undo a manual offset")
	_send_key(KEY_TAB)
	await wait_frames(2)
	assert_gt(panel.scroll.scroll_vertical, 0, "the next focus change reveals its owner")


func test_modal_page_scroll_keeps_priority() -> void:
	var panel: DialoguePanel = await _open_silence()
	var before := panel.scroll.scroll_vertical
	main.call("open_modal", "QA tall", func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(600, 0)
		for i in 60:
			var label := Label.new()
			label.text = "Line %d of the QA body." % i
			box.add_child(label)
		return box
	, 660, 380)
	await wait_frames(3)
	_send_key(KEY_PAGEDOWN)
	await wait_frames(2)
	var body: ScrollContainer = main.get("modal_scroll")
	assert_not_null(body, "the modal exposes its scrolling body")
	assert_gt(body.scroll_vertical, 0, "PageDown scrolls the modal body")
	assert_eq(panel.scroll.scroll_vertical, before, "the conversation body did not scroll")


func test_rebind_capture_consumes_the_page_key() -> void:
	var panel: DialoguePanel = await _open_silence()
	main.set("awaiting_rebind", "not_a_real_action")
	_send_key(KEY_PAGEDOWN)
	await wait_frames(2)
	assert_eq(String(main.get("awaiting_rebind")), "", "the capture consumed the page key")
	assert_eq(panel.scroll.scroll_vertical, 0, "the body did not scroll while capturing a rebind")
