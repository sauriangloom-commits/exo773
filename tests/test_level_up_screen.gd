extends GutTest

## Batch 4a of docs/LEVEL_UP_PLAN.md section 14: the level-up screen the party
## sheet opens, and the `Level up` button that opens it.
##
## The screen spends the step the engine already validates. It never computes a
## rule: it renders `LevelChoices.choices`, asks `LevelChoices.validate` and calls
## `LevelUp.apply` once. `tests/test_level_up_ui_surface.gd` pins that surface from
## the source text; these tests pin it from behaviour.
##
## The 160 % layout is pinned here by control-rectangle checks in the shape the
## creator probe uses (`viewport.encloses(control.get_global_rect())`). The
## `--level-up-probe` that walks both scales lives in batch 4b and 4c; until it
## runs, the 160 % layout is checked by these tests only and has not been seen in
## a window.

var main: Control = null
var original_scale := 1.0


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	Game.new_game(["kaelen", "sera", "aldric", "mira"], 4242)
	original_scale = float(Game.settings.get("text_scale", 1.0))
	main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(3)
	# Main starts on its menu whatever the state was before it existed, so the
	# exploration screen is built explicitly, the way `_route` builds it.
	if not main.current_screen is ExplorationScreen:
		main.call("_ensure_exploration")
		await wait_frames(3)
	assert_true(main.current_screen is ExplorationScreen, "the exploration screen is up")


func after_each() -> void:
	if main != null:
		main.queue_free()
		main = null
	Game.settings["text_scale"] = original_scale
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


# ------------------------------------------------------------------ helpers

func _character(index := 0) -> Character:
	return Game.party[index]


func _all_eligible() -> void:
	for ch in Game.party:
		ch.xp = LevelUp.XP_THRESHOLD


func _modal() -> Control:
	return main.get("modal") as Control


func _screen() -> LevelUpScreen:
	var screen = main.current_screen.get("level_up_screen")
	return screen as LevelUpScreen


func _focus_owner() -> Control:
	return main.get_viewport().gui_get_focus_owner() as Control


func _set_scale(scale: float) -> void:
	Game.settings["text_scale"] = scale
	main.theme = ThemeBuilder.build(16)


