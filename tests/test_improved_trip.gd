extends GutTest

## Improved Trip (PHB p.96): prerequisites INT 13 and Combat Expertise; no
## opportunity attack when tripping unarmed; +4 on the attacker's Strength check
## to trip; and an immediate melee attack after a successful trip, "as if you
## hadn't used your attack for the trip attempt".
##
## The +4 is deliberately not applied to the defender's opposed check or to a
## counter-trip: the feat improves your own attempt to trip an opponent, and a
## counter-trip is the opponent's attempt, not yours.

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


func _encounter(party: Array, monsters: Array, seed_value: int = 771) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var party_cells: Array = []
	var monster_cells: Array = []
	for i in party.size():
		party_cells.append(Vector2i(2 + i, 3))
	for i in monsters.size():
		monster_cells.append(Vector2i(3, 3 + i))
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _with_feat(ch: Character) -> Character:
	ch.abilities["int"] = 13
	ch.feats.append("Combat Expertise")
	ch.feats.append("Improved Trip")
	return ch


func _fighter() -> Character:
	var ch := _with_feat(_char("kaelen"))
	ch.abilities["str"] = 16
	return ch


## Target that almost always loses the opposed check, so a trip succeeds.
func _trip_win(ch: Character, seed_value: int = 771) -> Array:
	var zombie := _monster("zombie")
	zombie.ac_misc = -30
	zombie.stability_bonus = -60
	var e := _encounter([ch], [zombie], seed_value)
	_force_turn(e, ch)
	return [e, zombie]


func _pending_trip(ch: Character, use_weapon := false) -> Array:
	if use_weapon:
		ch.equip("weapon", content.items["light_flail"])
	for seed_value in range(1, 80):
		var fighter := _with_feat(_char("kaelen"))
		fighter.abilities["str"] = 16
		fighter.feats.append("Power Attack")
		var built := _trip_win(fighter, seed_value)
		var e: Encounter = built[0]
		var zombie: Character = built[1]
		var result := e.trip_active(1, {"use_weapon": use_weapon})
		if String(result.get("pending", "")) == "improved_trip_attack":
			return [e, fighter, zombie]
	return []


func test_prerequisites_are_int_13_and_combat_expertise() -> void:
	var ch := _char("kaelen")
	ch.abilities["int"] = 12
	ch.feats.append("Improved Trip")
	var missing_int := Feats.prereqs(ch, "improved_trip")
	assert_false(bool(missing_int["ok"]))
	assert_true(" ".join(missing_int["reasons"]).contains("INT 13"), str(missing_int["reasons"]))
	assert_false(Feats.has_active(ch, "improved_trip"), "an unmet prerequisite suspends the feat")

	ch.abilities["int"] = 13
	var missing_feat := Feats.prereqs(ch, "improved_trip")
	assert_false(bool(missing_feat["ok"]))
	assert_true(
		" ".join(missing_feat["reasons"]).contains("Combat Expertise"), str(missing_feat["reasons"])
	)

	ch.feats.append("Combat Expertise")
	assert_true(bool(Feats.prereqs(ch, "improved_trip")["ok"]), str(Feats.prereqs(ch, "improved_trip")))
	assert_true(Feats.has_active(ch, "improved_trip"))


func test_the_bonus_applies_to_the_attackers_trip_check_only() -> void:
	var compared := false
	for seed_value in range(1, 40):
		var plain := _char("kaelen")
		plain.abilities["str"] = 16
		var plain_zombie := _monster("zombie")
		plain_zombie.ac_misc = -30
		plain_zombie.stability_bonus = -60
		var plain_e := _encounter([plain], [plain_zombie], seed_value)
		_force_turn(plain_e, plain)
		var base := plain_e.trip_active(1)

		var fighter := _fighter()
		var feat_zombie := _monster("zombie")
		feat_zombie.ac_misc = -30
		feat_zombie.stability_bonus = -60
		var feat_e := _encounter([fighter], [feat_zombie], seed_value)
		_force_turn(feat_e, fighter)
		var boosted := feat_e.trip_active(1)

		if not bool(base.get("hit", false)) or not bool(boosted.get("hit", false)):
			continue
		compared = true
		assert_eq(
			int(boosted["opposed"]["attacker_modifier"]),
			int(base["opposed"]["attacker_modifier"]) + 4,
			"the trip check gains exactly +4"
		)
		assert_eq(
			int(boosted["opposed"]["defender_modifier"]),
			int(base["opposed"]["defender_modifier"]),
			"the defender's opposed check does not gain the feat bonus"
		)
		break
	assert_true(compared, "a seed should produce a hit for both attempts")


