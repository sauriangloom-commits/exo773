class_name LevelUpScreen
extends RefCounted

## The 3rd-to-4th level step as a screen (docs/LEVEL_UP_PLAN.md section 14).
##
## Presentation and the draft only. It reads what may be chosen with
## `LevelChoices.choices`, asks `LevelChoices.validate` before it applies anything,
## and calls `LevelUp.apply` once. It never stages: staging belongs to the choice
## module, and a screen that staged would be a second authority on what a legal
## draft is. `tests/test_level_up_ui_surface.gd` pins that surface from the source
## text and `tests/test_level_up_screen.gd` pins it from behaviour.
##
## The draft lives here, in the instance, never in the modal builder:
## `refresh_modal()` rebuilds the body from the builder, so a draft held in
## builder locals would reset the step on every redraw.
##
## The steps are derived from the choice data, not fixed: Summary, Ability, Skills
## and Confirm always, Feat when the class gains one at 4th level, Spells when the
## class has a spell choice. Nothing here needs an arrow key, because
## `_scroll_modal_body` consumes the arrows for body scrolling at 160 %; every row
## is a Button so Tab, Enter and Space are the whole interaction.

const SUMMARY_NAMES := {
	"fort": "SummaryFORT", "ref": "SummaryREF", "will": "SummaryWILL",
}
const SAVE_LABELS := {"fort": "Fortitude", "ref": "Reflex", "will": "Will"}
const STEP_LABELS := {
	"summary": "Summary",
	"ability": "Ability",
	"skills": "Skills",
	"feat": "Feat",
	"spells": "Spells",
	"confirm": "Confirm",
}

var main: Control = null
var ch: Character = null
var page := 0
## Called once when the modal closes, with whether the step was applied. The
## exploration screen uses it to put the party sheet back: the `modal` field is
## singular, so the level-up modal replaces the sheet's rather than stacking.
var on_close: Callable = Callable()
var draft := {"ability": "", "skills": {}, "feat": "", "spell": ""}
var steps: Array[String] = []
var step_index := 0
## The engine calls this screen made, in order. The screen reports its own path;
## the behavioural guarantees behind it are in the tests, which also compare the
## character before and after a refusal.
var trace: Array[String] = []
var refusal_message := ""
var applied := false

var _choices := {}
var _pending_focus := ""


## The step list for a character, read from the choice data rather than fixed:
## a fighter gets Feat, a sorcerer gets Spells, a rogue gets neither.
static func steps_for(character: Character) -> Array[String]:
	var out: Array[String] = ["summary", "ability", "skills"]
	var data := LevelChoices.choices(character, {})
	var feat: Dictionary = data.get("feat", {})
	if not Array(feat.get("options", [])).is_empty():
		out.append("feat")
	var spell: Dictionary = data.get("spell", {})
	if bool(spell.get("required", false)) or not Array(spell.get("options", [])).is_empty():
		out.append("spells")
	out.append("confirm")
	return out


static func step_labels_for(character: Character) -> Array[String]:
	var out: Array[String] = []
	for step in steps_for(character):
		out.append(String(STEP_LABELS.get(step, step)))
	return out


func open() -> void:
	applied = false
	refusal_message = ""
	steps = steps_for(ch)
	step_index = 0
	_pending_focus = ""
	main.open_modal("Level up", build, 900, 620)


func current_step() -> String:
	if steps.is_empty() or step_index < 0 or step_index >= steps.size():
		return ""
	return steps[step_index]


# ------------------------------------------------------------------ the body

