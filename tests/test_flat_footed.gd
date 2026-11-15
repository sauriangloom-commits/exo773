extends GutTest

## Combat-start flat-footedness (PHB p.133): "A character who has not yet acted
## during a combat is flat-footed." The state removes the Dexterity modifier
## from AC, denies attacks of opportunity, and lets a rogue sneak attack the
## target. It ends at the start of that character's first turn, not when their
## turn ends and not on awareness: an all-aware encounter still starts
## flat-footed because awareness only decides whether a surprise round occurs.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 424242


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
	party_cell := Vector2i(1, 5),
	monster_cell := Vector2i(7, 1)
) -> Encounter:
	var battle_map := _map()
	var e := Encounter.new()
	var party_cells: Array = []
	var monster_cells: Array = []
	for i in party.size():
		party_cells.append(Vector2i(party_cell.x + i, party_cell.y))
	for i in monsters.size():
		monster_cells.append(Vector2i(monster_cell.x - i, monster_cell.y))
	e.setup(party, monsters, battle_map, rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	return e


## Builds an encounter whose first combatant is a party member, so a monster or
## NPC enemy is still flat-footed when the party attacks. `begin()` activates the
## first combatant, and only that combatant ends its own flat-footed state, so
## the ordering has to be a real one rather than a mutated flag. The seed loop is
## deterministic: the same seeds are tried in the same order every run.
func _encounter_party_first(
	party: Array,
	monsters: Array,
	party_cell := Vector2i(1, 5),
	monster_cell := Vector2i(7, 1)
) -> Encounter:
	for attempt in 40:
		rng = RandomNumberGenerator.new()
		rng.seed = 9000 + attempt
		var e := _encounter(party, monsters, party_cell, monster_cell)
		if int(e.combatants[e.order[0]]["team"]) == Encounter.TEAM_PARTY:
			return e
	fail_test("could not build an encounter where the party acts first")
	return _encounter(party, monsters, party_cell, monster_cell)


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _logged(lines: Array, needle: String) -> bool:
	for line in lines:
		if String(line).contains(needle):
			return true
	return false


func test_combat_starts_with_every_combatant_flat_footed_except_the_active_one() -> void:
	var e := _encounter([_char("kaelen"), _char("sera")], [_monster("zombie")])
	var active_index := int(e.active_entry()["index"])
	assert_eq(e.combatants.size(), 3, "the encounter has three combatants")
	for entry in e.combatants:
		var index := int(entry["index"])
		if index == active_index:
			assert_false(
				e.is_flat_footed(index),
				"the first combatant is no longer flat-footed once their turn begins"
			)
		else:
			assert_true(
				e.is_flat_footed(index),
				"%s has not acted yet and is flat-footed" % (entry["char"] as Character).display_name
			)
	assert_true(
		_logged(e.log_lines, "All combatants are flat-footed until they start their first turn"),
		"the state is announced in the combat log"
	)


func test_flat_footed_target_loses_its_dexterity_modifier_to_ac() -> void:
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_party_first([kaelen], [ghoul], Vector2i(1, 3), Vector2i(2, 3))
	_force_turn(e, kaelen)
	assert_true(e.is_flat_footed(1), "the ghoul has not acted yet")
	var normal_ac := Rules.armor_class(ghoul)
	var flat_ac := Rules.armor_class(ghoul, {"flat_footed": true})
	assert_eq(flat_ac, normal_ac - 2, "the ghoul's +2 Dexterity modifier is removed")
	var result := e.attack_active(1)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	var attack: Dictionary = result.get("result", {})
	assert_eq(
		int(attack.get("target_ac", -1)),
		flat_ac,
		"the resolved attack uses the flat-footed AC, not the normal AC"
	)
	assert_true(
		_logged(e.log_lines, "is flat-footed: no Dexterity bonus to AC"),
		"the reason is visible in the combat log"
	)
	assert_eq(
		Rules.touch_ac(ghoul, {"flat_footed": true}),
		Rules.touch_ac(ghoul) - 2,
		"touch AC also loses the Dexterity modifier while flat-footed"
	)


func test_flat_footed_state_ends_at_the_start_of_the_first_turn() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var e := _encounter([kaelen, sera], [_monster("zombie")])
	var active_index := int(e.active_entry()["index"])
	var waiting_index := 1 if active_index == 0 else 0
	var waiting: Character = e.combatants[waiting_index]["char"]
	assert_true(e.is_flat_footed(waiting_index), "the waiting combatant is flat-footed")
	_force_turn(e, waiting)
	assert_false(e.is_flat_footed(waiting_index), "the state ends when the turn begins")
	assert_true(
		_logged(e.log_lines, "%s is no longer flat-footed" % waiting.display_name),
		"the end of the state is logged"
	)


func test_flat_footed_creature_cannot_make_an_opportunity_attack() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter_party_first([kaelen], [zombie], Vector2i(1, 3), Vector2i(2, 3))
	_force_turn(e, kaelen)
	assert_true(e.is_flat_footed(1), "the zombie has not acted yet")
	var before := e.log_lines.size()
	var move := e.move_active_to(Vector2i(1, 4))
	assert_true(bool(move.get("ok", false)), String(move.get("message", "")))
	assert_false(bool(e.aoo_used.get(1, false)), "a flat-footed creature cannot react")
	assert_true(
		_logged(e.log_lines.slice(before), "is flat-footed and cannot make an attack of opportunity"),
		"the refusal is explained instead of silently skipping the reaction"
	)


func test_opportunity_attack_is_available_once_the_creature_has_taken_its_first_turn() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie], Vector2i(1, 3), Vector2i(2, 3))
	_force_turn(e, zombie)
	assert_false(e.is_flat_footed(1), "the zombie's first turn has begun")
	_force_turn(e, kaelen)
	var before := e.log_lines.size()
	var move := e.move_active_to(Vector2i(1, 4))
	assert_true(bool(move.get("ok", false)), String(move.get("message", "")))
	assert_true(bool(e.aoo_used.get(1, false)), "a creature that has acted can react")
	assert_true(
		_logged(e.log_lines.slice(before), "attack of opportunity by"),
		"the opportunity attack resolved"
	)


