class_name CampaignCreator
extends Control

## Bounded campaign creator: metadata, small areas, entry point, transitions, an
## NPC placement and a form-based branching-dialogue editor.
##
## Encounter and quest editing are later slices. Everything here works on the
## in-memory draft; `CampaignStore` validates a temporary copy and writes the
## real package only on explicit save.

var main: Control
var draft: Dictionary = {}
var selected_area := 0
var selected_cell := Vector2i(-1, -1)
var dirty := false

var header_meta: Label
var save_button: Button
var validate_button: Button
var play_button: Button
var scroll: ScrollContainer
var title_edit: LineEdit
var description_edit: TextEdit
var area_name_edit: LineEdit
var facing_option: OptionButton
var area_list: VBoxContainer
var map_grid: GridContainer
var selection_label: Label
var status_label: Label
var pending_label: Label
var diagnostics_panel: VBoxContainer
var diagnostics: Array = []
var last_focused_control: Control
var set_entry_button: Button
var target_option: OptionButton
var transitions_label: Label

var npc_option: OptionButton
var npc_id_edit: LineEdit
var npc_name_edit: LineEdit
var npc_look_edit: TextEdit
var npc_dialogue_option: OptionButton
var npc_status: Label
var dialogue_option: OptionButton
var dialogue_id_edit: LineEdit
var speaker_edit: LineEdit
var start_option: OptionButton
var node_option: OptionButton
var node_id_edit: LineEdit
var node_text_edit: TextEdit
var node_next_option: OptionButton
var node_narration_edit: LineEdit
var node_flag_edit: LineEdit
var choice_option: OptionButton
var choice_text_edit: LineEdit
var choice_dest_option: OptionButton
var choice_check_toggle: CheckBox
var choice_plain_box: VBoxContainer
var choice_check_box: VBoxContainer
var choice_skill_option: OptionButton
var choice_dc_spin: SpinBox
var choice_actor_option: OptionButton
var choice_success_option: OptionButton
var choice_failure_option: OptionButton
var choice_guard_edit: LineEdit
var choice_require_edit: LineEdit
var choice_effect_edit: LineEdit
var dialogue_preview: Label
var choice_flag_option: OptionButton
var choice_quest_option: OptionButton
var choice_encounter_option: OptionButton
var quest_option: OptionButton
var quest_id_edit: LineEdit
var quest_title_edit: LineEdit
var quest_summary_edit: TextEdit
var quest_start_option: OptionButton
var quest_completion_option: OptionButton
var objective_option: OptionButton
var objective_id_edit: LineEdit
var objective_text_edit: LineEdit
var objective_flag_edit: LineEdit
var objective_flag_option: OptionButton
var quest_refs_label: Label
var flag_edit: LineEdit
var flag_desc_edit: LineEdit
var flags_label: Label
var encounter_option: OptionButton
var encounter_id_edit: LineEdit
var encounter_name_edit: LineEdit
var encounter_xp_spin: SpinBox
var encounter_intro_edit: LineEdit
var encounter_template_option: OptionButton
var encounter_monster_option: OptionButton
var encounter_monsters_label: Label
var victory_flag_edit: LineEdit
var victory_flag_option: OptionButton
var victory_narration_edit: LineEdit
var victory_quest_option: OptionButton
var trigger_option: OptionButton
var trigger_guard_edit: LineEdit
var trigger_narration_edit: LineEdit
var trigger_status: Label
var _selected_quest_id := ""
var _selected_objective_id := ""
var _selected_encounter_id := ""
var _selected_trigger_id := ""
var _monsters_cache := {}
var _selected_npc_id := ""
var _selected_dialogue_id := ""
var _selected_node_id := ""
var _selected_choice := 0
var _syncing_interaction := false


func setup(main_ref: Control, draft_ref: Dictionary) -> void:
	main = main_ref
	draft = draft_ref
	selected_area = 0
	_build()
	_refresh_all()
	_connect_pending_signals(self)
	_refresh_pending_label()


func capture_draft() -> Dictionary:
	if title_edit != null:
		draft["title"] = title_edit.text.strip_edges()
	if description_edit != null:
		draft["description"] = description_edit.text
	var area := _current_area()
	if not area.is_empty() and area_name_edit != null:
		area["name"] = area_name_edit.text.strip_edges()
	return draft


func _current_area() -> Dictionary:
	var areas: Array = Array(draft.get("areas", []))
	if selected_area < 0 or selected_area >= areas.size():
		return {}
	return Dictionary(areas[selected_area])


func _area_id() -> String:
	return String(_current_area().get("id", ""))


## QA/visual aid: scrolls the real creator so the interaction editor is visible
## at the supported minimum window size without changing layout or content.
func focus_interaction_section() -> void:
	await get_tree().process_frame
	if scroll == null or npc_option == null:
		return
	var offset := npc_option.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical
	scroll.scroll_vertical = maxi(0, int(offset) - 64)


## QA/visual aid: scrolls to the conversation identity and node fields.
func focus_dialogue_section() -> void:
	await get_tree().process_frame
	if scroll == null or node_text_edit == null:
		return
	var offset := dialogue_id_edit.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical
	scroll.scroll_vertical = maxi(0, int(offset) - 120)


## QA/visual aid: scrolls to the quest and flag editors.
func focus_quest_section() -> void:
	await get_tree().process_frame
	if scroll == null or quest_option == null:
		return
	var offset := quest_option.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical
	scroll.scroll_vertical = maxi(0, int(offset) - 60)


## QA/visual aid: scrolls to the campaign flag definition fields.
func focus_flag_section() -> void:
	await get_tree().process_frame
	if scroll == null or flag_edit == null:
		return
	var offset := flag_edit.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical
	scroll.scroll_vertical = maxi(0, int(offset) - 80)


## QA/visual aid: scrolls to the trigger guard fields.
func focus_trigger_section() -> void:
	await get_tree().process_frame
	if scroll == null or trigger_guard_edit == null:
		return
	var offset := trigger_guard_edit.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical
	scroll.scroll_vertical = maxi(0, int(offset) - 80)


## QA/visual aid: scrolls to the encounter and trigger editors.
func focus_encounter_section() -> void:
	await get_tree().process_frame
	if scroll == null or encounter_option == null:
		return
	var offset := encounter_option.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical
	scroll.scroll_vertical = maxi(0, int(offset) - 60)


## QA/visual aid: scrolls to the response form and its check/flag controls.
func focus_choices_section() -> void:
	await get_tree().process_frame
	if scroll == null or choice_option == null:
		return
	var offset := choice_option.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.scroll_vertical
	scroll.scroll_vertical = maxi(0, int(offset) - 180)


## Every supported entity form is protected the same way: compare its live
## controls to the applied draft, then require Apply / Discard / Cancel before a
## transition would overwrite them. There is no silent commit.
func _connect_pending_signals(node: Node) -> void:
	for child in node.get_children():
		if child is LineEdit:
			child.text_changed.connect(func(_value: String) -> void: _refresh_pending_label())
		elif child is TextEdit:
			child.text_changed.connect(func() -> void: _refresh_pending_label())
		elif child is OptionButton:
			child.item_selected.connect(func(_index: int) -> void: _refresh_pending_label())
		elif child is CheckBox:
			child.toggled.connect(func(_pressed: bool) -> void: _refresh_pending_label())
		elif child is SpinBox:
			child.value_changed.connect(func(_value: float) -> void: _refresh_pending_label())
		_connect_pending_signals(child)


func _refresh_pending_label() -> void:
	if pending_label == null:
		return
	var keys := pending_form_keys()
	pending_label.visible = not keys.is_empty()
	pending_label.text = ""
	if not keys.is_empty():
		var labels: Array[String] = []
		for key in keys:
			labels.append(_form_label(key))
		pending_label.text = "Pending form edits: %s. Apply or discard before changing entity, saving, or playtesting." % ", ".join(labels)


func _form_label(key: String) -> String:
	match key:
		"npc": return "NPC"
		"dialogue": return "conversation identity"
		"node": return "dialogue node"
		"choice": return "response"
		"quest": return "quest"
		"objective": return "objective"
		"encounter": return "encounter"
		"victory": return "victory consequences"
		"trigger": return "trigger"
	return key


func _selected_meta(option: OptionButton) -> String:
	if option == null or option.selected < 0 or option.selected >= option.item_count:
		return ""
	return String(option.get_item_metadata(option.selected))


## A stored value that the picker cannot represent is already an invalid applied
## value, not a user edit. Only a representable value that differs is pending.
func _option_pending(option: OptionButton, stored: String) -> bool:
	if _selected_meta(option) == stored:
		return false
	for i in option.item_count:
		if String(option.get_item_metadata(i)) == stored:
			return true
	return false


func _node_effect_values(node: Dictionary) -> Dictionary:
	var narration := ""
	var flag := ""
	for raw_effect in Array(node.get("effects", [])):
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		if String(effect.get("type", "")) == "narration" and narration == "":
			narration = String(effect.get("text", ""))
		if String(effect.get("type", "")) == "set_flag" and flag == "":
			flag = String(effect.get("flag", ""))
	return {"narration": narration, "flag": flag}


func _choice_form_state() -> Dictionary:
	var check_on := choice_check_toggle != null and choice_check_toggle.button_pressed
	var state := {
		"text": choice_text_edit.text if choice_text_edit != null else "",
		"guard": choice_guard_edit.text if choice_guard_edit != null else "",
		"require": choice_require_edit.text if choice_require_edit != null else "",
		"effect": choice_effect_edit.text if choice_effect_edit != null else "",
		"quest": _selected_meta(choice_quest_option),
		"encounter": _selected_meta(choice_encounter_option),
		"check": check_on,
		"skill": _selected_meta(choice_skill_option) if check_on else "",
		"dc": int(choice_dc_spin.value) if choice_dc_spin != null else 0,
		"actor": _selected_meta(choice_actor_option) if check_on else "",
		"success": _selected_meta(choice_success_option) if check_on else "",
		"failure": _selected_meta(choice_failure_option) if check_on else "",
		"next": _selected_meta(choice_dest_option) if not check_on else "",
	}
	return state


func _stored_choice_state(choice: Dictionary) -> Dictionary:
	var check: Dictionary = Dictionary(choice.get("check", {}))
	var check_on := not check.is_empty()
	var guard := ""
	var require_flag := ""
	for raw_condition in Array(choice.get("conditions", [])):
		if not raw_condition is Dictionary:
			continue
		var condition: Dictionary = raw_condition
		if String(condition.get("type", "")) == "not_flag" and guard == "":
			guard = String(condition.get("flag", ""))
		if String(condition.get("type", "")) == "flag" and require_flag == "":
			require_flag = String(condition.get("flag", ""))
	var effect_flag := ""
	var effect_quest := ""
	var effect_encounter := ""
	for raw_effect in Array(choice.get("effects", [])):
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		if String(effect.get("type", "")) == "set_flag" and effect_flag == "":
			effect_flag = String(effect.get("flag", ""))
		if String(effect.get("type", "")) == "quest_start" and effect_quest == "":
			effect_quest = String(effect.get("quest", ""))
		if String(effect.get("type", "")) == "start_combat" and effect_encounter == "":
			effect_encounter = String(effect.get("encounter", ""))
	return {
		"text": String(choice.get("text", "")),
		"guard": guard,
		"require": require_flag,
		"effect": effect_flag,
		"quest": effect_quest,
		"encounter": effect_encounter,
		"check": check_on,
		"skill": String(check.get("skill", "")) if check_on else "",
		"dc": int(check.get("dc", 12)) if check_on else 12,
		"actor": String(check.get("actor", "best")) if check_on else "",
		"success": String(check.get("success", "")) if check_on else "",
		"failure": String(check.get("failure", "")) if check_on else "",
		"next": String(choice.get("next", "")) if not check_on else "",
	}


func pending_form_keys() -> Array[String]:
	var keys: Array[String] = []
	if _npc_form_pending():
		keys.append("npc")
	if _dialogue_form_pending():
		keys.append("dialogue")
	if _node_form_pending():
		keys.append("node")
	if _choice_form_pending():
		keys.append("choice")
	if _quest_form_pending():
		keys.append("quest")
	if _objective_form_pending():
		keys.append("objective")
	if _encounter_form_pending():
		keys.append("encounter")
	if _victory_form_pending():
		keys.append("victory")
	if _trigger_form_pending():
		keys.append("trigger")
	return keys


func _npc_form_pending() -> bool:
	if npc_name_edit == null or _selected_npc_id == "":
		return false
	var npc := CampaignStore.find_npc(draft, _area_id(), _selected_npc_id)
	if npc.is_empty():
		return false
	return npc_id_edit.text.strip_edges() != _selected_npc_id \
		or npc_name_edit.text.strip_edges() != String(npc.get("name", "")) \
		or npc_look_edit.text != String(npc.get("look", "")) \
		or _option_pending(npc_dialogue_option, String(npc.get("dialogue", "")))


func _dialogue_form_pending() -> bool:
	if dialogue_id_edit == null or _selected_dialogue_id == "":
		return false
	var dialogue := CampaignStore.dialogue_by_id(draft, _selected_dialogue_id)
	if dialogue.is_empty():
		return false
	return dialogue_id_edit.text.strip_edges() != _selected_dialogue_id \
		or speaker_edit.text.strip_edges() != String(dialogue.get("speaker", ""))


func _node_form_pending() -> bool:
	if node_text_edit == null or _selected_dialogue_id == "" or _selected_node_id == "":
		return false
	var nodes := Dictionary(CampaignStore.dialogue_by_id(draft, _selected_dialogue_id).get("nodes", {}))
	if not nodes.has(_selected_node_id):
		return false
	var node: Dictionary = Dictionary(nodes[_selected_node_id])
	var effects := _node_effect_values(node)
	return node_text_edit.text != String(node.get("text", "")) \
		or _option_pending(node_next_option, String(node.get("next", ""))) \
		or node_narration_edit.text != String(effects.get("narration", "")) \
		or node_flag_edit.text != String(effects.get("flag", ""))


func _choice_form_pending() -> bool:
	if choice_text_edit == null or _selected_node_id == "":
		return false
	var dialogue := CampaignStore.dialogue_by_id(draft, _selected_dialogue_id)
	var node: Dictionary = Dictionary(Dictionary(dialogue.get("nodes", {})).get(_selected_node_id, {}))
	var choices: Array = Array(node.get("choices", []))
	if _selected_choice < 0 or _selected_choice >= choices.size():
		return false
	var current := _choice_form_state()
	var stored := _stored_choice_state(Dictionary(choices[_selected_choice]))
	for key in ["text", "guard", "require", "effect"]:
		if current[key] != stored[key]:
			return true
	if bool(current["check"]) != bool(stored["check"]):
		return true
	if _option_pending(choice_quest_option, String(stored["quest"])):
		return true
	if _option_pending(choice_encounter_option, String(stored["encounter"])):
		return true
	if bool(current["check"]):
		# Skill, DC and branch targets only exist for a check. A DC or skill
		# left in the form by an earlier check is not an edit to a plain choice.
		if int(current["dc"]) != int(stored["dc"]):
			return true
		return _option_pending(choice_skill_option, String(stored["skill"])) \
			or _option_pending(choice_actor_option, String(stored["actor"])) \
			or _option_pending(choice_success_option, String(stored["success"])) \
			or _option_pending(choice_failure_option, String(stored["failure"]))
	return _option_pending(choice_dest_option, String(stored["next"]))


func _quest_form_pending() -> bool:
	if quest_title_edit == null or _selected_quest_id == "":
		return false
	var quest := CampaignStore.quest_by_id(draft, _selected_quest_id)
	if quest.is_empty():
		return false
	return quest_title_edit.text != String(quest.get("title", "")) \
		or quest_summary_edit.text != String(quest.get("summary", "")) \
		or _option_pending(quest_start_option, String(draft.get("start_quest", ""))) \
		or _option_pending(quest_completion_option, String(draft.get("completion_quest", "")))


