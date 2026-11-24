class_name CombatScreen
extends Control

## Combat UI: initiative, action economy, targeting, spell/item selection and
## the full combat log. All resolution happens in Encounter/GameSession.

var main: Control
var view: CombatView
var log_label: RichTextLabel
var initiative_label: RichTextLabel
var active_label: Label
var message_label: Label
var turn_label: Label
var button_box: GridContainer
var target_box: VBoxContainer
var pending_action: Dictionary = {}
var attack_mode_box: HBoxContainer
var attack_mode_option: OptionButton
var selected_attack_mode := ""
var weapon_box: HBoxContainer
var shield_box: HBoxContainer
var weapon_label: Label
var weapon_option: OptionButton
var shield_option: OptionButton
var shield_ids: Array = []
var weapon_ids: Array = []
## Unarmed strikes deal nonlethal damage by default. A character with Improved
## Unarmed Strike may choose lethal without a penalty (PHB p.97); anyone else may
## still strike lethally at the printed -4 (PHB p.147). The choice only exists
## while the readied attack is the unarmed strike.
var unarmed_box: HBoxContainer
var unarmed_option: OptionButton
var selected_unarmed_damage := "nonlethal"
var power_attack_box: HBoxContainer
var power_attack_spin: SpinBox
var combat_expertise_box: HBoxContainer
var combat_expertise_spin: SpinBox
var combat_expertise_status: Label
## Fighting defensively has a selected state (pre-commitment, cancellable) and an
## active state (locked until the start of the next turn). Total defense is its
## own standard action; a selection may be replaced by it.
var fight_defensively_check: CheckBox
var fight_defensively_status: Label
var total_defense_button: Button
var _ui_actor_index := -1
var mode := "move"
var trip_weapon_check: CheckBox
## One button for both grapple exits: the holder releases for free, the held
## creature escapes with an opposed check. The label stays "Escape" because the
## enable map is keyed by button text (see _refresh_actions).
var grapple_exit_button: Button
var pin_button: Button
var decision_box: VBoxContainer
var sidebar_panel: ScrollContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
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
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := ThemeBuilder.heading("Combat — %s" % (Game.encounter.name if Game.encounter != null else ""), 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var pause := Button.new()
	pause.text = "Pause (Esc)"
	pause.pressed.connect(func() -> void: main._open_pause())
	header.add_child(pause)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	view = CombatView.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.custom_minimum_size = Vector2(0, 140)
	view.cell_clicked.connect(_on_cell_clicked)
	left.add_child(view)
	message_label = ThemeBuilder.body("", false, 14)
	message_label.custom_minimum_size = Vector2(0, 24)
	left.add_child(message_label)
	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(0, 90)
	left.add_child(log_panel)
	var log_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		log_margin.add_theme_constant_override("margin_" + side, 6)
	log_panel.add_child(log_margin)
	log_label = RichTextLabel.new()
	log_label.scroll_following = true
	log_label.add_theme_font_size_override("normal_font_size", ThemeBuilder.fs(12))
	log_margin.add_child(log_label)
	# The sidebar scrolls vertically so a tall decision panel stays reachable at
	# 1024x600 and at the largest text scale. Horizontal scrolling is disabled so
	# no child can grow a minimum width that pushes controls outside the window.
	var sidebar_scroll := ScrollContainer.new()
	sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Reserving the vertical bar keeps the content width constant. Without it a
	# wrapped status label changes the content height, which shows or hides the
	# bar, which changes the wrap width, which changes the height again — a
	# layout loop that starved the frame queue.
	sidebar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	sidebar_panel = sidebar_scroll
	body.add_child(sidebar_scroll)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(340, 0)
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation", 6)
	sidebar_scroll.add_child(sidebar)
	var init_panel := PanelContainer.new()
	init_panel.custom_minimum_size = Vector2(340, 90)
	sidebar.add_child(init_panel)
	var init_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		init_margin.add_theme_constant_override("margin_" + side, 8)
	init_panel.add_child(init_margin)
	initiative_label = RichTextLabel.new()
	initiative_label.bbcode_enabled = true
	initiative_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	initiative_label.add_theme_font_size_override("normal_font_size", ThemeBuilder.fs(12))
	init_margin.add_child(initiative_label)
	active_label = ThemeBuilder.body("", false, 13)
	sidebar.add_child(active_label)
	button_box = GridContainer.new()
	button_box.columns = 4
	button_box.add_theme_constant_override("h_separation", 6)
	button_box.add_theme_constant_override("v_separation", 6)
	sidebar.add_child(button_box)
	# Which carried weapon is readied. Inspecting the list is free; choosing a
	# different weapon goes through the encounter and costs a move action (PHB
	# p.142), so the control can never grant a silent equipment change.
	weapon_box = HBoxContainer.new()
	weapon_box.add_theme_constant_override("separation", 6)
	weapon_label = ThemeBuilder.body("Weapon", true, 11)
	weapon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_box.add_child(weapon_label)
	weapon_option = OptionButton.new()
	weapon_option.custom_minimum_size = Vector2(176, 0)
	weapon_option.item_selected.connect(_on_weapon_selected)
	weapon_box.add_child(weapon_option)
	weapon_box.visible = false
	sidebar.add_child(weapon_box)
	# Which shield is strapped on (PHB p.142). Readying uses a carried shield and
	# loosing unstraps and drops it on the current square, so neither choice is a
	# silent equipment swap and neither stores the shield away.
	shield_box = HBoxContainer.new()
	shield_box.add_theme_constant_override("separation", 6)
	var shield_label := ThemeBuilder.body("Shield", true, 11)
	shield_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shield_box.add_child(shield_label)
	shield_option = OptionButton.new()
	shield_option.custom_minimum_size = Vector2(176, 0)
	shield_option.item_selected.connect(_on_shield_selected)
	shield_box.add_child(shield_option)
	shield_box.visible = false
	sidebar.add_child(shield_box)
	attack_mode_box = HBoxContainer.new()
	attack_mode_box.add_theme_constant_override("separation", 6)
	var mode_label := ThemeBuilder.body("Attack mode", true, 11)
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attack_mode_box.add_child(mode_label)
	attack_mode_option = OptionButton.new()
	attack_mode_option.custom_minimum_size = Vector2(132, 0)
	attack_mode_option.item_selected.connect(_on_attack_mode_selected)
	attack_mode_box.add_child(attack_mode_option)
	attack_mode_box.visible = false
	sidebar.add_child(attack_mode_box)
	unarmed_box = HBoxContainer.new()
	unarmed_box.add_theme_constant_override("separation", 6)
	var unarmed_label := ThemeBuilder.body("Unarmed damage", true, 11)
	unarmed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unarmed_box.add_child(unarmed_label)
	unarmed_option = OptionButton.new()
	unarmed_option.custom_minimum_size = Vector2(176, 0)
	unarmed_option.item_selected.connect(_on_unarmed_damage_selected)
	unarmed_box.add_child(unarmed_option)
	unarmed_box.visible = false
	sidebar.add_child(unarmed_box)
	power_attack_box = HBoxContainer.new()
	power_attack_box.add_theme_constant_override("separation", 6)
	var power_label := ThemeBuilder.body("Power Attack", true, 11)
	power_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_attack_box.add_child(power_label)
	power_attack_spin = SpinBox.new()
	power_attack_spin.min_value = 0
	power_attack_spin.max_value = 0
	power_attack_spin.step = 1
	power_attack_spin.custom_minimum_size = Vector2(92, 0)
	power_attack_spin.value_changed.connect(_on_power_attack_changed)
	power_attack_box.add_child(power_attack_spin)
	power_attack_box.visible = false
	sidebar.add_child(power_attack_box)
	combat_expertise_box = HBoxContainer.new()
	combat_expertise_box.add_theme_constant_override("separation", 6)
	var expertise_label := ThemeBuilder.body("Combat Expertise", true, 11)
	expertise_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_expertise_box.add_child(expertise_label)
	combat_expertise_spin = SpinBox.new()
	combat_expertise_spin.min_value = 0
	combat_expertise_spin.max_value = 0
	combat_expertise_spin.step = 1
	combat_expertise_spin.custom_minimum_size = Vector2(92, 0)
	combat_expertise_spin.value_changed.connect(_on_combat_expertise_changed)
	combat_expertise_box.add_child(combat_expertise_spin)
	combat_expertise_box.visible = false
	sidebar.add_child(combat_expertise_box)
	combat_expertise_status = ThemeBuilder.body("", false, 10)
	combat_expertise_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_expertise_status.visible = false
	sidebar.add_child(combat_expertise_status)
	fight_defensively_check = CheckBox.new()
	fight_defensively_check.text = "Fight defensively"
	fight_defensively_check.add_theme_font_size_override("font_size", ThemeBuilder.fs(11))
	fight_defensively_check.toggled.connect(_on_fight_defensively_toggled)
	fight_defensively_check.visible = false
	sidebar.add_child(fight_defensively_check)
	fight_defensively_status = ThemeBuilder.body("", false, 10)
	fight_defensively_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fight_defensively_status.visible = false
	sidebar.add_child(fight_defensively_status)
	var trip_row := HBoxContainer.new()
	trip_row.add_theme_constant_override("separation", 6)
	var trip_label := ThemeBuilder.body("Trip weapon", true, 11)
	trip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trip_row.add_child(trip_label)
	trip_weapon_check = CheckBox.new()
	trip_weapon_check.text = "Use equipped trip weapon"
	trip_weapon_check.add_theme_font_size_override("font_size", ThemeBuilder.fs(11))
	trip_row.add_child(trip_weapon_check)
	sidebar.add_child(trip_row)
	# Message above a button row: a long autowrapped label in a horizontal box
	# gives the row an enormous minimum width, which squeezes the log and pushes
	# the buttons outside the window.
	decision_box = VBoxContainer.new()
	decision_box.add_theme_constant_override("separation", 6)
	sidebar.add_child(decision_box)
	_add_action_button("Move", func() -> void: _set_mode("move", "Click an empty square within your movement."))
	_add_action_button("5-ft step", func() -> void: _set_mode("step", "Click an adjacent square. A 5-foot step does not provoke."))
	# The short label keeps the four-column grid inside the sidebar's 340 px
	# minimum; a longer one widened the grid until the scroll container's
	# horizontal/vertical bars oscillated. The tooltip carries the full name.
	total_defense_button = _add_action_button("Defend", _on_total_defense)
	total_defense_button.tooltip_text = (
		"Total defense (PHB p.143): +4 dodge AC (+6 with 5 Tumble ranks), no attacks "
		+ "or opportunity attacks until the start of your next turn."
	)
	_add_action_button("Attack", func() -> void: _set_mode("attack", "Click an enemy within reach or range."))
	_add_action_button("Sheathe weapon", func() -> void: Game.combat_sheathe_weapon())
	_add_action_button("Load weapon", func() -> void: Game.combat_load_weapon())
	_add_action_button("Cast spell", _open_spells)
	_add_action_button("Use potion", _open_potions)
	_add_action_button("First aid", _open_first_aid)
	_add_action_button("Turn undead", _turn_undead)
	_add_action_button("Trip", _trip)
	_add_action_button("Bull rush", _bull_rush)
	_add_action_button("Grapple", _grapple)
	pin_button = _add_action_button("Pin", _pin)
	pin_button.tooltip_text = (
		"Hold the creature you are grappling immobile for 1 round (standard action). "
		+ "While pinning you cannot attack (PHB p.156)."
	)
	grapple_exit_button = _add_action_button("Escape", _grapple_exit)
	grapple_exit_button.tooltip_text = (
		"Escape a grapple with an opposed grapple check or Escape Artist, or let go "
		+ "for free if you are the one holding (PHB p.156)."
	)
	_add_action_button("Stand up", func() -> void: Game.combat_stand_up())
	_add_action_button("Pick up", _pick_up_here)
	_add_action_button("End turn", _end_turn)
	_add_action_button("Inspect", func() -> void: _inspect_active())
	turn_label = ThemeBuilder.body("", false, 11)
	sidebar.add_child(turn_label)
	sidebar.add_child(ThemeBuilder.body("Combatants — enemies first", true, 12))
	var target_scroll := ScrollContainer.new()
	target_scroll.custom_minimum_size = Vector2(0, 96)
	target_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(target_scroll)
	target_box = VBoxContainer.new()
	target_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_box.add_theme_constant_override("separation", 4)
	target_scroll.add_child(target_box)
	sidebar.add_child(ThemeBuilder.body(
		"Movement, attacks, AoOs, dying and spells follow D&D 3.5; see docs/SUPPORTED_FEATURES.md for scope.",
		true,
		11
	))


func _add_action_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 32)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", ThemeBuilder.fs(12))
	button.pressed.connect(callback)
	button_box.add_child(button)
	return button


