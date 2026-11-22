class_name Panels
extends RefCounted

## Reusable modal contents: character sheet, inventory, journal, settings,
## saves and pause menu. Presentation only; every action calls GameSession.

const REBIND_ACTIONS := [
	["move_forward", "Move forward"],
	["move_back", "Move back"],
	["strafe_left", "Strafe left"],
	["strafe_right", "Strafe right"],
	["turn_left", "Turn left"],
	["turn_right", "Turn right"],
	["interact", "Interact"],
	["open_party", "Party sheet"],
	["open_inventory", "Inventory"],
	["open_journal", "Journal"],
	["pause_menu", "Pause"],
]


## `on_level_up` is optional: a sheet that cannot spend a level (the combat view)
## passes none and then shows neither a button nor a refusal line. The page is the
## card - the sheet is a TabContainer with one page per party member - so the
## button lives in a header row above that page's own scroll body.
static func character_sheet(selected := 0, on_level_up := Callable()) -> Control:
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(800, 500)
	for i in Game.party.size():
		var ch: Character = Game.party[i]
		var page := MarginContainer.new()
		page.name = ch.display_name
		# At the largest text scale the tab strip was drawn over the sheet's first
		# line, so the page keeps its own top margin instead of trusting the tab bar.
		page.add_theme_constant_override("margin_top", 6)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var body := VBoxContainer.new()
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page.add_child(body)
		body.add_child(_level_up_header(i, ch, on_level_up))
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.text = _character_text(ch)
		scroll.add_child(text)
		body.add_child(scroll)
		tabs.add_child(page)
	if tabs.get_tab_count() > 0:
		tabs.current_tab = clampi(selected, 0, tabs.get_tab_count() - 1)
	return tabs


## The page's header row: a `Level up` button when the step is open, a muted
## reason line when it is not, and nothing at all when the caller cannot open the
## level-up screen. A disabled button would read as "almost available"; a page
## that does not offer the step offers no control for it.
static func _level_up_header(index: int, ch: Character, on_level_up: Callable) -> Control:
	var header := HBoxContainer.new()
	header.name = "PageHeader"
	header.add_theme_constant_override("separation", 8)
	var state := LevelUp.eligibility(ch)
	if bool(state.get("eligible", false)):
		if not on_level_up.is_valid():
			return header
		var button := Button.new()
		button.name = "LevelUpButton"
		button.text = "Level up"
		button.custom_minimum_size = Vector2(0, 34)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var captured := index
		button.pressed.connect(func() -> void: on_level_up.call(captured))
		header.add_child(button)
		var hint := ThemeBuilder.body(
			"This character has enough experience to advance to 4th level.", true, 12
		)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(hint)
		return header
	var message := String(state.get("message", ""))
	if message != "":
		var reason := ThemeBuilder.body(message, true, 12)
		reason.name = "LevelUpReason"
		reason.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(reason)
	return header


