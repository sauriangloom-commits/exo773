extends GutTest

## Cleave (PHB p.92): "If you deal a creature enough damage to make it drop
## (typically by dropping it to below 0 hit points or killing it), you get an
## immediate, extra melee attack against another creature within reach. You
## cannot take a 5-foot step before making this extra attack. The extra attack
## is with the same weapon and at the same bonus as the attack that dropped the
## previous creature. You can use this ability once per round."
##
## Great Cleave (no per-round limit) is not implemented.

var content: ContentDB


func before_each() -> void:
	content = Game.content


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
		"test"
	)


func _encounter(
	party: Array,
	monsters: Array,
	party_cells: Array = [],
	monster_cells: Array = [],
	seed_value: int = 771
) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pcells: Array = party_cells
	var mcells: Array = monster_cells
	if pcells.is_empty():
		for i in party.size():
			pcells.append(Vector2i(2, 3 + i))
	if mcells.is_empty():
		for i in monsters.size():
			mcells.append(Vector2i(3, 3 + i))
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, pcells, mcells, content.spells, "Test")
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _fighter(with_cleave := true) -> Character:
	var ch := _char("kaelen")
	ch.feats.clear()
	ch.abilities["str"] = 13
	ch.feats.append("Power Attack")
	if with_cleave:
		ch.feats.append("Cleave")
	return ch


func _enemy(hp := 1) -> Character:
	var ch := _monster("zombie")
	ch.max_hp = 200
	ch.hp = hp
	ch.ac_misc = -30
	ch.damage_reduction.clear()
	return ch


func test_prerequisites_are_str_13_and_power_attack() -> void:
	var ch := _char("kaelen")
	ch.feats.clear()
	ch.abilities["str"] = 12
	ch.feats.append("Power Attack")
	ch.feats.append("Cleave")
	var low_str := Feats.prereqs(ch, "cleave")
	assert_false(bool(low_str["ok"]))
	assert_true(" ".join(low_str["reasons"]).contains("STR 13"), str(low_str["reasons"]))
	assert_false(Feats.has_active(ch, "cleave"), "an unmet prerequisite suspends the feat")

	ch.abilities["str"] = 13
	ch.feats.clear()
	ch.feats.append("Cleave")
	var missing := Feats.prereqs(ch, "cleave")
	assert_false(bool(missing["ok"]))
	assert_true(" ".join(missing["reasons"]).contains("Power Attack"), str(missing["reasons"]))

	ch.feats.append("Power Attack")
	assert_true(bool(Feats.prereqs(ch, "cleave")["ok"]))
	assert_true(Feats.has_active(ch, "cleave"))


func test_dropping_a_creature_offers_another_target_in_reach() -> void:
	var fighter := _fighter()
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	var result := e.attack_active(1)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	assert_eq(String(result.get("pending", "")), "cleave_attack", "a drop offers Cleave")
	assert_true(e.has_pending_decision())
	assert_eq(String(e.pending_cleave.get("type", "")), "cleave_attack")
	assert_true(near.hp < 0 or near.has_condition("dead"), "the first enemy dropped")
	var targets := e.cleave_targets(0, 1)
	assert_eq(targets.size(), 1, "only the other living enemy is eligible")
	assert_eq(int(targets[0]["index"]), 2)


func test_merely_hitting_a_creature_does_not_offer_cleave() -> void:
	var fighter := _fighter()
	var sturdy := _enemy(60)
	var other := _enemy(1)
	var e := _encounter([fighter], [sturdy, other])
	_force_turn(e, fighter)
	e.attack_active(1)
	assert_false(e.has_pending_decision(), "the target survived, so nothing dropped")


func test_a_fighter_without_cleave_gets_no_extra_attack() -> void:
	var fighter := _fighter(false)
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	var result := e.attack_active(1)
	assert_eq(String(result.get("pending", "")), "")
	assert_false(e.has_pending_decision())


func test_targets_exclude_the_dropped_creature_allies_and_unreachable_enemies() -> void:
	var fighter := _fighter()
	var ally := _char("sera")
	var near := _enemy(1)
	var adjacent := _enemy(1)
	var far := _enemy(1)
	var e := _encounter(
		[fighter, ally],
		[near, adjacent, far],
		[Vector2i(2, 3), Vector2i(1, 3)],
		[Vector2i(3, 3), Vector2i(3, 4), Vector2i(7, 6)]
	)
	_force_turn(e, fighter)
	# Party indices 0-1, enemies 2-4. Only the adjacent enemy is another legal
	# creature within reach.
	var targets := e.cleave_targets(0, 2)
	assert_eq(targets.size(), 1)
	assert_eq(int(targets[0]["index"]), 3)


func test_the_extra_attack_uses_the_same_weapon_and_bonus() -> void:
	var fighter := _fighter()
	fighter.abilities["str"] = 16
	fighter.equip("weapon", content.items["masterwork_longsword"])
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	var first := e.attack_active(1)
	assert_eq(String(first.get("pending", "")), "cleave_attack")
	var stored := int(e.pending_cleave.get("attack_base", 0))
	assert_eq(stored, int(first["result"]["bonus_base"]), "Cleave stores the triggering attack's bonus")
	var resolved := e.resolve_cleave_attack(2)
	assert_true(bool(resolved.get("ok", false)), String(resolved.get("message", "")))
	var follow: Dictionary = resolved["result"]
	assert_eq(int(follow["bonus"]), stored, "the extra attack keeps the same attack bonus")
	assert_true(String(follow["label"]).contains("Longsword"), "the same weapon is used")
	assert_eq(int(follow["power_attack"]), 2, "the committed Power Attack is preserved")