## The modal builder. Called by `open_modal` and again by every `refresh_modal`,
## so it may only read the instance state and build controls from it.
func build() -> Control:
	trace.append("LevelChoices.choices")
	_choices = LevelChoices.choices(ch, draft)
	main.modal_on_close = _closed
	if steps.is_empty():
		steps = steps_for(ch)
	step_index = clampi(step_index, 0, maxi(0, steps.size() - 1))
	var root := VBoxContainer.new()
	root.name = "LevelUpBody"
	root.custom_minimum_size = Vector2(700, 0)
	root.add_theme_constant_override("separation", 8)
	root.add_child(_build_strip())
	var title := ThemeBuilder.heading(String(STEP_LABELS.get(current_step(), "")), 18)
	title.name = "StepTitle"
	root.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "StepScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rows := VBoxContainer.new()
	rows.name = "StepRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	_fill_step(rows)
	scroll.add_child(rows)
	root.add_child(scroll)
	root.add_child(_build_refusal())
	root.add_child(_build_footer())
	var target := _pending_focus
	_pending_focus = ""
	if target == "":
		target = _chosen_control_name()
	# Deferred so it lands after `open_modal` has focused the header's Close.
	call_deferred("_grab", target)
	return root


func _build_strip() -> Control:
	var strip := HBoxContainer.new()
	strip.name = "StepStrip"
	strip.add_theme_constant_override("separation", 10)
	for index in steps.size():
		var current := index == step_index
		var label := ThemeBuilder.short(String(STEP_LABELS.get(steps[index], "")), not current, 13)
		label.name = "Step_%d" % index
		if current:
			label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
		strip.add_child(label)
	return strip


func _build_refusal() -> Control:
	var label := ThemeBuilder.body(refusal_message, false, 13)
	label.name = "Refusal"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
	label.visible = refusal_message != ""
	return label


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 8)
	var back := _footer_button("Back", "footer_back")
	back.disabled = step_index == 0
	back.pressed.connect(_back)
	footer.add_child(back)
	var cancel := _footer_button("Cancel", "footer_cancel")
	cancel.pressed.connect(_cancel)
	footer.add_child(cancel)
	var forward := _footer_button(_forward_label(), "footer_forward")
	forward.disabled = not _forward_enabled()
	forward.pressed.connect(_forward)
	footer.add_child(forward)
	return footer


func _footer_button(text: String, control_name: String) -> Button:
	var button := Button.new()
	button.text = text
	button.name = control_name
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _forward_label() -> String:
	return "Apply level up" if current_step() == "confirm" else "Continue"


## Only the ability step blocks the forward button: the choice is required and a
## player should not have to discover that on Confirm. A missing feat or spell is
## left to Confirm, where `LevelChoices.validate` states the engine's own reason -
## that is the refusal path the tests pin.
func _forward_enabled() -> bool:
	if not bool(_choices.get("ok", false)):
		return false
	if current_step() == "ability":
		return String(draft.get("ability", "")) != ""
	return true


# ----------------------------------------------------------------- the steps

func _fill_step(rows: VBoxContainer) -> void:
	if not bool(_choices.get("ok", false)):
		rows.add_child(ThemeBuilder.body(String(_choices.get("message", "")), true, 14))
		return
	match current_step():
		"summary":
			_fill_summary(rows)
		"ability":
			_fill_ability(rows)
		"skills":
			_fill_skills(rows)
		"feat":
			_fill_feat(rows)
		"spells":
			_fill_spells(rows)
		"confirm":
			_fill_confirm(rows)