func _objective_form_pending() -> bool:
	if objective_text_edit == null or _selected_objective_id == "":
		return false
	for raw_objective in Array(CampaignStore.quest_by_id(draft, _selected_quest_id).get("objectives", [])):
		if raw_objective is Dictionary and String(Dictionary(raw_objective).get("id", "")) == _selected_objective_id:
			var objective: Dictionary = raw_objective
			return objective_id_edit.text.strip_edges() != _selected_objective_id \
				or objective_text_edit.text != String(objective.get("text", "")) \
				or objective_flag_edit.text != String(objective.get("flag", ""))
	return false


func _encounter_form_pending() -> bool:
	if encounter_name_edit == null or _selected_encounter_id == "":
		return false
	var encounter := CampaignStore.encounter_by_id(draft, _selected_encounter_id)
	if encounter.is_empty():
		return false
	return encounter_name_edit.text != String(encounter.get("name", "")) \
		or int(encounter_xp_spin.value) != int(encounter.get("xp", 0)) \
		or encounter_intro_edit.text != String(encounter.get("intro", ""))


func _victory_form_pending() -> bool:
	if victory_flag_edit == null or _selected_encounter_id == "":
		return false
	var encounter := CampaignStore.encounter_by_id(draft, _selected_encounter_id)
	if encounter.is_empty():
		return false
	var stored_flag := ""
	var stored_narration := ""
	var stored_quest := ""
	for raw_effect in Array(encounter.get("victory_effects", [])):
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		if String(effect.get("type", "")) == "set_flag" and stored_flag == "":
			stored_flag = String(effect.get("flag", ""))
		if String(effect.get("type", "")) == "narration" and stored_narration == "":
			stored_narration = String(effect.get("text", ""))
		if String(effect.get("type", "")) == "quest_start" and stored_quest == "":
			stored_quest = String(effect.get("quest", ""))
	return victory_flag_edit.text.strip_edges() != stored_flag \
		or victory_narration_edit.text != stored_narration \
		or _option_pending(victory_quest_option, stored_quest)


func _trigger_form_pending() -> bool:
	if trigger_guard_edit == null or _selected_trigger_id == "":
		return false
	var trigger := CampaignStore.find_trigger(draft, _area_id(), _selected_trigger_id)
	if trigger.is_empty():
		return false
	var narration := ""
	for raw_effect in Array(trigger.get("effects", [])):
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "narration":
			narration = String(Dictionary(raw_effect).get("text", ""))
	return trigger_guard_edit.text.strip_edges() != String(trigger.get("requires_flag_not", "")) \
		or trigger_narration_edit.text != narration


func apply_pending_forms() -> bool:
	var keys := pending_form_keys()
	if keys.is_empty():
		return true
	var forms := {}
	for key in keys:
		forms[key] = _pending_form_snapshot(key)
	var before_draft: Dictionary = draft.duplicate(true)
	var before_dirty := dirty
	var before_selection := _selection_snapshot()
	for key in ["npc", "dialogue", "node", "choice", "quest", "objective", "encounter", "victory", "trigger"]:
		if not keys.has(key):
			continue
		_restore_pending_form(key, Dictionary(forms[key]))
		var applied := false
		match key:
			"npc": applied = _apply_npc()
			"dialogue": applied = _apply_dialogue_identity()
			"node": applied = _apply_node()
			"choice": applied = _apply_choice()
			"quest": applied = _apply_quest()
			"objective": applied = _apply_objective()
			"encounter": applied = _apply_encounter()
			"victory": applied = _apply_victory()
			"trigger": applied = _update_trigger()
		if not applied:
			return _rollback_pending_apply(
				before_draft, before_dirty, before_selection, forms, status_label.text
			)
	if not pending_form_keys().is_empty():
		return _rollback_pending_apply(
			before_draft, before_dirty, before_selection, forms,
			"Some pending form edits could not be applied. The draft was left unchanged."
		)
	_refresh_pending_label()
	return true


## Undo only the in-memory effects of a failed guarded Apply and restore the
## exact form text that was present before it. No file is written here.
func _rollback_pending_apply(
	before_draft: Dictionary,
	before_dirty: bool,
	before_selection: Dictionary,
	forms: Dictionary,
	message: String
) -> bool:
	draft = before_draft.duplicate(true)
	_restore_selection(before_selection)
	_refresh_all()
	for key in forms.keys():
		_restore_pending_form(String(key), Dictionary(forms[key]))
	dirty = before_dirty
	if header_meta != null:
		header_meta.text = "Unsaved changes" if dirty else "Saved"
	_refresh_pending_label()
	status_label.text = message
	status_label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
	_restore_pending_focus()
	return false


func _selection_snapshot() -> Dictionary:
	return {
		"npc": _selected_npc_id,
		"dialogue": _selected_dialogue_id,
		"node": _selected_node_id,
		"choice": _selected_choice,
		"quest": _selected_quest_id,
		"objective": _selected_objective_id,
		"encounter": _selected_encounter_id,
		"trigger": _selected_trigger_id,
	}


func _restore_selection(state: Dictionary) -> void:
	_selected_npc_id = String(state.get("npc", ""))
	_selected_dialogue_id = String(state.get("dialogue", ""))
	_selected_node_id = String(state.get("node", ""))
	_selected_choice = int(state.get("choice", 0))
	_selected_quest_id = String(state.get("quest", ""))
	_selected_objective_id = String(state.get("objective", ""))
	_selected_encounter_id = String(state.get("encounter", ""))
	_selected_trigger_id = String(state.get("trigger", ""))


func _pending_form_snapshot(key: String) -> Dictionary:
	match key:
		"npc":
			return {
				"npc": _selected_npc_id, "id": npc_id_edit.text, "name": npc_name_edit.text,
				"look": npc_look_edit.text, "dialogue": _selected_meta(npc_dialogue_option),
			}
		"dialogue":
			return {
				"dialogue": _selected_dialogue_id, "id": dialogue_id_edit.text,
				"speaker": speaker_edit.text,
			}
		"node":
			return {
				"dialogue": _selected_dialogue_id, "node": _selected_node_id,
				"text": node_text_edit.text, "next": _selected_meta(node_next_option),
				"narration": node_narration_edit.text, "flag": node_flag_edit.text,
			}
		"choice":
			return {
				"dialogue": _selected_dialogue_id, "node": _selected_node_id,
				"choice": _selected_choice, "text": choice_text_edit.text,
				"guard": choice_guard_edit.text, "require": choice_require_edit.text,
				"effect": choice_effect_edit.text, "check": choice_check_toggle.button_pressed,
				"skill": _selected_meta(choice_skill_option), "dc": int(choice_dc_spin.value),
				"actor": _selected_meta(choice_actor_option),
				"success": _selected_meta(choice_success_option),
				"failure": _selected_meta(choice_failure_option),
				"dest": _selected_meta(choice_dest_option),
				"quest": _selected_meta(choice_quest_option),
				"encounter": _selected_meta(choice_encounter_option),
			}
		"quest":
			return {
				"quest": _selected_quest_id, "title": quest_title_edit.text,
				"summary": quest_summary_edit.text,
				"start": _selected_meta(quest_start_option),
				"completion": _selected_meta(quest_completion_option),
			}
		"objective":
			return {
				"quest": _selected_quest_id, "objective": _selected_objective_id,
				"id": objective_id_edit.text, "text": objective_text_edit.text,
				"flag": objective_flag_edit.text,
			}
		"encounter":
			return {
				"encounter": _selected_encounter_id, "name": encounter_name_edit.text,
				"xp": int(encounter_xp_spin.value), "intro": encounter_intro_edit.text,
			}
		"victory":
			return {
				"encounter": _selected_encounter_id, "flag": victory_flag_edit.text,
				"narration": victory_narration_edit.text,
				"quest": _selected_meta(victory_quest_option),
			}
		"trigger":
			return {
				"trigger": _selected_trigger_id, "guard": trigger_guard_edit.text,
				"narration": trigger_narration_edit.text,
			}
	return {}


func _restore_pending_form(key: String, state: Dictionary) -> void:
	match key:
		"npc":
			_selected_npc_id = String(state.get("npc", _selected_npc_id))
			npc_id_edit.text = String(state.get("id", ""))
			npc_name_edit.text = String(state.get("name", ""))
			npc_look_edit.text = String(state.get("look", ""))
			_select_by_meta(npc_dialogue_option, String(state.get("dialogue", "")))
		"dialogue":
			_selected_dialogue_id = String(state.get("dialogue", _selected_dialogue_id))
			dialogue_id_edit.text = String(state.get("id", ""))
			speaker_edit.text = String(state.get("speaker", ""))
		"node":
			_selected_dialogue_id = String(state.get("dialogue", _selected_dialogue_id))
			_selected_node_id = String(state.get("node", _selected_node_id))
			node_text_edit.text = String(state.get("text", ""))
			_select_by_meta(node_next_option, String(state.get("next", "")))
			node_narration_edit.text = String(state.get("narration", ""))
			node_flag_edit.text = String(state.get("flag", ""))
		"choice":
			_selected_dialogue_id = String(state.get("dialogue", _selected_dialogue_id))
			_selected_node_id = String(state.get("node", _selected_node_id))
			_selected_choice = int(state.get("choice", _selected_choice))
			choice_text_edit.text = String(state.get("text", ""))
			choice_guard_edit.text = String(state.get("guard", ""))
			choice_require_edit.text = String(state.get("require", ""))
			choice_effect_edit.text = String(state.get("effect", ""))
			choice_check_toggle.set_pressed_no_signal(bool(state.get("check", false)))
			_set_check_fields_visible(choice_check_toggle.button_pressed)
			_select_by_meta(choice_skill_option, String(state.get("skill", "")))
			choice_dc_spin.value = float(int(state.get("dc", 12)))
			_select_by_meta(choice_actor_option, String(state.get("actor", "")))
			_select_by_meta(choice_success_option, String(state.get("success", "")))
			_select_by_meta(choice_failure_option, String(state.get("failure", "")))
			_select_by_meta(choice_dest_option, String(state.get("dest", "")))
			_select_by_meta(choice_quest_option, String(state.get("quest", "")))
			_select_by_meta(choice_encounter_option, String(state.get("encounter", "")))
		"quest":
			_selected_quest_id = String(state.get("quest", _selected_quest_id))
			quest_title_edit.text = String(state.get("title", ""))
			quest_summary_edit.text = String(state.get("summary", ""))
			_select_by_meta(quest_start_option, String(state.get("start", "")))
			_select_by_meta(quest_completion_option, String(state.get("completion", "")))
		"objective":
			_selected_quest_id = String(state.get("quest", _selected_quest_id))
			_selected_objective_id = String(state.get("objective", _selected_objective_id))
			objective_id_edit.text = String(state.get("id", ""))
			objective_text_edit.text = String(state.get("text", ""))
			objective_flag_edit.text = String(state.get("flag", ""))
		"encounter":
			_selected_encounter_id = String(state.get("encounter", _selected_encounter_id))
			encounter_name_edit.text = String(state.get("name", ""))
			encounter_xp_spin.value = float(int(state.get("xp", 0)))
			encounter_intro_edit.text = String(state.get("intro", ""))
		"victory":
			_selected_encounter_id = String(state.get("encounter", _selected_encounter_id))
			victory_flag_edit.text = String(state.get("flag", ""))
			victory_narration_edit.text = String(state.get("narration", ""))
			_select_by_meta(victory_quest_option, String(state.get("quest", "")))
		"trigger":
			_selected_trigger_id = String(state.get("trigger", _selected_trigger_id))
			trigger_guard_edit.text = String(state.get("guard", ""))
			trigger_narration_edit.text = String(state.get("narration", ""))


func discard_pending_forms() -> void:
	_refresh_all()
	status_label.text = "Discarded pending form edits. Applied draft changes and the package are unchanged."
	status_label.add_theme_color_override("font_color", ThemeBuilder.MUTED)


func _restore_pending_focus() -> void:
	if last_focused_control != null and is_instance_valid(last_focused_control):
		last_focused_control.grab_focus()


func _guard_pending(action: Callable, context: String) -> bool:
	var keys := pending_form_keys()
	if keys.is_empty():
		action.call()
		return true
	var labels: Array[String] = []
	for key in keys:
		labels.append(_form_label(key))
	if main == null:
		status_label.text = "Pending form edits (%s) were not applied. Apply or discard them before %s." % [", ".join(labels), context]
		status_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
		_refresh_pending_label()
		_restore_pending_focus()
		return false
	main.open_modal("Pending form edits", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(
			"These form edits have not been applied to the draft: %s.\n\nApply keeps them and continues. Discard reverts only these form fields. Cancel leaves the text, selection and focus unchanged." % ", ".join(labels),
			true,
			14
		))
		var error_label := Label.new()
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		error_label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		box.add_child(error_label)
		var apply := Button.new()
		apply.text = "Apply changes and continue"
		apply.custom_minimum_size = Vector2(0, 40)
		apply.pressed.connect(func() -> void:
			if apply_pending_forms():
				main.close_modal()
				action.call()
			else:
				error_label.text = "Not applied: " + status_label.text
		)
		box.add_child(apply)
		var discard := Button.new()
		discard.text = "Discard these form edits"
		discard.custom_minimum_size = Vector2(0, 40)
		discard.pressed.connect(func() -> void:
			discard_pending_forms()
			main.close_modal()
			action.call()
		)
		box.add_child(discard)
		var cancel := Button.new()
		cancel.text = "Cancel"
		cancel.custom_minimum_size = Vector2(0, 40)
		cancel.pressed.connect(func() -> void:
			main.close_modal()
			_restore_pending_focus()
		)
		box.add_child(cancel)
		return box
	, 720, 360)
	return false


func _mark_dirty() -> void:
	dirty = true
	if header_meta != null:
		header_meta.text = "Unsaved changes" if dirty else "Saved"


