extends GutTest

## Aid Another (PHB p.154): a standard action; the helper must be in position to
## make a melee attack on an opponent engaging a friend; an attack roll against
## AC 10; on success the friend gains +2 on the next attack roll against that
## opponent or +2 AC against that opponent's next attack, until the beginning of
## the helper's next turn; similar bonuses stack.
##
## Project adaptations (docs/AID_ANOTHER_PLAN.md): the check provokes no
## opportunity attack, needs a melee weapon, and monsters never aid. Tests read
## the modifier through the roll's audit fields and the log, never through a
## hit or a miss.

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
			"##########",
			"#........#",
			"#........#",
			"#........#",
			"#........#",
			"#........#",
			"##########",
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


func _set_cells(e: Encounter, cells: Dictionary) -> void:
	for index in cells.keys():
		e.combatants[int(index)]["cell"] = cells[index]


## One aid attempt. With several eligible allies the friend stage is resolved
## explicitly; with one it rolls immediately.
func _aid(e: Encounter, foe_index: int, friend_index: int = -1) -> Dictionary:
	var result := e.aid_active(foe_index)
	if bool(result.get("ok", false)) and String(result.get("pending", "")) == "aid_friend":
		result = e.resolve_aid_friend(friend_index)
	return result


## The first seed whose aid check succeeds, so the success path is exercised
## without pinning the dice.
func _successful_aid(party: Array = [], monster: Character = null) -> Array:
	for seed_value in range(1, 300):
		var kaelen := _char("kaelen")
		var sera := _char("sera")
		var aldric := _char("aldric") if party.size() > 2 else null
		var zombie: Character = monster if monster != null else _monster("zombie")
		var part: Array = [kaelen, sera] if aldric == null else [kaelen, sera, aldric]
		var cells: Array = [Vector2i(2, 3), Vector2i(3, 4)]
		if aldric != null:
			cells.append(Vector2i(4, 3))
		var e := _encounter(part, [zombie], cells, [Vector2i(3, 3)], seed_value)
		_force_turn(e, kaelen)
		var result := _aid(e, part.size(), 1)
		if bool(result.get("ok", false)) and bool(result.get("success", false)):
			return [e, result, kaelen, sera, zombie]
	return []


func test_a_helper_with_no_eligible_ally_is_refused_and_spends_nothing() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie], [Vector2i(2, 3)], [Vector2i(3, 3)])
	_force_turn(e, kaelen)
	var result := e.aid_active(1)
	assert_false(bool(result.get("ok", false)), "the helper cannot aid himself")
	assert_false(bool(e.turn_state["standard_used"]), "a refused declaration spends nothing")
	assert_false(e.has_pending_decision())


func test_an_out_of_reach_or_unengaged_foe_is_refused() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var far := _monster("zombie")
	var e := _encounter(
		[kaelen, sera],
		[far],
		[Vector2i(2, 3), Vector2i(3, 4)],
		[Vector2i(8, 5)]
	)
	_force_turn(e, kaelen)
	assert_false(bool(e.aid_active(2).get("ok", false)), "the foe is out of the helper's reach")

	var unengaged := _monster("zombie")
	var second_helper := _char("kaelen")
	var second := _encounter(
		[second_helper, _char("sera")],
		[unengaged],
		[Vector2i(2, 3), Vector2i(8, 5)],
		[Vector2i(3, 3)]
	)
	_force_turn(second, second_helper)
	assert_false(
		bool(second.aid_active(2).get("ok", false)),
		"no ally is engaged with the foe"
	)
	assert_false(bool(second.turn_state["standard_used"]))


