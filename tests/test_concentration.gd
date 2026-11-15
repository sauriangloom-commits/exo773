extends GutTest

## Concentration while casting (PHB printed pp. 69-70, 140, 170).
##
## p. 170: "If while trying to cast a spell you take damage, you must make a
## Concentration check (DC 10 + points of damage taken + the level of the spell
## you're casting). If you fail the check, you lose the spell without effect."
## p. 70: "If more than one type of distraction is present, make a check for each
## one; any failed Concentration check indicates that the task is not completed."
## p. 140: "casting a spell while on the defensive does not provoke an attack of
## opportunity. It does, however, require a Concentration check (DC 15 + spell
## level) to pull off. Failure means that you lose the spell."
##
## The encounter now begins the cast (spending the action and the prepared cast)
## before reactions resolve, so a disrupted spell costs what the rules say it
## costs. These tests assert the roll inputs rather than only the outcome.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _wizard_id() -> String:
	for id in content.character_ids():
		var data := content.get_character(id)
		var prepared: Dictionary = data.get("spells", {}).get("prepared", {})
		for level in prepared.keys():
			if Array(prepared[level]).has("scorching_ray"):
				return id
	return ""


func _caster(ranks := 0) -> Character:
	var ch := Character.from_content(content.get_character(_wizard_id()), content.items)
	ch.id = "qa_concentration_caster"
	ch.display_name = "QA Caster"
	ch.max_hp = 60
	ch.hp = 60
	ch.skill_ranks["concentration"] = ranks
	return ch


func _zombie(id := "qa_zombie", name := "QA Zombie") -> Character:
	var ch := Character.from_content(content.get_monster("zombie"), content.items)
	ch.id = id
	ch.display_name = name
	ch.max_hp = 200
	ch.hp = 200
	return ch


func _ghoul() -> Character:
	var ch := Character.from_content(content.get_monster("ghoul"), content.items)
	ch.id = "qa_target"
	ch.display_name = "QA Target"
	ch.max_hp = 200
	ch.hp = 200
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


## Every combatant takes its first turn before the caster casts, so nobody is
## flat-footed when the opportunity attacks resolve (a flat-footed creature may
## not react, and these tests are about the reaction, not that state).
func _encounter(caster: Character, enemies: Array, cells: Array, seed := 424242) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var e := Encounter.new()
	var party_cells: Array = [Vector2i(1, 3)]
	e.setup([caster], enemies, _map(), rng, party_cells, cells, content.spells, "Test")
	e.begin()
	for entry in e.combatants:
		if entry["char"] == caster:
			continue
		for i in e.order:
			if e.combatants[i]["char"] == entry["char"]:
				e.turn_ptr = e.order.find(i)
				e._begin_turn(e.combatants[i])
				break
	for i in e.order:
		if e.combatants[i]["char"] == caster:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			break
	return e


func _enemy_index(e: Encounter, ch: Character) -> int:
	for entry in e.combatants:
		if entry["char"] == ch:
			return int(entry["index"])
	fail_test("enemy is not a combatant")
	return -1


func _logs(e: Encounter, needle: String) -> bool:
	for line in e.log_lines:
		if String(line).contains(needle):
			return true
	return false


func _log_count(e: Encounter, needle: String) -> int:
	var total := 0
	for line in e.log_lines:
		if String(line).contains(needle):
			total += 1
	return total


## Runs the cast for successive seeds until `wanted` accepts the result, so a
## scenario that needs an attack to hit or miss is found deterministically
## instead of relying on one lucky roll.
func _cast_until(
	caster_factory: Callable,
	enemies_factory: Callable,
	spell_id: String,
	defensive: bool,
	wanted: Callable
) -> Dictionary:
	for seed in range(1, 400):
		var caster: Character = caster_factory.call()
		var enemies: Array = enemies_factory.call()
		var cells: Array = []
		for entry in enemies:
			cells.append(entry["cell"])
		var clean: Array = []
		for entry in enemies:
			clean.append(entry["char"])
		var e := _encounter(caster, clean, cells, seed)
		var result := e.cast_active_spell(spell_id, clean.size(), {"defensive": defensive})
		if bool(wanted.call(result, e)):
			return {"seed": seed, "result": result, "encounter": e, "caster": caster}
	fail_test("no deterministic seed produced the wanted interruption")
	return {}


