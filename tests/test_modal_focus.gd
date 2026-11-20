extends GutTest

## Shared modal focus rules: Tab and Shift+Tab stay inside the open modal, the
## world behind it cannot be acted on, and closing returns focus to the opener
## (or a usable fallback). These cover the shared path every modal uses.

var main: Control = null
var original_scale := 1.0


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)
	original_scale = float(Game.settings.get("text_scale", 1.0))
	main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(3)


func after_each() -> void:
	if main != null:
		main.queue_free()
		main = null
	Game.settings["text_scale"] = original_scale
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


# ------------------------------------------------ keyboard scrolling of the body

## A body that deliberately overflows its 660x380 panel. `extra` adds one control
## below the fold whose own use of Up/Down or PageUp/PageDown is the point.
func _open_tall_modal(extra := "") -> void:
	main.call("open_modal", "QA Tall", func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(600, 0)
		box.add_theme_constant_override("separation", 2)
		for index in 40:
			box.add_child(ThemeBuilder.body(
				"QA scrolling line %02d of a deliberately tall modal body." % index, false, 15
			))
		if extra == "field":
			var field := LineEdit.new()
			field.text = "caret here"
			box.add_child(field)
		if extra == "list":
			var list := ItemList.new()
			list.custom_minimum_size = Vector2(0, 150)
			for item in 6:
				list.add_item("QA list row %d" % item)
			box.add_child(list)
		return box
	, 660, 380)
	await wait_frames(2)


func _scroll() -> ScrollContainer:
	return main.get("modal_scroll") as ScrollContainer


func _first_of_type(node: Node, type_name: String) -> Control:
	var found := node.find_children("*", type_name, true, false)
	return found[0] as Control if not found.is_empty() else null


func test_page_down_moves_about_ninety_percent_of_the_page() -> void:
	await _open_tall_modal()
	var scroll := _scroll()
	assert_not_null(scroll, "the modal exposes its scrolling body")
	if scroll == null:
		return
	var page := int(scroll.get_v_scroll_bar().page)
	assert_gt(page, 0, "the body has a measured page")
	var owner := _focus_owner()
	_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	assert_almost_eq(float(scroll.scroll_vertical), 0.9 * float(page), 2.0, "PageDown moves 90 % of the page")
	assert_eq(_focus_owner(), owner, "the focus ring stays on the control it was on")
	_send_key(KEY_PAGEUP)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, 0, "PageUp returns to the top")


func test_arrows_move_two_text_lines() -> void:
	await _open_tall_modal()
	var scroll := _scroll()
	if scroll == null:
		fail_test("the modal exposes its scrolling body")
		return
	var line: int = main.call("_modal_body_line_height")
	assert_gt(line, 0, "a text line has a positive height")
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, 2 * line, "Down moves exactly two text lines")
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, 4 * line, "a second Down moves two more")
	_send_key(KEY_UP)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, 2 * line, "Up moves two lines back")


func test_the_arrow_step_follows_the_text_scale() -> void:
	await _open_tall_modal()
	var base: int = main.call("_modal_body_line_height")
	Game.settings["text_scale"] = 1.6
	main.theme = ThemeBuilder.build(16)
	var scaled: int = main.call("_modal_body_line_height")
	assert_gt(scaled, base, "160 % text has a taller line")
	assert_almost_eq(float(scaled), float(base) * 1.6, 2.0, "the step grows with the text scale")


func test_scrolling_stops_at_both_bounds() -> void:
	await _open_tall_modal()
	var scroll := _scroll()
	if scroll == null:
		fail_test("the modal exposes its scrolling body")
		return
	var travel: int = main.call("_modal_body_scroll_range")
	assert_gt(travel, 0, "the overflowing body can travel")
	_send_key(KEY_PAGEUP)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, 0, "PageUp at the top stays at the top")
	for step in 12:
		_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, travel, "PageDown stops at the last page")
	for step in 3:
		_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, travel, "Down at the bottom does not overshoot")
	_send_key(KEY_PAGEUP)
	await wait_frames(1)
	assert_lt(scroll.scroll_vertical, travel, "PageUp leaves the bottom again")


func test_content_that_fits_does_not_scroll() -> void:
	main.call("open_modal", "QA Short", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body("A short confirmation that fits its panel.", true, 14))
		var action := Button.new()
		action.text = "QA short action"
		action.custom_minimum_size = Vector2(0, 40)
		box.add_child(action)
		return box
	, 520, 300)
	await wait_frames(2)
	var scroll := _scroll()
	if scroll == null:
		fail_test("the modal exposes its scrolling body")
		return
	assert_eq(int(main.call("_modal_body_scroll_range")), 0, "the short body cannot travel")
	var owner := _focus_owner()
	for code in [KEY_PAGEDOWN, KEY_DOWN, KEY_DOWN, KEY_UP, KEY_PAGEUP]:
		_send_key(code)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, 0, "a body that fits does not move")
	assert_eq(_focus_owner(), owner, "the ring stays on the same control")
	assert_not_null(_modal(), "the modal is still open")