# ------------------------------------------------------------------ layout

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 0)
	add_child(page)
	var top_margin := MarginContainer.new()
	top_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top"]:
		top_margin.add_theme_constant_override("margin_" + side, 20)
	page.add_child(top_margin)
	var header_stack := VBoxContainer.new()
	header_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_stack.add_theme_constant_override("separation", 4)
	top_margin.add_child(header_stack)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 6)
	scroll.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header_stack.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(ThemeBuilder.heading("Campaign Creator", 28))
	header_meta = ThemeBuilder.body("Saved", true, 12)
	header_meta.add_theme_color_override("font_color", ThemeBuilder.MUTED)
	titles.add_child(header_meta)
	save_button = Button.new()
	save_button.text = "Save draft"
	save_button.custom_minimum_size = Vector2(130, 40)
	save_button.pressed.connect(_save)
	header.add_child(save_button)
	validate_button = Button.new()
	validate_button.text = "Validate draft"
	validate_button.custom_minimum_size = Vector2(140, 40)
	validate_button.pressed.connect(_validate)
	header.add_child(validate_button)
	play_button = Button.new()
	play_button.text = "Playtest draft"
	play_button.custom_minimum_size = Vector2(150, 40)
	play_button.pressed.connect(_playtest)
	header.add_child(play_button)
	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(100, 40)
	back_button.pressed.connect(_back)
	header.add_child(back_button)
	header_stack.add_child(ThemeBuilder.body(
		"Save draft writes the package. Playtest draft runs these unsaved changes with all saves disabled.",
		true,
		11
	))
	status_label = ThemeBuilder.body("", false, 13)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_stack.add_child(status_label)
	pending_label = ThemeBuilder.body("", false, 12)
	pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pending_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
	pending_label.visible = false
	header_stack.add_child(pending_label)
	diagnostics_panel = VBoxContainer.new()
	diagnostics_panel.add_theme_constant_override("separation", 2)
	diagnostics_panel.visible = false
	header_stack.add_child(diagnostics_panel)

	var identity := ThemeBuilder.body(
		"%s  •  user://campaigns/%s  •  format %s" % [
			String(draft.get("id", "")),
			String(draft.get("id", "")),
			draft.get("format_version", "?"),
		],
		true,
		12
	)
	identity.add_theme_color_override("font_color", ThemeBuilder.MUTED)
	root.add_child(identity)

	var meta := VBoxContainer.new()
	meta.add_theme_constant_override("separation", 4)
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(meta)
	var title_label := ThemeBuilder.body("Title", true, 13)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	meta.add_child(title_label)
	title_edit = LineEdit.new()
	title_edit.text = String(draft.get("title", ""))
	title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_edit.text_changed.connect(func(_text: String) -> void: _mark_dirty())
	meta.add_child(title_edit)
	var description_label := ThemeBuilder.body("Description", true, 13)
	description_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	meta.add_child(description_label)
	description_edit = TextEdit.new()
	description_edit.text = String(draft.get("description", ""))
	description_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	description_edit.custom_minimum_size = Vector2(0, 90)
	description_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_edit.text_changed.connect(func() -> void: _mark_dirty())
	meta.add_child(description_edit)

	root.add_child(ThemeBuilder.separator())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(210, 420)
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	left.add_child(ThemeBuilder.body("Areas", true, 15))
	area_list = VBoxContainer.new()
	area_list.add_theme_constant_override("separation", 4)
	left.add_child(area_list)
	var add_area := Button.new()
	add_area.text = "Add area"
	add_area.custom_minimum_size = Vector2(0, 38)
	add_area.pressed.connect(_add_area)
	left.add_child(add_area)
	left.add_child(ThemeBuilder.body(
		"One small 9x9 area at a time. Click a floor cell, then set the entry or link a passage.",
		true,
		11
	))

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 6)
	body.add_child(center)
	center.add_child(ThemeBuilder.body("Layout  •  # wall, . floor, E entry, -> passage", true, 13))
	map_grid = GridContainer.new()
	map_grid.columns = 9
	map_grid.add_theme_constant_override("h_separation", 2)
	map_grid.add_theme_constant_override("v_separation", 2)
	center.add_child(map_grid)
	selection_label = ThemeBuilder.body("No cell selected.", true, 12)
	center.add_child(selection_label)
	var cell_actions := HBoxContainer.new()
	cell_actions.add_theme_constant_override("separation", 6)
	center.add_child(cell_actions)
	var toggle := Button.new()
	toggle.text = "Toggle wall / floor"
	toggle.custom_minimum_size = Vector2(170, 36)
	toggle.pressed.connect(_toggle_cell)
	cell_actions.add_child(toggle)
	set_entry_button = Button.new()
	set_entry_button.text = "Set entry here"
	set_entry_button.custom_minimum_size = Vector2(150, 36)
	set_entry_button.pressed.connect(_set_entry)
	cell_actions.add_child(set_entry_button)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 420)
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	right.add_child(ThemeBuilder.body("Area", true, 15))
	var area_name_label := ThemeBuilder.body("Area name", true, 11)
	area_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	right.add_child(area_name_label)
	var area_name_row := HBoxContainer.new()
	area_name_row.add_theme_constant_override("separation", 6)
	right.add_child(area_name_row)
	area_name_edit = LineEdit.new()
	area_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area_name_edit.text_changed.connect(func(_text: String) -> void: _mark_dirty())
	area_name_row.add_child(area_name_edit)
	var facing_row := HBoxContainer.new()
	facing_row.add_theme_constant_override("separation", 6)
	right.add_child(facing_row)
	var facing_label := ThemeBuilder.body("Entry facing", true, 12)
	facing_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	facing_row.add_child(facing_label)
	facing_option = OptionButton.new()
	for label in ["North", "East", "South", "West"]:
		facing_option.add_item(label)
	facing_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facing_option.item_selected.connect(func(_index: int) -> void: _mark_dirty())
	facing_row.add_child(facing_option)
	right.add_child(ThemeBuilder.separator())
	right.add_child(ThemeBuilder.body("Passage from the selected cell to another area", true, 13))
	target_option = OptionButton.new()
	target_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(target_option)
	var add_link := Button.new()
	add_link.text = "Add / update passage"
	add_link.custom_minimum_size = Vector2(0, 38)
	add_link.pressed.connect(_add_transition)
	right.add_child(add_link)
	transitions_label = ThemeBuilder.body("", true, 12)
	transitions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(transitions_label)
	right.add_child(ThemeBuilder.separator())
	right.add_child(ThemeBuilder.body(
		"Encounter layouts are fixed templates with four party cells. Monster stat blocks, new spells and tactical AI are not editable here; the quest and encounter sections below choose from the supported catalogues.",
		true,
		11
	))

	root.add_child(ThemeBuilder.separator())
	root.add_child(ThemeBuilder.heading("NPCs and dialogue", 20))
	root.add_child(ThemeBuilder.body(
		"Select a floor cell, place a speaker, then edit its conversation. The NPC is only a speaker: no combat stat block is required, and its id is local to this campaign. Effects and conditions used here are set flag, require flag and narration, with a skill check resolved by the chosen party actor.",
		true,
		12
	))
	# Stack the two editors rather than placing them side by side: the minimum
	# window is 1280 wide, and at 1.6 text scale side-by-side fields would force
	# horizontal scrolling and squeeze labels into vertical strips.
	var interaction := VBoxContainer.new()
	interaction.add_theme_constant_override("separation", 10)
	root.add_child(interaction)

	var npc_column := VBoxContainer.new()
	npc_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_column.add_theme_constant_override("separation", 5)
	interaction.add_child(npc_column)
	npc_column.add_child(ThemeBuilder.body("Placement", true, 15))
	var npc_row := HBoxContainer.new()
	npc_row.add_theme_constant_override("separation", 6)
	npc_column.add_child(npc_row)
	npc_option = OptionButton.new()
	npc_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_option.item_selected.connect(_select_npc)
	npc_row.add_child(npc_option)
	var place_npc := Button.new()
	place_npc.text = "Place NPC here"
	place_npc.custom_minimum_size = Vector2(130, 36)
	place_npc.pressed.connect(_place_npc)
	npc_row.add_child(place_npc)
	npc_column.add_child(ThemeBuilder.body("Stable id (campaign-local)", true, 11))
	npc_id_edit = LineEdit.new()
	npc_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_column.add_child(npc_id_edit)
	npc_column.add_child(ThemeBuilder.body("Display name", true, 11))
	npc_name_edit = LineEdit.new()
	npc_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_column.add_child(npc_name_edit)
	npc_column.add_child(ThemeBuilder.body("Placeholder description / look", true, 11))
	npc_look_edit = TextEdit.new()
	npc_look_edit.custom_minimum_size = Vector2(0, 80)
	npc_look_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	npc_column.add_child(npc_look_edit)
	npc_column.add_child(ThemeBuilder.body("Conversation", true, 11))
	npc_dialogue_option = OptionButton.new()
	npc_dialogue_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_column.add_child(npc_dialogue_option)
	var npc_actions := HBoxContainer.new()
	npc_actions.add_theme_constant_override("separation", 6)
	npc_column.add_child(npc_actions)
	var apply_npc := Button.new()
	apply_npc.text = "Apply NPC"
	apply_npc.custom_minimum_size = Vector2(100, 36)
	apply_npc.pressed.connect(_apply_npc)
	npc_actions.add_child(apply_npc)
	var move_npc := Button.new()
	move_npc.text = "Move here"
	move_npc.custom_minimum_size = Vector2(100, 36)
	move_npc.pressed.connect(_move_npc)
	npc_actions.add_child(move_npc)
	var remove_npc := Button.new()
	remove_npc.text = "Remove"
	remove_npc.custom_minimum_size = Vector2(80, 36)
	remove_npc.pressed.connect(_confirm_remove_npc)
	npc_actions.add_child(remove_npc)
	npc_status = ThemeBuilder.body("", true, 11)
	npc_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	npc_column.add_child(npc_status)

	interaction.add_child(ThemeBuilder.separator())
	var dialogue_column := VBoxContainer.new()
	dialogue_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_column.add_theme_constant_override("separation", 5)
	interaction.add_child(dialogue_column)
	var dialogue_head := HBoxContainer.new()
	dialogue_head.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(dialogue_head)
	var conversation_label := ThemeBuilder.body("Conversation", true, 15)
	conversation_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	conversation_label.custom_minimum_size = Vector2(160, 0)
	dialogue_head.add_child(conversation_label)
	dialogue_option = OptionButton.new()
	dialogue_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_option.item_selected.connect(_select_dialogue)
	dialogue_head.add_child(dialogue_option)
	var new_dialogue := Button.new()
	new_dialogue.text = "New"
	new_dialogue.custom_minimum_size = Vector2(70, 34)
	new_dialogue.pressed.connect(_new_dialogue)
	dialogue_head.add_child(new_dialogue)
	var delete_dialogue := Button.new()
	delete_dialogue.text = "Delete"
	delete_dialogue.custom_minimum_size = Vector2(80, 34)
	delete_dialogue.pressed.connect(_confirm_delete_dialogue)
	dialogue_head.add_child(delete_dialogue)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(identity_row)
	dialogue_id_edit = LineEdit.new()
	dialogue_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_id_edit.placeholder_text = "dialogue id"
	identity_row.add_child(dialogue_id_edit)
	speaker_edit = LineEdit.new()
	speaker_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speaker_edit.placeholder_text = "speaker name"
	identity_row.add_child(speaker_edit)
	var apply_identity := Button.new()
	apply_identity.text = "Apply identity"
	apply_identity.custom_minimum_size = Vector2(120, 34)
	apply_identity.pressed.connect(_apply_dialogue_identity)
	identity_row.add_child(apply_identity)

	var start_row := HBoxContainer.new()
	start_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(start_row)
	var start_label := ThemeBuilder.body("Start node", true, 11)
	start_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	start_label.custom_minimum_size = Vector2(90, 0)
	start_row.add_child(start_label)
	start_option = OptionButton.new()
	start_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_row.add_child(start_option)
	var set_start := Button.new()
	set_start.text = "Set start"
	set_start.custom_minimum_size = Vector2(90, 32)
	set_start.pressed.connect(_set_start_node)
	start_row.add_child(set_start)

	var node_row := HBoxContainer.new()
	node_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(node_row)
	var node_label := ThemeBuilder.body("Node", true, 11)
	node_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	node_label.custom_minimum_size = Vector2(60, 0)
	node_row.add_child(node_label)
	node_option = OptionButton.new()
	node_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_option.item_selected.connect(_select_node)
	node_row.add_child(node_option)
	var add_node := Button.new()
	add_node.text = "Add node"
	add_node.custom_minimum_size = Vector2(90, 32)
	add_node.pressed.connect(_add_node)
	node_row.add_child(add_node)
	var delete_node := Button.new()
	delete_node.text = "Delete node"
	delete_node.custom_minimum_size = Vector2(100, 32)
	delete_node.pressed.connect(_delete_node)
	node_row.add_child(delete_node)

	var node_id_row := HBoxContainer.new()
	node_id_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(node_id_row)
	node_id_edit = LineEdit.new()
	node_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_id_edit.placeholder_text = "node id"
	node_id_row.add_child(node_id_edit)
	var rename_node := Button.new()
	rename_node.text = "Rename node"
	rename_node.custom_minimum_size = Vector2(110, 32)
	rename_node.pressed.connect(_rename_node)
	node_id_row.add_child(rename_node)
	var add_choice := Button.new()
	add_choice.text = "Add response"
	add_choice.custom_minimum_size = Vector2(110, 32)
	add_choice.pressed.connect(_add_choice)
	node_id_row.add_child(add_choice)

	node_text_edit = TextEdit.new()
	node_text_edit.custom_minimum_size = Vector2(0, 96)
	node_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	node_text_edit.placeholder_text = "Text the speaker says"
	dialogue_column.add_child(node_text_edit)
	var next_row := HBoxContainer.new()
	next_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(next_row)
	var next_label := ThemeBuilder.body("If no responses, go to", true, 11)
	next_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	next_label.custom_minimum_size = Vector2(230, 0)
	next_row.add_child(next_label)
	node_next_option = OptionButton.new()
	node_next_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_row.add_child(node_next_option)
	var narration_row := HBoxContainer.new()
	narration_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(narration_row)
	node_narration_edit = LineEdit.new()
	node_narration_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_narration_edit.placeholder_text = "narration when this node opens (optional)"
	narration_row.add_child(node_narration_edit)
	node_flag_edit = LineEdit.new()
	node_flag_edit.custom_minimum_size = Vector2(180, 0)
	node_flag_edit.placeholder_text = "set flag on entry (optional)"
	narration_row.add_child(node_flag_edit)
	var apply_node := Button.new()
	apply_node.text = "Apply node"
	apply_node.custom_minimum_size = Vector2(100, 34)
	apply_node.pressed.connect(_apply_node)
	narration_row.add_child(apply_node)

	dialogue_column.add_child(ThemeBuilder.separator())
	var choice_head := HBoxContainer.new()
	choice_head.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(choice_head)
	var response_label := ThemeBuilder.body("Response", true, 13)
	response_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	response_label.custom_minimum_size = Vector2(100, 0)
	choice_head.add_child(response_label)
	choice_option = OptionButton.new()
	choice_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_option.item_selected.connect(_select_choice)
	choice_head.add_child(choice_option)
	var remove_choice := Button.new()
	remove_choice.text = "Remove response"
	remove_choice.custom_minimum_size = Vector2(140, 32)
	remove_choice.pressed.connect(_remove_choice)
	choice_head.add_child(remove_choice)
	choice_text_edit = LineEdit.new()
	choice_text_edit.placeholder_text = "Text the player chooses"
	choice_text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_column.add_child(choice_text_edit)
	choice_plain_box = VBoxContainer.new()
	choice_plain_box.add_theme_constant_override("separation", 4)
	dialogue_column.add_child(choice_plain_box)
	choice_plain_box.add_child(ThemeBuilder.body("Destination", true, 11))
	choice_dest_option = OptionButton.new()
	choice_dest_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_plain_box.add_child(choice_dest_option)
	choice_check_toggle = CheckBox.new()
	choice_check_toggle.text = "Skill check (rolled by the party when this response is chosen)"
	choice_check_toggle.toggled.connect(_toggle_choice_check)
	dialogue_column.add_child(choice_check_toggle)
	choice_check_box = VBoxContainer.new()
	choice_check_box.add_theme_constant_override("separation", 4)
	dialogue_column.add_child(choice_check_box)
	var check_stats := HBoxContainer.new()
	check_stats.add_theme_constant_override("separation", 6)
	choice_check_box.add_child(check_stats)
	choice_skill_option = OptionButton.new()
	choice_skill_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check_stats.add_child(choice_skill_option)
	choice_dc_spin = SpinBox.new()
	choice_dc_spin.min_value = 1
	choice_dc_spin.max_value = 60
	choice_dc_spin.value = 12
	choice_dc_spin.custom_minimum_size = Vector2(90, 0)
	check_stats.add_child(choice_dc_spin)
	choice_actor_option = OptionButton.new()
	choice_actor_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check_stats.add_child(choice_actor_option)
	var branch_row := HBoxContainer.new()
	branch_row.add_theme_constant_override("separation", 6)
	choice_check_box.add_child(branch_row)
	var success_label := ThemeBuilder.body("Success", true, 11)
	success_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	success_label.custom_minimum_size = Vector2(70, 0)
	branch_row.add_child(success_label)
	choice_success_option = OptionButton.new()
	choice_success_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	branch_row.add_child(choice_success_option)
	var failure_label := ThemeBuilder.body("Failure", true, 11)
	failure_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	failure_label.custom_minimum_size = Vector2(70, 0)
	branch_row.add_child(failure_label)
	choice_failure_option = OptionButton.new()
	choice_failure_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	branch_row.add_child(choice_failure_option)
	var flag_row := HBoxContainer.new()
	flag_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(flag_row)
	choice_guard_edit = LineEdit.new()
	choice_guard_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_guard_edit.placeholder_text = "hide after flag is set (require flag absent)"
	flag_row.add_child(choice_guard_edit)
	choice_require_edit = LineEdit.new()
	choice_require_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_require_edit.placeholder_text = "show only if flag is set"
	flag_row.add_child(choice_require_edit)
	choice_effect_edit = LineEdit.new()
	choice_effect_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_effect_edit.placeholder_text = "set campaign flag when chosen (optional)"
	flag_row.add_child(choice_effect_edit)
	var apply_choice := Button.new()
	apply_choice.text = "Apply response"
	apply_choice.custom_minimum_size = Vector2(120, 34)
	apply_choice.pressed.connect(_apply_choice)
	flag_row.add_child(apply_choice)
	var palette_row := HBoxContainer.new()
	palette_row.add_theme_constant_override("separation", 6)
	dialogue_column.add_child(palette_row)
	var flag_pick_label := ThemeBuilder.body("Known flag", true, 11)
	flag_pick_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	flag_pick_label.custom_minimum_size = Vector2(84, 0)
	palette_row.add_child(flag_pick_label)
	choice_flag_option = OptionButton.new()
	choice_flag_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_flag_option.item_selected.connect(_select_choice_flag)
	palette_row.add_child(choice_flag_option)
	var quest_pick_label := ThemeBuilder.body("Start quest", true, 11)
	quest_pick_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	quest_pick_label.custom_minimum_size = Vector2(84, 0)
	palette_row.add_child(quest_pick_label)
	choice_quest_option = OptionButton.new()
	choice_quest_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_row.add_child(choice_quest_option)
	var encounter_pick_label := ThemeBuilder.body("Start encounter", true, 11)
	encounter_pick_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	encounter_pick_label.custom_minimum_size = Vector2(120, 0)
	palette_row.add_child(encounter_pick_label)
	choice_encounter_option = OptionButton.new()
	choice_encounter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_row.add_child(choice_encounter_option)
	dialogue_preview = ThemeBuilder.body("", true, 12)
	dialogue_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_column.add_child(dialogue_preview)

	_build_quest_section(root)
	_build_flag_section(root)
	_build_encounter_section(root)
	_build_trigger_section(root)


