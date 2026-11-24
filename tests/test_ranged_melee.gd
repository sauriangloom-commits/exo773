extends GutTest

## Ranged attacks inside a melee (PHB p. 140) and the separate rule that a
## ranged attack provokes while threatened (PHB p. 135).
##
## p. 140: "If you shoot or throw a ranged weapon at a target engaged in melee
## with a friendly character, you take a -4 penalty on your attack roll because
## you have to aim carefully to avoid hitting your friend. Two characters are
## engaged in melee if they are enemies of each other and either threatens the
## other. (An unconscious or otherwise immobilized character is not considered
## engaged unless he is actually being attacked.) If your target ... is at least
## 10 feet away from the nearest friendly character, you can avoid the -4
## penalty... Precise Shot: If you have the Precise Shot feat, you don't take
## this penalty."
##
## The two conditions are independent: (A) is about the target's neighbours and
## changes the attack roll; (B) is about the attacker's neighbours and produces
## an opportunity attack. Neither implies the other, so every test below fixes
## one of them and checks that the other did not move.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func after_each() -> void:
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


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


## Every encounter uses the same seed so two runs that differ only in a
## neighbour's position roll the same d20 and their bonuses are comparable.
func _encounter_at(
	party: Array, party_cells: Array, monsters: Array, monster_cells: Array
) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	# These tests measure range, engagement and the into-melee penalty, so the
	# crossbow starts loaded; the reload action is covered by
	# tests/test_weapon_access.gd.
	for entry in e.combatants:
		var ch: Character = entry["char"]
		var weapon: Dictionary = ch.equipment.get("weapon", {})
		if String(weapon.get("reload", "")) != "":
			e.loaded_weapons[String(ch.id)] = String(weapon.get("id", ""))
	return e


## Sera carries a crossbow but has her short sword equipped, so a ranged test
## has to equip the crossbow explicitly. She is not proficient with this one,
## which is a constant -4 on both sides of every comparison here.
func _equip_crossbow(ch: Character) -> void:
	ch.equipment["weapon"] = content.items["light_crossbow"].duplicate(true)


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _index_of(e: Encounter, ch: Character) -> int:
	for entry in e.combatants:
		if entry["char"] == ch:
			return int(entry["index"])
	fail_test("character is not a combatant")
	return -1


func _logged(lines: Array, needle: String) -> bool:
	for line in lines:
		if String(line).contains(needle):
			return true
	return false


func _count(lines: Array, needle: String) -> int:
	var total := 0
	for line in lines:
		if String(line).contains(needle):
			total += 1
	return total


func _caster() -> Character:
	for id in content.character_ids():
		var data := content.get_character(id)
		var prepared: Dictionary = data.get("spells", {}).get("prepared", {})
		for level in prepared.keys():
			if Array(prepared[level]).has("scorching_ray"):
				return _char(id)
	return null


# ---------------------------------------------------------------------------
# (A) Shooting into a melee: the target is engaged with a friendly character.


func test_shooting_into_melee_takes_the_minus_4_penalty() -> void:
	var sera := _char("sera")
	_equip_crossbow(sera)
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var engaged := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(engaged, sera)
	var shot := engaged.attack_active(2)
	assert_true(bool(shot.get("ok", false)), String(shot.get("message", "")))
	assert_eq(
		int(shot["result"]["into_melee_penalty"]),
		-4,
		"a crossbow shot at a target engaged with an ally takes -4"
	)
	assert_true(
		_logged(engaged.log_lines, "shooting into melee -4"),
		"the penalty states its reason in the combat log"
	)
	assert_true(
		_logged(engaged.log_lines, "is engaged with Kaelen Dorn"),
		"the log names the friendly character the shot has to avoid"
	)
	# Same board, same seed, same shot, but no ally near the target: the only
	# difference in the attack bonus must be the penalty.
	var alone := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(6, 4)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(alone, sera)
	var free_shot := alone.attack_active(2)
	assert_eq(int(free_shot["result"]["into_melee_penalty"]), 0, "an unengaged target is a normal shot")
	assert_eq(int(shot["result"]["bonus"]), int(free_shot["result"]["bonus"]) - 4, "the penalty is exactly -4 on the roll")
	assert_false(
		_logged(alone.log_lines, "shooting into melee"),
		"no penalty line is emitted when the target is not engaged"
	)