static func _character_text(ch: Character) -> String:
	var lines: Array[String] = []
	lines.append("[b][color=#d6b45f]%s[/color][/b] — %s, %s" % [ch.display_name, ch.race, ch.display_class()])
	lines.append(
		"HP %d/%d%s    AC %d (touch %d, flat-footed %d)    Speed %d ft.    XP %d"
		% [
			ch.hp,
			ch.max_hp,
			("  [%s]" % ch.get_effect("dead").get("name", "")) if ch.has_condition("dead") else "",
			Rules.armor_class(ch),
			Rules.touch_ac(ch),
			Rules.armor_class(ch, {"flat_footed": true}),
			ch.speed_ft,
			ch.xp,
		]
	)
	lines.append("Base attack bonus +%d    Initiative %+d" % [ch.base_attack, Rules.ability_modifier(ch, "dex")])
	lines.append("")
	lines.append("[b]Abilities[/b]")
	var ability_names := {"str": "STR", "dex": "DEX", "con": "CON", "int": "INT", "wis": "WIS", "cha": "CHA"}
	for key in Rules.ABILITIES:
		lines.append(
			"  %s %d (%+d)" % [ability_names[key], int(ch.abilities.get(key, 10)), ch.ability_mod(key)]
		)
	lines.append("")
	lines.append("[b]Saving throws[/b]")
	for save in ["fort", "ref", "will"]:
		lines.append(
			"  %s %+d" % [save.to_upper(), Rules.saving_throw_bonus(ch, save)]
		)
	lines.append("")
	lines.append("[b]Attacks[/b]")
	if ch.is_monster:
		for attack in ch.attacks:
			lines.append("  " + _attack_line(ch, attack))
	else:
		var weapon: Dictionary = ch.equipped("weapon")
		if weapon.is_empty():
			weapon = {
				"name": "unarmed strike",
				"damage": "1d3",
				"damage_type": "nonlethal",
				"crit_range": 20,
				"crit_mult": 2,
			}
		lines.append("  " + _attack_line(ch, weapon))
		if not ch.equipment.get("armor", {}).is_empty():
			lines.append("  Armor: " + String(ch.equipment["armor"].get("name", "")))
		if not ch.equipment.get("shield", {}).is_empty():
			lines.append("  Shield: " + String(ch.equipment["shield"].get("name", "")))
	lines.append("")
	lines.append("[b]Skills[/b]")
	var shown_any := false
	for skill in Skills.all_keys():
		var ranks := int(ch.skill_ranks.get(skill, 0))
		var feat_total := int(Skills.feat_bonus(ch, skill)["total"])
		var synergy := Skills.synergy_bonus(ch, skill)
		if ranks == 0 and feat_total == 0 and synergy == 0:
			continue
		shown_any = true
		lines.append("  %s %s" % [Skills.name(skill), Skills.breakdown_text(ch, skill)])
	if not shown_any:
		lines.append("  (no trained skills)")
	lines.append("  Untrained skills use the ability modifier; trained-only skills need ranks.")
	if not ch.spells.is_empty():
		lines.append("")
		lines.append("[b]Spellcasting[/b]")
		lines.append(
			"  %s-based, caster level %d, %s"
			% [
				String(ch.spells.get("ability", "wis")).to_upper(),
				int(ch.spells.get("caster_level", ch.level)),
				"spontaneous" if bool(ch.spells.get("spontaneous", false)) else "prepared",
			]
		)
		var levels: Array = Dictionary(ch.spells.get("slots", {})).keys()
		levels.sort()
		for level_key in levels:
			var level := int(level_key)
			var remaining := ch.spell_slots_remaining(level)
			var spell_names: Array[String] = []
			if bool(ch.spells.get("spontaneous", false)):
				for spell_id in Array(ch.spells.get("known", [])):
					var spell := Game.content.get_spell(String(spell_id))
					if not spell.is_empty() and int(spell.get("level", 1)) == level:
						spell_names.append(String(spell.get("name", spell_id)))
			else:
				for spell_id in Array(Dictionary(ch.spells.get("prepared", {})).get(level_key, [])):
					var spell := Game.content.get_spell(String(spell_id))
					spell_names.append(String(spell.get("name", spell_id)) if not spell.is_empty() else String(spell_id))
			lines.append(
				"  Level %d: %d/%d remaining — %s"
				% [level, remaining, int(Dictionary(ch.spells["slots"]).get(level_key, {}).get("max", 0)), ", ".join(spell_names)]
			)
	lines.append("")
	lines.append("[b]Feats[/b]")
	if ch.feats.is_empty():
		lines.append("  —")
	for row in Feats.describe(ch):
		var suffix := ""
		if not bool(row["active"]):
			suffix = " [inactive: %s]" % String(row["reason"])
		lines.append("  %s — %s%s" % [String(row["name"]), String(row["benefit"]), suffix])
	var effects: Array[String] = []
	for effect in ch.effects:
		var rounds := int(effect.get("rounds_left", -1))
		effects.append(
			"%s%s" % [String(effect.get("name", effect.get("id", ""))), "" if rounds < 0 else " (%d rounds)" % rounds]
		)
	lines.append("[b]Conditions & effects[/b] " + (", ".join(effects) if not effects.is_empty() else "None"))
	lines.append("[b]Equipment slots[/b]")
	for slot in ["weapon", "armor", "shield"]:
		var item: Dictionary = ch.equipment.get(slot, {})
		lines.append("  %s: %s" % [slot.capitalize(), String(item.get("name", "—"))])
	lines.append("")
	lines.append("[i]%s[/i]" % ch.notes)
	return "\n".join(lines)