# ------------------------------------------------------------------ refresh

func _refresh_all() -> void:
	# Do not capture here: on first build the editors are still empty, and
	# capturing would overwrite the template's names with blank strings.
	_refresh_area_list()
	_refresh_map()
	_refresh_area_settings()
	_refresh_targets()
	_refresh_interaction()
	_refresh_flags()
	_refresh_quests()
	_refresh_encounters()
	_refresh_triggers()
	if header_meta != null:
		header_meta.text = "Unsaved changes" if dirty else "Saved"
		header_meta.add_theme_color_override("font_color", ThemeBuilder.GOLD if dirty else ThemeBuilder.MUTED)
	_refresh_pending_label()


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _refresh_area_list() -> void:
	_clear(area_list)
	var areas: Array = Array(draft.get("areas", []))
	for i in areas.size():
		var area: Dictionary = Dictionary(areas[i])
		var index := i
		var button := Button.new()
		button.text = "%s  (%s)" % [String(area.get("name", "Area")), String(area.get("id", "?"))]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 34)
		if i == selected_area:
			button.add_theme_color_override("font_color", ThemeBuilder.GOLD)
		button.pressed.connect(func() -> void: _select_area(index))
		area_list.add_child(button)


func _refresh_map() -> void:
	_clear(map_grid)
	var area := _current_area()
	if area.is_empty():
		return
	var rows: Array = Array(area.get("rows", []))
	var width := 0
	for row in rows:
		width = maxi(width, String(row).length())
	map_grid.columns = maxi(1, width)
	var entry: Dictionary = draft.get("entry", {})
	var entry_pos: Array = Array(entry.get("pos", []))
	var entry_here := String(entry.get("area", "")) == _area_id()
	var links := {}
	for raw_object in Array(area.get("objects", [])):
		if not raw_object is Dictionary:
			continue
		var obj: Dictionary = raw_object
		for raw_interaction in Array(obj.get("interactions", [])):
			for raw_effect in Array(Dictionary(raw_interaction).get("effects", [])):
				if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "travel":
					var p: Array = Array(obj.get("pos", []))
					if p.size() == 2:
						links[Vector2i(int(p[0]), int(p[1]))] = true
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			var pos := Vector2i(x, y)
			var text := row[x]
			if entry_here and entry_pos.size() == 2 and int(entry_pos[0]) == x and int(entry_pos[1]) == y:
				text = "E"
			elif links.has(pos):
				text = ">"
			var cell := Button.new()
			cell.text = text
			cell.custom_minimum_size = Vector2(34, 34)
			cell.tooltip_text = "(%d, %d)" % [x, y]
			if pos == selected_cell:
				cell.add_theme_color_override("font_color", ThemeBuilder.GOLD)
			cell.pressed.connect(func() -> void: _select_cell(pos))
			map_grid.add_child(cell)
	if selected_cell.x >= 0:
		var area_id := _area_id()
		selection_label.text = "Selected (%d, %d) in %s." % [selected_cell.x, selected_cell.y, area_id]
	else:
		selection_label.text = "No cell selected."


func _refresh_area_settings() -> void:
	var area := _current_area()
	if area.is_empty():
		area_name_edit.text = ""
		transitions_label.text = ""
		return
	area_name_edit.text = String(area.get("name", ""))
	var entry: Dictionary = draft.get("entry", {})
	if String(entry.get("area", "")) == _area_id():
		facing_option.select(clampi(int(entry.get("facing", 0)), 0, 3))
	var lines: Array[String] = []
	for raw_object in Array(area.get("objects", [])):
		if not raw_object is Dictionary:
			continue
		var obj: Dictionary = raw_object
		for raw_interaction in Array(obj.get("interactions", [])):
			for raw_effect in Array(Dictionary(raw_interaction).get("effects", [])):
				if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "travel":
					var p: Array = Array(obj.get("pos", []))
					lines.append(
						"(%d, %d) -> %s" % [int(p[0]), int(p[1]), String(Dictionary(raw_effect).get("area", "?"))]
					)
	transitions_label.text = "Passages here:\n" + ("\n".join(lines) if not lines.is_empty() else "(none)")


func _refresh_targets() -> void:
	target_option.clear()
	var areas: Array = Array(draft.get("areas", []))
	var current := _area_id()
	for raw_area in areas:
		var area: Dictionary = Dictionary(raw_area)
		var area_id := String(area.get("id", ""))
		if area_id == current:
			continue
		target_option.add_item(String(area.get("name", area_id)))
		target_option.set_item_metadata(target_option.item_count - 1, area_id)


# ------------------------------------------------------------------ actions

func _select_area(index: int) -> void:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_area(index), "change area")
		return
	capture_draft()
	selected_area = clampi(index, 0, maxi(0, Array(draft.get("areas", [])).size() - 1))
	selected_cell = Vector2i(-1, -1)
	_selected_npc_id = ""
	_selected_node_id = ""
	_selected_choice = 0
	_refresh_all()


func _select_cell(pos: Vector2i) -> void:
	selected_cell = pos
	_refresh_map()


func _toggle_cell() -> void:
	if selected_cell.x < 0:
		status_label.text = "Select a cell first."
		return
	capture_draft()
	var area := _current_area()
	var rows: Array = Array(area.get("rows", []))
	var ch := "#" if String(rows[selected_cell.y])[selected_cell.x] != "#" else "."
	if not CampaignStore.set_area_cell(draft, _area_id(), selected_cell, ch == "#"):
		status_label.text = "Border cells stay walls; choose an interior cell."
		return
	_mark_dirty()
	_refresh_map()
	status_label.text = "Cell (%d, %d) is now %s." % [selected_cell.x, selected_cell.y, "a wall" if ch == "#" else "floor"]


func _set_entry() -> void:
	if selected_cell.x < 0:
		status_label.text = "Select a floor cell first."
		return
	capture_draft()
	var result := CampaignStore.set_entry(draft, _area_id(), selected_cell, facing_option.selected)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()


func _add_area() -> void:
	capture_draft()
	var area := CampaignStore.add_area(draft, "Area %d" % (Array(draft.get("areas", [])).size() + 1))
	selected_area = Array(draft.get("areas", [])).size() - 1
	selected_cell = Vector2i(-1, -1)
	_selected_npc_id = ""
	_selected_node_id = ""
	dirty = true
	_refresh_all()
	status_label.text = "Added %s. Set an entry or link it to another area." % String(area.get("id", "area"))


func _add_transition() -> void:
	if selected_cell.x < 0:
		status_label.text = "Select a floor cell in this area first."
		return
	if target_option.selected < 0 or target_option.item_count == 0:
		status_label.text = "Add a second area before linking a passage."
		return
	capture_draft()
	var target_id := String(target_option.get_item_metadata(target_option.selected))
	var result := CampaignStore.add_transition(draft, _area_id(), selected_cell, target_id)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()


# ------------------------------------------------------------ NPC + dialogue

func _fill_options(option: OptionButton, entries: Array, selected: String) -> void:
	option.clear()
	option.clip_text = true
	option.fit_to_longest_item = false
	option.custom_minimum_size = Vector2(0, 34)
	var selected_index := -1
	for i in entries.size():
		var entry: Dictionary = entries[i]
		option.add_item(String(entry.get("label", "")))
		option.set_item_metadata(i, String(entry.get("meta", "")))
		if String(entry.get("meta", "")) == selected:
			selected_index = i
	if selected_index >= 0:
		option.select(selected_index)
	elif selected != "":
		# Keep an invalid stored id visible and selected instead of pretending the
		# first valid entry is the stored value. The label names the unresolved id.
		option.add_item("Unresolved reference: %s" % selected)
		option.set_item_metadata(option.item_count - 1, selected)
		option.select(option.item_count - 1)
	elif option.item_count > 0:
		option.select(0)


func _dialogue_entries() -> Array:
	var entries: Array = []
	var dialogues: Dictionary = CampaignStore.dialogues_of(draft)
	var ids: Array = dialogues.keys()
	ids.sort()
	for raw_id in ids:
		var id := String(raw_id)
		entries.append({"label": id, "meta": id})
	return entries


func _node_entries(dialogue: Dictionary) -> Array:
	var entries: Array = []
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	var ids: Array = nodes.keys()
	ids.sort()
	for raw_id in ids:
		var id := String(raw_id)
		entries.append({"label": id, "meta": id})
	return entries


func _destination_entries(dialogue: Dictionary, include_end: bool) -> Array:
	var entries: Array = []
	if include_end:
		entries.append({"label": "(end conversation)", "meta": ""})
	for raw_node in _node_entries(dialogue):
		entries.append(raw_node)
	return entries


func _refresh_interaction() -> void:
	if npc_option == null:
		return
	_syncing_interaction = true
	var area := _current_area()
	var npc_ids: Array[String] = []
	var npc_entries: Array = []
	for raw_npc in Array(area.get("npcs", [])):
		if not raw_npc is Dictionary:
			continue
		var npc: Dictionary = raw_npc
		var npc_id := String(npc.get("id", ""))
		npc_ids.append(npc_id)
		npc_entries.append({
			"label": "%s (%s)" % [String(npc.get("name", npc_id)), npc_id],
			"meta": npc_id,
		})
	if not npc_ids.has(_selected_npc_id):
		_selected_npc_id = npc_ids[0] if not npc_ids.is_empty() else ""
	_fill_options(npc_option, npc_entries, _selected_npc_id)
	var npc := CampaignStore.find_npc(draft, _area_id(), _selected_npc_id)
	npc_id_edit.text = String(npc.get("id", ""))
	npc_name_edit.text = String(npc.get("name", ""))
	npc_look_edit.text = String(npc.get("look", ""))
	var npc_dialogue := String(npc.get("dialogue", ""))
	var dialogue_entries := _dialogue_entries()
	_fill_options(npc_dialogue_option, dialogue_entries, npc_dialogue)
	var dialogues := CampaignStore.dialogues_of(draft)
	if not dialogues.has(_selected_dialogue_id):
		_selected_dialogue_id = npc_dialogue if dialogues.has(npc_dialogue) else ""
		if _selected_dialogue_id == "" and not dialogue_entries.is_empty():
			_selected_dialogue_id = String(Dictionary(dialogue_entries[0]).get("meta", ""))
	_fill_options(dialogue_option, dialogue_entries, _selected_dialogue_id)
	var dialogue := CampaignStore.dialogue_by_id(draft, _selected_dialogue_id)
	dialogue_id_edit.text = String(dialogue.get("id", _selected_dialogue_id))
	speaker_edit.text = String(dialogue.get("speaker", ""))
	var node_entries := _node_entries(dialogue)
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	if not nodes.has(_selected_node_id):
		_selected_node_id = String(dialogue.get("start", ""))
		if not nodes.has(_selected_node_id) and not node_entries.is_empty():
			_selected_node_id = String(Dictionary(node_entries[0]).get("meta", ""))
	_fill_options(start_option, node_entries, String(dialogue.get("start", "")))
	_fill_options(node_option, node_entries, _selected_node_id)
	var node: Dictionary = Dictionary(nodes.get(_selected_node_id, {}))
	node_id_edit.text = _selected_node_id
	node_text_edit.text = String(node.get("text", ""))
	_fill_options(node_next_option, _destination_entries(dialogue, true), String(node.get("next", "")))
	var narration := ""
	var node_flag := ""
	for raw_effect in Array(node.get("effects", [])):
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		if String(effect.get("type", "")) == "narration" and narration == "":
			narration = String(effect.get("text", ""))
		if String(effect.get("type", "")) == "set_flag" and node_flag == "":
			node_flag = String(effect.get("flag", ""))
	node_narration_edit.text = narration
	node_flag_edit.text = node_flag
	_refresh_choice_controls(dialogue, node)
	_syncing_interaction = false


func _refresh_choice_controls(dialogue: Dictionary, node: Dictionary) -> void:
	var choices: Array = Array(node.get("choices", []))
	var entries: Array = []
	for i in choices.size():
		entries.append({"label": "Response %d" % (i + 1), "meta": str(i)})
	if _selected_choice < 0 or _selected_choice >= choices.size():
		_selected_choice = 0
	_fill_options(choice_option, entries, str(_selected_choice) if not entries.is_empty() else "")
	_fill_options(choice_flag_option, _flag_entries(), "")
	_fill_options(choice_quest_option, _quest_entries_with_none(), "")
	_fill_options(choice_encounter_option, _encounter_entries_with_none(), "")
	_fill_options(choice_dest_option, _destination_entries(dialogue, true), "")
	_fill_options(choice_success_option, _destination_entries(dialogue, false), "")
	_fill_options(choice_failure_option, _destination_entries(dialogue, false), "")
	choice_skill_option.clear()
	for raw_skill in Skills.all_keys():
		var skill := String(raw_skill)
		choice_skill_option.add_item(Skills.name(skill))
		choice_skill_option.set_item_metadata(choice_skill_option.item_count - 1, skill)
	choice_actor_option.clear()
	choice_actor_option.add_item("Best suited character")
	choice_actor_option.set_item_metadata(0, "best")
	for raw_actor in Array(Dictionary(draft.get("party", {})).get("default", [])):
		var actor_id := String(raw_actor)
		choice_actor_option.add_item(actor_id.capitalize())
		choice_actor_option.set_item_metadata(choice_actor_option.item_count - 1, actor_id)
	if choices.is_empty():
		choice_text_edit.text = ""
		choice_check_toggle.set_pressed_no_signal(false)
		_set_check_fields_visible(false)
		dialogue_preview.text = _dialogue_preview_text(dialogue, node)
		return
	var choice: Dictionary = Dictionary(choices[_selected_choice])
	choice_text_edit.text = String(choice.get("text", ""))
	var check: Dictionary = Dictionary(choice.get("check", {}))
	choice_check_toggle.set_pressed_no_signal(not check.is_empty())
	_set_check_fields_visible(not check.is_empty())
	if not check.is_empty():
		_select_by_meta(choice_skill_option, String(check.get("skill", "")))
		choice_dc_spin.value = float(check.get("dc", 12))
		_select_by_meta(choice_actor_option, String(check.get("actor", "best")))
		_select_by_meta(choice_success_option, String(check.get("success", "")))
		_select_by_meta(choice_failure_option, String(check.get("failure", "")))
	else:
		_select_by_meta(choice_dest_option, String(choice.get("next", "")))
	var guard := ""
	var require_flag := ""
	for raw_condition in Array(choice.get("conditions", [])):
		if not raw_condition is Dictionary:
			continue
		var condition: Dictionary = raw_condition
		if String(condition.get("type", "")) == "not_flag" and guard == "":
			guard = String(condition.get("flag", ""))
		if String(condition.get("type", "")) == "flag" and require_flag == "":
			require_flag = String(condition.get("flag", ""))
	var effect_flag := ""
	var effect_quest := ""
	var effect_encounter := ""
	for raw_effect in Array(choice.get("effects", [])):
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		if String(effect.get("type", "")) == "set_flag" and effect_flag == "":
			effect_flag = String(effect.get("flag", ""))
		if String(effect.get("type", "")) == "quest_start" and effect_quest == "":
			effect_quest = String(effect.get("quest", ""))
		if String(effect.get("type", "")) == "start_combat" and effect_encounter == "":
			effect_encounter = String(effect.get("encounter", ""))
	choice_guard_edit.text = guard
	choice_require_edit.text = require_flag
	choice_effect_edit.text = effect_flag
	_select_by_meta(choice_quest_option, effect_quest)
	_select_by_meta(choice_encounter_option, effect_encounter)
	if effect_flag != "":
		_select_by_meta(choice_flag_option, effect_flag)
	dialogue_preview.text = _dialogue_preview_text(dialogue, node)


