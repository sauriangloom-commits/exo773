extends GutTest

## Combat engine: initiative, action economy, movement/AoO, attacks, DR,
## paralysis, spells and ending conditions.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 991


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _map(rows := []) -> BattleMap:
	var default_rows := [
		"#########",
		"#.......#",
		"#.......#",
		"#.......#",
		"#.......#",
		"#.......#",
		"#########",
	]
	return BattleMap.from_rows(rows if not rows.is_empty() else default_rows, "test")


func _encounter(party: Array, monsters: Array, party_cell := Vector2i(1, 5), monster_cell := Vector2i(7, 1), map: BattleMap = null) -> Encounter:
	var battle_map: BattleMap = map if map != null else _map()
	var e := Encounter.new()
	var party_cells: Array = []
	var monster_cells: Array = []
	for i in party.size():
		party_cells.append(Vector2i(party_cell.x + i, party_cell.y))
	for i in monsters.size():
		monster_cells.append(Vector2i(monster_cell.x - i, monster_cell.y))
	e.setup(party, monsters, battle_map, rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	_preload_ranged_weapons(e)
	return e


## These fixtures test range, line of sight and the ranged penalties, not the
## reload action; a character entering the fight with a loaded crossbow is the
## realistic baseline. Loading itself is covered by tests/test_weapon_access.gd.
func _preload_ranged_weapons(e: Encounter) -> void:
	for entry in e.combatants:
		var ch: Character = entry["char"]
		var weapon: Dictionary = ch.equipment.get("weapon", {})
		if String(weapon.get("reload", "")) != "":
			e.loaded_weapons[String(ch.id)] = String(weapon.get("id", ""))


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func test_initiative_order_is_descending() -> void:
	var party := [_char("kaelen"), _char("ysolde")]
	var e := _encounter(party, [_monster("zombie")])
	assert_eq(e.order.size(), 3, "all combatants roll initiative")
	for i in range(0, e.order.size() - 1):
		var a: Character = e.combatants[e.order[i]]["char"]
		var b: Character = e.combatants[e.order[i + 1]]["char"]
		var a_init := int(e.combatants[e.order[i]]["initiative"])
		var b_init := int(e.combatants[e.order[i + 1]]["initiative"])
		if a_init == b_init:
			assert_gte(
				Rules.ability_modifier(a, "dex"),
				Rules.ability_modifier(b, "dex"),
				"ties break on Dexterity"
			)
		else:
			assert_gt(a_init, b_init)


func test_double_move_spends_standard_action_and_blocks_third_move() -> void:
	var kaelen := _char("kaelen")
	var e := _encounter([kaelen], [_monster("zombie")])
	_force_turn(e, kaelen)
	var result := e.move_active_to(Vector2i(1, 3))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(e.turn_state["move_used"]))
	assert_false(bool(e.turn_state["standard_used"]))
	# PHB p.133/135: a character may spend a standard action on a second move.
	var second := e.move_active_to(Vector2i(1, 2))
	assert_true(bool(second["ok"]), String(second.get("message", "")))
	assert_true(bool(e.turn_state["standard_used"]), "double move spends the standard action")
	var third := e.move_active_to(Vector2i(1, 1))
	assert_false(bool(third["ok"]), "no third move action")
	assert_true(String(third["message"]).contains("move action"))


func test_movement_budget_is_enforced() -> void:
	var kaelen := _char("kaelen")
	kaelen.speed_ft = 20
	var e := _encounter([kaelen], [_monster("zombie")])
	_force_turn(e, kaelen)
	e.combatants[0]["cell"] = Vector2i(1, 1)
	var too_far := e.move_active_to(Vector2i(6, 5))
	assert_false(bool(too_far["ok"]))
	assert_true(String(too_far["message"]).contains("can move 20 ft."), String(too_far["message"]))


func test_melee_out_of_reach_is_rejected() -> void:
	var kaelen := _char("kaelen")
	var e := _encounter([kaelen], [_monster("zombie")])
	_force_turn(e, kaelen)
	var target_index := int(e.combatants[1]["index"])
	var result := e.attack_active(target_index)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("Move closer"), String(result["message"]))


func test_attack_consumes_standard_action() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie])
	_force_turn(e, kaelen)
	kaelen.hp = kaelen.max_hp
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	var zombie_hp := zombie.hp
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(e.turn_state["standard_used"]))
	assert_true(zombie.hp <= zombie_hp)
	var second := e.attack_active(1)
	assert_false(bool(second["ok"]))
	assert_true(String(second["message"]).contains("standard action"))


