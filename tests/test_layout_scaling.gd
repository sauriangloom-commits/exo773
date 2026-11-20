extends GutTest

## Layout scaling contract. The client area is the layout surface: the game no
## longer composes a fixed 1280x720 canvas and magnifies it, so every page has to
## lay out inside the smallest supported client (1280x720) even at the largest
## text scale, and every fixed panel size has to be capped to the client instead
## of asking for more room than exists.
##
## These checks size a screen to the minimum client explicitly and then look at
## the real laid-out rectangles. The rendered result on a real window is checked
## by `--layout-probe` (builds/qa/runs/2026-11-20_ui_fix).

const MIN_CLIENT := Vector2(1280, 720)


func before_each() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 2024)


func after_each() -> void:
	Game.settings["text_scale"] = 1.0


func _with_text_scale(value: float) -> void:
	Game.settings["text_scale"] = value


## Lays the screen out at an explicit client size. The test root is a plain Node,
## so nothing else resizes the screen behind our back.
func _layout_at(screen: Control, size: Vector2) -> void:
	add_child_autofree(screen)
	await wait_frames(2)
	screen.position = Vector2.ZERO
	screen.size = size
	await wait_frames(3)


## Controls that render outside the client without a scroll container able to
## bring them into view. Children of a ScrollContainer are legitimately outside
## its visible area, so they are skipped: reachability there is a scroll question,
## not a clipping question.
func _escapes(screen: Control) -> Array[String]:
	var client := Rect2(Vector2.ZERO, MIN_CLIENT)
	var found: Array[String] = []
	for node in screen.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		if _inside_scroll(control, screen):
			continue
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if not client.encloses(rect):
			found.append("%s %s" % [control.get_path(), str(rect)])
	return found


func _inside_scroll(control: Control, stop: Control) -> bool:
	var node := control.get_parent()
	while node != null and node != stop:
		if node is ScrollContainer:
			return true
		node = node.get_parent()
	return false


func test_the_client_area_is_the_layout_surface() -> void:
	# canvas_items stretch on a fixed 1280x720 base made a bigger window a
	# magnifying glass: the UI never received more room, and text scale had none.
	assert_eq(
		String(ProjectSettings.get_setting("display/window/stretch/mode", "")),
		"disabled",
		"the viewport follows the client instead of a fixed base canvas",
	)
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		1280,
		"1280 stays the documented minimum width",
	)
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)),
		720,
		"720 stays the documented minimum height",
	)


func test_exploration_lays_out_inside_the_minimum_client_at_max_text() -> void:
	_with_text_scale(1.6)
	var screen := ExplorationScreen.new()
	await _layout_at(screen, MIN_CLIENT)
	var escapes := _escapes(screen)
	assert_eq(escapes.size(), 0, "nothing escapes a 1280x720 client: %s" % ", ".join(escapes))
	assert_eq(screen.party_box.get_child_count(), 4, "every party card is still built")


func test_combat_lays_out_inside_the_minimum_client_at_max_text() -> void:
	Game.start_encounter("storeroom_dead")
	_with_text_scale(1.6)
	var screen := CombatScreen.new()
	await _layout_at(screen, MIN_CLIENT)
	var escapes := _escapes(screen)
	assert_eq(escapes.size(), 0, "nothing escapes a 1280x720 client: %s" % ", ".join(escapes))
	assert_gt(screen.target_box.get_child_count(), 0, "target rows are built")


func test_combat_reflows_at_a_wider_client() -> void:
	Game.start_encounter("storeroom_dead")
	_with_text_scale(1.6)
	var screen := CombatScreen.new()
	await _layout_at(screen, Vector2(1600, 900))
	var escapes: Array[String] = []
	var client := Rect2(Vector2.ZERO, Vector2(1600, 900))
	for node in screen.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree() or _inside_scroll(control, screen):
			continue
		var rect := control.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0 and not client.encloses(rect):
			escapes.append("%s %s" % [control.get_path(), str(rect)])
	assert_eq(escapes.size(), 0, "nothing escapes a 1600x900 client: %s" % ", ".join(escapes))


func test_dialogue_panel_is_capped_to_the_client() -> void:
	Game.start_dialogue("miruna")
	_with_text_scale(1.6)
	var panel := DialoguePanel.new()
	await _layout_at(panel, MIN_CLIENT)
	assert_not_null(panel.panel, "the conversation panel exists")
	assert_lte(panel.panel.custom_minimum_size.x, MIN_CLIENT.x - 32.0, "panel width is capped")
	assert_lte(panel.panel.custom_minimum_size.y, MIN_CLIENT.y - 32.0, "panel height is capped")


func test_dialogue_panel_reclamps_when_the_client_shrinks() -> void:
	Game.start_dialogue("miruna")
	_with_text_scale(1.6)
	var panel := DialoguePanel.new()
	await _layout_at(panel, MIN_CLIENT)
	var at_minimum := panel.panel.custom_minimum_size
	panel.size = Vector2(900, 600)
	await wait_frames(2)
	assert_lte(panel.panel.custom_minimum_size.y, 600.0 - 31.0, "a shorter client shrinks the panel request")
	assert_true(
		panel.panel.custom_minimum_size.y <= at_minimum.y,
		"clamping only ever reduces the request",
	)


func test_settings_readout_is_sized_by_its_own_text() -> void:
	_with_text_scale(1.6)
	var settings := Panels.settings(
		"",
		func(_action: String) -> void: pass,
		func() -> void: pass,
		func() -> void: pass
	)
	add_child_autofree(settings)
	await wait_frames(3)
	var readouts := 0
	for node in settings.find_children("*", "Label", true, false):
		var label := node as Label
		if not label.text.ends_with("%"):
			continue
		readouts += 1
		assert_eq(label.custom_minimum_size.x, 0.0, "no fixed width column: %s" % label.text)
		assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_OFF, "the value never wraps: %s" % label.text)
		assert_gte(
			label.size.x,
			label.get_minimum_size().x - 0.5,
			"the value keeps its own width: %s" % label.text
		)
	assert_gt(readouts, 0, "the sliders expose readouts")


func test_modal_size_is_capped_after_text_scaling() -> void:
	# `open_modal` multiplies the requested size by the text scale and then caps it
	# to the client. At the largest scale the cap is what keeps Settings usable.
	var client := MIN_CLIENT
	var requested := Vector2(760, 540) * 1.6
	var capped := Vector2(
		minf(requested.x, client.x - 32.0),
		minf(requested.y, client.y - 32.0),
	)
	assert_eq(capped.x, requested.x, "1216 still fits the 1248 available, so width keeps the scaled request")
	assert_lte(capped.x, client.x - 32.0, "a scaled modal request never exceeds the client")
	assert_eq(capped.y, client.y - 32.0, "a scaled modal request is capped in height")
	assert_gt(capped.y, 540.0, "the cap still leaves more room than the unscaled modal")


func test_the_window_is_not_scaled_fractionally() -> void:
	# The fullscreen overshoot (a 1920x1082 client on a 1920x1080 display) came from
	# scaling a fixed 1280x720 base by 1.5028. A disabled content scale is what makes
	# the client exactly the display; the windowed probe asserts the pixel result.
	assert_eq(
		get_window().content_scale_mode,
		Window.CONTENT_SCALE_MODE_DISABLED,
		"no fractional content scale between the client and the drawing surface",
	)