func _select_by_meta(option: OptionButton, meta: String) -> void:
	for i in option.item_count:
		if String(option.get_item_metadata(i)) == meta:
			option.select(i)
			return
	if meta != "":
		option.add_item("Unresolved reference: %s" % meta)
		option.set_item_metadata(option.item_count - 1, meta)
		option.select(option.item_count - 1)
	elif option.item_count > 0:
		option.select(0)


func _dialogue_preview_text(dialogue: Dictionary, node: Dictionary) -> String:
	var speaker := String(node.get("speaker_name", dialogue.get("speaker", "Speaker")))
	var lines: Array[String] = ["Preview — %s: %s" % [speaker, String(node.get("text", "(empty node)"))]]
	var choices: Array = Array(node.get("choices", []))
	if choices.is_empty():
		var next_id := String(node.get("next", ""))
		lines.append("Then: %s" % ("ends the conversation" if next_id == "" else "node '%s'" % next_id))
	else:
		for i in choices.size():
			var choice: Dictionary = Dictionary(choices[i])
			var destination := String(choice.get("next", ""))
			var check: Dictionary = Dictionary(choice.get("check", {}))
			var detail := ""
			if not check.is_empty():
				detail = " [%s DC %d → success %s / failure %s]" % [
					Skills.name(String(check.get("skill", ""))),
					int(check.get("dc", 10)),
					String(check.get("success", "?")),
					String(check.get("failure", "?")),
				]
			else:
				detail = " → %s" % ("end" if destination == "" else destination)
			lines.append("%d. %s%s" % [i + 1, String(choice.get("text", "")), detail])
	return "\n".join(lines)


func _set_check_fields_visible(visible_state: bool) -> void:
	if choice_plain_box != null:
		choice_plain_box.visible = not visible_state
	if choice_check_box != null:
		choice_check_box.visible = visible_state


func _toggle_choice_check(pressed: bool) -> void:
	_set_check_fields_visible(pressed)


func _select_npc(index: int) -> void:
	if _syncing_interaction:
		return
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_npc(index), "switch NPC")
		return
	_selected_npc_id = String(npc_option.get_item_metadata(index))
	var npc := CampaignStore.find_npc(draft, _area_id(), _selected_npc_id)
	var dialogue_id := String(npc.get("dialogue", ""))
	if CampaignStore.dialogues_of(draft).has(dialogue_id):
		_selected_dialogue_id = dialogue_id
		dialogue_id_edit.text = dialogue_id
		_selected_node_id = ""
		_selected_choice = 0
	_refresh_interaction()


func _select_dialogue(index: int) -> void:
	if _syncing_interaction:
		return
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_dialogue(index), "switch conversation")
		return
	_selected_dialogue_id = String(dialogue_option.get_item_metadata(index))
	_selected_node_id = ""
	_selected_choice = 0
	_refresh_interaction()


func _select_node(index: int) -> void:
	if _syncing_interaction:
		return
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_node(index), "switch dialogue node")
		return
	_selected_node_id = String(node_option.get_item_metadata(index))
	_selected_choice = 0
	_refresh_interaction()


func _select_choice(index: int) -> void:
	if _syncing_interaction:
		return
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_choice(index), "switch response")
		return
	_selected_choice = int(String(choice_option.get_item_metadata(index)))
	var dialogue := CampaignStore.dialogue_by_id(draft, _selected_dialogue_id)
	var node: Dictionary = Dictionary(Dictionary(dialogue.get("nodes", {})).get(_selected_node_id, {}))
	_refresh_choice_controls(dialogue, node)


func _place_npc() -> void:
	if selected_cell.x < 0:
		npc_status.text = "Select a floor cell first."
		return
	if _area_id() == "":
		npc_status.text = "Add or select an area first."
		return
	capture_draft()
	var npc_id := CampaignStore.next_npc_id(draft)
	var dialogue_id := npc_id + "_talk"
	var created := CampaignStore.add_dialogue(draft, dialogue_id, "New Speaker")
	if not bool(created.get("ok", false)):
		npc_status.text = String(created.get("message", "Could not create the conversation."))
		return
	var placed := CampaignStore.place_npc(
		draft,
		_area_id(),
		selected_cell,
		npc_id,
		"New Speaker",
		"(USER CAMPAIGN) A new speaker waits here.",
		dialogue_id
	)
	if not bool(placed.get("ok", false)):
		CampaignStore.delete_dialogue(draft, dialogue_id)
		npc_status.text = String(placed.get("message", "Could not place the NPC."))
		return
	_selected_npc_id = npc_id
	_selected_dialogue_id = dialogue_id
	_selected_node_id = "start"
	_selected_choice = 0
	_mark_dirty()
	_refresh_all()
	npc_status.text = "Placed %s with conversation %s. Edit its name and text below." % [npc_id, dialogue_id]
	status_label.text = npc_status.text


func _apply_npc() -> bool:
	if _selected_npc_id == "":
		npc_status.text = "Select or place an NPC first."
		status_label.text = npc_status.text
		return false
	capture_draft()
	var wanted_id := npc_id_edit.text.strip_edges()
	var wanted_name := npc_name_edit.text.strip_edges()
	var dialogue_id := _selected_meta(npc_dialogue_option)
	var stored_dialogue := String(CampaignStore.find_npc(draft, _area_id(), _selected_npc_id).get("dialogue", ""))
	if wanted_name == "":
		npc_status.text = "NPC display name cannot be empty."
		status_label.text = npc_status.text
		return false
	if dialogue_id != "" and not CampaignStore.dialogues_of(draft).has(dialogue_id) and dialogue_id != stored_dialogue:
		npc_status.text = "NPC references missing dialogue '%s'." % dialogue_id
		status_label.text = npc_status.text
		return false
	if wanted_id != _selected_npc_id:
		var renamed := CampaignStore.rename_npc(draft, _area_id(), _selected_npc_id, wanted_id)
		if not bool(renamed.get("ok", false)):
			npc_status.text = String(renamed.get("message", "Rename refused."))
			status_label.text = npc_status.text
			return false
		_selected_npc_id = wanted_id
	var result := CampaignStore.update_npc(
		draft, _area_id(), _selected_npc_id, npc_name_edit.text, npc_look_edit.text, dialogue_id
	)
	if not bool(result.get("ok", false)):
		npc_status.text = String(result.get("message", "NPC not updated."))
		status_label.text = npc_status.text
		return false
	if CampaignStore.dialogues_of(draft).has(dialogue_id):
		_selected_dialogue_id = dialogue_id
	_mark_dirty()
	_refresh_all()
	npc_status.text = "Updated NPC '%s'." % _selected_npc_id
	status_label.text = npc_status.text
	return true


func _move_npc() -> void:
	if selected_cell.x < 0:
		npc_status.text = "Select a floor cell first."
		return
	capture_draft()
	var result := CampaignStore.move_npc(draft, _area_id(), _selected_npc_id, selected_cell)
	npc_status.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
		status_label.text = npc_status.text


func _confirm_remove_npc() -> void:
	if _selected_npc_id == "":
		npc_status.text = "Select an NPC first."
		return
	var npc_id := _selected_npc_id
	main.open_modal("Remove NPC", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(
			"Remove '%s' from this area? Its conversation is kept, so other content is not broken." % npc_id,
			true,
			14
		))
		var confirm := Button.new()
		confirm.text = "Remove placement"
		confirm.custom_minimum_size = Vector2(0, 40)
		confirm.pressed.connect(func() -> void:
			main.close_modal()
			capture_draft()
			var result := CampaignStore.remove_npc(draft, _area_id(), npc_id)
			npc_status.text = String(result.get("message", ""))
			status_label.text = npc_status.text
			if bool(result.get("ok", false)):
				_selected_npc_id = ""
				_mark_dirty()
				_refresh_all()
		)
		box.add_child(confirm)
		var cancel := Button.new()
		cancel.text = "Keep editing"
		cancel.custom_minimum_size = Vector2(0, 40)
		cancel.pressed.connect(main.close_modal)
		box.add_child(cancel)
		return box
	, 620, 260)


func _new_dialogue() -> void:
	capture_draft()
	var dialogue_id := CampaignStore.next_dialogue_id(draft)
	var result := CampaignStore.add_dialogue(draft, dialogue_id, "New Speaker")
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_selected_dialogue_id = dialogue_id
		_selected_node_id = "start"
		_selected_choice = 0
		_mark_dirty()
		_refresh_all()


func _confirm_delete_dialogue() -> void:
	if _selected_dialogue_id == "":
		status_label.text = "Select a conversation first."
		return
	var dialogue_id := _selected_dialogue_id
	var refs := CampaignStore.dialogue_references(draft, dialogue_id)
	if not refs.is_empty():
		status_label.text = "Cannot delete '%s'; still referenced by %s." % [dialogue_id, ", ".join(refs)]
		return
	main.open_modal("Delete conversation", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(
			"Delete conversation '%s'? No NPC references it, so no placement will break." % dialogue_id,
			true,
			14
		))
		var confirm := Button.new()
		confirm.text = "Delete conversation"
		confirm.custom_minimum_size = Vector2(0, 40)
		confirm.pressed.connect(func() -> void:
			main.close_modal()
			capture_draft()
			var result := CampaignStore.delete_dialogue(draft, dialogue_id)
			status_label.text = String(result.get("message", ""))
			if bool(result.get("ok", false)):
				_selected_dialogue_id = ""
				_selected_node_id = ""
				_mark_dirty()
				_refresh_all()
		)
		box.add_child(confirm)
		var cancel := Button.new()
		cancel.text = "Keep editing"
		cancel.custom_minimum_size = Vector2(0, 40)
		cancel.pressed.connect(main.close_modal)
		box.add_child(cancel)
		return box
	, 620, 260)


func _apply_dialogue_identity() -> bool:
	if _selected_dialogue_id == "":
		status_label.text = "Select a conversation first."
		return false
	capture_draft()
	var new_speaker := speaker_edit.text.strip_edges()
	if new_speaker == "":
		status_label.text = "Speaker name cannot be empty."
		return false
	var old_id := _selected_dialogue_id
	var new_id := dialogue_id_edit.text.strip_edges()
	if new_id != old_id:
		var renamed := CampaignStore.rename_dialogue(draft, old_id, new_id)
		if not bool(renamed.get("ok", false)):
			status_label.text = String(renamed.get("message", "Rename refused."))
			return false
		_selected_dialogue_id = new_id
	var dialogue := CampaignStore.dialogue_by_id(draft, _selected_dialogue_id)
	var old_speaker := String(dialogue.get("speaker", ""))
	dialogue["speaker"] = new_speaker
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	for raw_node_id in nodes.keys():
		var node: Dictionary = Dictionary(nodes[raw_node_id]).duplicate(true)
		if String(node.get("speaker_name", "")) == old_speaker:
			node["speaker_name"] = new_speaker
		nodes[raw_node_id] = node
	dialogue["nodes"] = nodes
	_mark_dirty()
	_refresh_all()
	status_label.text = "Conversation '%s' now speaks as '%s'." % [_selected_dialogue_id, new_speaker]
	return true


func _set_start_node() -> void:
	if start_option.selected < 0:
		status_label.text = "Select a start node first."
		return
	capture_draft()
	var node_id := String(start_option.get_item_metadata(start_option.selected))
	var result := CampaignStore.set_dialogue_start(draft, _selected_dialogue_id, node_id)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()


func _add_node() -> void:
	if _selected_dialogue_id == "":
		status_label.text = "Select or create a conversation first."
		return
	capture_draft()
	var result := CampaignStore.add_dialogue_node(draft, _selected_dialogue_id)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_selected_node_id = String(result.get("id", ""))
		_selected_choice = 0
		_mark_dirty()
		_refresh_all()


func _delete_node() -> void:
	if _selected_node_id == "":
		status_label.text = "Select a node first."
		return
	capture_draft()
	var result := CampaignStore.delete_dialogue_node(draft, _selected_dialogue_id, _selected_node_id)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_selected_node_id = ""
		_selected_choice = 0
		_mark_dirty()
		_refresh_all()


func _rename_node() -> void:
	if _selected_node_id == "":
		status_label.text = "Select a node first."
		return
	capture_draft()
	var old_id := _selected_node_id
	var new_id := node_id_edit.text.strip_edges()
	var result := CampaignStore.rename_dialogue_node(draft, _selected_dialogue_id, old_id, new_id)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_selected_node_id = new_id
		_mark_dirty()
		_refresh_all()


func _apply_node() -> bool:
	if _selected_node_id == "":
		status_label.text = "Select a node first."
		return false
	capture_draft()
	var next_id := String(node_next_option.get_item_metadata(node_next_option.selected)) if node_next_option.selected >= 0 else ""
	var result := CampaignStore.set_dialogue_node(
		draft,
		_selected_dialogue_id,
		_selected_node_id,
		node_text_edit.text,
		speaker_edit.text,
		next_id,
		node_narration_edit.text,
		node_flag_edit.text
	)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
		return true
	return false


func _add_choice() -> void:
	if _selected_node_id == "":
		status_label.text = "Select a node first."
		return
	capture_draft()
	var result := CampaignStore.add_dialogue_choice(draft, _selected_dialogue_id, _selected_node_id)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_selected_choice = int(result.get("index", 0))
		_mark_dirty()
		_refresh_all()


func _remove_choice() -> void:
	if _selected_node_id == "":
		status_label.text = "Select a node first."
		return
	capture_draft()
	var result := CampaignStore.remove_dialogue_choice(
		draft, _selected_dialogue_id, _selected_node_id, _selected_choice
	)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_selected_choice = 0
		_mark_dirty()
		_refresh_all()


func _apply_choice() -> bool:
	if _selected_node_id == "":
		status_label.text = "Select a node first."
		return false
	capture_draft()
	var fields := {
		"text": choice_text_edit.text,
		"guard_flag": choice_guard_edit.text,
		"require_flag": choice_require_edit.text,
		"effect_flag": choice_effect_edit.text,
	}
	fields["quest_id"] = String(choice_quest_option.get_item_metadata(choice_quest_option.selected)) if choice_quest_option.selected >= 0 else ""
	fields["encounter_id"] = String(choice_encounter_option.get_item_metadata(choice_encounter_option.selected)) if choice_encounter_option.selected >= 0 else ""
	if choice_check_toggle.button_pressed:
		var skill := String(choice_skill_option.get_item_metadata(choice_skill_option.selected)) if choice_skill_option.selected >= 0 else ""
		var actor := String(choice_actor_option.get_item_metadata(choice_actor_option.selected)) if choice_actor_option.selected >= 0 else "best"
		var success := String(choice_success_option.get_item_metadata(choice_success_option.selected)) if choice_success_option.selected >= 0 else ""
		var failure := String(choice_failure_option.get_item_metadata(choice_failure_option.selected)) if choice_failure_option.selected >= 0 else ""
		fields["check"] = {
			"skill": skill,
			"dc": int(choice_dc_spin.value),
			"actor": actor,
			"success": success,
			"failure": failure,
		}
		fields["next"] = ""
	else:
		fields["check"] = {}
		fields["next"] = String(choice_dest_option.get_item_metadata(choice_dest_option.selected)) if choice_dest_option.selected >= 0 else ""
	var result := CampaignStore.update_dialogue_choice(
		draft, _selected_dialogue_id, _selected_node_id, _selected_choice, fields
	)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
		return true
	return false


