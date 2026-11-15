extends GutTest

## Cleave off-turn (PHB p.92): "If you deal a creature enough damage to make it
## drop ... you get an immediate, extra melee attack against another creature
## within reach." The rule is not limited to the attacker's own turn, so a
## party member's opportunity attack that drops a creature qualifies. The active
## combatant never changes while the decision is pending; the interrupted enemy
## route is stored as bounded data and resumed (or closed out) afterwards.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String, hp := 1) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.max_hp = 200
	ch.hp = hp
	ch.ac_misc = -30
	ch.damage_reduction.clear()
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


func _encounter(party: Array, monsters: Array, party_cells: Array, monster_cells: Array) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
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


func _index_of(e: Encounter, ch: Character) -> int:
	return int(e.entry_for(ch).get("index", -1))


func _fighter() -> Character:
	var ch := _char("kaelen")
	ch.feats.clear()
	ch.abilities["str"] = 13
	ch.feats.append("Power Attack")
	ch.feats.append("Cleave")
	ch.equip("weapon", content.items["masterwork_longsword"])
	return ch


## Fighter at (2,3), mover at (3,3) and a second enemy at (1,3). The sentinel at
## (7,6) keeps the encounter alive so a decision can exist after the drop.
func _off_turn_fixture() -> Dictionary:
	var fighter := _fighter()
	var mover := _monster("zombie")
	mover.display_name = "Mover"
	var other := _monster("zombie")
	other.display_name = "Second"
	var sentinel := _monster("zombie", 60)
	sentinel.display_name = "Sentinel"
	var e := _encounter(
		[fighter],
		[mover, other, sentinel],
		[Vector2i(2, 3)],
		[Vector2i(3, 3), Vector2i(1, 3), Vector2i(7, 6)]
	)
	return {"e": e, "fighter": fighter, "mover": mover, "other": other, "sentinel": sentinel}


func _trigger_opportunity(fixture: Dictionary) -> void:
	var e: Encounter = fixture["e"]
	_force_turn(e, fixture["mover"])
	# The mover leaves the fighter's threatened square; the fighter's opportunity
	# attack drops it, which is a resolved melee drop like any other.
	e.move_active_to(Vector2i(5, 3))


func test_opportunity_attack_drop_offers_cleave_without_changing_the_turn() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var fighter: Character = f["fighter"]
	var mover: Character = f["mover"]
	_trigger_opportunity(f)
	assert_true(mover.hp < 0 or mover.has_condition("dead"), "the mover dropped")
	assert_true(e.has_pending_decision(), "the drop offers Cleave")
	assert_eq(String(e.pending_cleave.get("type", "")), "cleave_attack")
	assert_true(bool(e.pending_cleave.get("off_turn", false)), "the trigger is recorded as off turn")
	assert_eq(e.active_character(), mover, "turn ownership does not move to the cleaver")
	assert_true(bool(e.aoo_used.get(_index_of(e, fighter), false)), "the opportunity attack was used")
	assert_false(e.finished, "the encounter continues")
	assert_true(e.off_turn_resume.size() > 0, "the interrupted route is recorded")


func test_off_turn_decline_keeps_the_use_and_resumes_the_interrupted_turn() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var fighter: Character = f["fighter"]
	var mover: Character = f["mover"]
	var other: Character = f["other"]
	_trigger_opportunity(f)
	var hp := other.hp
	assert_true(bool(e.decline_cleave()["ok"]))
	assert_false(e.has_pending_decision())
	assert_eq(other.hp, hp, "declining rolls no attack")
	assert_false(bool(e.cleave_used.has(_index_of(e, fighter))), "declining spends nothing")
	var resumed: Dictionary = e.resume_interrupted()
	assert_true(bool(resumed.get("resumed", false)), str(resumed))
	assert_ne(e.active_character(), mover, "the interrupted turn is closed out, not skipped")
	assert_true(e.off_turn_resume.is_empty(), "the continuation is consumed")


func test_off_turn_cleave_attack_resolves_then_the_turn_continues() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var fighter: Character = f["fighter"]
	var mover: Character = f["mover"]
	var other: Character = f["other"]
	_trigger_opportunity(f)
	var stored := int(e.pending_cleave.get("attack_base", 0))
	var resolved := e.resolve_cleave_attack(_index_of(e, other))
	assert_true(bool(resolved.get("ok", false)), String(resolved.get("message", "")))
	var follow: Dictionary = resolved["result"]
	assert_eq(int(follow["bonus"]), stored, "same attack base")
	assert_true(other.hp < 0 or other.has_condition("dead"), "the extra attack dropped the second enemy")
	assert_true(bool(e.cleave_used.has(_index_of(e, fighter))))
	assert_eq(e.active_character(), mover, "the interrupted turn still owns the turn while pending")
	assert_true(bool(e.resume_interrupted().get("resumed", false)))
	assert_ne(e.active_character(), mover, "the interrupted turn finishes")


func test_duplicate_off_turn_submission_is_refused() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var other: Character = f["other"]
	var target := _index_of(e, other)
	_trigger_opportunity(f)
	assert_true(bool(e.resolve_cleave_attack(target)["ok"]))
	var hp := other.hp
	var again := e.resolve_cleave_attack(target)
	assert_false(bool(again.get("ok", false)), "the decision was already resolved")
	assert_eq(other.hp, hp, "no second roll happens")


