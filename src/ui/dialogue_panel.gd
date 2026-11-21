class_name DialoguePanel
extends Control

## Dialogue presentation. All text comes from content/dialogue/*.json.
## Speaker identity is always shown as a labeled badge, and gated options
## remain visible with an explanation rather than disappearing silently.

var main: Control
## The framed conversation panel. Its minimum is capped to the client area, so a
## raised text scale or a resize can never push it past a window edge; the body
## scrolls instead.
var panel: PanelContainer
## The body scroller, kept so keyboard traversal can reveal the focused choice.
var scroll: ScrollContainer
## Choice buttons in content order, including unavailable ones (skipped by focus).
var choice_buttons: Array[Button] = []
## Full-viewport backdrop. It only dims: clicks pass through to the HUD panels
## that stay readable during a conversation.
var dim: ColorRect
## The framed panel starts below the HUD header (63 px at 160 %), so seed and
## gold readouts of any length stay visible instead of sitting under the panel.
## The header can grow when long readouts squeeze the location title, so the
## clearance is measured rather than assumed.
const PANEL_TOP := 72.0
const HEADER_GAP := 8.0
## The HUD header this panel measures; its resize moves the panel when long
## readouts add a line.
var watched_header: HBoxContainer
var leave_button: Button
## Last control inside this panel to take focus. A HUD click moves the ring to
## the HUD button, so this is what a closing HUD panel returns to.
var last_focus: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The overlay itself must not swallow clicks outside the framed panel: the
	# read-only HUD panels and Pause stay usable while a conversation is open.
	# IGNORE (not PASS) is required: a PASS cover still wins the mouse pick and
	# keeps the HUD behind it unreachable.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_clamp_panel)
	resized.connect(_clamp_panel)
	_rebuild()
	_watch_header()


## Panel origin: below the real header bottom, never above the base clearance.
func _panel_top() -> float:
	var top := PANEL_TOP
	if main != null and is_instance_valid(main):
		var screen: Node = main.get("current_screen")
		if screen is ExplorationScreen:
			var hud := (screen as ExplorationScreen).header
			if hud != null and is_instance_valid(hud) and hud.is_inside_tree():
				top = maxf(top, hud.get_global_rect().end.y + HEADER_GAP)
	return top


## Largest panel that still leaves a 16 px edge inside the current client area
## and starts below the header. The control is anchored full-rect, so its own
## size is the client area once layout has run; before the first layout it falls
## back to the viewport size.
func _panel_minimum() -> Vector2:
	var area := size
	if area.x <= 0.0 or area.y <= 0.0:
		area = get_viewport_rect().size
	var space := Vector2(area.x - 32.0, area.y - _panel_top() - 16.0)
	return Vector2(minf(860.0, maxf(space.x, 320.0)), minf(600.0, maxf(space.y, 240.0)))


## Called when the client area changes while a conversation is open: the panel
## keeps its proportion instead of remembering the size it was built at.
func _clamp_panel() -> void:
	if panel != null and is_instance_valid(panel):
		# A lower minimum does not shrink an existing Control, so set both.
		var fitted := _panel_minimum()
		panel.custom_minimum_size = fitted
		panel.size = fitted
		panel.position = Vector2(16, _panel_top())


func refresh() -> void:
	_rebuild()