## Regression: a paralyzed ally is an immobilized character and is not engaged
## for the firing-into-melee penalty (PHB p.140). The fixture keeps every other
## term fixed: Sera shoots 25 ft horizontally with a loaded crossbow, clear line
## of sight, no cover, no suppression feat and no other attack-penalty stance.
## The actual player path is Game.combat_attack -> Encounter.attack_active; the
## assertions read the applied modifier from the resolved result, not a hit roll.
func _player_into_melee_shot(
	first_ally_paralyzed: bool, include_first_ally: bool, include_second_ally: bool
) -> Dictionary:
	var sera := _char("sera")
	_equip_crossbow(sera)
	var first := _char("kaelen")
	var second := _char("aldric")
	if first_ally_paralyzed:
		first.add_effect("paralyzed", "Paralyzed", 2)
	var party: Array = [sera, first]
	var party_cells: Array = [
		Vector2i(1, 1), Vector2i(7, 1) if include_first_ally else Vector2i(7, 5)
	]
	if include_second_ally:
		party.append(second)
		party_cells.append(Vector2i(6, 2))
	var ghoul := _monster("ghoul")
	# Keep the target alive and state changes attributable: the check is about
	# the attack modifier, not whether this particular seeded d20 hits.
	ghoul.max_hp = 200
	ghoul.hp = 200
	var target_cell := Vector2i(6, 1)
	var e := _encounter_at(party, party_cells, [ghoul], [target_cell])
	_force_turn(e, sera)
	assert_true(e.is_weapon_loaded(sera), "fixture: the crossbow starts loaded")
	assert_true(
		e.map.has_line_of_sight(Vector2i(1, 1), target_cell), "fixture: line of sight is clear"
	)
	assert_false(Feats.has_active(sera, "precise_shot"), "fixture: no Precise Shot")
	assert_false(
		sera.has_effect("fighting_defensively"), "fixture: no attack-penalty stance"
	)
	Game.party = party
	Game.encounter = e
	Game.mode = "combat"
	Game.last_ui_message = ""
	var shot := Game.combat_attack(_index_of(e, ghoul))
	assert_true(bool(shot.get("ok", false)), String(shot.get("message", "")))
	return {"encounter": e, "shot": shot, "target": ghoul, "shooter": sera}


