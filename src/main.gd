extends Control

## Application shell: screen routing and modal presentation.

var current_screen: Control = null
var modal: Control = null
## The control that opened the active modal, so closing returns focus there.
var modal_return_focus: Control = null
## The scrolling body of the active modal, the target of PageUp/PageDown and the
## arrows. Null while no modal is open.
var modal_scroll: ScrollContainer = null
var modal_builder: Callable
var modal_title := ""
## Optional strip above a modal's scrolling body for a fact that must stay
## visible while the panel is used (currently the read-only Settings notice).
var modal_notice := ""
## The modal size a caller asked for at 100 % text, kept so `refresh_modal()`
## re-applies the same request instead of resetting every modal to 760x540.
var modal_base_size := Vector2(760, 540)
var awaiting_rebind := ""
var party_selection: Array[String] = []
var party_error: Label
## The Begin control of the party screen, so the declared range can make it
## unavailable instead of waiting for a press.
var party_start_button: Button
var trip_scenario := "success"
var cleave_scenario := "cleave"
var probe_scenario := ""
var probe_size := Vector2i(1280, 720)
var probe_text_scale := 0.0
var capture_dir := ""
var creator_draft: Dictionary = {}
var creator_dirty := false
var creator_probe_failures := 0
var _creator_probe_finished := false
var creator_focus := ""
var layout_scenario := "screen"

## Keyboard scrolling of a modal body. PageUp/PageDown move by 90 % of the
## visible page, so a sliver of the previous text stays on screen as context.
## Up/Down move by two rendered text lines: the body is prose, and two lines read
## like one paragraph step. The line height comes from the theme's default font at
## its current size, which ThemeBuilder derives from the text scale, so the step
## grows at 160 % instead of crawling. One press moves once; holding a key does
## not repeat (the same rule every other modal key follows).
const MODAL_PAGE_STEP := 0.9
const MODAL_LINE_STEP := 2

## Exit status for a command line the application cannot act on. 1 already means
## "ran, and a validation or probe check failed"; 2 means "the invocation itself
## was wrong", so a CI step can tell the two apart.
const UNKNOWN_ARG_EXIT_CODE := 2

## Application options that are complete on their own. These are read from
## `OS.get_cmdline_user_args()`, i.e. only text after Godot's `--` separator, so
## no engine option can appear here and none is ever rejected by this list.
## Keep it in step with the dispatch in `_ready()` and docs/SETUP.md.
const APP_FLAGS: Array[String] = [
	"--campaign-list-probe",
	"--cleave-probe",
	"--concentration-probe",
	"--creator-acceptance-probe",
	"--creator-combat-probe",
	"--creator-combat-reload-probe",
	"--creator-encounter-click-probe",
	"--creator-interaction-probe",
	"--creator-probe",
	"--creator-story-probe",
	"--creator-ui-probe",
	"--demo",
	"--demo-campaigns",
	"--demo-cleave",
	"--demo-combat",
	"--demo-combat-expertise",
	"--demo-concentration",
	"--demo-creator",
	"--demo-creator-diagnostics",
	"--demo-creator-interaction",
	"--demo-creator-pending",
	"--demo-defeat-qa",
	"--demo-dialogue",
	"--demo-inspect",
	"--demo-silence",
	"--demo-integration",
	"--demo-nonlethal",
	"--demo-party",
	"--demo-power-attack",
	"--demo-ranged",
	"--demo-shield",
	"--demo-town-square",
	"--demo-town-square-mira",
	"--demo-trip",
	"--demo-turn-undead",
	"--demo-turn-undead-rest",
	"--demo-turn-undead-save",
	"--demo-unarmed",
	"--demo-victory-qa",
	"--demo-weapons",
	"--diagnostic-navigation-probe",
	"--encounter-end-probe",
	"--inspect-probe",
	"--integration-probe",
	"--intro-click",
	"--intro-layout-probe",
	"--layout-probe",
	"--list-campaigns",
	"--nonlethal-probe",
	"--package-diagnostics-probe",
	"--party-layout-probe",
	"--party-limits-probe",
	"--pending-edit-probe",
	"--quest-log-probe",
	"--ranged-probe",
	"--save-compat-probe",
	"--save-compat-ui-probe",
	"--settings-notice-probe",
	"--shield-probe",
	"--training-probe",
	"--trip-probe",
	"--unarmed-probe",
	"--validate-campaigns",
	"--validate-diagnostics",
	"--weapon-probe",
]

## Application options written as `--name=value`; the value is required.
const APP_VALUE_OPTIONS: Array[String] = [
	"--campaign",
	"--campaign-probe",
	"--capture",
	"--capture-dir",
	"--cleave-scenario",
	"--creator-focus",
	"--layout-scenario",
	"--probe-size",
	"--probe-text-scale",
	"--text-scale",
	"--trip-scenario",
	"--trip-shots",
]


## "" when every application argument is a supported option, otherwise one
## actionable message naming the offenders. An unknown option is refused instead
## of falling through to the interactive game: a typo in a headless CI step used
## to start the game and look like a hang rather than an error.
##
## Bare text without a leading `-` is ignored here, exactly as the dispatch in
## `_ready()` has always ignored it.
static func application_arg_error(args: PackedStringArray) -> String:
	var unknown: Array[String] = []
	for arg in args:
		if not arg.begins_with("-"):
			continue
		if APP_FLAGS.has(arg) or _is_value_option(arg):
			continue
		unknown.append(arg)
	if unknown.is_empty():
		return ""
	var lines: Array[String] = [
		"Unknown application option%s:" % ("" if unknown.size() == 1 else "s"),
	]
	for arg in unknown:
		lines.append("  " + arg)
		var suggestions := _option_suggestions(arg)
		if not suggestions.is_empty():
			lines.append("    did you mean: " + ", ".join(PackedStringArray(suggestions)))
	lines.append(
		"Nothing was started (exit status %d). Application options follow Godot's `--` separator."
		% UNKNOWN_ARG_EXIT_CODE
	)
	lines.append(
		"Supported options are listed in docs/SETUP.md. Content checks: "
		+ "--list-campaigns, --validate-campaigns, --validate-diagnostics."
	)
	return "\n".join(PackedStringArray(lines))


## `--name=<value>`, with a non-empty value: `--probe-size=` alone would silently
## use the default, which is the kind of quiet misconfiguration this guard exists
## to prevent.
static func _is_value_option(arg: String) -> bool:
	for option in APP_VALUE_OPTIONS:
		if arg.begins_with(option + "="):
			return arg.length() > option.length() + 1
	return false


## Closest supported options by the first word of the name, so a mistyped
## command suggests what the caller probably meant. Capped at four.
static func _option_suggestions(option: String) -> Array[String]:
	var matches: Array[String] = []
	var body := option.trim_prefix("-")
	if body == "":
		return matches
	var head: String = body.split("-")[0]
	if head.length() < 3:
		return matches
	for candidate in APP_FLAGS + APP_VALUE_OPTIONS:
		if candidate.trim_prefix("--").begins_with(head) and candidate != option:
			matches.append(candidate)
		if matches.size() == 4:
			break
	return matches


func _ready() -> void:
	# Supported minimum window: below this the fixed combat/exploration layouts are
	# not a supported target (Godot would clamp them anyway).
	get_window().min_size = Vector2i(1280, 720)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeBuilder.build(16)
	# Focus moves without our Tab handler too (a click, a control grabbing focus
	# itself, a refresh), so the modal follows the focus owner from the viewport.
	get_viewport().gui_focus_changed.connect(_on_modal_focus_changed)
	Game.mode_changed.connect(_on_mode_changed)
	Game.state_changed.connect(_on_state_changed)
	Game.combat_finished.connect(_on_combat_finished)
	_show_menu()
	# Developer/QA launch harness. It is not a player-facing feature; it exists
	# so the slice can be launched directly into a screen for smoke testing.
	var args := OS.get_cmdline_user_args()
	var argument_error := application_arg_error(args)
	if argument_error != "":
		print(argument_error)
		get_tree().quit(UNKNOWN_ARG_EXIT_CODE)
		return
	# The scenario must be known before the demo dispatch below selects a variant.
	for arg in args:
		if arg.begins_with("--trip-scenario="):
			trip_scenario = arg.substr("--trip-scenario=".length())
		if arg.begins_with("--cleave-scenario="):
			cleave_scenario = arg.substr("--cleave-scenario=".length())
		if arg.begins_with("--probe-size="):
			var parts := arg.substr("--probe-size=".length()).split("x")
			if parts.size() == 2:
				probe_size = Vector2i(int(parts[0]), int(parts[1]))
		if arg.begins_with("--probe-text-scale="):
			probe_text_scale = float(arg.substr("--probe-text-scale=".length()))
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.substr("--capture-dir=".length())
		if arg.begins_with("--text-scale="):
			Game.settings["text_scale"] = clampf(float(arg.substr("--text-scale=".length())), 0.8, 1.6)
		if arg.begins_with("--creator-focus="):
			creator_focus = arg.substr("--creator-focus=".length())
		if arg.begins_with("--layout-scenario="):
			layout_scenario = arg.substr("--layout-scenario=".length())
	theme = ThemeBuilder.build(16)
	for arg in args:
		if arg.begins_with("--campaign="):
			var selected_campaign := arg.substr("--campaign=".length())
			var campaign_result := Game.load_campaign(selected_campaign)
			if not bool(campaign_result.get("ok", false)):
				print("CAMPAIGN LOAD FAILED: %s" % String(campaign_result.get("message", "")))
	if "--demo" in args:
		_start_demo("explore")
	elif "--demo-dialogue" in args:
		_start_demo("dialogue")
	elif "--demo-silence" in args:
		_start_demo("silence")
	elif "--demo-combat" in args:
		_start_demo("combat")
	elif "--demo-power-attack" in args:
		_start_demo("power_attack")
	elif "--demo-combat-expertise" in args:
		_start_demo("combat_expertise")
	elif "--demo-town-square" in args:
		_start_demo("town_square")
	elif "--demo-town-square-mira" in args:
		_start_demo("town_square", ["kaelen", "aldric", "ysolde", "mira"])
	elif "--demo-turn-undead" in args:
		_start_demo("turn_undead")
	elif "--demo-turn-undead-save" in args:
		_start_demo("turn_undead_save")
	elif "--demo-turn-undead-rest" in args:
		_start_demo("turn_undead_rest")
	elif "--demo-trip" in args:
		_start_demo("trip")
	elif "--demo-cleave" in args:
		_start_demo("cleave")
	elif "--demo-inspect" in args:
		_start_demo("inspect")
	elif "--demo-ranged" in args:
		_start_demo("ranged")
	elif "--demo-concentration" in args:
		_start_demo("concentration")
	elif "--demo-integration" in args:
		_start_demo("integration")
	elif "--demo-weapons" in args:
		_start_demo("weapons")
	elif "--demo-shield" in args:
		_start_demo("shield")
	elif "--demo-unarmed" in args:
		_start_demo("unarmed")
	elif "--demo-nonlethal" in args:
		_start_demo("nonlethal")
	elif "--demo-victory-qa" in args:
		_start_demo("victory_qa")
	elif "--demo-defeat-qa" in args:
		_start_demo("defeat_qa")
	if "--demo-creator-diagnostics" in args:
		_start_creator_diagnostics_demo()
	if "--demo-creator-pending" in args:
		_start_creator_pending_demo()
	if "--demo-campaigns" in args:
		_show_campaign_select()
	if "--demo-creator" in args:
		_show_creator_draft(CampaignStore.make_draft("Creator Preview", "creator_preview"))
	if "--demo-creator-interaction" in args:
		_show_creator_draft(_demo_creator_interaction_draft())
	if current_screen is CampaignCreator and creator_focus != "":
		match creator_focus:
			"dialogue": current_screen.call_deferred("focus_dialogue_section")
			"choices": current_screen.call_deferred("focus_choices_section")
			"quests": current_screen.call_deferred("focus_quest_section")
			"encounters": current_screen.call_deferred("focus_encounter_section")
			_: current_screen.call_deferred("focus_interaction_section")
	if "--demo-party" in args:
		party_selection.clear()
		_show_party_select()
	for arg in args:
		if arg.begins_with("--trip-scenario="):
			trip_scenario = arg.substr("--trip-scenario=".length())
		if arg.begins_with("--capture="):
			_capture_viewport(arg.substr("--capture=".length()))
	if "--trip-probe" in args:
		_trip_probe(trip_scenario)
	if "--cleave-probe" in args:
		_cleave_probe(cleave_scenario)
	if "--inspect-probe" in args:
		_inspect_probe()
	if "--ranged-probe" in args:
		_ranged_probe()
	if "--concentration-probe" in args:
		_concentration_probe()
	if "--integration-probe" in args:
		_integration_probe()
	if "--weapon-probe" in args:
		_weapon_probe()
	if "--shield-probe" in args:
		_shield_probe()
	if "--unarmed-probe" in args:
		_unarmed_probe()
	if "--nonlethal-probe" in args:
		_nonlethal_probe()
	if "--encounter-end-probe" in args:
		_encounter_end_probe()
	if "--package-diagnostics-probe" in args:
		_package_diagnostics_probe()
	if "--save-compat-probe" in args:
		_save_compat_probe()
	if "--save-compat-ui-probe" in args:
		_save_compat_ui_probe()
	if "--settings-notice-probe" in args:
		_settings_notice_probe()
	if "--campaign-list-probe" in args:
		_campaign_list_probe()
	if "--party-layout-probe" in args:
		_party_layout_probe()
	if "--party-limits-probe" in args:
		_party_limits_probe()
	if "--intro-layout-probe" in args:
		_intro_layout_probe()
	if "--training-probe" in args:
		_training_probe()
	if "--list-campaigns" in args:
		_list_campaigns_and_quit()
	if "--validate-campaigns" in args:
		_validate_campaigns_and_quit()
	if "--validate-diagnostics" in args:
		_validate_diagnostics_and_quit()
	if "--quest-log-probe" in args:
		_quest_log_probe()
	for arg in args:
		if arg.begins_with("--campaign-probe="):
			_campaign_probe(arg.substr("--campaign-probe=".length()))
	if "--creator-probe" in args:
		_creator_probe()
	if "--creator-ui-probe" in args:
		_creator_ui_probe()
	if "--creator-interaction-probe" in args:
		_creator_interaction_ui_probe()
	if "--creator-story-probe" in args:
		_creator_story_probe()
	if "--creator-combat-probe" in args:
		_creator_combat_probe()
	if "--creator-combat-reload-probe" in args:
		_creator_combat_reload_probe()
	if "--creator-encounter-click-probe" in args:
		_creator_encounter_click_probe()
	if "--creator-acceptance-probe" in args:
		_creator_acceptance_probe()
	if "--diagnostic-navigation-probe" in args:
		_diagnostic_navigation_probe()
	if "--pending-edit-probe" in args:
		_pending_edit_probe()
	if "--layout-probe" in args:
		_layout_probe(layout_scenario)


