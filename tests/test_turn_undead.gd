extends GutTest

## Turn undead (PHB pp.159-160; MM ghoul p.119, "Turn Resistance" glossary p.317).
## Every expected number comes from the cited table, formula or stat block. Dice
## are supplied explicitly through Encounter.deterministic_rolls where a precise
## outcome matters; no production rule or modifier is changed for the tests.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 90210


func after_each() -> void:
	SaveSystem.delete_save("slot2")
	SaveSystem.delete_save("qa_turn")


func _cleric(id := "aldric") -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _map(width := 9, height := 7) -> BattleMap:
	var rows: Array = []
	for y in height:
		var row := ""
		for x in width:
			var edge := y == 0 or y == height - 1 or x == 0 or x == width - 1
			row += "#" if edge else "."
		rows.append(row)
	return BattleMap.from_rows(rows, "turn undead")


func _encounter(
	party: Array, monsters: Array, party_cells: Array = [], monster_cells: Array = [], battle_map = null
) -> Encounter:
	var e := Encounter.new()
	var cells_party := party_cells.duplicate()
	var cells_monsters := monster_cells.duplicate()
	if cells_party.is_empty():
		for i in party.size():
			cells_party.append(Vector2i(1 + i, 5))
	if cells_monsters.is_empty():
		for i in monsters.size():
			cells_monsters.append(Vector2i(6, 1 + i))
	e.setup(
		party,
		monsters,
		battle_map if battle_map != null else _map(),
		rng,
		cells_party,
		cells_monsters,
		content.spells,
		"Turn undead"
	)
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in initiative order")


func _entry_for(e: Encounter, ch: Character) -> Dictionary:
	for entry in e.combatants:
		if entry["char"] == ch:
			return entry
	return {}


func _turned_effects(ch: Character) -> Array:
	return ch.effects.filter(func(x): return String(x.get("id", "")) == "turned")


# ---------------------------------------------------------------- eligibility

func test_cleric_gets_three_plus_charisma_modifier_uses() -> void:
	var aldric := _cleric()
	assert_eq(aldric.cleric_level(), 3)
	assert_eq(aldric.ability_mod("cha"), 1)
	assert_eq(aldric.turn_undead_max_uses(), 4)
	assert_eq(aldric.turn_undead_remaining(), 4)
	assert_true(aldric.consume_turn_undead())
	assert_eq(aldric.turn_undead_remaining(), 3)
	aldric.consume_turn_undead()
	aldric.consume_turn_undead()
	aldric.consume_turn_undead()
	assert_eq(aldric.turn_undead_remaining(), 0)
	assert_false(aldric.consume_turn_undead())


func test_non_cleric_has_no_turning_ability() -> void:
	var fighter := _cleric("kaelen")
	assert_eq(fighter.cleric_level(), 0)
	assert_eq(fighter.turn_undead_max_uses(), 0)
	var ghoul := _monster("ghoul")
	var e := _encounter([fighter], [ghoul])
	_force_turn(e, fighter)
	var status := e.can_active_turn_undead()
	assert_false(bool(status["ok"]))
	assert_string_contains(String(status["reason"]), "no turning ability")
	assert_false(bool(e.turn_undead()["ok"]))


func test_shipped_undead_declare_source_hit_dice_and_turn_resistance() -> void:
	# MM p.119 ghoul: 2d12 and +2 turn resistance. MM zombie template: no turn
	# resistance. ECR infected Strahd zombie: HD 6, no turn resistance.
	var ghoul := _monster("ghoul")
	assert_eq(ghoul.hit_dice, 2)
	assert_eq(ghoul.turn_resistance, 2, "the standard ghoul has +2 turn resistance")
	assert_eq(ghoul.turn_effective_hd(), 4)
	var zombie := _monster("zombie")
	assert_eq(zombie.hit_dice, 2)
	assert_eq(zombie.turn_resistance, 0)
	var infected := _monster("infected_zombie")
	assert_eq(infected.hit_dice, 6)
	assert_eq(infected.turn_resistance, 0)
	for ch in [ghoul, zombie, infected]:
		assert_true(ch.is_undead())
		assert_ne(ch.hit_dice, ch.max_hp, "Hit Dice must never be inferred from HP")


