extends GutTest

## Regressions for Phase 2 rules, content-gating and persistence fixes.
## Expected values come from the cited 3.5 source pages, not from prior output.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 606
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 606)


func after_each() -> void:
	SaveSystem.delete_save_everywhere("slot2")


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _map() -> BattleMap:
	return BattleMap.from_rows(
		[
			"#########",
			"#.......#",
			"#.......#",
			"#.......#",
			"#.......#",
			"#.......#",
			"#########",
		],
		"regression"
	)


func _encounter(party: Array, monsters: Array) -> Encounter:
	var e := Encounter.new()
	var party_cells: Array = []
	var monster_cells: Array = []
	for i in party.size():
		party_cells.append(Vector2i(1 + i, 5))
	for i in monsters.size():
		monster_cells.append(Vector2i(7 - i, 1))
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Regression")
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in initiative order")


func test_potion_in_melee_provokes_an_opportunity_attack() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(1, 2)
	_force_turn(e, kaelen)
	kaelen.hp = kaelen.max_hp
	var result := e.use_potion_active("potion_of_cure_light_wounds", 0)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true("\n".join(e.log_lines).contains("provokes attacks of opportunity"))
	assert_true(bool(e.aoo_used.get(1, false)), "the zombie's reaction is spent")


func test_potion_cannot_target_a_dead_ally_and_is_not_consumed() -> void:
	var kaelen := _char("kaelen")
	var aldric := _char("aldric")
	aldric.take_damage(99)
	var e := _encounter([kaelen, aldric], [_monster("zombie")])
	_force_turn(e, kaelen)
	var before := kaelen.inventory_count("potion_of_cure_light_wounds")
	var result := e.use_potion_active("potion_of_cure_light_wounds", 1)
	assert_false(bool(result["ok"]))
	assert_eq(kaelen.inventory_count("potion_of_cure_light_wounds"), before)


func test_dead_enemy_spell_target_is_rejected_without_spending_a_slot() -> void:
	var ysolde := _char("ysolde")
	var zombie := _monster("zombie")
	zombie.take_damage(99)
	var e := _encounter([ysolde], [zombie])
	_force_turn(e, ysolde)
	var result := e.cast_active_spell("magic_missile", 1)
	assert_false(bool(result["ok"]))
	assert_eq(ysolde.spell_slots_remaining(1), 3, "slot remains prepared")


func test_mage_armor_and_aid_use_caster_level_durations() -> void:
	var ysolde := _char("ysolde")
	ysolde.spells["caster_level"] = 4
	var e := _encounter([ysolde], [_monster("zombie")])
	e._cast_mage_armor(ysolde, ysolde, content.get_spell("mage_armor"))
	assert_eq(int(ysolde.get_effect("mage_armor")["rounds_left"]), 2400, "1 hour/level")

	var aldric := _char("aldric")
	aldric.spells["caster_level"] = 4
	e._cast_aid(aldric, aldric, content.get_spell("aid"))
	assert_eq(int(aldric.get_effect("aid")["rounds_left"]), 40, "1 min./level")
	assert_between(aldric.temp_hp, 5, 12, "1d8 + caster level, capped at +10")


