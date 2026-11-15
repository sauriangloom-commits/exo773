class_name DialoguePanel
extends Control

## Dialogue presentation. All text comes from content/dialogue/*.json.
## Speaker identity is always shown as a labeled badge, and gated options
## remain visible with an explanation rather than disappearing silently.

var main: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild()


func refresh() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	if Game.dialogue == null:
		return
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, minf(600.0, get_viewport_rect().size.y - 32.0))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	header.add_child(leave)

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
			choice_box.add_child(button)
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


func _leave() -> void:
	if Game.dialogue != null:
		Game.dialogue.finish_now()