# ---------------------------------------------------------------- check table

func test_turning_check_table_gives_maximum_hit_dice() -> void:
	# Table 8-9, PHB p.159, read against a 5th-level cleric.
	assert_eq(Rules.turn_max_hd(5, 0), 1)
	assert_eq(Rules.turn_max_hd(5, 1), 2)
	assert_eq(Rules.turn_max_hd(5, 3), 2)
	assert_eq(Rules.turn_max_hd(5, 4), 3)
	assert_eq(Rules.turn_max_hd(5, 6), 3)
	assert_eq(Rules.turn_max_hd(5, 7), 4)
	assert_eq(Rules.turn_max_hd(5, 9), 4)
	assert_eq(Rules.turn_max_hd(5, 10), 5)
	assert_eq(Rules.turn_max_hd(5, 12), 5)
	assert_eq(Rules.turn_max_hd(5, 13), 6)
	assert_eq(Rules.turn_max_hd(5, 16), 7)
	assert_eq(Rules.turn_max_hd(5, 19), 8)
	assert_eq(Rules.turn_max_hd(5, 22), 9)


func test_five_ranks_of_knowledge_religion_add_two_to_the_check() -> void:
	var aldric := _cleric()
	assert_eq(aldric.turn_check_bonus(), 0)
	aldric.skill_ranks["knowledge_religion"] = 5
	assert_eq(aldric.turn_check_bonus(), 2)
	var zombie := _monster("zombie")
	var e := _encounter([aldric], [zombie])
	_force_turn(e, aldric)
	# d20(8) + Cha 1 + 2 = 11 -> 3 HD maximum, so the 2-HD zombie is eligible.
	e.deterministic_rolls = [8, 1, 1]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(zombie.has_condition("turned"))
	assert_string_contains(e.get_log_text(), "d20(8)+3 = 11")


func test_turning_damage_is_two_d6_plus_level_plus_charisma() -> void:
	assert_eq(Rules.turn_damage(3, 1, 1, 1), 6)
	assert_eq(Rules.turn_damage(3, 1, 6, 6), 16)
	assert_eq(Rules.turn_damage(5, -1, 4, 2), 10)


# ------------------------------------------------- effective Hit Dice (turning)

func test_ghoul_turn_resistance_raises_the_maximum_hit_dice_needed() -> void:
	# A ghoul is 2 HD but turning treats it as 4 HD. A check that caps at 3 HD
	# must leave it unaffected; ignoring turn resistance would turn it here.
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	e.deterministic_rolls = [10]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_false(ghoul.has_condition("turned"), "4 effective HD exceeds a 3 HD maximum")
	assert_string_contains(e.get_log_text(), "can affect undead of up to 3 HD")
	assert_eq(aldric.turn_undead_remaining(), 3, "the attempt is still spent")

	# The same check does affect a ghoul whose turn resistance is removed.
	var plain := _monster("ghoul")
	plain.turn_resistance = 0
	var aldric2 := _cleric()
	var e2 := _encounter([aldric2], [plain])
	_force_turn(e2, aldric2)
	e2.deterministic_rolls = [10, 1, 1]
	assert_true(bool(e2.turn_undead()["ok"]))
	assert_true(plain.has_condition("turned"), "2 HD fits the 3 HD maximum")


func test_turn_resistance_is_counted_in_total_turning_capacity() -> void:
	# Zombie A has +3 turn resistance (5 effective HD), zombie B has 2. With 6
	# points of turning damage only A is turned; if resistance were ignored both
	# would fit (2 + 2 <= 6).
	var aldric := _cleric()
	var resistant := _monster("zombie")
	resistant.display_name = "Resistant Dead"
	resistant.turn_resistance = 3
	var plain := _monster("zombie")
	plain.display_name = "Plain Dead"
	var e := _encounter(
		[aldric], [resistant, plain], [Vector2i(1, 5)], [Vector2i(3, 5), Vector2i(5, 5)]
	)
	_force_turn(e, aldric)
	# Check 15 + 1 = 16 -> 5 HD maximum; damage 1 + 1 + 4 = 6.
	e.deterministic_rolls = [15, 1, 1]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(resistant.has_condition("turned"))
	assert_false(plain.has_condition("turned"), "only 1 HD of capacity remains")