func test_mage_armor_can_target_an_ally() -> void:
	var ysolde := _char("ysolde")
	var kaelen := _char("kaelen")
	var e := _encounter([ysolde, kaelen], [_monster("zombie")])
	_force_turn(e, ysolde)
	var kaelen_index := -1
	for entry in e.combatants:
		if entry["char"] == kaelen:
			kaelen_index = int(entry["index"])
	var result := e.cast_active_spell("mage_armor", kaelen_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(kaelen.has_condition("mage_armor"), "PHB p.225: target is a creature touched")
	assert_false(ysolde.has_condition("mage_armor"), "the caster was not the target")
	assert_eq(ysolde.spell_slots_remaining(1), 2, "one prepared slot was consumed")


func test_restore_default_controls_clears_custom_binding_and_persists() -> void:
	var original_settings := Game.settings.duplicate(true)
	var original_events := {}
	for entry in Panels.REBIND_ACTIONS:
		var action := String(entry[0])
		original_events[action] = InputMap.action_get_events(action).duplicate()
	var changed := Game.rebind("move_forward", KEY_UP)
	assert_true(bool(changed["ok"]), String(changed.get("message", "")))
	assert_eq(int(Game.settings["keybinds"]["move_forward"]), KEY_UP)
	var reset := Game.reset_default_controls()
	assert_true(bool(reset["ok"]), String(reset.get("message", "")))
	assert_true(Game.settings["keybinds"].is_empty(), "custom bindings are discarded")
	var restored := false
	for event in InputMap.action_get_events("move_forward"):
		if event is InputEventKey and event.physical_keycode == KEY_W:
			restored = true
	assert_true(restored, "move_forward is back on its shipped W binding")
	var config := ConfigFile.new()
	assert_eq(config.load(Game.SETTINGS_PATH), OK, "settings file was written")
	assert_eq(config.get_value("input", "keybinds", {}), {}, "persisted override map is empty")
	# This suite may run against a real profile; restore whatever was there.
	Game.settings = original_settings
	for action in original_events.keys():
		InputMap.action_erase_events(action)
		for event in original_events[action]:
			InputMap.action_add_event(action, event)
	Game.save_settings()


func test_moving_out_of_two_threats_provokes_from_both() -> void:
	var kaelen := _char("kaelen")
	var first_zombie := _monster("zombie")
	var second_zombie := _monster("zombie")
	var e := _encounter([kaelen], [first_zombie, second_zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(1, 2)
	e.combatants[2]["cell"] = Vector2i(3, 2)
	# Both reactors must have taken their first turn; a flat-footed creature
	# cannot make attacks of opportunity (PHB p.133).
	_force_turn(e, first_zombie)
	_force_turn(e, second_zombie)
	_force_turn(e, kaelen)
	kaelen.hp = kaelen.max_hp
	var result := e.move_active_to(Vector2i(2, 3))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(e.aoo_used.get(1, false)))
	assert_true(bool(e.aoo_used.get(2, false)))
	assert_true("\n".join(e.log_lines).count("attack of opportunity") >= 2)


func test_ghoul_moves_then_makes_only_one_attack() -> void:
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter([kaelen], [ghoul])
	e.combatants[0]["cell"] = Vector2i(7, 2)
	e.combatants[1]["cell"] = Vector2i(1, 2)
	e._run_monster_turn(e.combatants[1])
	var text := "\n".join(e.log_lines)
	assert_true(text.contains("moves"), text)
	assert_true(text.contains("attacks"), text)
	assert_false(text.contains("full attack"), "a ghoul cannot full attack after moving")


func test_bell_alone_does_not_resolve_the_warden_or_complete_the_quest() -> void:
	Game.party[0].add_to_inventory(content.get_item("bell_clapper"), 1)
	Game.flags["met_miruna"] = true
	Game.flags["found_clapper"] = true
	Game.position = Vector2i(7, 3)
	Game.facing = Dungeon.NORTH
	var result := Game.interact()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(Game.flags.get("bell_rung", false)))
	assert_false(bool(Game.flags.get("warden_resolved", false)))
	assert_false(Game.quests.is_complete("drowned_bell"))
	assert_false(Game.victory_pending)
	var again := Game.interact()
	assert_false(bool(again["ok"]), "the bell cannot be rung twice")


func test_save_write_is_atomic_and_malformed_load_does_not_mutate_state() -> void:
	Game.flags["atomic_probe"] = true
	Game.gold = 17
	var saved := Game.save_game("slot2")
	assert_true(bool(saved["ok"]), String(saved.get("message", "")))
	var path := SaveSystem.path_for("slot2", Game.campaign_id)
	assert_false(FileAccess.file_exists(path + ".tmp"), "no temporary residue")
	assert_false(FileAccess.file_exists(path + ".bak"), "no backup residue")
	var party_before := Game.party.size()
	var position_before := Game.position
	var flags_before := Game.flags.duplicate(true)
	var file := FileAccess.open(path, FileAccess.WRITE)
	# Valid JSON, invalid save shape: this exercises validation rather than the
	# JSON parser's own error reporting (which GUT treats as an engine error).
	file.store_string("{\"save_version\":1,\"party\":[]}")
	file.close()
	var loaded := Game.load_game("slot2")
	assert_false(bool(loaded["ok"]))
	assert_eq(Game.party.size(), party_before)
	assert_eq(Game.position, position_before)
	assert_eq(Game.flags, flags_before)


func test_healing_exactly_to_zero_leaves_disabled_not_stable() -> void:
	var kaelen := _char("kaelen")
	kaelen.take_damage(33)
	assert_eq(kaelen.hp, -5)
	kaelen.heal(5)
	assert_eq(kaelen.hp, 0)
	assert_true(kaelen.has_condition("disabled"))
	assert_false(kaelen.has_condition("dying"))
	assert_false(kaelen.has_condition("stable"))
	assert_false(kaelen.has_condition("unconscious"))


func test_aid_expiry_clears_its_temporary_hit_points() -> void:
	var kaelen := _char("kaelen")
	kaelen.add_effect("aid", "Aid", 1, "buff")
	kaelen.temp_hp = 7
	kaelen.tick_effects()
	assert_false(kaelen.has_effect("aid"))
	assert_eq(kaelen.temp_hp, 0)


func test_undead_are_immune_to_critical_hits() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var sword := content.get_item("masterwork_longsword")
	for i in 120:
		var result := Rules.attack(rng, kaelen, zombie, sword, 5)
		assert_false(bool(result.get("critical", false)), "undead cannot be critically hit")