func test_the_bonus_does_not_apply_to_the_counter_trip() -> void:
	var found := false
	for seed_value in range(1, 120):
		var fighter := _with_feat(_char("kaelen"))
		fighter.abilities["str"] = 1
		fighter.equip("weapon", content.items["light_flail"])
		var zombie := _monster("zombie")
		zombie.ac_misc = -30
		var e := _encounter([fighter], [zombie], seed_value)
		_force_turn(e, fighter)
		var result := e.trip_active(1, {"use_weapon": true, "release_weapon": false})
		if not bool(result.get("countered", false)):
			continue
		found = true
		var expected := int(Rules.best_ability_modifier(fighter, ["str", "dex"])["modifier"])
		assert_eq(
			int(result["counter"]["defender_modifier"]),
			expected,
			"the counter-trip resists with the ordinary modifier, not with Improved Trip's +4"
		)
		break
	assert_true(found, "a lost trip should counter-trip in the seeded sample")


func test_improved_trip_removes_the_unarmed_provocation() -> void:
	var found := false
	for seed_value in range(1, 60):
		var fighter := _fighter()
		var built := _trip_win(fighter, seed_value)
		var e: Encounter = built[0]
		var result := e.trip_active(1)
		if not bool(result.get("hit", false)):
			continue
		found = true
		for line in e.log_lines:
			assert_false(
				String(line).contains("Attack of opportunity"),
				"Improved Trip trips unarmed without provoking: %s" % String(line)
			)
		break
	assert_true(found, "a seed should produce a successful touch attack")


func test_a_qualifying_trip_pauses_with_the_granted_attack() -> void:
	var built := _pending_trip(_fighter())
	assert_false(built.is_empty(), "a successful qualifying trip should pause")
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var fighter: Character = built[1]
	var zombie: Character = built[2]
	var hp_before := zombie.hp
	assert_eq(String(e.pending_trip.get("type", "")), "improved_trip_attack")
	assert_eq(int(e.pending_trip.get("target_index", -1)), 1)
	assert_true(zombie.is_prone(), "the trip was applied before the pause")
	assert_true(bool(e.turn_state["standard_used"]), "the trip already spent the standard action")
	assert_eq(e.active_character(), fighter, "the pause belongs to the acting character")
	assert_eq(zombie.hp, hp_before, "the granted attack is not rolled automatically")
	assert_false(bool(e.attack_active(1)["ok"]), "no unrelated attack while the grant is pending")
	assert_false(bool(e.resolve_trip_decision(true)["ok"]), "the weapon-release resolver refuses this decision")


func test_a_successful_trip_without_the_feat_does_not_pause() -> void:
	var found := false
	for seed_value in range(1, 60):
		var plain := _char("kaelen")
		plain.abilities["str"] = 16
		var built := _trip_win(plain, seed_value)
		var e: Encounter = built[0]
		var zombie: Character = built[1]
		var result := e.trip_active(1)
		if not bool(result.get("trip_success", false)):
			continue
		found = true
		assert_false(e.has_pending_decision(), "Improved Trip is what grants the extra attack")
		assert_true(zombie.is_prone())
		break
	assert_true(found, "a seed should produce a successful trip")


func test_a_missed_or_lost_trip_grants_nothing() -> void:
	var fighter := _fighter()
	var zombie := _monster("zombie")
	zombie.ac_misc = 60
	var miss_e := _encounter([fighter], [zombie])
	_force_turn(miss_e, fighter)
	var miss := miss_e.trip_active(1)
	assert_false(bool(miss.get("hit", false)))
	assert_false(miss_e.has_pending_decision(), "a missed touch attack grants no follow-up")

	var losing := _fighter()
	losing.abilities["str"] = 1
	var stable := _monster("zombie")
	stable.ac_misc = -30
	stable.stability_bonus = 100
	var lose_e := _encounter([losing], [stable])
	_force_turn(lose_e, losing)
	var lost := lose_e.trip_active(1)
	assert_false(bool(lost.get("trip_success", false)))
	assert_false(lose_e.has_pending_decision(), "a lost trip grants no follow-up")
	assert_true(losing.is_prone(), "the counter-trip still resolves normally")