func test_ranged_attack_requires_line_of_sight() -> void:
	var sera := _char("sera")
	sera.equip("weapon", content.get_item("light_crossbow"))
	var zombie := _monster("zombie")
	var map := _map([
		"#########",
		"#...#...#",
		"#...#...#",
		"#...#...#",
		"#...#...#",
		"#...#...#",
		"#########",
	])
	var e := Encounter.new()
	e.setup(
		[sera],
		[zombie],
		map,
		rng,
		[Vector2i(1, 3)],
		[Vector2i(7, 3)],
		content.spells,
		"LOS test"
	)
	e.begin()
	_preload_ranged_weapons(e)
	_force_turn(e, sera)
	var result := e.attack_active(1)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("line of sight"), String(result["message"]))


func test_moving_out_of_threatened_square_provokes_attack_of_opportunity() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(1, 2)
	# A creature that has not taken its first turn is flat-footed and cannot make
	# attacks of opportunity (PHB p.133), so let the zombie's first turn pass
	# before exercising the movement reaction.
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	kaelen.hp = kaelen.max_hp
	var result := e.move_active_to(Vector2i(3, 2))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var log_text := "\n".join(e.log_lines)
	assert_true(log_text.contains("attack of opportunity"), "the log must show the provoked attack")
	assert_true(bool(e.aoo_used.get(1, false)), "the zombie's reaction is spent")


func test_five_foot_step_does_not_provoke() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(1, 2)
	_force_turn(e, kaelen)
	var result := e.move_active_to(Vector2i(3, 2), true)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_false("\n".join(e.log_lines).contains("attack of opportunity"))


func test_damage_reduction_5_slashing() -> void:
	var zombie := _monster("zombie")
	var e := _encounter([_char("kaelen")], [zombie])
	e._apply_damage(zombie, {"damage": 10, "damage_type": "bludgeoning"})
	assert_eq(zombie.hp, 11, "bludgeoning is reduced by 5")
	e._apply_damage(zombie, {"damage": 10, "damage_type": "slashing"})
	assert_eq(zombie.hp, 1, "slashing bypasses DR 5/slashing")


func test_ghoul_paralysis_affects_humans_but_not_elves() -> void:
	var ghoul := _monster("ghoul")
	var human := _char("kaelen")
	var elf := _char("ysolde")
	var e := _encounter([human, elf], [ghoul])
	var paralyzed := false
	for seed_value in range(1, 80):
		human.remove_effect("paralyzed")
		e.rng.seed = seed_value
		e._try_paralysis(ghoul, human, {"paralysis_dc": 12})
		if human.has_condition("paralyzed"):
			paralyzed = true
			break
	assert_true(paralyzed, "a failed DC 12 Fortitude save paralyzes a human")
	e.rng.seed = 123
	e._try_paralysis(ghoul, elf, {"paralysis_dc": 12})
	assert_false(elf.has_condition("paralyzed"), "elves are immune to ghoul paralysis")


func test_magic_missile_consumes_slot_and_kills_target() -> void:
	var ysolde := _char("ysolde")
	var zombie := _monster("zombie")
	zombie.hp = 1
	var e := _encounter([ysolde], [zombie], Vector2i(1, 5), Vector2i(5, 5))
	_force_turn(e, ysolde)
	var zombie_index := int(e.combatants[1]["index"])
	var result := e.cast_active_spell("magic_missile", zombie_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(ysolde.spell_slots_remaining(1), 2)
	assert_true(zombie.has_condition("dead"), "2 missiles (1d4+1 each) kill a 1 HP zombie")
	assert_true(e.finished)
	assert_eq(e.outcome, "victory")


func test_spell_range_is_enforced() -> void:
	var ysolde := _char("ysolde")
	var zombie := _monster("zombie")
	var big := _map([
		"#############",
		"#...........#",
		"#...........#",
		"#...........#",
		"#...........#",
		"#...........#",
		"#############",
	])
	var e := _encounter([ysolde], [zombie], Vector2i(1, 5), Vector2i(9, 5), big)
	_force_turn(e, ysolde)
	var result := e.cast_active_spell("scorching_ray", int(e.combatants[1]["index"]))
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("out of range"), String(result["message"]))