func test_turn_resistance_is_counted_for_destruction() -> void:
	# A 1-HD creature would be destroyed by a 3rd-level cleric (3 >= 2 * 1), but
	# with +2 turn resistance it is 3 effective HD and can only be turned.
	var aldric := _cleric()
	var frail := _monster("zombie")
	frail.display_name = "Frail Dead"
	frail.hit_dice = 1
	frail.turn_resistance = 0
	var warded := _monster("zombie")
	warded.display_name = "Warded Dead"
	warded.hit_dice = 1
	warded.turn_resistance = 2
	var e := _encounter([aldric], [frail], [Vector2i(1, 5)], [Vector2i(3, 5)])
	_force_turn(e, aldric)
	e.deterministic_rolls = [13, 3, 3]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(frail.has_condition("dead"), "1 effective HD is destroyed")

	var aldric2 := _cleric()
	var e2 := _encounter([aldric2], [warded], [Vector2i(1, 5)], [Vector2i(3, 5)])
	_force_turn(e2, aldric2)
	e2.deterministic_rolls = [13, 3, 3]
	assert_true(bool(e2.turn_undead()["ok"]))
	assert_false(warded.has_condition("dead"), "3 effective HD is not destroyed")
	assert_true(warded.has_condition("turned"))


# ---------------------------------------------------------------- resolution

func test_successful_turn_spends_the_standard_action_and_one_use() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	# Check 13 + 1 = 14 -> 4 HD maximum (the ghoul's 4 effective HD fit).
	e.deterministic_rolls = [13, 4, 5]
	var result := e.turn_undead()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(e.turn_state["standard_used"]))
	assert_eq(aldric.turn_undead_remaining(), 3)
	assert_true(ghoul.has_condition("turned"))
	assert_eq(int(ghoul.get_effect("turned").get("rounds_left", 0)), 10)
	assert_eq(String(ghoul.get_effect("turned").get("turner_id", "")), "aldric")
	assert_false(e.finished, "turning alone must not end the encounter")


func test_turning_check_below_target_hit_dice_leaves_it_unaffected() -> void:
	var aldric := _cleric()
	var infected := _monster("infected_zombie")
	var e := _encounter([aldric], [infected])
	_force_turn(e, aldric)
	# Check 10 + 1 = 11 -> 3 HD maximum; the infected zombie has 6 HD.
	e.deterministic_rolls = [10]
	var result := e.turn_undead()
	assert_true(bool(result["ok"]))
	assert_false(infected.has_condition("turned"))
	assert_string_contains(String(result["message"]), "affects no undead")
	assert_eq(aldric.turn_undead_remaining(), 3, "an attempt is still spent")


func test_two_hit_dice_are_turned_but_not_destroyed() -> void:
	var aldric := _cleric()
	var zombie := _monster("zombie")
	var e := _encounter([aldric], [zombie])
	_force_turn(e, aldric)
	# 3 < 2 * 2, so the zombie is turned rather than destroyed.
	e.deterministic_rolls = [12, 3, 3]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(zombie.has_condition("turned"))
	assert_false(zombie.has_condition("dead"))


# ---------------------------------------------------------------- range/order

func test_undead_beyond_60_feet_are_not_targets_and_a_use_is_not_spent() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter(
		[aldric], [ghoul], [Vector2i(1, 7)], [Vector2i(14, 7)], _map(15, 15)
	)
	_force_turn(e, aldric)
	assert_eq(e.map.distance_ft(Vector2i(1, 7), Vector2i(14, 7)), 65)
	assert_true(e.turn_candidates(aldric).is_empty())
	var result := e.turn_undead()
	assert_false(bool(result["ok"]))
	assert_string_contains(String(result.get("message", "")), "60 ft")
	assert_eq(aldric.turn_undead_remaining(), 4)