## Asserted creator-to-diagnostic navigation and recovery path. Reuses the real
## screen, selectors and scroll controls; exits nonzero on any failed check.
func _diagnostic_navigation_probe() -> void:
	var failures := 0
	var probe_id := "diagnostic_probe"
	CampaignStore.delete_user_campaign(probe_id)
	var created := CampaignStore.create("Diagnostic Probe", probe_id)
	if not bool(created.get("ok", false)):
		print("DIAGNOSTIC PROBE FAIL create: %s" % String(created.get("message", "")))
		get_tree().quit(1)
		return
	var draft: Dictionary = Dictionary(CampaignStore.load_package(probe_id).get("draft", {}))
	draft["entry"] = {"area": "area_01", "pos": [0, 0], "facing": 0}
	var area: Dictionary = Dictionary(Array(draft["areas"])[0])
	area["npcs"] = [
		{"id": "guide_a", "name": "Guide A", "look": "", "pos": [2, 2], "dialogue": "guide_talk"},
		{"id": "guide_b", "name": "Guide B", "look": "", "pos": [3, 2], "dialogue": "missing_talk"},
	]
	Array(draft["areas"])[0] = area
	CampaignStore.add_dialogue(draft, "guide_talk", "Guide A")
	var screen := CampaignCreator.new()
	add_child(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	screen.title_edit.text = "Probe unsaved title"
	screen.dirty = true
	screen._validate()
	for i in 2:
		await get_tree().process_frame
	failures += _probe_bool(screen.diagnostics_panel.visible, "results panel visible")
	var npc_diag := {}
	var entry_diag := {}
	for raw in screen.diagnostics:
		if String(Dictionary(raw).get("code", "")) == "npc.dialogue.missing" and String(Dictionary(raw).get("entity_id", "")) == "guide_b":
			npc_diag = Dictionary(raw)
		if String(Dictionary(raw).get("code", "")) == "entry.pos.wall":
			entry_diag = Dictionary(raw)
	failures += _probe_bool(not npc_diag.is_empty(), "NPC diagnostic identifies guide_b")
	failures += _probe_bool(not entry_diag.is_empty(), "entry diagnostic is structured")
	if not npc_diag.is_empty():
		await screen._navigate_diagnostic(npc_diag)
		failures += _probe_bool(screen._selected_npc_id == "guide_b", "diagnostic selected the right similar NPC")
		failures += _probe_bool(screen.last_focused_control == screen.npc_dialogue_option, "diagnostic focused the dialogue field")
		failures += _probe_bool(screen.title_edit.text == "Probe unsaved title" and screen.dirty, "navigation preserved dirty form state")
		Array(screen.draft["areas"][0]["npcs"]).remove_at(1)
		await screen._navigate_diagnostic(npc_diag)
		failures += _probe_bool(screen.status_label.text.contains("no longer exists"), "stale diagnostic asks for revalidation")
	if not entry_diag.is_empty():
		await screen._navigate_diagnostic(entry_diag)
		failures += _probe_bool(screen.last_focused_control == screen.set_entry_button, "entry diagnostic reached Set entry here")
	# Correct every seeded error, revalidate, then save through the creator.
	screen.draft["entry"] = {"area": "area_01", "pos": [4, 4], "facing": 0}
	var fixed_area: Dictionary = Dictionary(Array(screen.draft["areas"])[0])
	fixed_area["npcs"] = [{"id": "guide_a", "name": "Guide A", "look": "", "pos": [2, 2], "dialogue": "guide_talk"}]
	Array(screen.draft["areas"])[0] = fixed_area
	screen._validate()
	failures += _probe_bool(bool(Game.validate_campaign_draft(screen.draft).get("ok", false)), "corrected draft revalidates")
	failures += _probe_bool(screen.diagnostics_panel.visible == false, "corrected results panel clears")
	failures += _probe_bool(screen._save(), "corrected draft saves through the creator")
	print("DIAGNOSTIC PROBE %s (%d failed checks)" % ["PASS" if failures == 0 else "FAIL", failures])
	screen.queue_free()
	CampaignStore.delete_user_campaign(probe_id)
	get_tree().quit(0 if failures == 0 else 1)


## Asserted pending-form policy path. It uses the real creator controls, the
## real diagnostic navigation and the real modal buttons, then exits nonzero
## on any failed check. It is intentionally separate from the source tests.
func _pending_edit_probe() -> void:
	var failures := 0
	var probe_id := "pending_probe"
	CampaignStore.delete_user_campaign(probe_id)
	var created := CampaignStore.create("Pending Probe", probe_id)
	failures += _probe_bool(bool(created.get("ok", false)), "probe campaign created")
	if failures > 0:
		get_tree().quit(1)
		return
	var draft: Dictionary = Dictionary(CampaignStore.load_package(probe_id).get("draft", {}))
	draft["entry"] = {"area": "area_01", "pos": [0, 0], "facing": 0}
	var area: Dictionary = Dictionary(Array(draft["areas"])[0])
	area["npcs"] = [
		{"id": "guide_a", "name": "Guide A", "look": "", "pos": [2, 2], "dialogue": "guide_talk"},
		{"id": "guide_b", "name": "Guide B", "look": "", "pos": [3, 2], "dialogue": "missing_talk"},
	]
	Array(draft["areas"])[0] = area
	CampaignStore.add_dialogue(draft, "guide_talk", "Guide A")
	var screen := CampaignCreator.new()
	add_child(screen)
	screen.setup(self, draft)
	for i in 3:
		await get_tree().process_frame
	screen._validate()
	var npc_diag := {}
	for raw in screen.diagnostics:
		if String(Dictionary(raw).get("code", "")) == "npc.dialogue.missing" and String(Dictionary(raw).get("entity_id", "")) == "guide_b":
			npc_diag = Dictionary(raw)
	failures += _probe_bool(not npc_diag.is_empty(), "a diagnostic targets guide_b")
	var applied_name := String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", ""))
	screen.npc_name_edit.text = "Pending Guide"
	screen.last_focused_control = screen.npc_name_edit
	failures += _probe_bool(screen.pending_form_keys().has("npc"), "typing creates pending form state")
	failures += _probe_bool(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")) == applied_name, "typing does not change the applied draft")
	await screen._navigate_diagnostic(npc_diag)
	failures += _probe_bool(modal != null, "diagnostic navigation opens the pending prompt")
	var cancel := _find_button(modal, "Cancel")
	failures += _probe_bool(cancel != null, "the prompt offers Cancel")
	if cancel != null:
		cancel.pressed.emit()
		await get_tree().process_frame
	failures += _probe_bool(screen._selected_npc_id == "guide_a", "Cancel keeps the selection")
	failures += _probe_bool(screen.npc_name_edit.text == "Pending Guide", "Cancel keeps the text")
	failures += _probe_bool(screen.last_focused_control == screen.npc_name_edit, "Cancel returns focus")
	await screen._navigate_diagnostic(npc_diag)
	var apply := _find_button(modal, "Apply changes and continue")
	failures += _probe_bool(apply != null, "the prompt offers Apply")
	if apply != null:
		apply.pressed.emit()
		await get_tree().process_frame
	failures += _probe_bool(screen._selected_npc_id == "guide_b", "Apply continues to the intended result")
	failures += _probe_bool(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")) == "Pending Guide", "Apply validates and changes the draft")
	failures += _probe_bool(screen.pending_form_keys().is_empty(), "Apply clears pending state")
	screen._select_npc(0)
	screen.npc_name_edit.text = ""
	failures += _probe_bool(not screen.apply_pending_forms(), "failed Apply is refused")
	failures += _probe_bool(screen.npc_name_edit.text == "", "failed Apply keeps the entered text")
	failures += _probe_bool(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")) == "Pending Guide", "failed Apply keeps the draft")
	await screen._navigate_diagnostic(npc_diag)
	cancel = _find_button(modal, "Cancel")
	if cancel != null:
		cancel.pressed.emit()
		await get_tree().process_frame
	failures += _probe_bool(screen._selected_npc_id == "guide_a", "no navigation after failed Apply")
	screen.npc_name_edit.text = "Discard this text"
	screen.last_focused_control = screen.npc_name_edit
	await screen._navigate_diagnostic(npc_diag)
	var discard := _find_button(modal, "Discard these form edits")
	failures += _probe_bool(discard != null, "the prompt offers explicit Discard")
	if discard != null:
		discard.pressed.emit()
		await get_tree().process_frame
	failures += _probe_bool(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")) == "Pending Guide", "Discard leaves the applied draft unchanged")
	failures += _probe_bool(screen._selected_npc_id == "guide_b", "Discard continues only after being chosen")
	screen._select_npc(0)
	screen.npc_name_edit.text = "Unsaved form"
	var manifest_path := CampaignStore.package_dir(probe_id).path_join("campaign.json")
	var before := FileAccess.get_file_as_string(manifest_path)
	failures += _probe_bool(not screen._save(), "Save refuses pending form text")
	failures += _probe_bool(FileAccess.get_file_as_string(manifest_path) == before, "Save does not write while pending")
	cancel = _find_button(modal, "Cancel")
	if cancel != null:
		cancel.pressed.emit()
		await get_tree().process_frame
	screen._playtest()
	failures += _probe_bool(not Game.playtest_mode, "Playtest refuses pending form text")
	cancel = _find_button(modal, "Cancel")
	if cancel != null:
		cancel.pressed.emit()
		await get_tree().process_frame
	screen.discard_pending_forms()
	failures += _probe_bool(screen._select_npc_by_id("guide_b"), "unresolved NPC can be opened")
	failures += _probe_bool(screen._selected_meta(screen.npc_dialogue_option) == "missing_talk", "unresolved stored dialogue stays visible")
	failures += _probe_bool(screen.npc_dialogue_option.get_item_text(screen.npc_dialogue_option.selected).contains("Unresolved reference"), "unresolved option names the stored id")
	failures += _probe_bool(screen.pending_form_keys().is_empty(), "opening an unresolved entity is not an edit")
	screen.npc_name_edit.text = "Unresolved Kept"
	failures += _probe_bool(screen.apply_pending_forms(), "unrelated Apply preserves the unresolved reference")
	failures += _probe_bool(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_b").get("dialogue", "")) == "missing_talk", "unrelated Apply did not repair the reference")
	screen._select_npc(0)
	var atomic_before: Dictionary = screen.draft.duplicate(true)
	screen.npc_name_edit.text = "Atomic Attempt"
	screen.speaker_edit.text = "   "
	failures += _probe_bool(screen.pending_form_keys().has("npc") and screen.pending_form_keys().has("dialogue"), "two forms are pending")
	failures += _probe_bool(not screen.apply_pending_forms(), "later invalid form refuses the whole Apply")
	failures += _probe_bool(screen.draft == atomic_before, "failed multi-form Apply leaves the complete draft unchanged")
	failures += _probe_bool(screen.npc_name_edit.text == "Atomic Attempt" and screen.speaker_edit.text == "   ", "failed multi-form Apply keeps both entered texts")
	failures += _probe_bool(screen._selected_npc_id == "guide_a" and screen._selected_dialogue_id == "guide_talk", "failed multi-form Apply does not advance selection")
	failures += _probe_bool(screen.status_label.text.contains("cannot be empty"), "failed multi-form Apply keeps the explanation")
	failures += _probe_bool(FileAccess.get_file_as_string(manifest_path) == before, "failed multi-form Apply writes no campaign file")
	print("PENDING EDIT PROBE %s (%d failed checks)" % ["PASS" if failures == 0 else "FAIL", failures])
	screen.queue_free()
	CampaignStore.delete_user_campaign(probe_id)
	get_tree().quit(0 if failures == 0 else 1)


func _probe_bool(value: bool, label: String) -> int:
	print("  %s %s" % ["PASS" if value else "FAIL", label])
	return 0 if value else 1


# ---------------------------------------------------------------- campaigns

## Developer pipeline: list the installed packages without starting a game.
func _list_campaigns_and_quit() -> void:
	for id in Game.campaigns.order:
		var manifest: Dictionary = Game.campaigns.get_campaign(String(id))
		print("CAMPAIGN %s | %s | format=%s version=%s" % [
			String(id),
			String(manifest.get("title", "")),
			manifest.get("format_version", "?"),
			manifest.get("version", "?"),
		])
	get_tree().quit(0)


## Developer pipeline: validate every installed campaign and fail the process if
## any package is invalid. No game window or GUT run is required.
func _validate_campaigns_and_quit() -> void:
	var failures := 0
	for id in Game.campaigns.order:
		var result := Game.validate_campaign(String(id))
		var errors: Array = result.get("errors", [])
		if bool(result.get("ok", false)):
			print("CAMPAIGN VALID %s" % id)
		else:
			failures += 1
			print("CAMPAIGN INVALID %s (%d errors)" % [id, errors.size()])
			for error in errors:
				print("  - %s" % String(error))
	# A stored package that discovery could not read is not an installed campaign,
	# so the per-campaign loop above never sees it. Report it here and fail: the
	# author needs the reason, and a silently missing campaign is not a pass.
	for registry_error in Game.campaigns.errors:
		failures += 1
		print("CAMPAIGN PACKAGE ERROR: %s" % String(registry_error))
	print("CAMPAIGN VALIDATION %s" % ("PASS" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)


## Developer pipeline: structured diagnostics as JSON, with the same failure
## exit code as --validate-campaigns. Legacy text output stays untouched.
func _validate_diagnostics_and_quit() -> void:
	var failures := 0
	var all: Array = []
	for id in Game.campaigns.order:
		var result := Game.diagnose_campaign(String(id))
		var diagnostics: Array = result.get("diagnostics", [])
		all.append_array(diagnostics)
		if ContentDiagnostics.has_errors(diagnostics):
			failures += 1
		print("CAMPAIGN DIAGNOSTICS %s | %s" % [id, ContentDiagnostics.summary(diagnostics)])
	print("CAMPAIGN_DIAGNOSTICS_JSON " + JSON.stringify(all))
	print("CAMPAIGN DIAGNOSTICS %s" % ("PASS" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)


## Developer pipeline: start one campaign through the ordinary new-game path and
## assert its entry state. Exits nonzero on any failed check.
func _campaign_probe(campaign_id: String) -> void:
	var loaded := Game.load_campaign(campaign_id)
	if not bool(loaded.get("ok", false)):
		print("CAMPAIGN PROBE FAIL load %s: %s" % [campaign_id, String(loaded.get("message", ""))])
		get_tree().quit(1)
		return
	var manifest: Dictionary = Game.campaign
	var entry: Dictionary = manifest.get("entry", {})
	var started := Game.new_game([], 987654, campaign_id)
	if not bool(started.get("ok", false)):
		print("CAMPAIGN PROBE FAIL start %s: %s" % [campaign_id, String(started.get("message", ""))])
		get_tree().quit(1)
		return
	var entry_pos: Array = entry.get("pos", [])
	var checks: Array = [
		["campaign id", Game.campaign_id == campaign_id],
		["content valid", Game.content.errors.is_empty()],
		["mode explore", Game.mode == "explore"],
		["training mode off", not Game.training_mode],
		["entry area", Game.area_id == String(entry.get("area", ""))],
		["entry position", entry_pos.size() == 2 and Game.position == Vector2i(int(entry_pos[0]), int(entry_pos[1]))],
		["start quest active", Game.quests.is_active(String(manifest.get("start_quest", "")))],
	]
	var failures := 0
	for check in checks:
		var ok := bool(check[1])
		print("CAMPAIGN PROBE %s %s" % ["PASS" if ok else "FAIL", String(check[0])])
		if not ok:
			failures += 1
	print("CAMPAIGN PROBE %s campaign=%s" % ["PASS" if failures == 0 else "FAIL", campaign_id])
	get_tree().quit(0 if failures == 0 else 1)


## Quest bookkeeping probe: a completed quest must not be announced again by a
## later flag synchronization. Runs the same transition through QuestLog and the
## live campaign path; no content or save is changed.
func _quest_log_probe() -> void:
	probe_failures.clear()
	var log := QuestLog.new()
	log.setup({"watch": {
		"id": "watch",
		"title": "The Watch",
		"objectives": [
			{"id": "a", "text": "First.", "flag": "a"},
			{"id": "b", "text": "Second.", "flag": "b"},
		],
	}})
	log.start("watch")
	var flags := {"a": true, "b": true}
	var first := log.sync_flags(flags)
	var second := log.sync_flags(flags)
	_probe_check(first.has("Quest complete: The Watch"), "first sync completes the quest")
	_probe_check(second.is_empty(), "second sync reports no transition")
	_probe_check(log.status("watch") == "complete", "quest remains complete")

	var loaded := Game.load_campaign("ravenloft_demo")
	if not bool(loaded.get("ok", false)):
		print("QUEST LOG PROBE FAIL load: %s" % String(loaded.get("message", "")))
		get_tree().quit(1)
		return
	Game.new_game(["kaelen"], 987654, "ravenloft_demo")
	for flag in ["met_miruna", "found_clapper", "warden_resolved", "bell_rung"]:
		Game.flags[flag] = true
	Game.apply_effects([], "quest-log-probe")
	var first_count := 0
	for line in Game.log_lines:
		if String(line) == "Quest complete: The Drowned Bell":
			first_count += 1
	Game.apply_effects([], "quest-log-probe")
	var second_count := 0
	for line in Game.log_lines:
		if String(line) == "Quest complete: The Drowned Bell":
			second_count += 1
	_probe_check(first_count == 1, "campaign completion is logged once")
	_probe_check(second_count == 1, "later flag synchronization does not relog completion")
	_probe_check(Game.quests.is_complete("drowned_bell"), "campaign quest remains complete")
	print("QUEST LOG PROBE %s" % ("PASS" if probe_failures.is_empty() else "FAIL"))
	get_tree().quit(0 if probe_failures.is_empty() else 1)


## End-to-end creator probe: create, add area, link, set entry, validate, save,
## playtest travel, prove saves are blocked, and prove discovery after reload.
func _creator_probe() -> void:
	creator_probe_failures = 0
	var campaign_id := "probe_campaign"
	CampaignStore.delete_user_campaign(campaign_id)
	var created := CampaignStore.create("Probe Campaign", campaign_id)
	_creator_probe_check(bool(created.get("ok", false)), "campaign created: " + String(created.get("message", "")))
	_creator_probe_check(
		DirAccess.dir_exists_absolute(CampaignStore.package_dir(campaign_id)),
		"package directory exists"
	)
	Game.refresh_campaigns()
	_creator_probe_check(Game.campaigns.has(campaign_id), "campaign discovered without a registry edit")
	var loaded := CampaignStore.load_package(campaign_id)
	_creator_probe_check(bool(loaded.get("ok", false)), "package reopens from disk")
	var draft: Dictionary = Dictionary(loaded.get("draft", {}))
	_creator_probe_check(Array(draft.get("areas", [])).size() == 1, "template starts with one area")
	CampaignStore.add_area(draft, "Second Area")
	_creator_probe_check(Array(draft.get("areas", [])).size() == 2, "second area added")
	var link := CampaignStore.add_transition(draft, "area_01", Vector2i(4, 4), "area_02")
	_creator_probe_check(bool(link.get("ok", false)), "areas linked: " + String(link.get("message", "")))
	var entry := CampaignStore.set_entry(draft, "area_01", Vector2i(4, 5), 1)
	_creator_probe_check(bool(entry.get("ok", false)), "entry point set")
	var validation := Game.validate_campaign_draft(draft)
	_creator_probe_check(
		bool(validation.get("ok", false)),
		"draft validates: " + "\n".join(Array(validation.get("errors", [])))
	)
	var saved := CampaignStore.write_package(draft)
	_creator_probe_check(bool(saved.get("ok", false)), "draft saved to user://campaigns")
	Game.refresh_campaigns()
	var play_loaded := Game.load_campaign(campaign_id)
	_creator_probe_check(bool(play_loaded.get("ok", false)), "playtest loads through the ordinary loader")
	Game.playtest_mode = true
	var started := Game.new_game([], 1234, campaign_id)
	_creator_probe_check(bool(started.get("ok", false)), "playtest new game starts")
	_creator_probe_check(
		Game.position == Vector2i(4, 5) and Game.facing == 1,
		"playtest starts at the authored entry and facing"
	)
	var moved := Game.travel_to("area_02", Vector2i(4, 4), 0)
	_creator_probe_check(bool(moved.get("ok", false)), "playtest travels through the authored passage")
	_creator_probe_check(Game.area_id == "area_02", "playtest arrives in the second area")
	var overwrite := Game.save_game("slot1")
	_creator_probe_check(not bool(overwrite.get("ok", false)), "playtest refuses to write a campaign save")
	_creator_probe_check(not SaveSystem.exists("slot1", campaign_id), "no playtest save reaches disk")
	Game.abandon_playtest()
	_creator_probe_check(not Game.playtest_mode, "playtest mode ends cleanly")
	var relaunched := CampaignDB.new()
	relaunched.load_registry()
	_creator_probe_check(relaunched.has(campaign_id), "campaign survives a registry reload (relaunch)")
	CampaignStore.delete_user_campaign(campaign_id)
	Game.refresh_campaigns()
	var still_listed := false
	for manifest in CampaignStore.list_user_campaigns():
		if String(Dictionary(manifest).get("id", "")) == campaign_id:
			still_listed = true
	_creator_probe_check(not still_listed, "probe campaign cleaned up")
	Game.load_campaign("ravenloft_demo")
	print("CREATOR PROBE %s campaign=%s" % ["PASS" if creator_probe_failures == 0 else "FAIL", campaign_id])
	get_tree().quit(0 if creator_probe_failures == 0 else 1)


## QA-only creator fixture with an authored speaker, a looping introduction, a
## Search check and a flag-gated follow-up. It is never written to disk.
func _demo_creator_interaction_draft() -> Dictionary:
	var draft := CampaignStore.make_draft("Creator Preview — Interaction", "creator_preview")
	var talk := "keeper_talk"
	CampaignStore.add_dialogue(draft, talk, "Ivy, the Lantern Keeper")
	for node_name in ["lore", "success", "failure", "recall"]:
		var added := CampaignStore.add_dialogue_node(draft, talk)
		CampaignStore.rename_dialogue_node(draft, talk, String(added.get("id", "")), node_name)
	CampaignStore.set_dialogue_node(
		draft, talk, "lore", "\"My family kept the lamp before me. Now it is only me.\"",
		"Ivy, the Lantern Keeper", "start", "", ""
	)
	CampaignStore.set_dialogue_node(
		draft, talk, "success", "\"The ledger names the keepers who did not stay.\"",
		"Ivy, the Lantern Keeper", "start", "The ledger names three keepers; only Ivy's is not struck through.", "watcher_studied"
	)
	CampaignStore.set_dialogue_node(
		draft, talk, "failure", "\"You are asking the wrong questions for someone who wants to keep a light.\"",
		"Ivy, the Lantern Keeper", "start", "", ""
	)
	CampaignStore.set_dialogue_node(
		draft, talk, "recall", "\"You found the names. Now you know why I stay.\"",
		"Ivy, the Lantern Keeper", "", "", ""
	)
	CampaignStore.set_dialogue_node(
		draft, talk, "start", "(EXAMPLE DIALOGUE) Ivy turns the dead wick between her fingers.",
		"Ivy, the Lantern Keeper", "", "", ""
	)
	for raw_fields in [
		{"text": "Ask about the watch.", "next": "lore", "check": {}},
		{
			"text": "Search the counter. [Search DC 12]",
			"check": {"skill": "search", "dc": 12, "actor": "best", "success": "success", "failure": "failure"},
			"guard_flag": "watcher_studied",
		},
		{"text": "Ask what you found.", "next": "recall", "check": {}, "require_flag": "watcher_studied"},
		{"text": "Leave her to the light.", "next": "", "check": {}},
	]:
		var added_choice := CampaignStore.add_dialogue_choice(draft, talk, "start")
		var fields: Dictionary = raw_fields
		CampaignStore.update_dialogue_choice(draft, talk, "start", int(added_choice.get("index", -1)), fields)
	CampaignStore.set_quest_fields(
		draft, "creator_preview_quest", "The Cold Beacon", "(EXAMPLE) Light the beacon in the chapel.",
		"creator_preview_quest", ""
	)
	CampaignStore.update_objective(
		draft, "creator_preview_quest", "look_around", "light_beacon", "Light the beacon.", "beacon_lit"
	)
	CampaignStore.add_flag_definition(draft, "beacon_lit", "The chapel beacon is lit.")
	var encounter := CampaignStore.add_encounter(draft)
	var encounter_id := String(encounter.get("id", ""))
	CampaignStore.set_encounter_fields(draft, encounter_id, "Chapel Shade", 150, "(EXAMPLE) Something cold turns toward the light.")
	CampaignStore.set_encounter_victory(draft, encounter_id, "beacon_lit", "(EXAMPLE) The beacon catches.", "creator_preview_quest")
	CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(3, 3), encounter_id, "beacon_lit", "(EXAMPLE) A shape unfolds from the cold.")
	CampaignStore.place_npc(
		draft, "area_01", Vector2i(4, 3), "keeper_npc", "Ivy, the Lantern Keeper",
		"(EXAMPLE NPC) A weathered keeper waits beside a cold lamp.", talk
	)
	return draft

## Prints the final verdict and exits with a code the QA scripts can trust.
## Every early return in a probe goes through this, so a failed precondition
## never leaves the window running until the timeout kills it.
func _creator_probe_exit(campaign_id: String) -> void:
	_creator_probe_finished = true
	CampaignStore.delete_user_campaign(campaign_id)
	SaveSystem.delete_save_everywhere("slot1")
	print("CREATOR ACCEPTANCE PROBE %s campaign=%s failures=%d" % [
		"PASS" if creator_probe_failures == 0 else "FAIL",
		campaign_id,
		creator_probe_failures,
	])
	get_tree().quit(0 if creator_probe_failures == 0 else 1)


## A runtime error aborts the probe coroutine before its final exit call. This
## still ends the run - and fails it - instead of hanging until the harness
## timeout, which used to make a broken probe look like a slow one.
func _creator_probe_watchdog(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if _creator_probe_finished:
		return
	print("CREATOR ACCEPTANCE PROBE FAIL campaign=probe_acceptance reason=watchdog after %.0fs" % seconds)
	get_tree().quit(1)


func _creator_probe_check(ok: bool, label: String, detail := "") -> void:
	var suffix := "" if ok or detail == "" else " | " + detail
	print("CREATOR PROBE %s %s%s" % ["PASS" if ok else "FAIL", label, suffix])
	if not ok:
		creator_probe_failures += 1


## Asserts the creator's own controls and the playtest pause/return loop. This
## drives the real screens and button callbacks; it is not a headless backend
## check and it exits nonzero on any failed condition.
func _creator_ui_probe() -> void:
	creator_probe_failures = 0
	var campaign_id := "probe_ui_campaign"
	CampaignStore.delete_user_campaign(campaign_id)
	var screen := CampaignCreator.new()
	_set_screen(screen)
	screen.setup(self, CampaignStore.make_draft("UI Probe", campaign_id))
	await get_tree().process_frame
	_creator_probe_check(screen.area_list.get_child_count() == 1, "creator lists the template area")
	_creator_probe_check(screen.map_grid.get_child_count() == 81, "creator draws a 9x9 map")
	_creator_probe_check(screen.title_edit.text == "UI Probe", "title editor shows the draft")
	screen._add_area()
	await get_tree().process_frame
	_creator_probe_check(screen.area_list.get_child_count() == 2, "Add area adds a second area button")
	_creator_probe_check(String(screen._current_area().get("id", "")) == "area_02", "new area is selected")
	screen._select_area(0)
	screen.selected_cell = Vector2i(4, 3)
	screen._set_entry()
	_creator_probe_check(String(screen.status_label.text).contains("Entry set"), "Set entry reports success")
	await get_tree().process_frame
	_creator_probe_check(
		Dictionary(screen.draft.get("entry", {})).get("pos", []) == [4, 3],
		"entry point was captured from the selected cell"
	)
	screen.selected_cell = Vector2i(4, 4)
	screen.target_option.select(0)
	screen._add_transition()
	_creator_probe_check(String(screen.status_label.text).contains("Passage added"), "passage callback reports success")
	screen._validate()
	_creator_probe_check(String(screen.status_label.text).contains("Draft validates"), "Validate draft reports a valid draft")
	screen._save()
	_creator_probe_check(not screen.dirty, "Save draft clears the dirty flag")
	_creator_probe_check(
		DirAccess.dir_exists_absolute(CampaignStore.package_dir(campaign_id)),
		"Save draft writes the user package"
	)
	Game.refresh_campaigns()
	screen._playtest()
	await get_tree().process_frame
	_creator_probe_check(Game.playtest_mode, "Playtest enters playtest mode")
	_creator_probe_check(current_screen is ExplorationScreen, "Playtest routes to exploration")
	var travelled := Game.travel_to("area_02", Vector2i(4, 4), 0)
	_creator_probe_check(bool(travelled.get("ok", false)), "playtest travels to the linked area")
	_open_pause()
	var back := _find_button(modal, "Return to campaign creator")
	_creator_probe_check(back != null, "pause menu offers a return to the creator")
	if back != null:
		back.pressed.emit()
	await get_tree().process_frame
	_creator_probe_check(not Game.playtest_mode, "returning ends playtest mode")
	_creator_probe_check(current_screen is CampaignCreator, "returning restores the creator")
	_creator_probe_check(not creator_draft.is_empty(), "creator keeps its draft on return")
	if current_screen is CampaignCreator:
		_creator_probe_check(current_screen.area_list.get_child_count() == 2, "returned creator still has both areas")
	Game.refresh_campaigns()
	_show_campaign_select()
	await get_tree().process_frame
	_creator_probe_check(_find_button(current_screen, "Edit") != null, "campaign list offers Edit for the user campaign")
	_open_creator(campaign_id)
	await get_tree().process_frame
	_creator_probe_check(current_screen is CampaignCreator, "Edit opens the existing user campaign")
	CampaignStore.delete_user_campaign(campaign_id)
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")
	print("CREATOR UI PROBE %s campaign=%s" % ["PASS" if creator_probe_failures == 0 else "FAIL", campaign_id])
	get_tree().quit(0 if creator_probe_failures == 0 else 1)


## Drives the real NPC/dialogue controls: place a speaker, author a looping
## conversation with a Search check, a persistent success flag and a gated later
## response, then save, playtest, talk and return with the draft intact.
func _creator_interaction_ui_probe() -> void:
	creator_probe_failures = 0
	var campaign_id := "probe_interaction_campaign"
	CampaignStore.delete_user_campaign(campaign_id)
	SaveSystem.delete_save_everywhere("slot1")
	var screen := CampaignCreator.new()
	_set_screen(screen)
	screen.setup(self, CampaignStore.make_draft("Interaction Probe", campaign_id))
	await get_tree().process_frame
	screen.selected_cell = Vector2i(4, 3)
	screen._place_npc()
	await get_tree().process_frame
	_creator_probe_check(Array(screen._current_area().get("npcs", [])).size() == 1, "Place NPC adds one speaker")
	_creator_probe_check(screen.dialogue_option.item_count == 1, "placing an NPC creates its conversation")
	_creator_probe_check(String(screen.npc_id_edit.text) == "npc_01", "the creator generates a stable local NPC id")
	screen.npc_name_edit.text = "The Keeper"
	screen.npc_look_edit.text = "(USER CAMPAIGN) A keeper waits beside a cold lamp."
	screen._apply_npc()
	var stored_npc := CampaignStore.find_npc(screen.draft, "area_01", "npc_01")
	_creator_probe_check(String(stored_npc.get("name", "")) == "The Keeper", "Apply NPC stores the display name")
	_creator_probe_check(String(stored_npc.get("dialogue", "")) == "npc_01_talk", "the speaker keeps its dialogue link")

	screen.node_text_edit.text = "The keeper watches the lamp, not you."
	screen._apply_node()
	_creator_probe_check(String(screen.status_label.text).contains("Updated node"), "Apply node stores the introduction")
	for pair in [["lore", "The keeper remembers every watch.", "start"], ["success", "You find the keeper's ledger.", "start"], ["failure", "The keeper closes the ledger.", "start"], ["recall", "You ask about the names.", ""]]:
		screen._add_node()
		screen.node_id_edit.text = String(pair[0])
		screen._rename_node()
		screen.node_text_edit.text = String(pair[1])
		screen._select_by_meta(screen.node_next_option, String(pair[2]))
		if String(pair[0]) == "success":
			screen.node_narration_edit.text = "The ledger names the last three keepers."
			screen.node_flag_edit.text = "watcher_studied"
		screen._apply_node()
	_creator_probe_check(String(screen.node_option.get_item_metadata(screen.node_option.selected)) == "recall", "the last authored node is selected")
	_creator_probe_check(screen.node_option.item_count == 5, "four extra nodes join the introduction")

	var start_index := -1
	for i in screen.node_option.item_count:
		if String(screen.node_option.get_item_metadata(i)) == "start":
			start_index = i
	_creator_probe_check(start_index >= 0, "the start node is listed")
	if start_index >= 0:
		screen._select_node(start_index)
	# Response 1: a plain loop into lore.
	screen._add_choice()
	screen.choice_text_edit.text = "Ask about the watch."
	screen._select_by_meta(screen.choice_dest_option, "lore")
	screen._apply_choice()
	# Response 2: the Search check, hidden once the flag is set.
	screen._add_choice()
	screen.choice_text_edit.text = "Search the counter. [Search DC 12]"
	screen.choice_check_toggle.button_pressed = true
	screen._select_by_meta(screen.choice_skill_option, "search")
	screen.choice_dc_spin.value = 12
	screen._select_by_meta(screen.choice_actor_option, "kaelen")
	screen._select_by_meta(screen.choice_success_option, "success")
	screen._select_by_meta(screen.choice_failure_option, "failure")
	screen.choice_guard_edit.text = "watcher_studied"
	screen._apply_choice()
	# Response 3: only available after the success flag exists.
	screen._add_choice()
	screen.choice_text_edit.text = "Ask what you found."
	screen.choice_check_toggle.button_pressed = false
	screen._select_by_meta(screen.choice_dest_option, "recall")
	screen.choice_require_edit.text = "watcher_studied"
	screen._apply_choice()
	# Response 4: a clean exit.
	screen._add_choice()
	screen.choice_text_edit.text = "Leave."
	screen._select_by_meta(screen.choice_dest_option, "")
	screen._apply_choice()
	var start_node: Dictionary = Dictionary(Dictionary(CampaignStore.dialogue_by_id(screen.draft, "npc_01_talk").get("nodes", {}))["start"])
	_creator_probe_check(Array(start_node.get("choices", [])).size() == 4, "four authored responses are stored")
	screen._validate()
	_creator_probe_check(String(screen.status_label.text).contains("Draft validates"), "the authored interaction validates")
	_creator_probe_check(screen._save(), "the interaction saves")
	_creator_probe_check(not screen.dirty, "saving clears the dirty flag")
	var reopened := CampaignStore.load_package(campaign_id)
	_creator_probe_check(bool(reopened.get("ok", false)), "the authored package reopens")
	var reopened_draft: Dictionary = Dictionary(reopened.get("draft", {}))
	_creator_probe_check(Dictionary(reopened_draft.get("dialogues", {})).has("npc_01_talk"), "the conversation survives on disk")
	_creator_probe_check(Array(CampaignStore.find_npc(reopened_draft, "area_01", "npc_01").keys()).size() > 0, "the speaker survives on disk")

	screen._playtest()
	await get_tree().process_frame
	_creator_probe_check(Game.playtest_mode, "playtest starts in playtest mode")
	var talked := Game.interact()
	_creator_probe_check(bool(talked.get("ok", false)), "the authored NPC can be talked to from the entry cell")
	_creator_probe_check(Game.mode == "dialogue", "talking opens the authored conversation")
	var choices := Game.dialogue_choices()
	var check_choice := -1
	for choice in choices:
		if int(choice.get("index", -1)) == 1:
			check_choice = int(choice.get("index", -1))
	_creator_probe_check(check_choice == 1, "the skill-check response is offered")
	_return_to_creator()
	await get_tree().process_frame
	_creator_probe_check(current_screen is CampaignCreator, "returning restores the creator")
	if current_screen is CampaignCreator:
		_creator_probe_check(current_screen.npc_option.item_count == 1, "the returned creator still shows the placement")
		_creator_probe_check(current_screen.dialogue_option.item_count == 1, "the returned creator still shows the conversation")
	# An actual normal-play save must enable Continue/Load, while playtest left none.
	Game.playtest_mode = false
	var ordinary_load := Game.load_campaign(campaign_id)
	_creator_probe_check(bool(ordinary_load.get("ok", false)), "ordinary play reloads the authored package")
	Game.new_game([], 123)
	var ordinary_save := Game.save_game("slot1")
	_creator_probe_check(bool(ordinary_save.get("ok", false)), "ordinary play writes a campaign save")
	_show_menu()
	await get_tree().process_frame
	var continue_button := _find_button(current_screen, "Continue from latest save")
	var load_game_button := _find_button(current_screen, "Load game")
	_creator_probe_check(continue_button != null and not continue_button.disabled, "Continue is enabled with a real save")
	_creator_probe_check(load_game_button != null and not load_game_button.disabled, "Load game is enabled with a real save")
	Game.refresh_campaigns()
	_show_campaign_select()
	await get_tree().process_frame
	var continue_latest := _find_enabled_button(current_screen, "Continue latest")
	var load_slot := _find_enabled_button(current_screen, "Load slot")
	_creator_probe_check(continue_latest != null, "the authored campaign card enables Continue latest")
	_creator_probe_check(load_slot != null, "the authored campaign card enables Load slot")
	CampaignStore.delete_user_campaign(campaign_id)
	SaveSystem.delete_save_everywhere("slot1")
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")
	print("CREATOR INTERACTION PROBE %s campaign=%s" % ["PASS" if creator_probe_failures == 0 else "FAIL", campaign_id])
	get_tree().quit(0 if creator_probe_failures == 0 else 1)


## Asserts the complete authored loop without a window: quest, travel, placed
## encounter, victory once, changed NPC response, completion, playtest isolation
## and ordinary save/load. This probe ends combat through the engine's own
## finish path, so it verifies postcombat integration only; it is NOT a combat
## playthrough. The genuine attack-driven run is --creator-combat-probe.
func _creator_story_probe() -> void:
	creator_probe_failures = 0
	var campaign_id := "probe_story_campaign"
	var other_id := "probe_story_other"
	CampaignStore.delete_user_campaign(campaign_id)
	CampaignStore.delete_user_campaign(other_id)
	SaveSystem.delete_save_everywhere("slot1")
	var created := CampaignStore.create("Story Probe", campaign_id)
	_creator_probe_check(bool(created.get("ok", false)), "authored campaign created")
	var draft: Dictionary = Dictionary(CampaignStore.load_package(campaign_id).get("draft", {}))
	var quest_id := campaign_id + "_quest"
	var quest_set := CampaignStore.set_quest_fields(
		draft, quest_id, "The Cold Beacon", "(USER CAMPAIGN) Light the chapel beacon.", quest_id, quest_id
	)
	_creator_probe_check(bool(quest_set.get("ok", false)), "quest start and completion configured")
	var objective := CampaignStore.update_objective(
		draft, quest_id, "look_around", "light_beacon", "Light the beacon in the east chapel.", "beacon_lit"
	)
	_creator_probe_check(bool(objective.get("ok", false)), "objective bound to an explicit flag")
	_creator_probe_check(bool(CampaignStore.add_flag_definition(draft, "beacon_lit", "The beacon is lit.").get("ok", false)), "flag declared deliberately")
	var chapel := CampaignStore.add_area(draft, "East Chapel")
	var chapel_id := String(chapel.get("id", ""))
	_creator_probe_check(bool(CampaignStore.add_transition(draft, "area_01", Vector2i(4, 5), chapel_id).get("ok", false)), "passage to the chapel")
	_creator_probe_check(bool(CampaignStore.add_transition(draft, chapel_id, Vector2i(4, 5), "area_01").get("ok", false)), "return passage")
	var encounter := CampaignStore.add_encounter(draft)
	var encounter_id := String(encounter.get("id", ""))
	_creator_probe_check(bool(encounter.get("ok", false)), "campaign-local encounter created")
	_creator_probe_check(bool(CampaignStore.set_encounter_fields(draft, encounter_id, "Chapel Shade", 150, "(USER CAMPAIGN) Something cold turns toward the light.").get("ok", false)), "encounter fields bounded")
	var victory := CampaignStore.set_encounter_victory(draft, encounter_id, "beacon_lit", "(USER CAMPAIGN) The beacon catches and holds.", quest_id)
	_creator_probe_check(bool(victory.get("ok", false)), "victory connected to the objective flag")
	var trigger := CampaignStore.add_encounter_trigger(
		draft, chapel_id, Vector2i(4, 3), encounter_id, "beacon_lit", "(USER CAMPAIGN) A shape unfolds from the cold."
	)
	_creator_probe_check(bool(trigger.get("ok", false)), "trigger placed on a legal cell")
	_creator_probe_check(not bool(CampaignStore.add_encounter_trigger(draft, chapel_id, Vector2i(0, 0), encounter_id, "", "").get("ok", false)), "a wall cell refuses a trigger")
	var talk_result := CampaignStore.add_dialogue(draft, "keeper_talk", "The Keeper")
	_creator_probe_check(bool(talk_result.get("ok", false)), "conversation created")
	CampaignStore.set_dialogue_node(draft, "keeper_talk", "start", "\"The beacon has been out for three nights.\"", "The Keeper", "", "", "")
	var accept := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	var accepted := CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", int(accept.get("index", 0)), {
		"text": "I will light it.", "next": "", "quest_id": quest_id,
	})
	_creator_probe_check(bool(accepted.get("ok", false)), "response starts the quest from a discoverable list")
	var changed := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	var changed_result := CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", int(changed.get("index", 0)), {
		"text": "The beacon is lit.", "next": "", "require_flag": "beacon_lit",
	})
	_creator_probe_check(bool(changed_result.get("ok", false)), "later response gated by the objective flag")
	var leave := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", int(leave.get("index", 0)), {"text": "Leave.", "next": ""})
	var placed := CampaignStore.place_npc(draft, "area_01", Vector2i(4, 3), "keeper_npc", "The Keeper", "(USER CAMPAIGN) A keeper waits.", "keeper_talk")
	_creator_probe_check(bool(placed.get("ok", false)), "NPC placed in the starting area")
	var saved := CampaignStore.write_package(draft)
	_creator_probe_check(bool(saved.get("ok", false)), "authored save succeeds: " + String(saved.get("message", "")))
	var quests_path := CampaignStore.package_dir(campaign_id).path_join("quests.json")
	var saved_quests := FileAccess.get_file_as_string(quests_path)
	# Change the in-memory draft only: the playtest must use it, the saved package must not.
	draft["quests"][quest_id]["title"] = "The Cold Beacon (unsaved edit)"
	var staged := CampaignStore.stage_playtest(draft)
	_creator_probe_check(bool(staged.get("ok", false)), "playtest snapshot staged")
	var loaded := Game.load_campaign_snapshot(Dictionary(staged.get("manifest", {})))
	_creator_probe_check(bool(loaded.get("ok", false)), "playtest snapshot loads: " + String(loaded.get("message", "")))
	_creator_probe_check(String(Game.content.get_quest(quest_id).get("title", "")) == "The Cold Beacon (unsaved edit)", "playtest runs the in-memory draft")
	_creator_probe_check(FileAccess.get_file_as_string(quests_path) == saved_quests, "playtest never rewrites the saved package")
	Game.playtest_root = String(staged.get("root", ""))
	Game.playtest_mode = true
	_creator_probe_check(bool(Game.new_game([], 4242, campaign_id).get("ok", false)), "playtest new game starts")
	_creator_probe_check(bool(Game.interact().get("ok", false)), "keeper conversation opens")
	var accepted_choice := Game.dialogue_choose(0)
	_creator_probe_check(bool(accepted_choice.get("ok", false)), "accepting the task succeeds")
	_creator_probe_check(Game.quests.is_active(quest_id), "the quest starts from dialogue")
	Game.facing = 2
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the authored passage is usable")
	_creator_probe_check(Game.area_id == chapel_id, "travel reaches the second area")
	Game.facing = 0
	Game.move_forward()
	_creator_probe_check(Game.mode == "combat", "the placed trigger starts its encounter")
	Game.encounter.finish("victory")
	_creator_probe_check(bool(Game.flags.get("beacon_lit", false)), "victory sets the objective flag")
	_creator_probe_check(Game.quests.is_complete(quest_id), "the configured objective completes the quest")
	_creator_probe_check(bool(Game.flags.get("victory_shown", false)), "campaign victory fired because this quest is the completion quest")
	var xp_after_victory := int(Game.party[0].xp)
	Game.move_back()
	Game.move_forward()
	_creator_probe_check(Game.mode == "explore", "cleared trigger does not start combat again")
	_creator_probe_check(int(Game.party[0].xp) == xp_after_victory, "cleared trigger grants no extra XP")
	Game.move_back()
	Game.facing = 2
	_creator_probe_check(bool(Game.interact().get("ok", false)), "return passage works")
	_creator_probe_check(Game.area_id == "area_01", "the party returns to the keeper")
	Game.facing = 0
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the keeper can be spoken to again")
	var changed_available := false
	for choice in Game.dialogue_choices():
		if String(choice.get("text", "")).contains("beacon is lit") and bool(choice.get("available", false)):
			changed_available = true
	_creator_probe_check(changed_available, "the keeper's response changes after victory")
	_creator_probe_check(not bool(Game.save_game("slot1").get("ok", false)), "playtest cannot write a campaign save")
	Game.abandon_playtest()
	_creator_probe_check(not DirAccess.dir_exists_absolute(CampaignStore.PLAYTEST_ROOT.path_join(campaign_id)), "playtest staging is removed")
	_creator_probe_check(FileAccess.get_file_as_string(quests_path) == saved_quests, "saved package survived the playtest")
	# Ordinary play: the saved package, a real save, reload and no repeated encounter.
	Game.playtest_mode = false
	_creator_probe_check(bool(Game.load_campaign(campaign_id).get("ok", false)), "ordinary play reloads the saved package")
	_creator_probe_check(String(Game.content.get_quest(quest_id).get("title", "")) == "The Cold Beacon", "ordinary play uses the saved title")
	_creator_probe_check(bool(Game.new_game([], 5150, campaign_id).get("ok", false)), "ordinary new game starts")
	Game.interact()
	Game.dialogue_choose(0)
	Game.facing = 2
	Game.interact()
	Game.facing = 0
	Game.move_forward()
	_creator_probe_check(Game.mode == "combat", "ordinary play starts the authored encounter")
	Game.encounter.finish("victory")
	_creator_probe_check(bool(Game.flags.get("beacon_lit", false)), "ordinary victory sets the flag")
	_creator_probe_check(bool(Game.save_game("slot1").get("ok", false)), "ordinary play saves progress")
	_creator_probe_check(bool(Game.new_game([], 6161, campaign_id).get("ok", false)), "a fresh run clears progress")
	_creator_probe_check(not bool(Game.flags.get("beacon_lit", false)), "new run starts without the flag")
	_creator_probe_check(bool(Game.load_game("slot1").get("ok", false)), "saved progress loads")
	_creator_probe_check(bool(Game.flags.get("beacon_lit", false)), "saved flag survives reload")
	_creator_probe_check(bool(Game.flags.get("trigger_trigger_01", false)), "the trigger stays spent after reload")
	_creator_probe_check(Game.quests.is_complete(quest_id), "saved quest completion survives reload")
	var other := CampaignStore.create("Story Other", other_id)
	_creator_probe_check(bool(other.get("ok", false)), "second campaign created for isolation")
	_creator_probe_check(bool(Game.load_campaign(other_id).get("ok", false)), "second campaign loads")
	_creator_probe_check(bool(Game.new_game([], 7171, other_id).get("ok", false)), "second campaign starts")
	_creator_probe_check(not bool(Game.flags.get("beacon_lit", false)), "flags do not leak across campaigns")
	CampaignStore.delete_user_campaign(campaign_id)
	CampaignStore.delete_user_campaign(other_id)
	SaveSystem.delete_save_everywhere("slot1")
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")
	print("CREATOR STORY PROBE %s campaign=%s" % ["PASS" if creator_probe_failures == 0 else "FAIL", campaign_id])
	get_tree().quit(0 if creator_probe_failures == 0 else 1)


## ------------------------------------------------- creator combat acceptance
##
## Two processes, one authored scenario. Phase 1 creates the campaign through
## CampaignStore (the creator backend), reaches the trigger by ordinary
## exploration and wins using the real CombatScreen controls: the Attack button
## plus a click on the enemy's map cell, and End turn when the standard action is
## spent. It never calls Encounter.finish(), never edits hit points and never sets
## the victory flag itself. It then saves and quits.
##
## Phase 2 is a separate launch (a real relaunch against the same user:// data):
## it loads the campaign and the slot, checks the persisted result, walks over the
## trigger cell again and confirms no encounter, no XP and no second reward, then
## speaks to the NPC for the changed response.
const COMBAT_PROBE_STATE := "user://creator_combat_probe_state.json"


func _creator_combat_fixture(campaign_id: String) -> Dictionary:
	var created := CampaignStore.create("Combat Acceptance", campaign_id)
	_creator_probe_check(bool(created.get("ok", false)), "authored campaign created: " + String(created.get("message", "")))
	var draft: Dictionary = Dictionary(CampaignStore.load_package(campaign_id).get("draft", {}))
	var quest_id := campaign_id + "_quest"
	_creator_probe_check(
		bool(CampaignStore.set_quest_fields(
			draft, quest_id, "The Cold Beacon", "(USER CAMPAIGN) Light the chapel beacon.", quest_id, quest_id
		).get("ok", false)),
		"quest start and completion configured"
	)
	_creator_probe_check(
		bool(CampaignStore.update_objective(
			draft, quest_id, "look_around", "light_beacon", "Light the beacon in the east chapel.", "beacon_lit"
		).get("ok", false)),
		"objective bound to an explicit flag"
	)
	CampaignStore.add_flag_definition(draft, "beacon_lit", "The beacon is lit.")
	var chapel := CampaignStore.add_area(draft, "East Chapel")
	var chapel_id := String(chapel.get("id", ""))
	CampaignStore.add_transition(draft, "area_01", Vector2i(4, 5), chapel_id)
	CampaignStore.add_transition(draft, chapel_id, Vector2i(4, 5), "area_01")
	var encounter := CampaignStore.add_encounter(draft, "room_7x5")
	var encounter_id := String(encounter.get("id", ""))
	_creator_probe_check(bool(encounter.get("ok", false)), "campaign-local encounter created")
	CampaignStore.set_encounter_fields(
		draft, encounter_id, "Chapel Shade", 50, "(USER CAMPAIGN) Something cold turns toward the light."
	)
	# One shared zombie is the manageable, supported opposition for this check.
	_creator_probe_check(
		Array(CampaignStore.encounter_by_id(draft, encounter_id).get("monsters", [])).size() == 1,
		"the authored encounter starts with one monster"
	)
	CampaignStore.set_encounter_victory(draft, encounter_id, "beacon_lit", "(USER CAMPAIGN) The beacon catches and holds.", "")
	_creator_probe_check(
		bool(CampaignStore.add_encounter_trigger(
			draft, chapel_id, Vector2i(4, 3), encounter_id, "beacon_lit", "(USER CAMPAIGN) A shape unfolds from the cold."
		).get("ok", false)),
		"trigger placed on a legal chapel cell"
	)
	CampaignStore.add_dialogue(draft, "keeper_talk", "The Keeper")
	CampaignStore.set_dialogue_node(
		draft, "keeper_talk", "start", "\"The beacon has been out for three nights.\"", "The Keeper", "", "", ""
	)
	var accept := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", int(accept.get("index", 0)), {
		"text": "I will light it.", "next": "", "quest_id": quest_id,
	})
	var changed := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", int(changed.get("index", 0)), {
		"text": "The beacon is lit.", "next": "", "require_flag": "beacon_lit",
	})
	var leave := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", int(leave.get("index", 0)), {"text": "Leave.", "next": ""})
	_creator_probe_check(
		bool(CampaignStore.place_npc(
			draft, "area_01", Vector2i(4, 3), "keeper_npc", "The Keeper",
			"(USER CAMPAIGN) A keeper waits.", "keeper_talk"
		).get("ok", false)),
		"NPC placed beside the entry cell"
	)
	var saved := CampaignStore.write_package(draft)
	_creator_probe_check(bool(saved.get("ok", false)), "authored save succeeds: " + String(saved.get("message", "")))
	return {"quest_id": quest_id, "encounter_id": encounter_id, "chapel_id": chapel_id, "npc_id": "keeper_npc"}