static func _attack_line(ch: Character, weapon: Dictionary) -> String:
	var bonus := Rules.attack_bonus(ch, weapon, 0)
	var damage := String(weapon.get("damage", "1d3"))
	var damage_bonus := Rules.damage_bonus(ch, weapon)
	if damage_bonus != 0:
		damage += "%+d" % damage_bonus
	var range_text := ""
	if int(weapon.get("range_increment", 0)) > 0:
		range_text = ", range increment %d ft." % int(weapon["range_increment"])
	var paralysis := ""
	if int(weapon.get("paralysis_dc", 0)) > 0:
		paralysis = ", paralysis DC %d" % int(weapon["paralysis_dc"])
	var notes: Array[String] = []
	if Rules.weapon_nonproficiency_penalty(ch, weapon) != 0:
		notes.append("non-proficient -4")
	var armor_penalty := Rules.armor_attack_penalty(ch)
	if armor_penalty != 0:
		notes.append("armor/shield %+d" % armor_penalty)
	var suffix := ""
	if not notes.is_empty():
		suffix = " [%s]" % ", ".join(notes)
	return "%s: +%d, %s damage (%s, crit %d-20/x%d%s%s)%s" % [
		String(weapon.get("name", "attack")).capitalize(),
		bonus,
		damage,
		String(weapon.get("damage_type", "untyped")),
		int(weapon.get("crit_range", 20)),
		int(weapon.get("crit_mult", 2)),
		range_text,
		paralysis,
		suffix,
	]


static func inventory(on_change: Callable) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.custom_minimum_size = Vector2(760, 460)
	var gold := ThemeBuilder.body("Party gold: %d gp" % Game.gold, false, 16)
	root.add_child(gold)
	var hint := ThemeBuilder.body(
		"Loot goes to the first conscious adventurer. Equip weapons, armor and shields here; consumables can be used outside combat.",
		true,
		13
	)
	root.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for i in Game.party.size():
		var ch: Character = Game.party[i]
		list.add_child(ThemeBuilder.heading("%s — %s" % [ch.display_name, ch.display_class()], 20))
		var equipped: Array[String] = []
		for slot in ["weapon", "armor", "shield"]:
			var item: Dictionary = ch.equipment.get(slot, {})
			equipped.append("%s: %s" % [slot.capitalize(), String(item.get("name", "—"))])
		list.add_child(ThemeBuilder.body("Equipped — " + " | ".join(equipped), true, 13))
		if ch.inventory.is_empty():
			list.add_child(ThemeBuilder.body("  (empty pack)", true, 13))
			continue
		for entry_index in ch.inventory.size():
			var entry: Dictionary = ch.inventory[entry_index]
			var item: Dictionary = entry.get("item", {})
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var label := ThemeBuilder.body(
				"%s ×%d  [%s]" % [String(item.get("name", "?")), int(entry.get("qty", 1)), String(item.get("kind", ""))],
				false,
				14
			)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var kind := String(item.get("kind", ""))
			if ["weapon", "armor", "shield"].has(kind):
				var captured_i := i
				var captured_index := entry_index
				var equip := Button.new()
				equip.text = "Equip"
				equip.pressed.connect(func() -> void:
					Game.equip_item(captured_i, captured_index)
					on_change.call()
				)
				row.add_child(equip)
			if kind == "consumable":
				var captured_i2 := i
				var captured_index2 := entry_index
				var use := Button.new()
				use.text = "Use"
				use.pressed.connect(func() -> void:
					Game.use_item(captured_i2, captured_index2)
					on_change.call()
				)
				row.add_child(use)
			list.add_child(row)
			var tooltip := ThemeBuilder.body(String(item.get("description", "")), true, 12)
			tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(tooltip)
	return root