func test_monster_attacks_use_the_flat_footed_party_ac() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var zombie := _monster("zombie")
	var e := _encounter_party_first([kaelen, sera], [zombie])
	# Kaelen acts first, so Sera is still flat-footed when the zombie attacks.
	_force_turn(e, kaelen)
	var flat_ac := Rules.armor_class(sera, {"flat_footed": true})
	assert_lt(flat_ac, Rules.armor_class(sera), "Sera has a Dexterity bonus to lose")
	assert_true(e.is_flat_footed(1), "Sera has not acted yet")
	e._monster_single_attack(e.combatants[2], e.combatants[1])
	assert_true(
		_logged(e.log_lines, "vs AC %d" % flat_ac),
		"the monster's attack is resolved against the flat-footed AC"
	)


func test_rogue_sneak_attack_applies_against_a_flat_footed_opponent() -> void:
	# Every shipped monster is undead, which is immune to sneak attack, so this
	# fixture uses a living enemy character to exercise the rule itself.
	var sera := _char("sera")
	var enemy := _char("kaelen")
	var e := _encounter_party_first([sera], [enemy], Vector2i(1, 3), Vector2i(2, 3))
	_force_turn(e, sera)
	assert_true(e.is_flat_footed(1), "the enemy has not acted yet")
	var before_first := e.log_lines.size()
	e.attack_active(1)
	assert_true(
		_logged(e.log_lines.slice(before_first), "sneak attack applies"),
		"a flat-footed defender can be sneak attacked"
	)
	# Once the defender's first turn has begun the state is gone and the same
	# attack is an ordinary one: no flanking partner and no helpless condition.
	_force_turn(e, enemy)
	assert_false(e.is_flat_footed(1), "the enemy's first turn has begun")
	_force_turn(e, sera)
	var before_second := e.log_lines.size()
	e.attack_active(1)
	assert_false(
		_logged(e.log_lines.slice(before_second), "sneak attack applies"),
		"the same attack is not a sneak attack once the defender has acted"
	)


func test_finished_encounter_reports_no_flat_footed_combatants() -> void:
	var e := _encounter([_char("kaelen")], [_monster("zombie")])
	e.finish("victory")
	assert_false(e.is_flat_footed(1), "combat state does not outlive the encounter")


# ---------------------------------------------------------------------------
# PHB p.136 is explicit about what a denied Dexterity bonus means: "If you can't
# react to a blow, you can't use your Dexterity bonus to AC. (If you don't have a
# Dexterity bonus, nothing happens.)" and "Any situation that denies you your
# Dexterity bonus also denies you dodge bonuses." So a Dexterity penalty stays,
# a zero modifier changes nothing, and only dodge bonuses are dropped.