## Best legal square from which the active character can strike `cell` with a
## 5-ft melee reach, chosen by actual path length. QA geometry only: the click
## that uses it still goes through the Move control and the map cell.
func _probe_melee_approach(cell: Vector2i, from: Vector2i, active_index: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_cost := 9999
	var occupied := Game.encounter.occupied_except(active_index)
	for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		var candidate: Vector2i = cell + dir
		if not Game.encounter.map.in_bounds(candidate) or Game.encounter.map.is_blocked(candidate) or occupied.has(candidate):
			continue
		var path := Game.encounter.map.find_path(from, candidate, occupied)
		if path.is_empty():
			continue
		if path.size() < best_cost:
			best_cost = path.size()
			best = candidate
	return best


## Drives the encounter through the shipped control tree: Move into reach, then
## Attack on the target cell, ending the turn when the standard action is spent.
## Returns the number of attack clicks that were followed up with a cell click.
func _probe_win_authored_encounter() -> int:
	var attacks := 0
	var guard := 0
	while guard < 400 and Game.mode == "combat" and Game.encounter != null:
		guard += 1
		if Game.encounter.finished:
			break
		if not Game.encounter.is_player_turn():
			var wait_end := _probe_button(current_screen.button_box, "End turn")
			if wait_end == null or wait_end.disabled:
				await get_tree().process_frame
				continue
			await _probe_click(wait_end, "End turn")
			continue
		var target: Character = null
		for entry in Game.encounter.combatants:
			var ch: Character = entry["char"]
			if int(entry["team"]) == Encounter.TEAM_ENEMY and not ch.has_condition("dead"):
				target = ch
				break
		if target == null:
			break
		var active := Game.encounter.active_character()
		var active_entry := Game.encounter.active_entry()
		var active_cell: Vector2i = active_entry.get("cell", Vector2i(-1, -1))
		var enemy_cell := Game.encounter.cell_of(target)
		# Standard 5-ft melee reach: close the distance first, exactly as a
		# player must, then attack from an adjacent square.
		if Game.encounter.map.distance_ft(active_cell, enemy_cell) > 5:
			var dest := _probe_melee_approach(enemy_cell, active_cell, int(active_entry.get("index", -1)))
			var move_button := _probe_button(current_screen.button_box, "Move")
			if dest.x >= 0 and move_button != null and not move_button.disabled:
				await _probe_click(move_button, "Move")
				await _probe_click_cell(current_screen, dest, "move toward target")
			if Game.mode != "combat" or Game.encounter == null:
				break
			active_cell = Game.encounter.cell_of(active)
			if Game.encounter.map.distance_ft(active_cell, enemy_cell) > 5:
				var approach_end := _probe_button(current_screen.button_box, "End turn")
				if approach_end != null and not approach_end.disabled:
					await _probe_click(approach_end, "End turn")
				continue
		var attack_button := _probe_button(current_screen.button_box, "Attack")
		if attack_button != null and not attack_button.disabled:
			await _probe_click(attack_button, "Attack")
			if Game.mode != "combat" or Game.encounter == null:
				break
			await _probe_click_cell(current_screen, Game.encounter.cell_of(target), "attack target")
			attacks += 1
		else:
			var end_button := _probe_button(current_screen.button_box, "End turn")
			if end_button == null or end_button.disabled:
				await get_tree().process_frame
				continue
			await _probe_click(end_button, "End turn")
	return attacks


func _creator_combat_probe() -> void:
	creator_probe_failures = 0
	probe_failures.clear()
	probe_scenario = "creator_combat"
	probe_started_ms = Time.get_ticks_msec()
	var campaign_id := "probe_combat_campaign"
	CampaignStore.delete_user_campaign(campaign_id)
	SaveSystem.delete_save_everywhere("slot1")
	var fixture := _creator_combat_fixture(campaign_id)
	var quest_id := String(fixture.get("quest_id", ""))
	Game.refresh_campaigns()
	_creator_probe_check(bool(Game.load_campaign(campaign_id).get("ok", false)), "ordinary play loads the authored package")
	# Disclosed deterministic seed: every roll in this run is reproducible.
	var seed_value := 90210
	_creator_probe_check(bool(Game.new_game([], seed_value, campaign_id).get("ok", false)), "new game starts (seed %d)" % seed_value)
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the keeper conversation opens from the entry cell")
	_creator_probe_check(bool(Game.dialogue_choose(0).get("ok", false)), "accepting the task starts the quest")
	_creator_probe_check(Game.quests.is_active(quest_id), "the quest is active before the encounter")
	Game.facing = 2
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the authored passage is usable")
	_creator_probe_check(Game.area_id == String(fixture.get("chapel_id", "")), "travel reaches the chapel")
	get_window().size = Vector2i(1280, 720)
	for i in 6:
		await get_tree().process_frame
	Game.facing = 0
	var stepped := Game.move_forward()
	_creator_probe_check(bool(stepped.get("ok", false)), "walking onto the trigger cell succeeds")
	_creator_probe_check(Game.mode == "combat", "the placed trigger starts its encounter through exploration")
	for i in 4:
		await get_tree().process_frame
	_creator_probe_check(current_screen is CombatScreen, "the combat screen is the live screen")
	var xp_before := int(Game.party[0].xp)
	var attacks := 0
	if current_screen is CombatScreen:
		attacks = await _probe_win_authored_encounter()
	_creator_probe_check(attacks > 0, "attacks resolved through the Attack button and target cell (%d)" % attacks)
	_creator_probe_check(Game.mode == "explore", "the encounter ends in victory through combat controls")
	_creator_probe_check(Game.last_combat_result == "victory", "the engine reports victory (not defeat or error)")
	_creator_probe_check(bool(Game.flags.get("beacon_lit", false)), "victory sets the authored flag")
	_creator_probe_check(Game.quests.is_complete(quest_id), "the objective flag completes the authored quest")
	var xp_after := int(Game.party[0].xp)
	_creator_probe_check(xp_after == xp_before + 50, "the authored encounter XP is granted once")
	_creator_probe_check(bool(Game.save_game("slot1").get("ok", false)), "ordinary play saves the result")
	var state := {
		"campaign_id": campaign_id,
		"quest_id": quest_id,
		"xp": xp_after,
		"seed": seed_value,
		"attacks": attacks,
	}
	var file := FileAccess.open(COMBAT_PROBE_STATE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(state))
		file.close()
	_creator_probe_check(file != null, "reload state written for the second launch")
	print("CREATOR COMBAT PROBE %s attacks=%d xp=%d" % ["PASS" if creator_probe_failures == 0 else "FAIL", attacks, xp_after])
	get_tree().quit(0 if creator_probe_failures == 0 else 1)


func _creator_combat_reload_probe() -> void:
	creator_probe_failures = 0
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(COMBAT_PROBE_STATE))
	if not parsed is Dictionary:
		print("CREATOR COMBAT RELOAD PROBE FAIL no phase-one state; run --creator-combat-probe first")
		get_tree().quit(1)
		return
	var state: Dictionary = parsed
	var campaign_id := String(state.get("campaign_id", ""))
	var quest_id := String(state.get("quest_id", ""))
	var saved_xp := int(state.get("xp", -1))
	Game.refresh_campaigns()
	_creator_probe_check(bool(Game.load_campaign(campaign_id).get("ok", false)), "relaunch discovers the authored campaign")
	_creator_probe_check(bool(Game.load_game("slot1").get("ok", false)), "relaunch loads the saved game")
	_creator_probe_check(Game.area_id == "area_02", "the save restores the chapel area")
	_creator_probe_check(bool(Game.flags.get("beacon_lit", false)), "the victory flag survives the relaunch")
	_creator_probe_check(bool(Game.flags.get("trigger_trigger_01", false)), "the trigger is still spent after reload")
	_creator_probe_check(Game.quests.is_complete(quest_id), "the completed quest survives the relaunch")
	_creator_probe_check(int(Game.party[0].xp) == saved_xp, "saved XP matches the victory award")
	# Walk off and back onto the trigger cell through ordinary exploration.
	Game.move_back()
	Game.move_forward()
	_creator_probe_check(Game.mode == "explore", "a cleared trigger does not restart combat after reload")
	_creator_probe_check(int(Game.party[0].xp) == saved_xp, "re-crossing the trigger grants no second reward")
	Game.move_back()
	Game.facing = 2
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the return passage still works")
	_creator_probe_check(Game.area_id == "area_01", "the party is back with the keeper")
	Game.facing = 0
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the keeper can be spoken to after reload")
	var changed_available := false
	for choice in Game.dialogue_choices():
		if String(choice.get("text", "")).contains("beacon is lit") and bool(choice.get("available", false)):
			changed_available = true
	_creator_probe_check(changed_available, "the changed NPC response survives the relaunch")
	CampaignStore.delete_user_campaign(campaign_id)
	SaveSystem.delete_save_everywhere("slot1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(COMBAT_PROBE_STATE))
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")
	print("CREATOR COMBAT RELOAD PROBE %s campaign=%s" % ["PASS" if creator_probe_failures == 0 else "FAIL", campaign_id])
	get_tree().quit(0 if creator_probe_failures == 0 else 1)


## Resolves the New encounter click question with geometry rather than belief:
## print where the control is before and after the creator's own focus scroll,
## then click its real on-screen centre through the viewport.
func _creator_encounter_click_probe() -> void:
	probe_failures.clear()
	probe_scenario = "creator_encounter_click"
	probe_started_ms = Time.get_ticks_msec()
	get_window().size = Vector2i(1280, 720)
	var screen := CampaignCreator.new()
	_set_screen(screen)
	screen.setup(self, _demo_creator_interaction_draft())
	for i in 8:
		await get_tree().process_frame
	var view := get_viewport().get_visible_rect()
	var before := _find_button(screen, "New encounter")
	print("CLICK PROBE before viewport=%s scroll=%d rect=%s enclosed=%s visible=%s disabled=%s" % [
		str(view.size), screen.scroll.scroll_vertical,
		str(before.get_global_rect()) if before != null else "none",
		str(view.encloses(before.get_global_rect())) if before != null else "none",
		str(before.is_visible_in_tree()) if before != null else "none",
		str(before.disabled) if before != null else "none",
	])
	await screen.focus_encounter_section()
	for i in 6:
		await get_tree().process_frame
	var after := _find_button(screen, "New encounter")
	print("CLICK PROBE after viewport=%s scroll=%d rect=%s enclosed=%s visible=%s disabled=%s" % [
		str(view.size), screen.scroll.scroll_vertical,
		str(after.get_global_rect()) if after != null else "none",
		str(view.encloses(after.get_global_rect())) if after != null else "none",
		str(after.is_visible_in_tree()) if after != null else "none",
		str(after.disabled) if after != null else "none",
	])
	_probe_check(after != null, "New encounter control exists")
	if after == null:
		_probe_finish(probe_scenario)
		return
	_probe_check(view.encloses(after.get_global_rect()), "the focus scroll brings New encounter on screen")
	var count_before := screen.encounter_option.item_count
	await _probe_click(after, "New encounter")
	for i in 4:
		await get_tree().process_frame
	_probe_check(screen.encounter_option.item_count == count_before + 1, "New encounter creates a second encounter")
	var selected := String(screen.encounter_option.get_item_metadata(screen.encounter_option.selected)) if screen.encounter_option.selected >= 0 else ""
	print("CLICK PROBE result count=%d selected=%s status=%s" % [screen.encounter_option.item_count, selected, screen.status_label.text])
	_probe_check(selected == "encounter_02", "the newly created encounter is selected in the picker")
	_probe_check(String(screen.status_label.text).contains("Created encounter"), "the creator reports the new encounter")
	_probe_finish(probe_scenario)


func _find_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	if root is Button and String(root.text) == text:
		return root
	for child in root.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


## Campaign cards are ordered; the first card may be a bundled campaign with no
## saves. Continue/Load assertions need the enabled instance for the user card.
func _find_enabled_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	for child in root.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and String(button.text) == text and not button.disabled:
			return button
	return null


# ---------------------------------------------------------------- QA trip probe
## QA-only (--trip-probe). It drives the real control tree with real viewport
## mouse input and captures each result. It never calls a combat action
## directly, so what is recorded is what a click does. Screenshots go to
## --trip-shots=<directory> (default user://trip_shots).
var probe_shots := "user://trip_shots"


## Automated creator acceptance exercise. It starts at the campaign list, uses
## the visible Create campaign dialog and the creator's own controls for every
## authoring step, then validates, saves, playtests, returns, reopens from disk
## and plays/saves normally. It is a model-driven UI script, not a human study.
func _creator_acceptance_probe() -> void:
	creator_probe_failures = 0
	_creator_probe_finished = false
	_creator_probe_watchdog(60.0)
	var campaign_id := "probe_acceptance"
	CampaignStore.delete_user_campaign(campaign_id)
	SaveSystem.delete_save_everywhere("slot1")
	Game.refresh_campaigns()
	_show_campaign_select()
	await get_tree().process_frame
	var create := _find_button(current_screen, "Create campaign")
	_creator_probe_check(create != null, "campaign list offers Create campaign")
	if create == null:
		_creator_probe_exit(campaign_id)
		return
	create.pressed.emit()
	await get_tree().process_frame
	var fields: Array = modal.find_children("*", "LineEdit", true, false) if modal != null else []
	_creator_probe_check(fields.size() >= 2, "Create campaign dialog shows title and id fields")
	if fields.size() < 2:
		_creator_probe_exit(campaign_id)
		return
	fields[0].text = "Acceptance Chapel"
	fields[1].text = campaign_id
	var create_edit := _find_button(modal, "Create and edit")
	_creator_probe_check(create_edit != null, "Create and edit is available")
	if create_edit == null:
		_creator_probe_exit(campaign_id)
		return
	create_edit.pressed.emit()
	await get_tree().process_frame
	_creator_probe_check(current_screen is CampaignCreator, "creating a campaign opens the creator")
	if not current_screen is CampaignCreator:
		_creator_probe_exit(campaign_id)
		return
	var screen := current_screen as CampaignCreator
	_creator_probe_check(String(screen.draft.get("id", "")) == campaign_id, "the creator edits the new campaign")

	# Areas, entry and passage.
	screen.area_name_edit.text = "Chapel"
	screen.selected_cell = Vector2i(4, 4)
	screen.facing_option.select(0)
	screen._set_entry()
	_creator_probe_check(String(screen.status_label.text).contains("Entry set"), "Set entry here reports success")
	screen._add_area()
	await get_tree().process_frame
	_creator_probe_check(screen.area_list.get_child_count() == 2, "Add area creates a second area")
	screen.area_name_edit.text = "Crypt"
	screen._select_area(0)
	screen.selected_cell = Vector2i(4, 5)
	screen._select_by_meta(screen.target_option, "area_02")
	screen._add_transition()
	_creator_probe_check(String(screen.status_label.text).contains("Passage added"), "Add / update passage connects the areas")

	# Speaker, conversation and a skill-check branch.
	screen.selected_cell = Vector2i(4, 3)
	screen._place_npc()
	await get_tree().process_frame
	_creator_probe_check(Array(screen._current_area().get("npcs", [])).size() == 1, "Place NPC here adds a speaker")
	screen.npc_name_edit.text = "The Keeper"
	screen.npc_look_edit.text = "A keeper watches the cold altar."
	screen._apply_npc()
	screen.node_text_edit.text = "The chapel has been dark for three nights."
	screen._apply_node()
	for pair in [["success", "You find the old chapel roll."], ["failure", "The altar yields nothing."], ["thanks", "The beacon burns. The keeper bows."]]:
		screen._add_node()
		screen.node_id_edit.text = String(pair[0])
		screen._rename_node()
		screen.node_text_edit.text = String(pair[1])
		screen._select_by_meta(screen.node_next_option, "")
		screen._apply_node()
	screen.flag_edit.text = "beacon_lit"
	screen.flag_desc_edit.text = "The chapel beacon is lit."
	screen._define_flag()
	_creator_probe_check(String(screen.status_label.text).contains("Defined"), "Define flag reports success")
	var start_index := -1
	for i in screen.node_option.item_count:
		if String(screen.node_option.get_item_metadata(i)) == "start":
			start_index = i
	_creator_probe_check(start_index >= 0, "the start node is listed")
	if start_index < 0:
		_creator_probe_exit(campaign_id)
		return
	screen._select_node(start_index)
	screen._add_choice()
	screen.choice_text_edit.text = "Search the altar. [Search DC 5]"
	screen.choice_check_toggle.button_pressed = true
	screen._select_by_meta(screen.choice_skill_option, "search")
	screen.choice_dc_spin.value = 5
	screen._select_by_meta(screen.choice_actor_option, "best")
	screen._select_by_meta(screen.choice_success_option, "success")
	screen._select_by_meta(screen.choice_failure_option, "failure")
	screen._apply_choice()
	screen._add_choice()
	screen.choice_text_edit.text = "The beacon is lit."
	screen.choice_check_toggle.button_pressed = false
	screen._select_by_meta(screen.choice_dest_option, "thanks")
	screen.choice_require_edit.text = "beacon_lit"
	screen._apply_choice()
	screen._add_choice()
	screen.choice_text_edit.text = "Leave."
	screen._select_by_meta(screen.choice_dest_option, "")
	screen._apply_choice()
	var start_node: Dictionary = Dictionary(Dictionary(CampaignStore.dialogue_by_id(screen.draft, "npc_01_talk").get("nodes", {}))["start"])
	_creator_probe_check(Array(start_node.get("choices", [])).size() == 3, "three responses are stored")

	# Quest, objective and flag connection.
	screen._new_quest()
	await get_tree().process_frame
	screen.quest_title_edit.text = "The Cold Beacon"
	screen.quest_summary_edit.text = "Light the chapel beacon."
	screen._select_by_meta(screen.quest_start_option, screen._selected_quest_id)
	screen._select_by_meta(screen.quest_completion_option, screen._selected_quest_id)
	screen._apply_quest()
	screen.objective_id_edit.text = "light_beacon"
	screen.objective_text_edit.text = "Light the beacon."
	screen.objective_flag_edit.text = "beacon_lit"
	screen._apply_objective()
	var quest_id := screen._selected_quest_id
	_creator_probe_check(
		CampaignStore.first_objective_flag(screen.draft, quest_id) == "beacon_lit",
		"the objective is bound to beacon_lit"
	)

	# Encounter, victory wiring and trigger.
	screen._new_encounter()
	await get_tree().process_frame
	screen.encounter_name_edit.text = "Chapel Shade"
	screen.encounter_xp_spin.value = 50
	screen.encounter_intro_edit.text = "Something cold turns toward the light."
	screen._apply_encounter()
	screen._select_by_meta(screen.encounter_monster_option, "zombie")
	screen._add_monster()
	screen.victory_flag_edit.text = "beacon_lit"
	screen._select_by_meta(screen.victory_quest_option, screen._selected_quest_id)
	screen._apply_victory()
	screen._select_area(0)
	screen.selected_cell = Vector2i(3, 4)
	screen._place_trigger()
	_creator_probe_check(String(screen.status_label.text).contains("Placed trigger"), "Place here places the encounter trigger")
	screen._validate()
	_creator_probe_check(
		String(screen.status_label.text).contains("Draft validates"),
		"Validate draft accepts the authored campaign",
		"status=%s pending=%s errors=%s" % [
			String(screen.status_label.text).replace("\n", " | "),
			str(screen.pending_form_keys()),
			str(screen.diagnostics),
		]
	)
	screen._save()
	_creator_probe_check(not screen.dirty, "Save draft clears the dirty flag")
	screen.focus_encounter_section()
	await get_tree().process_frame
	var view := get_viewport().get_visible_rect()
	_creator_probe_check(view.encloses(screen.save_button.get_global_rect()), "Save draft stays visible while the encounter section is in view")
	_creator_probe_check(view.encloses(screen.play_button.get_global_rect()), "Playtest draft stays visible while the encounter section is in view")
	_creator_probe_check(view.encloses(screen.status_label.get_global_rect()), "validation and save messages stay visible while scrolled")
	screen.scroll.scroll_vertical = 0
	var quests_path := CampaignStore.package_dir(campaign_id).path_join("quests.json")
	var quests_before := FileAccess.get_file_as_string(quests_path)

	# Recovery: invalid entry, occupied trigger, referenced delete, unsaved navigation.
	screen.selected_cell = Vector2i(0, 0)
	screen._set_entry()
	_creator_probe_check(String(screen.status_label.text).to_lower().contains("wall") or String(screen.status_label.text).to_lower().contains("floor"), "a wall entry is refused with a reason")
	screen.selected_cell = Vector2i(4, 4)
	screen._place_trigger()
	_creator_probe_check(String(screen.status_label.text).to_lower().contains("entry") or String(screen.status_label.text).to_lower().contains("occupied"), "an occupied trigger cell is refused with a reason")
	screen._confirm_delete_quest()
	_creator_probe_check(String(screen.status_label.text).contains("Cannot delete"), "a referenced quest delete is refused and names the reference")
	screen.title_edit.text = "Acceptance Chapel (unsaved)"
	screen._mark_dirty()
	screen._back()
	await get_tree().process_frame
	_creator_probe_check(modal != null, "leaving with unsaved changes opens a decision dialog")
	var keep := _find_button(modal, "Keep editing")
	_creator_probe_check(keep != null, "the unsaved dialog offers Keep editing")
	if keep != null:
		keep.pressed.emit()
	await get_tree().process_frame
	_creator_probe_check(current_screen is CampaignCreator, "Keep editing preserves the draft in the creator")
	screen._save()

	# Playtest: talk, resolve the check, win the wired encounter, see the change.
	screen._playtest()
	await get_tree().process_frame
	_creator_probe_check(Game.playtest_mode, "Playtest enters playtest mode")
	_creator_probe_check(Game.mode == "explore", "Playtest starts in exploration")
	Game.facing = Dungeon.NORTH
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the placed NPC can be talked to")
	var search_choice := -1
	for choice in Game.dialogue_choices():
		if String(choice.get("text", "")).contains("Search"):
			search_choice = int(choice.get("index", -1))
	_creator_probe_check(search_choice >= 0, "the skill-check response is offered")
	if search_choice >= 0:
		Game.dialogue_choose(search_choice)
	for i in 4:
		if Game.mode == "dialogue":
			Game.dialogue_choose(0)
	_creator_probe_check(Game.mode == "explore", "the check resolves and the conversation can end")
	Game.facing = Dungeon.WEST
	Game.move_forward()
	_creator_probe_check(Game.mode == "combat", "the placed trigger starts its encounter")
	if Game.encounter == null:
		_creator_probe_check(false, "the trigger's encounter exists to finish")
	else:
		Game.encounter.finish("victory")
	_creator_probe_check(bool(Game.flags.get("beacon_lit", false)), "victory sets the authored flag")
	_creator_probe_check(Game.quests.is_complete(quest_id), "victory completes the wired quest")
	Game.move_back()
	Game.facing = Dungeon.NORTH
	_creator_probe_check(bool(Game.interact().get("ok", false)), "the keeper can be spoken to after victory")
	var changed := false
	for choice in Game.dialogue_choices():
		if String(choice.get("text", "")).contains("beacon is lit") and bool(choice.get("available", false)):
			changed = true
	_creator_probe_check(changed, "the keeper shows the changed response")
	_creator_probe_check(not bool(Game.save_game("slot1").get("ok", false)), "playtest refuses to overwrite a save")
	_open_pause()
	var back_to_creator := _find_button(modal, "Return to campaign creator")
	_creator_probe_check(back_to_creator != null, "pause offers Return to campaign creator")
	if back_to_creator != null:
		back_to_creator.pressed.emit()
	await get_tree().process_frame
	_creator_probe_check(current_screen is CampaignCreator, "returning restores the creator")
	_creator_probe_check(FileAccess.get_file_as_string(quests_path) == quests_before, "playtest leaves the saved package byte-identical")

	# Reopen from disk (restart simulation) and verify persisted authoring.
	var creator := current_screen as CampaignCreator
	if creator != null:
		creator._back()
	await get_tree().process_frame
	_creator_probe_check(current_screen is Control, "Back returns to the campaign list")
	Game.refresh_campaigns()
	_show_campaign_select()
	await get_tree().process_frame
	var edit := _find_button(current_screen, "Edit")
	_creator_probe_check(edit != null, "the authored campaign is listed with Edit")
	if edit == null:
		_creator_probe_exit(campaign_id)
		return
	edit.pressed.emit()
	await get_tree().process_frame
	_creator_probe_check(current_screen is CampaignCreator, "Edit reopens the campaign from disk")
	var reopened := current_screen as CampaignCreator
	if reopened != null:
		_creator_probe_check(reopened.area_list.get_child_count() == 2, "both authored areas survive the reopen")
		_creator_probe_check(String(CampaignStore.quest_by_id(reopened.draft, "quest_01").get("title", "")) == "The Cold Beacon", "the quest survives the reopen")
		_creator_probe_check(String(CampaignStore.encounter_by_id(reopened.draft, "encounter_01").get("name", "")) == "Chapel Shade", "the encounter survives the reopen")

	# Duplicate id through the Create campaign dialog.
	if reopened != null:
		reopened._back()
	await get_tree().process_frame
	_show_campaign_select()
	await get_tree().process_frame
	var create_again := _find_button(current_screen, "Create campaign")
	if create_again != null:
		create_again.pressed.emit()
		await get_tree().process_frame
		var dup_fields: Array = modal.find_children("*", "LineEdit", true, false) if modal != null else []
		if dup_fields.size() >= 2:
			dup_fields[0].text = "Duplicate"
			dup_fields[1].text = campaign_id
			var dup_create := _find_button(modal, "Create and edit")
			if dup_create != null:
				dup_create.pressed.emit()
		await get_tree().process_frame
		_creator_probe_check(modal != null, "a conflicting campaign id keeps the dialog open")
		var cancel := _find_button(modal, "Cancel")
		if cancel != null:
			cancel.pressed.emit()

	# Ordinary play and save/load.
	Game.playtest_mode = false
	_creator_probe_check(bool(Game.load_campaign(campaign_id).get("ok", false)), "ordinary play loads the saved campaign")
	_creator_probe_check(bool(Game.new_game([], 4242, campaign_id).get("ok", false)), "ordinary play starts a new game")
	_creator_probe_check(bool(Game.save_game("slot1").get("ok", false)), "ordinary play saves progress")
	Game.new_game([], 4343, campaign_id)
	_creator_probe_check(bool(Game.load_game("slot1").get("ok", false)), "saved progress loads again")

	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")
	_creator_probe_exit(campaign_id)


func _probe_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	for child in root.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text == text:
			return button
	return null


func _probe_click_at(at: Vector2, label: String) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	get_viewport().push_input(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		get_viewport().push_input(event)
		await get_tree().process_frame
	for i in 3:
		await get_tree().process_frame
	print("PROBE CLICK %s at %s" % [label, str(at)])


func _probe_click(control: Control, label: String) -> void:
	if control == null:
		_probe_check(false, "control '%s' exists" % label)
		return
	print("PROBE CONTROL %s enabled=%s" % [label, str(not control.disabled)])
	_probe_check(not control.disabled, "control '%s' is enabled" % label)
	# A control can exist, be enabled, and still sit outside the window; then a
	# real click cannot reach it and the scenario would only look green.
	_probe_check(
		get_viewport().get_visible_rect().encloses(control.get_global_rect()),
		"control '%s' is on screen" % label,
	)
	await _probe_click_at(control.get_global_rect().get_center(), label)


func _probe_click_cell(combat: Control, cell: Vector2i, label: String) -> void:
	var view = combat.view
	var base: Vector2 = view.get_global_rect().position + view.origin
	var at: Vector2 = base + Vector2(cell.x + 0.5, cell.y + 0.5) * float(view.cell_size)
	await _probe_click_at(at, "%s cell %s" % [label, str(cell)])


## Layout reachability probe for a supported window and text scale. Every visible
## interactive control must be reachable: inside the client area, or inside a
## ScrollContainer that can bring it there. A label that refuses to wrap may not be
## allocated less width than its own text. The screen comes from the ordinary
## `--demo-*` flags; `--layout-scenario=settings|inspect` opens the modal under test.
func _layout_probe(scenario: String) -> void:
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var failures := 0
	match scenario:
		"settings":
			_open_settings()
		"inspect":
			if current_screen is CombatScreen:
				(current_screen as CombatScreen)._inspect_active()
			else:
				failures += 1
				print("  LAYOUT WRONG SCREEN no combat screen for the inspect modal")
		"dialogue":
			if Game.dialogue == null:
				failures += 1
				print("  LAYOUT WRONG SCREEN no conversation open")
		"journal":
			_seed_journal_probe()
			open_modal("Journal", func() -> Control:
				return Panels.journal()
			, 800, 560)
		"refusal":
			_blocked_move_probe()
		"fullscreen":
			Game.set_fullscreen(true)
			# Switching to exclusive fullscreen is asynchronous; a fixed frame count
			# measured the old windowed client and passed for the wrong reason.
			for i in 120:
				await get_tree().process_frame
				if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
					break
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				failures += 1
				print("  LAYOUT FULLSCREEN NOT APPLIED mode=%d" % DisplayServer.window_get_mode())
			# The client size follows the mode change a few frames later.
			for i in 30:
				await get_tree().process_frame
	for i in 8:
		await get_tree().process_frame
	# Read the client once, before the fullscreen scenario restores the display; the
	# summary must describe the layout that was measured, not the restored window.
	var measured_client := get_viewport().get_visible_rect().size
	if scenario == "fullscreen":
		# Exclusive fullscreen used to report a 1920x1082 client on a 1920x1080
		# display because the fixed 1280x720 base was scaled by 1.5028. The client
		# must never be larger than the screen it is drawn on.
		var screen_size := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		var client_size := measured_client
		if client_size.x > float(screen_size.x) or client_size.y > float(screen_size.y):
			failures += 1
			print(
				"  LAYOUT FULLSCREEN OVERSHOOT client=%s screen=%s"
				% [str(client_size), str(screen_size)]
			)
	var checked := 0
	if current_screen != null:
		var screen_report: Array = await _layout_report(current_screen, "screen")
		failures += int(screen_report[0])
		checked += int(screen_report[1])
	if modal != null:
		var modal_report: Array = await _layout_report(modal, "modal")
		failures += int(modal_report[0])
		checked += int(modal_report[1])
	elif scenario == "settings" or scenario == "inspect" or scenario == "journal":
		failures += 1
		print("  LAYOUT MISSING modal for scenario '%s'" % scenario)
	if scenario == "journal":
		var journal_report: Array = await _layout_journal()
		failures += int(journal_report[0])
		checked += int(journal_report[1])
	if scenario == "refusal":
		var feedback_report: Array = await _layout_feedback()
		failures += int(feedback_report[0])
		checked += int(feedback_report[1])
	# A screen that never built would otherwise pass with nothing to check. The
	# journal is one text surface plus the modal's own button, so its floor is 2.
	var minimum_checked := 2 if scenario == "journal" else 5
	if checked < minimum_checked:
		failures += 1
		print("  LAYOUT TOO FEW controls checked (%d)" % checked)
	if capture_dir != "":
		await _capture_layout_shot(scenario)
	if scenario == "fullscreen":
		# Leave the display exactly as it was found; the setting is persisted.
		Game.set_fullscreen(false)
	print("LAYOUT PROBE %s scenario=%s client=%s text=%.2f controls=%d failures=%d" % [
		"PASS" if failures == 0 else "FAIL",
		scenario,
		str(measured_client),
		float(Game.settings.get("text_scale", 1.0)),
		checked,
		failures,
	])
	get_tree().quit(0 if failures == 0 else 1)


func _capture_layout_shot(scenario: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var client := get_viewport().get_visible_rect().size
	var shot_name := "layout_%s_%s_t%d_%dx%d" % [
		scenario,
		_screen_tag(),
		int(round(float(Game.settings.get("text_scale", 1.0)) * 100.0)),
		int(client.x),
		int(client.y),
	]
	var shot_path := capture_dir.path_join(shot_name + ".png")
	if image.save_png(shot_path) == OK:
		print("CAPTURED %s" % shot_path)
	else:
		print("CAPTURE FAILED %s" % shot_name)


## Faces the party out of the map and walks into the edge. The refusal must reach
## the exploration log; `_layout_feedback` checks where.
func _blocked_move_probe() -> void:
	Game.position = Vector2i(0, 0)
	Game.facing = Dungeon.WEST
	Game.move_forward()
	# The keyboard handler refreshes after acting; do the same so the log widget
	# reflects the refusal the way a player would see it.
	if current_screen != null and current_screen.has_method("refresh_screen"):
		current_screen.refresh_screen()


## Separates "the message exists" from "the player can see it": the line must be
## in `Game.log_lines`, in the log widget's rendered text, and the widget must lie
## inside the client. The capture taken after this is the visual evidence.
func _layout_feedback() -> Array:
	var screen := current_screen as ExplorationScreen
	if screen == null or screen.log_label == null:
		print("  LAYOUT FEEDBACK NO LOG WIDGET")
		return [1, 0]
	var line := "Cold stone blocks the way."
	var failures := 0
	var logged := false
	for entry in Game.log_lines.slice(maxi(0, Game.log_lines.size() - 3)):
		if String(entry) == line:
			logged = true
	if not logged:
		failures += 1
		print("  LAYOUT FEEDBACK MISSING FROM LOG")
	var rendered := screen.log_label.get_parsed_text()
	if not rendered.contains(line):
		failures += 1
		print("  LAYOUT FEEDBACK MISSING FROM LOG WIDGET")
	if not rendered.strip_edges().ends_with(line):
		failures += 1
		print("  LAYOUT FEEDBACK LINE IS NOT THE NEWEST ENTRY")
	var rect := screen.log_label.get_global_rect()
	if not get_viewport().get_visible_rect().encloses(rect):
		failures += 1
		print("  LAYOUT FEEDBACK LOG OUTSIDE CLIENT rect=%s" % str(rect))
	if modal != null:
		failures += 1
		print("  LAYOUT FEEDBACK LOG COVERED BY MODAL '%s'" % modal_title)
	if screen.log_label.get_visible_line_count() <= 0:
		failures += 1
		print("  LAYOUT FEEDBACK LOG SHOWS NO LINES")
	return [failures, 1]


## Shows one earned fact so the journal's layout covers wrapped prose instead of
## the empty-state line. The probe process never writes a save, so this is local.
func _seed_journal_probe() -> void:
	var facts: Variant = Game.content.journal.get("facts", []) if Game.content != null else []
	if not facts is Array or Array(facts).is_empty():
		return
	var first: Variant = Array(facts)[0]
	if not first is Dictionary:
		return
	var flag := String(Dictionary(first).get("flag", ""))
	if flag != "":
		Game.flags[flag] = true
	# Reveal the first question as well, so the probe lays out both sections.
	var questions: Variant = Game.content.journal.get("questions", [])
	if questions is Array and not Array(questions).is_empty():
		var first_question: Variant = Array(questions)[0]
		if first_question is Dictionary:
			var reveal := String(Dictionary(first_question).get("revealed_by", ""))
			if reveal != "":
				Game.flags[reveal] = true


## The Journal is one RichTextLabel rather than a set of interactive controls, so
## reachability alone would not notice an empty or raw-id body. This checks the
## rendered sections, the authored wording and the body's bounds.
func _layout_journal() -> Array:
	if modal == null:
		print("  LAYOUT JOURNAL NO MODAL")
		return [1, 0]
	var bodies := modal.find_children("*", "RichTextLabel", true, false)
	if bodies.is_empty():
		print("  LAYOUT JOURNAL NO BODY")
		return [1, 0]
	var body := bodies[0] as RichTextLabel
	var parsed := body.get_parsed_text()
	var failures := 0
	var notes := Panels.journal_notes(Game.flags)
	var expected_facts: Array = notes["facts"]
	var expected_questions: Array = notes["questions"]
	if not expected_facts.is_empty() and not parsed.contains("What you know"):
		failures += 1
		print("  LAYOUT JOURNAL MISSING FACTS SECTION")
	if not expected_questions.is_empty() and not parsed.contains("Still open"):
		failures += 1
		print("  LAYOUT JOURNAL MISSING QUESTIONS SECTION")
	for line in expected_facts:
		if not parsed.contains(String(line)):
			failures += 1
			print("  LAYOUT JOURNAL MISSING FACT TEXT")
	# The body is a fit_content label inside a ScrollContainer, so it is *meant*
	# to be taller than the panel: the scroller must be inside the client and the
	# text starts inside it. Requiring the label's own rect to fit would fail on
	# any journal long enough to scroll.
	var scroller := body.get_parent() as ScrollContainer
	if scroller == null:
		failures += 1
		print("  LAYOUT JOURNAL BODY IS NOT SCROLLABLE")
	elif not get_viewport().get_visible_rect().encloses(scroller.get_global_rect()):
		failures += 1
		print("  LAYOUT JOURNAL SCROLLER OUTSIDE CLIENT rect=%s" % str(scroller.get_global_rect()))
	var facts: Variant = Game.content.journal.get("facts", []) if Game.content != null else []
	if facts is Array:
		for raw in Array(facts):
			if not raw is Dictionary:
				continue
			var flag := String(Dictionary(raw).get("flag", ""))
			if flag != "" and parsed.contains(flag):
				failures += 1
				print("  LAYOUT JOURNAL RAW FLAG '%s'" % flag)
	return [failures, 1]


## Walks one screen (or modal) and returns [violations, interactive controls seen].
func _layout_report(root: Node, label: String) -> Array:
	var client := get_viewport().get_visible_rect()
	var failures := 0
	var controls: Array[Control] = []
	for node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control != null and control.is_visible_in_tree() and _layout_interactive(control):
			controls.append(control)
	for control in controls:
		if not client.encloses(control.get_global_rect()):
			var scroller := _layout_scroller(control)
			if scroller != null:
				scroller.ensure_control_visible(control)
				await get_tree().process_frame
		var rect := control.get_global_rect()
		if not client.encloses(rect):
			failures += 1
			print(
				"  LAYOUT UNREACHABLE %s %s rect=%s client=%s"
				% [label, _layout_path(control, root), str(rect), str(client)]
			)
	for node in root.find_children("*", "Label", true, false):
		var text_label := node as Label
		if text_label == null or not text_label.is_visible_in_tree():
			continue
		if text_label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			continue
		var needed := text_label.get_minimum_size().x
		if needed > text_label.size.x + 1.0:
			failures += 1
			print(
				"  LAYOUT TEXT CLIPPED %s %s needed=%.1f got=%.1f text=%s"
				% [label, _layout_path(text_label, root), needed, text_label.size.x, text_label.text]
			)
	return [failures, controls.size()]


## A stable, readable name for the screen under test (file name of its script),
## so captures of different screens never overwrite each other.
func _screen_tag() -> String:
	if current_screen == null:
		return "none"
	var script: Script = current_screen.get_script()
	if script != null and String(script.resource_path) != "":
		return String(script.resource_path).get_file().get_basename()
	return current_screen.get_class().to_lower()


func _layout_interactive(control: Control) -> bool:
	return (
		control is BaseButton
		or control is LineEdit
		or control is SpinBox
		or control is HSlider
		or control is TextEdit
	)


func _layout_scroller(control: Control) -> ScrollContainer:
	var node := control.get_parent()
	while node != null:
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	return null


func _layout_path(control: Control, root: Node) -> String:
	var parts: Array[String] = []
	var node: Node = control
	while node != null and node != root:
		parts.push_front(String(node.name))
		node = node.get_parent()
	return "/".join(PackedStringArray(parts))


func _probe_shot(scenario: String, step: String) -> void:
	# A headless run has no draw callback; it still exercises the controls and
	# writes an (empty) image so the same probe can smoke-test the logic.
	if DisplayServer.get_name() == "headless":
		for i in 2:
			await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := probe_shots.path_join("trip_%s_%s.png" % [scenario, step])
	if image == null:
		print("PROBE SHOT %s skipped (no image in this display mode)" % path)
		return
	var error := image.save_png(path)
	print("PROBE SHOT %s error=%d" % [path, error])


func _probe_tail(step: String) -> void:
	var e := Game.encounter
	print("PROBE STATE %s pending=%s actor=%s message=%s" % [
		step,
		str(e.has_pending_decision() if e != null else false),
		str(e.active_character().display_name if e != null and e.active_character() != null else "none"),
		Game.last_ui_message,
	])
	if e != null:
		for line in e.log_lines.slice(maxi(0, e.log_lines.size() - 6)):
			print("PROBE LOG %s" % String(line))


## Probe bookkeeping. A check records an expected outcome; the process exits
## nonzero when any check fails, so this is an acceptance probe rather than a
## transcript. Setup lives in the QA fixture (`_qa_trip_demo`); these checks only
## read the state that the real control tree produced.
var probe_failures: Array[String] = []
var probe_done := false
var probe_started_ms := 0


func _probe_check(ok: bool, label: String) -> void:
	if ok:
		print("PROBE CHECK PASS %s" % label)
		return
	probe_failures.append(label)
	print("PROBE CHECK FAIL %s" % label)


func _probe_log_contains(e: Encounter, needle: String) -> bool:
	for line in e.log_lines:
		if String(line).contains(needle):
			return true
	return false


## Bounds the run. A hung await would otherwise sit until the external
## --quit-after, which cannot report a scenario failure.
func _probe_watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	if probe_done:
		return
	print("PROBE FAIL: scenario '%s' exceeded the 90 s bound" % probe_scenario)
	get_tree().quit(1)


func _probe_finish(scenario: String) -> void:
	probe_done = true
	var elapsed := Time.get_ticks_msec() - probe_started_ms
	if probe_failures.is_empty():
		print("PROBE RESULT PASS scenario=%s elapsed_ms=%d" % [scenario, elapsed])
		get_tree().quit(0)
		return
	print(
		"PROBE RESULT FAIL scenario=%s elapsed_ms=%d failures=%d"
		% [scenario, elapsed, probe_failures.size()]
	)
	for failure in probe_failures:
		print("PROBE FAILED CHECK %s" % failure)
	get_tree().quit(1)


## Drives the real campaign-selection screen with a broken manifest and a broken
## story file, asserts safe refusal and readable reasons, then repairs both files
## and reopens the screen through the ordinary refresh path.
func _package_diagnostics_probe() -> void:
	probe_scenario = "package_diagnostics"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	var manifest_id := "qa_diag_manifest"
	var story_id := "qa_diag_story"
	CampaignStore.delete_user_campaign(manifest_id)
	CampaignStore.delete_user_campaign(story_id)
	var made_manifest := CampaignStore.create("Diagnostics Manifest Probe", manifest_id)
	var made_story := CampaignStore.create("Diagnostics Story Probe", story_id)
	_probe_check(bool(made_manifest.get("ok", false)) and bool(made_story.get("ok", false)), "disposable packages are created")
	if not bool(made_manifest.get("ok", false)) or not bool(made_story.get("ok", false)):
		_probe_finish("package_diagnostics")
		return
	var manifest_path := CampaignStore.package_dir(manifest_id).path_join("campaign.json")
	var manifest_backup := FileAccess.get_file_as_string(manifest_path)
	var area_path := CampaignStore.package_dir(story_id).path_join("areas").path_join("area_01.json")
	var area_backup := FileAccess.get_file_as_string(area_path)
	_write_probe_text(manifest_path, "{ not a manifest")
	_write_probe_text(area_path, "{\n\t\"id\": \"area_01\",\n\tbroken here\n}\n")
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")
	_show_campaign_select()
	for i in 4:
		await get_tree().process_frame
	_probe_check(Game.campaigns.has(story_id), "the story-damaged package is installed")
	_probe_check(not Game.campaigns.has(manifest_id), "the unreadable manifest package is not listed")
	_probe_check(_probe_label_contains(current_screen, "not valid JSON"), "the discovery reason is readable on screen")
	_probe_check(_probe_label_contains(current_screen, manifest_id), "the discovery reason names the package")
	var new_game_buttons := _probe_buttons(current_screen, "New game")
	_probe_check(new_game_buttons.size() == Game.campaigns.order.size(), "one New game control per listed campaign")
	var all_enabled := true
	for button in new_game_buttons:
		if (button as Button).disabled:
			all_enabled = false
	_probe_check(all_enabled, "all listed campaigns remain selectable")
	var story_index := Game.campaigns.order.find(story_id)
	var demo_index := Game.campaigns.order.find("ravenloft_demo")
	new_game_buttons[story_index].pressed.emit()
	for i in 4:
		await get_tree().process_frame
	_probe_check(modal_title == "Campaign unavailable", "the broken story package is refused safely")
	_probe_check(_probe_label_contains(modal, "areas/area_01.json"), "the refusal names the damaged file")
	_probe_check(_probe_label_contains(modal, "line 3"), "the refusal carries the parser line")
	_probe_check(Game.campaign_id == "ravenloft_demo", "the active campaign is not replaced")
	close_modal()
	for i in 2:
		await get_tree().process_frame
	var validate_buttons := _probe_buttons(current_screen, "Validate")
	_probe_check(validate_buttons.size() == Game.campaigns.order.size(), "one Validate control per listed campaign")
	validate_buttons[story_index].pressed.emit()
	for i in 4:
		await get_tree().process_frame
	_probe_check(modal_title == "Validate campaign", "the Validate control reports the damaged story file")
	_probe_check(_probe_label_contains(modal, "areas/area_01.json"), "validation names the damaged area file")
	close_modal()
	for i in 2:
		await get_tree().process_frame
	_write_probe_text(area_path, area_backup)
	Game.refresh_campaigns()
	_show_campaign_select()
	for i in 4:
		await get_tree().process_frame
	new_game_buttons = _probe_buttons(current_screen, "New game")
	story_index = Game.campaigns.order.find(story_id)
	new_game_buttons[story_index].pressed.emit()
	for i in 4:
		await get_tree().process_frame
	_probe_check(Game.campaign_id == story_id, "the repaired package loads through the reopen path")
	_probe_check(modal == null, "no refusal remains after the repair")
	Game.load_campaign("ravenloft_demo")
	_write_probe_text(manifest_path, manifest_backup)
	Game.refresh_campaigns()
	_show_campaign_select()
	for i in 4:
		await get_tree().process_frame
	_probe_check(Game.campaigns.has(manifest_id), "the repaired manifest package is listed again")
	_probe_check(not _probe_label_contains(current_screen, "not valid JSON"), "the discovery notice clears after repair")
	_probe_check(_probe_buttons(current_screen, "New game").size() == Game.campaigns.order.size(), "valid campaigns stay selectable throughout")
	_probe_check(demo_index >= 0 and Game.campaigns.order.find("ravenloft_demo") == demo_index, "the bundled campaign order is stable")
	CampaignStore.delete_user_campaign(manifest_id)
	CampaignStore.delete_user_campaign(story_id)
	Game.refresh_campaigns()
	Game.load_campaign("ravenloft_demo")
	_probe_finish("package_diagnostics")


func _probe_bytes(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _probe_read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if parsed is Dictionary else {}


func _probe_write_json(path: String, data: Dictionary) -> void:
	_write_probe_text(path, JSON.stringify(data, "	"))


## Reproduces supported content edits against an ordinary save, through the same
## load path the player uses. Prints each outcome; assertions are added only for
## the behavior this unit fixes.
func _save_compat_probe() -> void:
	probe_scenario = "save_compat"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	var id := "qa_compat_probe"
	CampaignStore.delete_user_campaign(id)
	Game.refresh_campaigns()
	SaveSystem.delete_save_everywhere("slot2")
	var made := CampaignStore.create("Compatibility Probe", id)
	_probe_check(bool(made.get("ok", false)), "disposable campaign is created")
	if not bool(made.get("ok", false)):
		_probe_finish("save_compat")
		return
	Game.refresh_campaigns()
	var pkg := CampaignStore.package_dir(id)
	var draft: Dictionary = Dictionary(CampaignStore.load_package(id).get("draft", {}))
	CampaignStore.add_area(draft, "Second Area")
	var side_ref := CampaignStore.add_quest(draft, "Side Quest")
	var side_quest := String(side_ref.get("id", ""))
	CampaignStore.add_flag_definition(draft, "compat_flag", "compat")
	var written := CampaignStore.write_package(draft)
	_probe_check(bool(written.get("ok", false)), "second area and flag are written")
	Game.refresh_campaigns()
	_probe_check(bool(Game.load_campaign(id).get("ok", false)), "the disposable campaign loads")
	Game.new_game(["kaelen"], 4242)
	var quest := id + "_quest"
	Game.quests.start(quest)
	Game.quests.start(side_quest)
	Game.flags["compat_flag"] = true
	Game.flags[id + "_quest_objective_01"] = true
	Game.flags[side_quest + "_done"] = true
	Game.travel_to("area_02", Vector2i(2, 3), 2)
	var saved := Game.save_game("slot2")
	_probe_check(bool(saved.get("ok", false)), "an ordinary save is written")
	var save_path := SaveSystem.path_for("slot2", id)
	var original_save := _probe_bytes(save_path)
	var manifest := _probe_read_json(pkg.path_join("campaign.json"))
	_probe_check(not original_save.is_empty(), "the save bytes are preserved for comparison")

	manifest["description"] = "Prose changed only."
	_probe_write_json(pkg.path_join("campaign.json"), manifest)
	var prose := _compat_reload(id)
	print("COMPAT prose load ok=%s pos=%s" % [str(prose.get("ok", false)), str(Game.position)])
	_probe_check(bool(prose.get("ok", false)) and Game.position == Vector2i(2, 3), "prose edit loads at the saved cell")

	manifest["entry"] = {"area": "area_01", "pos": [2, 2], "facing": 1}
	_probe_write_json(pkg.path_join("campaign.json"), manifest)
	var moved := _compat_reload(id)
	print("COMPAT entry moved ok=%s pos=%s" % [str(moved.get("ok", false)), str(Game.position)])
	_probe_check(bool(moved.get("ok", false)) and Game.position == Vector2i(2, 3), "entry move does not relocate the save")

	var area_path := pkg.path_join("areas").path_join("area_02.json")
	var area := _probe_read_json(area_path)
	var rows: Array = area["rows"]
	var original_row := String(rows[4])
	var blocked_row := original_row.substr(0, 4) + "#" + original_row.substr(5)
	rows[3] = String(rows[3]).substr(0, 2) + "#" + String(rows[3]).substr(3)
	area["rows"] = rows
	_probe_write_json(area_path, area)
	var blocked := _compat_reload(id)
	print("COMPAT blocked cell ok=%s pos=%s walkable=%s msg=%s" % [str(blocked.get("ok", false)), str(Game.position), str(Game.dungeon.is_walkable(Game.position)), String(blocked.get("message", ""))])
	_probe_check(not bool(blocked.get("ok", false)) and String(blocked.get("message", "")).contains("blocked") and Game.position == Vector2i(2, 3), "blocked saved cell is refused before activation")
	rows[3] = String(rows[3]).substr(0, 2) + "." + String(rows[3]).substr(3)
	area["rows"] = rows
	_probe_write_json(area_path, area)

	var saved_data := _probe_read_json(save_path)
	saved_data["position"] = [99, 99]
	_probe_write_json(save_path, saved_data)
	var oob := _compat_reload(id)
	print("COMPAT out of bounds ok=%s pos=%s msg=%s" % [str(oob.get("ok", false)), str(Game.position), String(oob.get("message", ""))])
	_probe_check(not bool(oob.get("ok", false)) and String(oob.get("message", "")).contains("outside") and Game.position == Vector2i(2, 3), "out-of-bounds save is refused, not teleported")
	_write_probe_text(save_path, original_save)
	# Quest removed while the package remains valid (start quest cleared).
	var quests := _probe_read_json(pkg.path_join("quests.json"))
	quests.erase(side_quest)
	_probe_write_json(pkg.path_join("quests.json"), quests)
	manifest = _probe_read_json(pkg.path_join("campaign.json"))
	_probe_write_json(pkg.path_join("campaign.json"), manifest)
	var quest_load := _compat_reload(id)
	print("COMPAT quest removed ok=%s start_status=%s side_status=%s msg=%s" % [str(quest_load.get("ok", false)), Game.quests.status(quest), Game.quests.status(side_quest), String(quest_load.get("message", ""))])
	_probe_check(not bool(quest_load.get("ok", false)) and String(quest_load.get("message", "")).contains(side_quest) and Game.quests.status(side_quest) == "active", "removed saved quest is refused without losing live progress")
	_probe_write_json(pkg.path_join("quests.json"), Dictionary(draft.get("quests", {})))
	_probe_write_json(pkg.path_join("campaign.json"), manifest)

	# Flag declaration removed, stored flag value expected to remain harmless.
	manifest.erase("flag_definitions")
	_probe_write_json(pkg.path_join("campaign.json"), manifest)
	var flag_load := _compat_reload(id)
	print("COMPAT flag decl removed ok=%s flag=%s" % [str(flag_load.get("ok", false)), str(Game.flags.get("compat_flag", null))])
	_probe_check(bool(flag_load.get("ok", false)) and bool(Game.flags.get("compat_flag", false)), "removed flag declaration is harmless to stored flags")

	# The saved area is removed from the package.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(area_path))
	var area_load := _compat_reload(id)
	print("COMPAT saved area removed ok=%s msg=%s" % [str(area_load.get("ok", false)), String(area_load.get("message", ""))])
	_probe_check(not bool(area_load.get("ok", false)), "removed saved area is refused")

	# Content version mismatch (manual authoring decision).
	manifest = _probe_read_json(pkg.path_join("campaign.json"))
	manifest["version"] = 2
	_probe_write_json(pkg.path_join("campaign.json"), manifest)
	var version_load := _compat_reload(id)
	print("COMPAT content version 2 ok=%s msg=%s" % [str(version_load.get("ok", false)), String(version_load.get("message", ""))])
	_probe_check(not bool(version_load.get("ok", false)), "content version mismatch is refused")
	print("COMPAT save bytes unchanged=%s" % str(_probe_bytes(save_path) == original_save))
	_probe_check(_probe_bytes(save_path) == original_save, "refused loads never rewrite the save")

	Game.load_campaign("ravenloft_demo")
	CampaignStore.delete_user_campaign(id)
	SaveSystem.delete_save_everywhere("slot2")
	_probe_finish("save_compat")


## Measures the shared modal and the campaign intro at the requested text scale.
func _intro_layout_probe() -> void:
	probe_scenario = "intro_layout"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	Game.refresh_campaigns()
	var loaded := Game.load_campaign("qa_list_long_title")
	_probe_check(bool(loaded.get("ok", false)), "the fixture campaign loads")
	if not bool(loaded.get("ok", false)):
		_probe_finish("intro_layout")
		return
	if probe_text_scale > 0.0:
		await _probe_set_text_scale(probe_text_scale)
	var party: Array = Array(Game.campaign.get("party", {}).get("default", ["kaelen"]))
	var started := Game.new_game(party, -1)
	_probe_check(bool(started.get("ok", false)), "the fixture campaign starts")
	_route()
	_show_intro()
	for i in 4:
		await get_tree().process_frame
	_probe_check(modal != null, "the intro modal opens")
	if modal == null:
		_probe_finish("intro_layout")
		return
	var window := get_viewport_rect().size
	var center := modal.get_child(1) as Control
	var panel := center.get_child(0) as Control
	var labels := panel.find_children("*", "Label", true, false)
	var heading: Label = null
	var body_labels := 0
	for node in labels:
		var label := node as Label
		if label == null:
			continue
		if String(label.text).begins_with(String(Game.campaign.get("title", "")).substr(0, 24)):
			heading = label
		else:
			body_labels += 1
	var close := _probe_buttons(panel, "Close (Esc)")
	var begin := _probe_buttons(panel, "Begin the campaign")
	print("INTRO scale=%.2f window=%s modal=%s panel=%s panelmin=%s center=%s" % [
		float(Game.settings.get("text_scale", 1.0)), str(window), str(modal.size),
		str(panel.get_global_rect()), str(panel.get_combined_minimum_size()), str(center.size)])
	if heading != null:
		print("INTRO heading=%s min=%s autowrap=%d" % [
			str(heading.get_global_rect()), str(heading.get_combined_minimum_size()),
			int(heading.autowrap_mode)])
	if not close.is_empty():
		print("INTRO close=%s" % str((close[0] as Control).get_global_rect()))
	if not begin.is_empty():
		print("INTRO begin=%s" % str((begin[0] as Control).get_global_rect()))
	var content_scrolls := panel.find_children("*", "ScrollContainer", true, false)
	print("INTRO labels=%d scrolls=%d" % [body_labels, content_scrolls.size()])
	if not content_scrolls.is_empty():
		var content_scroll := content_scrolls[0] as ScrollContainer
		print("INTRO scroll=%s page=%d max=%d focus=%s" % [
			str(content_scroll.get_global_rect()), int(content_scroll.get_v_scroll_bar().page),
			int(content_scroll.get_v_scroll_bar().max_value), str(content_scroll.follow_focus)])
	var panel_rect := panel.get_global_rect()
	_probe_check(panel_rect.position.x >= -1.0 and panel_rect.end.x <= window.x + 1.0, "the modal panel stays inside the window horizontally")
	_probe_check(panel_rect.position.y >= -1.0 and panel_rect.end.y <= window.y + 1.0, "the modal panel stays inside the window vertically")
	_probe_check(not close.is_empty(), "the Close control exists")
	if not close.is_empty():
		var close_rect := (close[0] as Control).get_global_rect()
		_probe_check(close_rect.position.x >= panel_rect.position.x and close_rect.end.x <= panel_rect.end.x, "Close stays inside the panel")
	_probe_check(not begin.is_empty(), "the intro Begin control exists")
	if not begin.is_empty():
		var begin_rect := (begin[0] as Control).get_global_rect()
		_probe_check(begin_rect.position.y >= panel_rect.position.y and begin_rect.end.y <= panel_rect.end.y, "Begin stays inside the panel")
		if not content_scrolls.is_empty():
			var content_scroll := content_scrolls[0] as ScrollContainer
			var scroll_rect := content_scroll.get_global_rect()
			if begin_rect.end.y > scroll_rect.end.y + 1.0:
				content_scroll.scroll_vertical = 100000
				await get_tree().process_frame
				await get_tree().process_frame
				begin_rect = (begin[0] as Control).get_global_rect()
				print("INTRO begin_after_scroll=%s scroll=%d" % [str(begin_rect), int(content_scroll.scroll_vertical)])
			_probe_check(begin_rect.position.y >= scroll_rect.position.y and begin_rect.end.y <= scroll_rect.end.y + 1.0, "Begin is reachable inside the scrolling content")
	_probe_check(heading != null, "the intro heading is rendered")
	if heading != null:
		var heading_rect := heading.get_global_rect()
		_probe_check(heading_rect.end.x <= panel_rect.end.x, "the intro heading stays inside the panel")
		_probe_check(heading.autowrap_mode != TextServer.AUTOWRAP_OFF, "the intro heading can wrap")
	if "--intro-click" in OS.get_cmdline_user_args() and not begin.is_empty():
		await _probe_click(begin[0], "Begin the campaign")
		_probe_check(modal == null, "a real click on Begin dismisses the intro")
	if capture_dir != "":
		await _capture_viewport("intro_layout")
		return
	_probe_finish("intro_layout")


## Reports the party-selection card/label/scroll geometry at the requested text
## scale and checks that wrapped traits stay inside their cards.
func _party_layout_probe() -> void:
	probe_scenario = "party_layout"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	Game.refresh_campaigns()
	var loaded := Game.load_campaign("qa_list_long_title")
	_probe_check(bool(loaded.get("ok", false)), "the fixture campaign loads")
	if not bool(loaded.get("ok", false)):
		_probe_finish("party_layout")
		return
	if probe_text_scale > 0.0:
		await _probe_set_text_scale(probe_text_scale)
	_show_party_select()
	await get_tree().process_frame
	await get_tree().process_frame
	var scrolls := current_screen.find_children("*", "ScrollContainer", true, false)
	_probe_check(not scrolls.is_empty(), "party selection has a scroll container")
	if scrolls.is_empty():
		_probe_finish("party_layout")
		return
	var scroll := scrolls[0] as ScrollContainer
	var grid := scroll.get_child(0) as GridContainer
	var footer := _probe_buttons(self, "Begin")
	_probe_check(not footer.is_empty(), "Begin is present")
	print("PARTY scale=%.2f window=%s scroll=%s page=%d max=%d hmax=%d hpage=%d grid=%s gridmin=%s" % [
		float(Game.settings.get("text_scale", 1.0)), str(get_window().size), str(scroll.size),
		int(scroll.get_v_scroll_bar().page), int(scroll.get_v_scroll_bar().max_value),
		int(scroll.get_h_scroll_bar().max_value), int(scroll.get_h_scroll_bar().page),
		str(grid.size), str(grid.get_combined_minimum_size())])
	var clipped := 0
	for raw_card in grid.get_children():
		var card := raw_card as PanelContainer
		if card == null:
			continue
		var title := ""
		for node in card.find_children("*", "CheckBox", true, false):
			var check := node as CheckBox
			if check != null:
				title = check.text
				break
		var card_rect := card.get_global_rect()
		for node in card.find_children("*", "Label", true, false):
			var label := node as Label
			if label == null:
				continue
			var label_rect := label.get_global_rect()
			var inside := label_rect.position.y >= card_rect.position.y - 1.0 and label_rect.end.y <= card_rect.end.y + 1.0
			if not inside:
				clipped += 1
			print("PARTY card=%s rect=%s min=%s label=%s labelrect=%s labelmin=%s inside=%s" % [
				title, str(card_rect), str(card.get_combined_minimum_size()),
				label.text.substr(0, 18), str(label_rect), str(label.get_combined_minimum_size()), str(inside)])
		_probe_check(true, "card %s inspected" % title)
	_probe_check(clipped == 0, "every trait label is inside its card")
	var checks := grid.find_children("*", "CheckBox", true, false)
	if not checks.is_empty():
		scroll.scroll_vertical = 0
		var last_check := checks[checks.size() - 1] as CheckBox
		last_check.grab_focus()
		await get_tree().process_frame
		await get_tree().process_frame
		var focus_view := scroll.get_global_rect()
		var focus_rect := last_check.get_global_rect()
		print("PARTY focus scroll=%d rect=%s view=%s" % [int(scroll.scroll_vertical), str(focus_rect), str(focus_view)])
		if scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page:
			_probe_check(scroll.scroll_vertical > 0, "focusing an off-screen party card scrolls it into view")
		_probe_check(focus_rect.position.y >= focus_view.position.y and focus_rect.end.y <= focus_view.end.y, "the focused party control is visible")
		var focused_card := last_check.get_parent().get_parent().get_parent() as Control
		var focused_card_rect := focused_card.get_global_rect()
		print("PARTY focus_card=%s view=%s" % [str(focused_card_rect), str(focus_view)])
		_probe_check(focused_card_rect.position.y >= focus_view.position.y and focused_card_rect.end.y <= focus_view.end.y, "the focused party card and its traits are fully visible")
	scroll.scroll_vertical = 100000
	await get_tree().process_frame
	await get_tree().process_frame
	var view := scroll.get_global_rect()
	var last_card := grid.get_child(grid.get_child_count() - 1) as Control
	var last_rect := last_card.get_global_rect()
	print("PARTY after_scroll=%d view=%s last=%s" % [int(scroll.scroll_vertical), str(view), str(last_rect)])
	_probe_check(last_rect.end.y <= view.end.y + 1.0, "the last party card is reachable at the bottom")
	if capture_dir != "":
		await _capture_viewport("party_layout")
		return
	_probe_finish("party_layout")


## The declared party contract in the real party screen: the campaign's own
## range is stated, Begin is unavailable below it with the reason on screen, and
## the supported sizes still start. Run against exported candidates so the
## ordinary screen is checked in the shipped executable.
func _party_limits_probe() -> void:
	probe_scenario = "party_limits"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	Game.refresh_campaigns()
	var loaded := Game.load_campaign("ashwick_ferry")
	_probe_check(bool(loaded.get("ok", false)), "the Ashwick package loads")
	if not bool(loaded.get("ok", false)):
		_probe_finish("party_limits")
		return
	if probe_text_scale > 0.0:
		await _probe_set_text_scale(probe_text_scale)
	party_selection.clear()
	_show_party_select()
	await get_tree().process_frame
	await get_tree().process_frame
	var header_seen := false
	for node in current_screen.find_children("*", "Label", true, false):
		if (node as Label).text.contains("Pick three to four adventurers"):
			header_seen = true
	_probe_check(header_seen, "the party screen states the declared 3-4 range")
	var by_id := {}
	for node in current_screen.find_children("*", "CheckBox", true, false):
		var check := node as CheckBox
		by_id[String(check.get_meta("character_id", ""))] = check
	_probe_check(by_id.size() == 5, "five pregens are offered")
	var found_begin := _probe_buttons(self, "Begin")
	_probe_check(not found_begin.is_empty(), "Begin is present")
	var error := party_error
	_probe_check(error != null, "the selection reason is present")
	if by_id.size() != 5 or found_begin.is_empty() or error == null:
		_probe_finish("party_limits")
		return
	var begin := found_begin[0] as Button
	for id in ["kaelen", "sera"]:
		if by_id.has(id):
			(by_id[id] as CheckBox).button_pressed = true
	for id in ["aldric", "ysolde", "mira"]:
		if by_id.has(id):
			(by_id[id] as CheckBox).button_pressed = false
	await get_tree().process_frame
	await get_tree().process_frame
	_probe_check(error.text == "Choose at least three adventurers.", "two characters show the real minimum")
	_probe_check(begin.disabled, "Begin is unavailable below the minimum")
	for label in ["Begin", "Back"]:
		var footer := _probe_buttons(self, label)
		_probe_check(not footer.is_empty(), "%s is present" % label)
		if not footer.is_empty():
			var rect := (footer[0] as Button).get_global_rect()
			_probe_check(
				rect.position.y >= 0.0 and rect.end.y <= float(get_window().size.y),
				"%s stays inside the window" % label,
			)
	var before_party := Game.party.size()
	begin.emit_signal("pressed")
	await get_tree().process_frame
	_probe_check(error.text == "Pick three to four adventurers.", "Begin states the campaign range")
	_probe_check(Game.party.size() == before_party, "two characters cannot begin")
	(by_id["aldric"] as CheckBox).button_pressed = true
	await get_tree().process_frame
	await get_tree().process_frame
	_probe_check(error.text == "3 selected.", "three characters are accepted")
	_probe_check(not begin.disabled, "Begin is available at the minimum")
	begin.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	_probe_check(Game.party.size() == 3, "three characters begin")
	_probe_check(Game.campaign_id == "ashwick_ferry", "the begun campaign is Ashwick")
	_probe_check(Game.mode == "explore", "the session starts in exploration")
	_probe_finish("party_limits")


## Reports the campaign list's real scroll geometry and focus-follow behavior.
## Fixtures come from the isolated profile, not from this probe.
func _campaign_list_probe() -> void:
	probe_scenario = "campaign_list"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	_show_campaign_select()
	await get_tree().process_frame
	await get_tree().process_frame
	if probe_text_scale > 0.0:
		await _probe_set_text_scale(probe_text_scale)
		_show_campaign_select()
		await get_tree().process_frame
		await get_tree().process_frame
	var scrolls := current_screen.find_children("*", "ScrollContainer", true, false)
	_probe_check(not scrolls.is_empty(), "the campaign screen has a scroll container")
	if scrolls.is_empty():
		_probe_finish("campaign_list")
		return
	var scroll := scrolls[0] as ScrollContainer
	var list := scroll.get_child(0) as Control
	var cards := 0
	for child in list.get_children():
		if child is PanelContainer:
			cards += 1
	var buttons := _probe_buttons(self, "New game")
	print("LIST cards=%d buttons=%d scroll_max=%d page=%d h_max=%d h_page=%d viewport=%s list=%s follow=%s scale=%.2f window=%s" % [
		cards, buttons.size(), int(scroll.get_v_scroll_bar().max_value), int(scroll.get_v_scroll_bar().page),
		int(scroll.get_h_scroll_bar().max_value), int(scroll.get_h_scroll_bar().page),
		str(scroll.size), str(list.size), str(scroll.follow_focus), float(Game.settings.get("text_scale", 1.0)), str(get_window().size)])
	_probe_check(cards >= 6, "the profile lists enough campaigns to exceed one screen")
	_probe_check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "the list is taller than the viewport")
	var last_button: Button = buttons[buttons.size() - 1] if not buttons.is_empty() else null
	_probe_check(last_button != null, "an off-screen campaign has an action")
	if last_button != null:
		last_button.grab_focus()
		await get_tree().process_frame
		await get_tree().process_frame
		var view := scroll.get_global_rect()
		var focus_rect := last_button.get_global_rect()
		print("LIST focus pos=%s scroll=%d viewport_top=%d viewport_bottom=%d" % [str(focus_rect.position), int(scroll.scroll_vertical), int(view.position.y), int(view.end.y)])
		_probe_check(scroll.scroll_vertical > 0, "focused off-screen action scrolls into view")
		_probe_check(focus_rect.position.y >= view.position.y and focus_rect.end.y <= view.end.y, "the focused action is inside the viewport")
		_probe_check(focus_rect.position.x >= view.position.x and focus_rect.end.x <= view.end.x, "the focused action is horizontally reachable")
	_probe_check(scroll.get_h_scroll_bar().max_value <= scroll.get_h_scroll_bar().page, "the list does not require horizontal scrolling")
	if capture_dir != "":
		await _capture_viewport("campaign_list_bottom")
		return
	_probe_finish("campaign_list")


func _compat_ui_fixture() -> Dictionary:
	var id := "qa_compat_ui"
	CampaignStore.delete_user_campaign(id)
	SaveSystem.delete_save_everywhere("slot2")
	Game.refresh_campaigns()
	var made := CampaignStore.create("Compatibility UI", id)
	if not bool(made.get("ok", false)):
		return {}
	Game.refresh_campaigns()
	var pkg := CampaignStore.package_dir(id)
	var draft: Dictionary = Dictionary(CampaignStore.load_package(id).get("draft", {}))
	CampaignStore.add_area(draft, "Second Area")
	CampaignStore.add_flag_definition(draft, "compat_flag", "compat")
	var written := CampaignStore.write_package(draft)
	if not bool(written.get("ok", false)):
		return {}
	Game.refresh_campaigns()
	if not bool(Game.load_campaign(id).get("ok", false)):
		return {}
	Game.new_game(["kaelen"], 4242)
	Game.flags["compat_flag"] = true
	if not bool(Game.travel_to("area_02", Vector2i(2, 3), 2).get("ok", false)):
		return {}
	if not bool(Game.save_game("slot2").get("ok", false)):
		return {}
	return {
		"id": id,
		"pkg": pkg,
		"area_path": pkg.path_join("areas").path_join("area_02.json"),
		"save_path": SaveSystem.path_for("slot2", id),
	}


func _compat_press_load(slot: String) -> String:
	_open_load_modal()
	await get_tree().process_frame
	await get_tree().process_frame
	if modal == null:
		return "load modal did not open"
	var pressed := false
	for node in modal.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == "Load":
			button.pressed.emit()
			pressed = true
			break
	if not pressed:
		return "load modal has no Load button"
	await get_tree().process_frame
	await get_tree().process_frame
	var status := ""
	if modal != null:
		for node in modal.find_children("*", "Label", true, false):
			var label := node as Label
			if label != null and label.text != "":
				status = label.text
	return status


## Drives the ordinary Load modal: a harmless edit loads, a blocked saved cell is
## refused with its message visible, the save survives, and restoring the area
## recovers the same progress.
func _save_compat_ui_probe() -> void:
	probe_scenario = "save_compat_ui"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	var fixture := _compat_ui_fixture()
	_probe_check(not fixture.is_empty(), "disposable campaign, save and second area exist")
	if fixture.is_empty():
		_probe_finish("save_compat_ui")
		return
	var id := String(fixture["id"])
	var area_path := String(fixture["area_path"])
	var save_path := String(fixture["save_path"])
	var original_save := _probe_bytes(save_path)
	# A real supported prose edit precedes the harmless UI load.
	var manifest := _probe_read_json(String(fixture["pkg"]).path_join("campaign.json"))
	manifest["description"] = "Compatibility UI prose changed."
	_probe_write_json(String(fixture["pkg"]).path_join("campaign.json"), manifest)
	Game.refresh_campaigns()
	Game.load_campaign(id)

	var harmless := await _compat_press_load("slot2")
	print("UI COMPAT harmless status=%s pos=%s" % [harmless, str(Game.position)])
	_probe_check(modal == null, "ordinary Load modal loads the harmless save and closes")
	_probe_check(Game.position == Vector2i(2, 3), "harmless load restores the saved cell")
	close_modal()

	var area := _probe_read_json(area_path)
	var rows: Array = area["rows"]
	var row := String(rows[3])
	rows[3] = row.substr(0, 2) + "#" + row.substr(3)
	area["rows"] = rows
	_probe_write_json(area_path, area)
	Game.refresh_campaigns()
	Game.load_campaign(id)
	var before_position := Game.position
	var refused := await _compat_press_load("slot2")
	print("UI COMPAT refused status=%s pos=%s bytes_same=%s" % [refused, str(Game.position), str(_probe_bytes(save_path) == original_save)])
	_probe_check(refused.contains("blocked") and refused.contains("area_02"), "refusal names the blocked saved location")
	_probe_check(modal != null, "the Load modal stays open after refusal")
	_probe_check(Game.position == before_position, "refusal leaves the live session untouched")
	_probe_check(Game.campaign_id == id, "refusal leaves the current campaign untouched")
	_probe_check(_probe_bytes(save_path) == original_save, "refusal leaves the save bytes untouched")
	close_modal()

	rows[3] = row
	area["rows"] = rows
	_probe_write_json(area_path, area)
	Game.refresh_campaigns()
	Game.load_campaign(id)
	var recovered := await _compat_press_load("slot2")
	print("UI COMPAT recovered status=%s pos=%s" % [recovered, str(Game.position)])
	_probe_check(modal == null and Game.position == Vector2i(2, 3), "restoring compatible content recovers the save")
	close_modal()

	# Interrupted write: the primary is gone and the backup holds the same save.
	# The list names the source, the load succeeds, and its message stays open
	# because the restored game is already live behind the panel.
	var backup_path := save_path + ".bak"
	var temp_path := save_path + ".tmp"
	_write_probe_text(backup_path, original_save)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	Game.load_campaign(id)
	_open_load_modal()
	await get_tree().process_frame
	await get_tree().process_frame
	_probe_check(_probe_label_contains(modal, "(from backup)"), "the Load list names the backup")
	var backup_status := await _compat_press_load("slot2")
	print("UI COMPAT backup status=%s pos=%s" % [backup_status, str(Game.position)])
	_probe_check(backup_status.contains("from its backup"), "the recovered load names its source")
	_probe_check(modal != null, "the recovered load leaves its message open")
	_probe_check(Game.position == Vector2i(2, 3), "the backup restores the saved cell")
	_probe_check(_probe_bytes(backup_path) == original_save, "the backup keeps its bytes")
	_probe_check(not FileAccess.file_exists(save_path), "loading does not promote the backup")
	close_modal()

	# A readable primary that is newer keeps the refusal even with a good backup.
	var newer: Dictionary = _probe_read_json(backup_path)
	newer["save_version"] = 99
	_probe_write_json(save_path, newer)
	var newer_status := await _compat_press_load("slot2")
	print("UI COMPAT newer primary status=%s" % newer_status)
	_probe_check(newer_status.contains("incompatible version"), "a newer primary keeps its refusal")
	_probe_check(modal != null, "the refusal keeps the Load modal open")
	_probe_check(_probe_bytes(backup_path) == original_save, "the refused load leaves the backup alone")
	close_modal()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	# With no readable backup, the temp file of the interrupted write stands in.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	_write_probe_text(temp_path, original_save)
	var temp_status := await _compat_press_load("slot2")
	print("UI COMPAT temp status=%s pos=%s" % [temp_status, str(Game.position)])
	_probe_check(temp_status.contains("unfinished write"), "the temp stands in when no backup reads")
	_probe_check(Game.position == Vector2i(2, 3), "the temp restores the saved cell")
	close_modal()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))

	# Two interruptions leave the committed copy under a working name next to a
	# damaged canonical backup: it must be discovered, not called an empty slot.
	_write_probe_text(save_path + ".bak", "not json")
	_write_probe_text(save_path + ".bak.2", original_save)
	var working_status := await _compat_press_load("slot2")
	print("UI COMPAT working copy status=%s pos=%s" % [working_status, str(Game.position)])
	_probe_check(working_status.contains("from its backup"), "a working backup copy is discovered")
	_probe_check(Game.position == Vector2i(2, 3), "the working backup restores the saved cell")
	_probe_check(modal != null, "the working-copy load leaves its message open")
	close_modal()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".bak.2"))

	# An incompatible copy with no primary keeps its refusal, and the row says so.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var incompatible: Dictionary = JSON.parse_string(original_save)
	incompatible["save_version"] = 99
	_probe_write_json(save_path + ".bak", incompatible)
	_open_load_modal()
	await get_tree().process_frame
	await get_tree().process_frame
	_probe_check(_probe_label_contains(modal, "(unreadable)"), "an unreadable-only slot is tagged")
	var incompatible_status := await _compat_press_load("slot2")
	print("UI COMPAT incompatible-only status=%s" % incompatible_status)
	_probe_check(incompatible_status.contains("incompatible version"), "an incompatible-only slot keeps its refusal")
	_probe_check(modal != null, "the incompatible-only refusal keeps the modal open")
	close_modal()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".bak"))

	# A hand-made archive with a slot-like name is not recovery and is not listed.
	_write_probe_text(save_path + ".2026-11-20", original_save)
	var stray_rows := 0
	for save_row in Game.list_saves():
		if String(Dictionary(save_row)["slot"]) == "slot2":
			stray_rows += 1
	_probe_check(stray_rows == 0, "a stray slot-like name does not list the slot")
	var stray_load := Game.load_game("slot2")
	_probe_check(not bool(stray_load.get("ok", false)) and String(stray_load.get("message", "")).contains("No save in"), "a stray slot-like name is not recovery")
	_probe_check(Panels._save_info("slot2") == "empty", "only a stray file reads as an empty slot")
	_probe_check(Game.position == Vector2i(2, 3), "the stray load changes nothing")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".2026-11-20"))
	_write_probe_text(save_path, original_save)
	Game.load_campaign(id)

	if capture_dir != "":
		rows[3] = row.substr(0, 2) + "#" + row.substr(3)
		area["rows"] = rows
		_probe_write_json(area_path, area)
		Game.refresh_campaigns()
		Game.load_campaign(id)
		await _compat_press_load("slot2")
		await _capture_viewport("save_compat_refusal")
		return
	CampaignStore.delete_user_campaign(id)
	SaveSystem.delete_save_everywhere("slot2")
	Game.load_campaign("ravenloft_demo")
	_probe_finish("save_compat_ui")