func test_victory_and_defeat_detection() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie])
	for entry in e.combatants:
		if int(entry["team"]) == 1:
			entry["char"].take_damage(99)
	e._check_end()
	assert_true(e.finished)
	assert_eq(e.outcome, "victory")

	var party := [_char("kaelen")]
	var e2 := _encounter(party, [_monster("zombie")])
	party[0].take_damage(99)
	e2._check_end()
	assert_true(e2.finished)
	assert_eq(e2.outcome, "defeat")


func test_defeat_when_party_is_only_dying_or_stable() -> void:
	var dying := _char("kaelen")
	var stable := _char("sera")
	var e := _encounter([dying, stable], [_monster("zombie")])
	dying.take_damage(35)
	assert_true(dying.has_condition("dying"))
	stable.take_damage(20)
	stable.stabilize()
	assert_true(stable.has_condition("stable"))
	e._check_end()
	assert_true(e.finished, "a party with no conscious member must not stall")
	assert_eq(e.outcome, "defeat")


func test_zombie_single_action_flag_is_data_driven() -> void:
	var zombie := _monster("zombie")
	assert_true(zombie.single_actions_only)
	assert_eq(int(zombie.damage_reduction.get("amount", 0)), 5)
	assert_true(zombie.tags.has("undead"))


func test_skill_based_stabilisation() -> void:
	var aldric := _char("aldric")
	var kaelen := _char("kaelen")
	kaelen.take_damage(35)
	assert_true(kaelen.has_condition("dying"))
	var e := _encounter([aldric, kaelen], [_monster("zombie")])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, aldric)
	var result := e.stabilize_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true("\n".join(e.log_lines).contains("DC 15"))


func test_power_attack_requires_strength_13() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["str"] = 12
	kaelen.feats.append("Power Attack")
	assert_false(Feats.has_active(kaelen, "power_attack"))
	var check := Feats.prereqs(kaelen, "power_attack")
	assert_false(bool(check["ok"]))
	assert_true("\n".join(check["reasons"]).contains("requires STR 13"), str(check["reasons"]))


func test_power_attack_commits_trade_until_next_turn() -> void:
	var kaelen := _char("kaelen")
	kaelen.feats.append("Power Attack")
	var weapon: Dictionary = kaelen.equipment.get("weapon", {})
	assert_eq(Feats.power_attack_max(kaelen), 3, "maximum equals base attack bonus")
	assert_eq(Feats.power_attack_attack_penalty(kaelen, 2), -2)
	assert_eq(Feats.power_attack_attack_penalty(kaelen, 99), -3, "the trade is capped by BAB")
	assert_eq(Rules.damage_bonus(kaelen, weapon, 5), 3, "Strength +3 without Power Attack")
	assert_eq(Rules.damage_bonus(kaelen, weapon, 5, 2), 5, "Power Attack adds the same amount")
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	var commit := e.set_active_power_attack(2)
	assert_true(bool(commit["ok"]), String(commit.get("message", "")))
	assert_eq(e.active_power_attack_amount(), 2)
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_eq(String(attack["attack_mode"]), "melee")
	assert_eq(int(attack["power_attack"]), 2)
	assert_eq(int(attack["power_attack_penalty"]), -2)
	assert_eq(int(attack["bonus"]), Rules.attack_bonus(kaelen, weapon, 5, "melee") - 2)
	assert_true(String(attack["label"]).contains("Power Attack -2"))
	assert_true(String(result["message"]).contains("Power Attack -2"))
	assert_eq(e.active_power_attack_amount(), 2, "the choice remains committed after the attack")
	var changed := e.set_active_power_attack(1)
	assert_false(bool(changed["ok"]), "the amount cannot be changed after an attack roll")
	assert_true(String(changed["message"]).contains("before the attack roll"), String(changed["message"]))
	# Two combatants: advance to the zombie and back to Kaelen's next turn.
	e.end_turn()
	assert_eq(e.active_character(), zombie)
	e.end_turn()
	assert_eq(e.active_character(), kaelen)
	assert_eq(e.active_power_attack_amount(), 0, "the committed amount expires at the next turn")
	var loaded := Character.from_dict(kaelen.to_dict(), content.items)
	assert_true(Feats.has_active(loaded, "power_attack"), "the feat survives a save round trip")