static func journal() -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(720, 420)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lines: Array[String] = []
	lines.append(_journal_heading("Quest Journal"))
	lines.append("")
	lines.append(Game.quests.journal_text())
	var notes := journal_notes(Game.flags)
	var facts: Array = notes["facts"]
	var questions: Array = notes["questions"]
	if not facts.is_empty():
		lines.append("")
		lines.append(_journal_heading("What you know"))
		for fact in facts:
			lines.append("  • %s" % String(fact))
	if not questions.is_empty():
		lines.append("")
		lines.append(_journal_heading("Still open"))
		for question in questions:
			lines.append("  • %s" % String(question))
	# A campaign with notes but no earned facts yet says so; a campaign with no
	# notes file adds nothing at all rather than an empty heading.
	if facts.is_empty() and questions.is_empty() and not journal_data().is_empty():
		lines.append("")
		lines.append("[color=#a7b4c0]Nothing recorded yet.[/color]")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.text = "\n".join(lines)
	scroll.add_child(text)
	root.add_child(scroll)
	return root


## The optional authored notes for the current campaign (empty when the campaign
## ships no `journal.json`).
static func journal_data() -> Dictionary:
	if Game.content == null:
		return {}
	var data: Variant = Game.content.journal
	return data if data is Dictionary else {}


## Player-facing Journal lines, derived read-only from the flag dictionary.
##
## Facts appear only once their flag is set, in authored order. A fact whose
## `conflicts_with` partner was already shown is suppressed, and showing a fact
## claims its partners: first entry in the authored list wins, so a save holding
## both sides of a mutually exclusive pair (a hand-edited or corrupted save)
## still produces one deterministic line instead of two contradictory ones.
##
## Questions appear while unresolved: `revealed_by` (optional) must be set for
## the question to surface, and `resolved_by` (optional) hides it once answered.
static func journal_notes(flags: Dictionary) -> Dictionary:
	var facts: Array[String] = []
	var questions: Array[String] = []
	var data := journal_data()
	if data.is_empty():
		return {"facts": facts, "questions": questions}
	var claimed := {}
	for raw in Array(data.get("facts", [])):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var flag := String(entry.get("flag", ""))
		var line := String(entry.get("text", ""))
		if flag == "" or line == "" or claimed.has(flag):
			continue
		if not bool(flags.get(flag, false)):
			continue
		var suppressed := false
		for other in Array(entry.get("conflicts_with", [])):
			if claimed.has(String(other)):
				suppressed = true
				break
		if suppressed:
			continue
		claimed[flag] = true
		for other in Array(entry.get("conflicts_with", [])):
			claimed[String(other)] = true
		facts.append(line)
	for raw in Array(data.get("questions", [])):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var line := String(entry.get("text", ""))
		if line == "":
			continue
		var reveal := String(entry.get("revealed_by", ""))
		if reveal != "" and not bool(flags.get(reveal, false)):
			continue
		var resolve := String(entry.get("resolved_by", ""))
		if resolve != "" and bool(flags.get(resolve, false)):
			continue
		questions.append(line)
	return {"facts": facts, "questions": questions}


## A heading inside the Journal's rich text. Deliberately not bold: the bundled
## font has no bold face, so `[b]` is drawn as a synthetic offset pass and reads
## as doubled glyphs. Size and gold carry the hierarchy instead.
static func _journal_heading(text_value: String) -> String:
	return "[font_size=%d][color=#d6b45f]%s[/color][/font_size]" % [ThemeBuilder.fs(20), text_value]