func test_a_flat_footed_foe_is_eligible_but_a_helpless_one_is_not() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen, sera], [zombie], [Vector2i(2, 3), Vector2i(3, 4)], [Vector2i(3, 3)])
	_force_turn(e, kaelen)
	assert_true(e.is_flat_footed(2), "the foe has not acted yet")
	var attempt := e.aid_active(2)
	assert_true(
		bool(attempt.get("ok", false)) or String(attempt.get("pending", "")) == "aid_friend",
		String(attempt.get("message", "a flat-footed foe can be aided against"))
	)

	var paralysed := _monster("zombie")
	var second := _encounter(
		[kaelen, sera],
		[paralysed],
		[Vector2i(2, 3), Vector2i(3, 4)],
		[Vector2i(3, 3)]
	)
	paralysed.add_effect("paralyzed", "Paralyzed", 2)
	_force_turn(second, kaelen)
	assert_false(
		bool(second.aid_active(2).get("ok", false)),
		"a helpless foe cannot be distracted from attacking"
	)

	var cowering := _monster("zombie")
	var third := _encounter(
		[kaelen, sera],
		[cowering],
		[Vector2i(2, 3), Vector2i(3, 4)],
		[Vector2i(3, 3)]
	)
	cowering.add_effect("cowering", "Cowering", 2)
	_force_turn(third, kaelen)
	assert_false(bool(third.aid_active(2).get("ok", false)), "a cowering foe is not engaging")


func test_a_successful_check_grants_plus_two_on_the_next_attack() -> void:
	var built := _successful_aid()
	assert_false(built.is_empty(), "a seed should produce a successful aid")
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var sera: Character = built[3]
	assert_eq(String(e.pending_aid.get("stage", "")), "bonus", "the check pauses for the bonus")
	var resolved := e.resolve_aid_choice("attack")
	assert_true(bool(resolved.get("ok", false)), String(resolved.get("message", "")))
	assert_false(e.has_pending_decision())
	assert_true(bool(e.turn_state["standard_used"]), "the check spends the standard action")
	assert_eq((e.aid_attack.get(1, []) as Array).size(), 1, "one grant is stored for the rogue")

	_force_turn(e, sera)
	var attack := e.attack_active(2)
	assert_true(bool(attack.get("ok", false)), String(attack.get("message", "")))
	var rolled: Dictionary = attack["result"]
	assert_eq(int(rolled.get("aid_bonus", 0)), 2, "the attack roll carries exactly +2")
	assert_true(e.get_log_text().contains("Aid Another"), "the bonus is named in the log")
	assert_true(bool(e.aid_attack.get(1, []).is_empty()), "the roll consumed the grant")


func test_the_attack_bonus_is_bound_to_one_foe_and_one_roll() -> void:
	var built := _successful_aid()
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var sera: Character = built[3]
	assert_true(bool(e.resolve_aid_choice("attack")["ok"]))
	# Two adjacent foes: index 2 is the aided one, index 3 is a bystander.
	var bystander := _monster("zombie")
	e.combatants.append({"char": bystander, "team": Encounter.TEAM_ENEMY, "index": 3, "cell": Vector2i(4, 2)})
	e.combatants[3]["cell"] = Vector2i(4, 2)
	_force_turn(e, sera)
	var wrong := e.attack_active(3)
	assert_eq(int((wrong.get("result", {}) as Dictionary).get("aid_bonus", 0)), 0, "a different foe gets nothing")
	assert_eq((e.aid_attack.get(1, []) as Array).size(), 1, "the grant survives the wrong target")
	_force_turn(e, sera)
	var right := e.attack_active(2)
	assert_eq(int((right.get("result", {}) as Dictionary).get("aid_bonus", 0)), 2)
	_force_turn(e, sera)
	var again := e.attack_active(2)
	assert_eq(int((again.get("result", {}) as Dictionary).get("aid_bonus", 0)), 0, "only the next roll gets it")


func test_the_defense_bonus_covers_only_the_foes_next_attack() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen, sera], [zombie], [Vector2i(2, 3), Vector2i(3, 4)], [Vector2i(3, 3)])
	_force_turn(e, kaelen)
	var granted := false
	for seed_value in range(1, 300):
		e.rng.seed = seed_value
		e.turn_state["standard_used"] = false
		var attempt := _aid(e, 2, 1)
		if bool(attempt.get("success", false)):
			e.resolve_aid_choice("defense")
			granted = true
			break
		e.pending_aid.clear()
	assert_true(granted, "a seed should produce a successful aid")
	var first := e._monster_single_attack(e.combatants[2], e.combatants[1])
	assert_eq(int(first.get("aid_ac_bonus", 0)), 2, "the foe's next attack sees +2 AC")
	var second := e._monster_single_attack(e.combatants[2], e.combatants[1])
	assert_eq(int(second.get("aid_ac_bonus", 0)), 0, "the following attack does not")


