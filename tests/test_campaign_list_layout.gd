extends GutTest

## The campaign list is a vertical ScrollContainer. Keyboard traversal must bring
## a focused card action into view, and a maximum-length title must wrap instead
## of widening the list and clipping every card horizontally.

const IDS := ["qa_list_layout_a", "qa_list_layout_b", "qa_list_layout_c", "qa_list_layout_long"]
const LONG_TITLE := "QA Long Campaign Title That Reaches The Full Eighty Character Authoring Limit"

var main: Control


func before_each() -> void:
	for id in IDS:
		CampaignStore.delete_user_campaign(id)
	var titles := ["QA Layout A", "QA Layout B", "QA Layout C", LONG_TITLE]
	for i in IDS.size():
		var made := CampaignStore.create(titles[i], IDS[i])
		assert_true(bool(made.get("ok", false)), String(made.get("message", "")))
	Game.refresh_campaigns()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame


func after_each() -> void:
	if main != null:
		main.queue_free()
		main = null
	for id in IDS:
		CampaignStore.delete_user_campaign(id)
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")


func test_the_list_follows_keyboard_focus_and_wraps_long_titles() -> void:
	main.call("_show_campaign_select")
	await get_tree().process_frame
	await get_tree().process_frame
	var scrolls := main.find_children("*", "ScrollContainer", true, false)
	assert_eq(scrolls.size(), 1, "the campaign screen has one scroll container")
	var scroll := scrolls[0] as ScrollContainer
	assert_true(scroll.follow_focus, "keyboard focus scrolls the list")
	assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "the list stays vertical")
	var long_label: Label = null
	for node in scroll.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.text.begins_with("QA Long Campaign Title"):
			long_label = label
			break
	assert_not_null(long_label, "the maximum-length title is rendered")
	if long_label != null:
		assert_eq(long_label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "the title wraps inside its card")
	assert_true(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "the fixture list is taller than one screen")
	var new_game := main.call("_probe_buttons", main, "New game") as Array
	assert_gt(new_game.size(), 1, "several campaigns expose their own action")
	var last: Button = new_game[new_game.size() - 1]
	last.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	var view := scroll.get_global_rect()
	var focused := last.get_global_rect()
	assert_gt(scroll.scroll_vertical, 0, "focusing an off-screen action scrolls the list")
	assert_true(focused.position.y >= view.position.y and focused.end.y <= view.end.y, "the focused action is visible")
	assert_true(focused.position.x >= view.position.x and focused.end.x <= view.end.x, "the focused action is horizontally visible")
	assert_true(scroll.get_h_scroll_bar().max_value <= scroll.get_h_scroll_bar().page, "no horizontal scrolling is required")
	var disabled_focus := 0
	for text in ["Continue latest", "Load slot"]:
		for node in scroll.find_children("*", "Button", true, false):
			var button := node as Button
			if button != null and button.text == text and button.disabled:
				disabled_focus += 1
				assert_eq(button.focus_mode, Control.FOCUS_NONE, "a disabled %s action is skipped by Tab" % text)
	assert_gt(disabled_focus, 0, "the fixture includes disabled actions")


func test_rebuilding_after_a_package_disappears_does_not_activate_a_card() -> void:
	main.call("_show_campaign_select")
	await get_tree().process_frame
	await get_tree().process_frame
	var before := (main.call("_probe_buttons", main, "New game") as Array).size()
	var campaign_before := Game.campaign_id
	CampaignStore.delete_user_campaign(IDS[0])
	Game.refresh_campaigns()
	main.call("_show_campaign_select")
	await get_tree().process_frame
	await get_tree().process_frame
	var after := (main.call("_probe_buttons", main, "New game") as Array).size()
	assert_eq(after, before - 1, "the removed package disappears from the rebuilt list")
	assert_eq(Game.campaign_id, campaign_before, "rebuilding does not load or act on a campaign")
	assert_true(main.get("current_screen") != null, "the campaign screen remains active")
