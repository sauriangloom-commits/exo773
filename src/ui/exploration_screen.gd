class_name ExplorationScreen
extends Control

## Exploration presentation: first-person view, party status, action bar,
## narration log, quest tracker and dialogue overlay.

var main: Control
var view: FirstPersonView
var log_label: RichTextLabel
var party_box: VBoxContainer
var quest_label: Label
var location_label: Label
var status_label: Label
var gold_label: Label
var dialogue_panel: DialoguePanel = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Game.log_added.connect(_on_log_added)
	Game.state_changed.connect(_on_state_changed)
	refresh_screen()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# Header.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	location_label = ThemeBuilder.heading("", 20)
	location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	location_label.custom_minimum_size.x = 0
	header.add_child(location_label)
	gold_label = ThemeBuilder.short("Gold: %d gp" % Game.gold, true, 13)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(gold_label)
	var seed_label := ThemeBuilder.short("Seed: %d" % Game.seed_value, true, 13)
	seed_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(seed_label)
	var pause := Button.new()
	pause.text = "Pause (Esc)"
	pause.pressed.connect(func() -> void: _open_pause())
	header.add_child(pause)

	# Body: view + sidebar.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	view = FirstPersonView.new()
	view.custom_minimum_size = Vector2(0, 140)
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(view)
	status_label = ThemeBuilder.body("", true, 13)
	left.add_child(status_label)

	var actions := GridContainer.new()
	actions.columns = 4
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	left.add_child(actions)
	_add_action(actions, "Turn left (Q)", func() -> void:
		Game.turn_left()
		refresh_screen()
	)
	_add_action(actions, "Forward (W)", func() -> void: _do(Game.move_forward()))
	_add_action(actions, "Turn right (E)", func() -> void:
		Game.turn_right()
		refresh_screen()
	)
	_add_action(actions, "Interact (F)", func() -> void: _do(Game.interact()))
	_add_action(actions, "Strafe left (A)", func() -> void: _do(Game.strafe_left()))
	_add_action(actions, "Back (S)", func() -> void: _do(Game.move_back()))
	_add_action(actions, "Strafe right (D)", func() -> void: _do(Game.strafe_right()))
	_add_action(actions, "Look", func() -> void: _look())
	_add_action(actions, "Take 10 check", func() -> void: _do(Game.interact_with_take(10)))
	_add_action(actions, "Take 20 check", func() -> void: _do(Game.interact_with_take(20)))

	# Sidebar. One outer scroll keeps every party member, the objective and the
	# quick actions reachable when text scaling raises the minimum height.
	var sidebar_scroll := ScrollContainer.new()
	sidebar_scroll.custom_minimum_size = Vector2(350, 0)
	sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sidebar_scroll)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(350, 0)
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation", 8)
	sidebar_scroll.add_child(sidebar)
	var party_header := HBoxContainer.new()
	sidebar.add_child(party_header)

	# Quick actions sit above the party list. At 1280x720 with raised text scale
	# the sidebar scrolls, and Save must never be the control that falls below the fold.
	var quick := GridContainer.new()
	quick.columns = 2
	quick.add_theme_constant_override("h_separation", 6)
	quick.add_theme_constant_override("v_separation", 6)
	sidebar.add_child(quick)
	_add_action(quick, "Sheet (C)", func() -> void: _open_party(0))
	_add_action(quick, "Inventory (I)", func() -> void: _open_inventory())
	_add_action(quick, "Journal (J)", func() -> void: _open_journal())
	_add_action(quick, "Save game", func() -> void: main._open_save_modal())
	var party_title := ThemeBuilder.heading("Party", 20)
	party_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_header.add_child(party_title)
	var party_button := Button.new()
	party_button.text = "Party (Tab)"
	party_button.pressed.connect(func() -> void: _open_party(0))
	party_header.add_child(party_button)
	party_box = VBoxContainer.new()
	party_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_box.add_theme_constant_override("separation", 6)
	sidebar.add_child(party_box)
	var quest_panel := PanelContainer.new()
	sidebar.add_child(quest_panel)
	var quest_margin := MarginContainer.new()
	quest_margin.add_theme_constant_override("margin_left", 8)
	quest_margin.add_theme_constant_override("margin_right", 8)
	quest_margin.add_theme_constant_override("margin_top", 6)
	quest_margin.add_theme_constant_override("margin_bottom", 6)
	quest_panel.add_child(quest_margin)
	var quest_box := VBoxContainer.new()
	quest_margin.add_child(quest_box)
	var quest_title := ThemeBuilder.heading("Objective", 16)
	quest_box.add_child(quest_title)
	quest_label = ThemeBuilder.body("", true, 12)
	quest_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_box.add_child(quest_label)

	# Narration log. The label scrolls inside the panel, so the panel only reserves
	# two lines at the maximum text size instead of a fixed 140 logical pixels that
	# made the whole page taller than a 1280x720 client.
	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(0, 80)
	root.add_child(log_panel)
	var log_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		log_margin.add_theme_constant_override("margin_" + side, 8)
	log_panel.add_child(log_margin)
	log_label = RichTextLabel.new()
	log_label.scroll_following = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.add_theme_font_size_override("normal_font_size", ThemeBuilder.fs(13))
	log_margin.add_child(log_label)


