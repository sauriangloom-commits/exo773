extends GutTest

## Shared modal constraints: a long title wraps, the panel stays inside the
## viewport, tall content scrolls, and Close/Continue remain reachable at 1.6.

const ID := "qa_modal_layout"
const TITLE := "QA Modal Layout"
const LONG_TITLE := "QA Long Modal Title That Reaches The Full Eighty Character Authoring Limit"

var main: Control
var original_scale := 1.0


func before_each() -> void:
	CampaignStore.delete_user_campaign(ID)
	var made := CampaignStore.create(TITLE, ID)
	assert_true(bool(made.get("ok", false)), String(made.get("message", "")))
	Game.refresh_campaigns()
	Game.load_campaign(ID)
	original_scale = float(Game.settings.get("text_scale", 1.0))
	Game.settings["text_scale"] = 1.6
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame


func after_each() -> void:
	if main != null:
		main.queue_free()
		main = null
	Game.settings["text_scale"] = original_scale
	CampaignStore.delete_user_campaign(ID)
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")


func _modal_panel() -> Control:
	var modal := main.get("modal") as Control
	if modal == null:
		return null
	var center := modal.get_child(1) as Control
	return center.get_child(0) as Control


func _labels(panel: Control) -> Array[Label]:
	var out: Array[Label] = []
	for node in panel.find_children("*", "Label", true, false):
		out.append(node as Label)
	return out


func _button(root: Control, text: String) -> Button:
	var found := main.call("_probe_buttons", root, text) as Array
	return found[0] as Button if not found.is_empty() else null


func test_long_title_and_tall_content_stay_inside_the_viewport() -> void:
	var content := func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(700, 900)
		box.add_theme_constant_override("separation", 8)
		for i in 24:
			box.add_child(ThemeBuilder.body("Narration line %d stays readable in the shared modal." % i, false, 15))
		var cont := Button.new()
		cont.text = "Continue"
		cont.custom_minimum_size = Vector2(0, 42)
		box.add_child(cont)
		return box
	main.call("open_modal", LONG_TITLE, content, 760, 540)
	for i in 3:
		await get_tree().process_frame
	var panel := _modal_panel()
	assert_not_null(panel, "the shared modal builds")
	if panel == null:
		return
	var window := main.get_viewport_rect().size
	var rect := panel.get_global_rect()
	assert_true(rect.position.x >= -1.0 and rect.end.x <= window.x + 1.0, "the modal fits horizontally")
	assert_true(rect.position.y >= -1.0 and rect.end.y <= window.y + 1.0, "the modal fits vertically")
	var heading: Label = null
	for label in _labels(panel):
		if label.text == LONG_TITLE:
			heading = label
	assert_not_null(heading, "the full heading is rendered")
	if heading != null:
		assert_eq(heading.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "the heading wraps")
		assert_true(heading.get_global_rect().end.x <= rect.end.x, "the heading stays inside the panel")
	var close := _button(panel, "Close (Esc)")
	assert_not_null(close, "Close is present")
	if close != null:
		var close_rect := close.get_global_rect()
		assert_true(close_rect.end.x <= window.x and close_rect.end.y <= window.y, "Close is inside the window")
	var scrolls := panel.find_children("*", "ScrollContainer", true, false)
	assert_eq(scrolls.size(), 1, "the modal content has one shared scroll container")
	var scroll := scrolls[0] as ScrollContainer
	assert_true(scroll.follow_focus, "modal focus follows into the scrolling content")
	assert_gt(scroll.get_v_scroll_bar().max_value, scroll.get_v_scroll_bar().page, "tall content scrolls")
	var cont := _button(panel, "Continue")
	assert_not_null(cont, "the content action is present")
	if cont != null:
		cont.grab_focus()
		await get_tree().process_frame
		await get_tree().process_frame
		var view := scroll.get_global_rect()
		var cont_rect := cont.get_global_rect()
		assert_gt(scroll.scroll_vertical, 0, "focusing the content action scrolls it into view")
		assert_true(cont_rect.position.y >= view.position.y and cont_rect.end.y <= view.end.y, "the content action is visible")
	assert_true(main.get("modal") != null, "the modal stays open while inspected")
	close.emit_signal("pressed")
	await get_tree().process_frame
	assert_null(main.get("modal"), "Close dismisses the shared modal")