func test_focus_stays_contained_while_the_body_scrolls() -> void:
	await _open_tall_modal()
	var outside := _outside_controls()
	for code in [KEY_PAGEDOWN, KEY_PAGEDOWN, KEY_DOWN, KEY_UP, KEY_PAGEUP]:
		_send_key(code)
	await wait_frames(1)
	var owner := _focus_owner()
	assert_not_null(owner, "a control still holds focus")
	assert_true(_modal().is_ancestor_of(owner), "scrolling did not move focus out of the modal")
	assert_false(outside.has(owner), "scrolling did not move focus onto the dimmed world")
	_send_key(KEY_TAB)
	await wait_frames(1)
	assert_true(_modal().is_ancestor_of(_focus_owner()), "Tab still cycles inside after scrolling")


func test_escape_still_closes_and_restores_focus_after_scrolling() -> void:
	var opener := await _opener()
	await _open_tall_modal()
	_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	_send_key(KEY_ESCAPE)
	await wait_frames(2)
	assert_null(_modal(), "Escape still closes the modal")
	assert_eq(_focus_owner(), opener, "Escape still returns focus to the opener")
	opener.queue_free()


func test_rebind_capture_still_wins_over_scrolling() -> void:
	await _open_tall_modal()
	main.set("awaiting_rebind", "not_a_real_action")
	_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	assert_eq(String(main.get("awaiting_rebind")), "", "the capture consumed the page key")
	var scroll := _scroll()
	if scroll != null:
		assert_eq(scroll.scroll_vertical, 0, "the body did not scroll while capturing a rebind")


func test_a_focused_text_field_keeps_the_arrows() -> void:
	await _open_tall_modal("field")
	var scroll := _scroll()
	var field := _first_of_type(_modal(), "LineEdit") as LineEdit
	assert_not_null(field, "the tall body offers a text field")
	if field == null or scroll == null:
		return
	field.grab_focus()
	await wait_frames(2)
	scroll.scroll_vertical = 100
	await wait_frames(1)
	var before := scroll.scroll_vertical
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, before, "a focused text field keeps Down for its caret")
	assert_eq(_focus_owner(), field, "the caret keeps focus")
	_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	assert_gt(scroll.scroll_vertical, before, "PageDown still pages the body from a text field")


func test_a_focused_list_keeps_the_arrows_and_moves_its_own_selection() -> void:
	await _open_tall_modal("list")
	var scroll := _scroll()
	var list := _first_of_type(_modal(), "ItemList") as ItemList
	assert_not_null(list, "the tall body offers a list")
	if list == null or scroll == null:
		return
	list.select(0)
	list.grab_focus()
	await wait_frames(2)
	var before := scroll.scroll_vertical
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, before, "a focused list keeps Down for its selection")
	var selected := list.get_selected_items()
	assert_eq(selected.size(), 1, "the list still has a selection")
	if selected.size() == 1:
		assert_eq(selected[0], 1, "the list moved its own selection")


## The Journal's shape: the shared body fits exactly and the panel wraps its text
## in a ScrollContainer of its own. The scrolling keys must move the body the
## player can actually see, not the outer one that cannot travel.
func test_a_body_that_wraps_its_own_scroll_container_still_scrolls() -> void:
	main.call("open_modal", "QA Nested", func() -> Control:
		var root := VBoxContainer.new()
		root.custom_minimum_size = Vector2(600, 0)
		var inner := ScrollContainer.new()
		inner.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var text := RichTextLabel.new()
		text.fit_content = true
		var lines: Array[String] = []
		for index in 60:
			lines.append("QA nested journal line %02d of a deliberately long panel." % index)
		text.text = "\n".join(PackedStringArray(lines))
		inner.add_child(text)
		root.add_child(inner)
		return root
	, 660, 380)
	await wait_frames(3)
	var outer := _scroll()
	if outer == null:
		fail_test("the modal exposes its scrolling body")
		return
	var inner_nodes := outer.find_children("*", "ScrollContainer", true, false)
	assert_false(inner_nodes.is_empty(), "the panel wraps its own scroll container")
	if inner_nodes.is_empty():
		return
	var inner := inner_nodes[0] as ScrollContainer
	assert_eq(int(main.call("_scroll_travel", outer)), 0, "the shared body itself fits")
	assert_gt(int(main.call("_modal_body_scroll_range")), 0, "the visible body can travel")
	assert_eq(main.call("_modal_body_target"), inner, "the scrolling keys target the inner body")
	_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	assert_gt(inner.scroll_vertical, 0, "PageDown moves the text the player can see")
	assert_eq(outer.scroll_vertical, 0, "the outer body stays where it was")
	_send_key(KEY_DOWN)
	await wait_frames(1)
	var line: int = main.call("_modal_body_line_height")
	assert_gt(inner.scroll_vertical, int(round(0.9 * float(inner.get_v_scroll_bar().page))), "Down adds two more lines")
	assert_gt(line, 0, "the line step is positive")