func test_paralyzed_ally_is_not_engaged_for_firing_into_melee() -> void:
	var conscious := _player_into_melee_shot(false, true, false)
	var paralyzed := _player_into_melee_shot(true, true, false)
	var none := _player_into_melee_shot(false, false, false)
	var with_second := _player_into_melee_shot(true, true, true)
	var conscious_result: Dictionary = conscious["shot"]["result"]
	var paralyzed_result: Dictionary = paralyzed["shot"]["result"]
	var none_result: Dictionary = none["shot"]["result"]
	var second_result: Dictionary = with_second["shot"]["result"]
	var base_bonus := int(none_result["bonus"])
	assert_eq(int(conscious_result["into_melee_penalty"]), -4, "a conscious adjacent ally is engaged")
	assert_eq(
		int(paralyzed_result["into_melee_penalty"]),
		0,
		"a paralyzed adjacent ally is immobilized and is not engaged",
	)
	assert_eq(int(none_result["into_melee_penalty"]), 0, "no adjacent ally means no penalty")
	assert_eq(
		int(second_result["into_melee_penalty"]),
		-4,
		"a second conscious ally still supplies the penalty when the first is paralyzed",
	)
	assert_eq(int(conscious_result["bonus"]), base_bonus - 4, "the conscious ally reaches the roll")
	assert_eq(
		int(paralyzed_result["bonus"]), base_bonus, "the paralyzed ally must not reach the roll"
	)
	assert_eq(
		int(second_result["bonus"]), base_bonus - 4, "the remaining conscious ally reaches the roll"
	)
	assert_true(
		_logged(conscious["encounter"].log_lines, "shooting into melee -4"),
		"the conscious case logs the applied penalty",
	)
	assert_false(
		_logged(paralyzed["encounter"].log_lines, "shooting into melee"),
		"the paralyzed case must not log an into-melee penalty",
	)
	assert_true(
		_logged(with_second["encounter"].log_lines, "shooting into melee -4"),
		"the second conscious ally still logs the applied penalty",
	)
	for label in ["conscious ally", "paralyzed ally", "no ally", "second conscious ally"]:
		var case: Dictionary = {
			"conscious ally": conscious,
			"paralyzed ally": paralyzed,
			"no ally": none,
			"second conscious ally": with_second,
		}[label]
		var result: Dictionary = case["shot"]["result"]
		var e: Encounter = case["encounter"]
		var target: Character = case["target"]
		var shooter: Character = case["shooter"]
		assert_eq(int(result["distance_ft"]), 25, "%s: range term is fixed" % label)
		assert_eq(int(result["cover"]), 0, "%s: cover term is fixed at zero" % label)
		assert_true(bool(result["ranged"]), "%s: the ordinary path resolved a ranged attack" % label)
		assert_false(e.is_weapon_loaded(shooter), "%s: firing spends the loaded shot" % label)
		assert_true(
			bool(e.turn_state["standard_used"]), "%s: the attack spends the standard action" % label
		)
		assert_false(target.has_condition("dead"), "%s: the target remains alive" % label)
		var expected_hp := 200 - (int(result["damage_applied"]) if bool(result["hit"]) else 0)
		assert_eq(target.hp, expected_hp, "%s: target HP reflects the resolved hit" % label)


func test_ten_feet_from_the_nearest_friendly_avoids_the_penalty() -> void:
	# A reach weapon threatens at 10 ft., so the target is engaged, yet p. 140
	# lets the shot avoid the penalty once the target is 10 ft. from the nearest
	# friendly character. Reach is set on the ally rather than authored, because
	# the slice has no reach weapon for the fighter.
	var sera := _char("sera")
	_equip_crossbow(sera)
	var kaelen := _char("kaelen")
	kaelen.reach_ft = 10
	var ghoul := _monster("ghoul")
	var reach_case := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(2, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(reach_case, sera)
	assert_eq(
		reach_case.map.distance_ft(Vector2i(2, 1), Vector2i(4, 1)),
		10,
		"the ally is exactly 10 ft. from the target"
	)
	var shot := reach_case.attack_active(2)
	assert_eq(int(shot["result"]["into_melee_penalty"]), 0, "10 ft. from the nearest ally avoids the penalty")
	# Control: the same reach at 5 ft. still takes the penalty.
	var close_case := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(close_case, sera)
	var close_shot := close_case.attack_active(2)
	assert_eq(int(close_shot["result"]["into_melee_penalty"]), -4, "5 ft. from the ally is inside the melee")


func test_thrown_weapons_take_the_penalty_as_well() -> void:
	var sera := _char("sera")
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	sera.equipment["weapon"] = content.items["dagger"].duplicate(true)
	_force_turn(e, sera)
	var throw := e.attack_active(2, "thrown")
	assert_true(bool(throw.get("ok", false)), String(throw.get("message", "")))
	assert_eq(String(throw["result"]["attack_mode"]), "thrown", "the attack is a thrown attack")
	assert_eq(int(throw["result"]["into_melee_penalty"]), -4, "p. 140 covers throwing as well as shooting")


func test_melee_attacks_are_not_affected_by_a_third_creature() -> void:
	var sera := _char("sera")
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, kaelen)
	var swing := e.attack_active(2)
	assert_true(bool(swing.get("ok", false)), String(swing.get("message", "")))
	assert_eq(int(swing["result"]["into_melee_penalty"]), 0, "a melee attack has no into-melee penalty")
	assert_false(_logged(e.log_lines, "shooting into melee"), "no ranged penalty line appears")
	assert_eq(int(swing["result"]["cover"]), 0, "melee attacks are not subject to soft cover")
	assert_false(_logged(e.log_lines, "PHB p.151"), "no cover line appears either")