func _save(on_saved := Callable()) -> bool:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _save(on_saved), "save")
		return false
	capture_draft()
	var result := CampaignStore.write_package(draft)
	if bool(result.get("ok", false)):
		dirty = false
		status_label.text = "Saved to user://campaigns/%s." % String(draft.get("id", ""))
		status_label.add_theme_color_override("font_color", ThemeBuilder.GOOD)
		_refresh_all()
		if on_saved.is_valid():
			on_saved.call()
		return true
	var errors: Array = result.get("errors", [String(result.get("message", "Save failed."))])
	status_label.text = "Not saved: " + String(errors[0])
	for i in mini(4, errors.size()):
		status_label.text += "\n- " + String(errors[i])
	status_label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
	return false


func _validate() -> void:
	capture_draft()
	var pending := pending_form_keys()
	var result := Game.validate_campaign_draft_diagnostics(draft)
	diagnostics = Array(result.get("diagnostics", []))
	_render_diagnostics()
	var errors: Array = result.get("errors", [])
	if bool(result.get("ok", false)):
		var warnings := ContentDiagnostics.count(diagnostics, ContentDiagnostics.WARNING)
		if not pending.is_empty():
			status_label.text = "Applied draft validates, but pending form edits are not included. Apply or discard them before saving or playtesting."
			status_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
			_refresh_pending_label()
			return
		status_label.text = "Draft validates: ids, maps, entry, transitions and references."
		if warnings > 0:
			status_label.text += " %d warning(s) are listed below." % warnings
		status_label.add_theme_color_override("font_color", ThemeBuilder.GOOD)
		return
	status_label.text = "Draft has %d problem(s):" % errors.size()
	for i in mini(6, errors.size()):
		status_label.text += "\n- " + String(errors[i])
	if not pending.is_empty():
		status_label.text += "\nPending form edits are separate; apply or discard them before saving or playtesting."
	status_label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
	_refresh_pending_label()


func _render_diagnostics() -> void:
	_clear(diagnostics_panel)
	if diagnostics.is_empty():
		diagnostics_panel.visible = false
		return
	diagnostics_panel.visible = true
	var summary := Label.new()
	summary.text = ContentDiagnostics.summary(diagnostics) + " Select a result to jump to its editor field."
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 12)
	summary.add_theme_color_override("font_color", ThemeBuilder.MUTED)
	diagnostics_panel.add_child(summary)
	var shown := 0
	for diag in diagnostics:
		if shown >= 4:
			break
		var entry: Dictionary = diag
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 28)
		button.text = "%s  %s" % [String(entry.get("severity", "error")).to_upper(), String(entry.get("message", ""))]
		button.tooltip_text = "%s • %s • %s" % [
			String(entry.get("code", "")),
			String(entry.get("source", "draft")),
			String(entry.get("field", "field")),
		]
		button.add_theme_color_override("font_color", ThemeBuilder.DANGER if String(entry.get("severity", "")) == "error" else ThemeBuilder.GOLD)
		button.pressed.connect(func() -> void: _navigate_diagnostic(entry))
		diagnostics_panel.add_child(button)
		shown += 1
	if diagnostics.size() > shown:
		var more := Label.new()
		more.text = "+ %d more; correct these and validate again." % (diagnostics.size() - shown)
		more.add_theme_font_size_override("font_size", 11)
		more.add_theme_color_override("font_color", ThemeBuilder.MUTED)
		diagnostics_panel.add_child(more)


func _navigate_diagnostic(diag: Dictionary) -> void:
	var section := String(diag.get("section", "advanced"))
	var area_id := String(diag.get("area_id", ""))
	var entity_id := String(diag.get("entity_id", ""))
	if section == "advanced" or bool(diag.get("advanced", false)):
		status_label.text = "This problem is outside the form editor. Edit %s in the package JSON, then validate again." % String(diag.get("source", "the package"))
		status_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
		return
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void:
			_validate()
			_navigate_diagnostic(diag)
		, "open this validation result")
		return
	if area_id != "" and not _select_area_by_id(area_id):
		_stale_diagnostic()
		return
	match section:
		"metadata":
			await _focus_control(title_edit)
		"entry":
			await _focus_control(set_entry_button)
		"passage":
			await _focus_control(target_option)
		"area":
			await _focus_control(area_name_edit)
		"npc":
			if not _select_npc_by_id(entity_id):
				_stale_diagnostic()
				return
			await _focus_control(npc_dialogue_option if String(diag.get("field", "")) == "dialogue" else npc_name_edit)
		"dialogue":
			if not _select_dialogue_by_id(entity_id):
				_stale_diagnostic()
				return
			await _focus_control(start_option if String(diag.get("field", "")) == "start" else dialogue_id_edit)
		"node":
			if not _select_ref_dialogue(diag) or not _select_node_by_id(entity_id):
				_stale_diagnostic()
				return
			await _focus_control(node_text_edit if String(diag.get("field", "")) == "text" else node_next_option)
		"choice":
			if not _select_ref_dialogue(diag) or not _select_choice_by_id(entity_id, int(diag.get("choice_index", 0))):
				_stale_diagnostic()
				return
			await _focus_control(choice_text_edit)
		"quest":
			if not _select_quest_by_id(entity_id):
				_stale_diagnostic()
				return
			await _focus_control(quest_title_edit)
		"objective":
			var refs := Array(diag.get("refs", []))
			if not refs.is_empty() and not _select_quest_by_id(String(refs[0])):
				_stale_diagnostic()
				return
			if not _select_objective_by_id(entity_id):
				_stale_diagnostic()
				return
			await _focus_control(objective_flag_edit if String(diag.get("field", "")) == "flag" else objective_text_edit)
		"flag":
			focus_flag_section()
			flag_edit.text = entity_id
			await _focus_control(flag_edit)
		"encounter":
			if not _select_encounter_by_id(entity_id):
				_stale_diagnostic()
				return
			await _focus_control(encounter_name_edit)
		"trigger":
			if not _select_trigger_by_id(entity_id):
				_stale_diagnostic()
				return
			await _focus_control(trigger_guard_edit)
		_:
			_stale_diagnostic()


func _focus_control(control: Control) -> void:
	if control == null or scroll == null:
		return
	await get_tree().process_frame
	if not is_instance_valid(control):
		return
	scroll.ensure_control_visible(control)
	last_focused_control = control
	control.grab_focus()


func _stale_diagnostic() -> void:
	status_label.text = "That item no longer exists in the draft. Validate draft again to refresh the results."
	status_label.add_theme_color_override("font_color", ThemeBuilder.GOLD)


func _select_area_by_id(area_id: String) -> bool:
	for i in Array(draft.get("areas", [])).size():
		if String(Dictionary(Array(draft.get("areas", []))[i]).get("id", "")) == area_id:
			if selected_area != i:
				_select_area(i)
			return true
	return false


func _select_npc_by_id(npc_id: String) -> bool:
	if CampaignStore.find_npc(draft, _area_id(), npc_id).is_empty():
		return false
	for i in npc_option.item_count:
		if String(npc_option.get_item_metadata(i)) == npc_id:
			_select_npc(i)
			return true
	return false


func _select_ref_dialogue(diag: Dictionary) -> bool:
	var refs := Array(diag.get("refs", []))
	if refs.is_empty():
		return false
	return _select_dialogue_by_id(String(refs[0]))


func _select_dialogue_by_id(dialogue_id: String) -> bool:
	if CampaignStore.dialogue_by_id(draft, dialogue_id).is_empty():
		return false
	for i in dialogue_option.item_count:
		if String(dialogue_option.get_item_metadata(i)) == dialogue_id:
			_select_dialogue(i)
			return true
	return false


func _select_node_by_id(node_id: String) -> bool:
	var dialogue := CampaignStore.dialogue_by_id(draft, _selected_dialogue_id)
	if not Dictionary(dialogue.get("nodes", {})).has(node_id):
		return false
	for i in node_option.item_count:
		if String(node_option.get_item_metadata(i)) == node_id:
			_select_node(i)
			return true
	return false


func _select_choice_by_id(node_id: String, choice_index: int) -> bool:
	if not _select_node_by_id(node_id):
		return false
	if choice_index < 0 or choice_index >= choice_option.item_count:
		return false
	_select_choice(choice_index)
	return true


func _select_quest_by_id(quest_id: String) -> bool:
	if CampaignStore.quest_by_id(draft, quest_id).is_empty():
		return false
	for i in quest_option.item_count:
		if String(quest_option.get_item_metadata(i)) == quest_id:
			_select_quest(i)
			return true
	return false


func _select_objective_by_id(objective_id: String) -> bool:
	var found := false
	for raw_objective in Array(CampaignStore.quest_by_id(draft, _selected_quest_id).get("objectives", [])):
		if raw_objective is Dictionary and String(Dictionary(raw_objective).get("id", "")) == objective_id:
			found = true
	if not found:
		return false
	for i in objective_option.item_count:
		if String(objective_option.get_item_metadata(i)) == objective_id:
			_select_objective(i)
			return true
	return false


func _select_encounter_by_id(encounter_id: String) -> bool:
	if CampaignStore.encounter_by_id(draft, encounter_id).is_empty():
		return false
	for i in encounter_option.item_count:
		if String(encounter_option.get_item_metadata(i)) == encounter_id:
			_select_encounter(i)
			return true
	return false


func _select_trigger_by_id(trigger_id: String) -> bool:
	var found := false
	for raw_trigger in CampaignStore.triggers_of(draft, _area_id()):
		if raw_trigger is Dictionary and String(Dictionary(raw_trigger).get("id", "")) == trigger_id:
			found = true
	if not found:
		return false
	for i in trigger_option.item_count:
		if String(trigger_option.get_item_metadata(i)) == trigger_id:
			_select_trigger(i)
			return true
	return false


func _playtest() -> void:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _playtest(), "start playtest")
		return
	capture_draft()
	var validation := Game.validate_campaign_draft(draft)
	if not bool(validation.get("ok", false)):
		var errors: Array = validation.get("errors", [])
		status_label.text = "Playtest needs a valid draft:" + ("\n- " + String(errors[0]) if not errors.is_empty() else "")
		status_label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		return
	var staged := CampaignStore.stage_playtest(draft)
	if not bool(staged.get("ok", false)):
		status_label.text = "Playtest could not stage a snapshot: " + String(staged.get("message", ""))
		status_label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		return
	main.start_creator_playtest(draft, staged, dirty)


func _back() -> void:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _back(), "leave the creator")
		return
	capture_draft()
	if not dirty:
		main.show_campaign_list()
		return
	main.open_modal("Unsaved changes", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(
			"The draft has changes that are not saved to disk. Save before leaving the creator?",
			false,
			14
		))
		var save_leave := Button.new()
		save_leave.text = "Save and leave"
		save_leave.custom_minimum_size = Vector2(0, 40)
		save_leave.pressed.connect(func() -> void:
			_save(func() -> void:
				main.close_modal()
				main.show_campaign_list()
			)
		)
		box.add_child(save_leave)
		var discard := Button.new()
		discard.text = "Discard changes and leave"
		discard.custom_minimum_size = Vector2(0, 40)
		discard.pressed.connect(func() -> void:
			dirty = false
			main.close_modal()
			main.show_campaign_list()
		)
		box.add_child(discard)
		var cancel := Button.new()
		cancel.text = "Keep editing"
		cancel.custom_minimum_size = Vector2(0, 40)
		cancel.pressed.connect(main.close_modal)
		box.add_child(cancel)
		return box
	, 620, 300)


# ------------------------------------------------------- quests and encounters
#
# These sections call the same CampaignStore helpers as the automated probe, so
# a control bug surfaces as a failed assertion instead of a second code path.

func _quest_entries() -> Array:
	var entries: Array = []
	var quests := CampaignStore.quests_of(draft)
	var ids: Array = quests.keys()
	ids.sort()
	for raw_id in ids:
		var quest_id := String(raw_id)
		var quest: Dictionary = Dictionary(quests[raw_id])
		entries.append({"label": "%s (%s)" % [String(quest.get("title", quest_id)), quest_id], "meta": quest_id})
	return entries


func _quest_entries_with_none() -> Array:
	var entries: Array = [{"label": "(no quest)", "meta": ""}]
	entries.append_array(_quest_entries())
	return entries


func _encounter_entries() -> Array:
	var entries: Array = []
	var encounters := CampaignStore.encounters_of(draft)
	var ids: Array = encounters.keys()
	ids.sort()
	for raw_id in ids:
		var encounter_id := String(raw_id)
		var encounter: Dictionary = Dictionary(encounters[raw_id])
		entries.append({"label": "%s (%s)" % [String(encounter.get("name", encounter_id)), encounter_id], "meta": encounter_id})
	return entries


func _encounter_entries_with_none() -> Array:
	var entries: Array = [{"label": "(no encounter)", "meta": ""}]
	entries.append_array(_encounter_entries())
	return entries


func _flag_entries() -> Array:
	var entries: Array = []
	for raw_flag in CampaignStore.known_flags(draft):
		entries.append({"label": String(raw_flag), "meta": String(raw_flag)})
	return entries


func _shared_monsters() -> Dictionary:
	if _monsters_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://content/shared/monsters.json"))
		if parsed is Dictionary:
			_monsters_cache = Dictionary(parsed).duplicate(true)
	return _monsters_cache


func _monster_entries() -> Array:
	var entries: Array = []
	var monsters := _shared_monsters()
	var ids: Array = monsters.keys()
	ids.sort()
	for raw_id in ids:
		var monster_id := String(raw_id)
		entries.append({
			"label": "%s (%s)" % [String(Dictionary(monsters[raw_id]).get("name", monster_id)), monster_id],
			"meta": monster_id,
		})
	return entries


## Row labels next to an expanding picker must not wrap: without a minimum width
## a Label collapses to one character per line at the largest text scale.
func _fixed_label(text: String, width: float) -> Label:
	var label := ThemeBuilder.body(text, true, 11)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2(width, 0)
	return label


