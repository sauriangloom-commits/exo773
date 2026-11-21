extends GutTest

## Dialogue keyboard focus: Tab and Shift+Tab walk the choices in content order,
## unavailable rows are skipped, and the body scroller reveals the new owner. The
## gated silence epilogue row is the far case: at 160 % it sits below the fold.

const ASHWICK := "ashwick_ferry"
const PARTY := ["kaelen", "sera", "aldric", "ysolde"]
const EPILOGUE := "Tell me what the silence means for the ferry."
const HUD_SHORTCUTS := [
	[KEY_C, "open_sheet", "Party & Character Sheet"],
	[KEY_I, "open_inventory", "Inventory & Equipment"],
	[KEY_J, "open_journal", "Journal"],
]

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


func _open_silence(seed := 4242) -> DialoguePanel:
	Game.new_game(PARTY, seed)
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


func test_root_and_dim_cover_the_viewport_without_covering_the_hud() -> void:
	var panel: DialoguePanel = await _open_silence()
	var area := panel.get_viewport_rect().size
	assert_eq(panel.size, area, "the overlay root fills the viewport")
	assert_not_null(panel.dim, "the dim exists")
	assert_eq(panel.dim.size, area, "the dim fills the viewport")
	assert_eq(
		panel.dim.mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"the dim never blocks the HUD panels behind it",
	)
	assert_eq(
		panel.mouse_filter,
		Control.MOUSE_FILTER_IGNORE,
		"the overlay root never wins the mouse pick over the HUD",
	)
	var party := _find_button(main, "Party (Tab)")
	assert_not_null(party, "the read-only HUD panel button exists")
	if party != null:
		assert_lte(
			panel.panel.get_global_rect().end.x,
			party.get_global_rect().position.x,
			"the framed panel leaves the HUD column exposed",
		)


func test_arrows_cycle_only_available_choices() -> void:
	var panel: DialoguePanel = await _open_silence()
	var epilogue := _epilogue_button(panel)
	assert_true(epilogue != null, "the silence epilogue row is present")
	assert_true(await _tab_until(panel, epilogue), "Tab reaches the epilogue row")
	var available: Array[Button] = []
	for button in panel.choice_buttons:
		if not button.disabled:
			available.append(button)
	var index := available.find(epilogue)
	assert_gt(index, 0, "an earlier available choice exists")
	_send_key(KEY_UP)
	await wait_frames(2)
	assert_eq(
		panel.get_viewport().gui_get_focus_owner(),
		available[index - 1],
		"Up moves to the previous available choice",
	)
	_send_key(KEY_DOWN)
	await wait_frames(2)
	assert_eq(panel.get_viewport().gui_get_focus_owner(), epilogue, "Down moves forward again")
	_send_key(KEY_LEFT)
	await wait_frames(2)
	assert_eq(
		panel.get_viewport().gui_get_focus_owner(),
		available[index - 1],
		"Left moves back through the list",
	)
	_send_key(KEY_RIGHT)
	await wait_frames(2)
	assert_eq(panel.get_viewport().gui_get_focus_owner(), epilogue, "Right moves forward")
	_send_key(KEY_DOWN)
	await wait_frames(2)
	assert_eq(
		panel.get_viewport().gui_get_focus_owner(),
		available[available.size() - 1],
		"Down reaches the next available choice",
	)
	for i in available.size() * 2:
		_send_key(KEY_DOWN)
		await wait_frames(1)
		var owner_control := panel.get_viewport().gui_get_focus_owner()
		assert_true(panel.is_ancestor_of(owner_control), "directional focus stays in the conversation")
		assert_false((owner_control as Button).disabled, "directional focus skips unavailable rows")


func _find_button(node: Node, label: String) -> Button:
	for child in node.get_children():
		if child is Button and (child as Button).text == label:
			return child as Button
		var found := _find_button(child, label)
		if found != null:
			return found
	return null


func _find_label(root: Node, prefix: String) -> Label:
	if root is Label and String((root as Label).text).begins_with(prefix):
		return root as Label
	for child in root.get_children():
		var found := _find_label(child, prefix)
		if found != null:
			return found
	return null


func _restart_at_scale(scale: float) -> void:
	if main != null:
		main.queue_free()
		main = null
		await wait_frames(2)
	Game.settings["text_scale"] = scale
	Game.load_campaign(ASHWICK)
	main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(4)