func test_power_attack_light_and_two_handed_damage_rules() -> void:
	var kaelen := _char("kaelen")
	kaelen.feats.append("Power Attack")
	var short_sword := content.get_item("short_sword")
	assert_false(short_sword.is_empty())
	assert_eq(Feats.power_attack_damage_bonus(kaelen, short_sword, 2), 0, "light weapons gain no damage")
	assert_eq(Feats.power_attack_attack_penalty(kaelen, 2), -2, "light weapons still take the attack penalty")
	var greatsword := {"name": "Greatsword", "damage": "2d6", "two_handed": true}
	assert_eq(Feats.power_attack_damage_bonus(kaelen, greatsword, 2), 4, "two-handed weapons add twice")
	var unarmed := {"name": "unarmed strike", "damage": "1d3", "attack_modes": ["melee"]}
	assert_eq(Feats.power_attack_damage_bonus(kaelen, unarmed, 2), 2, "unarmed strikes are the light-weapon exception")
	var natural := {"name": "Claw", "damage": "1d4", "natural": true, "attack_modes": ["melee"]}
	assert_eq(Feats.power_attack_damage_bonus(kaelen, natural, 2), 2, "natural weapons are the light-weapon exception")
	var plain := _char("kaelen")
	assert_eq(Feats.power_attack_max(plain), 0, "no feat, no trade")
	assert_eq(Feats.power_attack_damage_bonus(plain, greatsword, 2), 0)


func test_power_attack_choice_requires_feat_and_bab_cap() -> void:
	var kaelen := _char("kaelen")
	var e := _encounter([kaelen], [_monster("zombie")])
	_force_turn(e, kaelen)
	var missing := e.set_active_power_attack(1)
	assert_false(bool(missing["ok"]))
	assert_true(String(missing["message"]).contains("does not have Power Attack"), String(missing["message"]))
	kaelen.feats.append("Power Attack")
	var excess := e.set_active_power_attack(4)
	assert_false(bool(excess["ok"]))
	assert_true(String(excess["message"]).contains("between 0 and 3"), String(excess["message"]))
	var zero := e.set_active_power_attack(0)
	assert_true(bool(zero["ok"]))
	assert_eq(e.active_power_attack_amount(), 0)


func test_power_attack_does_not_penalize_ranged_attacks() -> void:
	var kaelen := _char("kaelen")
	kaelen.feats.append("Power Attack")
	var crossbow := content.get_item("light_crossbow")
	kaelen.equip("weapon", crossbow)
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_eq(String(attack["attack_mode"]), "ranged")
	assert_eq(int(attack["power_attack"]), 0, "ranged attacks get no Power Attack penalty")
	assert_eq(int(attack["power_attack_penalty"]), 0)
	assert_eq(int(attack["bonus"]), Rules.attack_bonus(kaelen, crossbow, 5, "ranged"))
	assert_eq(e.active_power_attack_amount(), 2, "the melee choice remains until the next turn")


func test_melee_dagger_is_melee_but_thrown_is_explicit() -> void:
	var dagger := content.get_item("dagger")
	assert_eq(Rules.weapon_attack_modes(dagger), ["melee", "thrown"])
	assert_eq(Rules.default_attack_mode(dagger), "melee")
	assert_false(Rules.is_ranged_weapon(dagger), "a melee dagger is not automatically ranged")
	assert_false(Rules.is_ranged_weapon(dagger, "melee"))
	assert_true(Rules.is_ranged_weapon(dagger, "thrown"))
	assert_eq(Rules.normalize_attack_mode(dagger, "ranged"), "", "a dagger cannot use a projectile mode")
	var melee_attacker := _char("kaelen")
	melee_attacker.feats.append("Power Attack")
	melee_attacker.equip("weapon", dagger)
	var melee_target := _monster("zombie")
	melee_target.max_hp = 100
	melee_target.hp = 100
	var melee := _encounter([melee_attacker], [melee_target])
	melee.combatants[0]["cell"] = Vector2i(2, 2)
	melee.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(melee, melee_attacker)
	assert_true(bool(melee.set_active_power_attack(2)["ok"]))
	var melee_result := melee.attack_active(1, "melee")
	assert_true(bool(melee_result["ok"]), String(melee_result.get("message", "")))
	var melee_attack: Dictionary = melee_result["result"]
	assert_eq(String(melee_attack["attack_mode"]), "melee")
	assert_eq(int(melee_attack["power_attack"]), 2)
	assert_eq(int(melee_attack["bonus"]), Rules.attack_bonus(melee_attacker, dagger, 5, "melee") - 2)
	assert_eq(Rules.damage_bonus(melee_attacker, dagger, 5, 2, "melee"), 3, "melee dagger is light: Str 3 but no Power Attack damage")
	var thrown_attacker := _char("kaelen")
	thrown_attacker.feats.append("Power Attack")
	thrown_attacker.equip("weapon", dagger)
	var thrown_target := _monster("zombie")
	thrown_target.max_hp = 100
	thrown_target.hp = 100
	var thrown := _encounter([thrown_attacker], [thrown_target])
	thrown.combatants[0]["cell"] = Vector2i(2, 2)
	thrown.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(thrown, thrown_attacker)
	assert_true(bool(thrown.set_active_power_attack(2)["ok"]))
	var thrown_result := thrown.attack_active(1, "thrown")
	assert_true(bool(thrown_result["ok"]), String(thrown_result.get("message", "")))
	var thrown_attack: Dictionary = thrown_result["result"]
	assert_eq(String(thrown_attack["attack_mode"]), "thrown")
	assert_true(bool(thrown_attack["ranged"]))
	assert_eq(int(thrown_attack["power_attack"]), 0, "Power Attack does not apply to a thrown attack")
	assert_eq(Rules.damage_bonus(thrown_attacker, dagger, 5, 2, "thrown"), 3, "a thrown dagger adds Strength but not Power Attack")
	assert_true(String(thrown_result["message"]).contains("(thrown)"))