func test_closest_undead_are_affected_first_and_capacity_is_spent() -> void:
	var aldric := _cleric()
	var ghouls := [_monster("ghoul"), _monster("ghoul"), _monster("ghoul"), _monster("ghoul")]
	for i in ghouls.size():
		ghouls[i].display_name = "Ghoul %d" % (i + 1)
	var e := _encounter(
		[aldric],
		ghouls,
		[Vector2i(1, 5)],
		[Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5)],
		_map(12, 7)
	)
	_force_turn(e, aldric)
	# Check 14 -> 4 HD maximum; damage 3 + 3 + 4 = 10 -> two 4-effective-HD ghouls.
	e.deterministic_rolls = [13, 3, 3]
	var result := e.turn_undead()
	assert_true(bool(result["ok"]))
	assert_true(ghouls[0].has_condition("turned"), "closest ghoul is turned first")
	assert_true(ghouls[1].has_condition("turned"))
	assert_false(ghouls[2].has_condition("turned"), "capacity is exhausted")
	assert_false(ghouls[3].has_condition("turned"))


func test_already_turned_undead_are_skipped_without_spending_capacity() -> void:
	var aldric := _cleric()
	var first := _monster("ghoul")
	var second := _monster("ghoul")
	first.display_name = "Ghoul A"
	second.display_name = "Ghoul B"
	first.add_effect("turned", "Turned", 10, "condition")
	var e := _encounter(
		[aldric], [first, second], [Vector2i(1, 5)], [Vector2i(3, 5), Vector2i(4, 5)]
	)
	_force_turn(e, aldric)
	e.deterministic_rolls = [13, 1, 1]
	var result := e.turn_undead()
	assert_true(bool(result["ok"]))
	assert_true(second.has_condition("turned"), "capacity is not wasted on the turned ghoul")
	assert_string_contains(e.get_log_text(), "Skipped (already turned): Ghoul A")
	assert_eq(_turned_effects(first).size(), 1, "the turned condition does not stack")


# ---------------------------------------------------------------- turned behavior

func test_turned_creature_flees_and_does_not_attack() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul], [Vector2i(1, 5)], [Vector2i(5, 5)])
	ghoul.add_effect("turned", "Turned", 10, "condition")
	var before := aldric.hp
	var ghoul_entry := _entry_for(e, ghoul)
	e._run_monster_turn(ghoul_entry)
	assert_gt(int(ghoul_entry["cell"].x), 5, "the turned ghoul moves away")
	assert_eq(aldric.hp, before, "a fleeing creature makes no attack")
	assert_true(ghoul.has_condition("turned"))


func test_flee_route_goes_around_an_obstacle() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter(
		[aldric],
		[ghoul],
		[Vector2i(1, 3)],
		[Vector2i(4, 3)],
		BattleMap.from_rows(
			[
				"#########",
				"#....#..#",
				"#....#..#",
				"#.......#",
				"#.......#",
				"#.......#",
				"#########",
			],
			"obstacle"
		)
	)
	ghoul.add_effect("turned", "Turned", 10, "condition")
	e._run_monster_turn(_entry_for(e, ghoul))
	var landing := e.cell_of(ghoul)
	assert_true(landing.x >= 6, "the ghoul reaches the open ground beyond the wall")
	assert_false(e.map.is_blocked(landing), "it never ends inside a wall")
	assert_gt(e.map.distance_ft(landing, Vector2i(1, 3)), 15)


func test_fleeing_uses_at_most_one_move_action() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter(
		[aldric], [ghoul], [Vector2i(1, 3)], [Vector2i(3, 3)], _map(15, 7)
	)
	ghoul.add_effect("turned", "Turned", 10, "condition")
	e._run_monster_turn(_entry_for(e, ghoul))
	var landing := e.cell_of(ghoul)
	assert_gt(landing.x, 3)
	assert_true(landing.x - 3 <= 6, "30 ft of movement is 6 squares")