func test_the_follow_up_attacks_the_tripped_target_once() -> void:
	var built := _pending_trip(_fighter())
	assert_false(built.is_empty(), "a successful qualifying trip should pause")
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var zombie: Character = built[2]
	var hp_before := zombie.hp
	var result := e.resolve_improved_trip_attack(true)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	assert_true(bool(result.get("attacked", false)))
	assert_false(e.has_pending_decision(), "the follow-up does not leave another decision")
	assert_true(bool(e.turn_state["standard_used"]), "the follow-up does not spend a second standard action")
	assert_true(String(e.get_log_text()).contains("Improved Trip grants an immediate melee attack"))
	var follow: Dictionary = result.get("result", {})
	if bool(follow.get("hit", false)):
		assert_lt(zombie.hp, hp_before, "a hit deals damage to the tripped target")
		var hp_after := zombie.hp
		assert_false(bool(e.resolve_improved_trip_attack(true)["ok"]), "the follow-up cannot be submitted twice")
		assert_eq(zombie.hp, hp_after, "a refused duplicate deals no further damage")
		assert_false(e.has_pending_decision(), "no recursive follow-up is created")
	assert_false(bool(e.attack_active(1)["ok"]), "the standard action is still spent after the follow-up")


func test_declining_the_follow_up_restores_ordinary_play() -> void:
	var built := _pending_trip(_fighter())
	assert_false(built.is_empty(), "a successful qualifying trip should pause")
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var fighter: Character = built[1]
	var zombie: Character = built[2]
	var hp_before := zombie.hp
	var result := e.resolve_improved_trip_attack(false)
	assert_true(bool(result.get("ok", false)))
	assert_false(bool(result.get("attacked", false)))
	assert_eq(zombie.hp, hp_before, "declining rolls no attack")
	assert_false(e.has_pending_decision())
	assert_true(String(e.get_log_text()).contains("declines the Improved Trip follow-up attack"))
	assert_false(bool(e.turn_state["move_used"]), "declining does not spend the move action")
	var move := e.move_active_to(Vector2i(2, 4))
	assert_true(bool(move.get("ok", false)), String(move.get("message", "")))
	assert_eq(e.active_character(), fighter, "ordinary play continues with the same character")
	assert_false(bool(e.resolve_improved_trip_attack(false)["ok"]), "a declined follow-up cannot be re-submitted")


func test_a_changed_turn_or_finished_encounter_voids_the_grant() -> void:
	var built := _pending_trip(_fighter())
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var zombie: Character = built[2]
	var hp_before := zombie.hp
	e.turn_ptr = (e.turn_ptr + 1) % e.order.size()
	var voided := e.resolve_improved_trip_attack(true)
	assert_false(bool(voided.get("ok", false)))
	assert_false(e.has_pending_decision(), "a changed turn clears the grant")
	assert_eq(zombie.hp, hp_before, "a voided grant deals no damage")

	var second := _pending_trip(_fighter())
	var ended: Encounter = second[0]
	var ended_zombie: Character = second[2]
	var ended_hp := ended_zombie.hp
	ended.finish("victory")
	assert_false(ended.has_pending_decision(), "encounter termination clears the grant")
	assert_false(bool(ended.resolve_improved_trip_attack(true)["ok"]))
	assert_eq(ended_zombie.hp, ended_hp)
	assert_true(String(ended.get_log_text()).contains("pending combat decision is void"))


func test_committed_power_attack_and_combat_expertise_apply_to_the_follow_up() -> void:
	# Both modifiers are committed before the trip, so the follow-up must inherit
	# the existing attack modifiers rather than reset them.
	var fighter := _with_feat(_char("kaelen"))
	fighter.abilities["str"] = 16
	fighter.feats.append("Power Attack")
	var zombie := _monster("zombie")
	zombie.ac_misc = -30
	zombie.stability_bonus = -60
	var committed := _encounter([fighter], [zombie])
	_force_turn(committed, fighter)
	assert_true(bool(committed.set_active_power_attack(2)["ok"]))
	assert_true(bool(committed.set_active_combat_expertise(2)["ok"]))
	var trip := committed.trip_active(1)
	assert_eq(String(trip.get("pending", "")), "improved_trip_attack", String(trip.get("message", "")))
	assert_true(bool(committed.resolve_improved_trip_attack(true)["ok"]))
	var text := committed.get_log_text()
	assert_true(text.contains("Power Attack -2"), "the committed Power Attack applies to the follow-up")
	assert_true(text.contains("Combat Expertise -2"), "the committed Combat Expertise applies to the follow-up")