func test_power_attack_applies_to_opportunity_attack() -> void:
	var kaelen := _char("kaelen")
	kaelen.feats.append("Power Attack")
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	_force_turn(e, zombie)
	assert_eq(e.power_attack_amount_for(0), 2, "another actor's turn does not erase the commitment")
	var move := e.move_active_to(Vector2i(3, 3))
	assert_true(bool(move["ok"]), String(move.get("message", "")))
	var log_text := "\n".join(e.log_lines)
	assert_true(log_text.contains("attack of opportunity"), "the off-turn attack resolves")
	assert_true(log_text.contains("Power Attack -2"), "the committed amount is used by the opportunity attack")
	assert_eq(e.power_attack_amount_for(0), 2, "the commitment survives the opportunity attack")


func test_power_attack_committed_state_is_per_actor() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	kaelen.feats.append("Power Attack")
	sera.abilities["str"] = 13
	sera.feats.append("Power Attack")
	var e := _encounter([kaelen, sera], [_monster("zombie")])
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	_force_turn(e, sera)
	assert_true(bool(e.set_active_power_attack(1)["ok"]))
	assert_eq(e.power_attack_amount_for(0), 2, "Kaelen's state is separate")
	assert_eq(e.power_attack_amount_for(1), 1, "Sera's state is separate")
	_force_turn(e, kaelen)
	assert_eq(e.power_attack_amount_for(0), 0, "Kaelen's next turn expires only his state")
	assert_eq(e.power_attack_amount_for(1), 1, "Sera's committed state remains")


func test_power_attack_critical_multiplies_the_damage_bonus() -> void:
	var kaelen := _char("kaelen")
	kaelen.feats.append("Power Attack")
	var target := _char("sera")
	target.ac_misc = -20
	var sword := {
		"name": "QA Sword",
		"damage": "1d1",
		"crit_range": 19,
		"crit_mult": 2,
		"attack_modes": ["melee"],
	}
	var e := _encounter([kaelen], [target])
	var found := false
	for seed_value in range(1, 500):
		e.rng.seed = seed_value
		var result := Rules.attack(
			e.rng, kaelen, target, sword, 5, {"power_attack": 2, "attack_mode": "melee"}
		)
		if bool(result["critical_confirmed"]):
			found = true
			assert_eq(int(result["damage"]), 12, "(1d1 + Str 3 + Power Attack 2) x 2")
			break
	assert_true(found, "a confirmed critical was found in the deterministic seed range")


func test_two_handed_power_attack_actual_damage() -> void:
	var kaelen := _char("kaelen")
	kaelen.feats.append("Power Attack")
	kaelen.equip("weapon", {
		"name": "Greatsword",
		"damage": "1d1",
		"crit_range": 21,
		"crit_mult": 2,
		"attack_modes": ["melee"],
		"two_handed": true,
	})
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	zombie.ac_misc = -20
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	e.rng.seed = 2
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(result["result"]["hit"]), String(result.get("message", "")))
	assert_eq(int(result["result"]["damage"]), 8, "1 + Str 3 + doubled Power Attack 4")