func test_cornered_turned_creature_cowers_and_is_easier_to_hit() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul], [Vector2i(1, 1)], [Vector2i(7, 1)], _map(9, 3))
	ghoul.add_effect("turned", "Turned", 10, "condition")
	e._run_monster_turn(_entry_for(e, ghoul))
	assert_true(ghoul.has_condition("cowering"), "a creature that cannot flee cowers")
	var weapon := {"name": "longsword", "damage": "1d8", "melee": true}
	var with_cowering := Rules.attack(_seeded_rng(), aldric, ghoul, weapon, 5)
	ghoul.remove_effect("cowering")
	var without := Rules.attack(_seeded_rng(), aldric, ghoul, weapon, 5)
	assert_eq(int(with_cowering["bonus"]) - int(without["bonus"]), 2, "+2 to attacks against a cowering target")


func _seeded_rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	return r


func test_cowering_expires_and_normal_behavior_resumes() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul], [Vector2i(1, 1)], [Vector2i(7, 1)], _map(9, 3))
	ghoul.add_effect("turned", "Turned", 10, "condition")
	e._run_monster_turn(_entry_for(e, ghoul))
	assert_true(ghoul.has_condition("cowering"))
	ghoul.tick_effects()
	assert_false(ghoul.has_condition("cowering"), "cowering lasts one round")
	ghoul.remove_effect("turned")
	var before := e.map.distance_ft(e.cell_of(ghoul), Vector2i(1, 1))
	e._run_monster_turn(_entry_for(e, ghoul))
	assert_lt(e.map.distance_ft(e.cell_of(ghoul), Vector2i(1, 1)), before, "it advances again")


func test_turned_effect_expires_after_ten_rounds() -> void:
	var ghoul := _monster("ghoul")
	ghoul.add_effect("turned", "Turned", 10, "condition")
	for i in 9:
		ghoul.tick_effects()
	assert_true(ghoul.has_condition("turned"))
	ghoul.tick_effects()
	assert_false(ghoul.has_condition("turned"))


func test_cleric_approaching_within_10_feet_ends_the_turning() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul], [Vector2i(1, 5)], [Vector2i(4, 5)])
	_force_turn(e, aldric)
	e.deterministic_rolls = [13, 3, 3]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(ghoul.has_condition("turned"))
	var moved := e.move_active_to(Vector2i(2, 5))
	assert_true(bool(moved["ok"]), String(moved.get("message", "")))
	assert_false(ghoul.has_condition("turned"), "the cleric crossed from 15 ft to 10 ft")
	assert_string_contains(e.get_log_text(), "overcomes the turning as Brother Aldric comes within 10 ft")


func test_standing_within_10_feet_when_turned_does_not_break_it() -> void:
	# "You can stand within 10 feet without breaking the turning effect."
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul], [Vector2i(1, 5)], [Vector2i(2, 5)])
	_force_turn(e, aldric)
	e.deterministic_rolls = [13, 3, 3]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(ghoul.has_condition("turned"))
	e._run_monster_turn(_entry_for(e, ghoul))
	assert_true(ghoul.has_condition("turned"), "standing close does not break it")


func test_turned_creature_moving_close_does_not_break_it() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul], [Vector2i(1, 5)], [Vector2i(4, 5)])
	_force_turn(e, aldric)
	e.deterministic_rolls = [13, 3, 3]
	assert_true(bool(e.turn_undead()["ok"]))
	_entry_for(e, ghoul)["cell"] = Vector2i(2, 5)
	assert_true(ghoul.has_condition("turned"), "only the cleric's approach breaks it")


func test_another_party_member_approaching_does_not_break_it() -> void:
	var kaelen := _cleric("kaelen")
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter(
		[kaelen, aldric], [ghoul], [Vector2i(1, 5), Vector2i(2, 5)], [Vector2i(5, 5)]
	)
	_force_turn(e, aldric)
	e.deterministic_rolls = [13, 3, 3]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(ghoul.has_condition("turned"))
	_force_turn(e, kaelen)
	var moved := e.move_active_to(Vector2i(4, 4))
	assert_true(bool(moved["ok"]), String(moved.get("message", "")))
	assert_eq(e.map.distance_ft(e.cell_of(ghoul), e.cell_of(kaelen)), 5)
	assert_true(ghoul.has_condition("turned"), "a different party member does not matter")