func _build_quest_section(root: VBoxContainer) -> void:
	root.add_child(ThemeBuilder.separator())
	root.add_child(ThemeBuilder.heading("Quests", 20))
	root.add_child(ThemeBuilder.body(
		"An objective completes when its flag is set, and only after its quest has started. A completed quest ends the campaign only when it is also chosen as the completion quest. Objective flags set before the quest starts stay uncredited until the quest is active.",
		true,
		12
	))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	root.add_child(head)
	var quest_label := ThemeBuilder.body("Quest", true, 13)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	quest_label.custom_minimum_size = Vector2(60, 0)
	head.add_child(quest_label)
	quest_option = OptionButton.new()
	quest_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_option.item_selected.connect(_select_quest)
	head.add_child(quest_option)
	var new_quest := Button.new()
	new_quest.text = "New quest"
	new_quest.custom_minimum_size = Vector2(110, 34)
	new_quest.pressed.connect(_new_quest)
	head.add_child(new_quest)
	var delete_quest := Button.new()
	delete_quest.text = "Delete quest"
	delete_quest.custom_minimum_size = Vector2(120, 34)
	delete_quest.pressed.connect(_confirm_delete_quest)
	head.add_child(delete_quest)
	var id_row := HBoxContainer.new()
	id_row.add_theme_constant_override("separation", 6)
	root.add_child(id_row)
	quest_id_edit = LineEdit.new()
	quest_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_id_edit.placeholder_text = "quest id (stable, campaign-local)"
	id_row.add_child(quest_id_edit)
	var rename_quest := Button.new()
	rename_quest.text = "Rename quest"
	rename_quest.custom_minimum_size = Vector2(130, 34)
	rename_quest.pressed.connect(_rename_quest)
	id_row.add_child(rename_quest)
	quest_title_edit = LineEdit.new()
	quest_title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_title_edit.placeholder_text = "Quest title"
	root.add_child(quest_title_edit)
	quest_summary_edit = TextEdit.new()
	quest_summary_edit.custom_minimum_size = Vector2(0, 64)
	quest_summary_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	quest_summary_edit.placeholder_text = "Placeholder quest description"
	root.add_child(quest_summary_edit)
	var campaign_row := HBoxContainer.new()
	campaign_row.add_theme_constant_override("separation", 6)
	root.add_child(campaign_row)
	var start_label := ThemeBuilder.body("Campaign start", true, 11)
	start_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	campaign_row.add_child(start_label)
	quest_start_option = OptionButton.new()
	quest_start_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_row.add_child(quest_start_option)
	var completion_label := ThemeBuilder.body("Campaign completion", true, 11)
	completion_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	campaign_row.add_child(completion_label)
	quest_completion_option = OptionButton.new()
	quest_completion_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_row.add_child(quest_completion_option)
	var apply_quest := Button.new()
	apply_quest.text = "Apply quest"
	apply_quest.custom_minimum_size = Vector2(120, 34)
	apply_quest.pressed.connect(_apply_quest)
	campaign_row.add_child(apply_quest)
	var objective_head := HBoxContainer.new()
	objective_head.add_theme_constant_override("separation", 6)
	root.add_child(objective_head)
	var objective_label := ThemeBuilder.body("Objective", true, 13)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	objective_label.custom_minimum_size = Vector2(74, 0)
	objective_head.add_child(objective_label)
	objective_option = OptionButton.new()
	objective_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_option.item_selected.connect(_select_objective)
	objective_head.add_child(objective_option)
	var add_objective_button := Button.new()
	add_objective_button.text = "Add objective"
	add_objective_button.custom_minimum_size = Vector2(130, 34)
	add_objective_button.pressed.connect(_add_objective)
	objective_head.add_child(add_objective_button)
	var remove_objective_button := Button.new()
	remove_objective_button.text = "Remove"
	remove_objective_button.custom_minimum_size = Vector2(90, 34)
	remove_objective_button.pressed.connect(_remove_objective)
	objective_head.add_child(remove_objective_button)
	var objective_row := HBoxContainer.new()
	objective_row.add_theme_constant_override("separation", 6)
	root.add_child(objective_row)
	objective_id_edit = LineEdit.new()
	objective_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_id_edit.placeholder_text = "objective id"
	objective_row.add_child(objective_id_edit)
	objective_flag_option = OptionButton.new()
	objective_flag_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_flag_option.item_selected.connect(_select_objective_flag)
	objective_row.add_child(objective_flag_option)
	objective_flag_edit = LineEdit.new()
	objective_flag_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_flag_edit.placeholder_text = "objective flag"
	objective_row.add_child(objective_flag_edit)
	var apply_objective := Button.new()
	apply_objective.text = "Apply objective"
	apply_objective.custom_minimum_size = Vector2(140, 34)
	apply_objective.pressed.connect(_apply_objective)
	objective_row.add_child(apply_objective)
	objective_text_edit = LineEdit.new()
	objective_text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_text_edit.placeholder_text = "Objective text"
	root.add_child(objective_text_edit)
	quest_refs_label = ThemeBuilder.body("", true, 11)
	quest_refs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(quest_refs_label)


func _build_flag_section(root: VBoxContainer) -> void:
	root.add_child(ThemeBuilder.separator())
	root.add_child(ThemeBuilder.heading("Campaign flags", 20))
	root.add_child(ThemeBuilder.body(
		"Flags are the only consequence currency. Define the flags you intend to set: a used flag that is not declared is listed as undeclared, so a typo stays visible instead of becoming hidden state.",
		true,
		12
	))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	root.add_child(row)
	flag_edit = LineEdit.new()
	flag_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flag_edit.placeholder_text = "flag_name"
	row.add_child(flag_edit)
	flag_desc_edit = LineEdit.new()
	flag_desc_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flag_desc_edit.placeholder_text = "What this flag means"
	row.add_child(flag_desc_edit)
	var define_flag := Button.new()
	define_flag.text = "Define flag"
	define_flag.custom_minimum_size = Vector2(110, 34)
	define_flag.pressed.connect(_define_flag)
	row.add_child(define_flag)
	var inspect_flag := Button.new()
	inspect_flag.text = "Inspect references"
	inspect_flag.custom_minimum_size = Vector2(160, 34)
	inspect_flag.pressed.connect(_inspect_flag)
	row.add_child(inspect_flag)
	var remove_flag := Button.new()
	remove_flag.text = "Remove definition"
	remove_flag.custom_minimum_size = Vector2(160, 34)
	remove_flag.pressed.connect(_remove_flag)
	row.add_child(remove_flag)
	flags_label = ThemeBuilder.body("", true, 11)
	flags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(flags_label)


func _build_encounter_section(root: VBoxContainer) -> void:
	root.add_child(ThemeBuilder.separator())
	root.add_child(ThemeBuilder.heading("Encounters", 20))
	root.add_child(ThemeBuilder.body(
		"Supported layouts place the party and up to four shared monsters on legal cells. Victory consequences are applied by the existing combat engine; monster statistics, new spells and tactical AI are not editable here.",
		true,
		12
	))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	root.add_child(head)
	var encounter_label := ThemeBuilder.body("Encounter", true, 13)
	encounter_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	encounter_label.custom_minimum_size = Vector2(74, 0)
	head.add_child(encounter_label)
	encounter_option = OptionButton.new()
	encounter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_option.item_selected.connect(_select_encounter)
	head.add_child(encounter_option)
	var new_encounter := Button.new()
	new_encounter.text = "New encounter"
	new_encounter.custom_minimum_size = Vector2(140, 34)
	new_encounter.pressed.connect(_new_encounter)
	head.add_child(new_encounter)
	var delete_encounter := Button.new()
	delete_encounter.text = "Delete encounter"
	delete_encounter.custom_minimum_size = Vector2(150, 34)
	delete_encounter.pressed.connect(_confirm_delete_encounter)
	head.add_child(delete_encounter)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 6)
	root.add_child(identity_row)
	encounter_id_edit = LineEdit.new()
	encounter_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_id_edit.placeholder_text = "encounter id"
	identity_row.add_child(encounter_id_edit)
	var rename_encounter := Button.new()
	rename_encounter.text = "Rename"
	rename_encounter.custom_minimum_size = Vector2(90, 34)
	rename_encounter.pressed.connect(_rename_encounter)
	identity_row.add_child(rename_encounter)
	encounter_name_edit = LineEdit.new()
	encounter_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_name_edit.placeholder_text = "Encounter name"
	identity_row.add_child(encounter_name_edit)
	encounter_xp_spin = SpinBox.new()
	encounter_xp_spin.min_value = 0
	encounter_xp_spin.max_value = 100000
	encounter_xp_spin.step = 25
	encounter_xp_spin.custom_minimum_size = Vector2(110, 0)
	identity_row.add_child(encounter_xp_spin)
	var apply_encounter := Button.new()
	apply_encounter.text = "Apply encounter"
	apply_encounter.custom_minimum_size = Vector2(140, 34)
	apply_encounter.pressed.connect(_apply_encounter)
	identity_row.add_child(apply_encounter)
	encounter_intro_edit = LineEdit.new()
	encounter_intro_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_intro_edit.placeholder_text = "Placeholder introduction when combat starts"
	root.add_child(encounter_intro_edit)
	var layout_row := HBoxContainer.new()
	layout_row.add_theme_constant_override("separation", 6)
	root.add_child(layout_row)
	layout_row.add_child(_fixed_label("Battle map", 90))
	encounter_template_option = OptionButton.new()
	encounter_template_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout_row.add_child(encounter_template_option)
	var apply_layout := Button.new()
	apply_layout.text = "Apply layout"
	apply_layout.custom_minimum_size = Vector2(120, 34)
	apply_layout.pressed.connect(_apply_layout)
	layout_row.add_child(apply_layout)
	var monster_row := HBoxContainer.new()
	monster_row.add_theme_constant_override("separation", 6)
	root.add_child(monster_row)
	monster_row.add_child(_fixed_label("Monster", 70))
	encounter_monster_option = OptionButton.new()
	encounter_monster_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	monster_row.add_child(encounter_monster_option)
	var add_monster := Button.new()
	add_monster.text = "Add monster"
	add_monster.custom_minimum_size = Vector2(120, 34)
	add_monster.pressed.connect(_add_monster)
	monster_row.add_child(add_monster)
	var remove_monster := Button.new()
	remove_monster.text = "Remove last"
	remove_monster.custom_minimum_size = Vector2(120, 34)
	remove_monster.pressed.connect(_remove_last_monster)
	monster_row.add_child(remove_monster)
	encounter_monsters_label = ThemeBuilder.body("", true, 11)
	encounter_monsters_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(encounter_monsters_label)
	var victory_row := HBoxContainer.new()
	victory_row.add_theme_constant_override("separation", 6)
	root.add_child(victory_row)
	victory_row.add_child(_fixed_label("Victory flag", 100))
	victory_flag_option = OptionButton.new()
	victory_flag_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	victory_flag_option.item_selected.connect(_select_victory_flag)
	victory_row.add_child(victory_flag_option)
	victory_flag_edit = LineEdit.new()
	victory_flag_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	victory_flag_edit.placeholder_text = "flag set on victory"
	victory_row.add_child(victory_flag_edit)
	victory_quest_option = OptionButton.new()
	victory_quest_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	victory_row.add_child(victory_quest_option)
	var apply_victory := Button.new()
	apply_victory.text = "Apply victory"
	apply_victory.custom_minimum_size = Vector2(130, 34)
	apply_victory.pressed.connect(_apply_victory)
	victory_row.add_child(apply_victory)
	victory_narration_edit = LineEdit.new()
	victory_narration_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	victory_narration_edit.placeholder_text = "Placeholder narration after victory (optional)"
	root.add_child(victory_narration_edit)


func _build_trigger_section(root: VBoxContainer) -> void:
	root.add_child(ThemeBuilder.separator())
	root.add_child(ThemeBuilder.heading("Encounter triggers", 20))
	root.add_child(ThemeBuilder.body(
		"Place a trigger on the selected floor cell of the current area. A trigger fires once per playthrough and is marked spent. Leaving the guard empty uses the encounter's victory flag, so a cleared encounter never repeats after a reload.",
		true,
		12
	))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	root.add_child(head)
	var trigger_label := ThemeBuilder.body("Trigger", true, 13)
	trigger_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	trigger_label.custom_minimum_size = Vector2(60, 0)
	head.add_child(trigger_label)
	trigger_option = OptionButton.new()
	trigger_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_option.item_selected.connect(_select_trigger)
	head.add_child(trigger_option)
	var place_trigger := Button.new()
	place_trigger.text = "Place here"
	place_trigger.custom_minimum_size = Vector2(110, 34)
	place_trigger.pressed.connect(_place_trigger)
	head.add_child(place_trigger)
	var update_trigger := Button.new()
	update_trigger.text = "Update trigger"
	update_trigger.custom_minimum_size = Vector2(130, 34)
	update_trigger.pressed.connect(_update_trigger)
	head.add_child(update_trigger)
	var remove_trigger := Button.new()
	remove_trigger.text = "Remove trigger"
	remove_trigger.custom_minimum_size = Vector2(130, 34)
	remove_trigger.pressed.connect(_remove_trigger)
	head.add_child(remove_trigger)
	var guard_row := HBoxContainer.new()
	guard_row.add_theme_constant_override("separation", 6)
	root.add_child(guard_row)
	trigger_guard_edit = LineEdit.new()
	trigger_guard_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_guard_edit.placeholder_text = "once-only guard flag (optional; defaults to the victory flag)"
	guard_row.add_child(trigger_guard_edit)
	trigger_narration_edit = LineEdit.new()
	trigger_narration_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_narration_edit.placeholder_text = "Narration when the trigger fires (optional)"
	guard_row.add_child(trigger_narration_edit)
	trigger_status = ThemeBuilder.body("", true, 11)
	trigger_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(trigger_status)


# ------------------------------------------------------------------ refresh

func _refresh_flags() -> void:
	if flags_label == null:
		return
	var defs := CampaignStore.flags_of(draft)
	var defined: Array[String] = []
	for raw_flag in defs.keys():
		defined.append(String(raw_flag))
	defined.sort()
	var undeclared: Array[String] = []
	for flag in CampaignStore.known_flags(draft):
		if not defs.has(flag):
			undeclared.append(flag)
	flags_label.text = "Defined: %s\nUsed but not defined: %s" % [
		(", ".join(defined) if not defined.is_empty() else "(none)"),
		(", ".join(undeclared) if not undeclared.is_empty() else "(none)"),
	]
	var entries := _flag_entries()
	_fill_options(objective_flag_option, entries, "")
	_fill_options(victory_flag_option, entries, "")
	_fill_options(choice_flag_option, entries, "")


func _refresh_quests() -> void:
	if quest_option == null:
		return
	var entries := _quest_entries()
	var ids: Array = []
	for entry in entries:
		ids.append(String(Dictionary(entry).get("meta", "")))
	if not ids.has(_selected_quest_id):
		_selected_quest_id = String(ids[0]) if not ids.is_empty() else ""
	_fill_options(quest_option, entries, _selected_quest_id)
	_fill_options(quest_start_option, _quest_entries(), String(draft.get("start_quest", "")))
	_fill_options(quest_completion_option, _quest_entries_with_none(), String(draft.get("completion_quest", "")))
	var quest := CampaignStore.quest_by_id(draft, _selected_quest_id)
	quest_id_edit.text = _selected_quest_id
	quest_title_edit.text = String(quest.get("title", ""))
	quest_summary_edit.text = String(quest.get("summary", ""))
	var objectives: Array = Array(quest.get("objectives", []))
	var objective_entries: Array = []
	var objective_ids: Array = []
	for raw_objective in objectives:
		if not raw_objective is Dictionary:
			continue
		var objective: Dictionary = raw_objective
		var objective_id := String(objective.get("id", ""))
		objective_ids.append(objective_id)
		objective_entries.append({
			"label": "%s — %s" % [objective_id, String(objective.get("text", ""))],
			"meta": objective_id,
		})
	if not objective_ids.has(_selected_objective_id):
		_selected_objective_id = String(objective_ids[0]) if not objective_ids.is_empty() else ""
	_fill_options(objective_option, objective_entries, _selected_objective_id)
	var selected_objective := {}
	for raw_objective in objectives:
		if raw_objective is Dictionary and String(Dictionary(raw_objective).get("id", "")) == _selected_objective_id:
			selected_objective = Dictionary(raw_objective)
	objective_id_edit.text = String(selected_objective.get("id", ""))
	objective_text_edit.text = String(selected_objective.get("text", ""))
	objective_flag_edit.text = String(selected_objective.get("flag", ""))
	if _selected_quest_id == "":
		quest_refs_label.text = "No quests yet. Create one: the campaign needs a start quest."
		return
	var refs := CampaignStore.quest_references(draft, _selected_quest_id)
	quest_refs_label.text = "References: " + (", ".join(refs) if not refs.is_empty() else "(none yet)")