func test_light_weapon_actual_attack_keeps_penalty_without_damage_bonus() -> void:
	var kaelen := _char("kaelen")
	kaelen.feats.append("Power Attack")
	kaelen.equip("weapon", {
		"name": "QA Light Blade",
		"damage": "1d1",
		"crit_range": 21,
		"crit_mult": 2,
		"attack_modes": ["melee"],
		"light_weapon": true,
	})
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	zombie.ac_misc = -20
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	e.rng.seed = 2
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(result["result"]["hit"]), String(result.get("message", "")))
	assert_eq(int(result["result"]["power_attack_penalty"]), -2)
	assert_eq(int(result["result"]["damage"]), 4, "1 + Str 3, with no light-weapon Power Attack damage")


func test_combat_expertise_requires_intelligence_13() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 12
	kaelen.feats.append("Combat Expertise")
	assert_false(Feats.has_active(kaelen, "combat_expertise"))
	var check := Feats.prereqs(kaelen, "combat_expertise")
	assert_false(bool(check["ok"]))
	assert_true("\n".join(check["reasons"]).contains("requires INT 13"), str(check["reasons"]))
	assert_eq(Feats.combat_expertise_max(kaelen), 0, "no legal amount without the prerequisite")


func test_combat_expertise_caps_at_five_and_base_attack() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	assert_eq(Feats.combat_expertise_max(kaelen), 3, "base attack bonus 3 limits the trade")
	assert_eq(Feats.combat_expertise_attack_penalty(kaelen, 2), -2)
	assert_eq(Feats.combat_expertise_attack_penalty(kaelen, 99), -3, "BAB caps the trade")
	kaelen.base_attack = 10
	assert_eq(Feats.combat_expertise_max(kaelen), 5, "the printed maximum is +5")
	assert_eq(Feats.combat_expertise_attack_penalty(kaelen, 99), -5)
	kaelen.base_attack = 0
	assert_eq(Feats.combat_expertise_max(kaelen), 0, "zero BAB permits no positive amount")
	var plain := _char("kaelen")
	assert_eq(Feats.combat_expertise_max(plain), 0, "no feat, no trade")


func test_combat_expertise_commits_only_on_melee_attack_and_expires() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	var weapon: Dictionary = kaelen.equipment.get("weapon", {})
	var baseline_ac := Rules.armor_class(kaelen)
	var baseline_touch := Rules.touch_ac(kaelen)
	assert_eq(Rules.armor_class(kaelen), baseline_ac, "no benefit before the qualifying attack")
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	var pending := e.set_active_combat_expertise(2)
	assert_true(bool(pending["ok"]), String(pending.get("message", "")))
	assert_eq(e.active_combat_expertise_pending_amount(), 2)
	assert_eq(e.active_combat_expertise_amount(), 0)
	assert_eq(Rules.armor_class(kaelen), baseline_ac, "the pending choice is not AC yet")
	assert_false(kaelen.has_effect("combat_expertise"))
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_eq(String(attack["attack_mode"]), "melee")
	assert_eq(int(attack["combat_expertise"]), 2)
	assert_eq(int(attack["combat_expertise_penalty"]), -2)
	assert_eq(
		int(attack["bonus"]),
		Rules.attack_bonus(kaelen, weapon, 5, "melee") - 2,
		"the activating attack itself takes the penalty"
	)
	assert_eq(Rules.damage_bonus(kaelen, weapon, 5, 0, "melee"), 3, "Combat Expertise is not a damage bonus")
	assert_true(String(attack["label"]).contains("Combat Expertise -2"))
	assert_true(String(result["message"]).contains("Combat Expertise -2"))
	assert_eq(e.active_combat_expertise_amount(), 2, "the effect is committed after the attack")
	assert_eq(e.active_combat_expertise_pending_amount(), 0, "pending input is cleared")
	assert_eq(Feats.combat_expertise_dodge_bonus(kaelen), 2)
	assert_eq(Rules.armor_class(kaelen), baseline_ac + 2, "dodge AC applies after activation")
	assert_eq(Rules.touch_ac(kaelen), baseline_touch + 2, "dodge applies to touch AC")
	# PHB p.87: losing a prerequisite suspends the benefit until it returns.
	kaelen.abilities["int"] = 12
	assert_eq(Feats.combat_expertise_dodge_bonus(kaelen), 0, "a lost Int 13 suspends the bonus")
	assert_eq(Rules.armor_class(kaelen), baseline_ac, "temporary Int loss removes the dodge AC")
	kaelen.abilities["int"] = 13
	assert_eq(Rules.armor_class(kaelen), baseline_ac + 2, "the committed choice resumes with Int 13")
	var changed := e.set_active_combat_expertise(1)
	assert_false(bool(changed["ok"]), "the committed amount cannot change after the attack")
	assert_true(String(changed["message"]).contains("before the attack roll"), String(changed["message"]))
	# The effect lasts through other actors' turns and expires at the next turn.
	e.end_turn()
	assert_eq(e.active_character(), zombie)
	e.end_turn()
	assert_eq(e.active_character(), kaelen)
	assert_eq(e.active_combat_expertise_amount(), 0, "the effect expires at the next turn")
	assert_false(kaelen.has_effect("combat_expertise"))
	assert_eq(Rules.armor_class(kaelen), baseline_ac, "AC returns to its pre-activation value")
	var loaded := Character.from_dict(kaelen.to_dict(), content.items)
	assert_true(Feats.has_active(loaded, "combat_expertise"), "the feat survives a save round trip")