func _fill_summary(rows: VBoxContainer) -> void:
	var preview := LevelUp.preview(ch, draft)
	if not bool(preview.get("ok", false)):
		rows.add_child(_summary("SummaryHP", String(preview.get("message", "")), true))
		return
	var hp: Dictionary = preview["hit_points"]
	rows.add_child(_summary("SummaryHP", "Hit points: %d/%d -> %d/%d" % [
		int(hp["hp_before"]), int(hp["max_before"]), int(hp["hp_after"]), int(hp["max_after"]),
	]))
	var bab: Dictionary = preview["base_attack"]
	rows.add_child(_summary("SummaryBAB", "Base attack: +%d -> +%d" % [
		int(bab["before"]), int(bab["after"]),
	]))
	var saves: Dictionary = preview["base_saves"]
	for save in ["fort", "ref", "will"]:
		var entry: Dictionary = saves[save]
		rows.add_child(_summary(String(SUMMARY_NAMES[save]), "%s: +%d -> +%d" % [
			String(SAVE_LABELS[save]), int(entry["before"]), int(entry["after"]),
		]))
	var ability: Dictionary = preview["ability"]
	var ability_text := "Ability increase: 1 point"
	if String(ability.get("key", "")) != "":
		ability_text = "Ability increase: %s %d -> %d" % [
			String(ability["key"]).to_upper(), int(ability["before"]), int(ability["after"]),
		]
	rows.add_child(_summary("SummaryAbility", ability_text))
	rows.add_child(_summary(
		"SummarySkills", "Skill points: %d" % int(Dictionary(_choices["skills"])["budget"])
	))
	var granted := int(Dictionary(_choices["feat"])["granted"])
	rows.add_child(_summary(
		"SummaryFeat", "Feat slot: none" if granted < 1 else "Feat slot: %d" % granted
	))
	rows.add_child(_summary("SummarySpells", _spell_slots_text(preview)))
	for notice in Array(preview.get("notices", [])):
		rows.add_child(_summary("SummaryNotice", String(notice), true))


func _spell_slots_text(preview: Dictionary) -> String:
	var after: Dictionary = Dictionary(preview.get("spells", {})).get("slots_after", {})
	var before: Dictionary = Dictionary(preview.get("spells", {})).get("slots_before", {})
	if after.is_empty():
		return "Spell slots: none"
	var lines: Array[String] = ["Spell slots:"]
	var levels: Array = after.keys()
	levels.sort()
	for raw_level in levels:
		var key := String(raw_level)
		var entry: Dictionary = Dictionary(after[raw_level])
		var prior: Dictionary = Dictionary(before.get(key, {}))
		lines.append("  level %s: %d -> %d" % [
			key, int(prior.get("max", 0)), int(entry.get("max", 0)),
		])
	return "\n".join(lines)


## A read-only line. Named so the tests read the summary by key and compare the
## numbers to `LevelUp.preview`, not to rendered prose.
func _summary(control_name: String, text: String, muted := false) -> Label:
	var label := ThemeBuilder.body(text, muted, 14)
	label.name = control_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _fill_ability(rows: VBoxContainer) -> void:
	var group := ButtonGroup.new()
	var scores: Dictionary = Dictionary(_choices["ability"]).get("scores", {})
	var chosen := String(draft.get("ability", ""))
	for raw_key in LevelUp.ABILITIES:
		var key := String(raw_key)
		var data: Dictionary = scores.get(key, {})
		var before := int(data.get("before", 10))
		var text := "%s %d" % [key.to_upper(), before]
		if key == chosen:
			text = "%s %d -> %d" % [key.to_upper(), before, int(data.get("after", before))]
		var button := _row_button(text, "ability_" + key)
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = key == chosen
		var captured := key
		button.pressed.connect(func() -> void: _choose_ability(captured))
		rows.add_child(button)
	if chosen == "":
		rows.add_child(_summary("AbilityHint", "Choose the score this level raises.", true))


func _fill_skills(rows: VBoxContainer) -> void:
	var skills: Dictionary = _choices["skills"]
	var spent := int(skills["spent"])
	var budget := int(skills["budget"])
	var header := ThemeBuilder.body("Spent %d of %d points" % [spent, budget], false, 14)
	header.name = "SpentHeader"
	rows.add_child(header)
	if spent < budget:
		rows.add_child(_summary(
			"SkillsHint", "Unspent points are discarded when the level is applied.", true
		))
	var reset := _row_button("Reset points", "skill_reset")
	reset.disabled = spent == 0
	reset.pressed.connect(_reset_skills)
	rows.add_child(reset)
	for raw in Array(skills["options"]):
		var row := Dictionary(raw)
		var skill := String(row["skill"])
		var ranks := int(row["ranks"])
		var max_new := int(row["max_new_ranks"])
		var text := "%s %d" % [String(row["name"]), ranks]
		if max_new > 0:
			var cost := int(row["cost_per_rank"])
			text += " -> %d (%d point%s)" % [ranks + 1, cost, "" if cost == 1 else "s"]
		else:
			text += " — " + _block_reason(row, int(skills["remaining"]))
		var button := _row_button(text, "skill_" + skill)
		button.disabled = max_new <= 0
		var captured := skill
		button.pressed.connect(func() -> void: _spend_skill(captured))
		rows.add_child(button)