func test_ordinary_cast_while_unthreatened_needs_no_concentration_check() -> void:
	var caster := _caster()
	var target := _ghoul()
	var e := _encounter(caster, [target], [Vector2i(1, 1)])
	var result := e.cast_active_spell("magic_missile", 1)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(result["concentration_checks"].size()), 0, "no distraction, no check")
	assert_false(_logs(e, "Concentration check"), "nothing is rolled")
	assert_false(_logs(e, "provokes"), "an unthreatened cast does not provoke")
	assert_eq(int(caster.spells["slots"]["1"]["used"]), 1, "exactly one slot is spent")


func test_threatened_cast_without_damage_needs_no_concentration_check() -> void:
	var found := _cast_until(
		func() -> Character: return _caster(),
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = -50
			return [{"char": zombie, "cell": Vector2i(2, 3)}, {"char": _ghoul(), "cell": Vector2i(1, 1)}],
		"magic_missile",
		false,
		func(result: Dictionary, e: Encounter) -> bool:
			return _logs(e, "Attack of opportunity by") and bool(result["ok"])
	)
	assert_false(found.is_empty(), "a missed opportunity attack leaves the spell intact")
	var e: Encounter = found["encounter"]
	assert_eq(_log_count(e, "Attack of opportunity by"), 1, "one threatening enemy reacted")
	assert_false(_logs(e, "injury while casting"), "no damage means no injury check")
	assert_eq(int(found["result"]["concentration_checks"].size()), 0, "no check was made")


func test_damage_during_casting_allows_the_spell_on_a_successful_check() -> void:
	var found := _cast_until(
		func() -> Character: return _caster(10),
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = 50
			return [{"char": zombie, "cell": Vector2i(2, 3)}, {"char": _ghoul(), "cell": Vector2i(1, 1)}],
		"magic_missile",
		false,
		func(result: Dictionary, e: Encounter) -> bool:
			return _logs(e, "injury while casting") and bool(result["ok"])
	)
	assert_false(found.is_empty(), "a hitting opportunity attack still allows the spell")
	var checks: Array = found["result"]["concentration_checks"]
	assert_eq(checks.size(), 1, "one damaging interruption makes one check")
	var entry: Dictionary = checks[0]
	assert_eq(String(entry["kind"]), "injury", "the check is an injury check")
	var damage := int(entry["damage"])
	assert_gt(damage, 0, "the interruption dealt damage")
	assert_eq(int(entry["dc"]), 10 + damage + 1, "DC is 10 + damage + spell level")
	assert_eq(int(entry["check"]["dc"]), int(entry["dc"]), "the rolled check uses that DC")
	assert_true(bool(entry["check"]["success"]), "the fixture has the ranks to pass")
	assert_true(_logs(found["encounter"], "casts Magic Missile"), "the spell then resolves")


func test_failed_injury_check_disrupts_the_spell_and_spends_the_cast() -> void:
	var found := _cast_until(
		func() -> Character:
			var caster := _caster(0)
			caster.abilities["con"] = 1
			return caster,
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = 50
			return [{"char": zombie, "cell": Vector2i(2, 3)}, {"char": _ghoul(), "cell": Vector2i(1, 1)}],
		"magic_missile",
		false,
		func(result: Dictionary, e: Encounter) -> bool:
			return bool(result.get("disrupted", false))
	)
	assert_false(found.is_empty(), "a failed check is reachable")
	var e: Encounter = found["encounter"]
	var caster: Character = found["caster"]
	assert_false(bool(found["result"]["ok"]), "the cast reports failure")
	assert_true(bool(e.turn_state["standard_used"]), "the standard action is spent")
	assert_eq(int(caster.spells["slots"]["1"]["used"]), 1, "the slot is spent")
	assert_eq(
		Array(caster.spells["prepared"]["1"]).count("magic_missile"),
		1,
		"the prepared cast is lost (one of two remains)"
	)
	var target: Character = e.combatants[1]["char"]
	assert_eq(target.hp, target.max_hp, "no spell effect was applied")
	assert_true(_logs(e, "The spell is disrupted"), "the disruption is stated")
	var checks: Array = found["result"]["concentration_checks"]
	assert_false(bool(checks[0]["check"]["success"]), "the recorded check failed")