func test_the_bonus_expires_at_the_start_of_the_helpers_next_turn() -> void:
	var built := _successful_aid()
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var kaelen: Character = built[2]
	assert_true(bool(e.resolve_aid_choice("attack")["ok"]))
	_force_turn(e, kaelen)
	assert_true((e.aid_attack.get(1, []) as Array).is_empty(), "the start of the helper's turn expires it")
	assert_true(e.get_log_text().contains("expires"), "the expiry is logged")


func test_two_helpers_stack_to_four() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var aldric := _char("aldric")
	var zombie := _monster("zombie")
	var e := _encounter(
		[kaelen, sera, aldric],
		[zombie],
		[Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 3)],
		[Vector2i(3, 3)]
	)
	var first := false
	var second := false
	for seed_value in range(1, 300):
		e.rng.seed = seed_value
		_force_turn(e, kaelen)
		var attempt := _aid(e, 3, 1)
		if bool(attempt.get("success", false)):
			e.resolve_aid_choice("attack")
			first = true
			break
		e.pending_aid.clear()
	for seed_value in range(1, 300):
		e.rng.seed = seed_value
		_force_turn(e, aldric)
		var attempt := _aid(e, 3, 1)
		if bool(attempt.get("success", false)):
			e.resolve_aid_choice("attack")
			second = true
			break
		e.pending_aid.clear()
	assert_true(first and second, "two seeded successes are needed")
	_force_turn(e, sera)
	var attack := e.attack_active(3)
	assert_eq(int((attack.get("result", {}) as Dictionary).get("aid_bonus", 0)), 4, "similar bonuses stack")


func test_a_failed_check_spends_the_standard_action_and_grants_nothing() -> void:
	var failed := {}
	for seed_value in range(1, 300):
		var kaelen := _char("kaelen")
		var sera := _char("sera")
		var zombie := _monster("zombie")
		var e := _encounter(
			[kaelen, sera],
			[zombie],
			[Vector2i(2, 3), Vector2i(3, 4)],
			[Vector2i(3, 3)],
			seed_value
		)
		_force_turn(e, kaelen)
		var attempt := _aid(e, 2, 1)
		if bool(attempt.get("ok", false)) and not bool(attempt.get("success", true)):
			failed = {"e": e, "result": attempt}
			break
	assert_false(failed.is_empty(), "a seed should produce a failed check")
	if failed.is_empty():
		return
	var e: Encounter = failed["e"]
	assert_true(bool(e.turn_state["standard_used"]), "the attempt spends the standard action")
	assert_false(e.has_pending_decision(), "a failure opens no choice")
	assert_true(e.aid_attack.is_empty() and e.aid_ac.is_empty(), "nothing is granted")
	assert_true(e.get_log_text().contains("fails"), "the failure is logged")


func test_a_grappled_or_pinned_helper_is_refused() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen, sera], [zombie], [Vector2i(2, 3), Vector2i(3, 4)], [Vector2i(3, 3)])
	e.grapples.append({"holder": 2, "held": 0, "pinned": false})
	_force_turn(e, kaelen)
	assert_false(bool(e.aid_active(2).get("ok", false)), "a grappled helper cannot assist")
	assert_false(bool(e.turn_state["standard_used"]))

	var pinned := _encounter(
		[_char("kaelen"), _char("sera")],
		[_monster("zombie")],
		[Vector2i(2, 3), Vector2i(3, 4)],
		[Vector2i(3, 3)]
	)
	pinned.grapples.append({"holder": 2, "held": 0, "pinned": true})
	_force_turn(pinned, pinned.combatants[0]["char"])
	assert_false(bool(pinned.aid_active(2).get("ok", false)), "a pinned helper cannot assist")