# ---------------------------------------------------------------------------
# Precise Shot (PHB p. 98) removes the into-melee penalty and nothing else.
# Soft cover from a creature is a different rule and survives the feat.


func test_precise_shot_removes_the_penalty_but_not_cover() -> void:
	var sera := _char("sera")
	_equip_crossbow(sera)
	sera.feats = ["Point Blank Shot", "Precise Shot"]
	assert_true(Feats.has_active(sera, "precise_shot"), "the fixture meets the prerequisite")
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	# Kaelen stands beside the ghoul, so the fixture has both conditions at once:
	# the target is engaged (the -4) and a creature screens a corner (cover).
	var e := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, sera)
	var shot := e.attack_active(2)
	assert_eq(int(shot["result"]["into_melee_penalty"]), 0, "Precise Shot removes the -4")
	assert_false(_logged(e.log_lines, "shooting into melee"), "the penalty rule emits nothing")
	# Correction: the feat is not a cover exemption. Improved Precise Shot ignores
	# cover, but it needs BAB +11 (PHB p. 96) and is not in this slice.
	assert_eq(int(shot["result"]["cover"]), 4, "Precise Shot does not remove cover")
	assert_eq(
		int(shot["result"]["target_ac"]),
		CombatScreen.effective_ac(ghoul, e.is_flat_footed(_index_of(e, ghoul)), 4),
		"the shot resolves against the covered AC even with the feat",
	)
	assert_true(_logged(e.log_lines, "PHB p.151"), "the cover rule is cited separately")


func test_precise_shot_without_point_blank_shot_does_nothing() -> void:
	var sera := _char("sera")
	_equip_crossbow(sera)
	sera.feats = ["Precise Shot"]
	assert_false(Feats.has_active(sera, "precise_shot"), "an unmet prerequisite disables the feat")
	assert_false(bool(Feats.prereqs(sera, "precise_shot")["ok"]), "the requirement is reported")
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, sera)
	var shot := e.attack_active(2)
	assert_eq(int(shot["result"]["into_melee_penalty"]), -4, "without the feat the penalty still applies")


# ---------------------------------------------------------------------------
# (B) Making a ranged attack while threatened provokes, and is separate.


func test_ranged_attack_while_threatened_provokes_without_into_melee_penalty() -> void:
	var sera := _char("sera")
	_equip_crossbow(sera)
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var zombie := _monster("zombie")
	# The zombie stands next to Sera (she is threatened); Kaelen is far from the
	# ghoul (the ghoul is not engaged). Only (B) applies.
	var e := _encounter_at(
		[sera, kaelen],
		[Vector2i(1, 4), Vector2i(6, 4)],
		[ghoul, zombie],
		[Vector2i(4, 1), Vector2i(2, 4)]
	)
	_force_turn(e, zombie)
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var shot := e.attack_active(2)
	assert_true(bool(shot.get("ok", false)), String(shot.get("message", "")))
	assert_eq(int(shot["result"]["into_melee_penalty"]), 0, "the target is not engaged, so (A) does not apply")
	assert_true(
		_logged(e.log_lines.slice(before), "makes a ranged attack while threatened and provokes"),
		"the provocation is stated as its own rule"
	)
	assert_true(bool(e.aoo_used.get(_index_of(e, zombie), false)), "the threatening zombie reacted")
	assert_false(_logged(e.log_lines, "shooting into melee"), "the two rules are not conflated")