func _on_state_changed() -> void:
	refresh_screen()


func refresh_screen() -> void:
	if Game.encounter == null:
		return
	var e := Game.encounter
	message_label.text = Game.last_ui_message
	if Game.last_ui_message == "":
		message_label.text = "Choose an action."
	initiative_label.text = _initiative_text()
	var active := e.active_entry()
	if active.is_empty() or e.finished:
		active_label.text = "Encounter finished: %s" % e.outcome
	else:
		var ch: Character = active["char"]
		# Nonlethal damage is tracked apart from hit points (PHB p.139), so it is
		# shown beside them instead of being folded into the HP total.
		var nonlethal := ""
		if ch.nonlethal > 0:
			nonlethal = " • nonlethal %d" % ch.nonlethal
		if ch.has_condition("staggered"):
			nonlethal += " • staggered"
		elif not ch.is_conscious():
			nonlethal += " • helpless"
		active_label.text = "%s — HP %d/%d%s • AC %d • Round %d • %s" % [
			ch.display_name,
			ch.hp,
			ch.max_hp,
			nonlethal,
			Rules.armor_class(ch),
			e.round_number,
			"party" if int(active["team"]) == Encounter.TEAM_PARTY else "enemy",
		]
	var turn_ch := e.active_character()
	var active_index := int(active["index"]) if not active.is_empty() else -1
	if active_index != _ui_actor_index:
		_ui_actor_index = active_index
		selected_attack_mode = ""
	var weapon: Dictionary = e._primary_weapon(turn_ch) if turn_ch != null else {}
	var can_choose_weapon := (
		turn_ch != null and not e.finished and e.is_player_turn() and not turn_ch.is_monster
	)
	weapon_box.visible = can_choose_weapon
	if can_choose_weapon:
		_sync_weapon_options(turn_ch, weapon)
	shield_box.visible = can_choose_weapon
	if can_choose_weapon:
		_sync_shield_options(turn_ch)
	var attack_modes: Array[String] = []
	if turn_ch != null:
		attack_modes = Rules.weapon_attack_modes(weapon)
	var unarmed_ready := turn_ch != null and bool(weapon.get("unarmed", false))
	var can_choose_unarmed := (
		unarmed_ready and not e.finished and e.is_player_turn() and not turn_ch.is_monster
	)
	unarmed_box.visible = can_choose_unarmed
	if can_choose_unarmed:
		_sync_unarmed_options(turn_ch)
	var can_choose_mode := (
		turn_ch != null and not e.finished and e.is_player_turn() and attack_modes.size() > 1
	)
	attack_mode_box.visible = can_choose_mode
	if can_choose_mode:
		_sync_attack_modes(attack_modes)
	else:
		selected_attack_mode = ""
	var can_power_attack := (
		turn_ch != null and not e.finished and Feats.power_attack_max(turn_ch) > 0
	)
	power_attack_box.visible = can_power_attack
	if can_power_attack:
		power_attack_spin.max_value = Feats.power_attack_max(turn_ch)
		power_attack_spin.set_value_no_signal(float(e.active_power_attack_amount()))
		power_attack_spin.editable = e.is_player_turn() and not bool(e.turn_state.get("standard_used", false))
	else:
		power_attack_spin.set_value_no_signal(0)
		power_attack_spin.editable = false
	var can_combat_expertise := (
		turn_ch != null and not e.finished and Feats.combat_expertise_max(turn_ch) > 0
	)
	combat_expertise_box.visible = can_combat_expertise
	combat_expertise_status.visible = can_combat_expertise
	if can_combat_expertise:
		var maximum := Feats.combat_expertise_max(turn_ch)
		var committed := e.combat_expertise_amount_for(active_index)
		var pending := e.combat_expertise_pending_for(active_index)
		combat_expertise_spin.max_value = maximum
		combat_expertise_spin.set_value_no_signal(float(committed if committed > 0 else pending))
		combat_expertise_spin.editable = (
			e.is_player_turn()
			and not bool(e.turn_state.get("standard_used", false))
			and committed == 0
		)
		if committed > 0:
			combat_expertise_status.text = (
				"Active: -%d attack / +%d dodge AC until the start of your next turn."
				% [committed, committed]
			)
		elif pending > 0:
			combat_expertise_status.text = (
				"Pending: -%d attack / +%d dodge AC; activates on a melee attack."
				% [pending, pending]
			)
		elif not e.is_player_turn():
			combat_expertise_status.text = "Not your turn; no Combat Expertise choice is active."
		elif bool(e.turn_state.get("standard_used", false)):
			combat_expertise_status.text = "Standard action spent; Combat Expertise was not activated."
		else:
			combat_expertise_status.text = (
				"Choose 0–%d before a melee attack; no benefit until that attack." % maximum
			)
	else:
		combat_expertise_spin.set_value_no_signal(0)
		combat_expertise_spin.editable = false
		combat_expertise_status.text = ""
	var can_defend := (
		turn_ch != null and not e.finished and e.is_player_turn() and not turn_ch.is_monster
	)
	fight_defensively_check.visible = can_defend
	fight_defensively_status.visible = can_defend
	if can_defend:
		var fd_active := e.fight_defensively_active_for(active_index)
		var fd_selected := e.fight_defensively_selected_for(active_index)
		var td_active := e.total_defense_active_for(active_index)
		var standard_spent := bool(e.turn_state.get("standard_used", false))
		var tumble := int(turn_ch.skill_ranks.get("tumble", 0)) >= 5
		var fd_bonus := 3 if tumble else 2
		var td_bonus := 6 if tumble else 4
		fight_defensively_check.set_pressed_no_signal(fd_active or fd_selected)
		# Locked once active: the stance cannot be cancelled before it expires.
		fight_defensively_check.disabled = fd_active or td_active or standard_spent
		if fd_active:
			fight_defensively_status.text = (
				"Active: -4 attack / +%d dodge AC until the start of your next turn; cannot be cancelled."
				% fd_bonus
			)
		elif fd_selected:
			fight_defensively_status.text = (
				"Selected: +%d dodge AC and -4 attack apply only when an attack is committed."
				% fd_bonus
			)
		elif td_active:
			fight_defensively_status.text = (
				"Total defense: +%d dodge AC; no attacks or opportunity attacks this round."
				% td_bonus
			)
		elif standard_spent:
			fight_defensively_status.text = "Standard action spent; no defensive action can start now."
		else:
			fight_defensively_status.text = (
				"Optional: +%d dodge AC for -4 on attacks, once an attack is committed."
				% fd_bonus
			)
	else:
		fight_defensively_check.set_pressed_no_signal(false)
		fight_defensively_check.disabled = true
		fight_defensively_status.text = ""
	if turn_ch != null and turn_ch.cleric_level() > 0:
		var status := Game.combat_can_turn_undead()
		turn_label.text = "Turn undead: %d of %d uses left today%s" % [
			turn_ch.turn_undead_remaining(),
			turn_ch.turn_undead_max_uses(),
			"" if bool(status.get("ok", false)) else " — " + String(status.get("reason", "")),
		]
	else:
		turn_label.text = "Turn undead: only a cleric can use this action."
	_rebuild_targets()
	_rebuild_decision()
	_refresh_log()
	view.mode = mode
	view.queue_redraw()
	_update_button_states()