func test_the_follow_up_uses_the_prone_targets_melee_ac() -> void:
	var built := _pending_trip(_fighter())
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var zombie: Character = built[2]
	var zombie_index := int(e.entry_for(zombie).get("index", -1))
	var expected_ac := Rules.armor_class(
		zombie,
		{
			"attack_mode": "melee",
			"flat_footed": e.is_flat_footed(zombie_index),
		}
	)
	var standing_ac := zombie.ac()
	assert_lt(expected_ac, standing_ac, "a prone defender has -4 AC against the melee follow-up (PHB Table 8-6)")
	var result := e.resolve_improved_trip_attack(true)
	var follow: Dictionary = result.get("result", {})
	if not bool(follow.get("hit", false)):
		return
	assert_eq(
		int(follow["target_ac"]),
		expected_ac,
		"the follow-up uses the prone melee AC, including any combat-start flat-footedness (PHB p.133)"
	)


## PHB p.96 grants "a melee attack", not the method used for the trip, so an
## unarmed trip may follow up with the weapon already in hand.
func _pending_with(fighter: Character) -> Array:
	for seed_value in range(1, 80):
		var built := _trip_win(fighter, seed_value)
		var e: Encounter = built[0]
		var result := e.trip_active(1)
		if String(result.get("pending", "")) == "improved_trip_attack":
			return [e, fighter, built[1]]
	return []


func test_an_unarmed_trip_can_follow_up_with_the_weapon_in_hand() -> void:
	var fighter := _fighter()
	fighter.equip("weapon", content.items["masterwork_longsword"])
	var weapon_name := String(Dictionary(fighter.equipment["weapon"]).get("name", "Longsword"))
	var built := _pending_with(fighter)
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var resolved := e.resolve_improved_trip_attack(true, "melee")
	assert_true(bool(resolved.get("ok", false)), String(resolved.get("message", "")))
	var follow: Dictionary = resolved.get("result", {})
	assert_true(
		String(follow.get("label", "")).contains(weapon_name),
		"the follow-up uses the held weapon, not an unarmed strike: %s" % follow.get("label", "")
	)


func test_the_follow_up_can_be_an_unarmed_strike_while_armed() -> void:
	var fighter := _fighter()
	fighter.equip("weapon", content.items["masterwork_longsword"])
	var built := _pending_with(fighter)
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var resolved := e.resolve_improved_trip_attack(true, "unarmed")
	assert_true(bool(resolved.get("ok", false)), String(resolved.get("message", "")))
	var follow: Dictionary = resolved.get("result", {})
	assert_eq(String(follow.get("label", "")), "unarmed strike")


func test_a_ranged_weapon_cannot_be_the_follow_up_and_the_decision_survives() -> void:
	var fighter := _fighter()
	fighter.equip(
		"weapon",
		{
			"id": "qa_bow",
			"name": "QA Bow",
			"kind": "weapon",
			"category": "martial",
			"damage": "1d6",
			"damage_type": "piercing",
			"crit_range": 20,
			"crit_mult": 2,
			"range_increment": 60,
			"attack_modes": ["ranged"],
		}
	)
	var built := _pending_with(fighter)
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var refused := e.resolve_improved_trip_attack(true, "ranged")
	assert_false(bool(refused.get("ok", false)))
	assert_true(String(refused.get("message", "")).contains("melee"))
	assert_true(e.has_pending_decision(), "an illegal choice does not consume the decision")
	var fallback := e.resolve_improved_trip_attack(true, "")
	assert_true(bool(fallback.get("ok", false)), String(fallback.get("message", "")))
	assert_eq(String(Dictionary(fallback.get("result", {})).get("label", "")), "unarmed strike")