## Why a skill row cannot take a point now, in the row itself: a disabled row
## without a reason reads as a bug.
func _block_reason(row: Dictionary, remaining: int) -> String:
	var ranks := int(row["ranks"])
	var cap := int(row["cap"])
	if ranks >= cap:
		return "at the %d-rank cap" % cap
	var cost := int(row["cost_per_rank"])
	if remaining < cost:
		return "needs %d point%s, %d left" % [cost, "" if cost == 1 else "s", remaining]
	return "no point available"


func _fill_feat(rows: VBoxContainer) -> void:
	var group := ButtonGroup.new()
	var chosen := String(draft.get("feat", ""))
	for raw in Array(Dictionary(_choices["feat"])["options"]):
		var row := Dictionary(raw)
		# Display the readable label; the draft captures `text`, which is the stored
		# value the engine parses, so a weapon parameter stays an item id.
		var text := String(row["text"])
		var label := String(row.get("label", text))
		if not bool(row["eligible"]):
			label += " — " + "; ".join(PackedStringArray(row["reasons"]))
		var button := _row_button(label, _feat_control_name(row))
		button.toggle_mode = true
		button.button_group = group
		button.disabled = not bool(row["eligible"])
		button.button_pressed = String(row["text"]) == chosen
		var captured := String(row["text"])
		button.pressed.connect(func() -> void: _choose_feat(captured))
		rows.add_child(button)


func _feat_control_name(row: Dictionary) -> String:
	var parameter := String(row.get("param", ""))
	var base := "feat_" + String(row.get("key", ""))
	return base if parameter == "" else "%s_%s" % [base, parameter]


func _fill_spells(rows: VBoxContainer) -> void:
	var group := ButtonGroup.new()
	var chosen := String(draft.get("spell", ""))
	for raw in Array(Dictionary(_choices["spell"])["options"]):
		var row := Dictionary(raw)
		var spell_id := String(row["id"])
		var text := "%s (%s, level %d)" % [
			String(row["name"]), String(row["school"]), int(row["level"]),
		]
		var button := _row_button(text, "spell_" + spell_id)
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = spell_id == chosen
		var captured := spell_id
		button.pressed.connect(func() -> void: _choose_spell(captured))
		rows.add_child(button)


func _fill_confirm(rows: VBoxContainer) -> void:
	var preview := LevelUp.preview(ch, draft)
	if not bool(preview.get("ok", false)):
		rows.add_child(ThemeBuilder.body(String(preview.get("message", "")), true, 14))
		return
	var hp: Dictionary = preview["hit_points"]
	rows.add_child(_summary("ConfirmLevel", "Level %d -> %d" % [
		int(preview["from_level"]), int(preview["to_level"]),
	]))
	rows.add_child(_summary("ConfirmHP", "Hit points %d/%d -> %d/%d" % [
		int(hp["hp_before"]), int(hp["max_before"]), int(hp["hp_after"]), int(hp["max_after"]),
	]))
	var bab: Dictionary = preview["base_attack"]
	rows.add_child(_summary("ConfirmBAB", "Base attack +%d -> +%d" % [
		int(bab["before"]), int(bab["after"]),
	]))
	var saves: Dictionary = preview["base_saves"]
	for save in ["fort", "ref", "will"]:
		var entry: Dictionary = saves[save]
		rows.add_child(_summary("Confirm" + String(save).to_upper(), "%s +%d -> +%d" % [
			String(SAVE_LABELS[save]), int(entry["before"]), int(entry["after"]),
		]))
	var ability: Dictionary = preview["ability"]
	rows.add_child(_summary("ConfirmAbility", "Ability: %s %d -> %d" % [
		String(ability["key"]).to_upper(), int(ability["before"]), int(ability["after"]),
	]))
	var ranks: Dictionary = Dictionary(preview["skills"])["ranks"]
	var skill_lines: Array[String] = []
	var skill_keys: Array = ranks.keys()
	skill_keys.sort()
	for raw_skill in skill_keys:
		skill_lines.append("%s +%d" % [Skills.name(String(raw_skill)), int(ranks[raw_skill])])
	rows.add_child(_summary(
		"ConfirmSkills",
		"Skills: none" if skill_lines.is_empty() else "Skills: " + ", ".join(skill_lines),
	))
	rows.add_child(_summary("ConfirmFeat", _confirm_feat_text(preview)))
	rows.add_child(_summary("ConfirmSpells", _confirm_spell_text(preview)))