func test_off_turn_use_blocks_a_second_cleave_in_the_same_round() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var fighter: Character = f["fighter"]
	var other: Character = f["other"]
	_trigger_opportunity(f)
	e.resolve_cleave_attack(_index_of(e, other))
	e.resume_interrupted()
	assert_true(bool(e.cleave_used.has(_index_of(e, fighter))))
	# The fighter's own turn arrives later in the same round.
	_force_turn(e, fighter)
	e.attack_active(_index_of(e, f["sentinel"]))
	assert_false(e.has_pending_decision(), "the same round offers no second Cleave")


func test_own_turn_use_blocks_a_later_opportunity_cleave() -> void:
	var fighter := _fighter()
	var near := _monster("zombie")
	near.display_name = "Near"
	var other := _monster("zombie")
	other.display_name = "Second"
	var walker := _monster("zombie")
	walker.display_name = "Walker"
	var sentinel := _monster("zombie", 60)
	sentinel.display_name = "Sentinel"
	var e := _encounter(
		[fighter],
		[near, other, walker, sentinel],
		[Vector2i(2, 3)],
		[Vector2i(3, 3), Vector2i(1, 3), Vector2i(2, 4), Vector2i(7, 6)]
	)
	_force_turn(e, fighter)
	assert_eq(String(e.attack_active(_index_of(e, near)).get("pending", "")), "cleave_attack")
	assert_true(bool(e.resolve_cleave_attack(_index_of(e, other))["ok"]))
	assert_true(bool(e.cleave_used.has(_index_of(e, fighter))))
	_force_turn(e, walker)
	e.move_active_to(Vector2i(5, 4))
	assert_false(e.has_pending_decision(), "the once-per-round use already happened")


func test_target_circumstances_are_reevaluated_not_copied() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var other: Character = f["other"]
	other.add_effect("cowering", "Cowering", 1, "condition")
	# The new target has not taken its first turn, so combat-start flat-footedness
	# (PHB p.133) is part of the AC the follow-up must evaluate afresh.
	var expected_ac := Rules.armor_class(
		other,
		{
			"attack_mode": "melee",
			"flat_footed": e.is_flat_footed(_index_of(e, other)),
		}
	)
	_trigger_opportunity(f)
	var stored := int(e.pending_cleave.get("attack_base", 0))
	var resolved := e.resolve_cleave_attack(_index_of(e, other))
	var follow: Dictionary = resolved["result"]
	assert_eq(String(follow["attack_mode"]), "melee", "the melee mode is preserved")
	assert_eq(int(follow["bonus"]), stored + 2, "a cowering target still gives its +2")
	assert_eq(int(follow["target_ac"]), expected_ac, "the new target's AC is evaluated fresh")


func test_helpless_target_adds_its_own_bonus_on_top_of_the_preserved_base() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var other: Character = f["other"]
	other.add_effect("paralyzed", "Paralyzed", 5, "condition")
	_trigger_opportunity(f)
	var stored := int(e.pending_cleave.get("attack_base", 0))
	var resolved := e.resolve_cleave_attack(_index_of(e, other))
	assert_eq(int(resolved["result"]["bonus"]), stored + 4, "helpless +4 applies to the new target")


func test_prone_target_keeps_the_base_but_uses_prone_ac() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var other: Character = f["other"]
	other.set_prone(true)
	var expected_ac := Rules.armor_class(
		other,
		{
			"attack_mode": "melee",
			"flat_footed": e.is_flat_footed(_index_of(e, other)),
		}
	)
	_trigger_opportunity(f)
	var stored := int(e.pending_cleave.get("attack_base", 0))
	var resolved := e.resolve_cleave_attack(_index_of(e, other))
	var follow: Dictionary = resolved["result"]
	assert_eq(int(follow["bonus"]), stored)
	assert_eq(int(follow["target_ac"]), expected_ac)


func test_only_enemies_within_reach_are_offered() -> void:
	var fighter := _fighter()
	var mover := _monster("zombie")
	mover.display_name = "Mover"
	var far := _monster("zombie")
	far.display_name = "Far"
	var e := _encounter(
		[fighter],
		[mover, far],
		[Vector2i(2, 3)],
		[Vector2i(3, 3), Vector2i(7, 6)]
	)
	_force_turn(e, mover)
	e.move_active_to(Vector2i(5, 3))
	assert_false(e.has_pending_decision(), "nothing in reach means no decision")
	assert_true(e.off_turn_resume.is_empty(), "no continuation is stored without a decision")


func test_encounter_end_voids_the_off_turn_decision_and_the_continuation() -> void:
	var f := _off_turn_fixture()
	var e: Encounter = f["e"]
	var mover: Character = f["mover"]
	var other: Character = f["other"]
	var sentinel: Character = f["sentinel"]
	_trigger_opportunity(f)
	assert_true(e.has_pending_decision())
	# Remove every other enemy before the granted attack lands, so the extra
	# attack itself ends the encounter.
	mover.take_damage(999)
	sentinel.take_damage(999)
	assert_true(bool(e.resolve_cleave_attack(_index_of(e, other))["ok"]))
	assert_true(e.finished, "the last enemies are down")
	assert_eq(e.outcome, "victory")
	assert_false(e.has_pending_decision())
	assert_true(e.off_turn_resume.is_empty(), "a finished encounter has nothing to resume")
	assert_false(bool(e.resume_interrupted().get("resumed", false)))