## Drives the real Settings modal at the requested text scale with a settings
## file that is newer than this build: the read-only notice must be visible
## without scrolling, inside the panel, outside the scrolling body, and it must
## survive a panel refresh without freezing the controls.
func _settings_notice_probe() -> void:
	probe_scenario = "settings_notice"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	if probe_text_scale > 0.0:
		# The scale itself is exercised through the player-facing slider by the
		# layout probes; this probe pins the scale it measures.
		Game.settings["text_scale"] = probe_text_scale
		_apply_theme()
		await get_tree().process_frame
	Game.settings_newer = true
	_open_settings()
	for i in 6:
		await get_tree().process_frame
	_probe_check(modal != null, "the Settings modal opens")
	if modal == null:
		_probe_finish("settings_notice")
		return
	var notice := modal.find_child("ModalNotice", true, false) as Label
	_probe_check(notice != null and notice.text.contains("not written"), "the read-only notice is shown")
	if notice == null:
		_probe_finish("settings_notice")
		return
	var panel: Control = notice.get_parent()
	while panel != null and not (panel is PanelContainer):
		panel = panel.get_parent()
	_probe_check(panel != null, "the notice lives in the modal panel")
	if panel == null:
		_probe_finish("settings_notice")
		return
	var rect := notice.get_global_rect()
	var panel_rect := panel.get_global_rect()
	print("NOTICE scale=%s applied=%s notice=%s panel=%s" % [str(probe_text_scale), str(Game.settings.get("text_scale", 0.0)), str(rect), str(panel_rect)])
	_probe_check(rect.position.y >= panel_rect.position.y and rect.end.y <= panel_rect.end.y, "the notice stays inside the panel vertically")
	_probe_check(rect.position.x >= panel_rect.position.x and rect.end.x <= panel_rect.end.x, "the notice does not run off the panel")
	_probe_check(modal_scroll != null and not modal_scroll.is_ancestor_of(notice), "the notice is outside the scrolling body")
	if modal_scroll != null:
		_probe_check(rect.end.y <= modal_scroll.get_global_rect().position.y + 1.0, "the notice is visible without scrolling")
	var sliders := modal.find_children("*", "HSlider", true, false)
	_probe_check(not sliders.is_empty(), "the controls are still offered")
	Game.settings_newer = true
	refresh_modal()
	for i in 4:
		await get_tree().process_frame
	_probe_check(modal != null and modal.find_child("ModalNotice", true, false) != null, "the notice survives a panel refresh")
	close_modal()
	Game.settings_newer = false
	_probe_finish("settings_notice")


func _compat_reload(id: String) -> Dictionary:
	Game.refresh_campaigns()
	var campaign_load := Game.load_campaign(id)
	if not bool(campaign_load.get("ok", false)):
		return {"ok": false, "message": campaign_load.get("message", ""), "stage": "campaign"}
	return Game.load_game("slot2")


func _write_probe_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _probe_label_contains(root: Node, needle: String) -> bool:
	if root == null:
		return false
	if root is Label and String((root as Label).text).contains(needle):
		return true
	for child in root.get_children():
		if _probe_label_contains(child, needle):
			return true
	return false


func _probe_buttons(root: Node, text: String) -> Array:
	var found: Array = []
	if root == null:
		return found
	for child in root.find_children("*", "Button", true, false):
		if String((child as Button).text) == text:
			found.append(child)
	return found


## Asserts the encounter-end distinction that the nonlethal UI probe does not
## reach: a paralysed enemy does not end the fight or pay rewards, the ordinary
## turn loop lets the paralysis expire, and only a real defeat resolves it once.
func _encounter_end_probe() -> void:
	probe_scenario = "encounter_end"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	var started_new := Game.new_game(["kaelen", "aldric"], 9191)
	_probe_check(bool(started_new.get("ok", false)), "a QA party starts")
	var started := Game.start_encounter("qa_victory")
	_probe_check(bool(started.get("ok", false)), "the QA victory encounter starts")
	var e := Game.encounter
	if e == null:
		_probe_check(false, "the encounter exists")
		_probe_finish("encounter_end")
		return
	var enemy: Character = null
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			enemy = entry["char"]
	_probe_check(enemy != null, "the QA encounter has an enemy")
	if enemy == null:
		_probe_finish("encounter_end")
		return
	var xp_before: int = int(Game.party[0].xp)
	enemy.add_effect("paralyzed", "Paralysed", 2)
	e._check_end()
	_probe_check(not e.finished, "temporary paralysis does not end the encounter")
	_probe_check(int(Game.party[0].xp) == xp_before, "temporary paralysis pays no XP")
	var guard := 0
	while enemy.has_condition("paralyzed") and guard < 12:
		guard += 1
		e.end_turn()
		e.auto_advance()
	_probe_check(not enemy.has_condition("paralyzed"), "the paralysis expires through the turn loop")
	_probe_check(not e.finished, "the encounter is unresolved after the recovery")
	e._check_end()
	_probe_check(not e.finished, "recovery alone does not resolve the fight")
	enemy.apply_nonlethal(enemy.hp + 1)
	e._check_end()
	_probe_check(e.finished and String(e.outcome) == "victory", "a real defeat resolves in victory")
	var xp_after: int = int(Game.party[0].xp)
	_probe_check(xp_after == xp_before + int(e.xp_award), "victory pays XP once")
	e.changed.emit()
	_probe_check(int(Game.party[0].xp) == xp_after, "the same resolution cannot pay twice")
	_probe_finish("encounter_end")