func _refresh_encounters() -> void:
	if encounter_option == null:
		return
	var entries := _encounter_entries()
	var ids: Array = []
	for entry in entries:
		ids.append(String(Dictionary(entry).get("meta", "")))
	if not ids.has(_selected_encounter_id):
		_selected_encounter_id = String(ids[0]) if not ids.is_empty() else ""
	_fill_options(encounter_option, entries, _selected_encounter_id)
	var encounter := CampaignStore.encounter_by_id(draft, _selected_encounter_id)
	encounter_id_edit.text = _selected_encounter_id
	encounter_name_edit.text = String(encounter.get("name", ""))
	encounter_xp_spin.value = float(int(encounter.get("xp", 0)))
	encounter_intro_edit.text = String(encounter.get("intro", ""))
	if encounter_template_option.item_count == 0:
		for template_id in CampaignStore.ENCOUNTER_TEMPLATES.keys():
			encounter_template_option.add_item(String(Dictionary(CampaignStore.ENCOUNTER_TEMPLATES[template_id]).get("label", template_id)))
			encounter_template_option.set_item_metadata(encounter_template_option.item_count - 1, String(template_id))
	_fill_options(encounter_monster_option, _monster_entries(), "")
	var monsters: Array = Array(encounter.get("monsters", []))
	var cells: Array = Array(encounter.get("monster_cells", []))
	var monster_lines: Array[String] = []
	for i in monsters.size():
		monster_lines.append("%d. %s" % [i + 1, String(monsters[i])])
	encounter_monsters_label.text = "Monsters (%d of %d cells): %s" % [
		monsters.size(),
		mini(CampaignStore.MAX_ENCOUNTER_MONSTERS, cells.size()),
		(", ".join(monster_lines) if not monster_lines.is_empty() else "(none)"),
	]
	var victory_flag := ""
	var victory_narration := ""
	var victory_quest := ""
	for raw_effect in Array(encounter.get("victory_effects", [])):
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		if String(effect.get("type", "")) == "set_flag" and victory_flag == "":
			victory_flag = String(effect.get("flag", ""))
		if String(effect.get("type", "")) == "narration" and victory_narration == "":
			victory_narration = String(effect.get("text", ""))
		if String(effect.get("type", "")) == "quest_start" and victory_quest == "":
			victory_quest = String(effect.get("quest", ""))
	victory_flag_edit.text = victory_flag
	victory_narration_edit.text = victory_narration
	_fill_options(victory_quest_option, _quest_entries_with_none(), victory_quest)


func _refresh_triggers() -> void:
	if trigger_option == null:
		return
	var triggers := CampaignStore.triggers_of(draft, _area_id())
	var entries: Array = []
	var ids: Array = []
	for raw_trigger in triggers:
		if not raw_trigger is Dictionary:
			continue
		var trigger: Dictionary = raw_trigger
		var trigger_id := String(trigger.get("id", ""))
		ids.append(trigger_id)
		var pos: Array = Array(trigger.get("pos", [0, 0]))
		entries.append({
			"label": "%s @ (%d, %d) → %s" % [trigger_id, int(pos[0]), int(pos[1]), String(trigger.get("encounter", "?"))],
			"meta": trigger_id,
		})
	if not ids.has(_selected_trigger_id):
		_selected_trigger_id = String(ids[0]) if not ids.is_empty() else ""
	_fill_options(trigger_option, entries, _selected_trigger_id)
	var lines: Array[String] = []
	for raw_trigger in triggers:
		if not raw_trigger is Dictionary:
			continue
		var trigger: Dictionary = raw_trigger
		var guard := String(trigger.get("requires_flag_not", ""))
		var suffix := ""
		if guard != "":
			suffix = " (once-only guard: %s)" % guard
		lines.append("%s → %s%s" % [String(trigger.get("id", "?")), String(trigger.get("encounter", "?")), suffix])
	trigger_status.text = "Triggers in %s: %s" % [_area_id(), (", ".join(lines) if not lines.is_empty() else "(none)")]


# ---------------------------------------------------------------- quest edits

func _select_quest(index: int) -> void:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_quest(index), "switch quest")
		return
	_selected_quest_id = String(quest_option.get_item_metadata(index))
	_selected_objective_id = ""
	_refresh_quests()


func _new_quest() -> void:
	capture_draft()
	var result := CampaignStore.add_quest(draft)
	if bool(result.get("ok", false)):
		_selected_quest_id = String(result.get("id", ""))
		_selected_objective_id = ""
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _rename_quest() -> void:
	if _selected_quest_id == "":
		status_label.text = "Select a quest first."
		return
	capture_draft()
	var new_id := quest_id_edit.text.strip_edges()
	var result := CampaignStore.rename_quest(draft, _selected_quest_id, new_id)
	if bool(result.get("ok", false)):
		_selected_quest_id = new_id
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _confirm_delete_quest() -> void:
	if _selected_quest_id == "":
		status_label.text = "Select a quest first."
		return
	var quest_id := _selected_quest_id
	var refs := CampaignStore.quest_references(draft, quest_id)
	if not refs.is_empty():
		status_label.text = "Cannot delete quest '%s'; still referenced by %s." % [quest_id, ", ".join(refs)]
		return
	main.open_modal("Delete quest", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(
			"Delete quest '%s'? Nothing references it, so no dialogue, trigger or encounter will break." % quest_id,
			true,
			14
		))
		var confirm := Button.new()
		confirm.text = "Delete quest"
		confirm.custom_minimum_size = Vector2(0, 40)
		confirm.pressed.connect(func() -> void:
			main.close_modal()
			capture_draft()
			var result := CampaignStore.delete_quest(draft, quest_id)
			if bool(result.get("ok", false)):
				_selected_quest_id = ""
				_selected_objective_id = ""
				_mark_dirty()
				_refresh_all()
			status_label.text = String(result.get("message", ""))
		)
		box.add_child(confirm)
		var cancel := Button.new()
		cancel.text = "Keep editing"
		cancel.custom_minimum_size = Vector2(0, 40)
		cancel.pressed.connect(main.close_modal)
		box.add_child(cancel)
		return box
	, 620, 280)


func _apply_quest() -> bool:
	if _selected_quest_id == "":
		status_label.text = "Select a quest first."
		return false
	capture_draft()
	var start_id := String(quest_start_option.get_item_metadata(quest_start_option.selected)) if quest_start_option.selected >= 0 else ""
	var completion_id := String(quest_completion_option.get_item_metadata(quest_completion_option.selected)) if quest_completion_option.selected >= 0 else ""
	var result := CampaignStore.set_quest_fields(
		draft, _selected_quest_id, quest_title_edit.text, quest_summary_edit.text, start_id, completion_id
	)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
		status_label.text = String(result.get("message", ""))
		return true
	status_label.text = String(result.get("message", ""))
	return false


func _select_objective(index: int) -> void:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_objective(index), "switch objective")
		return
	_selected_objective_id = String(objective_option.get_item_metadata(index))
	var quest := CampaignStore.quest_by_id(draft, _selected_quest_id)
	for raw_objective in Array(quest.get("objectives", [])):
		if raw_objective is Dictionary and String(Dictionary(raw_objective).get("id", "")) == _selected_objective_id:
			var objective: Dictionary = raw_objective
			objective_id_edit.text = _selected_objective_id
			objective_text_edit.text = String(objective.get("text", ""))
			objective_flag_edit.text = String(objective.get("flag", ""))


func _select_objective_flag(index: int) -> void:
	objective_flag_edit.text = String(objective_flag_option.get_item_metadata(index))


func _add_objective() -> void:
	if _selected_quest_id == "":
		status_label.text = "Select a quest first."
		return
	capture_draft()
	var result := CampaignStore.add_objective(draft, _selected_quest_id)
	if bool(result.get("ok", false)):
		_selected_objective_id = String(result.get("id", ""))
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _apply_objective() -> bool:
	if _selected_quest_id == "" or _selected_objective_id == "":
		status_label.text = "Select an objective first."
		return false
	capture_draft()
	var old_id := _selected_objective_id
	var new_id := objective_id_edit.text.strip_edges()
	var result := CampaignStore.update_objective(
		draft, _selected_quest_id, old_id, new_id, objective_text_edit.text, objective_flag_edit.text
	)
	status_label.text = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		_selected_objective_id = new_id
		_mark_dirty()
		_refresh_all()
		var flag := objective_flag_edit.text.strip_edges()
		if not CampaignStore.flags_of(draft).has(flag):
			status_label.text += " That flag is used but not declared; define it under Campaign flags if it is intentional."
		return true
	return false


func _remove_objective() -> void:
	if _selected_quest_id == "" or _selected_objective_id == "":
		status_label.text = "Select an objective first."
		return
	capture_draft()
	var result := CampaignStore.remove_objective(draft, _selected_quest_id, _selected_objective_id)
	if bool(result.get("ok", false)):
		_selected_objective_id = ""
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


# ----------------------------------------------------------------- flag edits

func _define_flag() -> void:
	capture_draft()
	var result := CampaignStore.add_flag_definition(draft, flag_edit.text, flag_desc_edit.text)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _inspect_flag() -> void:
	var flag := flag_edit.text.strip_edges()
	if flag == "":
		flag = String(choice_effect_edit.text).strip_edges()
	if flag == "":
		flag = objective_flag_edit.text.strip_edges()
	if flag == "":
		status_label.text = "Type or select a flag to inspect."
		return
	var refs := CampaignStore.flag_references(draft, flag)
	status_label.text = "Flag '%s' references: %s" % [flag, (", ".join(refs) if not refs.is_empty() else "(none)")]


func _remove_flag() -> void:
	capture_draft()
	var result := CampaignStore.remove_flag_definition(draft, flag_edit.text.strip_edges())
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


# ------------------------------------------------------------ encounter edits

func _select_encounter(index: int) -> void:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_encounter(index), "switch encounter")
		return
	_selected_encounter_id = String(encounter_option.get_item_metadata(index))
	_refresh_encounters()
	_refresh_triggers()


func _new_encounter() -> void:
	capture_draft()
	var template_id := String(encounter_template_option.get_item_metadata(encounter_template_option.selected)) if encounter_template_option.selected >= 0 else "room_7x5"
	var result := CampaignStore.add_encounter(draft, template_id)
	if bool(result.get("ok", false)):
		_selected_encounter_id = String(result.get("id", ""))
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _rename_encounter() -> void:
	if _selected_encounter_id == "":
		status_label.text = "Select an encounter first."
		return
	capture_draft()
	var new_id := encounter_id_edit.text.strip_edges()
	var result := CampaignStore.rename_encounter(draft, _selected_encounter_id, new_id)
	if bool(result.get("ok", false)):
		_selected_encounter_id = new_id
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _confirm_delete_encounter() -> void:
	if _selected_encounter_id == "":
		status_label.text = "Select an encounter first."
		return
	var encounter_id := _selected_encounter_id
	var refs := CampaignStore.encounter_references(draft, encounter_id)
	if not refs.is_empty():
		status_label.text = "Cannot delete encounter '%s'; still referenced by %s." % [encounter_id, ", ".join(refs)]
		return
	main.open_modal("Delete encounter", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(
			"Delete encounter '%s'? No trigger or dialogue references it." % encounter_id,
			true,
			14
		))
		var confirm := Button.new()
		confirm.text = "Delete encounter"
		confirm.custom_minimum_size = Vector2(0, 40)
		confirm.pressed.connect(func() -> void:
			main.close_modal()
			capture_draft()
			var result := CampaignStore.delete_encounter(draft, encounter_id)
			if bool(result.get("ok", false)):
				_selected_encounter_id = ""
				_mark_dirty()
				_refresh_all()
			status_label.text = String(result.get("message", ""))
		)
		box.add_child(confirm)
		var cancel := Button.new()
		cancel.text = "Keep editing"
		cancel.custom_minimum_size = Vector2(0, 40)
		cancel.pressed.connect(main.close_modal)
		box.add_child(cancel)
		return box
	, 620, 280)


func _apply_encounter() -> bool:
	if _selected_encounter_id == "":
		status_label.text = "Select an encounter first."
		return false
	capture_draft()
	var result := CampaignStore.set_encounter_fields(
		draft, _selected_encounter_id, encounter_name_edit.text, int(encounter_xp_spin.value), encounter_intro_edit.text
	)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
		status_label.text = String(result.get("message", ""))
		return true
	status_label.text = String(result.get("message", ""))
	return false


func _apply_layout() -> void:
	if _selected_encounter_id == "":
		status_label.text = "Select an encounter first."
		return
	capture_draft()
	var template_id := String(encounter_template_option.get_item_metadata(encounter_template_option.selected)) if encounter_template_option.selected >= 0 else ""
	var result := CampaignStore.set_encounter_template(draft, _selected_encounter_id, template_id)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _add_monster() -> void:
	if _selected_encounter_id == "":
		status_label.text = "Select an encounter first."
		return
	capture_draft()
	var monster_id := String(encounter_monster_option.get_item_metadata(encounter_monster_option.selected)) if encounter_monster_option.selected >= 0 else ""
	var result := CampaignStore.add_encounter_monster(draft, _selected_encounter_id, monster_id)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _remove_last_monster() -> void:
	if _selected_encounter_id == "":
		status_label.text = "Select an encounter first."
		return
	capture_draft()
	var monsters: Array = Array(CampaignStore.encounter_by_id(draft, _selected_encounter_id).get("monsters", []))
	var result := CampaignStore.remove_encounter_monster(draft, _selected_encounter_id, monsters.size() - 1)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _select_victory_flag(index: int) -> void:
	victory_flag_edit.text = String(victory_flag_option.get_item_metadata(index))


func _select_choice_flag(index: int) -> void:
	choice_effect_edit.text = String(choice_flag_option.get_item_metadata(index))


func _apply_victory() -> bool:
	if _selected_encounter_id == "":
		status_label.text = "Select an encounter first."
		return false
	capture_draft()
	var quest_id := String(victory_quest_option.get_item_metadata(victory_quest_option.selected)) if victory_quest_option.selected >= 0 else ""
	var flag := victory_flag_edit.text.strip_edges()
	var detail := ""
	if flag == "" and quest_id != "":
		flag = CampaignStore.first_objective_flag(draft, quest_id)
		if flag != "":
			detail = " Victory flag defaulted to the quest's first objective flag '%s'." % flag
	var result := CampaignStore.set_encounter_victory(draft, _selected_encounter_id, flag, victory_narration_edit.text, quest_id)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
		status_label.text = String(result.get("message", "")) + detail
		return true
	status_label.text = String(result.get("message", "")) + detail
	return false


# -------------------------------------------------------------- trigger edits

func _select_trigger(index: int) -> void:
	if not pending_form_keys().is_empty():
		_guard_pending(func() -> void: _select_trigger(index), "switch trigger")
		return
	_selected_trigger_id = String(trigger_option.get_item_metadata(index))
	var trigger := CampaignStore.find_trigger(draft, _area_id(), _selected_trigger_id)
	trigger_guard_edit.text = String(trigger.get("requires_flag_not", ""))
	var narration := ""
	for raw_effect in Array(trigger.get("effects", [])):
		if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "narration":
			narration = String(Dictionary(raw_effect).get("text", ""))
	trigger_narration_edit.text = narration


func _place_trigger() -> void:
	capture_draft()
	if selected_cell.x < 0:
		status_label.text = "Select a floor cell on the map first."
		return
	if _selected_encounter_id == "":
		status_label.text = "Create or select an encounter first."
		return
	var guard := trigger_guard_edit.text.strip_edges()
	if guard == "":
		for raw_effect in Array(CampaignStore.encounter_by_id(draft, _selected_encounter_id).get("victory_effects", [])):
			if raw_effect is Dictionary and String(Dictionary(raw_effect).get("type", "")) == "set_flag":
				guard = String(Dictionary(raw_effect).get("flag", ""))
				break
	var result := CampaignStore.add_encounter_trigger(
		draft, _area_id(), selected_cell, _selected_encounter_id, guard, trigger_narration_edit.text
	)
	if bool(result.get("ok", false)):
		_selected_trigger_id = String(result.get("id", ""))
		trigger_guard_edit.text = guard
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))


func _update_trigger() -> bool:
	if _selected_trigger_id == "":
		status_label.text = "Select a trigger first."
		return false
	capture_draft()
	var result := CampaignStore.update_encounter_trigger(
		draft, _area_id(), _selected_trigger_id, _selected_encounter_id, trigger_guard_edit.text, trigger_narration_edit.text
	)
	if bool(result.get("ok", false)):
		_mark_dirty()
		_refresh_all()
		status_label.text = String(result.get("message", ""))
		return true
	status_label.text = String(result.get("message", ""))
	return false


func _remove_trigger() -> void:
	if _selected_trigger_id == "":
		status_label.text = "Select a trigger first."
		return
	capture_draft()
	var result := CampaignStore.remove_encounter_trigger(draft, _area_id(), _selected_trigger_id)
	if bool(result.get("ok", false)):
		_selected_trigger_id = ""
		_mark_dirty()
		_refresh_all()
	status_label.text = String(result.get("message", ""))