func test_defensive_cast_succeeds_without_provoking() -> void:
	var found := _cast_until(
		func() -> Character: return _caster(10),
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = 50
			return [{"char": zombie, "cell": Vector2i(2, 3)}],
		"magic_missile",
		true,
		func(result: Dictionary, _e: Encounter) -> bool: return bool(result["ok"])
	)
	assert_false(found.is_empty(), "a defensive cast can succeed")
	var e: Encounter = found["encounter"]
	assert_false(_logs(e, "provokes"), "defensive casting does not provoke")
	assert_false(_logs(e, "Attack of opportunity by"), "no reaction is taken")
	assert_true(_logs(e, "casts Magic Missile defensively"), "the mode is stated")
	var checks: Array = found["result"]["concentration_checks"]
	assert_eq(String(checks[0]["kind"]), "defensive", "the defensive check is recorded")
	assert_eq(int(checks[0]["dc"]), 15 + 1, "DC is 15 + spell level")
	assert_true(bool(checks[0]["check"]["success"]), "the fixture passes the check")


func test_failed_defensive_cast_loses_the_spell_without_provoking() -> void:
	var found := _cast_until(
		func() -> Character:
			var caster := _caster(0)
			caster.abilities["con"] = 1
			return caster,
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = 50
			return [{"char": zombie, "cell": Vector2i(2, 3)}],
		"scorching_ray",
		true,
		func(result: Dictionary, _e: Encounter) -> bool: return bool(result.get("disrupted", false))
	)
	assert_false(found.is_empty(), "a defensive failure is reachable")
	var e: Encounter = found["encounter"]
	assert_false(_logs(e, "Attack of opportunity by"), "defensive casting never provokes")
	assert_eq(int(found["caster"].spells["slots"]["2"]["used"]), 1, "the level-2 slot is spent")
	assert_true(_logs(e, "The spell is disrupted"), "the loss is stated")
	assert_eq(found["caster"].spells["prepared"]["2"].count("scorching_ray"), 1, "one ray remains prepared")


func test_spell_level_is_part_of_the_dc() -> void:
	# Same caster, same damaging interruption, two different spell levels: only
	# the level term may differ, so the DCs differ by exactly the level gap.
	var low := _cast_until(
		func() -> Character: return _caster(20),
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = 50
			return [{"char": zombie, "cell": Vector2i(2, 3)}, {"char": _ghoul(), "cell": Vector2i(1, 1)}],
		"magic_missile",
		false,
		func(result: Dictionary, e: Encounter) -> bool:
			return _logs(e, "injury while casting") and bool(result["ok"])
	)
	var high := _cast_until(
		func() -> Character: return _caster(20),
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = 50
			return [{"char": zombie, "cell": Vector2i(2, 3)}, {"char": _ghoul(), "cell": Vector2i(1, 1)}],
		"scorching_ray",
		false,
		func(result: Dictionary, e: Encounter) -> bool:
			return _logs(e, "injury while casting") and bool(result["ok"])
	)
	assert_false(low.is_empty(), "level-1 injury case found")
	assert_false(high.is_empty(), "level-2 injury case found")
	var low_dc := int(low["result"]["concentration_checks"][0]["dc"]) - int(low["result"]["concentration_checks"][0]["damage"])
	var high_dc := int(high["result"]["concentration_checks"][0]["dc"]) - int(high["result"]["concentration_checks"][0]["damage"])
	assert_eq(high_dc - low_dc, 1, "the level-2 spell raises the DC by one")