## Settings' shape at 100 %: a wrapper whose own minimum size gives it a sliver of
## travel, and the list the player reads inside it. The list is the pane.
func _open_wrapped_modal() -> void:
	main.call("open_modal", "QA Wrapped", func() -> Control:
		var root := VBoxContainer.new()
		root.custom_minimum_size = Vector2(600, 420)
		root.add_theme_constant_override("separation", 4)
		var inner := ScrollContainer.new()
		inner.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for index in 40:
			list.add_child(ThemeBuilder.body("QA wrapped row %02d of a long settings list." % index, false, 15))
		inner.add_child(list)
		root.add_child(inner)
		return root
	, 660, 380)
	await wait_frames(3)


## A tall prose body with one short nested list: the body must keep the keys.
func _open_body_with_short_list() -> void:
	main.call("open_modal", "QA Body", func() -> Control:
		var root := VBoxContainer.new()
		root.custom_minimum_size = Vector2(600, 0)
		root.add_theme_constant_override("separation", 4)
		for index in 40:
			root.add_child(ThemeBuilder.body("QA prose line %02d of a long body." % index, false, 15))
		var inner := ScrollContainer.new()
		inner.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		inner.custom_minimum_size = Vector2(0, 60)
		var short_list := VBoxContainer.new()
		short_list.add_child(ThemeBuilder.body("One short row.", true, 13))
		short_list.add_child(ThemeBuilder.body("Another short row.", true, 13))
		inner.add_child(short_list)
		root.add_child(inner)
		return root
	, 660, 380)
	await wait_frames(3)


func _open_control_modal(kind: String) -> void:
	main.call("open_modal", "QA Control", func() -> Control:
		var root := VBoxContainer.new()
		root.custom_minimum_size = Vector2(600, 0)
		root.add_theme_constant_override("separation", 4)
		if kind == "hs":
			var slider := HSlider.new()
			slider.min_value = 0.0
			slider.max_value = 1.0
			slider.step = 0.05
			slider.value = 0.5
			root.add_child(slider)
		elif kind == "vs":
			var vertical := VSlider.new()
			vertical.min_value = 0.0
			vertical.max_value = 1.0
			vertical.step = 0.05
			vertical.value = 0.5
			vertical.custom_minimum_size = Vector2(40, 80)
			root.add_child(vertical)
		elif kind == "tabs":
			var bar := TabBar.new()
			bar.add_tab("One")
			bar.add_tab("Two")
			root.add_child(bar)
		for index in 40:
			root.add_child(ThemeBuilder.body("QA control filler %02d." % index, false, 15))
		return root
	, 660, 380)
	await wait_frames(3)


func test_a_wrapper_with_a_taller_list_scrolls_the_list() -> void:
	await _open_wrapped_modal()
	var outer := _scroll()
	if outer == null:
		fail_test("the modal exposes its scrolling body")
		return
	var inner := _first_of_type(outer, "ScrollContainer") as ScrollContainer
	assert_not_null(inner, "the wrapper holds its own list")
	if inner == null:
		return
	var outer_travel := int(main.call("_scroll_travel", outer))
	var inner_travel := int(main.call("_scroll_travel", inner))
	assert_gt(outer_travel, 0, "the wrapper itself can travel a sliver")
	assert_gt(inner_travel, outer_travel, "the list travels further than the wrapper")
	assert_eq(main.call("_modal_body_target"), inner, "the keys move the list, not the wrapper")
	for step in 3:
		_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	assert_eq(inner.scroll_vertical, inner_travel, "PageDown reaches the end of the list")
	assert_eq(outer.scroll_vertical, 0, "the wrapper stays where it was")