# ---------------------------------------------------------------- resources

func test_extra_turning_adds_four_uses_per_taking_and_rejects_non_turners() -> void:
	var aldric := _cleric()
	assert_eq(aldric.turn_undead_max_uses(), 4)
	aldric.feats.append("Extra Turning")
	assert_true(Feats.has_active(aldric, "extra_turning"))
	assert_eq(aldric.turn_undead_max_uses(), 8)
	aldric.feats.append("Extra Turning")
	assert_eq(aldric.turn_undead_max_uses(), 12, "Extra Turning stacks with itself")
	var fighter := _cleric("kaelen")
	fighter.feats.append("Extra Turning")
	assert_eq(fighter.turn_undead_max_uses(), 0)
	assert_false(Feats.has_active(fighter, "extra_turning"))
	assert_gt(Feats.validate_for_character(fighter).size(), 0)


func test_improved_turning_raises_effective_level_and_turn_cap() -> void:
	var plain := _cleric()
	var plain_ghoul := _monster("ghoul")
	var plain_encounter := _encounter([plain], [plain_ghoul])
	_force_turn(plain_encounter, plain)
	plain_encounter.deterministic_rolls = [10, 1, 1]
	assert_true(bool(plain_encounter.turn_undead()["ok"]))
	assert_false(plain_ghoul.has_condition("turned"), "level 3 caps at 3 HD; the ghoul is 4 HD")
	assert_string_contains(plain_encounter.get_log_text(), "up to 3 HD")
	var aldric := _cleric()
	aldric.feats.append("Improved Turning")
	assert_eq(Feats.turn_level_bonus(aldric), 1)
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	e.deterministic_rolls = [10, 1, 1]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(ghoul.has_condition("turned"), "effective level 4 can affect the 4-HD ghoul")
	assert_string_contains(e.get_log_text(), "effective cleric level 4")
	assert_string_contains(e.get_log_text(), "up to 4 HD")
	assert_string_contains(e.get_log_text(), "2d6(1, 1)+5 = 7")
	var destroyer := _cleric()
	destroyer.feats.append("Improved Turning")
	var zombie := _monster("zombie")
	var destroy_encounter := _encounter([destroyer], [zombie])
	_force_turn(destroy_encounter, destroyer)
	destroy_encounter.deterministic_rolls = [13, 1, 1]
	assert_true(bool(destroy_encounter.turn_undead()["ok"]))
	assert_true(zombie.dead, "effective level 4 meets the 2-HD destruction threshold")
	assert_string_contains(destroy_encounter.get_log_text(), "destroyed")


func test_turning_feats_survive_save_round_trip() -> void:
	var aldric := _cleric()
	aldric.feats.append("Extra Turning")
	aldric.feats.append("Improved Turning")
	var restored := Character.from_dict(aldric.to_dict(), content.items)
	assert_eq(restored.turn_undead_max_uses(), 8)
	assert_eq(Feats.turn_level_bonus(restored), 1)


func test_exhausted_cleric_is_rejected_with_a_reason() -> void:
	var aldric := _cleric()
	aldric.turn_undead_used = aldric.turn_undead_max_uses()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	var status := e.can_active_turn_undead()
	assert_false(bool(status["ok"]))
	assert_string_contains(String(status["reason"]), "No turning attempts remain")


func test_daily_uses_survive_manual_save_load_and_rest() -> void:
	Game.new_game(["kaelen", "aldric"], 707)
	var aldric: Character = null
	for ch in Game.party:
		if ch.id == "aldric":
			aldric = ch
	assert_not_null(aldric)
	aldric.consume_turn_undead()
	aldric.consume_turn_undead()
	assert_eq(aldric.turn_undead_used, 2)
	var saved := Game.save_game("slot2")
	assert_true(bool(saved["ok"]), String(saved.get("message", "")))
	aldric.turn_undead_used = 0
	var loaded := Game.load_game("slot2")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	var reloaded: Character = null
	for ch in Game.party:
		if ch.id == "aldric":
			reloaded = ch
	assert_eq(reloaded.turn_undead_used, 2, "attempts spent persist across save/load")
	assert_eq(reloaded.turn_undead_remaining(), 2)
	Game.rest_party(false)
	assert_eq(reloaded.turn_undead_remaining(), reloaded.turn_undead_max_uses(), "rest restores the full allowance")