static func settings(awaiting_action: String, on_rebind: Callable, on_scale_changed: Callable, on_restore_defaults: Callable) -> Control:
	var root := VBoxContainer.new()
	# Width only: the panel already has a size of its own, and a fixed 480 px
	# height overflowed the 453 px body at 100 % text. That 27 px strip was the
	# body's own travel, which nothing could scroll (the keys and the wheel both
	# move the list inside), so the bottom row stayed clipped. Without it the body
	# fits, the list gets the whole height and its last row is fully reachable.
	root.custom_minimum_size = Vector2(720, 0)
	root.add_theme_constant_override("separation", 10)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	# Clear the scrollbar: at 160 % the rebind buttons ran underneath it.
	var list_margin := MarginContainer.new()
	list_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_margin.add_theme_constant_override("margin_right", 18)
	scroll.add_child(list_margin)
	list_margin.add_child(list)
	list.add_child(ThemeBuilder.heading("Audio", 20))
	for volume in [["master", "Master"], ["music", "Music"], ["sfx", "Sound effects"], ["ambience", "Ambience"]]:
		var captured_volume := String(volume[0])
		list.add_child(_slider_row(String(volume[1]), float(Game.settings.get(captured_volume, 0.7)), func(value: float) -> void:
			Game.set_volume(captured_volume, value)
		))
	list.add_child(ThemeBuilder.heading("Display", 20))
	list.add_child(_slider_row("Text size", float(Game.settings.get("text_scale", 1.0)), func(value: float) -> void:
		Game.set_text_scale(value)
		on_scale_changed.call()
	, 0.8, 1.6, 0.05))
	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = bool(Game.settings.get("fullscreen", false))
	fullscreen.toggled.connect(func(value: bool) -> void: Game.set_fullscreen(value))
	list.add_child(fullscreen)
	list.add_child(ThemeBuilder.body("Missing audio files stay silent by design; see docs/ASSET_GUIDE.md.", true, 12))
	list.add_child(ThemeBuilder.heading("Controls", 20))
	list.add_child(ThemeBuilder.body("Click a binding, then press the new key. Changes save immediately.", true, 13))
	for entry in REBIND_ACTIONS:
		var action := String(entry[0])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := ThemeBuilder.body(String(entry[1]), false, 14)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button := Button.new()
		if awaiting_action == action:
			button.text = "Press a key…"
		else:
			button.text = _current_binding(action)
		var captured := action
		button.pressed.connect(func() -> void: on_rebind.call(captured))
		row.add_child(button)
		list.add_child(row)
	list.add_child(ThemeBuilder.body(
		"Restoring defaults discards custom bindings only; audio, display, campaign saves and other settings are kept.",
		true,
		12
	))
	var confirm := ConfirmationDialog.new()
	confirm.title = "Restore default controls"
	confirm.dialog_text = "Restore all keyboard bindings to their shipped defaults?"
	confirm.ok_button_text = "Restore defaults"
	confirm.cancel_button_text = "Cancel"
	confirm.confirmed.connect(func() -> void: on_restore_defaults.call())
	root.add_child(confirm)
	var restore := Button.new()
	restore.text = "Restore Default Controls"
	restore.custom_minimum_size = Vector2(0, 36)
	restore.pressed.connect(func() -> void: confirm.popup_centered())
	list.add_child(restore)
	return root