func test_a_long_body_with_a_short_inner_list_scrolls_the_body() -> void:
	await _open_body_with_short_list()
	var outer := _scroll()
	if outer == null:
		fail_test("the modal exposes its scrolling body")
		return
	var inner := _first_of_type(outer, "ScrollContainer") as ScrollContainer
	assert_not_null(inner, "the body holds a short nested list")
	if inner == null:
		return
	assert_gt(int(main.call("_scroll_travel", outer)), int(main.call("_scroll_travel", inner)), "the body travels further")
	assert_eq(main.call("_modal_body_target"), outer, "the prose body keeps the keys")
	var line: int = main.call("_modal_body_line_height")
	_send_key(KEY_PAGEDOWN)
	await wait_frames(1)
	assert_gt(outer.scroll_vertical, 0, "PageDown moves the body")
	assert_eq(inner.scroll_vertical, 0, "the short list does not move")
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_gt(line, 0, "the line step is positive")


func test_a_focused_horizontal_slider_scrolls_the_body_without_changing_its_value() -> void:
	await _open_control_modal("hs")
	var slider := _first_of_type(_modal(), "HSlider") as HSlider
	var scroll := _scroll()
	assert_not_null(slider, "the modal offers a horizontal slider")
	if slider == null or scroll == null:
		return
	slider.grab_focus()
	await wait_frames(2)
	var line: int = main.call("_modal_body_line_height")
	var before_value := slider.value
	var before_scroll := scroll.scroll_vertical
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, before_scroll + 2 * line, "Down scrolls the body from a slider")
	assert_eq(slider.value, before_value, "Down does not change the slider's value")
	assert_eq(_focus_owner(), slider, "the slider keeps focus")
	var scrolled := scroll.scroll_vertical
	_send_key(KEY_RIGHT)
	await wait_frames(1)
	assert_gt(slider.value, before_value, "Right still adjusts the slider")
	assert_eq(scroll.scroll_vertical, scrolled, "Right does not scroll the body")
	assert_eq(_focus_owner(), slider, "the slider still holds focus after Right")


func test_a_focused_tab_bar_scrolls_the_body_and_right_still_switches_tabs() -> void:
	await _open_control_modal("tabs")
	var bar := _first_of_type(_modal(), "TabBar") as TabBar
	var scroll := _scroll()
	assert_not_null(bar, "the modal offers a tab bar")
	if bar == null or scroll == null:
		return
	bar.grab_focus()
	await wait_frames(2)
	var line: int = main.call("_modal_body_line_height")
	assert_eq(_focus_owner(), bar, "the tab bar holds focus")
	_send_key(KEY_RIGHT)
	await wait_frames(1)
	assert_eq(bar.current_tab, 1, "Right still switches tabs")
	assert_eq(scroll.scroll_vertical, 0, "Right does not scroll the body")
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_eq(scroll.scroll_vertical, 2 * line, "Down scrolls the body from the tab bar")
	assert_eq(bar.current_tab, 1, "Down does not change the tab")
	assert_eq(_focus_owner(), bar, "the tab bar keeps focus")


func test_a_focused_vertical_slider_keeps_the_arrows() -> void:
	await _open_control_modal("vs")
	var slider := _first_of_type(_modal(), "VSlider") as VSlider
	var scroll := _scroll()
	assert_not_null(slider, "the modal offers a vertical slider")
	if slider == null or scroll == null:
		return
	slider.grab_focus()
	await wait_frames(2)
	var before := slider.value
	_send_key(KEY_DOWN)
	await wait_frames(1)
	assert_lt(slider.value, before, "a vertical slider still uses Down for its value")
	assert_eq(scroll.scroll_vertical, 0, "the body does not scroll from a vertical slider")
	assert_eq(_focus_owner(), slider, "the vertical slider keeps focus")


func test_the_scroll_helper_ignores_keys_it_does_not_own() -> void:
	await _open_tall_modal()
	for code in [KEY_ENTER, KEY_TAB, KEY_ESCAPE, KEY_W]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = true
		assert_false(bool(main.call("_scroll_modal_body", event)), "key %d is not a body scroll key" % code)


func test_a_closed_modal_has_no_body_to_scroll() -> void:
	main.call("open_modal", "QA Tall", func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(600, 2400)
		return box
	, 660, 380)
	await wait_frames(2)
	main.call("close_modal")
	await wait_frames(1)
	assert_null(main.get("modal_scroll"), "closing drops the body reference")
	var event := InputEventKey.new()
	event.keycode = KEY_PAGEDOWN
	event.physical_keycode = KEY_PAGEDOWN
	event.pressed = true
	assert_false(bool(main.call("_scroll_modal_body", event)), "nothing scrolls without a modal")