func test_panel_clears_the_header_at_both_scales_with_long_readouts() -> void:
	for scale in [1.0, 1.6]:
		await _restart_at_scale(scale)
		var panel: DialoguePanel = await _open_silence()
		var screen: ExplorationScreen = main.get("current_screen")
		var rect := panel.panel.get_global_rect()
		# Standard readouts keep the exact panel size shipped today.
		assert_almost_eq(rect.size.x, 860.0, 0.5, "the panel keeps its width at scale %.1f" % scale)
		assert_almost_eq(rect.size.y, 600.0, 0.5, "the panel keeps its height at scale %.1f" % scale)
		assert_almost_eq(
			panel.scroll.size.y, 556.0, 1.0,
			"the body keeps its height, so no choice row is lost at scale %.1f" % scale,
		)
		# Stress the header: these readouts are wider than any real total, and at
		# 160 % they push the title onto more lines, growing the header itself.
		screen.gold_label.text = "Gold: 1234567890 gp"
		var seed_label := _find_label(main, "Seed:")
		assert_not_null(seed_label, "the seed readout exists")
		seed_label.text = "Seed: 9876543210"
		await wait_frames(4)
		var pause := _find_button(main, "Pause (Esc)")
		var gold := _find_label(main, "Gold:")
		assert_not_null(pause, "the header Pause button exists")
		assert_not_null(gold, "the gold readout exists")
		rect = panel.panel.get_global_rect()
		assert_gte(
			rect.position.y, pause.get_global_rect().end.y + 7.0,
			"the panel starts below the grown header at scale %.1f" % scale,
		)
		assert_false(
			rect.intersects(gold.get_global_rect()),
			"the gold readout is never covered at scale %.1f" % scale,
		)
		assert_false(
			rect.intersects(seed_label.get_global_rect()),
			"the seed readout is never covered at scale %.1f" % scale,
		)
		assert_false(
			rect.intersects(pause.get_global_rect()),
			"Pause is never covered at scale %.1f" % scale,
		)
		assert_lte(
			rect.end.y, panel.get_viewport_rect().size.y - 16.0,
			"the panel bottom stays inside the client at scale %.1f" % scale,
		)
		assert_lte(rect.size.y, 600.0, "the panel never grows past its shipped height")
		assert_gt(panel.scroll.size.y, 240.0, "a usable body remains at scale %.1f" % scale)
		assert_eq(panel.choice_buttons.size(), 13, "all choices remain built at scale %.1f" % scale)
		var epilogue := _epilogue_button(panel)
		assert_true(await _tab_until(panel, epilogue), "the epilogue stays reachable at scale %.1f" % scale)


func test_hud_panel_close_returns_focus_to_the_last_dialogue_control() -> void:
	var panel: DialoguePanel = await _open_silence()
	_send_key(KEY_TAB)
	await wait_frames(2)
	var expected := panel.get_viewport().gui_get_focus_owner() as Button
	assert_true(expected != null and panel.choice_buttons.has(expected), "a choice holds the ring")
	var party := _find_button(main, "Party (Tab)")
	assert_not_null(party, "the HUD panel button exists")
	party.grab_focus()
	party.pressed.emit()
	await wait_frames(3)
	assert_not_null(main.get("modal"), "the HUD panel opened over the conversation")
	main.call("close_modal")
	await wait_frames(3)
	assert_eq(
		panel.get_viewport().gui_get_focus_owner(), expected,
		"focus returns to the dialogue choice, not the HUD button",
	)
	await _press_enter()
	await wait_frames(4)
	assert_null(main.get("modal"), "Enter advances the dialogue instead of reopening the panel")


func test_hud_panel_close_after_dialogue_rebuild_falls_back_to_a_choice() -> void:
	var panel: DialoguePanel = await _open_silence()
	_send_key(KEY_TAB)
	await wait_frames(2)
	var party := _find_button(main, "Party (Tab)")
	party.grab_focus()
	party.pressed.emit()
	await wait_frames(3)
	assert_not_null(main.get("modal"), "the HUD panel opened")
	panel.refresh()
	await wait_frames(4)
	main.call("close_modal")
	await wait_frames(3)
	var owner_control := panel.get_viewport().gui_get_focus_owner() as Button
	assert_not_null(owner_control, "the rebuilt conversation takes the ring")
	assert_true(panel.choice_buttons.has(owner_control), "the fallback is a rebuilt dialogue choice")
	assert_false(owner_control.disabled, "the fallback is an available choice")


func test_exploration_panel_close_returns_to_its_opener() -> void:
	await _restart_at_scale(1.0)
	Game.new_game(PARTY, 4242)
	await wait_frames(4)
	var party := _find_button(main, "Party (Tab)")
	assert_not_null(party, "exploration exposes the Party button")
	party.grab_focus()
	party.pressed.emit()
	await wait_frames(3)
	assert_not_null(main.get("modal"), "the exploration panel opened")
	main.call("close_modal")
	await wait_frames(3)
	assert_eq(
		main.get_viewport().gui_get_focus_owner(), party,
		"exploration keeps returning focus to the opener",
	)


