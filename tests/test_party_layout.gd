extends GutTest

## Party selection at the largest text scale: each character card must grow with
## its wrapped traits, the grid must scroll instead of clipping, keyboard focus
## must bring the whole focused card into view, and Begin/Back must stay visible.

const ID := "qa_party_layout"
const TITLE := "QA Party Layout"

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
	main.call("_show_party_select")
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


func _party_scroll() -> ScrollContainer:
	var scrolls := main.find_children("*", "ScrollContainer", true, false)
	if scrolls.is_empty():
		return null
	return scrolls[0] as ScrollContainer


func _cards(scroll: ScrollContainer) -> Array[Control]:
	var out: Array[Control] = []
	for node in scroll.get_child(0).get_children():
		if node is PanelContainer:
			out.append(node as Control)
	return out


func _checks(scroll: ScrollContainer) -> Array[CheckBox]:
	var out: Array[CheckBox] = []
	for node in scroll.find_children("*", "CheckBox", true, false):
		out.append(node as CheckBox)
	return out


func _button(text: String) -> Button:
	var found := main.call("_probe_buttons", main, text) as Array
	return found[0] as Button if not found.is_empty() else null


func test_every_card_grows_and_focus_reveals_the_whole_card() -> void:
	var scroll := _party_scroll()
	assert_not_null(scroll, "party selection has a scroll container")
	if scroll == null:
		return
	assert_true(scroll.follow_focus, "keyboard focus follows into the party grid")
	var cards := _cards(scroll)
	assert_eq(cards.size(), Game.content.playable_character_ids().size(), "every pregen has a card")
	var clipped := 0
	for card in cards:
		for node in card.find_children("*", "Label", true, false):
			var label := node as Label
			var card_rect := card.get_global_rect()
			var label_rect := label.get_global_rect()
			if label_rect.position.y < card_rect.position.y - 1.0 or label_rect.end.y > card_rect.end.y + 1.0:
				clipped += 1
	assert_eq(clipped, 0, "wrapped traits stay inside their cards")
	assert_gt(scroll.get_v_scroll_bar().max_value, scroll.get_v_scroll_bar().page, "the 1.6 grid is taller than one screen")
	assert_true(
		scroll.get_h_scroll_bar().max_value <= scroll.get_h_scroll_bar().page,
		"the party grid needs no horizontal scrolling",
	)
	var checks := _checks(scroll)
	assert_gt(checks.size(), 4, "the pregen list exceeds one screen")
	var last_card := cards[cards.size() - 1]
	scroll.scroll_vertical = 0
	checks[checks.size() - 1].grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	var view := scroll.get_global_rect()
	var card_rect := last_card.get_global_rect()
	assert_gt(scroll.scroll_vertical, 0, "focusing the last pregen scrolls the grid")
	assert_true(
		card_rect.position.y >= view.position.y and card_rect.end.y <= view.end.y,
		"the focused card and all of its traits are visible",
	)
	for text in ["Begin", "Back"]:
		var button := _button(text)
		assert_not_null(button, "%s is visible" % text)
		if button != null:
			var rect := button.get_global_rect()
			assert_true(rect.end.y <= main.get_viewport_rect().size.y, "%s stays inside the window" % text)
			assert_true(rect.position.y >= view.end.y - 1.0, "%s stays below the scrolling cards" % text)


func test_selection_limits_and_begin_use_the_chosen_party() -> void:
	var scroll := _party_scroll()
	assert_not_null(scroll, "party selection has a scroll container")
	if scroll == null:
		return
	var checks := _checks(scroll)
	assert_eq(checks.size(), 5, "the fixture exposes five pregens")
	var begin := _button("Begin")
	var back := _button("Back")
	assert_not_null(begin, "Begin is present")
	assert_not_null(back, "Back is present")
	for check in checks:
		check.button_pressed = false
	await get_tree().process_frame
	await get_tree().process_frame
	var error := main.get("party_error") as Label
	assert_eq(error.text, "Choose at least one adventurer.", "an empty party is refused immediately")
	begin.emit_signal("pressed")
	await get_tree().process_frame
	assert_eq(Game.campaign_id, ID, "Begin with no selection does not start the campaign")
	assert_eq(error.text, "Pick one to four adventurers.", "Begin explains the empty party")
	checks[0].button_pressed = true
	await get_tree().process_frame
	assert_eq(error.text, "1 selected.", "the minimum party is accepted")
	for check in checks:
		check.button_pressed = true
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(error.text, "Choose at most four adventurers.", "a fifth selection is refused immediately")
	begin.emit_signal("pressed")
	await get_tree().process_frame
	assert_eq(Game.campaign_id, ID, "Begin with five does not start the campaign")
	assert_eq(error.text, "Pick one to four adventurers.", "Begin explains the maximum")
	checks[4].button_pressed = false
	await get_tree().process_frame
	assert_eq(error.text, "4 selected.", "four selections are accepted")
	begin.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(Game.campaign_id, ID, "Begin starts the loaded campaign")
	assert_eq(Game.party.size(), 4, "Begin starts with the four chosen characters")


func test_back_then_reopen_resets_selection_but_keeps_the_campaign() -> void:
	var scroll := _party_scroll()
	assert_not_null(scroll, "party selection has a scroll container")
	if scroll == null:
		return
	var checks := _checks(scroll)
	checks[0].button_pressed = false
	await get_tree().process_frame
	var back := _button("Back")
	assert_not_null(back, "Back is present")
	back.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(main.get("current_screen") != null, "Back returns to the campaign list")
	assert_eq(Game.campaign_id, ID, "Back keeps the campaign identity")
	var title_seen := false
	for node in main.find_children("*", "Label", true, false):
		if (node as Label).text.contains(TITLE):
			title_seen = true
	assert_true(title_seen, "the campaign title is still shown after Back")
	main.call("_show_party_select")
	await get_tree().process_frame
	await get_tree().process_frame
	checks = _checks(_party_scroll())
	var selected := 0
	for check in checks:
		if check.button_pressed:
			selected += 1
	assert_eq(selected, 4, "reopening restores the default party instead of stale edits")
	assert_true(main.get("party_selection").size() == 4, "the selection model matches the visible defaults")