func test_a_helpless_ally_receives_only_the_defense_bonus() -> void:
	var built := _successful_aid()
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	var sera: Character = built[3]
	# Re-grant with a helpless ally: the attack half would expire unused.
	e.aid_attack.clear()
	e.aid_ac.clear()
	e.pending_aid.clear()
	e.turn_state["standard_used"] = false
	sera.add_effect("paralyzed", "Paralyzed", 2)
	var granted := false
	for seed_value in range(1, 300):
		e.rng.seed = seed_value
		var attempt := _aid(e, 2, 1)
		if bool(attempt.get("success", false)):
			granted = true
			break
		e.pending_aid.clear()
	assert_true(granted, "a seed should produce a successful aid")
	assert_false(e.has_pending_decision(), "no attack/AC choice is offered to a helpless ally")
	assert_eq((e.aid_ac.get(1, []) as Array).size(), 1, "the +2 AC is granted")
	assert_true(e.aid_attack.is_empty(), "the +2 attack is not")
	assert_true(e.get_log_text().contains("+2 AC"), "the log names the granted half")


func test_death_and_finish_clean_up_grants() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var aldric := _char("aldric")
	var zombie := _monster("zombie")
	var survivor := _monster("zombie")
	var e := _encounter(
		[kaelen, sera, aldric],
		[zombie, survivor],
		[Vector2i(2, 3), Vector2i(3, 4), Vector2i(2, 5)],
		[Vector2i(3, 3), Vector2i(8, 5)]
	)
	_force_turn(e, kaelen)
	var granted := false
	for seed_value in range(1, 300):
		e.rng.seed = seed_value
		e.turn_state["standard_used"] = false
		var attempt := _aid(e, 3, 1)
		if bool(attempt.get("success", false)):
			e.resolve_aid_choice("attack")
			granted = true
			break
		e.pending_aid.clear()
	assert_true(granted)
	sera.take_damage(999)
	e._check_end()
	assert_true((e.aid_attack.get(1, []) as Array).is_empty(), "a dead ally's grants are pruned")

	e.aid_ac[2] = [{"foe": 3, "amount": 2, "helper": 0}]
	e.pending_aid = {"stage": "bonus", "helper": 0, "friend": 2, "foe": 3}
	e.finish("victory")
	assert_true(e.aid_attack.is_empty() and e.aid_ac.is_empty(), "finish clears the grants")
	assert_false(e.has_pending_decision(), "finish voids the open choice")


func test_turning_does_not_clear_a_grant() -> void:
	var kaelen := _char("kaelen")
	var aldric := _char("aldric")
	var ghoul := _monster("ghoul")
	ghoul.level = 20
	ghoul.max_hp = 200
	ghoul.hp = 200
	var e := _encounter([kaelen, aldric], [ghoul], [Vector2i(2, 3), Vector2i(3, 4)], [Vector2i(3, 3)])
	_force_turn(e, kaelen)
	var granted := false
	for seed_value in range(1, 300):
		e.rng.seed = seed_value
		e.turn_state["standard_used"] = false
		var attempt := _aid(e, 2, 1)
		if bool(attempt.get("success", false)):
			e.resolve_aid_choice("defense")
			granted = true
			break
		e.pending_aid.clear()
	assert_true(granted)
	_force_turn(e, aldric)
	e.turn_undead()
	assert_false(e.finished, "a 20-HD ghoul resists a 3rd-level turning")
	assert_eq((e.aid_ac.get(1, []) as Array).size(), 1, "turning does not clear the grant")


func test_an_open_choice_blocks_other_actions_and_is_discarded_at_turn_start() -> void:
	var built := _successful_aid()
	assert_false(built.is_empty())
	if built.is_empty():
		return
	var e: Encounter = built[0]
	assert_true(e.has_pending_decision())
	assert_false(bool(e.attack_active(2).get("ok", false)), "the pending choice blocks attacks")
	assert_false(bool(e.move_active_to(Vector2i(2, 4))["ok"]), "the pending choice blocks movement")
	var next_index := int((e.turn_ptr + 1) % e.order.size())
	e.turn_ptr = next_index
	e._begin_turn(e.combatants[e.order[next_index]])
	assert_false(e.has_pending_decision(), "an unresolved choice is discarded at the next turn")
	assert_true(e.get_log_text().contains("discarded"))


func test_a_helper_must_have_a_melee_weapon_in_hand() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen, sera], [zombie], [Vector2i(2, 3), Vector2i(3, 4)], [Vector2i(3, 3)])
	kaelen.equipment.erase("weapon")
	_force_turn(e, kaelen)
	assert_false(bool(e.aid_active(2).get("ok", false)), "the check needs a weapon to interfere with")
	assert_false(bool(e.turn_state["standard_used"]))