func test_multiple_interruptions_make_one_check_each() -> void:
	var found := _cast_until(
		func() -> Character: return _caster(20),
		func() -> Array:
			var first := _zombie("qa_zombie_a", "QA Zombie A")
			first.base_attack = 50
			var second := _zombie("qa_zombie_b", "QA Zombie B")
			second.base_attack = 50
			return [
				{"char": first, "cell": Vector2i(2, 3)},
				{"char": second, "cell": Vector2i(1, 2)},
				{"char": _ghoul(), "cell": Vector2i(1, 1)},
			],
		"magic_missile",
		false,
		func(_result: Dictionary, e: Encounter) -> bool:
			return _logs(e, "injury while casting") and _log_count(e, "injury while casting") == 2
	)
	assert_false(found.is_empty(), "both threatening enemies interrupted")
	var checks: Array = found["result"]["concentration_checks"]
	assert_eq(checks.size(), 2, "one check per damaging interruption (PHB p.70)")
	assert_eq(_log_count(found["encounter"], "Attack of opportunity by"), 2, "two reactions resolved")


func test_caster_incapacitated_by_the_interruption_cannot_complete_the_spell() -> void:
	var found := _cast_until(
		func() -> Character: return _caster(20),
		func() -> Array:
			var zombie := _zombie()
			zombie.base_attack = 50
			zombie.attacks = [{
				"name": "slam",
				"damage": "20d6+100",
				"crit_range": 20,
				"crit_mult": 2,
				"damage_type": "bludgeoning",
			}]
			return [{"char": zombie, "cell": Vector2i(2, 3)}, {"char": _ghoul(), "cell": Vector2i(1, 1)}],
		"magic_missile",
		false,
		func(result: Dictionary, e: Encounter) -> bool:
			var ch: Character = e.combatants[0]["char"]
			return bool(result.get("disrupted", false)) and not ch.can_act()
	)
	assert_false(found.is_empty(), "the caster can be dropped by the reaction")
	var e: Encounter = found["encounter"]
	assert_false(bool(found["result"]["ok"]), "the spell does not complete")
	assert_true(_logs(e, "cannot complete the spell"), "the reason is logged")
	assert_eq(int(found["caster"].spells["slots"]["1"]["used"]), 1, "the cast is still spent")
	assert_false(_logs(e, "casts Magic Missile."), "no completed-cast line is written")



func test_invalid_target_consumes_nothing() -> void:
	var caster := _caster()
	var target := _ghoul()
	var e := _encounter(caster, [target], [Vector2i(1, 1)])
	var used_before := int(caster.spells["slots"]["1"].get("used", 0))
	var result := e.cast_active_spell("magic_missile", 0)
	assert_false(bool(result["ok"]), "casting at yourself is refused")
	assert_eq(int(caster.spells["slots"]["1"].get("used", 0)), used_before, "no slot is spent")
	assert_false(bool(e.turn_state["standard_used"]), "no action is spent")
	assert_false(_logs(e, "Concentration"), "no check is made for an invalid selection")


func test_missing_concentration_ranks_use_constitution_only() -> void:
	var caster := _caster()
	assert_eq(
		int(caster.skill_ranks.get("concentration", 0)), 0, "the shipped caster has no Concentration ranks"
	)
	assert_eq(
		Rules.skill_total(caster, "concentration"),
		Rules.ability_modifier(caster, "con"),
		"untrained Concentration is the Constitution modifier, not a free rank"
	)
	assert_true(Skills.untrained_allowed("concentration"), "the skill is usable untrained (PHB p.69)")


func test_old_save_without_the_skill_entry_keeps_working() -> void:
	var data := content.get_character(_wizard_id()).duplicate(true)
	(data["skill_ranks"] as Dictionary).erase("concentration")
	var caster := Character.from_content(data, content.items)
	caster.id = "qa_old_save_caster"
	caster.display_name = "QA Old Save Caster"
	caster.max_hp = 60
	caster.hp = 60
	var e := _encounter(caster, [_ghoul()], [Vector2i(1, 1)])
	var result := e.cast_active_spell("magic_missile", 1)
	assert_true(bool(result["ok"]), "a save without the skill key still casts")
	assert_eq(
		Rules.skill_total(caster, "concentration"),
		Rules.ability_modifier(caster, "con"),
		"a missing entry is read as zero ranks, not as an error"
	)