static func _slider_row(
	label_text: String,
	value: float,
	on_change: Callable,
	min_value := 0.0,
	max_value := 1.0,
	step := 0.05
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := ThemeBuilder.body(label_text, false, 14)
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(220, 24)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	# The readout is sized by its own text. A fixed 52 px column wrapped "160 %"
	# into two lines at the largest text scale, which read as a broken value.
	var readout := ThemeBuilder.body("%d%%" % int(round(value * 100.0)), true, 13)
	readout.autowrap_mode = TextServer.AUTOWRAP_OFF
	readout.size_flags_horizontal = Control.SIZE_SHRINK_END
	readout.custom_minimum_size = Vector2.ZERO
	slider.value_changed.connect(func(v: float) -> void: readout.text = "%d%%" % int(round(v * 100.0)))
	row.add_child(readout)
	return row


static func _current_binding(action: String) -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
	return "Unbound"


static func saves(mode: String, on_done: Callable) -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(700, 380)
	root.add_theme_constant_override("separation", 10)
	root.add_child(ThemeBuilder.body(
		"Saving is available while exploring. Combat and dialogue cannot be saved (deliberate, documented limitation).",
		true,
		13
	))
	var status := ThemeBuilder.body("", false, 13)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	if mode == "save":
		for slot_value in ["slot1", "slot2", "slot3"]:
			var slot := String(slot_value)
			var row := HBoxContainer.new()
			var info := ThemeBuilder.body(
				"%s — %s" % [slot, _save_info(slot)],
				false,
				14
			)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var button := Button.new()
			button.text = "Save here"
			var captured := slot
			button.pressed.connect(func() -> void:
				var result := Game.save_game(captured)
				if bool(result.get("ok", false)):
					# Refreshing shows the timestamp that was actually written.
					on_done.call()
				else:
					# Keep the panel open so a failed write is visible, not implied.
					status.text = String(result.get("message", "Save failed."))
			)
			row.add_child(button)
			list.add_child(row)
	else:
		var saves_list := Game.list_saves()
		if saves_list.is_empty():
			list.add_child(ThemeBuilder.body("No saves yet.", true, 14))
		for save_info in saves_list:
			var row := HBoxContainer.new()
			var source := String(save_info.get("source", "primary"))
			var tag := ""
			if not bool(save_info.get("readable", true)):
				tag = " (unreadable)"
			elif source == "backup":
				tag = " (from backup)"
			elif source == "temp":
				tag = " (unfinished save)"
			var info := ThemeBuilder.body(
				"%s — %s — %s%s" % [String(save_info["slot"]), String(save_info["saved_at"]), String(save_info["summary"]), tag],
				false,
				13
			)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var button := Button.new()
			button.text = "Load"
			var captured_slot := String(save_info["slot"])
			button.pressed.connect(func() -> void:
				var result := Game.load_game(captured_slot)
				status.text = String(result.get("message", ""))
				if not bool(result.get("ok", false)):
					status.text = String(result.get("message", "Load failed."))
					return
				if String(result.get("recovered_from", "")) != "":
					# Keep the panel open so the recovery is read, not implied: the
					# restored game is already live behind it.
					status.text += " The restored game is live behind this panel."
					return
				on_done.call()
			)
			row.add_child(button)
			list.add_child(row)
	root.add_child(status)
	return root


static func _save_info(slot: String) -> String:
	var path := SaveSystem.path_for(slot, Game.campaign_id)
	if not FileAccess.file_exists(path) and Game.campaign_id == Game.LEGACY_CAMPAIGN_ID:
		path = SaveSystem.path_for(slot)
	if not FileAccess.file_exists(path):
		# An interrupted write can leave any working copy with no primary. It is
		# not an empty slot, and saving over it must not look like the first save.
		var found := SaveSystem.first_readable(slot, Game.campaign_id)
		if not found.is_empty():
			var recovered: Dictionary = found["data"]
			return "interrupted — %s — %s" % [
				String(recovered.get("saved_at", "")),
				String(recovered.get("summary", "")),
			]
		if SaveSystem.has_artifacts(slot, Game.campaign_id):
			# Files remain, so this is not an empty slot. Say which way they are
			# unusable: an incompatible copy is a different problem from dead bytes.
			for entry in SaveSystem.slot_files(slot, Game.campaign_id):
				var read := SaveSystem.read_payload(slot, String(entry["path"]))
				if String(read.get("reason", "")) == "unsupported_version":
					return "unreadable — incompatible copy"
			return "damaged — no readable copy"
		return "empty"
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return "%s — %s" % [String(parsed.get("saved_at", "")), String(parsed.get("summary", ""))]
	return "unreadable"


static func pause(on_resume: Callable, on_save: Callable, on_load: Callable, on_settings: Callable, on_menu: Callable) -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(420, 0)
	root.add_theme_constant_override("separation", 10)
	var buttons := [
		["Resume", on_resume],
		["Save game", on_save],
		["Load game", on_load],
		["Settings", on_settings],
		["Return to main menu", on_menu],
	]
	for entry in buttons:
		var button := Button.new()
		button.text = String(entry[0])
		button.custom_minimum_size = Vector2(0, 42)
		var callback: Callable = entry[1]
		button.pressed.connect(func() -> void: callback.call())
		root.add_child(button)
	root.add_child(ThemeBuilder.body(
		"Pause stops input but not the game clock; combat is turn-based, so this is safe.",
		true,
		12
	))
	return root