func _confirm_feat_text(preview: Dictionary) -> String:
	var feat: Dictionary = preview["feat"]
	var granted := String(feat.get("granted", ""))
	if granted != "":
		return "Feat: " + granted
	if int(feat.get("slots_after", 0)) > int(feat.get("slots_before", 0)):
		return "Feat: none chosen"
	return "Feat: this class gains none at 4th level"


func _confirm_spell_text(preview: Dictionary) -> String:
	var known: Array = Array(preview["spells"].get("known_before", [])).duplicate()
	for raw_id in Array(preview["spells"].get("known_after", [])):
		if not known.has(raw_id):
			var spell := Game.content.get_spell(String(raw_id)) if Game.content != null else {}
			return "Spell: " + String(spell.get("name", raw_id))
	return "Spell: this class learns none at 4th level"


func _row_button(text: String, control_name: String) -> Button:
	var button := Button.new()
	button.text = text
	button.name = control_name
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


# ------------------------------------------------------------------ the draft

func _choose_ability(key: String) -> void:
	if String(draft.get("ability", "")) == key:
		return
	draft["ability"] = key
	_rebuild("ability_" + key)


func _choose_feat(text: String) -> void:
	if String(draft.get("feat", "")) == text:
		return
	draft["feat"] = text
	_rebuild("")


func _choose_spell(spell_id: String) -> void:
	if String(draft.get("spell", "")) == spell_id:
		return
	draft["spell"] = spell_id
	_rebuild("spell_" + spell_id)


## One rank per press, and only when the choice data says the row can take one:
## the screen never decides a cost or a cap itself.
func _spend_skill(skill: String) -> void:
	var data := LevelChoices.choices(ch, draft)
	if not bool(data.get("ok", false)):
		return
	var row := {}
	for raw in Array(Dictionary(data["skills"])["options"]):
		if String(Dictionary(raw).get("skill", "")) == skill:
			row = Dictionary(raw)
			break
	if row.is_empty() or int(row.get("max_new_ranks", 0)) <= 0:
		return
	var skills := Dictionary(draft.get("skills", {})).duplicate()
	skills[skill] = int(skills.get(skill, 0)) + 1
	draft["skills"] = skills
	_rebuild("skill_" + skill)


func _reset_skills() -> void:
	draft["skills"] = {}
	_rebuild("skill_reset")


# ----------------------------------------------------------------- navigation

func _back() -> void:
	if step_index == 0:
		return
	step_index -= 1
	refusal_message = ""
	_rebuild(_chosen_control_name())


func _forward() -> void:
	if current_step() == "confirm":
		confirm()
		return
	if not _forward_enabled():
		return
	step_index += 1
	refusal_message = ""
	_rebuild("")


func _cancel() -> void:
	main.close_modal()