func _initiative_text() -> String:
	var e := Game.encounter
	if e.order.is_empty():
		return "[b]Rolling initiative…[/b]"
	var lines: Array[String] = ["[b]Initiative — round %d[/b]" % e.round_number]
	for i in e.order:
		var entry: Dictionary = e.combatants[i]
		var ch: Character = entry["char"]
		var marker := "▶" if i == e.order[e.turn_ptr] else "  "
		var status := "dead" if ch.has_condition("dead") else ("dying" if ch.has_condition("dying") else "%d/%d HP" % [ch.hp, ch.max_hp])
		if ch.is_prone():
			status += " • prone"
		lines.append("%s %s — init %d — %s" % [marker, ch.display_name, int(entry["initiative"]), status])
	return "\n".join(lines)


func _rebuild_targets() -> void:
	for child in target_box.get_children():
		child.queue_free()
	var e := Game.encounter
	var ordered: Array = []
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			ordered.append(entry)
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_PARTY:
			ordered.append(entry)
	for entry in ordered:
		var ch: Character = entry["char"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var label := ThemeBuilder.body(
			"%s — %d/%d HP%s%s"
			% [
				ch.display_name,
				ch.hp,
				ch.max_hp,
				" (dead)" if ch.has_condition("dead") else "",
				" (prone)" if ch.is_prone() else "",
			],
			true,
			11
		)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var index := int(entry["index"])
		if int(entry["team"]) == Encounter.TEAM_ENEMY and not ch.has_condition("dead"):
			# The enemy panel reports the AC an attack would use right now, so it
			# is reachable from the same row as the attack itself.
			var inspect_enemy := Button.new()
			inspect_enemy.text = "Inspect"
			inspect_enemy.pressed.connect(func() -> void: _inspect_index(index))
			row.add_child(inspect_enemy)
			var attack := Button.new()
			attack.text = "Attack"
			attack.disabled = not _can_standard(e)
			attack.pressed.connect(func() -> void: _attack(index))
			row.add_child(attack)
		elif int(entry["team"]) == Encounter.TEAM_PARTY:
			var inspect := Button.new()
			inspect.text = "Inspect"
			inspect.pressed.connect(func() -> void: _inspect_index(index))
			row.add_child(inspect)
		target_box.add_child(row)
	if not e.ground_items.is_empty():
		target_box.add_child(ThemeBuilder.body("Ground", true, 11))
		var active_now := e.active_entry()
		var cell_now := (
			Vector2i(active_now["cell"]) if not active_now.is_empty() else Vector2i(-1, -1)
		)
		for i in e.ground_items.size():
			var ground: Dictionary = e.ground_items[i]
			var ground_row := HBoxContainer.new()
			var ground_label := ThemeBuilder.body(
				String(Dictionary(ground["item"]).get("name", "item")), true, 11
			)
			ground_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ground_row.add_child(ground_label)
			var pickup := Button.new()
			pickup.text = "Pick up"
			var here := Vector2i(ground["cell"]) == cell_now
			pickup.disabled = not here or not e.is_player_turn() or e.has_pending_decision()
			pickup.tooltip_text = (
				"Move action; provokes an opportunity attack (PHB p.141)."
				if here
				else "Stand in the item's square to pick it up."
			)
			pickup.pressed.connect(func() -> void: Game.combat_pick_up(i))
			ground_row.add_child(pickup)
			target_box.add_child(ground_row)


func _can_standard(e: Encounter) -> bool:
	var ch := e.active_character()
	# PHB p.147: staggered creatures take a standard action or a move action, never
	# both, so a staggered character that already moved cannot use a standard action.
	if ch != null and ch.has_condition("staggered") and bool(e.turn_state.get("move_used", false)):
		return false
	return (
		e.is_player_turn()
		and not bool(e.turn_state.get("standard_used", false))
		and not e.has_pending_decision()
	)


func _update_button_states() -> void:
	var e := Game.encounter
	var player_turn := e.is_player_turn()
	var standard := _can_standard(e)
	var moved := bool(e.turn_state.get("move_used", false))
	var five_foot_used := bool(e.turn_state.get("five_foot_used", false))
	# A second move action may spend the standard action (double move). A
	# 5-foot step instead forbids any further movement this turn.
	var staggered_actor := e.active_character()
	var staggered := staggered_actor != null and staggered_actor.has_condition("staggered")
	var moves := (
		player_turn
		and not five_foot_used
		and not (moved and bool(e.turn_state.get("standard_used", false)))
		and not (staggered and bool(e.turn_state.get("standard_used", false)))
	)
	var buttons := button_box.get_children()
	var turn_status := Game.combat_can_turn_undead()
	var pending := e.has_pending_decision()
	var turn_ch := e.active_character()
	var active_entry_now := e.active_entry()
	var active_cell := (
		Vector2i(active_entry_now["cell"]) if not active_entry_now.is_empty() else Vector2i(-1, -1)
	)
	var active_index := (
		int(active_entry_now["index"]) if not active_entry_now.is_empty() else -1
	)
	# One stable Escape label, explained by role: pinned, holding (release), held.
	if grapple_exit_button != null and active_index >= 0:
		if e.is_pinned(active_index):
			grapple_exit_button.tooltip_text = (
				"Escape the pin with an opposed grapple check or Escape Artist; a success "
				+ "still leaves you grappling (PHB p.156)."
			)
		elif e.grapple_role(active_index) == "holder":
			grapple_exit_button.tooltip_text = (
				"Let go for free; releasing a pin also ends the whole hold (PHB p.156)."
			)
		else:
			grapple_exit_button.tooltip_text = (
				"Escape a grapple with an opposed grapple check or Escape Artist, or let go "
				+ "for free if you are the one holding (PHB p.156)."
			)
	var prone := turn_ch != null and turn_ch.is_prone()
	var trip_weapon_ready := turn_ch != null and bool(e._primary_weapon(turn_ch).get("trip", false))
	trip_weapon_check.disabled = not trip_weapon_ready or pending
	if not trip_weapon_ready:
		trip_weapon_check.button_pressed = false
	var ground_here := false
	for ground in e.ground_items:
		if Vector2i(ground["cell"]) == active_cell:
			ground_here = true
			break
	var enabled := {
		"Move": moves,
		"5-ft step": player_turn and not moved and not five_foot_used and not prone and int(e.turn_state.get("moved_ft", 0)) == 0,
		"Attack": standard,
		"Sheathe weapon":
		player_turn
		and turn_ch != null
		and not moved
		and not bool(turn_ch.equipment.get("weapon", {}).is_empty()),
		"Load weapon":
		player_turn
		and turn_ch != null
		and String(e._primary_weapon(turn_ch).get("reload", "")) != ""
		and not e.is_weapon_loaded(turn_ch)
		and not moved,
		"Cast spell": standard,
		"Use potion": standard,
		"First aid": standard,
		"Turn undead": bool(turn_status.get("ok", false)),
		"Trip": standard,
		"Bull rush": standard,
		"Grapple": standard,
		"Pin": (
			standard
			and active_index >= 0
			and e.grapple_role(active_index) == "holder"
			and not e.is_pinned(e.grapple_partner(active_index))
		),
		"Escape": player_turn and active_index >= 0 and e.is_grappled(active_index),
		"Stand up": player_turn and prone and not moved,
		"Pick up":
		player_turn
		and ground_here
		and not five_foot_used
		and not (moved and bool(e.turn_state.get("standard_used", false))),
		"End turn": not e.finished,
		"Inspect": not e.finished,
		"Defend": (
			standard
			and not e.fight_defensively_active_for(active_index)
			and not e.total_defense_active_for(active_index)
		),
	}
	if pending:
		for key in enabled.keys():
			enabled[key] = false
	for button in buttons:
		if button is Button:
			button.disabled = not bool(enabled.get(String(button.text), false))


func _refresh_log() -> void:
	var e := Game.encounter
	var lines := e.log_lines
	var start := maxi(0, lines.size() - 160)
	log_label.text = "\n".join(lines.slice(start))
	log_label.scroll_to_line(maxi(0, log_label.get_line_count() - 1))


func _on_cell_clicked(cell: Vector2i) -> void:
	var e := Game.encounter
	if e == null or e.finished:
		return
	if not e.is_player_turn():
		Game.last_ui_message = "It is not your turn."
		refresh_screen()
		return
	if e.has_pending_decision():
		Game.last_ui_message = "Resolve the pending combat decision first."
		refresh_screen()
		return
	var entry := _entry_at(cell)
	if not pending_action.is_empty():
		if entry.is_empty():
			Game.last_ui_message = "Choose a creature for that action."
			refresh_screen()
			return
		if not _pending_target_valid(entry):
			Game.last_ui_message = "That spell or item cannot target that creature."
			refresh_screen()
			return
		_execute_pending(int(entry["index"]))
		return
	if mode == "trip":
		if entry.is_empty() or int(entry["team"]) != Encounter.TEAM_ENEMY:
			Game.last_ui_message = "Choose an enemy to trip."
			refresh_screen()
			return
		Game.combat_trip(int(entry["index"]), trip_weapon_check.button_pressed)
		refresh_screen()
		return
	if mode == "bull_rush":
		if entry.is_empty() or int(entry["team"]) != Encounter.TEAM_ENEMY:
			Game.last_ui_message = "Choose an enemy to bull rush."
			refresh_screen()
			return
		Game.combat_bull_rush(int(entry["index"]))
		refresh_screen()
		return
	if mode == "grapple":
		if entry.is_empty() or int(entry["team"]) != Encounter.TEAM_ENEMY:
			Game.last_ui_message = "Choose an enemy to grapple."
			refresh_screen()
			return
		Game.combat_grapple(int(entry["index"]))
		refresh_screen()
		return
	if mode == "step":
		if not entry.is_empty():
			Game.last_ui_message = "A 5-foot step must end on an empty square."
			refresh_screen()
			return
		Game.combat_move(cell, true)
		refresh_screen()
		return
	if mode == "attack":
		if entry.is_empty() or int(entry["team"]) != Encounter.TEAM_ENEMY:
			Game.last_ui_message = "Choose an enemy to attack."
			refresh_screen()
			return
		var enemy: Character = entry["char"]
		if enemy.has_condition("dead"):
			Game.last_ui_message = "%s is already dead." % enemy.display_name
			refresh_screen()
			return
		_attack(int(entry["index"]))
		return
	if not entry.is_empty():
		var ch: Character = entry["char"]
		if int(entry["team"]) == Encounter.TEAM_ENEMY and not ch.has_condition("dead"):
			_attack(int(entry["index"]))
			return
		if int(entry["team"]) == Encounter.TEAM_PARTY:
			_inspect_index(int(entry["index"]))
			return
	Game.combat_move(cell, false)
	refresh_screen()


func _entry_at(cell: Vector2i) -> Dictionary:
	for entry in Game.encounter.combatants:
		if entry["cell"] == cell:
			return entry
	return {}


func _pending_target_valid(entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	var target: Character = entry.get("char") as Character
	if target == null or target.has_condition("dead"):
		return false
	var team := int(entry.get("team", -1))
	if String(pending_action.get("type", "")) == "item":
		return team == Encounter.TEAM_PARTY
	var resolve := String(pending_action.get("resolve", ""))
	if ["cure_light_wounds", "aid", "mage_armor"].has(resolve):
		return team == Encounter.TEAM_PARTY
	if ["magic_missile", "scorching_ray"].has(resolve):
		return team == Encounter.TEAM_ENEMY
	return true


## Pending-decision gate for UI entry points. The engine rejects the action too;
## this only avoids opening a modal or target mode that cannot resolve.
func _refuse_while_pending() -> bool:
	var e := Game.encounter
	if e == null or not e.has_pending_decision():
		return false
	Game.last_ui_message = "Resolve the pending combat decision first."
	refresh_screen()
	return true


func _trip() -> void:
	if _refuse_while_pending():
		return
	mode = "trip"
	Game.last_ui_message = (
		"Click an enemy within reach to Trip. Check 'Use equipped trip weapon' for a weapon trip."
	)
	refresh_screen()


func _bull_rush() -> void:
	if _refuse_while_pending():
		return
	mode = "bull_rush"
	Game.last_ui_message = "Click an enemy within reach to Bull rush (PHB p.154)."
	refresh_screen()


func _grapple() -> void:
	if _refuse_while_pending():
		return
	mode = "grapple"
	Game.last_ui_message = "Click an enemy within reach to Grapple (PHB p.155)."
	refresh_screen()


## No target mode: the pinned creature is always the grapple partner.
func _pin() -> void:
	if _refuse_while_pending():
		return
	Game.combat_pin()
	refresh_screen()


## One control, two printed outcomes: the holder lets go for free, the held
## creature spends its standard action on the opposed check.
func _grapple_exit() -> void:
	if _refuse_while_pending():
		return
	Game.combat_grapple_exit()
	refresh_screen()


func _pick_up_here() -> void:
	if _refuse_while_pending():
		return
	var e := Game.encounter
	if e == null:
		return
	var entry := e.active_entry()
	if entry.is_empty():
		return
	var cell := Vector2i(entry["cell"])
	for i in e.ground_items.size():
		if Vector2i(e.ground_items[i]["cell"]) == cell:
			Game.combat_pick_up(i)
			refresh_screen()
			return
	Game.last_ui_message = "There is nothing on the ground in your square."
	refresh_screen()


## A bounded, scrolling list for decision targets. Many eligible targets must
## not push the accept/decline controls below the window at 1024x600 or at the
## largest text scale.
func _decision_scroll(count: int) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, mini(152, maxi(40, count * 40)))
	return scroll


## Shown while a combat decision is paused: Trip (PHB p.159), Improved Trip's
## granted attack (p.96) or Cleave (p.92), on or off turn.
func _rebuild_decision() -> void:
	for child in decision_box.get_children():
		child.queue_free()
	var e := Game.encounter
	if e == null or not e.has_pending_decision():
		return
	if not e.pending_cleave.is_empty():
		var cleaver_index := int(e.pending_cleave.get("actor_index", -1))
		if cleaver_index < 0 or cleaver_index >= e.combatants.size():
			return
		var cleaver: Character = e.combatants[cleaver_index]["char"]
		var dropped_index := int(e.pending_cleave.get("dropped_index", -1))
		var dropped_name := "a creature"
		if dropped_index >= 0 and dropped_index < e.combatants.size():
			dropped_name = String((e.combatants[dropped_index]["char"] as Character).display_name)
		var off_turn := not e.is_player_turn()
		var cleave_label := ThemeBuilder.body(
			(
				"Cleave: %s dropped %s off turn. Choose another enemy within reach, or decline (PHB p.92). The interrupted turn resumes afterwards."
				if off_turn
				else "Cleave: %s dropped %s. Choose another enemy within reach, or decline (PHB p.92)."
			)
			% [cleaver.display_name, dropped_name],
			false,
			10
		)
		cleave_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cleave_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		decision_box.add_child(cleave_label)
		var targets := e.cleave_targets(cleaver_index, dropped_index)
		var choices_scroll := _decision_scroll(targets.size())
		decision_box.add_child(choices_scroll)
		var choices := VBoxContainer.new()
		choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices.add_theme_constant_override("separation", 6)
		choices_scroll.add_child(choices)
		for other in targets:
			var pick := Button.new()
			pick.text = "Attack %s" % String((other["char"] as Character).display_name)
			var target_index := int(other["index"])
			pick.pressed.connect(func() -> void: Game.combat_resolve_cleave(target_index))
			choices.add_child(pick)
		# Decline stays outside the scrolling list so it is always reachable.
		var pass_up := Button.new()
		pass_up.text = "Decline extra attack"
		pass_up.pressed.connect(func() -> void: Game.combat_decline_cleave())
		decision_box.add_child(pass_up)
		return
	if not e.pending_bull_rush.is_empty():
		_rebuild_bull_rush_decision(e)
		return
	var actor_index := int(e.pending_trip.get("actor_index", -1))
	if actor_index < 0 or actor_index >= e.combatants.size():
		return
	var ch: Character = e.combatants[actor_index]["char"]
	if String(e.pending_trip.get("type", "weapon_release")) == "improved_trip_attack":
		var target_index := int(e.pending_trip.get("target_index", -1))
		var target_name := "the tripped opponent"
		if target_index >= 0 and target_index < e.combatants.size():
			target_name = String((e.combatants[target_index]["char"] as Character).display_name)
		var attack_label := ThemeBuilder.body(
			"Improved Trip: %s may immediately attack %s (PHB p.96)." % [ch.display_name, target_name],
			false,
			10
		)
		attack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		attack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		decision_box.add_child(attack_label)
		# The feat grants "a melee attack", not the trip method. Offer every melee
		# attack already available in hand; taking a different weapon out would be
		# an equip action and is not offered.
		var follow_menu := OptionButton.new()
		follow_menu.add_item("Unarmed strike")
		follow_menu.set_item_metadata(0, "unarmed")
		var primary := e._primary_weapon(ch)
		for mode in Rules.weapon_attack_modes(primary):
			if Rules.is_ranged_attack(primary, mode):
				continue
			follow_menu.add_item("%s (%s)" % [String(primary.get("name", "weapon")), mode])
			follow_menu.set_item_metadata(follow_menu.item_count - 1, mode)
		if follow_menu.item_count > 1:
			follow_menu.select(1)
		decision_box.add_child(follow_menu)
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 6)
		decision_box.add_child(buttons)
		var take := Button.new()
		take.text = "Make the extra attack"
		take.pressed.connect(
			func() -> void:
				var picked := String(follow_menu.get_item_metadata(follow_menu.selected))
				Game.combat_resolve_improved_trip(true, picked)
		)
		buttons.add_child(take)
		var decline := Button.new()
		decline.text = "Decline extra attack"
		decline.pressed.connect(func() -> void: Game.combat_resolve_improved_trip(false))
		buttons.add_child(decline)
		return
	var label := ThemeBuilder.body(
		"%s lost the counter-trip. Drop the weapon to stay standing, or keep it and fall prone (PHB p.159)."
		% ch.display_name,
		false,
		10
	)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decision_box.add_child(label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	decision_box.add_child(buttons)
	var drop := Button.new()
	drop.text = "Drop weapon"
	drop.pressed.connect(func() -> void: Game.combat_resolve_trip(true))
	buttons.add_child(drop)
	var keep := Button.new()
	keep.text = "Keep weapon"
	keep.pressed.connect(func() -> void: Game.combat_resolve_trip(false))
	buttons.add_child(keep)


## PHB p.154: after a won check the rusher chooses whether to move with the
## defender. Every roll is already final, so this only offers the two distances.
func _rebuild_bull_rush_decision(e: Encounter) -> void:
	var actor_index := int(e.pending_bull_rush.get("actor_index", -1))
	var target_index := int(e.pending_bull_rush.get("target_index", -1))
	if actor_index < 0 or actor_index >= e.combatants.size():
		return
	var ch: Character = e.combatants[actor_index]["char"]
	var target_name := "the defender"
	if target_index >= 0 and target_index < e.combatants.size():
		target_name = String((e.combatants[target_index]["char"] as Character).display_name)
	var push_ft := int(e.pending_bull_rush.get("push_ft", 5))
	var label := ThemeBuilder.body(
		(
			"Bull rush: %s won the check. Push %s 5 feet, or move with them and push %d feet (PHB p.154)."
			% [ch.display_name, target_name, push_ft]
		),
		false,
		10
	)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decision_box.add_child(label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	decision_box.add_child(buttons)
	var stay := Button.new()
	stay.text = "Push 5 ft"
	stay.pressed.connect(func() -> void: Game.combat_resolve_bull_rush(false))
	buttons.add_child(stay)
	var follow := Button.new()
	follow.text = "Follow"
	follow.pressed.connect(func() -> void: Game.combat_resolve_bull_rush(true))
	buttons.add_child(follow)


## PHB p.97: Improved Unarmed Strike lets the character deal lethal or nonlethal
## damage with an unarmed strike at no penalty. Without the feat the strike deals
## nonlethal damage only, and a lethal strike takes the printed -4 (PHB p.147).
func _sync_unarmed_options(ch: Character) -> void:
	var ius := Feats.has_feat(ch, "improved_unarmed_strike")
	unarmed_option.clear()
	unarmed_option.add_item("Nonlethal (default)")
	unarmed_option.add_item("Lethal (-4, PHB p.147)" if not ius else "Lethal (feat, no penalty)")
	var index := 1 if selected_unarmed_damage == "lethal" else 0
	unarmed_option.select(index)
	unarmed_option.disabled = e_finished_guard()


func e_finished_guard() -> bool:
	return Game.encounter != null and Game.encounter.finished


func _on_unarmed_damage_selected(index: int) -> void:
	selected_unarmed_damage = "lethal" if index == 1 else "nonlethal"
	var note := "nonlethal damage (PHB p.139)"
	if selected_unarmed_damage == "lethal":
		note = "lethal damage; Improved Unarmed Strike removes the -4 (PHB pp.97, 147)"
	Game.last_ui_message = "Unarmed strike will deal %s." % note
	if message_label != null:
		message_label.text = Game.last_ui_message


func _sync_weapon_options(ch: Character, equipped: Dictionary) -> void:
	var rows := ch.carried_weapons()
	var equipped_id := String(equipped.get("id", ""))
	weapon_option.clear()
	weapon_ids.clear()
	for row in rows:
		var row_id := String(row["id"])
		weapon_ids.append(row_id)
		var text := String(row["name"])
		if row_id == equipped_id:
			text += " (readied)"
		weapon_option.add_item(text)
	var index := weapon_ids.find(equipped_id)
	weapon_option.select(maxi(0, index))
	weapon_option.disabled = false


## The shield control lists what the character carries plus, when a shield is
## strapped on, an explicit loose entry. Choosing a carried shield straps it on
## (PHB p.142) and choosing the loose entry unstraps and drops it; both go through
## the encounter, so the UI never changes equipment on its own.
func _sync_shield_options(ch: Character) -> void:
	var rows := ch.carried_shields()
	shield_option.clear()
	shield_ids.clear()
	var readied_id := ""
	for row in rows:
		var row_id := String(row["id"])
		var text := String(row["name"])
		if bool(row.get("equipped", false)):
			text += " (strapped)"
			readied_id = row_id
		shield_ids.append(row_id)
		shield_option.add_item(text)
	if readied_id != "":
		shield_ids.append("__loose__")
		shield_option.add_item("Loose shield (drops it)")
	shield_option.disabled = shield_option.item_count == 0
	if shield_option.item_count == 0:
		return
	var index := 0
	if readied_id != "":
		index = maxi(0, shield_ids.find(readied_id))
	shield_option.select(index)


func _on_shield_selected(index: int) -> void:
	if index < 0 or index >= shield_ids.size():
		return
	if String(shield_ids[index]) == "__loose__":
		Game.combat_loose_shield()
	else:
		Game.combat_ready_shield(String(shield_ids[index]))
	_after_action()


func _on_weapon_selected(index: int) -> void:
	if index < 0 or index >= weapon_ids.size():
		return
	Game.combat_draw_weapon(String(weapon_ids[index]))
	_after_action()


func _on_attack_mode_selected(index: int) -> void:
	selected_attack_mode = String(attack_mode_option.get_item_metadata(index))
	Game.last_ui_message = "Attack mode: %s." % selected_attack_mode.capitalize()
	if message_label != null:
		message_label.text = Game.last_ui_message


func _sync_attack_modes(modes: Array[String]) -> void:
	if attack_mode_option.item_count != modes.size():
		attack_mode_option.clear()
		for entry in modes:
			attack_mode_option.add_item(entry.capitalize())
			attack_mode_option.set_item_metadata(attack_mode_option.item_count - 1, entry)
	var index := modes.find(selected_attack_mode)
	if index < 0:
		index = 0
		selected_attack_mode = modes[index]
	attack_mode_option.select(index)


func _on_power_attack_changed(value: float) -> void:
	if power_attack_box != null and not power_attack_box.visible:
		return
	var result := Game.combat_set_power_attack(int(value))
	if not bool(result.get("ok", false)):
		var e := Game.encounter
		power_attack_spin.set_value_no_signal(
			float(e.active_power_attack_amount()) if e != null else 0.0
		)
	Game.last_ui_message = String(result.get("message", "Power Attack unchanged."))
	if message_label != null:
		message_label.text = Game.last_ui_message


func _on_combat_expertise_changed(value: float) -> void:
	if combat_expertise_box != null and not combat_expertise_box.visible:
		return
	var result := Game.combat_set_combat_expertise(int(value))
	if not bool(result.get("ok", false)):
		var e := Game.encounter
		if e != null:
			var shown := e.active_combat_expertise_amount()
			if shown == 0:
				shown = e.active_combat_expertise_pending_amount()
			combat_expertise_spin.set_value_no_signal(float(shown))
	Game.last_ui_message = String(result.get("message", "Combat Expertise unchanged."))
	if message_label != null:
		message_label.text = Game.last_ui_message


## Selecting is not activating: the checkbox only records intent until an attack
## commits. A refusal (already active, total defense, standard spent) restores
## the pressed state from the encounter rather than trusting the widget.
func _on_fight_defensively_toggled(pressed: bool) -> void:
	if fight_defensively_check == null:
		return
	var result := Game.combat_set_fight_defensively(pressed)
	if not bool(result.get("ok", false)):
		var e := Game.encounter
		if e != null:
			var entry := e.active_entry()
			var index := int(entry["index"]) if not entry.is_empty() else -1
			fight_defensively_check.set_pressed_no_signal(
				e.fight_defensively_active_for(index) or e.fight_defensively_selected_for(index)
			)
	Game.last_ui_message = String(result.get("message", "Fighting defensively unchanged."))
	if message_label != null:
		message_label.text = Game.last_ui_message


func _on_total_defense() -> void:
	var result := Game.combat_total_defense()
	Game.last_ui_message = String(result.get("message", "Total defense unavailable."))
	if message_label != null:
		message_label.text = Game.last_ui_message


func _attack(index: int) -> void:
	pending_action = {}
	var attack_mode := ""
	if attack_mode_box != null and attack_mode_box.visible:
		attack_mode = selected_attack_mode
	var unarmed_damage := ""
	if unarmed_box != null and unarmed_box.visible:
		unarmed_damage = selected_unarmed_damage
	var result := Game.combat_attack(index, attack_mode, unarmed_damage)
	if bool(result.get("ok", false)):
		Game.last_ui_message = String(result.get("message", "Attack resolved."))
	_after_action()


func _after_action() -> void:
	if Game.mode != "combat":
		return
	refresh_screen()


func _set_mode(new_mode: String, message: String) -> void:
	mode = new_mode
	pending_action = {}
	Game.last_ui_message = message
	refresh_screen()


func _turn_undead() -> void:
	if _refuse_while_pending():
		return
	pending_action = {}
	Game.combat_turn_undead()
	_after_action()


func _end_turn() -> void:
	pending_action = {}
	Game.combat_end_turn()
	if Game.mode == "combat":
		refresh_screen()


func _open_spells() -> void:
	if _refuse_while_pending():
		return
	var e := Game.encounter
	if e == null or not e.is_player_turn():
		return
	var spells := Game.combat_spells_for_active()
	if spells.is_empty():
		Game.last_ui_message = "No prepared spells remain for this adventurer."
		refresh_screen()
		return
	main.open_modal("Cast a spell", func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(620, 360)
		box.add_theme_constant_override("separation", 8)
		# Casting mode is an explicit choice made here, per casting. It is never
		# switched automatically and does not survive the modal: the checkbox is
		# created unchecked each time the list opens.
		var mode_note := ThemeBuilder.body(
			"Ordinary casting provokes if you are threatened. Defensive casting does not, but you must make a Concentration check (DC 15 + spell level).",
			false,
			11
		)
		mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(mode_note)
		var defensive_check := CheckBox.new()
		defensive_check.text = "Cast defensively (Concentration check, no attack of opportunity)"
		defensive_check.button_pressed = false
		defensive_check.add_theme_font_size_override("font_size", ThemeBuilder.fs(11))
		box.add_child(defensive_check)
		for entry in spells:
			var spell: Dictionary = entry["spell"]
			var button := Button.new()
			var resolve := String(spell.get("resolve", ""))
			var target_hint := "self"
			if ["cure_light_wounds", "aid", "mage_armor"].has(resolve):
				target_hint = "ally"
			elif ["magic_missile", "scorching_ray"].has(resolve):
				target_hint = "enemy"
			elif resolve == "bless":
				target_hint = "all allies"
			button.text = "%s — level %d — %d left — target: %s" % [
				String(spell.get("name", "?")),
				int(spell.get("level", 1)),
				int(entry["remaining"]),
				target_hint,
			]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var captured := String(spell.get("id", ""))
			var captured_resolve := resolve
			button.pressed.connect(func() -> void:
				var defensive := defensive_check.button_pressed
				main.close_modal()
				_select_spell(captured, captured_resolve, defensive)
			)
			box.add_child(button)
		return box
	, 680, 420)


func _select_spell(spell_id: String, resolve: String, defensive := false) -> void:
	var e := Game.encounter
	if e == null:
		return
	var active := e.active_entry()
	if active.is_empty():
		return
	if resolve == "bless":
		Game.combat_cast(spell_id, int(active["index"]), defensive)
		_after_action()
		return
	pending_action = {"type": "spell", "id": spell_id, "resolve": resolve, "defensive": defensive}
	Game.last_ui_message = "Spell selected%s: choose a %s." % [
		" (defensively)" if defensive else "",
		"enemy" if ["magic_missile", "scorching_ray"].has(resolve) else "ally",
	]
	refresh_screen()


func _open_potions() -> void:
	if _refuse_while_pending():
		return
	var e := Game.encounter
	if e == null or not e.is_player_turn():
		return
	var active: Character = e.active_character()
	if active == null:
		return
	var consumables: Array = []
	for entry in active.inventory:
		var item: Dictionary = entry.get("item", {})
		if String(item.get("kind", "")) == "consumable":
			consumables.append({"id": String(entry["id"]), "name": String(item.get("name", "?")), "qty": int(entry.get("qty", 1))})
	if consumables.is_empty():
		Game.last_ui_message = "%s has no usable potions." % active.display_name
		refresh_screen()
		return
	main.open_modal("Use a potion", func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(520, 220)
		for entry in consumables:
			var button := Button.new()
			button.text = "%s ×%d" % [entry["name"], entry["qty"]]
			var captured_item_id := String(entry["id"])
			button.pressed.connect(func() -> void:
				main.close_modal()
				pending_action = {"type": "item", "id": captured_item_id}
				Game.last_ui_message = "Potion selected: choose who drinks it."
				refresh_screen()
			)
			box.add_child(button)
		return box
	, 620, 320)


func _open_first_aid() -> void:
	if _refuse_while_pending():
		return
	var e := Game.encounter
	if e == null:
		return
	var dying: Array = []
	for entry in e.combatants:
		var ch: Character = entry["char"]
		if ch.has_condition("dying"):
			dying.append(entry)
	if dying.is_empty():
		Game.last_ui_message = "No one is dying."
		refresh_screen()
		return
	var active_entry := e.active_entry()
	if active_entry.is_empty():
		return
	main.open_modal("First aid (Heal DC 15)", func() -> Control:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(520, 220)
		box.add_child(ThemeBuilder.body("Adjacent only. Uses your standard action.", true, 13))
		for entry in dying:
			var ch: Character = entry["char"]
			var button := Button.new()
			button.text = "Stabilize %s" % ch.display_name
			var captured := int(entry["index"])
			button.pressed.connect(func() -> void:
				main.close_modal()
				Game.combat_stabilize(captured)
				_after_action()
			)
			box.add_child(button)
		return box
	, 620, 320)


func _execute_pending(target_index: int) -> void:
	var action := pending_action
	pending_action = {}
	if String(action.get("type", "")) == "spell":
		Game.combat_cast(
			String(action["id"]), target_index, bool(action.get("defensive", false))
		)
	else:
		Game.combat_item(String(action["id"]), target_index)
	_after_action()


func _inspect_active() -> void:
	if Game.encounter == null:
		return
	var active := Game.encounter.active_entry()
	if active.is_empty():
		return
	_inspect_index(int(active["index"]))


## The AC an attack resolves against for this combatant right now. The inspector
## and the attack resolver both come through Rules.armor_class / Rules.touch_ac
## and add the encounter's cover term the same way, so the panel cannot disagree
## with the roll it is describing. `touch` selects the AC a ranged touch attack
## uses, and cover applies to both (Rules Compendium, "Touch Attacks").
static func effective_ac(ch: Character, flat_footed: bool, cover := 0, touch := false) -> int:
	var base := (
		Rules.touch_ac(ch, {"flat_footed": flat_footed})
		if touch
		else Rules.armor_class(ch, {"flat_footed": flat_footed})
	)
	return base + maxi(0, cover)


## The panel's attacker-dependent cover line. One function so the text cannot
## drift from `effective_ac`: it states the normal AC and the touch AC a ranged
## touch attack would use, both with the same cover term the resolver adds.
static func cover_summary(
	ch: Character, flat_footed: bool, cover: int, shooter_name: String
) -> String:
	return "%s's ranged attack: AC %d • touch %d (+%d cover, PHB p.151)" % [
		shooter_name,
		effective_ac(ch, flat_footed, cover),
		effective_ac(ch, flat_footed, cover, true),
		cover,
	]


## Soft cover exists only against a particular attacker, so the inspector asks
## the encounter only when the active combatant is an enemy of the inspected
## one; the panel then names that shooter next to the number.
func _cover_vs_active(index: int) -> int:
	if Game.encounter == null:
		return 0
	var active: Dictionary = Game.encounter.active_entry()
	if active.is_empty() or int(active["index"]) == index:
		return 0
	if int(active["team"]) == int(Game.encounter.combatants[index]["team"]):
		return 0
	return Game.encounter.creature_cover(int(active["index"]), index)


func _inspect_index(index: int) -> void:
	if Game.encounter == null:
		return
	var entry: Dictionary = Game.encounter.combatants[index]
	var ch: Character = entry["char"]
	var party_index := Game.party.find(ch)
	if party_index >= 0:
		main.open_modal("%s" % ch.display_name, func() -> Control:
			return Panels.character_sheet(party_index)
		, 900, 620)
	else:
		main.open_modal("%s" % ch.display_name, func() -> Control:
			var box := VBoxContainer.new()
			box.custom_minimum_size = Vector2(560, 280)
			box.add_child(ThemeBuilder.heading(ch.display_name, 22))
			box.add_child(ThemeBuilder.body("%s — %s" % [ch.monster_type.capitalize(), ch.notes], false, 13))
			# Report the AC an attack would actually use right now, so a creature
			# that has not taken its first turn reads as flat-footed (PHB p.133).
			var flat := Game.encounter.is_flat_footed(index)
			var nonlethal_text := ""
			if ch.nonlethal > 0:
				nonlethal_text = " (nonlethal %d)" % ch.nonlethal
			box.add_child(ThemeBuilder.body(
				"HP %d/%d%s • AC %d%s • Initiative %+d • Attacks: %s"
				% [
					ch.hp,
					ch.max_hp,
					nonlethal_text,
					effective_ac(ch, flat),
					" (flat-footed)" if flat else "",
					Rules.ability_modifier(ch, "dex"),
					", ".join(_attack_names(ch)),
				],
				false,
				13
			))
			# A covered target does not get a bare attacker-dependent number: the
			# clause names the shooter and states both ACs the roll can use, because
			# a ranged touch attack resolves against touch AC and keeps cover.
			var cover := _cover_vs_active(index)
			if cover > 0:
				var shooter_entry: Dictionary = Game.encounter.active_entry()
				var shooter: Character = shooter_entry["char"]
				box.add_child(ThemeBuilder.body(
					cover_summary(ch, flat, cover, shooter.display_name), true, 12
				))
			for attack in ch.attacks:
				box.add_child(ThemeBuilder.body(Panels._attack_line(ch, attack), true, 12))
			return box
		, 640, 380)


func _attack_names(ch: Character) -> Array[String]:
	var names: Array[String] = []
	for attack in ch.attacks:
		names.append(String(attack.get("name", "attack")))
	return names
