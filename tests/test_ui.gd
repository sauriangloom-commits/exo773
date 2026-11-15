extends GutTest

## Headless UI construction checks. These instantiate the real screens and
## panels so missing nodes, bad types or null state are caught automatically.
## Rendering itself is checked separately with screenshots (docs/TEST_REPORT.md).

func before_each() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 2024)


func test_exploration_screen_builds() -> void:
	var screen := ExplorationScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	assert_not_null(screen.view, "first-person view exists")
	assert_eq(screen.party_box.get_child_count(), 4, "party sidebar lists the party")
	assert_true(screen.log_label.text.length() > 0, "log shows the introduction")


func test_exploration_sidebar_keeps_all_party_cards_at_large_text() -> void:
	var previous := float(Game.settings.get("text_scale", 1.0))
	Game.settings["text_scale"] = 1.6
	var screen := ExplorationScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	assert_eq(screen.party_box.get_child_count(), 4, "all party cards remain present")
	assert_gt(screen.find_children("*", "ScrollContainer", true, false).size(), 0, "sidebar is scrollable")
	Game.settings["text_scale"] = previous


func test_character_and_inventory_panels_build() -> void:
	var sheet := Panels.character_sheet(0)
	add_child_autofree(sheet)
	await wait_frames(1)
	assert_gt(sheet.get_tab_count(), 0, "sheet has one tab per adventurer")
	var inventory := Panels.inventory(func() -> void: pass)
	add_child_autofree(inventory)
	await wait_frames(1)
	assert_gt(inventory.get_child_count(), 0)
	var journal := Panels.journal()
	add_child_autofree(journal)
	await wait_frames(1)
	assert_gt(journal.get_child_count(), 0)
	var settings := Panels.settings("", func(_action: String) -> void: pass, func() -> void: pass, func() -> void: pass)
	add_child_autofree(settings)
	await wait_frames(1)
	assert_gt(settings.get_child_count(), 0)
	var saves := Panels.saves("save", func() -> void: pass)
	add_child_autofree(saves)
	await wait_frames(1)
	assert_gt(saves.get_child_count(), 0)


func test_dialogue_panel_builds_with_visible_choices() -> void:
	Game.start_dialogue("miruna")
	var screen := ExplorationScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	screen.show_dialogue()
	await wait_frames(2)
	assert_eq(Game.mode, "dialogue")
	assert_not_null(screen.dialogue_panel)
	assert_gt(Game.dialogue_choices().size(), 0)


func test_combat_screen_builds_and_lists_targets() -> void:
	Game.start_encounter("storeroom_dead")
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	assert_eq(Game.mode, "combat")
	assert_not_null(screen.view)
	assert_gt(screen.target_box.get_child_count(), 0, "target list is populated")
	assert_gt(screen.log_label.text.length(), 0, "combat log is present")
	assert_not_null(screen.power_attack_box, "Power Attack control exists")
	assert_false(screen.power_attack_box.visible, "no Power Attack control without the feat")
	assert_not_null(screen.combat_expertise_box, "Combat Expertise control exists")
	assert_false(screen.combat_expertise_box.visible, "no Combat Expertise control without the feat")


func test_main_scene_and_party_select_build() -> void:
	Game.reset_to_menu()
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(3)
	assert_not_null(main.current_screen, "menu built")
	main._show_party_select()
	await wait_frames(2)
	assert_not_null(main.current_screen, "party select built")


func test_rebind_button_enters_capture_mode() -> void:
	Game.reset_to_menu()
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(3)
	main._open_settings()
	await wait_frames(2)
	var binding: Button = null
	for node in main.modal.find_children("*", "Button", true, false):
		if (node as Button).text == "W":
			binding = node
			break
	assert_not_null(binding, "Move forward shows its current binding")
	binding.emit_signal("pressed")
	await wait_frames(2)
	assert_eq(main.awaiting_rebind, "move_forward", "capture target survives modal refresh")
	var capture_text := false
	for node in main.modal.find_children("*", "Button", true, false):
		if (node as Button).text == "Press a key…":
			capture_text = true
	assert_true(capture_text, "settings shows capture mode")


func test_exploration_quick_actions_sit_above_the_scrolling_party_list() -> void:
	var screen := ExplorationScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	var save_button: Button = null
	for node in screen.find_children("*", "Button", true, false):
		if (node as Button).text == "Save game":
			save_button = node
	assert_not_null(save_button, "the exploration screen offers a Save action")
	# The sidebar scrolls at 1280x720 with raised text scale; the quick actions
	# must precede the party list so Save cannot be clipped below the fold.
	assert_true(
		save_button.get_parent().get_index() < screen.party_box.get_index(),
		"quick actions precede the party list inside the sidebar"
	)