func test_movement_and_a_five_foot_step_are_refused_while_the_grant_is_pending() -> void:
	var fighter := _fighter()
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	e.attack_active(1)
	assert_true(e.has_pending_decision())
	assert_false(bool(e.move_active_to(Vector2i(2, 4))["ok"]), "no movement before the extra attack")
	assert_false(bool(e.move_active_to(Vector2i(2, 4), true)["ok"]), "no 5-foot step before the extra attack")
	assert_false(bool(e.attack_active(2)["ok"]), "the extra attack is target-selected through the decision")


func test_cleave_is_usable_only_once_per_round() -> void:
	var fighter := _fighter()
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	e.attack_active(1)
	assert_true(e.has_pending_decision())
	var resolved := e.resolve_cleave_attack(2)
	assert_true(bool(resolved.get("ok", false)))
	assert_true(bool(e.cleave_used.has(0)), "the use is consumed by the extra attack")
	assert_false(e.has_pending_decision(), "the extra attack's own drop cannot chain another Cleave")


func test_declining_restores_ordinary_play_without_consuming_the_use() -> void:
	var fighter := _fighter()
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	e.attack_active(1)
	var hp_before := other.hp
	var declined := e.decline_cleave()
	assert_true(bool(declined.get("ok", false)))
	assert_false(e.has_pending_decision())
	assert_eq(other.hp, hp_before, "declining rolls no attack")
	assert_false(bool(e.cleave_used.has(0)), "declining does not consume the once-per-round use")
	assert_true(String(e.get_log_text()).contains("declines the Cleave attack"))
	assert_true(bool(e.move_active_to(Vector2i(2, 4))["ok"]), "ordinary play continues")


func test_a_resolved_cleave_cannot_be_submitted_twice() -> void:
	var fighter := _fighter()
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	e.attack_active(1)
	e.resolve_cleave_attack(2)
	var hp_after := other.hp
	var again := e.resolve_cleave_attack(2)
	assert_false(bool(again.get("ok", false)))
	assert_eq(other.hp, hp_after, "a duplicate submission deals no further damage")


func test_no_legal_target_means_no_decision_and_the_encounter_can_end() -> void:
	var fighter := _fighter()
	var only := _enemy(1)
	var e := _encounter([fighter], [only])
	_force_turn(e, fighter)
	var result := e.attack_active(1)
	assert_eq(String(result.get("pending", "")), "")
	assert_false(e.has_pending_decision())
	assert_true(e.finished, "dropping the last enemy ends the encounter")
	assert_eq(e.outcome, "victory")


func test_committed_power_attack_and_combat_expertise_apply_to_the_extra_attack() -> void:
	var fighter := _fighter()
	fighter.abilities["str"] = 16
	fighter.abilities["int"] = 13
	fighter.feats.append("Combat Expertise")
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	assert_true(bool(e.set_active_power_attack(2)["ok"]))
	assert_true(bool(e.set_active_combat_expertise(2)["ok"]))
	var first := e.attack_active(1)
	assert_eq(String(first.get("pending", "")), "cleave_attack")
	var stored := int(e.pending_cleave.get("attack_base", 0))
	var resolved := e.resolve_cleave_attack(2)
	var follow: Dictionary = resolved["result"]
	assert_eq(int(follow["power_attack"]), 2)
	assert_eq(int(follow["combat_expertise"]), 2)
	assert_eq(int(follow["bonus"]), stored)


func test_a_drop_from_the_improved_trip_follow_up_can_trigger_cleave() -> void:
	var fighter := _fighter()
	fighter.abilities["int"] = 13
	fighter.feats.append("Combat Expertise")
	fighter.feats.append("Improved Trip")
	fighter.equip("weapon", content.items["masterwork_longsword"])
	var near := _enemy(1)
	near.stability_bonus = -60
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	var trip := e.trip_active(1)
	assert_eq(String(trip.get("pending", "")), "improved_trip_attack")
	assert_true(e.pending_cleave.is_empty(), "the trip itself deals no damage and cannot Cleave")
	var follow := e.resolve_improved_trip_attack(true, "melee")
	assert_true(bool(follow.get("ok", false)), String(follow.get("message", "")))
	assert_eq(String(follow.get("pending", "")), "cleave_attack", "the follow-up drop grants Cleave")
	assert_true(e.has_pending_decision())
	assert_eq(String(e.pending_cleave.get("type", "")), "cleave_attack")


func test_a_dead_or_changed_pending_target_cannot_be_attacked() -> void:
	var fighter := _fighter()
	var near := _enemy(1)
	var other := _enemy(1)
	var e := _encounter([fighter], [near, other])
	_force_turn(e, fighter)
	e.attack_active(1)
	other.take_damage(999)
	var refused := e.resolve_cleave_attack(2)
	assert_false(bool(refused.get("ok", false)), "a dead creature is not a legal target")
	assert_true(e.has_pending_decision(), "the refused choice does not consume the decision")
	assert_true(bool(e.decline_cleave()["ok"]), "the player can still decline")

	var second := _fighter()
	var second_near := _enemy(1)
	var second_other := _enemy(1)
	var e2 := _encounter([second], [second_near, second_other])
	_force_turn(e2, second)
	e2.attack_active(1)
	e2.turn_ptr = (e2.turn_ptr + 1) % e2.order.size()
	var voided := e2.resolve_cleave_attack(2)
	assert_false(bool(voided.get("ok", false)))
	assert_false(e2.has_pending_decision(), "a changed turn clears the grant")
	assert_eq(second_other.hp, 1, "a voided grant deals no damage")