func test_combat_expertise_does_not_commit_on_ranged_attack() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	kaelen.equip("weapon", content.get_item("light_crossbow"))
	var baseline_ac := Rules.armor_class(kaelen)
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_true(bool(attack["ranged"]))
	assert_eq(int(attack["combat_expertise"]), 0, "a ranged attack is not a qualifying melee action")
	assert_eq(int(attack["combat_expertise_penalty"]), 0)
	assert_eq(e.active_combat_expertise_amount(), 0)
	assert_eq(e.active_combat_expertise_pending_amount(), 0, "the unused pending choice is discarded")
	assert_eq(Rules.armor_class(kaelen), baseline_ac)


func test_combat_expertise_dodge_bonus_stacks_and_is_lost_flat_footed() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	var baseline_ac := Rules.armor_class(kaelen)
	var baseline_touch := Rules.touch_ac(kaelen)
	var baseline_flat := Rules.armor_class(kaelen, {"flat_footed": true})
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	assert_true(bool(e.attack_active(1)["ok"]))
	assert_eq(Rules.armor_class(kaelen), baseline_ac + 2)
	assert_eq(Rules.touch_ac(kaelen), baseline_touch + 2)
	assert_eq(
		Rules.armor_class(kaelen, {"flat_footed": true}),
		baseline_flat,
		"a flat-footed defender loses the Combat Expertise dodge bonus"
	)
	kaelen.feats.append("Dodge")
	assert_eq(Rules.armor_class(kaelen), baseline_ac + 3, "dodge bonuses stack")
	assert_eq(Rules.touch_ac(kaelen), baseline_touch + 3)
	assert_eq(
		Rules.armor_class(kaelen, {"flat_footed": true}),
		baseline_flat,
		"Dodge's dodge bonus is denied while flat-footed (PHB p.136), like Combat Expertise's"
	)