func test_save_modal_opens_from_the_exploration_interface() -> void:
	Game.reset_to_menu()
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(3)
	main._open_save_modal()
	await wait_frames(2)
	assert_not_null(main.modal, "the save interface opens")
	assert_eq(String(main.modal_title), "Save Game")
	var labels: Array = []
	for node in main.modal.find_children("*", "Button", true, false):
		labels.append((node as Button).text)
	assert_true(labels.has("Save here"), "the save interface lists named slots: %s" % str(labels))


func test_power_attack_control_feeds_the_actual_attack() -> void:
	Game.new_game(["kaelen", "sera"], 31415)
	var kaelen: Character = Game.party[0]
	kaelen.feats.append("Power Attack")
	Game.start_encounter("storeroom_dead")
	var e := Game.encounter
	var active_entry: Dictionary = {}
	for entry in e.combatants:
		if entry["char"] == kaelen:
			active_entry = entry
	assert_false(active_entry.is_empty(), "Kaelen is in the encounter")
	e.turn_ptr = e.order.find(int(active_entry["index"]))
	e._begin_turn(active_entry)
	var enemy_entry: Dictionary = {}
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY and not entry["char"].has_condition("dead"):
			enemy_entry = entry
			break
	assert_false(enemy_entry.is_empty(), "a living enemy is available")
	e.combatants[int(active_entry["index"])]["cell"] = Vector2i(2, 2)
	e.combatants[int(enemy_entry["index"])]["cell"] = Vector2i(2, 3)
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	assert_true(screen.power_attack_box.visible, "the active feat holder can choose an amount")
	assert_eq(int(screen.power_attack_spin.max_value), kaelen.base_attack)
	screen.power_attack_spin.value = 2
	screen._attack(int(enemy_entry["index"]))
	await wait_frames(1)
	assert_true("\n".join(e.log_lines).contains("Power Attack -2"), "the UI passes the amount into resolution")
	assert_eq(e.active_power_attack_amount(), 2, "committed state remains after the attack")
	assert_false(screen.power_attack_spin.editable, "the committed amount is locked after the attack")


func test_switching_ui_actor_preserves_other_committed_power_attack() -> void:
	Game.new_game(["kaelen", "sera"], 2024)
	var kaelen: Character = Game.party[0]
	var sera: Character = Game.party[1]
	kaelen.feats.append("Power Attack")
	sera.abilities["str"] = 13
	sera.feats.append("Power Attack")
	Game.start_encounter("storeroom_dead")
	var e := Game.encounter
	var kaelen_entry: Dictionary = {}
	var sera_entry: Dictionary = {}
	for entry in e.combatants:
		if entry["char"] == kaelen:
			kaelen_entry = entry
		elif entry["char"] == sera:
			sera_entry = entry
	assert_false(kaelen_entry.is_empty(), "Kaelen is in the encounter")
	assert_false(sera_entry.is_empty(), "Sera is in the encounter")
	e.turn_ptr = e.order.find(int(kaelen_entry["index"]))
	e._begin_turn(kaelen_entry)
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	screen.power_attack_spin.value = 2
	assert_eq(e.power_attack_amount_for(int(kaelen_entry["index"])), 2)
	# Switching the visible actor is not a turn boundary for the previous actor.
	e.turn_ptr = e.order.find(int(sera_entry["index"]))
	e._begin_turn(sera_entry)
	screen.refresh_screen()
	await wait_frames(1)
	assert_eq(e.power_attack_amount_for(int(kaelen_entry["index"])), 2, "Kaelen's commitment survives the UI switch")
	assert_eq(e.active_power_attack_amount(), 0, "Sera has no committed choice of her own")
	assert_true(screen.power_attack_box.visible)
	assert_eq(int(screen.power_attack_spin.value), 0)


func test_attack_mode_control_offers_melee_and_thrown_for_dagger() -> void:
	Game.new_game(["kaelen"], 2718)
	var kaelen: Character = Game.party[0]
	kaelen.feats.append("Power Attack")
	kaelen.equip("weapon", Game.content.get_item("dagger"))
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	var active_entry: Dictionary = {}
	for entry in e.combatants:
		if entry["char"] == kaelen:
			active_entry = entry
	assert_false(active_entry.is_empty())
	e.turn_ptr = e.order.find(int(active_entry["index"]))
	e._begin_turn(active_entry)
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	assert_true(screen.attack_mode_box.visible, "a dagger exposes its attack modes")
	assert_eq(screen.attack_mode_option.item_count, 2)
	assert_eq(screen.attack_mode_option.get_item_text(0), "Melee")
	assert_eq(screen.attack_mode_option.get_item_text(1), "Thrown")
	screen._on_attack_mode_selected(1)
	assert_eq(screen.selected_attack_mode, "thrown")
	screen.power_attack_spin.value = 2
	var enemy_index := -1
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			enemy_index = int(entry["index"])
			break
	assert_gt(enemy_index, -1)
	screen._attack(enemy_index)
	await wait_frames(1)
	assert_true("\n".join(e.log_lines).contains("Dagger (thrown)"), "the selected mode reaches resolution")