## Header height is not constant: long gold/seed readouts can squeeze the
## location title onto more lines, so follow its resizes too.
func _watch_header() -> void:
	if main == null or not is_instance_valid(main):
		return
	var screen: Node = main.get("current_screen")
	if not screen is ExplorationScreen:
		return
	var hud := (screen as ExplorationScreen).header
	if hud == null or hud == watched_header:
		return
	if watched_header != null and is_instance_valid(watched_header):
		if watched_header.resized.is_connected(_clamp_panel):
			watched_header.resized.disconnect(_clamp_panel)
	hud.resized.connect(_clamp_panel)
	watched_header = hud


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	scroll = null
	dim = null
	leave_button = null
	last_focus = null
	choice_buttons.clear()
	if Game.dialogue == null:
		return
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	panel = PanelContainer.new()
	panel.custom_minimum_size = _panel_minimum()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.position = Vector2(16, _panel_top())
	layer.add_child(panel)
	_clamp_panel.call_deferred()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Tab and Shift+Tab move through the choices below; the scroller must bring the
	# new focus owner into view instead of leaving it below the fold.
	scroll.follow_focus = true
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)
	var kind := Game.dialogue.speaker_kind()
	var badge_text := "NPC"
	match kind:
		"narrator":
			badge_text = "NARRATOR"
		"creature":
			badge_text = "CREATURE"
		"party":
			badge_text = "PARTY"
		_:
			badge_text = "NPC"
	var badge := Label.new()
	badge.text = "  %s  " % badge_text
	badge.add_theme_color_override("font_color", ThemeBuilder.BG)
	badge.add_theme_stylebox_override(
		"normal", _badge_style(ThemeBuilder.GOLD if kind == "creature" else ThemeBuilder.BLUE)
	)
	header.add_child(badge)
	var speaker := ThemeBuilder.heading(Game.dialogue.speaker_name(), 22)
	speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(speaker)
	var leave := Button.new()
	leave.text = "Leave conversation"
	leave.pressed.connect(_leave)
	leave.focus_entered.connect(_remember_focus.bind(leave))
	header.add_child(leave)
	leave_button = leave

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size = Vector2(0, 110)
	text.text = Game.dialogue.text()
	text.add_theme_font_size_override("normal_font_size", ThemeBuilder.fs(17))
	box.add_child(text)

	var check := Game.dialogue.last_skill_result
	if not check.is_empty():
		var check_label := ThemeBuilder.body(
			"%s check — d20(%d)%+d = %d vs DC %d: %s"
			% [
				String(check.get("actor", "Party")),
				int(check.get("roll", 0)),
				int(check.get("bonus", 0)),
				int(check.get("total", 0)),
				int(check.get("dc", 0)),
				"success" if bool(check.get("success", false)) else "failure",
			],
			true,
			14
		)
		check_label.add_theme_color_override(
			"font_color", ThemeBuilder.GOOD if bool(check.get("success", false)) else ThemeBuilder.DANGER
		)
		box.add_child(check_label)

	box.add_child(ThemeBuilder.separator())
	var choices := Game.dialogue_choices()
	if choices.is_empty():
		var continue_button := Button.new()
		continue_button.text = "Continue"
		continue_button.pressed.connect(_leave)
		continue_button.focus_entered.connect(_remember_focus.bind(continue_button))
		choice_buttons.append(continue_button)
		box.add_child(continue_button)
	else:
		var choice_box := VBoxContainer.new()
		choice_box.add_theme_constant_override("separation", 8)
		box.add_child(choice_box)
		for choice in choices:
			var button := Button.new()
			var label := String(choice["text"])
			if bool(choice.get("has_check", false)):
				var actor_name := String(choice.get("actor_name", ""))
				if not label.contains("DC"):
					label += "  [%s — %s]" % [String(choice.get("check_text", "")), actor_name]
				elif not actor_name.is_empty() and not label.contains(actor_name):
					label += "  — %s" % actor_name
			if not bool(choice.get("available", true)):
				label += "  — unavailable"
			button.text = label
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size = Vector2(0, 38)
			button.disabled = not bool(choice.get("available", true))
			if not bool(choice.get("available", true)):
				button.tooltip_text = String(choice.get("reason", "Not available yet."))
			var index := int(choice["index"])
			button.pressed.connect(func() -> void: _choose(index))
			button.focus_entered.connect(_remember_focus.bind(button))
			choice_box.add_child(button)
			choice_buttons.append(button)
	var hint := ThemeBuilder.body(
		"Example dialogue written for this project. Choices with skill checks name the adventurer who will roll.",
		true,
		13
	)
	box.add_child(hint)


func _badge_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _choose(index: int) -> void:
	var result := Game.dialogue_choose(index)
	if not bool(result.get("ok", false)):
		_rebuild()
		return
	if Game.mode != "dialogue":
		# Combat or exploration took over; the main screen router handles it.
		return
	_rebuild()


## Move the ring through this page's choices in content order, skipping rows the
## content rules left unavailable. Wraps at both ends and keeps the owner visible.
func cycle_focus(direction: int) -> void:
	var targets: Array[Button] = []
	for button in choice_buttons:
		if is_instance_valid(button) and not button.disabled:
			targets.append(button)
	if targets.is_empty():
		return
	var current := -1
	var owner_control := get_viewport().gui_get_focus_owner()
	for i in targets.size():
		if targets[i] == owner_control:
			current = i
			break
	var next := 0 if direction > 0 else targets.size() - 1
	if current != -1:
		next = posmod(current + direction, targets.size())
	targets[next].grab_focus()
	if scroll != null and is_instance_valid(scroll):
		scroll.ensure_control_visible(targets[next])


## Scroll one visible page (90 %) without touching the focus ring. Clamped to the
## body's real travel, so PageUp at the top and PageDown at the bottom do nothing.
func scroll_page(direction: int) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	var bar := scroll.get_v_scroll_bar()
	var step := maxi(1, int(round(bar.page * 0.9)))
	var travel := maxi(0, int(bar.max_value - bar.page))
	scroll.scroll_vertical = clampi(scroll.scroll_vertical + step * direction, 0, travel)


func _remember_focus(control: Control) -> void:
	last_focus = control


## Control a closing HUD panel returns to: the last dialogue control that held
## the ring, then the first available choice, then Leave. Null only when the
## panel has no usable control at all.
func return_target() -> Control:
	# last_focus can already be freed by a rebuild; test it before the typed call.
	if is_instance_valid(last_focus) and _can_focus(last_focus):
		return last_focus
	for button in choice_buttons:
		if _can_focus(button) and not button.disabled:
			return button
	if _can_focus(leave_button):
		return leave_button
	return null


func _can_focus(control: Control) -> bool:
	return (
		control != null
		and is_instance_valid(control)
		and control.is_inside_tree()
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
	)


func _leave() -> void:
	if Game.dialogue != null:
		Game.dialogue.finish_now()