func test_combat_expertise_applies_to_opportunity_attack_and_combines_with_power_attack() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	kaelen.feats.append("Power Attack")
	var weapon: Dictionary = kaelen.equipment.get("weapon", {})
	var baseline_ac := Rules.armor_class(kaelen)
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	zombie.ac_misc = -20
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	assert_eq(Rules.armor_class(kaelen), baseline_ac, "Power Attack alone grants no AC")
	var result := e.attack_active(1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_true(bool(attack["hit"]), String(result.get("message", "")))
	assert_eq(int(attack["power_attack"]), 2, "Power Attack remains a separate committed choice")
	assert_eq(int(attack["combat_expertise"]), 2)
	assert_eq(
		int(attack["bonus"]),
		Rules.attack_bonus(kaelen, weapon, 5, "melee") - 4,
		"the two attack penalties combine"
	)
	assert_eq(Rules.damage_bonus(kaelen, weapon, 5, 2, "melee"), 5, "Power Attack still adds damage")
	assert_eq(Rules.damage_bonus(kaelen, weapon, 5, 0, "melee"), 3, "Combat Expertise contributes no damage")
	assert_eq(Rules.armor_class(kaelen), baseline_ac + 2, "only Combat Expertise adds dodge AC")
	_force_turn(e, zombie)
	var move := e.move_active_to(Vector2i(3, 3))
	assert_true(bool(move["ok"]), String(move.get("message", "")))
	var log_text := "\n".join(e.log_lines)
	assert_true(log_text.contains("attack of opportunity"), "the off-turn attack resolves")
	assert_true(log_text.contains("Power Attack -2"), "the opportunity attack keeps Power Attack")
	assert_true(log_text.contains("Combat Expertise -2"), "the opportunity attack keeps Combat Expertise")
	assert_eq(e.combat_expertise_amount_for(0), 2, "the commitment survives the opportunity attack")
	e.end_turn()
	assert_eq(e.active_character(), kaelen)
	assert_eq(e.active_power_attack_amount(), 0)
	assert_eq(e.active_combat_expertise_amount(), 0)
	assert_false(kaelen.has_effect("combat_expertise"))


func test_combat_expertise_incoming_attack_uses_the_committed_dodge_ac() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	assert_true(bool(e.attack_active(1)["ok"]))
	_force_turn(e, zombie)
	var incoming := e.attack_active(0)
	assert_true(bool(incoming["ok"]), String(incoming.get("message", "")))
	var attack: Dictionary = incoming["result"]
	assert_eq(
		int(attack["target_ac"]),
		Rules.armor_class(kaelen),
		"the incoming attack uses the committed dodge bonus"
	)
	assert_true(String(incoming["message"]).contains("vs AC"), String(incoming["message"]))


func test_combat_expertise_state_is_per_actor() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	kaelen.abilities["int"] = 13
	sera.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	sera.feats.append("Combat Expertise")
	var e := _encounter([kaelen, sera], [_monster("zombie")])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[2]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	assert_true(bool(e.attack_active(2)["ok"]))
	assert_eq(e.combat_expertise_amount_for(0), 2)
	_force_turn(e, sera)
	assert_eq(e.combat_expertise_amount_for(0), 2, "Kaelen's commitment survives Sera's turn")
	assert_eq(e.active_combat_expertise_amount(), 0, "Sera has no committed choice of her own")
	assert_true(bool(e.set_active_combat_expertise(1)["ok"]))
	assert_eq(e.combat_expertise_pending_for(1), 1)
	_force_turn(e, kaelen)
	assert_eq(e.combat_expertise_amount_for(0), 0, "only Kaelen's state expires on his next turn")
	assert_eq(e.combat_expertise_pending_for(1), 1, "Sera's pending choice remains hers")


func test_combat_expertise_pending_never_activates_on_an_opportunity_attack() -> void:
	# PHB p.92: the choice is made when you use the attack action or full attack
	# action in melee. An opportunity attack is neither, so a pending amount must
	# not activate there even though a committed amount does apply to it.
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	var baseline_ac := Rules.armor_class(kaelen)
	var zombie := _monster("zombie")
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([kaelen], [zombie])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	assert_eq(e.active_combat_expertise_pending_amount(), 2)
	_force_turn(e, zombie)
	var log_start := e.log_lines.size()
	var move := e.move_active_to(Vector2i(3, 3))
	assert_true(bool(move["ok"]), String(move.get("message", "")))
	var turn_log := "\n".join(e.log_lines.slice(log_start))
	assert_true(turn_log.contains("attack of opportunity"), "the off-turn attack resolves")
	assert_false(
		turn_log.contains("Combat Expertise"),
		"an opportunity attack must not activate the pending amount"
	)
	assert_eq(e.combat_expertise_amount_for(0), 0, "nothing was committed by the opportunity attack")
	assert_eq(e.combat_expertise_pending_for(0), 2, "the pending choice is untouched")
	assert_eq(Rules.armor_class(kaelen), baseline_ac, "no dodge AC before the attack action")
	_force_turn(e, kaelen)
	assert_eq(e.combat_expertise_pending_for(0), 0, "an unused pending choice expires at the next turn")


func test_combat_expertise_effect_is_removed_when_combat_ends() -> void:
	var kaelen := _char("kaelen")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	var e := _encounter([kaelen], [_monster("zombie")])
	e.combatants[0]["cell"] = Vector2i(2, 2)
	e.combatants[1]["cell"] = Vector2i(2, 3)
	_force_turn(e, kaelen)
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	assert_true(bool(e.attack_active(1)["ok"]))
	assert_true(kaelen.has_effect("combat_expertise"))
	e.finish("victory")
	assert_false(kaelen.has_effect("combat_expertise"), "combat state does not leak into exploration")
	assert_eq(e.combat_expertise_amount_for(0), 0)
	assert_true(Feats.has_active(kaelen, "combat_expertise"), "the feat itself remains")