func _send_key(code: int, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = true
	main.get_viewport().push_input(event)


func _send_echo(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = true
	main.get_viewport().push_input(event)


func _open_sheet(index := 0) -> void:
	main.current_screen.call("_open_party", index)
	await wait_frames(3)


func _tabs() -> TabContainer:
	if _modal() == null:
		return null
	for node in _modal().find_children("*", "TabContainer", true, false):
		return node as TabContainer
	return null


## The sheet's pages in party order. The sheet is a TabContainer with one
## MarginContainer per party member, so a page is the card the button belongs to.
func _pages() -> Array[Control]:
	var out: Array[Control] = []
	var tabs := _tabs()
	if tabs == null:
		return out
	for child in tabs.get_children():
		if child is MarginContainer:
			out.append(child as Control)
	return out


func _named(node: Node, control_name: String) -> Control:
	if node == null:
		return null
	return node.find_child(control_name, true, false) as Control


func _button_named(control_name: String) -> Button:
	return _named(_modal(), control_name) as Button


func _label_named(control_name: String) -> Label:
	return _named(_modal(), control_name) as Label


func _button_in(node: Node, text: String) -> Button:
	if node == null:
		return null
	for found in node.find_children("*", "Button", true, false):
		var button := found as Button
		if button.text == text:
			return button
	return null


func _level_up_button(page: int) -> Button:
	var pages := _pages()
	if page < 0 or page >= pages.size():
		return null
	return _named(pages[page], "LevelUpButton") as Button


func _reason_label(page: int) -> Label:
	var pages := _pages()
	if page < 0 or page >= pages.size():
		return null
	return _named(pages[page], "LevelUpReason") as Label


func _open_level_up(page: int) -> LevelUpScreen:
	var tabs := _tabs()
	assert_not_null(tabs, "the party sheet is open")
	if tabs == null:
		return null
	tabs.current_tab = page
	await wait_frames(1)
	var button := _level_up_button(page)
	assert_not_null(button, "page %d offers Level up" % page)
	if button == null:
		return null
	button.pressed.emit()
	await wait_frames(3)
	return _screen()


func _press(text: String) -> void:
	var button := _button_in(_modal(), text)
	assert_not_null(button, "%s is present" % text)
	if button == null:
		return
	button.pressed.emit()
	await wait_frames(2)


func _press_named(control_name: String) -> void:
	var button := _button_named(control_name)
	assert_not_null(button, "%s is present" % control_name)
	if button == null:
		return
	button.pressed.emit()
	await wait_frames(2)


func _step_title() -> String:
	var title := _label_named("StepTitle")
	return "" if title == null else title.text


func _strip_texts() -> Array[String]:
	var out: Array[String] = []
	var strip := _named(_modal(), "StepStrip")
	if strip == null:
		return out
	for child in strip.get_children():
		var label := child as Label
		if label != null:
			out.append(label.text)
	return out


## The panel the modal body sits in: found by walking up, because a node's default
## name carries a counter once several panels have existed in one run.
func _panel_of(control: Control) -> Control:
	var node := control
	while node != null and not node is PanelContainer:
		node = node.get_parent()
	return node


func _step_scroll() -> ScrollContainer:
	return _named(_modal(), "StepScroll") as ScrollContainer


func _travel(scroll: ScrollContainer) -> int:
	return int(main.call("_scroll_travel", scroll))


## True when the control's whole height sits inside the pane that clips it.
func _fully_inside(control: Control, pane: Control) -> bool:
	if control == null or pane == null:
		return false
	var rect := control.get_global_rect()
	var view := pane.get_global_rect()
	return rect.position.y >= view.position.y - 0.5 and rect.end.y <= view.end.y + 0.5


func _contains_rect(outer: Control, inner: Control) -> bool:
	if outer == null or inner == null:
		return false
	var box := outer.get_global_rect()
	var rect := inner.get_global_rect()
	return (
		rect.position.x >= box.position.x - 0.5
		and rect.position.y >= box.position.y - 0.5
		and rect.end.x <= box.end.x + 0.5
		and rect.end.y <= box.end.y + 0.5
	)


## Walks Summary -> Ability (choose) -> Skills -> Feat (choose) -> Confirm.
func _walk_to_confirm(feat := true) -> void:
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	await _press("Continue")
	if feat:
		await _press_named("feat_power_attack")
	await _press("Continue")


func _summary_text(control_name: String) -> String:
	var label := _label_named(control_name)
	return "" if label == null else label.text


# -------------------------------------------------------------------- the sheet

# 1
func test_the_sheet_offers_level_up_only_on_eligible_pages() -> void:
	_character(0).xp = LevelUp.XP_THRESHOLD
	await _open_sheet(0)
	var pages := _pages()
	assert_eq(pages.size(), 4, "the sheet has one page per party member")
	var buttons := 0
	for index in pages.size():
		var button := _level_up_button(index)
		var reason := _reason_label(index)
		if index == 0:
			assert_not_null(button, "an eligible page offers Level up")
			assert_null(reason, "an eligible page shows no refusal line")
		else:
			assert_null(button, "a page below the threshold offers none")
			assert_not_null(reason, "a page below the threshold states why")
			assert_true(
				String(reason.text).contains(str(LevelUp.XP_THRESHOLD)),
				"the reason names the threshold",
			)
		if button != null:
			buttons += 1
	assert_eq(buttons, 1, "one button per eligible character")


# --------------------------------------------------------------------- steps

# 2
func test_the_steps_follow_the_class() -> void:
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	assert_eq(
		_strip_texts(),
		["Summary", "Ability", "Skills", "Feat", "Confirm"],
		"a fighter sees Summary, Ability, Skills, Feat, Confirm",
	)
	main.call("close_modal")
	await wait_frames(3)
	await _open_level_up(1)
	assert_eq(
		_strip_texts(),
		["Summary", "Ability", "Skills", "Confirm"],
		"a rogue sees neither Feat nor Spells",
	)
	main.call("close_modal")
	await wait_frames(3)
	await _open_level_up(3)
	assert_eq(
		_strip_texts(),
		["Summary", "Ability", "Skills", "Spells", "Confirm"],
		"a sorcerer sees Spells and no Feat",
	)


# 3
func test_summary_matches_the_preview() -> void:
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	var ch := _character(0)
	var preview := LevelUp.preview(ch, {})
	var hp: Dictionary = preview["hit_points"]
	assert_true(
		_summary_text("SummaryHP").contains("%d/%d -> %d/%d" % [
			int(hp["hp_before"]), int(hp["max_before"]), int(hp["hp_after"]), int(hp["max_after"])
		]),
		"the summary repeats the preview HP",
	)
	var bab: Dictionary = preview["base_attack"]
	assert_true(
		_summary_text("SummaryBAB").contains("+%d -> +%d" % [int(bab["before"]), int(bab["after"])]),
		"the summary repeats the preview base attack",
	)
	var saves: Dictionary = preview["base_saves"]
	for save in ["fort", "ref", "will"]:
		var entry: Dictionary = saves[save]
		assert_true(
			_summary_text("Summary" + String(save).to_upper()).contains(
				"+%d -> +%d" % [int(entry["before"]), int(entry["after"])]
			),
			"the summary repeats the preview %s save" % save,
		)
	var choices := LevelChoices.choices(ch, {})
	assert_true(_summary_text("SummaryAbility").contains("1 point"), "the summary repeats the ability budget")
	assert_true(
		_summary_text("SummarySkills").contains(str(int(choices["skills"]["budget"]))),
		"the summary repeats the skill points",
	)
	assert_true(
		_summary_text("SummaryFeat").contains(str(int(choices["feat"]["granted"]))),
		"the summary repeats the feat slot",
	)
	main.call("close_modal")
	await wait_frames(3)
	await _open_level_up(3)
	var caster := _character(3)
	var spell_preview := LevelUp.preview(caster, {})
	var slots: Dictionary = spell_preview["spells"]["slots_after"]
	var before_slots: Dictionary = spell_preview["spells"]["slots_before"]
	var level_two: Dictionary = slots.get("2", {})
	var before_two: Dictionary = before_slots.get("2", {})
	assert_true(
		_summary_text("SummarySpells").contains("%d -> %d" % [
			int(before_two.get("max", 0)), int(level_two.get("max", 0))
		]),
		"the summary repeats the spell slots",
	)


# ----------------------------------------------------------------- navigation

# 4
func test_back_returns_to_the_previous_step_with_the_draft() -> void:
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	var back := _button_in(_modal(), "Back")
	assert_not_null(back, "Back is present")
	if back != null:
		assert_true(back.disabled, "Back is disabled on Summary")
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	await _press("Back")
	assert_eq(_step_title(), "Ability", "Back shows the Ability step")
	var chosen := _button_named("ability_str")
	assert_not_null(chosen, "the ability row is rebuilt")
	if chosen != null:
		assert_true(chosen.button_pressed, "the chosen ability is still selected")


# 5
func test_cancel_returns_to_the_sheet_without_applying() -> void:
	_all_eligible()
	await _open_sheet(0)
	var ch := _character(0)
	var before := ch.to_dict().duplicate(true)
	await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Cancel")
	await wait_frames(3)
	assert_null(main.current_screen.get("level_up_screen"), "the modal is closed")
	assert_eq(ch.to_dict(), before, "the character is unchanged")
	assert_not_null(_tabs(), "the sheet is open on the same page")
	if _tabs() != null:
		assert_eq(_tabs().current_tab, 0, "the sheet is open on the same page")
	assert_eq(_focus_owner(), _level_up_button(0), "focus returns to the Level up button")


# 6
func test_escape_closes_without_applying() -> void:
	_all_eligible()
	await _open_sheet(0)
	var ch := _character(0)
	var before := ch.to_dict().duplicate(true)
	await _open_level_up(0)
	_send_key(KEY_ESCAPE)
	await wait_frames(3)
	assert_null(main.current_screen.get("level_up_screen"), "Escape closes the modal")
	assert_eq(ch.to_dict(), before, "the character is unchanged")
	await _open_level_up(0)
	_send_echo(KEY_ESCAPE)
	await wait_frames(2)
	assert_not_null(main.current_screen.get("level_up_screen"), "a held Escape does nothing")


# -------------------------------------------------------------------- confirm

# 7
func test_confirm_applies_through_validate_and_apply() -> void:
	_all_eligible()
	await _open_sheet(0)
	var ch := _character(0)
	var screen := await _open_level_up(0)
	var preview := LevelUp.preview(ch, {"ability": "str", "feat": "Power Attack"})
	await _walk_to_confirm()
	await _press("Apply level up")
	var validated := screen.trace.find("LevelChoices.validate")
	var applied := screen.trace.find("LevelUp.apply")
	assert_true(validated >= 0, "validate ran before apply")
	assert_true(validated >= 0 and applied > validated, "validate ran before apply")
	assert_eq(screen.trace.count("LevelUp.apply"), 1, "apply ran once")
	assert_eq(ch.level, 4, "the level is 4")
	assert_eq(ch.max_hp, int(preview["hit_points"]["max_after"]), "the applied values match the preview")
	assert_eq(ch.base_attack, int(preview["base_attack"]["after"]), "the applied base attack matches")
	assert_eq(
		int(Dictionary(ch.base_saves)["fort"]),
		int(Dictionary(preview["base_saves"])["fort"]["after"]),
		"the applied fortitude save matches",
	)
	assert_true(ch.feats.has("Power Attack"), "the chosen feat is recorded")


# 8
func test_a_refused_confirm_keeps_the_modal_open_and_changes_nothing() -> void:
	_all_eligible()
	await _open_sheet(0)
	var ch := _character(0)
	var before := ch.to_dict().duplicate(true)
	await _open_level_up(0)
	await _walk_to_confirm(false)
	await _press("Apply level up")
	assert_not_null(main.current_screen.get("level_up_screen"), "the modal is still open")
	var refusal := _label_named("Refusal")
	assert_not_null(refusal, "the refusal label exists")
	if refusal != null:
		assert_true(refusal.visible, "the refusal message is shown")
		assert_true(refusal.text.contains("choose one"), "the refusal message is the engine's")
	assert_eq(ch.to_dict(), before, "the character is unchanged")
	var owner := _focus_owner()
	assert_not_null(owner, "a control takes focus")
	if owner != null:
		assert_true(owner.name.begins_with("feat_"), "focus moved to the refused group")
		assert_false((owner as Button).disabled, "focus landed on a control that can be chosen")
	assert_eq(_step_title(), "Feat", "the refusal shows the step that owns it")


# 9
func test_apply_is_not_called_when_validate_refuses() -> void:
	_all_eligible()
	await _open_sheet(0)
	var screen := await _open_level_up(0)
	await _walk_to_confirm(false)
	await _press("Apply level up")
	assert_eq(screen.trace.count("LevelUp.apply"), 0, "apply was not reached")
	assert_gt(screen.trace.count("LevelChoices.validate"), 0, "validate was reached")


# --------------------------------------------------------------------- skills

# 10
func test_the_skills_step_cannot_overspend() -> void:
	_all_eligible()
	await _open_sheet(0)
	var screen := await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	await _press_named("skill_climb")
	var header := _label_named("SpentHeader")
	assert_not_null(header, "the header reads the spend")
	if header != null:
		assert_eq(header.text, "Spent 1 of 2 points", "the header reads Spent 1 of 2 points")
	await _press_named("skill_climb")
	header = _label_named("SpentHeader")
	if header != null:
		assert_eq(header.text, "Spent 2 of 2 points", "the header reads Spent 2 of 2")
	var climb := _button_named("skill_climb")
	assert_not_null(climb, "the climb row is rebuilt")
	if climb != null:
		assert_true(climb.disabled, "a third point is refused")
		climb.pressed.emit()
		await wait_frames(2)
	assert_eq(int(Dictionary(screen.draft.get("skills", {})).get("climb", 0)), 2, "a third point is refused")
	main.call("close_modal")
	await wait_frames(3)
	# A row at its cap: the rogue's search is 6 of 7, so one point reaches it.
	await _open_level_up(1)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	await _press_named("skill_search")
	var capped := _button_named("skill_search")
	assert_not_null(capped, "the search row is rebuilt")
	if capped != null:
		assert_true(capped.disabled, "rows disable at their cap")
		assert_true(capped.text.contains("cap"), "the capped row states why")


# --------------------------------------------------------------------- feats

# 11
func test_the_fighter_feat_rows_carry_their_reasons() -> void:
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	await _press("Continue")
	var power := _button_named("feat_power_attack")
	assert_not_null(power, "Power Attack is offered")
	if power != null:
		assert_false(power.disabled, "Power Attack is offered")
	var cleave := _button_named("feat_cleave")
	assert_not_null(cleave, "Cleave is listed")
	if cleave != null:
		assert_true(cleave.disabled, "a row without its prerequisite is disabled")
		assert_true(cleave.text.contains("requires the Power Attack feat"), "the row states why")


# -------------------------------------------------------------------- layout

# 12
func test_the_modal_traps_focus_at_both_scales() -> void:
	for scale in [1.0, 1.6]:
		_set_scale(scale)
		_all_eligible()
		await _open_sheet(0)
		await _open_level_up(0)
		var modal := _modal()
		assert_not_null(modal, "the modal is open at %s" % scale)
		if modal == null:
			return
		for step in 60:
			_send_key(KEY_TAB)
			await wait_frames(1)
			var owner := _focus_owner()
			assert_not_null(owner, "Tab stop %d has focus at %s" % [step, scale])
			assert_true(modal.is_ancestor_of(owner), "focus never leaves the modal at %s" % scale)
		for step in 60:
			_send_key(KEY_TAB, true)
			await wait_frames(1)
			assert_true(modal.is_ancestor_of(_focus_owner()), "Shift+Tab stops inside at %s" % scale)
		main.call("close_modal")
		await wait_frames(3)
		_set_scale(original_scale)


# 13
func test_every_focusable_is_revealed_in_the_body_at_160_percent() -> void:
	_set_scale(1.6)
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	var pane := _step_scroll()
	assert_not_null(pane, "the step body exists")
	if pane == null:
		return
	var rows := _named(_modal(), "StepRows")
	assert_not_null(rows, "the step rows exist")
	if rows == null:
		return
	var checked := 0
	for control in main.call("_modal_focusables"):
		var target := control as Control
		# The header Close and the footer are outside the scrolling body by
		# design (C3); this check is about the rows the body scrolls.
		if not rows.is_ancestor_of(target):
			continue
		checked += 1
		target.grab_focus()
		await wait_frames(2)
		assert_true(_fully_inside(target, pane), "the focused row is fully inside the body")
	assert_gt(checked, 0, "the step has rows to reveal")


# 14
func test_the_panel_and_footer_fit_the_window_at_160_percent() -> void:
	_set_scale(1.6)
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	var pane := _step_scroll()
	var footer := _named(_modal(), "Footer")
	var panel := _panel_of(_named(_modal(), "LevelUpBody"))
	assert_not_null(pane, "the step body exists")
	assert_not_null(footer, "the footer exists")
	assert_not_null(panel, "the panel exists")
	if pane == null or footer == null or panel == null:
		return
	var window := main.get_viewport_rect()
	assert_true(window.encloses(panel.get_global_rect()), "the panel fits the client area")
	assert_true(_contains_rect(panel, footer), "the footer fits the panel")
	assert_false(_contains_rect(pane, footer), "the footer is outside the scrolling body")
	var step_bar := pane.get_h_scroll_bar()
	assert_true(step_bar.max_value <= step_bar.page, "the step body needs no horizontal scrolling")
	var body := main.get("modal_scroll") as ScrollContainer
	if body != null:
		var bar := body.get_h_scroll_bar()
		assert_true(bar.max_value <= bar.page, "no horizontal scrollbar")


# 15
func test_the_strip_and_rows_wrap_without_clipping() -> void:
	_set_scale(1.6)
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	var strip := _named(_modal(), "StepStrip")
	assert_not_null(strip, "the step strip exists")
	if strip != null:
		for child in strip.get_children():
			var label := child as Label
			if label == null:
				continue
			assert_true(
				label.get_minimum_size().x <= label.size.x + 0.5,
				"the step label is not clipped",
			)
			assert_true(_contains_rect(strip, label), "the step label is inside the strip")
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	var pane := _step_scroll()
	assert_not_null(pane, "the step body exists")
	if pane == null:
		return
	for child in _named(_modal(), "StepRows").get_children():
		var row := child as Control
		if row == null:
			continue
		assert_true(row.size.x <= pane.size.x + 1.0, "the skill row is not wider than the body")
		break


# 16
func test_the_body_scrolls_for_the_skills_step_at_160_percent() -> void:
	_set_scale(1.6)
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	var pane := _step_scroll()
	assert_not_null(pane, "the step body exists")
	if pane == null:
		return
	assert_gt(_travel(pane), 0, "the Skills step is taller than its body")
	var rows := _named(_modal(), "StepRows")
	var last: Control = null
	for child in rows.get_children():
		if child is Button and not (child as Button).disabled:
			last = child as Control
	assert_not_null(last, "the Skills step offers a row")
	if last == null:
		return
	last.grab_focus()
	await wait_frames(3)
	assert_true(_fully_inside(last, pane), "the last row is revealed")


# ------------------------------------------------- extra 4a acceptance tests

# 17
func test_the_draft_survives_a_modal_rebuild_and_focus_restore() -> void:
	_all_eligible()
	await _open_sheet(0)
	await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	await _press_named("skill_climb")
	# A rebuild is what a text-scale change and every row press both do.
	main.call("refresh_modal")
	await wait_frames(3)
	assert_eq(_step_title(), "Skills", "the rebuild keeps the step")
	var header := _label_named("SpentHeader")
	assert_not_null(header, "the spend header survives the rebuild")
	if header != null:
		assert_eq(header.text, "Spent 1 of 2 points", "the rebuild keeps the allocation")
	var owner := _focus_owner()
	assert_not_null(owner, "a control holds focus after the rebuild")
	if owner != null:
		assert_eq(owner.name, "skill_climb", "the rebuild restores focus to the chosen row")
	await _press("Back")
	var chosen := _button_named("ability_str")
	assert_not_null(chosen, "the ability step is rebuilt")
	if chosen != null:
		assert_true(chosen.button_pressed, "the draft's ability survives the rebuild")


# 18
func test_a_stale_page_cannot_apply_after_the_character_has_leveled() -> void:
	_all_eligible()
	await _open_sheet(0)
	var ch := _character(0)
	var screen := await _open_level_up(0)
	await _walk_to_confirm()
	# Another surface spends the step while this screen still shows Confirm.
	var elsewhere := LevelUp.apply(ch, {"ability": "str", "feat": "Power Attack"})
	assert_true(bool(elsewhere.get("ok", false)), "another surface applied the step")
	assert_eq(ch.level, 4, "the character is level 4")
	var after := ch.to_dict().duplicate(true)
	await _press("Apply level up")
	assert_not_null(main.current_screen.get("level_up_screen"), "the stale modal stays open")
	assert_eq(ch.to_dict(), after, "the stale draft changes nothing")
	assert_eq(screen.trace.count("LevelUp.apply"), 0, "the stale screen never applies")
	var refusal := _label_named("Refusal")
	assert_not_null(refusal, "the refusal label exists")
	if refusal != null:
		assert_true(refusal.visible, "the refusal message is shown")
		assert_true(refusal.text.contains("already"), "the refusal is the engine's")


# 19
func test_a_confirm_writes_only_the_intended_character_fields() -> void:
	_all_eligible()
	await _open_sheet(0)
	var ch := _character(0)
	var before := ch.to_dict().duplicate(true)
	var others := {}
	for member in Game.party:
		others[member.id] = member.to_dict().duplicate(true)
	await _open_level_up(0)
	await _press("Continue")
	await _press_named("ability_str")
	await _press("Continue")
	await _press_named("skill_climb")
	await _press("Continue")
	await _press_named("feat_power_attack")
	await _press("Continue")
	await _press("Apply level up")
	var after := ch.to_dict()
	var changed: Array[String] = []
	for key in after.keys():
		if after[key] != before.get(key):
			changed.append(String(key))
	changed.sort()
	assert_eq(changed, [
		"abilities", "base_attack", "base_saves", "feats", "hp", "level", "max_hp", "skill_ranks"
	], "the level-up writes only the fields it owns")
	assert_eq(after["xp"], before["xp"], "the level step awards no XP")
	for member in Game.party:
		if member.id == ch.id:
			continue
		assert_eq(member.to_dict(), others[member.id], "%s is unchanged" % member.display_name)


# 20
## C7's keyboard half. The plan promises that End, like PageDown, scrolls the step
## body (LEVEL_UP_PLAN.md 14.5); the body used to ignore it, so the last Skills row
## could only be reached by Tabbing to it.
func test_end_scrolls_the_skills_body_to_its_last_row_at_both_scales() -> void:
	for scale in [1.0, 1.6]:
		_set_scale(scale)
		_all_eligible()
		await _open_sheet(0)
		await _open_level_up(0)
		await _press("Continue")
		await _press_named("ability_str")
		await _press("Continue")
		var pane := _step_scroll()
		var rows := _named(_modal(), "StepRows")
		assert_not_null(pane, "the step body exists at %s" % scale)
		assert_not_null(rows, "the step rows exist at %s" % scale)
		if pane == null or rows == null:
			continue
		var travel := _travel(pane)
		var last: Control = null
		for child in rows.get_children():
			if child is Button:
				last = child as Control
		assert_not_null(last, "the Skills step offers rows at %s" % scale)
		if last == null:
			continue
		assert_gt(travel, 0, "the Skills step is taller than its body at %s" % scale)
		_send_key(KEY_END)
		await wait_frames(3)
		assert_eq(pane.scroll_vertical, travel, "End takes the body to its last row at %s" % scale)
		assert_true(_fully_inside(last, pane), "End reveals the last row at %s" % scale)
		main.call("close_modal")
		await wait_frames(3)
		_set_scale(original_scale)