func _trip_probe(scenario: String) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = scenario
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	# Match the shipped window so every click coordinate is the real layout.
	get_window().size = Vector2i(1280, 720)
	for i in 6:
		await get_tree().process_frame
	print("PROBE VIEWPORT=%s" % str(get_viewport().get_visible_rect().size))
	var combat := current_screen
	if combat == null or Game.encounter == null:
		_probe_check(false, "combat screen with an encounter exists")
		_probe_finish(scenario)
		return
	var e := Game.encounter
	var enemy: Character = null
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			enemy = entry["char"]
			break
	var actor := e.active_character()
	_probe_check(actor != null, "an active character exists")
	_probe_check(
		actor != null and actor.display_name == "QA Trip Fighter", "the fixture actor is active"
	)
	_probe_check(enemy != null, "the fixture has an enemy")
	_probe_check(e.is_player_turn(), "the fixture starts on the party turn")
	print(
		"PROBE START scenario=%s actor=%s enemy=%s prone=%s"
		% [
			scenario,
			str(actor.display_name) if actor != null else "none",
			str(enemy.display_name) if enemy != null else "none",
			str(actor.is_prone()) if actor != null else "none",
		]
	)
	await _probe_shot(scenario, "00_start")
	var trip_button := _probe_button(combat.button_box, "Trip")
	var attack_button := _probe_button(combat.button_box, "Attack")
	var end_button := _probe_button(combat.button_box, "End turn")
	match scenario:
		"success":
			await _probe_click(trip_button, "Trip")
			await _probe_click(combat.trip_weapon_check, "trip weapon")
			await _probe_click_cell(combat, e.cell_of(enemy), "trip target")
			await _probe_shot(scenario, "01_tripped")
			_probe_tail("after trip")
			_probe_check(enemy.is_prone(), "the target is prone")
			_probe_check(not e.has_pending_decision(), "no decision is pending")
			_probe_check(bool(e.turn_state["standard_used"]), "the trip spent the standard action")
			_probe_check(e.active_character() == actor, "the trip does not end the turn")
			_probe_check(_probe_log_contains(e, "is tripped"), "the trip is logged")
			var hp_after_trip := enemy.hp
			await _probe_shot(scenario, "02_attack_prone_target")
			_probe_tail("after trip")
			_probe_check(attack_button.disabled, "a spent standard action disables Attack")
			_probe_check(enemy.hp == hp_after_trip, "a spent standard action refuses a second attack")
		"touch_fail":
			await _probe_click(trip_button, "Trip")
			await _probe_click(combat.trip_weapon_check, "trip weapon")
			await _probe_click_cell(combat, e.cell_of(enemy), "trip target")
			await _probe_shot(scenario, "01_missed")
			_probe_tail("after missed trip")
			_probe_check(not enemy.is_prone(), "a missed touch attack does not trip")
			_probe_check(
				bool(e.turn_state["standard_used"]), "the attempt still spends the standard action"
			)
			_probe_check(_probe_log_contains(e, "touch attack misses"), "the miss is logged")
			_probe_check(not e.has_pending_decision(), "no decision follows a miss")
		"counter_drop", "counter_keep", "return":
			await _probe_click(trip_button, "Trip")
			await _probe_click(combat.trip_weapon_check, "trip weapon")
			await _probe_click_cell(combat, e.cell_of(enemy), "trip target")
			await _probe_shot(scenario, "01_decision")
			_probe_tail("decision pending")
			_probe_check(e.has_pending_decision(), "the counter-trip pauses for a decision")
			_probe_check(
				String(e.pending_trip.get("type", "")) == "weapon_release",
				"the pending decision is the weapon-release choice",
			)
			_probe_check(bool(e.turn_state["standard_used"]), "the trip action is already spent")
			var hp_at_decision := enemy.hp
			var choice := "Keep weapon" if scenario != "counter_drop" else "Drop weapon"
			await _probe_click(_probe_button(combat.decision_box, choice), choice)
			await _probe_shot(scenario, "02_resolved")
			_probe_tail("after decision")
			_probe_check(not e.has_pending_decision(), "the decision clears")
			_probe_check(enemy.hp == hp_at_decision, "the trip itself deals no damage")
			if scenario == "counter_drop":
				_probe_check(not actor.is_prone(), "dropping the weapon keeps the actor standing")
				_probe_check(actor.equipped("weapon").is_empty(), "the weapon is no longer equipped")
				_probe_check(e.ground_items.size() == 1, "the dropped weapon is on the ground once")
				if e.ground_items.size() == 1:
					_probe_check(
						String(e.ground_items[0]["id"]) == "light_flail",
						"the ground item is the dropped flail",
					)
				_probe_check(
					actor.inventory_count("light_flail") == 0, "the drop does not duplicate the item"
				)
				await _probe_click(_probe_button(combat.button_box, "Pick up"), "Pick up")
				await _probe_shot(scenario, "03_picked_up")
				_probe_check(actor.inventory_count("light_flail") == 1, "Pick up recovers the weapon")
				_probe_check(e.ground_items.is_empty(), "the recovered item leaves the ground")
				_probe_check(actor.equipped("weapon").is_empty(), "the recovered item is not equipped")
			else:
				_probe_check(actor.is_prone(), "keeping the weapon means being tripped")
				_probe_check(not actor.equipped("weapon").is_empty(), "the weapon is retained")
				_probe_check(e.ground_items.is_empty(), "nothing was dropped")
			if scenario == "counter_keep":
				await _probe_click(_probe_button(combat.button_box, "Stand up"), "Stand up")
				await _probe_shot(scenario, "03_stood_up")
				_probe_check(not actor.is_prone(), "Stand up clears prone")
				_probe_check(bool(e.turn_state["move_used"]), "Stand up spends the move action")
			if scenario == "return":
				# Trip spent the standard action; end the turn so the enemy acts and
				# control visibly returns before the finishing attack.
				await _probe_click(end_button, "End turn")
				for i in 8:
					await get_tree().process_frame
				await _probe_shot(scenario, "03_new_round")
				_probe_check(e.active_character() == actor, "the turn returns to the party")
				await _probe_click(attack_button, "Attack")
				await _probe_click_cell(combat, e.cell_of(enemy), "attack target")
				await _probe_shot(scenario, "04_victory")
				print("PROBE MODE AFTER=%s" % Game.mode)
				_probe_check(enemy.has_condition("dead"), "the enemy is defeated")
				_probe_check(Game.mode == "explore", "victory returns to exploration")
		"prone":
			_probe_check(actor.is_prone(), "the fixture actor starts prone")
			await _probe_click(attack_button, "Attack")
			await _probe_click_cell(combat, e.cell_of(enemy), "attack target")
			await _probe_shot(scenario, "01_prone_attack")
			_probe_check(
				bool(e.turn_state["standard_used"]), "the prone attack spends the standard action"
			)
			await _probe_click(_probe_button(combat.button_box, "Stand up"), "Stand up")
			await _probe_shot(scenario, "02_stood_up")
			_probe_check(not actor.is_prone(), "Stand up clears prone")
			_probe_check(bool(e.turn_state["move_used"]), "Stand up spends the move action")
		"stand_aoo":
			await _probe_click(_probe_button(combat.button_box, "Stand up"), "Stand up")
			await _probe_shot(scenario, "01_aoo_and_stand")
			_probe_tail("after stand up")
			_probe_check(_probe_log_contains(e, "Attack of opportunity"), "standing up provokes")
			_probe_check(_probe_log_contains(e, "back on their feet"), "the actor stands")
			_probe_check(not actor.is_prone(), "the actor is no longer prone")
		"pickup":
			await _probe_click(_probe_button(combat.button_box, "Pick up"), "Pick up")
			await _probe_shot(scenario, "01_first_pickup")
			_probe_check(bool(e.turn_state["move_used"]), "the first pickup spends the move action")
			_probe_check(actor.inventory_count("dagger") == 1, "the dagger is recovered")
			_probe_check(actor.equipped("weapon").is_empty(), "the recovered dagger is unequipped")
			await _probe_click(_probe_button(combat.button_box, "Pick up"), "Pick up again")
			await _probe_shot(scenario, "02_second_pickup")
			_probe_tail("after pickups")
			_probe_check(e.ground_items.is_empty(), "both ground items are recovered")
			_probe_check(actor.inventory_count("light_flail") == 1, "the flail is recovered once")
			_probe_check(
				bool(e.turn_state["standard_used"]), "the second pickup spends the standard action"
			)
		"crawl":
			# A 5-ft step is refused while prone, so the control is disabled; record
			# that state, then crawl into an empty square with the Move control.
			var step_button := _probe_button(combat.button_box, "5-ft step")
			_probe_check(
				step_button != null and step_button.disabled, "a 5-ft step is refused while prone"
			)
			await _probe_shot(scenario, "01_step_refused")
			var start_cell := e.cell_of(actor)
			await _probe_click(_probe_button(combat.button_box, "Move"), "Move")
			await _probe_click_cell(combat, start_cell + Vector2i(1, 0), "crawl square")
			await _probe_shot(scenario, "02_crawled")
			_probe_tail("after crawl")
			_probe_check(
				e.cell_of(actor) == start_cell + Vector2i(1, 0), "the actor crawls one square"
			)
			_probe_check(actor.is_prone(), "crawling does not clear prone")
			_probe_check(bool(e.turn_state["move_used"]), "crawling spends the move action")
		"improved_trip", "improved_trip_decline":
			await _probe_click(trip_button, "Trip")
			await _probe_click_cell(combat, e.cell_of(enemy), "trip target")
			await _probe_shot(scenario, "01_grant")
			_probe_tail("after qualifying trip")
			_probe_check(enemy.is_prone(), "the trip knocks the target prone")
			_probe_check(bool(e.turn_state["standard_used"]), "the trip spent the standard action")
			_probe_check(
				String(e.pending_trip.get("type", "")) == "improved_trip_attack",
				"Improved Trip pauses with the granted attack",
			)
			_probe_check(e.active_character() == actor, "the grant belongs to the acting character")
			_probe_check(
				not _probe_log_contains(e, "Attack of opportunity"),
				"the unarmed trip does not provoke",
			)
			_probe_check(
				_probe_button(combat.decision_box, "Decline extra attack") != null,
				"the decision panel offers declining",
			)
			var hp_before_follow := enemy.hp
			if scenario == "improved_trip":
				await _probe_click(
					_probe_button(combat.decision_box, "Make the extra attack"), "extra attack"
				)
				await _probe_shot(scenario, "02_follow_up")
				_probe_tail("after follow-up")
				_probe_check(not e.has_pending_decision(), "the follow-up clears the decision")
				_probe_check(
					_probe_log_contains(e, "Improved Trip grants an immediate melee attack"),
					"the granted attack is resolved",
				)
				_probe_check(enemy.hp <= hp_before_follow, "the follow-up never heals the target")
				_probe_check(
					bool(e.turn_state["standard_used"]),
					"the follow-up spends no second standard action",
				)
				# The extra attack is part of the trip action, so the standard action
				# stays spent: Attack must be unavailable, not offer a second attack.
				_probe_check(attack_button.disabled, "a spent standard action disables Attack")
				_probe_check(
					not e.has_pending_decision(), "the follow-up cannot recursively grant another"
				)
			else:
				await _probe_click(
					_probe_button(combat.decision_box, "Decline extra attack"), "decline"
				)
				await _probe_shot(scenario, "02_declined")
				_probe_tail("after declining")
				_probe_check(not e.has_pending_decision(), "declining clears the decision")
				_probe_check(enemy.hp == hp_before_follow, "declining rolls no attack")
				_probe_check(
					_probe_log_contains(e, "declines the Improved Trip follow-up attack"),
					"declining is logged",
				)
				_probe_check(
					not bool(e.turn_state["move_used"]), "declining leaves ordinary play available"
				)
		_:
			_probe_check(false, "scenario '%s' is known" % scenario)
	await _probe_shot(scenario, "99_end")
	print("PROBE DONE scenario=%s" % scenario)
	_probe_finish(scenario)


func _apply_theme() -> void:
	theme = ThemeBuilder.build(16)


func _clear_current() -> void:
	if current_screen != null:
		current_screen.queue_free()
		current_screen = null


func _set_screen(node: Control) -> void:
	_clear_current()
	current_screen = node
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(node)


# ---------------------------------------------------------------- menus

func _show_menu() -> void:
	close_modal()
	Game.training_mode = false
	awaiting_rebind = ""
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var glow := ColorRect.new()
	glow.color = Color(0.18, 0.22, 0.27, 0.55)
	glow.position = Vector2(0, 0)
	glow.size = Vector2(1280, 260)
	root.add_child(glow)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 560)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	box.add_child(ThemeBuilder.heading("RAVENLOFT FOUNDATION", 36))
	box.add_child(ThemeBuilder.body("A D&D 3.5 Ravenloft-inspired first-person RPG foundation", false, 18))
	var label := ThemeBuilder.body(
		"EXAMPLE CONTENT • PLACEHOLDER ART • NOT A COMPLETE CAMPAIGN",
		true,
		13
	)
	label.add_theme_color_override("font_color", ThemeBuilder.GOLD)
	box.add_child(label)
	box.add_child(ThemeBuilder.separator())
	var has_save := Game.has_any_save()
	var continue_button := Button.new()
	continue_button.text = "Continue from latest save"
	continue_button.disabled = not has_save
	continue_button.custom_minimum_size = Vector2(0, 44)
	continue_button.pressed.connect(_continue_game)
	box.add_child(continue_button)
	var new_button := Button.new()
	new_button.text = "Choose a campaign"
	new_button.custom_minimum_size = Vector2(0, 44)
	new_button.pressed.connect(func() -> void: _show_campaign_select())
	box.add_child(new_button)
	var load_button := Button.new()
	load_button.text = "Load game"
	load_button.custom_minimum_size = Vector2(0, 44)
	load_button.disabled = not has_save
	load_button.pressed.connect(func() -> void: _show_campaign_select())
	box.add_child(load_button)
	# Optional, clearly labelled rules demonstrations: real engine, example
	# content, no campaign progression and no campaign saves.
	var training_button := Button.new()
	training_button.text = "Combat Training / Rules Demonstrations"
	training_button.custom_minimum_size = Vector2(0, 44)
	training_button.pressed.connect(_show_training_menu)
	box.add_child(training_button)
	var settings_button := Button.new()
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(0, 44)
	settings_button.pressed.connect(_open_settings)
	box.add_child(settings_button)
	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(0, 44)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit_button)
	box.add_child(ThemeBuilder.separator())
	box.add_child(ThemeBuilder.body(
		"Move W/S • Strafe A/D • Turn Q/E • Interact F • Party Tab • Sheet C • Inventory I • Journal J • Pause Esc",
		true,
		13
	))
	if not Game.content.errors.is_empty():
		var error_text := "Content validation errors:\n" + "\n".join(Game.content.errors.slice(0, 4))
		var error_label := ThemeBuilder.body(error_text, true, 12)
		error_label.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		box.add_child(error_label)
	_set_screen(root)


## Visible entry for the optional demonstrations. It reuses the QA fixtures, so
## shipped pregens, encounters and campaign saves are untouched.
func _show_training_menu() -> void:
	open_modal("Combat Training — Rules Demonstrations", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		box.add_child(ThemeBuilder.body(
			"Optional demonstrations of implemented rules. They use a temporary fighter and example enemies — not campaign content, not campaign saves, and no shipped character's feats are changed.",
			true,
			13
		))
		var cleave := Button.new()
		cleave.text = "Cleave — drop an enemy, then attack another in reach"
		cleave.custom_minimum_size = Vector2(0, 44)
		cleave.pressed.connect(func() -> void:
			close_modal()
			_start_training("cleave")
		)
		box.add_child(cleave)
		var trip := Button.new()
		trip.text = "Improved Trip — trip, then the granted attack"
		trip.custom_minimum_size = Vector2(0, 44)
		trip.pressed.connect(func() -> void:
			close_modal()
			_start_training("improved_trip")
		)
		box.add_child(trip)
		var back := Button.new()
		back.text = "Back to menu"
		back.custom_minimum_size = Vector2(0, 44)
		back.pressed.connect(func() -> void:
			close_modal()
			_show_menu()
		)
		box.add_child(back)
		return box
	, 760, 340)


func _start_training(kind: String) -> void:
	Game.training_mode = true
	match kind:
		"cleave":
			_qa_cleave_demo("cleave")
		"improved_trip":
			_qa_trip_demo("improved_trip")
		_:
			Game.training_mode = false
			print("TRAINING FAILED: unknown demonstration '%s'" % kind)
			return
	if Game.mode == "combat":
		_show_combat()
	else:
		print("TRAINING FAILED: demonstration '%s' did not start combat" % kind)
		Game.training_mode = false


## QA helper: saves the actual game viewport to docs/screenshots and exits.
func _capture_viewport(capture_name: String) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	if current_screen != null:
		_dump_layout(current_screen, 0)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "res://docs/screenshots/%s.png" % capture_name
	if capture_dir != "":
		path = capture_dir.path_join("%s.png" % capture_name)
	var error := image.save_png(path)
	if error == OK:
		print("CAPTURED %s" % path)
	else:
		print("CAPTURE FAILED %d" % error)
	get_tree().quit()


func _dump_layout(node: Node, depth: int) -> void:
	if depth > 4:
		return
	if node is Control:
		print("LAYOUT %s%s %s size=%s min=%s" % [
			"  ".repeat(depth), node.get_class(), node.name, str(node.size), str(node.custom_minimum_size)
		])
	for child in node.get_children():
		_dump_layout(child, depth + 1)


func _start_demo(kind: String, party_ids: Array = ["kaelen", "sera", "aldric", "ysolde"]) -> void:
	var result := Game.new_game(party_ids, 424242)
	if not bool(result.get("ok", false)):
		return
	# Every command-line demonstration is QA evidence, not campaign play: it must
	# never autosave over a player's slots or grant campaign XP. Explicit QA slots
	# (for example `qa_turn`) are still written where a probe needs them.
	Game.training_mode = true
	match kind:
		"dialogue":
			Game.position = Vector2i(2, 10)
			Game.facing = Dungeon.NORTH
			Game.start_dialogue("miruna")
		"combat":
			Game.start_encounter("storeroom_dead")
		"power_attack":
			_qa_power_attack_demo()
		"combat_expertise":
			_qa_combat_expertise_demo()
		"trip":
			_qa_trip_demo(trip_scenario)
		"cleave":
			_qa_cleave_demo(cleave_scenario)
		"inspect":
			_qa_inspect_demo()
		"silence":
			# QA only: seed the broken-token, silent-bell state so the gated
			# epilogue row can be reached with ordinary input.
			Game.flags["maela_decision"] = true
			Game.flags["maela_mercy"] = true
			Game.flags["drowned_cleared"] = true
			Game.flags["bell_resolved"] = true
			Game.flags["bell_silenced"] = true
			Game.start_dialogue("maela_vey")
		"ranged":
			_qa_ranged_demo()
		"concentration":
			_qa_concentration_demo()
		"integration":
			_qa_integration_demo()
		"weapons":
			_qa_weapons_demo()
		"shield":
			_qa_shield_demo()
		"unarmed":
			_qa_unarmed_demo()
		"nonlethal":
			_qa_nonlethal_demo()
		"town_square":
			var moved := Game.travel_to("barovia_town_square", Vector2i(5, 9), Dungeon.NORTH)
			if not bool(moved.get("ok", false)):
				print("DEMO TOWN SQUARE FAILED: %s" % moved.get("message", ""))
		"turn_undead":
			# QA only: an isolated encounter with the cleric placed first in
			# initiative so the action can be exercised without waiting on a random
			# initiative order. The turning roll itself stays a real seeded roll.
			_qa_start_encounter("qa_turn_undead", "aldric")
		"turn_undead_save":
			# QA only: spend one daily use, round-trip it through the real save
			# system, then show the remaining allowance in combat.
			_qa_spend_turning_uses(1)
			var qa_saved := Game.save_game("qa_turn")
			var qa_loaded := Game.load_game("qa_turn")
			print("QA TURN SAVE: save=%s load=%s" % [qa_saved.get("ok"), qa_loaded.get("ok")])
			_qa_start_encounter("qa_turn_undead", "aldric")
		"turn_undead_rest":
			# QA only: spend two uses, then call the same recovery the shrine uses.
			_qa_spend_turning_uses(2)
			Game.rest_party(false)
			_qa_start_encounter("qa_turn_undead", "aldric")
		"victory_qa":
			# QA only: one adjacent 1-HP enemy so victory and its single reward can
			# be observed through the interface without replaying the E3 encounter.
			_qa_start_encounter("qa_victory", "kaelen")
			var ve := Game.encounter
			if ve != null:
				for entry in ve.combatants:
					if int(entry["team"]) == Encounter.TEAM_ENEMY:
						(entry["char"] as Character).hp = 1
		"defeat_qa":
			# QA only: defeat routing smoke check.
			_qa_start_encounter("qa_victory", "kaelen")
			var de := Game.encounter
			for ch in Game.party:
				ch.take_damage(ch.hp + 20)
			if de != null:
				de._check_end()
		_:
			pass
	_route()


## QA harness helpers. These place an encounter and its active combatant; they
## never change a rule, a roll or a modifier.
func _qa_start_encounter(encounter_id: String, actor_id: String) -> void:
	Game.start_encounter(encounter_id)
	var e := Game.encounter
	if e == null:
		return
	for i in e.order:
		var ch: Character = e.combatants[i]["char"]
		if ch.id == actor_id:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			Game.emit_signal("state_changed")
			return


func _qa_power_attack_demo() -> void:
	# Isolated QA fixture: derive a temporary fighter, do not edit a pregen.
	var data := Game.content.get_character("kaelen")
	var qa := Character.from_content(data, Game.content.items)
	qa.id = "qa_power_attacker"
	qa.display_name = "QA Power Attacker"
	qa.feats.clear()
	qa.feats.append("Power Attack")
	qa.equip("weapon", Game.content.get_item("dagger"))
	Game.party.clear()
	Game.party.append(qa)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA POWER ATTACK FAILED: encounter did not start")
		return
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			var enemy: Character = entry["char"]
			enemy.max_hp = 100
			enemy.hp = 100
			# QA-only target adjustments make the demonstration deterministic:
			# low AC so the seeded attack lands, and no DR so dagger damage is
			# visible. Shipped monster data is untouched.
			enemy.ac_misc = -5
			enemy.damage_reduction.clear()
			# The QA fixture starts turned so its next turn flees and provokes a
			# real opportunity attack from the committed Power Attack.
			enemy.add_effect("turned", "Turned", 10, "condition")
	for i in e.order:
		if e.combatants[i]["char"] == qa:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			break
	Game.emit_signal("state_changed")
	print("QA POWER ATTACK READY: dagger modes=melee/thrown, enemy adjacent and turned")


