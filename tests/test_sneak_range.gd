extends GutTest

## PHB p. 50: "Ranged attacks can count as sneak attacks only if the target is
## within 30 feet." The limit is measured attacker-to-target on the same grid
## distance the engine already uses for range increments, so 30 ft. is inside it
## and 35 ft. is outside. It applies to any ranged attack that would otherwise be
## a sneak attack - here the flat-footed route, because a ranged attacker can never
## flank - and it removes the extra dice without changing the action spent or the
## attack roll. Every assertion reads the applied dice from the result and the log,
## not hit or miss.

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


## Ten columns: the interior runs x=1..8, so cells 5 ft. apart cover 25, 30 and
## 35 ft. with clear line of sight and no cover.
func _map() -> BattleMap:
	return BattleMap.from_rows(
		[
			"##########",
			"#........#",
			"#........#",
			"#........#",
			"##########",
		]
	)


func _encounter(party: Array, monsters: Array, party_cells: Array, monster_cells: Array) -> Encounter:
	var e := Encounter.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7717
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Sneak range")
	e.begin()
	_preload_ranged_weapons(e)
	return e


## A crossbow that is not loaded refuses the shot for a reason unrelated to
## distance, so the ranged cases load it through the encounter's own state.
func _preload_ranged_weapons(e: Encounter) -> void:
	for entry in e.combatants:
		var ch: Character = entry["char"]
		var weapon: Dictionary = ch.equipment.get("weapon", {})
		if String(weapon.get("reload", "")) != "":
			e.loaded_weapons[String(ch.id)] = String(weapon.get("id", ""))


## The applied sneak dice appear in the damage rolls as one "extra ..." entry, so
## this reads the roll rather than the hit or miss outcome.
func _extra_dice(attack: Dictionary) -> String:
	for roll in Array(attack.get("damage_rolls", [])):
		if String(roll).begins_with("extra "):
			return String(roll)
	return ""


func _force_turn(e: Encounter, ch: Character) -> void:
	var entry := e.entry_for(ch)
	assert_false(entry.is_empty(), "%s is in the encounter" % ch.display_name)
	if entry.is_empty():
		return
	e.turn_ptr = e.order.find(int(entry["index"]))
	e._begin_turn(entry)


## The looter has not acted, so it is flat-footed and the flat-footed route is
## open. Sera is the only combatant whose turn is forced, which leaves that state
## intact while her standard action is fresh.
func _ranged_attack_at(distance_cells: int) -> Dictionary:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	# Seeded fixture: Sera's crossbow is equipped so the shot is a ranged attack
	# with the shipped weapon, and the looter is left flat-footed by not acting.
	sera.equip("weapon", content.get_item("light_crossbow"))
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, sera],
		[looter],
		[Vector2i(1, 3), Vector2i(1, 2)],
		[Vector2i(1 + distance_cells, 2)]
	)
	assert_true(e.is_flat_footed(int(e.entry_for(looter)["index"])), "seeded: the looter is flat-footed")
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var result := e.attack_active(int(e.entry_for(looter)["index"]), "ranged")
	return {
		"e": e,
		"result": result,
		"fresh": " ".join(Array(e.log_lines.slice(before))),
		"distance": e.map.distance_ft(
			e.combatants[int(e.entry_for(sera)["index"])]["cell"],
			e.combatants[int(e.entry_for(looter)["index"])]["cell"]
		),
	}


## Positive control: 25 ft. is inside the printed limit, so the flat-footed
## sneak dice apply exactly as they did before this rule existed.
func test_a_ranged_sneak_attack_inside_thirty_feet_applies() -> void:
	var run := _ranged_attack_at(5)
	assert_eq(int(run["distance"]), 25, "covers: the seeded shot is 25 ft.")
	assert_true(bool(run["result"]["ok"]), String(run["result"].get("message", "")))
	var attack: Dictionary = run["result"]["result"]
	assert_true(_extra_dice(attack).begins_with("extra "), "inside the limit the rogue's dice apply")
	assert_true(String(run["fresh"]).contains("sneak attack applies: +2d6"), String(run["fresh"]))
	assert_true(bool(run["e"].turn_state["standard_used"]), "covers: the shot spends the standard action")


## 35 ft. is beyond the printed limit, so the same shot carries no extra dice.
func test_a_ranged_sneak_attack_beyond_thirty_feet_does_not_apply() -> void:
	var run := _ranged_attack_at(7)
	assert_eq(int(run["distance"]), 35, "covers: the seeded shot is 35 ft.")
	assert_true(bool(run["result"]["ok"]), String(run["result"].get("message", "")))
	var attack: Dictionary = run["result"]["result"]
	assert_eq(_extra_dice(attack), "", "beyond the limit the dice are withheld")
	assert_false(String(run["fresh"]).contains("sneak attack applies"), String(run["fresh"]))
	# The limit withholds dice, not the attack: it still resolves and still costs
	# the standard action, and the flat-footed condition is still reported.
	assert_true(bool(run["e"].turn_state["standard_used"]), "the shot still spends the standard action")
	assert_true(String(run["fresh"]).contains("flat-footed"), String(run["fresh"]))
	assert_true(
		String(run["fresh"]).contains("no sneak attack beyond 30 ft."),
		String(run["fresh"])
	)


## The boundary: "within 30 feet" includes exactly 30, which on this grid is the
## cell six steps away.
func test_thirty_feet_is_inside_the_ranged_limit() -> void:
	var run := _ranged_attack_at(6)
	assert_eq(int(run["distance"]), 30, "covers: the seeded shot is 30 ft.")
	assert_true(bool(run["result"]["ok"]), String(run["result"].get("message", "")))
	var attack: Dictionary = run["result"]["result"]
	assert_true(_extra_dice(attack).begins_with("extra "), "30 ft. is within the limit")
	assert_true(String(run["fresh"]).contains("sneak attack applies: +2d6"), String(run["fresh"]))


## Melee sneak attack is untouched by a limit that only covers ranged attacks.
func test_a_melee_sneak_attack_is_unchanged() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, sera],
		[looter],
		[Vector2i(2, 2), Vector2i(4, 2)],
		[Vector2i(3, 2)]
	)
	var before := e.log_lines.size()
	_force_turn(e, sera)
	var result := e.attack_active(int(e.entry_for(looter)["index"]))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_true(_extra_dice(attack).begins_with("extra "), "the adjacent flat-footed rogue still sneaks")
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_true(fresh.contains("sneak attack applies: +2d6"), fresh)
	assert_true(bool(e.turn_state["standard_used"]), "the melee attack spends the standard action")


## A non-rogue has no sneak dice at any distance, so the new limit must not alter
## what her ranged attack reports.
func test_a_non_rogue_ranged_attack_is_unchanged() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	# Seeded fixture: the fighter borrows the same crossbow so the only difference
	# from the rogue case is the absence of sneak dice.
	kaelen.equip("weapon", content.get_item("light_crossbow"))
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, sera],
		[looter],
		[Vector2i(1, 2), Vector2i(1, 3)],
		[Vector2i(6, 2)]
	)
	assert_true(e.is_flat_footed(int(e.entry_for(looter)["index"])), "seeded: the looter is flat-footed")
	_force_turn(e, kaelen)
	var before := e.log_lines.size()
	var result := e.attack_active(int(e.entry_for(looter)["index"]), "ranged")
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_eq(_extra_dice(attack), "", "a non-rogue never carries sneak dice")
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_false(fresh.contains("sneak attack applies"), fresh)
	assert_true(bool(e.turn_state["standard_used"]), "the shot still spends the standard action")