func test_combat_expertise_control_stays_pending_until_the_melee_attack() -> void:
	Game.new_game(["kaelen", "sera"], 31415)
	var kaelen: Character = Game.party[0]
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	Game.start_encounter("storeroom_dead")
	var e := Game.encounter
	var active_entry: Dictionary = {}
	for entry in e.combatants:
		if entry["char"] == kaelen:
			active_entry = entry
	assert_false(active_entry.is_empty(), "Kaelen is in the encounter")
	e.turn_ptr = e.order.find(int(active_entry["index"]))
	e._begin_turn(active_entry)
	var enemy_entry: Dictionary = {}
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY and not entry["char"].has_condition("dead"):
			enemy_entry = entry
			break
	assert_false(enemy_entry.is_empty(), "a living enemy is available")
	e.combatants[int(active_entry["index"])]["cell"] = Vector2i(2, 2)
	e.combatants[int(enemy_entry["index"])]["cell"] = Vector2i(2, 3)
	var baseline_ac := Rules.armor_class(kaelen)
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	assert_true(screen.combat_expertise_box.visible, "the feat holder can choose an amount")
	assert_eq(int(screen.combat_expertise_spin.max_value), 3)
	assert_true(screen.combat_expertise_status.text.contains("Choose 0"), screen.combat_expertise_status.text)
	screen.combat_expertise_spin.value = 2
	assert_eq(e.active_combat_expertise_pending_amount(), 2)
	assert_eq(e.active_combat_expertise_amount(), 0)
	assert_eq(Rules.armor_class(kaelen), baseline_ac, "pending input grants no AC")
	assert_true(screen.combat_expertise_status.text.contains("Pending"), screen.combat_expertise_status.text)
	screen._attack(int(enemy_entry["index"]))
	await wait_frames(1)
	assert_true("\n".join(e.log_lines).contains("Combat Expertise -2"), "the UI commits the real attack")
	assert_eq(e.active_combat_expertise_amount(), 2)
	assert_eq(Rules.armor_class(kaelen), baseline_ac + 2)
	assert_true(screen.combat_expertise_status.text.contains("Active"), screen.combat_expertise_status.text)
	assert_false(screen.combat_expertise_spin.editable, "the committed amount is locked after the attack")


func test_switching_ui_actor_preserves_other_committed_combat_expertise() -> void:
	Game.new_game(["kaelen", "sera"], 2024)
	var kaelen: Character = Game.party[0]
	var sera: Character = Game.party[1]
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	sera.abilities["int"] = 13
	sera.feats.append("Combat Expertise")
	Game.start_encounter("storeroom_dead")
	var e := Game.encounter
	var kaelen_entry: Dictionary = {}
	var sera_entry: Dictionary = {}
	var enemy_entry: Dictionary = {}
	for entry in e.combatants:
		if entry["char"] == kaelen:
			kaelen_entry = entry
		elif entry["char"] == sera:
			sera_entry = entry
		elif int(entry["team"]) == Encounter.TEAM_ENEMY and not entry["char"].has_condition("dead"):
			enemy_entry = entry
	assert_false(kaelen_entry.is_empty(), "Kaelen is in the encounter")
	assert_false(sera_entry.is_empty(), "Sera is in the encounter")
	assert_false(enemy_entry.is_empty(), "a living enemy is available")
	e.combatants[int(kaelen_entry["index"])]["cell"] = Vector2i(2, 2)
	e.combatants[int(enemy_entry["index"])]["cell"] = Vector2i(2, 3)
	e.turn_ptr = e.order.find(int(kaelen_entry["index"]))
	e._begin_turn(kaelen_entry)
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	screen.combat_expertise_spin.value = 2
	var ac_before := Rules.armor_class(kaelen)
	screen._attack(int(enemy_entry["index"]))
	await wait_frames(1)
	assert_eq(e.combat_expertise_amount_for(int(kaelen_entry["index"])), 2)
	assert_eq(Rules.armor_class(kaelen), ac_before + 2, "committed AC remains on Kaelen")
	e.turn_ptr = e.order.find(int(sera_entry["index"]))
	e._begin_turn(sera_entry)
	screen.refresh_screen()
	await wait_frames(1)
	assert_eq(
		e.combat_expertise_amount_for(int(kaelen_entry["index"])),
		2,
		"Kaelen's committed effect survives the UI switch"
	)
	assert_eq(e.active_combat_expertise_amount(), 0, "Sera has no committed choice of her own")
	assert_true(screen.combat_expertise_box.visible)
	assert_eq(int(screen.combat_expertise_spin.value), 0)
	assert_true(screen.combat_expertise_status.text.contains("Choose 0"), screen.combat_expertise_status.text)