func test_each_hud_shortcut_opens_its_panel_with_focus_contained_and_returns_to_the_choice() -> void:
	var panel: DialoguePanel = await _open_silence()
	_send_key(KEY_TAB)
	await wait_frames(2)
	var expected := panel.get_viewport().gui_get_focus_owner() as Button
	assert_true(expected != null and panel.choice_buttons.has(expected), "a dialogue choice holds the ring")
	for shortcut in HUD_SHORTCUTS:
		var code: int = shortcut[0]
		var title: String = shortcut[2]
		_send_key(code)
		await wait_frames(4)
		var modal: Control = main.get("modal")
		assert_not_null(modal, "%s opens a panel during dialogue" % OS.get_keycode_string(code))
		assert_eq(String(main.get("modal_title")), title, "%s opens the right panel" % OS.get_keycode_string(code))
		assert_eq(Game.mode, "dialogue", "the conversation stays open behind the panel")
		var owner_control := panel.get_viewport().gui_get_focus_owner()
		assert_true(owner_control != null and modal.is_ancestor_of(owner_control), "focus starts inside the panel")
		_send_key(KEY_TAB)
		await wait_frames(2)
		owner_control = panel.get_viewport().gui_get_focus_owner()
		assert_true(owner_control != null and modal.is_ancestor_of(owner_control), "Tab stays inside the panel")
		main.call("close_modal")
		await wait_frames(3)
		assert_null(main.get("modal"), "the panel closes")
		assert_eq(
			panel.get_viewport().gui_get_focus_owner(), expected,
			"closing the %s panel returns to the prior dialogue choice" % title,
		)


func test_escape_closes_a_hud_panel_before_ending_the_conversation() -> void:
	var panel: DialoguePanel = await _open_silence()
	_send_key(KEY_TAB)
	await wait_frames(2)
	var expected := panel.get_viewport().gui_get_focus_owner() as Button
	for shortcut in HUD_SHORTCUTS:
		_send_key(int(shortcut[0]))
		await wait_frames(4)
		assert_not_null(main.get("modal"), "the panel is open before Escape")
		_send_key(KEY_ESCAPE)
		await wait_frames(3)
		assert_null(main.get("modal"), "Escape closes the panel")
		assert_eq(Game.mode, "dialogue", "Escape does not end the conversation while a panel is open")
		assert_eq(panel.get_viewport().gui_get_focus_owner(), expected, "Escape returns to the prior choice")
	_send_key(KEY_ESCAPE)
	await wait_frames(3)
	assert_ne(Game.mode, "dialogue", "Escape with no panel still ends the conversation")


func test_rebind_capture_precedes_hud_shortcuts() -> void:
	var panel: DialoguePanel = await _open_silence()
	for shortcut in HUD_SHORTCUTS:
		main.set("awaiting_rebind", "not_a_real_action")
		_send_key(int(shortcut[0]))
		await wait_frames(2)
		assert_eq(String(main.get("awaiting_rebind")), "", "the capture consumed the shortcut key")
		assert_null(main.get("modal"), "the shortcut opens no panel while capturing a rebind")
		assert_eq(Game.mode, "dialogue", "the conversation stays open during rebind capture")


func test_an_open_modal_keeps_priority_over_hud_shortcuts() -> void:
	var panel: DialoguePanel = await _open_silence()
	main.call("open_modal", "QA priority", func() -> Control:
		var box := VBoxContainer.new()
		box.add_child(ThemeBuilder.body("The open modal keeps priority.", false, 14))
		return box
	, 600, 300)
	await wait_frames(3)
	var modal: Control = main.get("modal")
	assert_not_null(modal, "the QA modal opened")
	for shortcut in HUD_SHORTCUTS:
		_send_key(int(shortcut[0]))
		await wait_frames(2)
		assert_eq(main.get("modal"), modal, "%s does not replace an open modal" % OS.get_keycode_string(int(shortcut[0])))
		assert_eq(String(main.get("modal_title")), "QA priority", "the open modal keeps its title")


func test_tab_still_cycles_dialogue_choices_with_hud_shortcuts_enabled() -> void:
	var panel: DialoguePanel = await _open_silence()
	_send_key(KEY_TAB)
	await wait_frames(2)
	var owner_control := panel.get_viewport().gui_get_focus_owner()
	assert_true(
		owner_control != null and panel.choice_buttons.has(owner_control),
		"Tab stays on the dialogue choices",
	)
	assert_ne(owner_control, _find_button(main, "Party (Tab)"), "Tab never focuses the Party button")
	assert_null(main.get("modal"), "Tab opens no HUD panel")


func test_hud_shortcuts_do_not_open_in_combat() -> void:
	Game.new_game(PARTY, 4242)
	var started := Game.start_encounter("ashwick_tack_room_dead")
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))
	await wait_frames(4)
	assert_eq(Game.mode, "combat", "the QA encounter starts")
	for shortcut in HUD_SHORTCUTS:
		_send_key(int(shortcut[0]))
		await wait_frames(2)
		assert_null(main.get("modal"), "%s opens no HUD panel in combat" % OS.get_keycode_string(int(shortcut[0])))
	assert_eq(Game.mode, "combat", "combat mode is unchanged")


func test_hud_shortcuts_do_not_open_in_the_campaign_creator() -> void:
	Game.reset_to_menu()
	main.call("_show_creator_draft", CampaignStore.make_draft("QA Shortcuts", "qa_dialogue_shortcuts"))
	await wait_frames(4)
	assert_true(main.get("current_screen") is CampaignCreator, "the campaign creator is the current screen")
	for shortcut in HUD_SHORTCUTS:
		_send_key(int(shortcut[0]))
		await wait_frames(2)
		assert_null(main.get("modal"), "%s opens no HUD panel in the creator" % OS.get_keycode_string(int(shortcut[0])))
	assert_true(main.get("current_screen") is CampaignCreator, "the creator stays open")