func _add_action(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)


func _do(_result: Variant) -> void:
	refresh_screen()


func _look() -> void:
	Game.log(Game.look())
	refresh_screen()


func _on_log_added(_text: String) -> void:
	refresh_log()


func _on_state_changed() -> void:
	refresh_screen()


func refresh_screen() -> void:
	if Game.dungeon == null:
		return
	location_label.text = Game.dungeon.display_name
	if gold_label != null:
		gold_label.text = "Gold: %d gp" % Game.gold
	var target := Game.dungeon.front_target(Game.position, Game.facing)
	var target_text := ""
	match String(target.get("kind", "")):
		"npc":
			target_text = " • facing: %s" % String(target["data"].get("name", "someone"))
		"object":
			target_text = " • facing: %s" % String(target["data"].get("name", "something"))
		"door":
			target_text = " • facing: %s" % String(target["data"].get("name", "a door"))
		"wall":
			target_text = " • facing: stone wall"
		_:
			target_text = " • facing: open floor"
	status_label.text = "Position %d,%d • Facing %s%s" % [
		Game.position.x,
		Game.position.y,
		Dungeon.FACING_NAMES[Game.facing].capitalize(),
		target_text,
	]
	_rebuild_party()
	quest_label.text = Game.quest_tracker_text()
	refresh_log()
	if view != null:
		view.queue_redraw()
	if Game.mode == "dialogue" and Game.dialogue != null:
		show_dialogue()
	elif dialogue_panel != null and is_instance_valid(dialogue_panel):
		dialogue_panel.queue_free()
		dialogue_panel = null


func _rebuild_party() -> void:
	if party_box == null:
		return
	for child in party_box.get_children():
		child.queue_free()
	for i in Game.party.size():
		var ch: Character = Game.party[i]
		var card := PanelContainer.new()
		party_box.add_child(card)
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 6)
		card.add_child(margin)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		margin.add_child(box)
		var row := HBoxContainer.new()
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = ch.display_name
		name_label.add_theme_font_size_override("font_size", ThemeBuilder.fs(14))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(name_label)
		var vitals := ThemeBuilder.short("HP %d/%d · AC %d" % [ch.hp, ch.max_hp, Rules.armor_class(ch)], true, 10)
		vitals.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(vitals)
		var hp := ProgressBar.new()
		hp.max_value = maxf(1.0, float(ch.max_hp))
		hp.value = float(maxi(ch.hp, 0))
		hp.show_percentage = false
		hp.custom_minimum_size = Vector2(0, 7)
		box.add_child(hp)
		var states: Array[String] = []
		if ch.has_condition("dead"):
			states.append("DEAD")
		elif ch.has_condition("dying"):
			states.append("DYING")
		elif ch.has_condition("stable"):
			states.append("STABLE")
		elif ch.has_condition("unconscious"):
			states.append("UNCONSCIOUS")
		elif ch.has_condition("paralyzed"):
			states.append("PARALYZED")
		for effect in ch.effects:
			if String(effect.get("kind", "")) == "buff":
				states.append(String(effect.get("name", "")))
		if not states.is_empty():
			box.add_child(ThemeBuilder.body(" • ".join(states), false, 10))


func refresh_log() -> void:
	if log_label == null:
		return
	var start := maxi(0, Game.log_lines.size() - 120)
	var lines := Game.log_lines.slice(start)
	log_label.text = "\n".join(lines)
	log_label.scroll_to_line(maxi(0, log_label.get_line_count() - 1))


func show_dialogue() -> void:
	if Game.dialogue == null:
		return
	if dialogue_panel == null or not is_instance_valid(dialogue_panel):
		dialogue_panel = DialoguePanel.new()
		dialogue_panel.main = main
		add_child(dialogue_panel)
	else:
		dialogue_panel.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if main != null and main.modal != null:
		return
	if Game.mode != "explore":
		return
	if event.is_action_pressed("move_forward"):
		Game.move_forward()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_back"):
		Game.move_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("strafe_left"):
		Game.strafe_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("strafe_right"):
		Game.strafe_right()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("turn_left"):
		Game.turn_left()
		refresh_screen()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("turn_right"):
		Game.turn_right()
		refresh_screen()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		Game.interact()
		refresh_screen()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_party"):
		_open_party(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_sheet"):
		_open_party(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_inventory"):
		_open_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_journal"):
		_open_journal()
		get_viewport().set_input_as_handled()


func _open_party(index: int) -> void:
	main.open_modal("Party & Character Sheet", func() -> Control:
		return Panels.character_sheet(index)
	, 900, 620)


func _open_inventory() -> void:
	main.open_modal("Inventory & Equipment", func() -> Control:
		return Panels.inventory(main.refresh_modal)
	, 880, 600)


func _open_journal() -> void:
	main.open_modal("Journal", func() -> Control:
		return Panels.journal()
	, 800, 560)


func _open_pause() -> void:
	main._open_pause()