func test_shooting_into_melee_while_unthreatened_does_not_provoke() -> void:
	var sera := _char("sera")
	_equip_crossbow(sera)
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var shot := e.attack_active(2)
	assert_eq(int(shot["result"]["into_melee_penalty"]), -4, "the shot is into a melee")
	assert_eq(_count(e.log_lines.slice(before), "Attack of opportunity by"), 0, "nobody threatens Sera, so no reaction")
	assert_false(_logged(e.log_lines, "while threatened"), "no provocation is claimed")


# ---------------------------------------------------------------------------
# Ranged spells: Complete Arcane p. 85 makes an attack-roll spell a weapon, and
# p. 73 gives Precise Shot the same exemption for ranged spells.


func test_ranged_touch_spell_takes_the_penalty() -> void:
	var caster := _caster()
	assert_not_null(caster, "a prepared caster with scorching ray exists")
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[caster, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, caster)
	var cast := e.cast_active_spell("scorching_ray", 2)
	assert_true(bool(cast.get("ok", false)), String(cast.get("message", "")))
	assert_true(
		_logged(e.log_lines, "shooting into melee -4"),
		"the ray is fired into a melee and takes the same -4"
	)
	assert_true(
		_logged(e.log_lines, "Complete Arcane p.73"),
		"the log cites the rule that extends the penalty to ranged spells"
	)


func test_ray_into_a_clear_target_is_not_penalised() -> void:
	var caster := _caster()
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[caster, kaelen], [Vector2i(1, 4), Vector2i(6, 4)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, caster)
	var cast := e.cast_active_spell("scorching_ray", 2)
	assert_true(bool(cast.get("ok", false)), String(cast.get("message", "")))
	assert_true(_logged(e.log_lines, "casts Scorching Ray"), "the ray was actually fired")
	assert_false(_logged(e.log_lines, "shooting into melee"), "an unengaged target is a normal ray")


func test_casting_a_ray_while_threatened_provokes_only_once() -> void:
	# The casting rule and the ranged-attack rule must not both fire for one
	# action: Complete Arcane treats the spell as one action that is both cast
	# and fired, so the ray adds no second opportunity attack.
	var caster := _caster()
	var ghoul := _monster("ghoul")
	var zombie := _monster("zombie")
	var e := _encounter_at(
		[caster], [Vector2i(1, 4)], [ghoul, zombie], [Vector2i(4, 1), Vector2i(2, 4)]
	)
	_force_turn(e, zombie)
	_force_turn(e, caster)
	var before := e.log_lines.size()
	e.cast_active_spell("scorching_ray", 1)
	var fresh := e.log_lines.slice(before)
	assert_eq(_count(fresh, "Attack of opportunity by"), 1, "exactly one opportunity attack for the spell")
	assert_true(
		_logged(fresh, "casts Scorching Ray while threatened and provokes"),
		"the provocation comes from casting, not from a second ranged-attack rule"
	)


func test_magic_missile_has_no_attack_roll_so_no_penalty() -> void:
	var caster := _caster()
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[caster, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, caster)
	var cast := e.cast_active_spell("magic_missile", 2)
	assert_true(bool(cast.get("ok", false)), String(cast.get("message", "")))
	assert_false(_logged(e.log_lines, "shooting into melee"), "a spell with no attack roll cannot be shot into a melee")


# ---------------------------------------------------------------------------
# Soft cover from creatures (PHB p. 151): +4 AC on ranged attacks when a
# creature's square lies on the line. The geometry itself is covered by
# tests/test_cover_geometry.gd; these tests check that the encounter reads it,
# that it reaches the roll, and that it stacks with nothing.