## Validates first, then applies once. A refusal keeps the modal open on the same
## step, shows the engine's own message and moves focus to the refused group, so
## the player can go Back, change the answer and try again.
func confirm() -> void:
	trace.append("LevelChoices.validate")
	var result := LevelChoices.validate(ch, draft)
	if not bool(result.get("ok", false)):
		refusal_message = String(result.get("message", "The level-up cannot be applied."))
		var fields: Dictionary = result.get("fields", {})
		var field := String(fields.keys()[0]) if not fields.is_empty() else ""
		# The step that owns the refusal is the step whose controls the player
		# has to change, so the modal moves there rather than leaving focus on
		# a Confirm row it cannot act on. The modal itself stays open.
		var owner_step := _step_for_field(field)
		var owner_index := steps.find(owner_step)
		if owner_step != "" and owner_index >= 0:
			step_index = owner_index
		_pending_focus = _group_focus(field)
		main.refresh_modal()
		return
	refusal_message = ""
	trace.append("LevelUp.apply")
	var applied_result := LevelUp.apply(ch, draft)
	if not bool(applied_result.get("ok", false)):
		# The engine disagreed with validate. Show it rather than closing on a
		# half-applied screen; the character is unchanged either way.
		refusal_message = String(applied_result.get("message", "The level-up cannot be applied."))
		main.refresh_modal()
		return
	applied = true
	main.close_modal()


func _rebuild(focus_name: String) -> void:
	_pending_focus = focus_name
	main.refresh_modal()


## The control to put focus on for the current step, from the draft: what the
## player chose here is what they should come back to.
func _chosen_control_name() -> String:
	match current_step():
		"ability":
			var ability := String(draft.get("ability", ""))
			return "" if ability == "" else "ability_" + ability
		"skills":
			var skills := Dictionary(draft.get("skills", {}))
			var keys: Array = skills.keys()
			keys.sort()
			return "" if keys.is_empty() else "skill_" + String(keys[0])
		"feat":
			for raw in Array(Dictionary(_choices.get("feat", {})).get("options", [])):
				var row := Dictionary(raw)
				if String(row.get("text", "")) == String(draft.get("feat", "")):
					return _feat_control_name(row)
			return ""
		"spells":
			var spell := String(draft.get("spell", ""))
			return "" if spell == "" else "spell_" + spell
	return ""


## The step that owns a refusal group, so a refusal can land where the answer is.
func _step_for_field(field: String) -> String:
	match field:
		"feat":
			return "feat" if steps.has("feat") else ""
		"spell":
			return "spells" if steps.has("spells") else ""
		"skills":
			return "skills"
		"ability":
			return "ability"
	return ""


func _group_focus(field: String) -> String:
	match field:
		"feat":
			return "@feat_"
		"spell":
			return "@spell_"
		"skills":
			return "@skill_"
		"ability":
			return "@ability_"
	return ""


## `@prefix` means "the first row of that group that can be chosen": a disabled
## row can hold focus only if the trap let it there, and the refusal should land
## on something the player can act on.
func _grab(control_name: String) -> void:
	if main == null:
		return
	var root: Control = main.get("modal")
	if root == null:
		return
	var target: Control = null
	if control_name.begins_with("@"):
		var prefix := control_name.substr(1)
		var rows := root.find_child("StepRows", true, false)
		if rows != null:
			for child in rows.get_children():
				var button := child as Button
				if button == null:
					continue
				if String(button.name).begins_with(prefix) and not button.disabled:
					target = button
					break
	elif control_name != "":
		target = root.find_child(control_name, true, false) as Control
	if not _can_take_focus(target):
		target = _first_control(root)
	if _can_take_focus(target):
		target.grab_focus()


func _first_control(root: Control) -> Control:
	var rows := root.find_child("StepRows", true, false)
	if rows != null:
		for child in rows.get_children():
			var button := child as Button
			if button != null and not button.disabled:
				return button
	var footer := root.find_child("Footer", true, false)
	if footer != null:
		for child in footer.get_children():
			var button := child as Button
			if button != null and not button.disabled:
				return button
	return null


func _can_take_focus(control: Control) -> bool:
	if control == null:
		return false
	if not control.is_inside_tree() or not control.is_visible_in_tree():
		return false
	if control.focus_mode == Control.FOCUS_NONE:
		return false
	var button := control as Button
	return button == null or not button.disabled


## The modal closed. `close_modal` runs this once, whichever path closed it, so
## Cancel, the header Close and Esc all leave the same result.
func _closed() -> void:
	if on_close.is_valid():
		on_close.call(applied)