func test_positive_dexterity_bonus_is_denied_while_flat_footed() -> void:
	var sera := _char("sera")
	assert_eq(Rules.ability_modifier(sera, "dex"), 3, "fixture has a +3 Dexterity modifier")
	assert_true(Feats.has_active(sera, "dodge"), "fixture carries the Dodge feat")
	var normal := Rules.armor_class(sera)
	var flat := Rules.armor_class(sera, {"flat_footed": true})
	assert_eq(normal - flat, 4, "flat-footed denies the +3 Dexterity bonus and the +1 dodge bonus")
	assert_eq(Rules.touch_ac(sera) - Rules.touch_ac(sera, {"flat_footed": true}), 4, "touch AC applies the same denial")


func test_zero_dexterity_modifier_leaves_armor_class_unchanged() -> void:
	var aldric := _char("aldric")
	assert_eq(Rules.ability_modifier(aldric, "dex"), 0, "fixture has no Dexterity modifier")
	assert_eq(
		Rules.armor_class(aldric, {"flat_footed": true}),
		Rules.armor_class(aldric),
		"with no Dexterity bonus, nothing happens (PHB p.136)"
	)
	assert_eq(Rules.touch_ac(aldric, {"flat_footed": true}), Rules.touch_ac(aldric), "touch AC is unchanged too")


func test_negative_dexterity_modifier_still_applies_while_flat_footed() -> void:
	var zombie := _monster("zombie")
	assert_eq(Rules.ability_modifier(zombie, "dex"), -1, "fixture has a -1 Dexterity modifier")
	var normal := Rules.armor_class(zombie)
	assert_eq(
		Rules.armor_class(zombie, {"flat_footed": true}),
		normal,
		"a Dexterity penalty is not a bonus and is not removed"
	)
	assert_eq(
		Rules.touch_ac(zombie, {"flat_footed": true}),
		Rules.touch_ac(zombie),
		"touch AC keeps the Dexterity penalty as well"
	)


func test_only_dodge_bonuses_are_dropped_when_dexterity_is_denied() -> void:
	var sera := _char("sera")
	# A non-dodge miscellaneous AC bonus must survive the denial; this is the
	# guard against removing every AC bonus indiscriminately.
	sera.ac_misc = 2
	var normal := Rules.armor_class(sera)
	var flat := Rules.armor_class(sera, {"flat_footed": true})
	assert_eq(normal - flat, 4, "only the Dexterity bonus and Dodge are lost, not ac_misc")
	assert_eq(
		Rules.armor_class(sera, {"flat_footed": true}),
		10 + Rules.armor_bonus(sera) + 3 + 2 - 3,
		"the dodge bonus and the Dexterity bonus are gone while the +2 misc bonus remains"
	)
	# The Dodge feat's contribution is a dodge bonus, so it is the only feat AC
	# the denial removes.
	assert_eq(int(Feats.modifier(sera, "ac")["total"]), 1, "normal AC includes the Dodge feat")
	assert_eq(
		Rules._feat_ac_bonus(sera, true),
		0,
		"denying Dexterity denies the Dodge feat's dodge bonus"
	)


func test_armor_limited_dexterity_bonus_limits_the_flat_footed_loss() -> void:
	var fighter := _char("kaelen")
	fighter.abilities["dex"] = 24
	assert_eq(Rules.ability_modifier(fighter, "dex"), 7, "unarmoured modifier would be +7")
	assert_eq(int(fighter.equipment.get("armor", {}).get("max_dex", 0)), 4, "chain shirt caps Dexterity at +4")
	var normal := Rules.armor_class(fighter)
	var flat := Rules.armor_class(fighter, {"flat_footed": true})
	assert_eq(normal - flat, 4, "only the armor-permitted +4 is lost, not the full +7")


func test_inspector_and_attack_resolution_use_the_same_ac() -> void:
	var kaelen := _char("kaelen")
	var ghoul := _monster("ghoul")
	var e := _encounter_party_first([kaelen], [ghoul], Vector2i(1, 3), Vector2i(2, 3))
	_force_turn(e, kaelen)
	assert_true(e.is_flat_footed(1), "the ghoul has not acted yet")
	var panel_ac := CombatScreen.effective_ac(ghoul, e.is_flat_footed(1))
	var first := e.attack_active(1)
	assert_eq(panel_ac, int(first["result"]["target_ac"]), "the panel and the roll agree while flat-footed")
	_force_turn(e, ghoul)
	var standing_panel := CombatScreen.effective_ac(ghoul, e.is_flat_footed(1))
	assert_eq(standing_panel, Rules.armor_class(ghoul), "the panel shows the standing AC after that turn")
	_force_turn(e, kaelen)
	var second := e.attack_active(1)
	assert_eq(standing_panel, int(second["result"]["target_ac"]), "the panel and the roll agree after the turn")