func test_a_creature_in_the_line_raises_the_targets_ac_by_4() -> void:
	var sera := _char("sera")
	_equip_crossbow(sera)
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var covered := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(covered, sera)
	var shot := covered.attack_active(2)
	assert_true(bool(shot.get("ok", false)), String(shot.get("message", "")))
	assert_eq(int(shot["result"]["cover"]), 4, "a creature in the line is soft cover")
	assert_eq(
		int(shot["result"]["target_ac"]),
		CombatScreen.effective_ac(ghoul, covered.is_flat_footed(_index_of(covered, ghoul)), 4),
		"the resolver's AC is the inspector's covered AC",
	)
	assert_true(_logged(covered.log_lines, "has cover, +4 AC"), "the log states the cover term")
	# Control: same seed, same shot, the ally stands out of every line.
	var open := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(6, 4)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(open, sera)
	var clear_shot := open.attack_active(2)
	assert_eq(int(clear_shot["result"]["cover"]), 0, "an ally out of the line is not cover")
	assert_false(_logged(open.log_lines, "has cover"), "no cover line is emitted")
	assert_eq(
		int(shot["result"]["target_ac"]),
		int(clear_shot["result"]["target_ac"]) + 4,
		"cover is exactly +4 AC and applies once",
	)


func test_thrown_weapons_get_soft_cover_too() -> void:
	var sera := _char("sera")
	sera.equipment["weapon"] = content.items["dagger"].duplicate(true)
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[sera, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, sera)
	var throw := e.attack_active(2, "thrown")
	assert_true(bool(throw.get("ok", false)), String(throw.get("message", "")))
	assert_eq(int(throw["result"]["cover"]), 4, "a thrown weapon is a ranged attack")
	assert_eq(int(throw["result"]["into_melee_penalty"]), -4, "the two ranged rules stay independent")


func test_a_ranged_touch_spell_keeps_cover() -> void:
	var caster := _caster()
	assert_not_null(caster, "a prepared caster with scorching ray exists")
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_at(
		[caster, kaelen], [Vector2i(1, 4), Vector2i(3, 1)], [ghoul], [Vector2i(4, 1)]
	)
	_force_turn(e, caster)
	var cast := e.cast_active_spell("scorching_ray", 2)
	assert_true(bool(cast.get("ok", false)), String(cast.get("message", "")))
	assert_true(_logged(e.log_lines, "casts Scorching Ray"), "the ray was fired")
	assert_true(
		_logged(e.log_lines, "has cover, +4 AC"),
		"a ranged touch spell is a ranged attack and the creature in the line still covers",
	)


## The roll itself: cover is a modifier on AC, so a touch attack loses it too.
func test_the_cover_term_raises_touch_ac_in_the_roll() -> void:
	var sera := _char("sera")
	_equip_crossbow(sera)
	var ghoul := _monster("ghoul")
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var weapon: Dictionary = content.items["light_crossbow"]
	var plain := Rules.attack(rng, sera, ghoul, weapon, 20, {"touch": true})
	var covered := Rules.attack(rng, sera, ghoul, weapon, 20, {"touch": true, "cover": 4})
	assert_eq(int(plain["target_ac"]), Rules.touch_ac(ghoul, {}), "touch AC without cover")
	assert_eq(int(covered["target_ac"]), int(plain["target_ac"]) + 4, "cover is +4 on touch AC")
	assert_eq(int(covered["cover"]), 4, "the result records the term it applied")


## The inspect panel must not show a bare attacker-dependent AC, and it must
## state the AC the actual attack type uses: a ranged touch attack resolves
## against touch AC and keeps cover, so both numbers appear with the +4.
func test_the_inspector_states_both_covered_acs_for_the_named_shooter() -> void:
	var ghoul := _monster("ghoul")
	var summary := CombatScreen.cover_summary(ghoul, false, 4, "Sera Vane")
	assert_eq(
		summary,
		"Sera Vane's ranged attack: AC %d • touch %d (+4 cover, PHB p.151)"
		% [Rules.armor_class(ghoul, {}) + 4, Rules.touch_ac(ghoul, {}) + 4],
		"the clause names the shooter and states both covered ACs",
	)
	assert_true(summary.contains("PHB p.151"), "the panel cites the rule")