func _qa_combat_expertise_demo() -> void:
	# Isolated QA fixture: derive a temporary fighter, do not edit a pregen.
	var data := Game.content.get_character("kaelen")
	var qa := Character.from_content(data, Game.content.items)
	qa.id = "qa_expertise_fighter"
	qa.display_name = "QA Expertise Fighter"
	qa.abilities["int"] = 13
	qa.feats.clear()
	qa.feats.append("Combat Expertise")
	qa.feats.append("Power Attack")
	qa.equip("weapon", Game.content.get_item("masterwork_longsword"))
	Game.party.clear()
	Game.party.append(qa)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA COMBAT EXPERTISE FAILED: encounter did not start")
		return
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			var enemy: Character = entry["char"]
			enemy.max_hp = 100
			enemy.hp = 100
			enemy.ac_misc = -5
			enemy.damage_reduction.clear()
			enemy.add_effect("turned", "Turned", 10, "condition")
	# A second, not-turned enemy is appended for the incoming-attack check.
	# The first enemy flees and provokes the committed opportunity attack.
	var incoming := Character.from_content(
		Game.content.get_monster("zombie"), Game.content.items
	)
	incoming.id = "qa_expertise_incoming"
	incoming.display_name = "QA Incoming Zombie"
	incoming.max_hp = 100
	incoming.hp = 100
	incoming.ac_misc = -5
	incoming.damage_reduction.clear()
	e.add_combatant(incoming, Vector2i(3, 2), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	for i in e.order:
		if e.combatants[i]["char"] == qa:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			break
	Game.emit_signal("state_changed")
	print(
		"QA COMBAT EXPERTISE READY: CE/PA controls; attack, then End turn for AOO and incoming attack"
	)


## QA-only Cleave probe (--cleave-probe, variant via --cleave-scenario=<id>).
## Like the Trip probe it drives the real control tree with viewport mouse input
## and asserts outcomes; the fixture below only sets starting conditions.
func _cleave_probe(scenario: String) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = scenario
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 6:
		await get_tree().process_frame
	print("PROBE VIEWPORT=%s" % str(get_viewport().get_visible_rect().size))
	var combat := current_screen
	if combat == null or Game.encounter == null:
		_probe_check(false, "combat screen with an encounter exists")
		_probe_finish(scenario)
		return
	if scenario.begins_with("cleave_offturn"):
		await _cleave_probe_off_turn(scenario, combat)
		return
	var e := Game.encounter
	var actor := e.active_character()
	var enemies: Array = e.living_entries(Encounter.TEAM_ENEMY)
	_probe_check(actor != null and actor.display_name == "QA Cleave Fighter", "the fixture actor is active")
	_probe_check(enemies.size() >= 1, "the fixture has an enemy")
	_probe_check(e.is_player_turn(), "the fixture starts on the party turn")
	var first: Character = enemies[0]["char"]
	var second: Character = null
	if enemies.size() > 1:
		second = enemies[1]["char"]
	var step_button := _probe_button(combat.button_box, "5-ft step")
	var attack_button := _probe_button(combat.button_box, "Attack")
	await _probe_shot(scenario, "00_start")
	if scenario == "cleave_from_trip":
		await _probe_click(_probe_button(combat.button_box, "Trip"), "Trip")
		await _probe_click_cell(combat, e.cell_of(first), "trip target")
		await _probe_shot(scenario, "01_trip_grant")
		_probe_tail("after improved trip")
		_probe_check(
			String(e.pending_trip.get("type", "")) == "improved_trip_attack",
			"Improved Trip pauses for its attack choice",
		)
		_probe_check(step_button != null and step_button.disabled, "a 5-foot step is refused during the decision")
		await _probe_click(_probe_button(combat.decision_box, "Make the extra attack"), "extra attack")
	else:
		await _probe_click(attack_button, "Attack")
		await _probe_click_cell(combat, e.cell_of(first), "attack target")
	for i in 6:
		await get_tree().process_frame
	await _probe_shot(scenario, "02_trigger")
	_probe_tail("after triggering attack")
	_probe_check(first.hp < 0 or first.has_condition("dead"), "the first enemy dropped")
	if scenario == "cleave_no_target":
		_probe_check(not e.has_pending_decision(), "no Cleave decision without another target")
		_probe_check(Game.mode == "explore", "victory returns to exploration")
		await _probe_shot(scenario, "99_end")
		_probe_finish(scenario)
		return
	_probe_check(e.has_pending_decision(), "Cleave pauses for a decision")
	_probe_check(String(e.pending_cleave.get("type", "")) == "cleave_attack", "the pending decision is Cleave")
	_probe_check(e.cleave_used.is_empty(), "the use is not spent before the extra attack")
	_probe_check(second != null and not second.has_condition("dead"), "the second enemy is untouched")
	_probe_check(bool(e.turn_state["standard_used"]), "the triggering attack already spent the standard action")
	_probe_check(step_button != null and step_button.disabled, "a 5-foot step is refused before the extra attack")
	var target_button: Button = null
	if second != null:
		target_button = _probe_button(combat.decision_box, "Attack %s" % second.display_name)
	_probe_check(target_button != null, "the second enemy is offered")
	_probe_check(
		_probe_button(combat.decision_box, "Decline extra attack") != null, "declining is offered"
	)
	var hp_before := second.hp if second != null else 0
	if scenario == "cleave_decline":
		await _probe_scroll_sidebar(combat)
		await _probe_click(_probe_button(combat.decision_box, "Decline extra attack"), "decline")
		for i in 4:
			await get_tree().process_frame
		await _probe_shot(scenario, "03_declined")
		_probe_tail("after declining")
		_probe_check(not e.has_pending_decision(), "declining clears the decision")
		_probe_check(second != null and second.hp == hp_before, "declining leaves the second enemy untouched")
		_probe_check(e.cleave_used.is_empty(), "declining does not spend the round's Cleave")
		_probe_check(_probe_log_contains(e, "declines the Cleave attack"), "declining is logged")
		_probe_check(Game.mode == "combat", "declining returns to ordinary combat")
	else:
		await _probe_scroll_sidebar(combat)
		await _probe_click(target_button, "cleave target")
		for i in 8:
			await get_tree().process_frame
		await _probe_shot(scenario, "03_follow_through")
		_probe_tail("after cleave")
		_probe_check(not e.has_pending_decision(), "the extra attack clears the decision")
		_probe_check(
			second != null and (second.hp < hp_before or second.has_condition("dead")),
			"the extra attack resolves against the chosen enemy",
		)
		_probe_check(e.cleave_used.size() == 1, "the once-per-round use is consumed once")
		_probe_check(_probe_log_contains(e, "follows through"), "the extra attack is logged")
		_probe_check(Game.mode == "explore", "combat returns to exploration")
	await _probe_shot(scenario, "99_end")
	_probe_finish(scenario)


## Scrolls the combat sidebar so decision controls below the fold at 1024x600 or
## at the largest text scale are still reachable through real clicks.
func _probe_scroll_sidebar(combat: Control) -> void:
	var screen := combat as CombatScreen
	if screen == null or screen.sidebar_panel == null:
		return
	screen.sidebar_panel.scroll_vertical = 100000
	for i in 4:
		await get_tree().process_frame


## Off-turn Cleave: the engine triggered it from a real opportunity attack that
## dropped the fleeing mover; everything below is driven through the controls.
func _cleave_probe_off_turn(scenario: String, combat: Control) -> void:
	var e := Game.encounter
	var mover := e.active_character()
	_probe_check(mover != null and mover.display_name == "QA Cleave Mover", "the interrupted turn belongs to the mover")
	_probe_check(e.has_pending_decision(), "the off-turn drop offers Cleave")
	_probe_check(String(e.pending_cleave.get("type", "")) == "cleave_attack", "the pending decision is Cleave")
	_probe_check(bool(e.pending_cleave.get("off_turn", false)), "the decision is recorded as off turn")
	_probe_check(not e.off_turn_resume.is_empty(), "the interrupted route is recorded")
	await _probe_shot(scenario, "00_pending")
	await _probe_scroll_sidebar(combat)
	var second_button := _probe_button(combat.decision_box, "Attack QA Cleave Second")
	_probe_check(second_button != null, "the second enemy is offered")
	var decline := _probe_button(combat.decision_box, "Decline extra attack")
	_probe_check(decline != null, "declining is offered")
	var second: Character = null
	for entry in e.combatants:
		if (entry["char"] as Character).id == "qa_cleave_second":
			second = entry["char"]
			break
	var hp_before := second.hp if second != null else 0
	if scenario == "cleave_offturn_decline":
		await _probe_click(decline, "decline")
	else:
		await _probe_click(second_button, "cleave target")
	for i in 10:
		await get_tree().process_frame
	await _probe_shot(scenario, "01_resolved")
	_probe_tail("after off-turn cleave")
	_probe_check(not e.has_pending_decision(), "the decision is resolved")
	_probe_check(e.off_turn_resume.is_empty(), "the interrupted action is consumed")
	_probe_check(e.active_character() == null or e.active_character() != mover, "the interrupted turn finishes")
	if scenario == "cleave_offturn_decline":
		_probe_check(second != null and second.hp == hp_before, "declining leaves the second enemy untouched")
		_probe_check(e.cleave_used.is_empty(), "declining spends nothing")
	else:
		_probe_check(second != null and (second.hp < hp_before or second.has_condition("dead")), "the extra attack lands")
		# The interrupted sequence can roll the round over, which legitimately
		# resets the once-per-round track; the log proves the attack happened.
		_probe_check(_probe_log_contains(e, "follows through"), "the extra attack is logged")
	await _probe_shot(scenario, "99_end")
	_probe_finish(scenario)


## Verifies the visible training entry: main menu -> Combat Training -> Cleave.
func _training_probe() -> void:
	probe_scenario = "training_entry"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 6:
		await get_tree().process_frame
	var entry := _probe_button(self, "Combat Training / Rules Demonstrations")
	_probe_check(entry != null, "the training entry is on the main menu")
	await _probe_click(entry, "Combat Training")
	for i in 4:
		await get_tree().process_frame
	var cleave := _probe_button(self, "Cleave — drop an enemy, then attack another in reach")
	_probe_check(cleave != null, "the Cleave demonstration is listed")
	await _probe_click(cleave, "Cleave demonstration")
	for i in 12:
		await get_tree().process_frame
	_probe_check(Game.mode == "combat", "the demonstration starts combat")
	_probe_check(Game.training_mode, "training mode is marked (no campaign save or XP)")
	_probe_check(
		Game.encounter != null and Game.encounter.active_character() != null,
		"an encounter is running",
	)
	await _probe_shot("training", "00_start")
	_probe_finish("training_entry")


## QA-only enemy-inspection fixture (--demo-inspect). Two defenders with
## different Dexterity modifiers: a Sera-derived duelist (+3 Dexterity and the
## Dodge feat) whose AC must drop while flat-footed, and a zombie (-1 Dexterity)
## whose AC must not change. The fixture never edits a roll or an outcome; it
## only places combatants and re-runs the ordinary initiative path.
func _qa_inspect_demo() -> void:
	var fighter := Character.from_content(Game.content.get_character("kaelen"), Game.content.items)
	fighter.id = "qa_inspect_fighter"
	fighter.display_name = "QA Inspect Fighter"
	Game.party.clear()
	Game.party.append(fighter)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA INSPECT FAILED: encounter did not start")
		return
	var duelist := Character.from_content(Game.content.get_character("sera"), Game.content.items)
	duelist.id = "qa_inspect_duelist"
	duelist.display_name = "QA Inspect Duelist"
	duelist.max_hp = 60
	duelist.hp = 60
	e.add_combatant(duelist, Vector2i(3, 3), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	var zombie: Character = null
	for entry in e.combatants:
		var ch: Character = entry["char"]
		if int(entry["team"]) == Encounter.TEAM_ENEMY and ch.id != "qa_inspect_duelist":
			zombie = ch
			entry["cell"] = Vector2i(3, 2)
	if zombie != null:
		zombie.id = "qa_inspect_zombie"
		zombie.display_name = "QA Inspect Zombie"
		zombie.max_hp = 60
		zombie.hp = 60
	e.combatants[0]["cell"] = Vector2i(2, 3)
	# Re-run the real initiative path until the party fighter is first, so both
	# defenders are genuinely flat-footed when the probe inspects them. No flag is
	# hand-set and no roll is changed.
	var party_first := false
	for attempt in 80:
		e.begin()
		if e.active_character() == fighter and not e.finished:
			party_first = true
			break
	print(
		"QA INSPECT READY: party_first=%s duelist_flat=%d duelist_standing=%d zombie_flat=%d zombie_standing=%d"
		% [
			str(party_first),
			Rules.armor_class(duelist, {"flat_footed": true}),
			Rules.armor_class(duelist),
			Rules.armor_class(zombie, {"flat_footed": true}) if zombie != null else -1,
			Rules.armor_class(zombie) if zombie != null else -1,
		]
	)


## QA-only (--inspect-probe). Drives the real combat window: opens the enemy
## inspection panel through its row button, reads the rendered text, sets the text
## size through the Settings slider, and re-opens the panel after the defenders'
## first turn. Captures every state under --trip-shots=<dir>.
func _inspect_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "inspect"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var combat := current_screen
	if combat == null or Game.encounter == null:
		_probe_check(false, "combat screen with an encounter exists")
		_probe_finish("inspect")
		return
	var e := Game.encounter
	var duelist: Character = null
	var zombie: Character = null
	for entry in e.combatants:
		var ch: Character = entry["char"]
		if ch.id == "qa_inspect_duelist":
			duelist = ch
		elif ch.id == "qa_inspect_zombie":
			zombie = ch
	_probe_check(duelist != null and zombie != null, "both inspection defenders exist")
	if duelist == null or zombie == null:
		_probe_finish("inspect")
		return
	_probe_check(
		e.active_character() != null and e.active_character().id == "qa_inspect_fighter",
		"the party fighter acts first, so both defenders are still flat-footed",
	)
	var duelist_index := int(e.entry_for(duelist)["index"])
	var zombie_index := int(e.entry_for(zombie)["index"])
	_probe_check(e.is_flat_footed(duelist_index), "the duelist is flat-footed before its first turn")
	_probe_check(e.is_flat_footed(zombie_index), "the zombie is flat-footed before its first turn")
	await _probe_shot("inspect", "00_start")
	# ------------------------------------------- clicking a party token is free
	# Report triage (2026-11-14): clicking a party token opens that adventurer's
	# sheet. It must not spend the turn, roll anything or hand the initiative on,
	# so the grid click a player would make is replayed here and the encounter is
	# required to be identical afterwards.
	var fighter: Character = e.active_character()
	var fighter_cell: Vector2i = e.cell_of(fighter)
	var round_before := e.round_number
	var turn_before := int(e.order[e.turn_ptr])
	var state_before := Dictionary(e.turn_state).duplicate(true)
	var hp_before: Array = []
	for entry in e.combatants:
		hp_before.append(int((entry["char"] as Character).hp))
	var log_before := e.log_lines.size()
	await _probe_click_cell(combat, fighter_cell, "party token %s" % fighter.display_name)
	for i in 5:
		await get_tree().process_frame
	_probe_check(modal != null, "clicking a party token opens the character sheet")
	_probe_check(e.round_number == round_before, "the round is unchanged by opening a sheet")
	_probe_check(
		int(e.order[e.turn_ptr]) == turn_before,
		"the active combatant is unchanged by opening a sheet",
	)
	_probe_check(
		Dictionary(e.turn_state) == state_before,
		"no movement or action is spent by opening a sheet",
	)
	var hp_after: Array = []
	for entry in e.combatants:
		hp_after.append(int((entry["char"] as Character).hp))
	_probe_check(hp_after == hp_before, "no combatant's hit points change by opening a sheet")
	_probe_check(e.log_lines.size() == log_before, "opening a sheet writes no combat log line")
	await _probe_shot("inspect", "00b_party_token_sheet")
	await _probe_close_modal()
	_probe_check(
		e.round_number == round_before and int(e.order[e.turn_ptr]) == turn_before,
		"closing the sheet leaves the same turn open",
	)
	_probe_check(
		Dictionary(e.turn_state) == state_before,
		"closing the sheet spends nothing either",
	)
	# ---------------------------------------------------------------- panel, 1.0x
	await _probe_open_inspect(combat, duelist)
	var duelist_flat := CombatScreen.effective_ac(duelist, true)
	_probe_check(
		_probe_modal_ac_line().contains("AC %d (flat-footed)" % duelist_flat),
		"the panel shows %d and the flat-footed marker" % duelist_flat,
	)
	_probe_check(
		duelist_flat < CombatScreen.effective_ac(duelist, false),
		"the flat-footed AC is lower for a positive Dexterity modifier",
	)
	await _probe_shot("inspect", "01_panel_flat")
	await _probe_close_modal()
	await _probe_open_inspect(combat, zombie)
	_probe_check(
		_probe_modal_ac_line().contains("AC %d (flat-footed)" % CombatScreen.effective_ac(zombie, true)),
		"the panel also marks the zombie flat-footed",
	)
	_probe_check(
		CombatScreen.effective_ac(zombie, true) == CombatScreen.effective_ac(zombie, false),
		"a negative Dexterity modifier is not removed, so that AC is unchanged",
	)
	await _probe_shot("inspect", "02_panel_flat_negative_dex")
	await _probe_close_modal()
	# ------------------------------------------------- roll uses the panel's number
	await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
	await _probe_click_cell(combat, e.cell_of(duelist), "attack the duelist")
	for i in 6:
		await get_tree().process_frame
	_probe_check(
		_probe_log_contains(e, "vs AC %d" % duelist_flat),
		"the attack roll resolves against the %d the panel showed" % duelist_flat,
	)
	await _probe_shot("inspect", "03_attack_flat_ac")
	# ------------------------------------------- text size through Settings slider
	var original_scale := float(Game.settings.get("text_scale", 1.0))
	await _probe_set_text_scale(1.6)
	_probe_check(
		is_equal_approx(float(Game.settings.get("text_scale", 1.0)), 1.6),
		"the Settings slider set the text size to 1.6",
	)
	await _probe_open_inspect(combat, duelist)
	_probe_check(
		_probe_modal_ac_line().contains("AC %d (flat-footed)" % duelist_flat),
		"the marker is still shown at 1.6 text size",
	)
	_probe_check(_probe_modal_labels_fit(), "the panel text stays inside the panel at 1.6")
	await _probe_shot("inspect", "04_panel_flat_1p6")
	await _probe_close_modal()
	# -------------------------------------------------- after the defenders' turns
	await _probe_click(_probe_button(combat.button_box, "End turn"), "End turn")
	for i in 300:
		await get_tree().process_frame
		if e.finished or e.is_player_turn():
			break
	_probe_check(not e.is_flat_footed(duelist_index), "the duelist is no longer flat-footed after acting")
	_probe_check(not e.is_flat_footed(zombie_index), "the zombie is no longer flat-footed after acting")
	await _probe_open_inspect(combat, duelist)
	var standing_ac := CombatScreen.effective_ac(duelist, false)
	var ac_line := _probe_modal_ac_line()
	_probe_check(
		ac_line.contains("AC %d " % standing_ac) and not ac_line.contains("flat-footed"),
		"the panel shows the standing AC %d and no marker after that turn (line: %s)"
		% [standing_ac, ac_line],
	)
	await _probe_shot("inspect", "05_panel_after_turn")
	await _probe_close_modal()
	Game.set_text_scale(original_scale)
	_probe_finish("inspect")


## QA-only weapon fixture (--demo-weapons). The shipped rogue exactly as
## authored (short sword readied, light crossbow carried) against one standard
## zombie. The zombie is rooted so the ranged demonstration stays at 30 ft; no
## item, stat, feat or encounter is changed for the player character.
func _qa_weapons_demo() -> void:
	var sera := Character.from_content(Game.content.get_character("sera"), Game.content.items)
	var zombie := Character.from_content(Game.content.get_monster("zombie"), Game.content.items)
	zombie.id = "qa_weapon_target"
	zombie.display_name = "QA Target Zombie"
	zombie.speed_ft = 0
	Game.party.clear()
	Game.party.append(sera)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA WEAPONS FAILED: encounter did not start")
		return
	e.add_combatant(zombie, Vector2i(7, 3), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	for attempt in 120:
		e.begin()
		if e.active_character() == sera and not e.finished:
			break
	e.entry_for(sera)["cell"] = Vector2i(1, 3)
	e.entry_for(zombie)["cell"] = Vector2i(7, 3)
	e.rng.seed = 20261114
	print(
		"QA WEAPONS READY: sera=%s readied=%s target=%s"
		% [
			str(e.cell_of(sera)),
			String(sera.equipment.get("weapon", {}).get("id", "")),
			str(e.cell_of(zombie)),
		]
	)


## QA-only integration fixture (--demo-integration): the shipped campaign
## encounter "town_square_zombies" with its own map, party cells and standard
## infected zombies, played by the unmodified pregens. No stat block, cell or
## modifier is edited; the only fixture value is a fixed dice seed so the
## acceptance run is repeatable.
## QA-only shield fixture (--demo-shield): the shipped fighter with his authored
## longsword and heavy steel shield, facing one stationary zombie. Nothing about
## his stat block, equipment or the zombie is edited.
func _qa_shield_demo() -> void:
	var kaelen := Character.from_content(Game.content.get_character("kaelen"), Game.content.items)
	var zombie := Character.from_content(Game.content.get_monster("zombie"), Game.content.items)
	zombie.id = "qa_shield_target"
	zombie.display_name = "QA Shield Zombie"
	zombie.speed_ft = 0
	Game.party.clear()
	Game.party.append(kaelen)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA SHIELD FAILED: encounter did not start")
		return
	e.add_combatant(zombie, Vector2i(8, 3), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	for attempt in 120:
		e.begin()
		if e.active_character() == kaelen and not e.finished:
			break
	e.entry_for(kaelen)["cell"] = Vector2i(2, 3)
	e.entry_for(zombie)["cell"] = Vector2i(8, 3)
	e.rng.seed = 20261115
	print(
		"QA SHIELD READY: kaelen=%s shield=%s ac=%d"
		% [
			str(e.cell_of(kaelen)),
			String(kaelen.equipment.get("shield", {}).get("id", "")),
			Rules.armor_class(kaelen),
		]
	)


func _probe_select_shield(combat: Control, needle: String) -> bool:
	if combat == null:
		return false
	var option: OptionButton = combat.shield_option
	if option == null:
		return false
	for i in option.item_count:
		if option.get_item_text(i).to_lower().contains(needle):
			option.select(i)
			option.item_selected.emit(i)
			return true
	return false


## QA-only (--shield-probe, fixture --demo-shield): ready and loose a shield through
## the ordinary controls, with the printed move-action costs, the drop on the
## character's square, pickup and re-strapping, and the standard-action substitution
## from PHB p.138.
func _shield_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "shield"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var combat := current_screen
	var e := Game.encounter
	if combat == null or e == null:
		_probe_check(false, "the shield encounter is running")
		_probe_finish("shield")
		return
	var kaelen: Character = null
	for entry in e.combatants:
		if String(entry["char"].id) == "kaelen":
			kaelen = entry["char"]
	if kaelen == null:
		_probe_check(false, "the fixture has the fighter")
		_probe_finish("shield")
		return
	var option: OptionButton = combat.shield_option
	_probe_check(option != null, "the shield control exists")
	var listed := ""
	if option != null:
		for i in option.item_count:
			listed += option.get_item_text(i) + "|"
	_probe_check(listed.to_lower().contains("heavy steel shield (strapped)"), "the strapped shield is marked")
	_probe_check(listed.to_lower().contains("loose shield (drops it)"), "loosing is an explicit choice")
	_probe_check(String(kaelen.equipment.get("shield", {}).get("id", "")) == "heavy_steel_shield", "state: the shield starts strapped")
	_probe_check(Rules.armor_class(kaelen) == 17, "state: AC starts at 17 with the shield")
	await _probe_shot("shield", "00_before")
	var before_loose := e.log_lines.size()
	var picked := _probe_select_shield(combat, "loose shield")
	_probe_check(picked, "the loose entry is selected")
	for i in 10:
		await get_tree().process_frame
	var loosed := _probe_ranged_new_lines(e, before_loose)
	_probe_check(loosed.contains("unstraps and drops Heavy Steel Shield"), "loosing unstraps and drops")
	_probe_check(kaelen.equipment.get("shield", {}).is_empty(), "state: nothing is strapped on")
	_probe_check(Rules.armor_class(kaelen) == 15, "state: AC drops by the shield bonus")
	_probe_check(kaelen.inventory_count("heavy_steel_shield") == 0, "state: loosing is not storing")
	_probe_check(e.ground_items.size() == 1, "state: the shield lies on the ground")
	await _probe_shot("shield", "01_loosed")
	var before_pick := e.log_lines.size()
	await _probe_click(_probe_button(combat.button_box, "Pick up"), "Pick up")
	for i in 10:
		await get_tree().process_frame
	_probe_check(_probe_ranged_new_lines(e, before_pick).contains("picks up"), "the dropped shield can be recovered")
	_probe_check(kaelen.inventory_count("heavy_steel_shield") == 1, "state: the shield is carried again")
	_probe_check(e.ground_items.is_empty(), "state: nothing is left on the ground")
	await _probe_shot("shield", "02_picked_up")
	var round_two := await _probe_advance_to(combat, "kaelen", 2)
	_probe_check(round_two, "the fighter gets a second turn")
	if round_two:
		var before_ready := e.log_lines.size()
		var strapped := _probe_select_shield(combat, "heavy steel shield")
		_probe_check(strapped, "the carried shield is selected")
		for i in 10:
			await get_tree().process_frame
		_probe_check(
			_probe_ranged_new_lines(e, before_ready).contains("straps Heavy Steel Shield"),
			"strapping it on costs a move action",
		)
		_probe_check(Rules.armor_class(kaelen) == 17, "state: the shield bonus returns")
		_probe_check(kaelen.inventory_count("heavy_steel_shield") == 0, "state: no duplicate copy is left")
		await _probe_shot("shield", "03_restrapped")
		var before_second := e.log_lines.size()
		var second := _probe_select_shield(combat, "loose shield")
		_probe_check(second, "the shield can be loosed again in the same turn")
		for i in 10:
			await get_tree().process_frame
		_probe_check(
			_probe_ranged_new_lines(e, before_second).contains("standard action used as a move; PHB p.138"),
			"the second move-equivalent spends the standard action",
		)
		_probe_check(Rules.armor_class(kaelen) == 15, "state: the shield is off again")
		_probe_check(e.ground_items.size() == 1, "state: it is on the ground again")
		await _probe_shot("shield", "04_loose_standard")
	_probe_finish("shield")


## QA-only unarmed fixture (--demo-unarmed): the shipped rogue with her hands empty
## beside one living enemy and one undead enemy. Nothing about the characters is
## edited except the rogue's readied weapon slot, which the player can empty with the
## ordinary Sheathe action anyway; the fixture only skips that setup turn.
func _qa_unarmed_demo() -> void:
	var sera := Character.from_content(Game.content.get_character("sera"), Game.content.items)
	sera.equipment["weapon"] = {}
	sera.max_hp = 40
	sera.hp = 40
	var brawler := Character.from_content(Game.content.get_character("kaelen"), Game.content.items)
	brawler.id = "qa_unarmed_brawler"
	brawler.display_name = "QA Armed Brawler"
	brawler.max_hp = 40
	brawler.hp = 40
	brawler.speed_ft = 0
	# QA only: the brawler keeps his ordinary defenses except that the probe lowers
	# his AC so one punch reliably lands. Nothing about the attacker is changed.
	brawler.ac_misc = -20
	var zombie := Character.from_content(Game.content.get_monster("zombie"), Game.content.items)
	zombie.id = "qa_unarmed_zombie"
	zombie.display_name = "QA Unarmed Zombie"
	zombie.speed_ft = 0
	Game.party.clear()
	Game.party.append(sera)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA UNARMED FAILED: encounter did not start")
		return
	e.add_combatant(brawler, Vector2i(3, 3), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	e.add_combatant(zombie, Vector2i(2, 4), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	for attempt in 120:
		e.begin()
		if e.active_character() == sera and not e.finished:
			break
	e.entry_for(sera)["cell"] = Vector2i(2, 3)
	e.entry_for(brawler)["cell"] = Vector2i(3, 3)
	e.entry_for(zombie)["cell"] = Vector2i(2, 4)
	e.rng.seed = 20261116
	print(
		"QA UNARMED READY: sera=%s readied=%s brawler=%s zombie=%s"
		% [
			str(e.cell_of(sera)),
			String(sera.equipment.get("weapon", {}).get("id", "")),
			str(e.cell_of(brawler)),
			str(e.cell_of(zombie)),
		]
	)


## QA-only (--unarmed-probe, fixture --demo-unarmed): ordinary unarmed attacks through
## the ordinary controls - nonlethal damage on a living target, the printed
## provocation from an armed target, undead immunity, and the unchanged threat state.
func _unarmed_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "unarmed"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var combat := current_screen
	var e := Game.encounter
	if combat == null or e == null:
		_probe_check(false, "the unarmed encounter is running")
		_probe_finish("unarmed")
		return
	var sera: Character = null
	var brawler: Character = null
	var zombie: Character = null
	for entry in e.combatants:
		match String(entry["char"].id):
			"sera":
				sera = entry["char"]
			"qa_unarmed_brawler":
				brawler = entry["char"]
			"qa_unarmed_zombie":
				zombie = entry["char"]
	if sera == null or brawler == null or zombie == null:
		_probe_check(false, "the fixture has the rogue, a living enemy and an undead one")
		_probe_finish("unarmed")
		return
	_probe_check(sera.equipment.get("weapon", {}).is_empty(), "state: the rogue is empty-handed")
	_probe_check(e.threat_capability(sera).is_empty(), "state: ordinary empty hands threaten nothing")
	_probe_check(
		String(e.available_melee_attack(sera).get("name", "")) == "unarmed strike",
		"state: the unarmed strike is an available attack",
	)
	_probe_check(
		String(e._primary_weapon(sera).get("damage", "")) == "1d3", "state: Medium unarmed damage is 1d3"
	)
	await _probe_shot("unarmed", "00_before")
	var hp_before := brawler.hp
	var punch_hit := false
	var punch_said_unarmed := false
	var punch_said_armed_target := false
	for attempt in 4:
		var before_punch := e.log_lines.size()
		await _probe_click(_probe_button(current_screen.button_box, "Attack"), "Attack")
		await _probe_click_cell(current_screen, e.cell_of(brawler), "punch the armed brawler")
		for i in 16:
			await get_tree().process_frame
		var punch := _probe_ranged_new_lines(e, before_punch)
		punch_said_unarmed = punch_said_unarmed or punch.contains("attacks unarmed")
		punch_said_armed_target = (
			punch_said_armed_target
			or punch.contains("provokes an attack of opportunity from QA Armed Brawler")
		)
		if punch.contains("nonlethal damage"):
			punch_hit = true
			break
		if e.finished:
			break
		var another := await _probe_advance_to(current_screen, "sera", e.round_number + 1)
		if not another:
			break
	_probe_check(punch_said_unarmed, "the attack is declared as unarmed")
	_probe_check(punch_said_armed_target, "an armed target gets the printed reaction (PHB p.139)")
	_probe_check(punch_hit, "the strike lands as nonlethal damage")
	_probe_check(brawler.hp == hp_before, "state: hit points are untouched by nonlethal damage")
	_probe_check(brawler.nonlethal > 0, "state: nonlethal damage is tracked separately")
	_probe_check(
		e.threat_capability(sera).is_empty(), "state: attacking unarmed does not make the rogue armed"
	)
	await _probe_shot("unarmed", "01_nonlethal")
	# The immunity half runs through the same damage application the attack path
	# uses; the round-by-round route would need two more turns of setup and the
	# immunity itself is a property of the damage type, not of the turn order.
	var zombie_hp := zombie.hp
	var before_immune := e.log_lines.size()
	var immune_result := {
		"hit": true,
		"damage": 3,
		"nonlethal": true,
		"attacker": sera,
		"target": zombie,
		"weapon": e._primary_weapon(sera),
	}
	e._apply_damage(zombie, immune_result)
	var immune_log := _probe_ranged_new_lines(e, before_immune)
	_probe_check(immune_log.contains("immune to nonlethal"), "the undead are immune to nonlethal damage")
	_probe_check(zombie.hp == zombie_hp, "state: the zombie loses no hit points")
	_probe_check(zombie.nonlethal == 0, "state: no nonlethal damage is recorded on the undead")
	await _probe_shot("unarmed", "02_undead_immune")
	_probe_finish("unarmed")


## QA-only nonlethal fixture (--demo-nonlethal): the shipped rogue, staggered by
## accumulated nonlethal damage, beside a dummy that is staggered for the same
## reason. The totals are set as state, exactly like the QA hit-point values, so the
## probe can drive the transitions through the ordinary controls without spending
## ten turns of punching. Nothing about the rules is edited.
func _qa_nonlethal_demo() -> void:
	var sera := Character.from_content(Game.content.get_character("sera"), Game.content.items)
	sera.equipment["weapon"] = {}
	sera.max_hp = 40
	sera.hp = 20
	sera.nonlethal = 20
	sera.refresh_nonlethal_state()
	if sera.inventory_count("potion_of_cure_light_wounds") <= 0:
		sera.add_to_inventory(Game.content.items["potion_of_cure_light_wounds"], 1)
	var dummy := Character.from_content(Game.content.get_character("kaelen"), Game.content.items)
	dummy.id = "qa_nonlethal_dummy"
	dummy.display_name = "QA Staggered Dummy"
	dummy.equipment["weapon"] = {}
	dummy.max_hp = 6
	dummy.hp = 6
	dummy.nonlethal = 6
	dummy.refresh_nonlethal_state()
	dummy.speed_ft = 0
	# QA only: keeps the dummy's AC low so the demo punch reliably lands.
	dummy.ac_misc = -20
	Game.party.clear()
	Game.party.append(sera)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA NONLETHAL FAILED: encounter did not start")
		return
	# The QA victory scenario ships its own monster; this fixture needs a single
	# controlled dummy, so the shipped enemy is dropped before the encounter begins.
	var party_only := []
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_PARTY:
			entry["index"] = party_only.size()
			party_only.append(entry)
	e.combatants = party_only
	e.add_combatant(dummy, Vector2i(3, 3), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	for attempt in 120:
		e.begin()
		if e.active_character() == sera and not e.finished:
			break
	e.entry_for(sera)["cell"] = Vector2i(2, 3)
	e.entry_for(dummy)["cell"] = Vector2i(3, 3)
	e.rng.seed = 20261117
	sera.refresh_nonlethal_state()
	dummy.refresh_nonlethal_state()
	print(
		"QA NONLETHAL READY: sera_hp=%d sera_nonlethal=%d state=%s dummy_state=%s"
		% [
			int(sera.hp),
			int(sera.nonlethal),
			String(sera.nonlethal_state()),
			String(dummy.nonlethal_state()),
		]
	)


## QA-only (--nonlethal-probe, fixture --demo-nonlethal). Shows the printed
## thresholds through the ordinary controls: the staggered action limit, a magical
## potion clearing the state, and a punch pushing the dummy past its hit points.
func _nonlethal_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "nonlethal"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var e := Game.encounter
	if current_screen == null or e == null:
		_probe_check(false, "the nonlethal encounter is running")
		_probe_finish("nonlethal")
		return
	var sera: Character = null
	var dummy: Character = null
	for entry in e.combatants:
		match String(entry["char"].id):
			"sera":
				sera = entry["char"]
			"qa_nonlethal_dummy":
				dummy = entry["char"]
	if sera == null or dummy == null:
		_probe_check(false, "the fixture has the rogue and the dummy")
		_probe_finish("nonlethal")
		return
	_probe_check(sera.has_condition("staggered"), "state: the rogue starts staggered")
	_probe_check(sera.nonlethal == sera.hp, "state: nonlethal damage equals current hit points")
	var label: String = current_screen.active_label.text
	_probe_check(label.contains("nonlethal 20"), "the status line shows the nonlethal total")
	_probe_check(label.contains("staggered"), "the status line shows the staggered state")
	await _probe_shot("nonlethal", "00_staggered")
	# PHB p.147: staggered means one standard action or one move action, not both.
	await _probe_click(_probe_button(current_screen.button_box, "Move"), "Move")
	await _probe_click_cell(current_screen, Vector2i(2, 2), "step aside")
	for i in 12:
		await get_tree().process_frame
	var attack_button := _probe_button(current_screen.button_box, "Attack")
	_probe_check(attack_button != null, "control: the Attack button is present")
	if attack_button != null:
		_probe_check(attack_button.disabled, "staggered: Attack is refused after a move action")
	await _probe_shot("nonlethal", "01_staggered_limit")
	# Healing: a potion removes nonlethal damage equal to the amount it cures.
	var round_two := await _probe_advance_to(current_screen, "sera", 2)
	_probe_check(round_two, "the rogue gets another turn")
	if not round_two:
		_probe_finish("nonlethal")
		return
	var nonlethal_before := sera.nonlethal
	var hp_before := sera.hp
	await _probe_click(_probe_button(current_screen.button_box, "Use potion"), "Use potion")
	await _probe_click_modal_button("Potion")
	await _probe_click_cell(current_screen, e.cell_of(sera), "drink the potion")
	for i in 16:
		await get_tree().process_frame
	_probe_check(sera.hp > hp_before, "the potion restores hit points")
	_probe_check(sera.nonlethal < nonlethal_before, "the potion also removes nonlethal damage")
	_probe_check(not sera.has_condition("staggered"), "state: the staggered condition is gone")
	_probe_check(sera.nonlethal_state() != "staggered", "state: no nonlethal threshold now applies")
	await _probe_shot("nonlethal", "02_healed")
	# A punch pushes an already-staggered dummy past its hit points.
	_probe_check(dummy.nonlethal == dummy.hp, "state: the dummy is exactly at its threshold")
	var round_three := await _probe_advance_to(current_screen, "sera", 3)
	_probe_check(round_three, "the rogue gets a third turn")
	if not round_three:
		_probe_finish("nonlethal")
		return
	for attempt in 4:
		await _probe_click(_probe_button(current_screen.button_box, "Attack"), "Attack")
		await _probe_click_cell(current_screen, e.cell_of(dummy), "punch the dummy")
		for i in 16:
			await get_tree().process_frame
		if dummy.has_condition("nonlethal_unconscious") or e.finished:
			break
		var more := await _probe_advance_to(current_screen, "sera", e.round_number + 1)
		if not more:
			break
	_probe_check(dummy.has_condition("nonlethal_unconscious"), "the dummy falls unconscious from nonlethal damage")
	_probe_check(not dummy.is_conscious(), "state: unconscious and helpless (PHB p.147)")
	_probe_check(Rules.is_helpless(dummy), "state: helpless")
	_probe_check(dummy.hp == 6, "state: the dummy's hit points are untouched")
	_probe_check(e.finished and e.outcome == "victory", "the encounter ends once no enemy can fight")
	await _probe_shot("nonlethal", "03_unconscious")
	_probe_finish("nonlethal")


func _qa_integration_demo() -> void:
	var loaded := Game.load_campaign("ravenloft_demo")
	if not bool(loaded.get("ok", false)):
		print("QA INTEGRATION FAILED: campaign did not load")
		return
	var started := Game.start_encounter("town_square_zombies")
	if not bool(started.get("ok", false)):
		print("QA INTEGRATION FAILED: encounter did not start: %s" % String(started.get("message", "")))
		return
	var e := Game.encounter
	e.rng.seed = 20261113
	var roster: Array[String] = []
	for entry in e.combatants:
		var ch: Character = entry["char"]
		roster.append("%s@%s" % [ch.id, str(entry.get("cell", Vector2i(-1, -1)))])
	print("QA INTEGRATION READY: %s" % ", ".join(roster))


## QA-only Concentration fixture (--demo-concentration). Two wizard clones, one
## with enough Concentration ranks to pass and one untrained with Con 1, each
## standing next to a zombie that hits on its opportunity attack, plus an
## unengaged spell target. Shipped characters are not modified.
func _qa_concentration_demo() -> void:
	var good := _qa_concentration_caster("qa_conc_good", "QA Caster Prepared", 20, 12)
	var weak := _qa_concentration_caster("qa_conc_weak", "QA Caster Untrained", 0, 1)
	var feat_caster := _qa_concentration_caster("qa_conc_feat", "QA Caster Combat Casting", 0, 1)
	if good == null or weak == null or feat_caster == null:
		print("QA CONCENTRATION FAILED: no prepared caster in content")
		return
	feat_caster.feats.append("Combat Casting")
	Game.party.clear()
	Game.party.append(good)
	Game.party.append(weak)
	Game.party.append(feat_caster)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA CONCENTRATION FAILED: encounter did not start")
		return
	var biter := _qa_concentration_zombie("qa_conc_biter", "QA Biter", "1d6+2")
	var heavy := _qa_concentration_zombie("qa_conc_heavy", "QA Heavy Hitter", "1d6+4")
	var feat_biter := _qa_concentration_zombie("qa_conc_feat_biter", "QA Feat Biter", "1d6+2")
	var target := Character.from_content(Game.content.get_monster("ghoul"), Game.content.items)
	target.id = "qa_conc_target"
	target.display_name = "QA Spell Target"
	target.max_hp = 200
	target.hp = 200
	# The fixture keeps its geometry: enemies hold their cells (speed 0) so the
	# probe always targets the same square, but still react and attack.
	target.speed_ft = 0
	biter.speed_ft = 0
	heavy.speed_ft = 0
	feat_biter.speed_ft = 0
	e.add_combatant(biter, Vector2i(2, 2), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	e.add_combatant(heavy, Vector2i(4, 2), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	e.add_combatant(feat_biter, Vector2i(6, 2), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	e.add_combatant(target, Vector2i(1, 1), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	for attempt in 120:
		e.begin()
		if e.active_character() == good and not e.finished:
			break
	# `begin()` re-applies the encounter layout, so the QA cells are set last.
	e.entry_for(good)["cell"] = Vector2i(2, 3)
	e.entry_for(weak)["cell"] = Vector2i(4, 3)
	e.entry_for(feat_caster)["cell"] = Vector2i(6, 3)
	e.entry_for(biter)["cell"] = Vector2i(2, 2)
	e.entry_for(heavy)["cell"] = Vector2i(4, 2)
	e.entry_for(feat_biter)["cell"] = Vector2i(6, 2)
	e.entry_for(target)["cell"] = Vector2i(1, 1)
	print(
		"QA CONCENTRATION READY: good=%s weak=%s target=%s"
		% [str(e.cell_of(good)), str(e.cell_of(weak)), str(e.cell_of(target))]
	)


func _qa_concentration_caster(
	qa_id: String, qa_name: String, ranks: int, constitution: int
) -> Character:
	var ch := _qa_ranged_caster()
	if ch == null:
		return null
	ch.id = qa_id
	ch.display_name = qa_name
	ch.max_hp = 90
	ch.hp = 90
	ch.abilities["con"] = constitution
	ch.skill_ranks["concentration"] = ranks
	return ch


func _qa_concentration_zombie(qa_id: String, qa_name: String, damage: String) -> Character:
	var ch := _qa_ranged_character("zombie", qa_id, qa_name)
	# The reaction has to land for the injury rule to be exercised; the clone's
	# attack bonus and damage are fixture values, not shipped stat block edits.
	ch.base_attack = 50
	ch.attacks = [
		{"name": "slam", "damage": damage, "crit_range": 20, "crit_mult": 2, "damage_type": "bludgeoning"}
	]
	return ch


## QA-only ranged fixture (--demo-ranged). Clones stand in for the party so no
## shipped character is edited: one shooter, one shooter with Precise Shot, one
## shooter aimed at an unengaged target, the wizard for a ray, and a fighter who
## is the "friendly character" the target is engaged with. Cells and initiative
## are the encounter's own; `begin()` is simply re-run until the first shooter
## acts first, exactly as the inspection fixture does.
func _qa_ranged_demo() -> void:
	var shooter := _qa_ranged_character("sera", "qa_ranged_shooter", "QA Ranged Shooter")
	var precise := _qa_ranged_character("sera", "qa_ranged_precise", "QA Precise Shooter")
	precise.feats = ["Point Blank Shot", "Precise Shot"]
	var clear_shooter := _qa_ranged_character("sera", "qa_ranged_clear", "QA Clear Shooter")
	var caster := _qa_ranged_caster()
	var ally := _qa_ranged_character("kaelen", "qa_ranged_ally", "QA Ranged Ally")
	for ch in [shooter, precise, clear_shooter, caster]:
		if ch == null:
			print("QA RANGED FAILED: fixture character missing")
			return
		ch.equipment["weapon"] = Game.content.items["light_crossbow"].duplicate(true)
	Game.party.clear()
	for ch in [shooter, precise, clear_shooter, caster]:
		Game.party.append(ch)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA RANGED FAILED: encounter did not start")
		return
	var party_cells := [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3)]
	for i in mini(party_cells.size(), e.combatants.size()):
		e.combatants[i]["cell"] = party_cells[i]
	# This probe measures range, engagement and the ray's single provocation, not
	# the reload step, so its QA shooters start with a loaded crossbow.
	for entry in e.combatants:
		var shooter_ch: Character = entry["char"]
		var shooter_weapon: Dictionary = shooter_ch.equipment.get("weapon", {})
		if String(shooter_weapon.get("reload", "")) != "":
			e.loaded_weapons[String(shooter_ch.id)] = String(shooter_weapon.get("id", ""))
	var target: Character = null
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			target = entry["char"]
			break
	if target == null:
		print("QA RANGED FAILED: no enemy to shoot at")
		return
	target.id = "qa_ranged_target"
	target.display_name = "QA Ranged Target"
	target.max_hp = 60
	target.hp = 60
	e.entry_for(target)["cell"] = Vector2i(5, 2)
	e.add_combatant(ally, Vector2i(5, 1), Encounter.TEAM_PARTY)
	e.order.append(int(e.combatants.size() - 1))
	var clear_target := _qa_ranged_character("zombie", "qa_ranged_clear_target", "QA Clear Target")
	# The zombie AI closes on the party, which would make the "unengaged" case
	# engaged before the control shot. This clone is rooted for the fixture; no
	# shipped monster is changed.
	clear_target.speed_ft = 0
	e.add_combatant(clear_target, Vector2i(7, 1), Encounter.TEAM_ENEMY)
	e.order.append(int(e.combatants.size() - 1))
	var first := false
	for attempt in 120:
		e.begin()
		if e.active_character() == shooter and not e.finished:
			first = true
			break
	# `begin()` re-applies the encounter layout and may reorder `combatants`, so
	# the QA cells are applied last and by character rather than by index.
	e.entry_for(shooter)["cell"] = Vector2i(2, 3)
	e.entry_for(precise)["cell"] = Vector2i(3, 3)
	e.entry_for(clear_shooter)["cell"] = Vector2i(4, 3)
	e.entry_for(caster)["cell"] = Vector2i(5, 3)
	e.entry_for(ally)["cell"] = Vector2i(5, 1)
	e.entry_for(target)["cell"] = Vector2i(5, 2)
	e.entry_for(clear_target)["cell"] = Vector2i(7, 3)
	print(
		"QA RANGED READY: shooter_first=%s target_cell=%s clear_cell=%s ally_cell=%s"
		% [
			str(first),
			str(e.entry_for(target)["cell"]),
			str(e.entry_for(clear_target)["cell"]),
			str(e.entry_for(ally)["cell"]),
		]
	)

func _qa_ranged_character(source_id: String, qa_id: String, qa_name: String) -> Character:
	var is_monster := Game.content.get_character(source_id).is_empty()
	var data := (
		Game.content.get_monster(source_id) if is_monster else Game.content.get_character(source_id)
	)
	var ch := Character.from_content(data, Game.content.items)
	if ch == null:
		return null
	ch.id = qa_id
	ch.display_name = qa_name
	ch.max_hp = 60
	ch.hp = 60
	return ch


## The slice has one prepared arcane caster; this finds it by its prepared list
## instead of hard-coding an id that content could rename.
func _qa_ranged_caster() -> Character:
	for id in Game.content.character_ids():
		var data := Game.content.get_character(id)
		var prepared: Dictionary = data.get("spells", {}).get("prepared", {})
		for level in prepared.keys():
			if Array(prepared[level]).has("scorching_ray"):
				return _qa_ranged_character(
					id, "qa_ranged_caster", "QA Ranged Caster"
				)
	return null


## QA-only (--ranged-probe, fixture --demo-ranged). Asserts the ranged rules in
## the rendered combat log, driven only through the ordinary buttons: Attack +
## target cell, Cast spell + spell button + target cell, End turn to reach the
## next actor. The log is read from the RichTextLabel the player sees, not from
## `Encounter.log_lines`, so a formatting regression fails the probe.
func _ranged_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "ranged"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var combat := current_screen
	var e := Game.encounter
	if combat == null or e == null:
		_probe_check(false, "combat screen with an encounter exists")
		_probe_finish("ranged")
		return
	var shooter: Character = null
	var target: Character = null
	var clear_target: Character = null
	var ally: Character = null
	for entry in e.combatants:
		var ch: Character = entry["char"]
		match String(ch.id):
			"qa_ranged_shooter": shooter = ch
			"qa_ranged_target": target = ch
			"qa_ranged_clear_target": clear_target = ch
			"qa_ranged_ally": ally = ch
	_probe_check(shooter != null and e.active_character() == shooter, "the QA ranged shooter acts first")
	if shooter == null or target == null or clear_target == null or ally == null:
		_probe_check(false, "the ranged fixture has a shooter, a target, a clear target and an ally")
		_probe_finish("ranged")
		return
	# Click the cells the encounter actually holds, then assert the geometry the
	# two conditions depend on, so a layout regression cannot pass silently.
	var target_cell := Vector2i(e.entry_for(target)["cell"])
	var clear_cell := Vector2i(e.entry_for(clear_target)["cell"])
	_probe_check(
		(
			e.map.distance_ft(Vector2i(e.entry_for(ally)["cell"]), target_cell)
			<= maxi(ally.reach_ft, BattleMap.CELL_FT)
		),
		"the staged ally is engaged with the target",
	)
	var party_team := int(e.combatants[0]["team"])
	var clear_engaged := false
	for entry in e.combatants:
		if int(entry["team"]) != party_team:
			continue
		if e.map.distance_ft(Vector2i(entry["cell"]), clear_cell) <= 5:
			clear_engaged = true
	_probe_check(not clear_engaged, "no party member is next to the unengaged target")
	var clear_on_cell := false
	for entry in e.combatants:
		if Vector2i(entry["cell"]) == clear_cell:
			clear_on_cell = true
	_probe_check(clear_on_cell, "the unengaged target stands on %s" % str(clear_cell))
	await _probe_shot("ranged", "00_start")
	# ------------------------------------------------ (A) engaged target: -4 shown
	var before_index := e.log_lines.size()
	await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
	await _probe_click_cell(combat, target_cell, "shoot the engaged target")
	for i in 12:
		await get_tree().process_frame
	var fresh := _probe_ranged_new_lines(e, before_index)
	_probe_check(fresh.contains("with Light Crossbow"), "the engaged shot was a crossbow attack")
	_probe_check(fresh.contains("shooting into melee -4"), "the breakdown shows the into-melee -4")
	_probe_check(
		fresh.contains("is engaged with QA "),
		"the breakdown names the friendly character the shot has to avoid (segment: %s)"
		% fresh.substr(0, 700),
	)
	await _probe_shot("ranged", "01_engaged_penalty")
	# ------------------------------------------- Precise Shot attacker: exempt
	var precise_ready := await _probe_advance_to(combat, "qa_ranged_precise")
	_probe_check(precise_ready, "the Precise Shot shooter's turn arrives")
	if precise_ready:
		before_index = e.log_lines.size()
		await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
		await _probe_click_cell(combat, target_cell, "shoot the engaged target with Precise Shot")
		for i in 12:
			await get_tree().process_frame
		fresh = _probe_ranged_new_lines(e, before_index)
		_probe_check(fresh.contains("with Light Crossbow"), "the Precise Shot attack was a crossbow attack")
		_probe_check(
			not fresh.contains("shooting into melee"),
			"Precise Shot removes the into-melee penalty from the breakdown",
		)
		await _probe_shot("ranged", "02_precise_shot_exempt")
	# --------------------------------------- unengaged target: no penalty at all
	var clear_ready := await _probe_advance_to(combat, "qa_ranged_clear")
	_probe_check(clear_ready, "the clear-shot shooter's turn arrives")
	if clear_ready:
		before_index = e.log_lines.size()
		await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
		# The grid click was not registering on this far cell, so the control shot
		# uses the enemy row's own Attack button, which is also an ordinary control.
		_probe_check(
			e.cell_of(clear_target) == clear_cell,
			"the unengaged target is still on %s when the control shot is taken" % str(clear_cell),
		)
		var clear_button := _probe_enemy_row_button(combat, "QA Clear Target", "Attack")
		_probe_check(clear_button != null, "the enemy row for the unengaged target offers Attack")
		if clear_button != null:
			await _probe_click(clear_button, "shoot the unengaged target")
		for i in 12:
			await get_tree().process_frame
		fresh = _probe_ranged_new_lines(e, before_index)
		_probe_check(
			fresh.contains("with Light Crossbow"),
			"the control shot was a crossbow attack (segment: %s; message: %s)"
			% [fresh.substr(0, 700), Game.last_ui_message],
		)
		_probe_check(
			fresh.contains("vs AC") and not fresh.contains("shooting into melee"),
			"an unengaged target takes no into-melee penalty (segment: %s)"
			% fresh.substr(0, 900),
		)
		await _probe_shot("ranged", "03_unengaged_control")
	# ------------------------------------------- ray: penalty and one provocation
	var caster_ready := await _probe_advance_to(combat, "qa_ranged_caster")
	_probe_check(caster_ready, "the caster's turn arrives")
	if caster_ready:
		before_index = e.log_lines.size()
		await _probe_click(_probe_button(combat.button_box, "Cast spell"), "Cast spell")
		for i in 6:
			await get_tree().process_frame
		var spell_chosen := await _probe_click_modal_button("Scorching Ray")
		_probe_check(spell_chosen, "the spell list offers Scorching Ray")
		if spell_chosen:
			await _probe_click_cell(combat, target_cell, "cast the ray at the engaged target")
			for i in 16:
				await get_tree().process_frame
			fresh = _probe_ranged_new_lines(e, before_index)
			_probe_check(fresh.contains("casts Scorching Ray"), "the ray was cast")
			_probe_check(fresh.contains("scorching ray (ranged touch)"), "the ray resolved as a ranged touch attack")
			_probe_check(fresh.contains("shooting into melee -4"), "the ray takes the into-melee penalty")
			_probe_check(fresh.contains("Complete Arcane p.73"), "the ray's penalty cites the weaponlike-spell rule")
			# Each threatening enemy may react once. A second reaction from the same
			# creature would be the duplicate provocation this check exists for, so
			# the assertion is per-attacker rather than a bare count.
			var repeated := _probe_ranged_repeated_aoo(fresh)
			_probe_check(
				repeated == "",
				"no creature reacted twice to the ray (repeat: %s; segment: %s)"
				% [repeated, fresh.substr(0, 1600)],
			)
			_probe_check(
				_probe_ranged_count(fresh, "provokes attacks of opportunity") == 1,
				"exactly one provocation line belongs to the cast",
			)
			await _probe_shot("ranged", "04_ray_into_melee")
	_probe_finish("ranged")


## The lines this one action added. `CombatScreen._refresh_log` renders the tail
## of `log_lines` verbatim into `log_label`, so joining the new lines is what the
## player sees; using the exact slice keeps a "must not appear" assertion from
## matching an earlier action after the label scrolls.
func _probe_ranged_new_lines(e: Encounter, from_index: int) -> String:
	var text := ""
	for line in e.log_lines.slice(maxi(0, from_index)):
		text += String(line) + "\n"
	return text


## Returns the name of a creature that took more than one opportunity attack,
## or "" when every reaction comes from a different creature.
func _probe_ranged_repeated_aoo(text: String) -> String:
	var seen := {}
	var marker := "Attack of opportunity by "
	var at := text.find(marker)
	while at >= 0:
		var rest := text.substr(at + marker.length())
		var stop := rest.find("!")
		if stop > 0:
			var who := rest.substr(0, stop).strip_edges()
			if seen.has(who):
				return who
			seen[who] = true
		at = text.find(marker, at + 1)
	return ""


func _probe_ranged_count(text: String, needle: String) -> int:
	var total := 0
	var at := text.find(needle)
	while at >= 0:
		total += 1
		at = text.find(needle, at + needle.length())
	return total


## Ends turns through the real button until `id` is the active player character.
func _probe_advance_to(combat: Control, id: String, min_round := 1) -> bool:
	var e := Game.encounter
	for i in 60:
		if e == null or e.finished:
			return false
		var active := e.active_character()
		if (
			e.is_player_turn()
			and active != null
			and String(active.id) == id
			and int(e.round_number) >= min_round
		):
			return true
		var screen := current_screen if current_screen != null else combat
		await _probe_click(_probe_button(screen.button_box, "End turn"), "End turn")
		for f in 600:
			await get_tree().process_frame
			if e == null or e.finished or e.is_player_turn():
				break
	return false


func _probe_click_modal_button(prefix: String) -> bool:
	if modal == null:
		return false
	for node in modal.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text.begins_with(prefix):
			await _probe_click(button, prefix)
			for i in 4:
				await get_tree().process_frame
			return true
	return false


## QA-only (--weapon-probe, fixture --demo-weapons). Drives the weapon chooser,
## the Load weapon button and the ordinary Attack control with the shipped rogue
## unmodified: draw the carried crossbow, be refused an unloaded shot, load it,
## fire it, then return to the melee weapon. The dropdown item is selected through
## the control's own signal because a native popup is a separate window that
## synthetic clicks cannot reliably reach; every other action is a real click.
func _weapon_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "weapons"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var combat := current_screen
	var e := Game.encounter
	if combat == null or e == null:
		_probe_check(false, "the weapon encounter is running")
		_probe_finish("weapons")
		return
	var sera: Character = null
	var target: Character = null
	for entry in e.combatants:
		var ch: Character = entry["char"]
		if String(ch.id) == "sera":
			sera = ch
		elif String(ch.id) == "qa_weapon_target":
			target = ch
	if sera == null or target == null:
		_probe_check(false, "the fixture has the rogue and a target")
		_probe_finish("weapons")
		return
	var option: OptionButton = combat.weapon_option
	_probe_check(option != null and option.item_count >= 2, "the weapon control lists carried weapons")
	var listed := ""
	if option != null:
		for i in option.item_count:
			listed += option.get_item_text(i) + "|"
	_probe_check(
		listed.to_lower().contains("light crossbow"), "the carried crossbow is offered"
	)
	_probe_check(
		listed.to_lower().contains("short sword (readied)"), "the readied sword is marked"
	)
	_probe_check(
		String(sera.equipment.get("weapon", {}).get("id", "")) == "short_sword",
		"state: the sword starts readied",
	)
	await _probe_shot("weapons", "00_before")
	var before_switch := e.log_lines.size()
	var picked := _probe_select_weapon(combat, "light crossbow")
	_probe_check(picked, "the crossbow is selected in the weapon control")
	for i in 10:
		await get_tree().process_frame
	var refused := _probe_ranged_new_lines(e, before_switch)
	_probe_check(
		String(Game.last_ui_message).contains("separate move action"),
		"switching weapons is refused until the sword is put away",
	)
	_probe_check(
		String(sera.equipment.get("weapon", {}).get("id", "")) == "short_sword",
		"state: the refused switch changed nothing",
	)
	_probe_check(not e.turn_state.get("move_used", false), "state: the refusal spent no action")
	await _probe_shot("weapons", "01_switch_refused")
	var before_sheathe := e.log_lines.size()
	await _probe_click(_probe_button(combat.button_box, "Sheathe weapon"), "Sheathe weapon")
	for i in 10:
		await get_tree().process_frame
	var sheathed := _probe_ranged_new_lines(e, before_sheathe)
	_probe_check(sheathed.contains("sheathes Short Sword (move action; PHB p.142)"), "sheathing costs a move action")
	_probe_check(sera.equipment.get("weapon", {}).is_empty(), "state: the hand is empty")
	_probe_check(
		String(e.available_melee_attack(sera).get("name", "")) == "unarmed strike",
		"state: an empty hand can still attempt the unarmed strike",
	)
	_probe_check(
		e.threat_capability(sera).is_empty(),
		"state: ordinary empty hands do not threaten (PHB p.137)",
	)
	await _probe_shot("weapons", "02_sheathed")
	var round_two := await _probe_advance_to(combat, "sera", 2)
	_probe_check(round_two, "the rogue gets a second turn")
	if round_two:
		var before_draw := e.log_lines.size()
		var drawn_pick := _probe_select_weapon(combat, "light crossbow")
		_probe_check(drawn_pick, "the crossbow is selected again")
		for i in 10:
			await get_tree().process_frame
		var drawn := _probe_ranged_new_lines(e, before_draw)
		_probe_check(drawn.contains("draws Light Crossbow (move action; PHB p.142)"), "drawing costs its own move action")
		_probe_check(
			String(sera.equipment.get("weapon", {}).get("id", "")) == "light_crossbow",
			"state: the crossbow is readied",
		)
		_probe_check(e.threat_capability(sera).is_empty(), "state: a readied crossbow gives no melee threat")
		await _probe_shot("weapons", "03_drawn")
		var hp_before := target.hp
		await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
		await _probe_click_cell(combat, e.cell_of(target), "aim at the target")
		for i in 12:
			await get_tree().process_frame
		_probe_check(
			String(Game.last_ui_message).contains("not loaded"),
			"the status message explains that an unloaded crossbow cannot fire",
		)
		_probe_check(
			not _probe_ranged_new_lines(e, before_draw).contains("Light Crossbow:"),
			"no attack roll is made for the refused shot",
		)
		_probe_check(target.hp == hp_before, "state: the refused shot changed nothing")
		_probe_check(not e.is_weapon_loaded(sera), "state: a refused shot does not load the weapon")
		await _probe_shot("weapons", "04_unloaded_refusal")
		var round_three := await _probe_advance_to(combat, "sera", 3)
		_probe_check(round_three, "the rogue gets a third turn")
		if round_three:
			var before_load := e.log_lines.size()
			await _probe_click(_probe_button(combat.button_box, "Load weapon"), "Load weapon")
			for i in 12:
				await get_tree().process_frame
			var loaded := _probe_ranged_new_lines(e, before_load)
			_probe_check(loaded.contains("loads Light Crossbow (move action"), "loading costs a move action")
			_probe_check(e.is_weapon_loaded(sera), "state: the crossbow is loaded")
			await _probe_shot("weapons", "05_loaded")
			var before_shot := e.log_lines.size()
			await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
			await _probe_click_cell(combat, e.cell_of(target), "fire at the target")
			for i in 16:
				await get_tree().process_frame
			var shot := _probe_ranged_new_lines(e, before_shot)
			_probe_check(shot.contains("Light Crossbow"), "the resolved attack uses the crossbow")
			_probe_check(
				shot.contains("vs AC") and (shot.contains("damage") or shot.contains("MISS")),
				"the shot resolves with its own roll and outcome",
			)
			_probe_check(not e.is_weapon_loaded(sera), "state: firing spends the shot")
			await _probe_shot("weapons", "06_fired")
			var round_four := await _probe_advance_to(combat, "sera", 4)
			if round_four:
				await _probe_click(_probe_button(combat.button_box, "Sheathe weapon"), "Sheathe weapon")
				for i in 10:
					await get_tree().process_frame
				_probe_check(sera.equipment.get("weapon", {}).is_empty(), "state: the crossbow is sheathed")
				var round_five := await _probe_advance_to(combat, "sera", 5)
				_probe_check(round_five, "the rogue gets a fifth turn")
				if round_five:
					var before_back := e.log_lines.size()
					var back := _probe_select_weapon(combat, "short sword")
					_probe_check(back, "the sword is selected again")
					for i in 10:
						await get_tree().process_frame
					var returned := _probe_ranged_new_lines(e, before_back)
					_probe_check(returned.contains("draws Short Sword"), "returning to melee costs its own move action")
					_probe_check(
						String(sera.equipment.get("weapon", {}).get("id", "")) == "short_sword",
						"state: the sword is readied again",
					)
					_probe_check(not e.threat_capability(sera).is_empty(), "state: melee threat returns with the sword")
					await _probe_shot("weapons", "07_back_to_melee")
	_probe_finish("weapons")


func _probe_select_weapon(combat: Control, needle: String) -> bool:
	if combat == null:
		return false
	var option: OptionButton = combat.weapon_option
	if option == null:
		return false
	for i in option.item_count:
		if option.get_item_text(i).to_lower().contains(needle):
			option.select(i)
			option.item_selected.emit(i)
			return true
	return false


## QA-only (--integration-probe, fixture --demo-integration). Plays the shipped
## town-square encounter with the unmodified pregens and standard zombies, using
## the ordinary controls: opening flat-footedness, a melee attack against a
## flat-footed enemy, a thrown attack into a melee, and an ordinary spell cast
## while threatened. It reports rule behavior, not a difficulty judgment.
func _integration_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "integration"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var combat := current_screen
	var e := Game.encounter
	if combat == null or e == null:
		_probe_check(false, "the campaign encounter is running")
		_probe_finish("integration")
		return
	var opening := false
	for line in e.log_lines:
		if String(line).contains("All combatants are flat-footed"):
			opening = true
	_probe_check(opening, "the opening announces combat-start flat-footedness")
	var enemies: Array = []
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			enemies.append(entry)
	var all_flat := not enemies.is_empty()
	for entry in enemies:
		if not e.is_flat_footed(int(entry["index"])):
			all_flat = false
	_probe_check(all_flat, "state: every enemy starts flat-footed")
	await _probe_shot("integration", "00_opening")
	# Rendered evidence of the state, before anyone has acted: the enemy panel's
	# own AC line says the target is flat-footed.
	var first_enemy: Character = enemies[0]["char"]
	await _probe_open_inspect(combat, first_enemy)
	_probe_check(
		_probe_modal_text().contains("flat-footed"), "the enemy panel reports flat-footed"
	)
	await _probe_shot("integration", "01_flat_footed_panel")
	close_modal()
	for i in 4:
		await get_tree().process_frame
	var kaelen: Character = null
	var ysolde: Character = null
	for entry in e.combatants:
		var ch: Character = entry["char"]
		if String(ch.id) == "kaelen":
			kaelen = ch
		elif String(ch.id) == "ysolde":
			ysolde = ch
	var kaelen_ready := await _probe_advance_to(combat, "kaelen")
	_probe_check(kaelen_ready, "Kaelen's turn arrives")
	if kaelen_ready and kaelen != null:
		var before := e.log_lines.size()
		var active_entry := e.active_entry()
		var active_cell: Vector2i = active_entry.get("cell", Vector2i(-1, -1))
		var target := _probe_nearest_enemy(e)
		_probe_check(target != null, "a living enemy is available to attack")
		var was_flat := false
		if target != null:
			was_flat = e.is_flat_footed(int(e.entry_for(target).get("index", -1)))
			var enemy_cell := e.cell_of(target)
			if e.map.distance_ft(active_cell, enemy_cell) > 5:
				var dest := _probe_melee_approach(
					enemy_cell, active_cell, int(active_entry.get("index", -1))
				)
				var move_button := _probe_button(combat.button_box, "Move")
				if dest.x >= 0 and move_button != null and not move_button.disabled:
					await _probe_click(move_button, "Move")
					await _probe_click_cell(combat, dest, "move toward the zombie")
			await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
			await _probe_click_cell(combat, e.cell_of(target), "attack the zombie")
			for i in 16:
				await get_tree().process_frame
		var fresh := _probe_ranged_new_lines(e, before)
		_probe_check(
			fresh.contains("is flat-footed") == was_flat,
			"the attack reports the flat-footed state the resolver actually applied"
		)
		_probe_check(fresh.contains("vs AC"), "the attack prints the AC it used")
		await _probe_shot("integration", "02_melee_attack")
	# Round 2: Ysolde throws her dagger, a ranged attack, at an engaged enemy.
	var throw_ready := await _probe_advance_to(combat, "ysolde", 2)
	_probe_check(throw_ready, "Ysolde's second-round turn arrives")
	if throw_ready and ysolde != null:
		var engaged := _probe_engaged_enemy(e)
		_probe_check(engaged != null, "an enemy is engaged with a party member")
		var mode_ok := _probe_select_attack_mode(combat, "thrown")
		_probe_check(mode_ok, "the attack-mode control offers a ranged mode")
		if engaged != null:
			var before_throw := e.log_lines.size()
			await _probe_click(_probe_button(combat.button_box, "Attack"), "Attack")
			await _probe_click_cell(combat, e.cell_of(engaged), "throw at the engaged zombie")
			for i in 16:
				await get_tree().process_frame
			var thrown := _probe_ranged_new_lines(e, before_throw)
			_probe_check(thrown.contains("shooting into melee -4"), "the throw takes the printed -4")
			await _probe_shot("integration", "03_thrown_into_melee")
	# Round 3: Ysolde moves into reach of a zombie and casts normally, so the
	# cast provokes and any damage forces her real (untrained) Concentration check.
	var cast_ready := await _probe_advance_to(combat, "ysolde", 3)
	_probe_check(cast_ready, "Ysolde's third-round turn arrives")
	if cast_ready and ysolde != null:
		var slot_before := int(ysolde.spells["slots"]["1"].get("used", 0))
		var victim := _probe_nearest_enemy(e)
		_probe_check(victim != null, "a living enemy is available to target")
		if victim != null:
			var victim_cell := e.cell_of(victim)
			var active_entry := e.active_entry()
			var active_cell: Vector2i = active_entry.get("cell", Vector2i(-1, -1))
			if e.map.distance_ft(active_cell, victim_cell) > 5:
				var dest := _probe_melee_approach(
					victim_cell, active_cell, int(active_entry.get("index", -1))
				)
				var move_button := _probe_button(combat.button_box, "Move")
				if dest.x >= 0 and move_button != null and not move_button.disabled:
					await _probe_click(move_button, "Move")
					await _probe_click_cell(combat, dest, "move into the zombie's reach")
			var before_cast := e.log_lines.size()
			await _probe_cast_spell(combat, "Magic Missile", e.cell_of(victim), false)
			var cast_text := _probe_ranged_new_lines(e, before_cast)
			_probe_check(cast_text.contains("provokes"), "ordinary casting in reach provokes")
			if cast_text.contains("injury while casting"):
				_probe_check(
					cast_text.contains("Concentration check:"),
					"the interruption forces a Concentration check",
				)
				var failed := cast_text.contains("FAILED")
				_probe_check(
					(not failed and cast_text.contains("casts Magic Missile."))
						or (failed and cast_text.contains("The spell is disrupted")),
					"the outcome matches the check",
				)
			else:
				_probe_check(
					cast_text.contains("casts Magic Missile."),
					"an undamaged cast completes",
				)
			_probe_check(
				int(ysolde.spells["slots"]["1"].get("used", 0)) == slot_before + 1,
				"state: exactly one slot was spent",
			)
			await _probe_shot("integration", "04_cast_threatened")
	_probe_finish("integration")


func _probe_nearest_enemy(e: Encounter) -> Character:
	var active := e.active_character()
	if active == null:
		return null
	var from := e.cell_of(active)
	var best := 9999
	var found: Character = null
	for entry in e.combatants:
		if int(entry["team"]) != Encounter.TEAM_ENEMY:
			continue
		var ch: Character = entry["char"]
		if ch.has_condition("dead"):
			continue
		var distance := e.map.distance_ft(from, entry["cell"])
		if distance < best:
			best = distance
			found = ch
	return found


func _probe_engaged_enemy(e: Encounter) -> Character:
	for entry in e.combatants:
		if int(entry["team"]) != Encounter.TEAM_ENEMY:
			continue
		var enemy: Character = entry["char"]
		if enemy.has_condition("dead"):
			continue
		for other in e.combatants:
			if int(other["team"]) != Encounter.TEAM_PARTY:
				continue
			if e.map.distance_ft(entry["cell"], other["cell"]) <= 5:
				return enemy
	return null


## Selects an attack mode through the screen's own option control. Used because a
## thrown dagger is the only ranged attack the shipped pregens carry.
func _probe_select_attack_mode(combat: Control, needle: String) -> bool:
	if combat == null:
		return false
	var option: OptionButton = combat.get("attack_mode_option")
	if option == null:
		return false
	for i in option.item_count:
		var text := option.get_item_text(i).to_lower()
		var meta := String(option.get_item_metadata(i)).to_lower()
		if text.contains(needle) or meta.contains(needle):
			option.select(i)
			option.item_selected.emit(i)
			return true
	return false


## QA-only (--concentration-probe, fixture --demo-concentration). Drives the real
## spell list, its defensive checkbox and the target cell, and asserts the
## rendered log for each case. Backend state (slots, target HP) is checked
## separately and labelled `state:` so the two kinds of evidence stay distinct.
func _concentration_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trip-shots="):
			probe_shots = arg.substr("--trip-shots=".length())
	DirAccess.make_dir_recursive_absolute(probe_shots)
	probe_scenario = "concentration"
	probe_started_ms = Time.get_ticks_msec()
	_probe_watchdog()
	get_window().size = probe_size
	for i in 8:
		await get_tree().process_frame
	var combat := current_screen
	var e := Game.encounter
	if combat == null or e == null:
		_probe_check(false, "combat screen with an encounter exists")
		_probe_finish("concentration")
		return
	var good: Character = null
	var weak: Character = null
	var feat_caster: Character = null
	var target: Character = null
	for entry in e.combatants:
		var ch: Character = entry["char"]
		match String(ch.id):
			"qa_conc_good": good = ch
			"qa_conc_weak": weak = ch
			"qa_conc_feat": feat_caster = ch
			"qa_conc_target": target = ch
	if good == null or weak == null or feat_caster == null or target == null:
		_probe_check(false, "the concentration fixture has both casters and a target")
		_probe_finish("concentration")
		return
	var target_cell := e.cell_of(target)
	# Round 1 starts with everyone flat-footed (PHB p. 134), and a flat-footed
	# creature cannot take an attack of opportunity. Wait for round 2 so the
	# reactions being measured are legal.
	var second_round := await _probe_advance_to(combat, "qa_conc_good", 2)
	_probe_check(second_round, "the prepared caster acts after the enemies' first turns")
	target_cell = e.cell_of(target)
	await _probe_shot("concentration", "00_start")
	# ------------------------------- ordinary cast, damage, check succeeds
	var before := e.log_lines.size()
	var cast_ok := await _probe_cast_spell(combat, "Magic Missile", target_cell, false)
	_probe_check(cast_ok, "the spell list, its buttons and the target cell were usable")
	var fresh := _probe_ranged_new_lines(e, before)
	_probe_check(fresh.contains("while threatened and provokes"), "ordinary casting in a threatened square provokes")
	_probe_check(fresh.contains("injury while casting"), "the damage triggers an injury check")
	_probe_check(fresh.contains("Concentration check:") and fresh.contains("success"), "the check is shown and succeeds")
	_probe_check(fresh.contains("casts Magic Missile."), "the spell then resolves")
	var hp_after_good := target.hp
	_probe_check(hp_after_good < target.max_hp, "state: the spell damaged the target")
	await _probe_shot("concentration", "01_injury_success")
	# ------------------------------- ordinary cast, damage, check fails
	var weak_ready := await _probe_advance_to(combat, "qa_conc_weak")
	_probe_check(weak_ready, "the untrained caster's turn arrives")
	if weak_ready:
		target_cell = e.cell_of(target)
		before = e.log_lines.size()
		await _probe_cast_spell(combat, "Magic Missile", target_cell, false)
		fresh = _probe_ranged_new_lines(e, before)
		_probe_check(fresh.contains("injury while casting"), "the injury check is required here too")
		_probe_check(fresh.contains("FAILED"), "the untrained check fails")
		_probe_check(fresh.contains("The spell is disrupted"), "the log states the disruption")
		_probe_check(
			not fresh.contains("casts Magic Missile."), "no completed-cast line is written"
		)
		_probe_check(target.hp == hp_after_good, "state: the disrupted spell had no effect")
		_probe_check(
			int(weak.spells["slots"]["1"].get("used", 0)) == 1,
			"state: the level-1 slot was spent anyway",
		)
		await _probe_shot("concentration", "02_injury_failure")
	# ------------------------------- defensive cast, check succeeds
	var good_ready := await _probe_advance_to(combat, "qa_conc_good")
	_probe_check(good_ready, "the prepared caster acts again next round")
	if good_ready:
		var hp_before_defensive := target.hp
		target_cell = e.cell_of(target)
		before = e.log_lines.size()
		await _probe_cast_spell(combat, "Magic Missile", target_cell, true)
		fresh = _probe_ranged_new_lines(e, before)
		_probe_check(fresh.contains("casts Magic Missile defensively"), "the defensive mode is named")
		_probe_check(not fresh.contains("provokes"), "defensive casting does not provoke")
		_probe_check(not fresh.contains("Attack of opportunity by"), "no reaction is rolled")
		_probe_check(fresh.contains("DC 15 + 1 = DC 16"), "the defensive DC is 15 + spell level")
		_probe_check(target.hp < hp_before_defensive, "state: the defensive spell took effect")
		await _probe_shot("concentration", "03_defensive_success")
	# ------------------------------- defensive cast, check fails
	var weak_again := await _probe_advance_to(combat, "qa_conc_weak")
	_probe_check(weak_again, "the untrained caster acts again next round")
	if weak_again:
		var hp_before_failed := target.hp
		target_cell = e.cell_of(target)
		before = e.log_lines.size()
		await _probe_cast_spell(combat, "Scorching Ray", target_cell, true)
		fresh = _probe_ranged_new_lines(e, before)
		_probe_check(fresh.contains("casts Scorching Ray defensively"), "the defensive ray is named")
		_probe_check(not fresh.contains("Attack of opportunity by"), "defensive casting still does not provoke")
		_probe_check(fresh.contains("FAILED") and fresh.contains("The spell is disrupted"), "the failed check loses the ray")
		_probe_check(target.hp == hp_before_failed, "state: the disrupted ray had no effect")
		_probe_check(
			int(weak.spells["slots"]["2"].get("used", 0)) == 1,
			"state: the level-2 slot was spent",
		)
		await _probe_shot("concentration", "04_defensive_failure")
	# ------------------------------- Combat Casting adds +4 to the defensive check
	var feat_ready := await _probe_advance_to(combat, "qa_conc_feat")
	_probe_check(feat_ready, "the feat-holder's turn arrives")
	if feat_ready:
		target_cell = e.cell_of(target)
		before = e.log_lines.size()
		await _probe_cast_spell(combat, "Magic Missile", target_cell, true)
		fresh = _probe_ranged_new_lines(e, before)
		_probe_check(fresh.contains("casts Magic Missile defensively"), "the defensive cast is named")
		_probe_check(fresh.contains("DC 15 + 1 = DC 16"), "the feat does not change the DC")
		_probe_check(
			fresh.contains("Combat Casting +4"), "the feat's +4 appears in the roll breakdown"
		)
		_probe_check(
			fresh.contains("CON modifier -5"), "the breakdown also shows the Con modifier"
		)
		_probe_check(not fresh.contains("Attack of opportunity by"), "still no reaction")
		_probe_check(
			int(feat_caster.spells["slots"]["1"].get("used", 0)) == 1,
			"state: the feat-holder's slot was spent once",
		)
		await _probe_shot("concentration", "05_combat_casting")
	_probe_finish("concentration")


## Opens the spell list, sets the defensive checkbox through the real control, and
## picks the spell and target.
func _probe_cast_spell(
	combat: Control, spell_prefix: String, cell: Vector2i, defensive: bool
) -> bool:
	await _probe_click(_probe_button(combat.button_box, "Cast spell"), "Cast spell")
	for i in 6:
		await get_tree().process_frame
	var box := _probe_defensive_checkbox()
	if box == null:
		return false
	if box.button_pressed != defensive:
		await _probe_click(box, "defensive casting checkbox")
		for i in 3:
			await get_tree().process_frame
	if box.button_pressed != defensive:
		return false
	var chosen := await _probe_click_modal_button(spell_prefix)
	if not chosen:
		return false
	await _probe_click_cell(combat, cell, "cast %s at the target" % spell_prefix)
	for i in 16:
		await get_tree().process_frame
	return true


func _probe_defensive_checkbox() -> CheckBox:
	if modal == null:
		return null
	for node in modal.find_children("*", "CheckBox", true, false):
		return node as CheckBox
	return null


## Opens the enemy panel through its real row button, scrolling it into view first.
func _probe_open_inspect(combat: Control, target: Character) -> void:
	var button := _probe_enemy_inspect_button(combat, target.display_name)
	_probe_check(button != null, "the inspect control for %s exists" % target.display_name)
	if button == null:
		return
	var container := button.get_parent()
	while container != null and not (container is ScrollContainer):
		container = container.get_parent()
	if container is ScrollContainer:
		(container as ScrollContainer).ensure_control_visible(button)
		await get_tree().process_frame
	await _probe_click(button, "inspect %s" % target.display_name)
	for i in 5:
		await get_tree().process_frame


func _probe_enemy_inspect_button(combat: Control, display_name: String) -> Button:
	for child in combat.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text != "Inspect":
			continue
		var row := button.get_parent()
		if row == null:
			continue
		for sibling in row.get_children():
			var value = sibling.get("text")
			if value != null and String(value).contains(display_name):
				return button
	return null


## Finds a button inside the enemy row whose text contains `display_name`.
func _probe_enemy_row_button(combat: Control, display_name: String, text: String) -> Button:
	for child in combat.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text != text:
			continue
		var row := button.get_parent()
		if row == null:
			continue
		for sibling in row.get_children():
			var value = sibling.get("text")
			if value != null and String(value).contains(display_name):
				return button
	return null


func _probe_modal_text() -> String:
	if modal == null:
		return ""
	var parts: Array[String] = []
	for node in modal.find_children("*", "", true, false):
		var value = node.get("text")
		if value != null:
			parts.append(String(value))
	return "\n".join(parts)


## The AC line of the enemy panel, so a check never matches unrelated prose.
func _probe_modal_ac_line() -> String:
	for line in _probe_modal_text().split("\n"):
		if String(line).contains("• AC "):
			return String(line)
	return ""


func _probe_modal_labels_fit() -> bool:
	if modal == null:
		return false
	var panels := modal.find_children("*", "PanelContainer", true, false)
	if panels.is_empty():
		return false
	var inner: Rect2 = (panels[0] as Control).get_global_rect().grow(-1.0)
	for node in modal.find_children("*", "RichTextLabel", true, false):
		var rect: Rect2 = (node as Control).get_global_rect()
		if rect.size.x <= 0.0:
			continue
		if rect.position.x < inner.position.x - 1.0 or rect.end.x > inner.end.x + 1.0:
			return false
		if rect.position.y < inner.position.y - 1.0 or rect.end.y > inner.end.y + 1.0:
			return false
	return true


func _probe_close_modal() -> void:
	var close := _probe_button(modal, "Close (Esc)")
	if close != null:
		await _probe_click(close, "close modal")
	for i in 4:
		await get_tree().process_frame


## Sets the text size by clicking the real Settings slider at its maximum.
func _probe_set_text_scale(value: float) -> void:
	_open_settings()
	for i in 6:
		await get_tree().process_frame
	var sliders := modal.find_children("*", "HSlider", true, false)
	_probe_check(not sliders.is_empty(), "the Settings panel exposes sliders")
	if sliders.is_empty():
		return
	var slider := sliders[sliders.size() - 1] as HSlider
	_probe_check(
		is_equal_approx(float(slider.max_value), value),
		"the Text size slider spans up to %.1f" % value,
	)
	var container := slider.get_parent()
	while container != null and not (container is ScrollContainer):
		container = container.get_parent()
	if container is ScrollContainer:
		(container as ScrollContainer).ensure_control_visible(slider)
		await get_tree().process_frame
	var rect := slider.get_global_rect()
	await _probe_click_at(
		Vector2(rect.end.x - 3.0, rect.position.y + rect.size.y * 0.5), "Text size slider maximum"
	)
	for i in 4:
		await get_tree().process_frame
	await _probe_close_modal()


## QA-only Trip fixture (--demo-trip, variant via --trip-scenario=<id>). It
## derives a temporary fighter from pregen data — shipped characters, encounters
## and monsters are untouched — and sets initial conditions only. It never edits
## a roll or an outcome after an action, so what the interface shows is ordinary
## resolution with a documented starting state.
func _qa_trip_demo(scenario: String) -> void:
	var data := Game.content.get_character("kaelen")
	var qa := Character.from_content(data, Game.content.items)
	qa.id = "qa_trip_fighter"
	qa.display_name = "QA Trip Fighter"
	qa.abilities["int"] = 13
	qa.feats.append("Power Attack")
	qa.feats.append("Combat Expertise")
	qa.equip("weapon", Game.content.get_item("light_flail"))
	Game.party.clear()
	Game.party.append(qa)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA TRIP FAILED: encounter did not start")
		return
	var enemy: Character = null
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			enemy = entry["char"]
			break
	if enemy == null:
		print("QA TRIP FAILED: no enemy in the fixture encounter")
		return
	enemy.max_hp = 200
	enemy.hp = 200
	enemy.damage_reduction.clear()
	enemy.ac_misc = -10
	# Improved Trip adds a feat to the temporary fighter; prerequisites are met
	# up front and no roll or outcome is edited after an action.
	if scenario.begins_with("improved_trip"):
		qa.abilities["int"] = 13
		qa.feats.append("Combat Expertise")
		qa.feats.append("Improved Trip")
		if scenario == "improved_trip":
			qa.unequip("weapon")
	var note := ""
	match scenario:
		"success":
			enemy.stability_bonus = -40
			note = "Tick 'Use equipped trip weapon', click Trip, then click the enemy: touch and opposed check always succeed."
		"touch_fail":
			enemy.ac_misc = 40
			note = "Tick 'Use equipped trip weapon' and click Trip, then the enemy: the touch attack misses and the standard action is still spent."
		"counter_drop", "counter_keep", "return":
			enemy.stability_bonus = 40
			note = (
				"Tick 'Use equipped trip weapon', click Trip, then the enemy: the counter-trip succeeds. Choose 'Drop weapon'."
				if scenario == "counter_drop"
				else "Tick 'Use equipped trip weapon', click Trip, then the enemy: the counter-trip succeeds. Choose 'Keep weapon'."
			)
			if scenario == "return":
				enemy.max_hp = 1
				enemy.hp = 1
				note = "Trip, choose 'Keep weapon', attack the prone enemy (it dies), then confirm combat returns to exploration."
		"prone":
			qa.set_prone(true)
			note = "The fighter starts prone: Attack shows the -4 melee penalty, prone AC applies, and Stand up is available."
		"stand_aoo":
			qa.set_prone(true)
			note = "The fighter starts prone beside the enemy: Stand up provokes a real opportunity attack while still prone."
		"pickup":
			qa.unequip("weapon")
			note = "Two items lie in the fighter's square: Pick up spends a move action, provokes, and stores the item unequipped."
		"crawl":
			qa.set_prone(true)
			note = "The fighter starts prone: Move permits only a 5-ft crawl that provokes; a 5-ft step is refused."
		"improved_trip":
			enemy.stability_bonus = -40
			note = "Click Trip, then the enemy: the unarmed trip does not provoke and Improved Trip offers an immediate attack. Choose 'Make the extra attack'."
		"improved_trip_decline":
			enemy.stability_bonus = -40
			note = "Click Trip, then the enemy: Improved Trip offers an immediate attack. Choose 'Decline extra attack' to return to ordinary play."
		_:
			print("QA TRIP FAILED: unknown scenario '%s'" % scenario)
			return
	if scenario == "pickup":
		var cell := e.cell_of(qa)
		e.ground_items.append(
			{"id": "dagger", "item": Game.content.get_item("dagger"), "cell": cell}
		)
		e.ground_items.append(
			{"id": "light_flail", "item": Game.content.get_item("light_flail"), "cell": cell}
		)
	for i in e.order:
		if e.combatants[i]["char"] == qa:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			break
	if scenario in ["prone", "stand_aoo", "crawl"]:
		qa.set_prone(true)
	Game.emit_signal("state_changed")
	print("QA TRIP READY: scenario=%s actor=%s" % [scenario, qa.display_name])
	print("QA TRIP INSTRUCTIONS: %s" % note)


## QA-only Cleave fixture (--demo-cleave, variant via --cleave-scenario=<id>).
## Derives a temporary fighter with the feat and sets starting conditions only;
## every drop and every decision below comes from ordinary resolution.
func _qa_cleave_demo(scenario: String) -> void:
	var data := Game.content.get_character("kaelen")
	var qa := Character.from_content(data, Game.content.items)
	qa.id = "qa_cleave_fighter"
	qa.display_name = "QA Cleave Fighter"
	qa.abilities["str"] = 13
	qa.feats.append("Power Attack")
	qa.feats.append("Cleave")
	qa.equip("weapon", Game.content.get_item("masterwork_longsword"))
	if scenario == "cleave_from_trip":
		qa.abilities["int"] = 13
		qa.feats.append("Combat Expertise")
		qa.feats.append("Improved Trip")
	Game.party.clear()
	Game.party.append(qa)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	if e == null:
		print("QA CLEAVE FAILED: encounter did not start")
		return
	var first: Character = null
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			first = entry["char"]
			break
	if first == null:
		print("QA CLEAVE FAILED: no enemy in the fixture encounter")
		return
	# One hit point and a very low AC make the seeded attack land; the fixture
	# never edits a roll or an outcome after an action.
	first.max_hp = 200
	first.hp = 1
	first.damage_reduction.clear()
	first.ac_misc = -30
	if scenario.begins_with("cleave_offturn"):
		_qa_cleave_offturn_demo(scenario, qa, first)
		return
	if scenario == "cleave_from_trip":
		first.stability_bonus = -40
	var note := "Click Attack, then the first enemy: it drops and Cleave offers the second enemy in reach."
	if scenario != "cleave_no_target":
		var second := Character.from_content(Game.content.get_monster("zombie"), Game.content.items)
		second.id = "qa_cleave_second"
		second.display_name = "QA Cleave Second"
		second.max_hp = 200
		second.hp = 1
		second.ac_misc = -30
		second.damage_reduction.clear()
		e.add_combatant(second, Vector2i(3, 3), Encounter.TEAM_ENEMY)
		e.order.append(int(e.combatants.size() - 1))
	match scenario:
		"cleave":
			pass
		"cleave_decline":
			note = "Click Attack, then the first enemy, then 'Decline extra attack': the second enemy is untouched and normal play resumes."
		"cleave_no_target":
			note = "One enemy only: dropping it ends the encounter without a Cleave decision."
		"cleave_from_trip":
			note = "Click Trip, then the first enemy, then 'Make the extra attack': the follow-up drops it and Cleave offers the second enemy."
		_:
			print("QA CLEAVE FAILED: unknown scenario '%s'" % scenario)
			return
	for i in e.order:
		if e.combatants[i]["char"] == qa:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			break
	Game.emit_signal("state_changed")
	print("QA CLEAVE READY: scenario=%s actor=%s" % [scenario, qa.display_name])
	print("QA CLEAVE INSTRUCTIONS: %s" % note)


## QA-only off-turn Cleave fixture. A turned enemy flees past the fighter, whose
## real opportunity attack drops it. The interrupted turn is executed once here;
## the decision itself is driven through the real controls.
func _qa_cleave_offturn_demo(scenario: String, qa: Character, mover: Character) -> void:
	var e := Game.encounter
	var ally := Character.from_content(Game.content.get_character("aldric"), Game.content.items)
	ally.id = "qa_cleave_cleric"
	ally.display_name = "QA Cleave Cleric"
	Game.party.append(ally)
	e.add_combatant(ally, Vector2i(1, 1), Encounter.TEAM_PARTY)
	var second := Character.from_content(Game.content.get_monster("zombie"), Game.content.items)
	second.id = "qa_cleave_second"
	second.display_name = "QA Cleave Second"
	second.max_hp = 200
	second.hp = 1
	second.ac_misc = -30
	second.damage_reduction.clear()
	e.add_combatant(second, Vector2i(3, 2), Encounter.TEAM_ENEMY)
	var sentinel := Character.from_content(Game.content.get_monster("zombie"), Game.content.items)
	sentinel.id = "qa_cleave_sentinel"
	sentinel.display_name = "QA Cleave Sentinel"
	sentinel.max_hp = 60
	sentinel.hp = 60
	e.add_combatant(sentinel, Vector2i(0, 0), Encounter.TEAM_ENEMY)
	mover.display_name = "QA Cleave Mover"
	mover.add_effect("turned", "Turned", 10, "condition")
	var effect := mover.get_effect("turned")
	effect["turner_id"] = ally.id
	effect["turner_name"] = ally.display_name
	e.order.clear()
	for member in [qa, mover, second, sentinel]:
		e.order.append(int(e.entry_for(member)["index"]))
	e.turn_ptr = 1
	e._begin_turn(e.combatants[int(e.order[1])])
	e._run_monster_turn(e.combatants[int(e.order[1])])
	Game.emit_signal("state_changed")
	print(
		"QA CLEAVE READY: scenario=%s actor=%s pending=%s"
		% [scenario, mover.display_name, str(e.pending_cleave.get("type", ""))]
	)
	print(
		"QA CLEAVE INSTRUCTIONS: %s"
		% (
			"Decline the off-turn Cleave decision; the interrupted turn then finishes."
			if scenario == "cleave_offturn_decline"
			else "Accept the off-turn Cleave decision against QA Cleave Second; the interrupted turn then finishes."
		)
	)


func _qa_spend_turning_uses(count: int) -> void:
	for ch in Game.party:
		if ch.id != "aldric":
			continue
		for i in count:
			ch.consume_turn_undead()


func _continue_game() -> void:
	var result := Game.continue_latest()
	if not bool(result.get("ok", false)):
		_show_menu()
		return
	_route()


## Campaign selection is the player-facing entry to the platform. Every package
## uses the same loader, validation, party selection, play and save systems; the
## only differences are content files.
func _show_campaign_select() -> void:
	close_modal()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	root.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	box.add_child(ThemeBuilder.heading("Campaigns", 30))
	box.add_child(ThemeBuilder.body(
		"Each campaign is a content package played on the same rules platform. Shared rules live once in content/shared; a campaign adds only its own areas, dialogue, quests and encounters.",
		true,
		14
	))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Keyboard traversal is a supported way through this list. Without this,
	# Tab can focus an action outside the viewport and the list never follows it.
	scroll.follow_focus = true
	# Cards are designed as a vertical list; horizontal overflow would clip
	# wrapped descriptions and push actions off the visible edge.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	if not Game.campaigns.errors.is_empty():
		# Discovery skips a package it cannot read; without this notice the
		# author's campaign would simply be missing from the list with no reason.
		var notice := PanelContainer.new()
		notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(notice)
		var notice_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			notice_margin.add_theme_constant_override("margin_" + side, 10)
		notice.add_child(notice_margin)
		var notice_text := ThemeBuilder.body(
			"Some campaign packages could not be read and are not listed:
"
			+ "
".join(Game.campaigns.errors.slice(0, 4)),
			true,
			12
		)
		notice_text.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		notice_margin.add_child(notice_text)
	for raw_id in Game.campaigns.order:
		var campaign_key := String(raw_id)
		var manifest: Dictionary = Game.campaigns.get_campaign(campaign_key)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(card)
		var card_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			card_margin.add_theme_constant_override("margin_" + side, 12)
		card.add_child(card_margin)
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 6)
		card_margin.add_child(card_box)
		var title_label := ThemeBuilder.heading(String(manifest.get("title", campaign_key)), 22)
		# The authoring title limit is 80 characters; that still exceeds the card
		# width at the largest text scale, so wrap it instead of widening the list.
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_box.add_child(title_label)
		var meta := ThemeBuilder.body(
			"%s • format %s • content version %s • entry %s" % [
				campaign_key,
				manifest.get("format_version", "?"),
				manifest.get("version", "?"),
				String(Dictionary(manifest.get("entry", {})).get("area", "?")),
			],
			true,
			12
		)
		meta.add_theme_color_override("font_color", ThemeBuilder.MUTED)
		card_box.add_child(meta)
		var source_label := ThemeBuilder.body(
			"USER CAMPAIGN — editable" if bool(manifest.get("writable", false)) else "Bundled package — read-only",
			true,
			11
		)
		source_label.add_theme_color_override(
			"font_color", ThemeBuilder.BLUE if bool(manifest.get("writable", false)) else ThemeBuilder.MUTED
		)
		card_box.add_child(source_label)
		card_box.add_child(ThemeBuilder.body(String(manifest.get("description", "")), false, 14))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		card_box.add_child(actions)
		var has_saves := Game.has_campaign_save(campaign_key)
		var captured := campaign_key
		var start := Button.new()
		start.text = "New game"
		start.custom_minimum_size = Vector2(150, 38)
		start.pressed.connect(func() -> void: _choose_campaign(captured))
		actions.add_child(start)
		var continue_button := Button.new()
		continue_button.text = "Continue latest"
		continue_button.disabled = not has_saves
		if continue_button.disabled:
			continue_button.focus_mode = Control.FOCUS_NONE
		continue_button.custom_minimum_size = Vector2(170, 38)
		continue_button.pressed.connect(func() -> void: _select_campaign_and_continue(captured))
		actions.add_child(continue_button)
		var load_button := Button.new()
		load_button.text = "Load slot"
		load_button.disabled = not has_saves
		if load_button.disabled:
			load_button.focus_mode = Control.FOCUS_NONE
		load_button.custom_minimum_size = Vector2(120, 38)
		load_button.pressed.connect(func() -> void: _select_campaign_and_load(captured))
		actions.add_child(load_button)
		var validate_button := Button.new()
		validate_button.text = "Validate"
		validate_button.custom_minimum_size = Vector2(120, 38)
		validate_button.pressed.connect(func() -> void: _validate_campaign_dialog(captured))
		actions.add_child(validate_button)
		if bool(manifest.get("writable", false)):
			var edit_button := Button.new()
			edit_button.text = "Edit"
			edit_button.custom_minimum_size = Vector2(100, 38)
			edit_button.pressed.connect(func() -> void: _open_creator(captured))
			actions.add_child(edit_button)
	box.add_child(ThemeBuilder.separator())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	var hint := ThemeBuilder.body(
		"Create campaign writes an editable copy under user://campaigns; bundled packages stay read-only and keep their accepted content unchanged.",
		true,
		12
	)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(hint)
	var create_button := Button.new()
	create_button.text = "Create campaign"
	create_button.custom_minimum_size = Vector2(160, 40)
	create_button.pressed.connect(_create_campaign_dialog)
	footer.add_child(create_button)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(120, 40)
	back.pressed.connect(_show_menu)
	footer.add_child(back)
	_set_screen(root)


func _choose_campaign(campaign_id: String) -> void:
	var loaded := Game.load_campaign(campaign_id)
	if not bool(loaded.get("ok", false)):
		_show_campaign_error(campaign_id, loaded)
		return
	party_selection.clear()
	_show_party_select()


func _select_campaign_and_continue(campaign_id: String) -> void:
	var loaded := Game.load_campaign(campaign_id)
	if not bool(loaded.get("ok", false)):
		_show_campaign_error(campaign_id, loaded)
		return
	_continue_game()


func _select_campaign_and_load(campaign_id: String) -> void:
	var loaded := Game.load_campaign(campaign_id)
	if not bool(loaded.get("ok", false)):
		_show_campaign_error(campaign_id, loaded)
		return
	_open_load_modal()


func _validate_campaign_dialog(campaign_id: String) -> void:
	var result := Game.validate_campaign(campaign_id)
	var errors: Array = result.get("errors", [])
	open_modal("Validate campaign", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		if errors.is_empty():
			box.add_child(ThemeBuilder.body(
				"%s validates: content, cross-references, entry point, party and required capabilities." % campaign_id,
				false,
				14
			))
		else:
			box.add_child(ThemeBuilder.body("%d problem(s) found:" % errors.size(), true, 14))
			for error in errors.slice(0, 12):
				box.add_child(ThemeBuilder.body("- " + String(error), true, 13))
		var close := Button.new()
		close.text = "Close"
		close.custom_minimum_size = Vector2(0, 40)
		close.pressed.connect(close_modal)
		box.add_child(close)
		return box
	, 860, 520)


func _show_campaign_error(campaign_id: String, result: Dictionary) -> void:
	var errors: Array = result.get("errors", [String(result.get("message", ""))])
	open_modal("Campaign unavailable", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body("'%s' could not be loaded." % campaign_id, true, 15))
		for error in errors.slice(0, 8):
			box.add_child(ThemeBuilder.body("- " + String(error), true, 13))
		var close := Button.new()
		close.text = "Close"
		close.custom_minimum_size = Vector2(0, 40)
		close.pressed.connect(close_modal)
		box.add_child(close)
		return box
	, 760, 400)


# ---------------------------------------------------------------- creator

func _create_campaign_dialog() -> void:
	var title_edit := LineEdit.new()
	title_edit.placeholder_text = "Campaign title"
	title_edit.custom_minimum_size = Vector2(0, 36)
	var id_edit := LineEdit.new()
	id_edit.placeholder_text = "campaign_id (lowercase letters, digits, underscores)"
	id_edit.custom_minimum_size = Vector2(0, 36)
	var status := ThemeBuilder.body("", true, 12)
	status.add_theme_color_override("font_color", ThemeBuilder.DANGER)
	var auto_id := {"enabled": true}
	title_edit.text_changed.connect(func(text: String) -> void:
		if bool(auto_id["enabled"]):
			id_edit.text = _slug_for_id(text)
	)
	id_edit.text_changed.connect(func(_text: String) -> void: auto_id["enabled"] = false)
	open_modal("Create campaign", func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(
			"Creates a writable user campaign from the neutral template: one 9x9 area, an entry point and a placeholder quest. Bundled packages stay read-only.",
			true,
			13
		))
		box.add_child(ThemeBuilder.body("Title", true, 13))
		box.add_child(title_edit)
		box.add_child(ThemeBuilder.body("Campaign id", true, 13))
		box.add_child(id_edit)
		box.add_child(ThemeBuilder.body("Stored in user://campaigns/<id>; the id becomes the save identity.", true, 11))
		box.add_child(status)
		var create := Button.new()
		create.text = "Create and edit"
		create.custom_minimum_size = Vector2(0, 40)
		create.pressed.connect(func() -> void:
			var result := CampaignStore.create(title_edit.text, id_edit.text.strip_edges())
			if not bool(result.get("ok", false)):
				status.text = String(result.get("message", "Could not create the campaign."))
				return
			Game.refresh_campaigns()
			close_modal()
			_open_creator(String(result.get("id", id_edit.text.strip_edges())))
		)
		box.add_child(create)
		var cancel := Button.new()
		cancel.text = "Cancel"
		cancel.custom_minimum_size = Vector2(0, 40)
		cancel.pressed.connect(close_modal)
		box.add_child(cancel)
		return box
	, 640, 420)


func _slug_for_id(text: String) -> String:
	var slug := ""
	for i in text.length():
		var ch := text.substr(i, 1).to_lower()
		if ch >= "a" and ch <= "z":
			slug += ch
		elif ch >= "0" and ch <= "9" and slug != "":
			slug += ch
		elif slug != "" and not slug.ends_with("_"):
			slug += "_"
	slug = slug.trim_suffix("_")
	if slug == "" or not (slug[0] >= "a" and slug[0] <= "z"):
		slug = "campaign_" + slug
	return slug.substr(0, 40)


## QA-only windowed fixture: one entry-placement diagnostic, no saved data.
func _start_creator_diagnostics_demo() -> void:
	var draft := CampaignStore.make_draft("Diagnostics Demo", "diagnostics_demo")
	draft["entry"] = {"area": "area_01", "pos": [0, 0], "facing": 0}
	_show_creator_draft(draft, true)
	call_deferred("_validate_creator_diagnostics_demo")


func _validate_creator_diagnostics_demo() -> void:
	var screen := current_screen as CampaignCreator
	if screen == null:
		return
	screen.title_edit.text = "Diagnostics Demo — unsaved title"
	screen.dirty = true
	screen._validate()


## Visual/QA fixture: one pending NPC name and one structured result that
## targets another NPC. It exercises the real pending prompt without writing.
func _start_creator_pending_demo() -> void:
	var draft := CampaignStore.make_draft("Pending Demo", "pending_demo")
	draft["entry"] = {"area": "area_01", "pos": [0, 0], "facing": 0}
	var area: Dictionary = Dictionary(Array(draft["areas"])[0])
	area["npcs"] = [
		{"id": "guide_a", "name": "Guide A", "look": "", "pos": [2, 2], "dialogue": "guide_talk"},
		{"id": "guide_b", "name": "Guide B", "look": "", "pos": [3, 2], "dialogue": "missing_talk"},
	]
	Array(draft["areas"])[0] = area
	CampaignStore.add_dialogue(draft, "guide_talk", "Guide A")
	_show_creator_draft(draft, true)
	call_deferred("_prepare_creator_pending_demo")


func _prepare_creator_pending_demo() -> void:
	var screen := current_screen as CampaignCreator
	if screen == null:
		return
	screen._select_npc_by_id("guide_b")
	screen.npc_name_edit.text = "Pending Guide B name"
	screen.last_focused_control = screen.npc_name_edit
	screen._validate()
	screen.focus_interaction_section()


func _open_creator(campaign_id: String) -> void:
	var loaded := CampaignStore.load_package(campaign_id)
	if not bool(loaded.get("ok", false)):
		_show_simple_error("Cannot edit campaign", String(loaded.get("message", "")))
		return
	_show_creator_draft(Dictionary(loaded.get("draft", {})))


func _show_creator_draft(draft: Dictionary, dirty := false) -> void:
	creator_draft = draft.duplicate(true)
	creator_dirty = dirty
	var screen := CampaignCreator.new()
	_set_screen(screen)
	screen.setup(self, creator_draft)
	if dirty:
		screen.dirty = true
		screen._refresh_all()


## Public entry used by the creator's Back/Save-and-leave paths.
func show_campaign_list() -> void:
	_show_campaign_select()


func start_creator_playtest(draft: Dictionary, staged: Dictionary, dirty := false) -> void:
	creator_draft = draft.duplicate(true)
	creator_dirty = dirty
	var campaign_id := String(draft.get("id", ""))
	var loaded := Game.load_campaign_snapshot(Dictionary(staged.get("manifest", {})))
	if not bool(loaded.get("ok", false)):
		CampaignStore.cleanup_playtest(campaign_id)
		_show_simple_error("Cannot playtest", String(loaded.get("message", "")))
		return
	Game.playtest_root = String(staged.get("root", ""))
	Game.playtest_mode = true
	var started := Game.new_game([], 424242, campaign_id)
	if not bool(started.get("ok", false)):
		Game.abandon_playtest()
		_show_simple_error("Cannot playtest", String(started.get("message", "")))
		return
	_route()


func _return_to_creator() -> void:
	Game.abandon_playtest()
	close_modal()
	if not creator_draft.is_empty():
		_show_creator_draft(creator_draft, creator_dirty)
	else:
		_show_campaign_select()


func _show_simple_error(title: String, message: String) -> void:
	open_modal(title, func() -> Control:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.add_child(ThemeBuilder.body(message, true, 14))
		var close := Button.new()
		close.text = "Close"
		close.custom_minimum_size = Vector2(0, 40)
		close.pressed.connect(close_modal)
		box.add_child(close)
		return box
	, 620, 260)


func _show_party_select() -> void:
	close_modal()
	var root := Control.new()
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	root.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	box.add_child(ThemeBuilder.heading("Choose your adventurers", 30))
	var party_cfg: Dictionary = Game.campaign.get("party", {})
	party_start_button = null
	box.add_child(ThemeBuilder.body(
		"Campaign: %s. Pick %s adventurers; the default four cover fighter, rogue, cleric and wizard." % [
			String(Game.campaign.get("title", "campaign")),
			Game.party_range_text(),
		],
		true,
		14
	))
	party_selection.clear()
	var defaults: Array = Array(party_cfg.get("default", ["kaelen"]))
	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.follow_focus = true
	box.add_child(grid_scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid_scroll.add_child(grid)
	for id in Game.content.playable_character_ids():
		var data := Game.content.get_character(id)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var card_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			card_margin.add_theme_constant_override("margin_" + side, 10)
		card.add_child(card_margin)
		var card_box := VBoxContainer.new()
		card_margin.add_child(card_box)
		var check := CheckBox.new()
		check.text = String(data.get("name", id))
		check.button_pressed = defaults.has(id)
		check.add_theme_font_size_override("font_size", ThemeBuilder.fs(18))
		check.toggled.connect(func(_pressed: bool) -> void: _update_selection(grid))
		check.set_meta("character_id", id)
		check.focus_entered.connect(func() -> void: grid_scroll.ensure_control_visible(card))
		card_box.add_child(check)
		var ch := Character.from_content(data, Game.content.items)
		var stats := "Level %d %s %s • HP %d • AC %d\nSTR %d DEX %d CON %d INT %d WIS %d CHA %d" % [
			ch.level,
			ch.race,
			ch.char_class,
			ch.max_hp,
			Rules.armor_class(ch),
			int(ch.abilities["str"]),
			int(ch.abilities["dex"]),
			int(ch.abilities["con"]),
			int(ch.abilities["int"]),
			int(ch.abilities["wis"]),
			int(ch.abilities["cha"]),
		]
		card_box.add_child(ThemeBuilder.body(stats, true, 13))
		card_box.add_child(ThemeBuilder.body(String(ch.notes), true, 12))
	box.add_child(ThemeBuilder.separator())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	party_error = ThemeBuilder.body("", true, 13)
	party_error.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(party_error)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(120, 40)
	back.pressed.connect(func() -> void: _show_campaign_select())
	footer.add_child(back)
	var start := Button.new()
	start.text = "Begin"
	start.custom_minimum_size = Vector2(160, 40)
	start.pressed.connect(func() -> void: _start_game())
	footer.add_child(start)
	party_start_button = start
	_set_screen(root)
	_update_selection(grid)


func _update_selection(grid: GridContainer) -> void:
	party_selection.clear()
	for child in grid.get_children():
		for sub in child.get_children():
			for control in sub.get_children():
				for candidate in control.get_children():
					if candidate is CheckBox and candidate.has_meta("character_id"):
						if candidate.button_pressed:
							party_selection.append(String(candidate.get_meta("character_id")))
	var refusal := Game.party_size_error(party_selection.size())
	if party_error != null:
		if refusal != "":
			party_error.text = refusal
			party_error.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		else:
			party_error.text = "%d selected." % party_selection.size()
			party_error.add_theme_color_override("font_color", ThemeBuilder.MUTED)
	if party_start_button != null:
		party_start_button.disabled = refusal != ""


func _start_game() -> void:
	# The refusal mirrors new_game's own check; the party screen never relies on
	# a hard-coded size, and the loaded campaign's declared range is the reason.
	var refusal := Game.party_size_error(party_selection.size())
	if refusal != "":
		if party_error != null:
			party_error.text = "Pick %s adventurers." % Game.party_range_text()
			party_error.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		return
	var result := Game.new_game(party_selection, -1)
	if not bool(result.get("ok", false)):
		if party_error != null:
			party_error.text = String(result.get("message", "Could not start."))
			party_error.add_theme_color_override("font_color", ThemeBuilder.DANGER)
		return
	_route()
	_show_intro()


func _show_intro() -> void:
	open_modal(
		String(Game.campaign.get("title", "Campaign")),
		func() -> Control:
			var box := VBoxContainer.new()
			box.custom_minimum_size = Vector2(720, 420)
			box.add_theme_constant_override("separation", 10)
			for line in Array(Game.content.narration.get("intro", [])):
				box.add_child(ThemeBuilder.body(String(line), false, 15))
			box.add_child(ThemeBuilder.separator())
			box.add_child(ThemeBuilder.body(
				"Nothing here is final content. Example placeholders stand in for art, audio and campaign writing.",
				true,
				13
			))
			var begin := Button.new()
			begin.text = "Begin the campaign"
			begin.custom_minimum_size = Vector2(0, 42)
			begin.pressed.connect(func() -> void: close_modal())
			box.add_child(begin)
			return box,
		800,
		520
	)


# ---------------------------------------------------------------- routing

func _on_mode_changed(mode: String) -> void:
	match mode:
		"menu":
			_show_menu()
		"combat":
			_show_combat()
		"defeat":
			_show_defeat()
		"dialogue":
			_ensure_exploration()
			if current_screen != null and current_screen.has_method("show_dialogue"):
				current_screen.show_dialogue()
		_:
			_ensure_exploration()


func _route() -> void:
	_on_mode_changed(Game.mode)


func _ensure_exploration() -> void:
	if current_screen is ExplorationScreen:
		current_screen.refresh_screen()
		if Game.mode == "dialogue":
			current_screen.show_dialogue()
		return
	var screen := ExplorationScreen.new()
	screen.main = self
	_set_screen(screen)


func _show_combat() -> void:
	if current_screen is CombatScreen:
		current_screen.refresh_screen()
		return
	var screen := CombatScreen.new()
	screen.main = self
	_set_screen(screen)


func _show_defeat() -> void:
	close_modal()
	var root := Control.new()
	var bg := ColorRect.new()
	bg.color = Color("#120d0d")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 420)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	box.add_child(ThemeBuilder.heading("DEFEAT", 36))
	for line in Array(Game.content.narration.get("defeat", [])):
		box.add_child(ThemeBuilder.body(String(line), false, 15))
	box.add_child(ThemeBuilder.body(
		"Combat is saved only on victory, so the last save is before this fight unless you saved manually.",
		true,
		13
	))
	var load := Button.new()
	load.text = "Load a save"
	load.custom_minimum_size = Vector2(0, 42)
	load.pressed.connect(_open_load_modal)
	box.add_child(load)
	var menu := Button.new()
	menu.text = "Main menu"
	menu.custom_minimum_size = Vector2(0, 42)
	menu.pressed.connect(func() -> void:
		Game.reset_to_menu()
		_show_menu()
	)
	box.add_child(menu)
	_set_screen(root)


func _on_state_changed() -> void:
	if current_screen != null and is_instance_valid(current_screen) and current_screen.has_method("refresh_screen"):
		current_screen.refresh_screen()
	if Game.mode == "explore" and Game.take_victory_pending():
		_show_victory()


func _on_combat_finished(result: String) -> void:
	# Demonstrations return to their own menu; they never fall through to the
	# campaign's exploration screen or victory flow.
	if Game.training_mode:
		Game.training_mode = false
		_show_menu()
		return
	# Mode changes already route to exploration/defeat; only the victory modal
	# needs an extra step here.
	if result == "victory":
		_route()
		if Game.take_victory_pending():
			_show_victory()


func _show_victory() -> void:
	open_modal(
		"Campaign objective complete",
		func() -> Control:
			var box := VBoxContainer.new()
			box.custom_minimum_size = Vector2(680, 340)
			box.add_theme_constant_override("separation", 12)
			for line in Array(Game.content.narration.get("victory", [])):
				box.add_child(ThemeBuilder.body(String(line), false, 15))
			box.add_child(ThemeBuilder.separator())
			box.add_child(ThemeBuilder.body(
				"Objective complete. Continue exploring, inspect your party, or save.",
				false,
				14
			))
			var close := Button.new()
			close.text = "Continue exploring"
			close.custom_minimum_size = Vector2(0, 42)
			close.pressed.connect(func() -> void: close_modal())
			box.add_child(close)
			return box,
		760,
		440
	)


# ---------------------------------------------------------------- modals

func open_modal(title: String, builder: Callable, width := 760, height := 540, preserve_rebind := false, notice := "") -> void:
	var pending_rebind := awaiting_rebind
	# The opener is the control focused before this modal stack began. A refresh,
	# or a modal that opens another, keeps it, so closing returns to the world
	# control the player actually used rather than to a freed modal button.
	var opener := modal_return_focus
	if modal == null:
		opener = get_viewport().gui_get_focus_owner()
	close_modal(false)
	if preserve_rebind:
		awaiting_rebind = pending_rebind
	modal_title = title
	modal_builder = builder
	modal_notice = notice
	modal_base_size = Vector2(width, height)
	modal = Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel := PanelContainer.new()
	var available := get_viewport_rect().size - Vector2(32, 32)
	# The panel follows the text scale: at 160 % the same content needs that much
	# more room, and a fixed 760x540 box left Settings showing a third of itself.
	# It is still capped to the client area, where the body scrolls instead.
	var text_scale := clampf(float(Game.settings.get("text_scale", 1.0)), 1.0, 1.6)
	var requested := modal_base_size * text_scale
	panel.custom_minimum_size = Vector2(minf(requested.x, available.x), minf(requested.y, available.y))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var heading := ThemeBuilder.heading(title, 24)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.x = 0
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := Button.new()
	close.text = "Close (Esc)"
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(close_modal)
	header.add_child(close)
	box.add_child(ThemeBuilder.separator())
	if modal_notice != "":
		# Outside the scroll on purpose: a notice about the panel's own limits is
		# useless if reading the controls can scroll it away.
		var banner := ThemeBuilder.body(modal_notice, true, 13)
		banner.name = "ModalNotice"
		banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(banner)
	var content_scroll := ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_scroll.follow_focus = true
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content_scroll)
	modal_scroll = content_scroll
	var content: Control = builder.call()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(content)
	close.grab_focus()
	modal_return_focus = opener


func refresh_modal() -> void:
	if modal_builder.is_valid():
		open_modal(
			modal_title,
			modal_builder,
			int(modal_base_size.x),
			int(modal_base_size.y),
			true,
			modal_notice
		)


func close_modal(restore_focus := true) -> void:
	if modal != null:
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner != null and modal.is_ancestor_of(focus_owner):
			focus_owner.release_focus()
		modal.queue_free()
		modal = null
	modal_scroll = null
	modal_builder = Callable()
	modal_title = ""
	modal_notice = ""
	awaiting_rebind = ""
	if restore_focus:
		_restore_modal_focus()


## Returns focus to the control that opened the modal, or to the first usable
## control on the screen when that control is gone (a screen rebuild, a probe,
## or a launch where nothing had focus yet).
func _restore_modal_focus() -> void:
	var target := modal_return_focus
	modal_return_focus = null
	if _can_take_focus(target):
		target.grab_focus()
		return
	var fallback := _first_focusable(current_screen)
	if fallback != null:
		fallback.grab_focus()


func _can_take_focus(control: Control) -> bool:
	return (
		control != null
		and is_instance_valid(control)
		and control.is_inside_tree()
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
		and not control is ScrollContainer
	)


func _first_focusable(root: Node) -> Control:
	if root == null:
		return null
	for child in root.get_children():
		if child is Control:
			var control := child as Control
			if _can_take_focus(control):
				return control
		var nested := _first_focusable(child)
		if nested != null:
			return nested
	return null


## The controls Tab may visit inside the active modal, in tree order. Scroll
## bodies are skipped: they have no focus style, so a stop there would make the
## ring vanish mid-cycle; `_reveal_modal_focus` scrolls the chosen control into
## view, through every pane that holds it.
func _modal_focusables() -> Array[Control]:
	var out: Array[Control] = []
	if modal == null:
		return out
	_collect_focusables(modal, out)
	return out


func _collect_focusables(node: Node, out: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if (
				control.focus_mode != Control.FOCUS_NONE
				and control.is_visible_in_tree()
				and not control is ScrollContainer
			):
				out.append(control)
		_collect_focusables(child, out)


## Tab and Shift+Tab stay inside the modal and wrap at either end; background
## controls can no longer receive focus while it is open.
func _cycle_modal_focus(direction: int) -> void:
	var focusables := _modal_focusables()
	if focusables.is_empty():
		return
	var owner := get_viewport().gui_get_focus_owner()
	var index := focusables.find(owner)
	var next := 0
	if index >= 0:
		next = wrapi(index + direction, 0, focusables.size())
	elif direction < 0:
		next = focusables.size() - 1
	focusables[next].grab_focus()


func _on_modal_focus_changed(_control: Control) -> void:
	_reveal_modal_focus()


## Scrolls every pane that holds the focused control - the inner list first, then
## each wrapper up to the shared body - so it sits inside the pane the player can
## see. The shared body's own `follow_focus` only ever moves the body, and panels
## wrap their content in a ScrollContainer of their own (Settings, the party
## sheet, inventory), so a row below the fold used to keep focus while staying
## invisible. Each wrapper is asked to show the pane inside it rather than the
## deep control: that is what the player sees, and it keeps every step independent
## of the others' scroll offsets.
##
## A control inside a popup raised from the modal is left alone: the popup has its
## own coordinates and its own scrolling, and the body behind it must not move.
func _reveal_modal_focus() -> void:
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null or modal == null or not modal.is_ancestor_of(owner):
		return
	var panes: Array[ScrollContainer] = []
	var node: Node = owner
	while node != null and node != modal:
		if node is Window:
			return
		if node is ScrollContainer:
			panes.append(node as ScrollContainer)
		node = node.get_parent()
	for index in panes.size():
		var target: Control = owner if index == 0 else panes[index - 1]
		_reveal_in_pane(panes[index], target)


## Moves one pane just far enough to show the control, aligning its top when the
## control is taller than the pane, and clamped to the pane's own travel.
func _reveal_in_pane(container: ScrollContainer, control: Control) -> void:
	if container == null or control == null or not container.is_visible_in_tree():
		return
	var content: Control = null
	for child in container.get_children():
		if child is Control and not child is ScrollBar:
			content = child as Control
			break
	if content == null:
		return
	# Positions inside the content do not change while the pane scrolls, so the
	# order the panes are adjusted in does not matter.
	var top := control.global_position.y - content.global_position.y
	var height := control.size.y
	var view_top := float(container.scroll_vertical)
	var view_height := container.size.y
	var pad := 8.0
	var delta := 0.0
	if height + pad * 2.0 >= view_height:
		delta = top - view_top
	elif top - pad < view_top:
		delta = top - pad - view_top
	elif top + height + pad > view_top + view_height:
		delta = top + height + pad - (view_top + view_height)
	if is_zero_approx(delta):
		return
	var moved := int(round(view_top + delta))
	container.scroll_vertical = clampi(moved, 0, _scroll_travel(container))


## Scrolls the open modal's body with the keyboard and reports whether the event
## was consumed. Focus is never touched, so the ring stays on the control it was
## on and focus containment is exactly as it was; a body that fits does not move;
## and a control that needs the key keeps it.
func _scroll_modal_body(event: InputEventKey) -> bool:
	if modal == null or modal_scroll == null or not _modal_owns_keyboard():
		return false
	var page := event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up")
	var direction := 0
	if event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_down"):
		direction = 1
	elif event.is_action_pressed("ui_page_up") or event.is_action_pressed("ui_up"):
		direction = -1
	if direction == 0:
		return false
	if _focused_control_needs_vertical_keys(page):
		return false
	var body := _modal_body_target()
	if body == null:
		return false
	var step := 0
	if page:
		step = int(round(MODAL_PAGE_STEP * float(_modal_body_page_height())))
	else:
		step = MODAL_LINE_STEP * _modal_body_line_height()
	step = maxi(step, 1)
	var target := clampi(body.scroll_vertical + direction * step, 0, _modal_body_scroll_range())
	body.scroll_vertical = target
	# Handled even when the body did not move: letting an arrow fall through would
	# move the focus ring with Godot's traversal, possibly onto the dimmed world.
	return true


## True while the modal has the keyboard to itself. A popup opened from inside a
## modal (an OptionButton list, a menu) takes focus into its own window, and the
## body behind it must not scroll while the player navigates the popup.
func _modal_owns_keyboard() -> bool:
	var owner := get_viewport().gui_get_focus_owner()
	return owner == null or (modal != null and modal.is_ancestor_of(owner))


## The focused control, or one of its ancestors inside the modal, that uses these
## keys for itself: a caret (Up/Down), a vertical value (VSlider), a list or tree
## selection, or a multi-line editor that pages its own text (PageUp/PageDown).
## While one holds focus the key is left alone rather than taken away from the
## player's editing.
##
## An HSlider and a TabBar are deliberately not on this list: they use Left/Right
## (measured: Right moves 0.50 -> 0.55 and switches a tab; Up/Down change neither),
## so leaving Up/Down with them only let Godot's focus traversal move the ring.
## They scroll the body instead. A SpinBox stays listed as a conservative default
## for a numeric field, although Godot 4.7 does not act on Up/Down for it either;
## no shipped modal contains one.
func _focused_control_needs_vertical_keys(page: bool) -> bool:
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null:
		return false
	var node: Node = owner
	while node != null and node != modal:
		var control := node as Control
		if control != null:
			if control is TextEdit:
				return true
			if not page and (
				control is LineEdit
				or (control is Range and not control is HSlider)
				or control is ItemList
				or control is Tree
			):
				return true
		node = node.get_parent()
	return false


## Pixels one arrow press moves: two rendered text lines at the current text
## scale. The theme's default font is sized by ThemeBuilder from the text
## setting, so 160 % text moves about 1.6x as far per press.
func _modal_body_line_height() -> int:
	var size := 16
	var font: Font = ThemeDB.fallback_font
	if theme != null:
		if theme.default_font_size > 0:
			size = theme.default_font_size
		if theme.default_font != null:
			font = theme.default_font
	return maxi(1, int(round(font.get_height(size))))


## The container the scroll keys should actually move: the visible pane with the
## most vertical travel, and the shared body on a tie.
##
## Panels routinely wrap their content in a ScrollContainer of their own (the
## Journal, Inventory, character sheet and Settings all do), so the shared body is
## often just a wrapper whose own minimum size makes it travel a few pixels while
## the list the player reads sits inside it. Choosing by travel picks the pane that
## holds the content; choosing the wrapper first left the rest of Settings
## unreachable. Ties keep the shared body, so a plain body still scrolls itself.
## Invisible panes are skipped: a page that was never laid out reports a page of 0
## and therefore a huge, meaningless travel (hidden tabs, for example).
func _modal_body_target() -> ScrollContainer:
	if modal_scroll == null:
		return null
	var best := modal_scroll
	var best_travel := _scroll_travel(modal_scroll)
	for node in modal_scroll.find_children("*", "ScrollContainer", true, false):
		var inner := node as ScrollContainer
		if inner == null or not inner.is_visible_in_tree():
			continue
		if inner.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
			continue
		var travel := _scroll_travel(inner)
		if travel > best_travel:
			best = inner
			best_travel = travel
	return best


## How far a container can travel. The container clamps too, but clamping here
## keeps the bounds one testable rule for both the modal body and a nested panel.
func _scroll_travel(scroll: ScrollContainer) -> int:
	if scroll == null:
		return 0
	var bar := scroll.get_v_scroll_bar()
	return maxi(0, int(bar.max_value - bar.page))


## The height of the part of the body currently on screen, which a page step is
## a fraction of. Zero before layout, which keeps PageUp/PageDown harmless.
func _modal_body_page_height() -> int:
	var body := _modal_body_target()
	if body == null:
		return 0
	return maxi(0, int(body.get_v_scroll_bar().page))


## How far the body can actually travel.
func _modal_body_scroll_range() -> int:
	return _scroll_travel(_modal_body_target())


func _open_load_modal() -> void:
	open_modal("Load Game", func() -> Control:
		return Panels.saves("load", func() -> void:
			if Game.mode != "defeat":
				close_modal()
				_route()
			else:
				close_modal()
				_route()
		)
	, 860, 520)


func _open_save_modal() -> void:
	open_modal("Save Game", func() -> Control:
		return Panels.saves("save", func() -> void: refresh_modal())
	, 860, 500)


func _open_settings() -> void:
	var notice := ""
	if Game.settings_newer:
		notice = "Read-only settings: this file was saved by a newer version of the game, so changes here apply for this session but are not written."
	open_modal("Settings", func() -> Control:
		return Panels.settings(awaiting_rebind, func(action: String) -> void:
			awaiting_rebind = action
			refresh_modal()
		, func() -> void:
			_apply_theme()
			if current_screen != null and current_screen.has_method("refresh_screen"):
				current_screen.refresh_screen()
			refresh_modal()
		, func() -> void:
			awaiting_rebind = ""
			Game.reset_default_controls()
			refresh_modal()
		)
	, 780, 560, false, notice)


func _open_pause() -> void:
	if Game.playtest_mode:
		open_modal("Playtest paused", func() -> Control:
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 10)
			box.add_child(ThemeBuilder.body(
				"Playtest saves are disabled, so this session cannot overwrite a campaign save. Returning to the creator keeps the draft.",
				true,
				14
			))
			var resume := Button.new()
			resume.text = "Resume playtest"
			resume.custom_minimum_size = Vector2(0, 42)
			resume.pressed.connect(close_modal)
			box.add_child(resume)
			var back := Button.new()
			back.text = "Return to campaign creator"
			back.custom_minimum_size = Vector2(0, 42)
			back.pressed.connect(_return_to_creator)
			box.add_child(back)
			return box
		, 620, 300)
		return
	if Game.mode == "dialogue":
		if Game.dialogue != null:
			Game.dialogue.finish_now()
		return
	open_modal("Paused", func() -> Control:
		return Panels.pause(
			func() -> void: close_modal(),
			func() -> void:
				if Game.mode == "combat":
					open_modal("Cannot save now", func() -> Control:
						var box := VBoxContainer.new()
						box.add_child(ThemeBuilder.body(
							"Saving is disabled during combat. Finish the fight (victory autosaves) or load an earlier save.",
							false,
							15
						))
						return box
					, 560, 200)
				else:
					_open_save_modal(),
			func() -> void: _open_load_modal(),
			func() -> void: _open_settings(),
			func() -> void:
				Game.reset_to_menu()
		)
	, 560, 440)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if awaiting_rebind != "":
			Game.rebind(awaiting_rebind, event.physical_keycode)
			awaiting_rebind = ""
			refresh_modal()
			get_viewport().set_input_as_handled()
			return
		if modal != null:
			# Keyboard access to a body taller than its panel. Handled before Tab
			# because Godot's GUI traversal also listens to the arrows, and an arrow
			# that fell through could move the focus ring off the modal.
			if _scroll_modal_body(event as InputEventKey):
				get_viewport().set_input_as_handled()
				return
			# Focus containment: Tab and Shift+Tab cycle the modal's own controls
			# and never reach the world behind it. Handled here, before the GUI,
			# because Godot's automatic traversal walks the whole tree.
			# Godot matches actions without comparing modifiers by default, so a
			# shifted Tab matches ui_focus_next too; the shift decides direction.
			if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
				var backward := (event as InputEventWithModifiers).shift_pressed
				_cycle_modal_focus(-1 if backward else 1)
				get_viewport().set_input_as_handled()
				return
			# If focus somehow sits outside the modal, activation is swallowed
			# rather than reaching a background button.
			if event.is_action_pressed("ui_accept"):
				var focus_owner := get_viewport().gui_get_focus_owner()
				if focus_owner == null or not modal.is_ancestor_of(focus_owner):
					get_viewport().set_input_as_handled()
					return
		# A conversation owns Tab while it is open: the ring moves through its
		# choices in content order (unavailable rows are skipped) and the panel
		# scrolls the new owner into view, instead of the ring wandering into the
		# HUD behind the dim layer.
		if Game.mode == "dialogue" and current_screen is ExplorationScreen:
			var talk_panel := (current_screen as ExplorationScreen).dialogue_panel
			if talk_panel != null and is_instance_valid(talk_panel):
				# Page keys move the body only: the focus ring, the Tab order and
				# activation stay where they were, and arrows keep their Godot
				# focus traversal.
				if event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
					talk_panel.scroll_page(-1 if event.is_action_pressed("ui_page_up") else 1)
					get_viewport().set_input_as_handled()
					return
				# Arrow keys stay on the available choices. Godot's geometric
				# traversal would otherwise land on unavailable rows or leave the
				# conversation for the HUD behind it.
				if (
					event.is_action_pressed("ui_up")
					or event.is_action_pressed("ui_down")
					or event.is_action_pressed("ui_left")
					or event.is_action_pressed("ui_right")
				):
					var focus_back := event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left")
					talk_panel.cycle_focus(-1 if focus_back else 1)
					get_viewport().set_input_as_handled()
					return
				if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
					var talk_backward := (event as InputEventWithModifiers).shift_pressed
					talk_panel.cycle_focus(-1 if talk_backward else 1)
					get_viewport().set_input_as_handled()
					return
		if event.is_action_pressed("pause_menu"):
			if modal != null:
				close_modal()
			else:
				_open_pause()
			get_viewport().set_input_as_handled()