func test_pre_milestone_save_without_turning_fields_gets_a_full_allowance() -> void:
	var payload := _cleric().to_dict()
	payload.erase("hit_dice")
	payload.erase("turn_resistance")
	payload.erase("turn_undead_used")
	var legacy := Character.from_dict(payload, content.items)
	assert_eq(legacy.hit_dice, 0)
	assert_eq(legacy.turn_resistance, 0)
	assert_eq(legacy.turn_undead_used, 0, "the field counts attempts spent")
	assert_eq(legacy.turn_undead_max_uses(), 4, "uses are derived, so old saves still work")
	assert_eq(legacy.turn_undead_remaining(), 4, "no attempts spent means a full allowance")


func test_legacy_payload_with_spent_attempts_stays_spent() -> void:
	var payload := _cleric().to_dict()
	payload["turn_undead_used"] = 4
	var legacy := Character.from_dict(payload, content.items)
	assert_eq(legacy.turn_undead_remaining(), 0)
	legacy.rest()
	assert_eq(legacy.turn_undead_remaining(), 4)


# ------------------------------------------------------- encounter consequences

func test_turning_alone_does_not_finish_the_encounter_or_award_xp() -> void:
	Game.new_game(["kaelen", "aldric"], 808)
	Game.start_encounter("qa_turn_undead")
	var e := Game.encounter
	var aldric: Character = null
	for ch in Game.party:
		if ch.id == "aldric":
			aldric = ch
	for entry in e.combatants:
		if entry["char"] == aldric:
			e.turn_ptr = e.order.find(int(entry["index"]))
			e._begin_turn(entry)
	e.deterministic_rolls = [13, 6, 6]
	var xp_before: int = int(Game.party[0].xp)
	assert_true(bool(e.turn_undead()["ok"]))
	assert_false(e.finished, "living turned enemies keep the encounter open")
	assert_eq(Game.party[0].xp, xp_before, "turning grants no XP")


func test_turned_encounter_does_not_softlock_over_several_rounds() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var zombie := _monster("zombie")
	var e := _encounter(
		[aldric], [ghoul, zombie], [Vector2i(1, 5)], [Vector2i(5, 3), Vector2i(6, 3)]
	)
	_force_turn(e, aldric)
	e.deterministic_rolls = [13, 6, 6]
	assert_true(bool(e.turn_undead()["ok"]))
	assert_true(ghoul.has_condition("turned"))
	assert_true(zombie.has_condition("turned"))
	for i in 8:
		if e.finished:
			break
		e.end_turn()
		if e.finished:
			break
		e.auto_advance()
	assert_false(e.finished, "the encounter remains playable while enemies are turned")
	assert_ne(e.outcome, "error")
	assert_true(e.round_number >= 8)
	assert_true(ghoul.has_condition("turned"), "the 10-round duration has not run out")


func test_turned_enemies_can_be_destroyed_and_award_xp_once() -> void:
	Game.new_game(["kaelen", "aldric"], 909)
	Game.start_encounter("qa_turn_undead")
	var e := Game.encounter
	e.xp_award = 250
	var xp_before: int = int(Game.party[0].xp)
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			e._destroy_undead(entry["char"])
	e._check_end()
	assert_eq(e.outcome, "victory")
	assert_eq(Game.party[0].xp, xp_before + 250)
	e.changed.emit()
	assert_eq(Game.party[0].xp, xp_before + 250, "the reward must not be granted twice")


func test_defeat_routing_and_restart_still_work() -> void:
	Game.new_game(["kaelen", "aldric"], 910)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	for ch in Game.party:
		ch.take_damage(ch.hp + 20)
	e._check_end()
	assert_eq(e.outcome, "defeat")
	assert_eq(Game.mode, "defeat")
	var restarted := Game.new_game(["kaelen", "aldric"], 911)
	assert_true(bool(restarted.get("ok", true)))
	assert_eq(Game.mode, "explore")