func test_short_content_needs_no_scroll_and_keeps_actions_visible() -> void:
	var content := func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body("Short confirmation text.", true, 14))
		var action := Button.new()
		action.text = "Continue"
		action.custom_minimum_size = Vector2(0, 40)
		box.add_child(action)
		return box
	main.call("open_modal", "Confirm", content, 520, 300)
	for i in 3:
		await get_tree().process_frame
	var panel := _modal_panel()
	assert_not_null(panel, "the short modal builds")
	if panel == null:
		return
	var window := main.get_viewport_rect().size
	var rect := panel.get_global_rect()
	assert_true(rect.end.x <= window.x and rect.end.y <= window.y, "the short modal fits the window")
	var cont := _button(panel, "Continue")
	assert_not_null(cont, "Continue is present")
	if cont != null:
		var cont_rect := cont.get_global_rect()
		assert_true(cont_rect.end.x <= rect.end.x and cont_rect.end.y <= rect.end.y, "Continue stays inside the panel")
	var close := _button(panel, "Close (Esc)")
	assert_not_null(close, "Close is present")
	if close != null:
		assert_true(close.get_global_rect().end.y <= window.y, "Close stays inside the window")


func test_intro_uses_the_shared_modal_and_dismisses_to_exploration() -> void:
	var party: Array = Array(Game.campaign.get("party", {}).get("default", ["kaelen"]))
	var started := Game.new_game(party, -1)
	assert_true(bool(started.get("ok", false)), "the campaign starts")
	main.call("_route")
	main.call("_show_intro")
	for i in 3:
		await get_tree().process_frame
	var panel := _modal_panel()
	assert_not_null(panel, "the intro uses the shared modal")
	if panel == null:
		return
	var heading: Label = null
	for label in _labels(panel):
		if label.text == TITLE:
			heading = label
	assert_not_null(heading, "the campaign title is the modal heading")
	if heading != null:
		assert_true(heading.autowrap_mode != TextServer.AUTOWRAP_OFF, "the intro title wraps")
	var narration := false
	for label in _labels(panel):
		if label.text.contains("begins here") or label.text.contains("placeholder"):
			narration = true
	assert_true(narration, "intro narration is rendered")
	var begin := _button(panel, "Begin the campaign")
	assert_not_null(begin, "Begin the campaign is present")
	var close := _button(panel, "Close (Esc)")
	assert_not_null(close, "Close is present")
	if close != null:
		assert_eq(main.get_viewport().gui_get_focus_owner(), close, "the intro starts with Close focused")
	var campaign_before := Game.campaign_id
	var mode_before := Game.mode
	if begin != null:
		begin.emit_signal("pressed")
		await get_tree().process_frame
		assert_null(main.get("modal"), "Begin dismisses the intro")
		assert_null(main.get_viewport().gui_get_focus_owner(), "Begin dismissal releases modal focus")
		assert_eq(Game.campaign_id, campaign_before, "Begin keeps the campaign identity")
		assert_eq(Game.mode, mode_before, "Begin leaves the game in exploration")
		assert_true(main.get("current_screen") != null, "exploration receives input after Begin")
		main.call("_show_intro")
		for i in 2:
			await get_tree().process_frame
		panel = _modal_panel()
		assert_not_null(panel, "the intro can be reopened")
		if panel != null:
			close = _button(panel, "Close (Esc)")
			assert_not_null(close, "Close is present when reopened")
			if close != null:
				close.emit_signal("pressed")
				await get_tree().process_frame
				assert_null(main.get("modal"), "Close dismisses the reopened intro")
				assert_null(main.get_viewport().gui_get_focus_owner(), "Close dismissal releases modal focus")
				assert_eq(Game.campaign_id, campaign_before, "Close keeps the campaign identity")
				assert_eq(Game.mode, mode_before, "Close leaves the game in exploration")
				main.call("_show_intro")
				for i in 2:
					await get_tree().process_frame
				var escape := InputEventKey.new()
				escape.physical_keycode = KEY_ESCAPE
				escape.pressed = true
				main.call("_input", escape)
				await get_tree().process_frame
				assert_null(main.get("modal"), "Escape dismisses the intro")
				assert_eq(Game.mode, mode_before, "Escape leaves the game in exploration")
