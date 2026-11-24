extends GutTest

## PHB p. 153: "When making a melee attack, you get a +2 flanking bonus if your
## opponent is threatened by a character or creature friendly to you on the
## opponent's opposite border or opposite corner." The attacker must be one of the
## pair: a third party's flank does not help, a ranged attacker gets no bonus, and
## an ally that cannot act or does not threaten does not complete the pair.
##
## Rogue sneak attack (PHB pp. 49-50) uses the same participation rule: the rogue
## must flank the target herself, or catch it flat-footed or helpless. Every
## assertion here reads the applied attack modifier from the roll, not hit or miss.

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
		]
	)


func _encounter(party: Array, monsters: Array, party_cells: Array, monster_cells: Array) -> Encounter:
	var e := Encounter.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7717
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Flanking")
	e.begin()
	_preload_ranged_weapons(e)
	return e


## A crossbow that is not loaded refuses the shot for a reason unrelated to
## flanking, so the ranged cases load it through the encounter's own state.
func _preload_ranged_weapons(e: Encounter) -> void:
	for entry in e.combatants:
		var ch: Character = entry["char"]
		var weapon: Dictionary = ch.equipment.get("weapon", {})
		if String(weapon.get("reload", "")) != "":
			e.loaded_weapons[String(ch.id)] = String(weapon.get("id", ""))


func _force_turn(e: Encounter, ch: Character) -> void:
	var entry := e.entry_for(ch)
	assert_false(entry.is_empty(), "%s is in the encounter" % ch.display_name)
	if entry.is_empty():
		return
	e.turn_ptr = e.order.find(int(entry["index"]))
	e._begin_turn(entry)


func _place(e: Encounter, ch: Character, cell: Vector2i) -> void:
	var entry := e.entry_for(ch)
	assert_false(entry.is_empty())
	if entry.is_empty():
		return
	e.combatants[int(entry["index"])]["cell"] = cell


## The pair straddles the looter on the x axis: kaelen at (3,4), sera at (5,4),
## looter at (4,4). Sera's own attack must carry +2.
func test_a_flanker_gets_plus_two_through_the_ordinary_attack() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, sera],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var result := e.attack_active(looter_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	var base := Rules.attack_bonus(sera, sera.equipment.get("weapon", {}), 5, "melee")
	assert_eq(int(attack["bonus"]), base + 2, "the flanking attacker's roll carries +2")
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_true(fresh.contains("flanking +2"), "the log names the flanking bonus: %s" % fresh)


## Kaelen and Aldric straddle the looter; Sera attacks from the north. She is not
## one of the pair, so no +2.
func test_a_third_party_flank_gives_the_attacker_no_bonus() -> void:
	var kaelen := _char("kaelen")
	var aldric := _char("aldric")
	var sera := _char("sera")
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, aldric, sera],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4), Vector2i(4, 3)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var result := e.attack_active(looter_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	var base := Rules.attack_bonus(sera, sera.equipment.get("weapon", {}), 5, "melee")
	assert_eq(int(attack["bonus"]), base, "someone else's flank is not Sera's bonus")
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_false(fresh.contains("flanking +2"), "no flanking line for a non-flanker: %s" % fresh)


## The table grants "Flanking defender +2" for melee and nothing for ranged.
func test_a_ranged_attacker_gets_no_flanking_bonus() -> void:
	var kaelen := _char("kaelen")
	var aldric := _char("aldric")
	var sera := _char("sera")
	var crossbow := content.get_item("light_crossbow")
	sera.equip("weapon", crossbow)
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, aldric, sera],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4), Vector2i(4, 3)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	_force_turn(e, sera)
	var result := e.attack_active(looter_index, "ranged")
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	# Two allies are engaged with the target, so the printed -4 for shooting into
	# melee applies; a flanking +2 would show up as -2 here instead of -4.
	assert_eq(
		int(attack["bonus"]),
		Rules.attack_bonus(sera, crossbow, 5, "ranged") - 4,
		"a ranged attack has no flanking bonus even with two allies engaged"
	)


## "Only a creature or character that threatens the defender can help an attacker
## get a flanking bonus." A crossbow-armed ally on the far side does not.
func test_a_non_threatening_ally_does_not_complete_the_pair() -> void:
	var sera := _char("sera")
	var aldric := _char("aldric")
	aldric.equip("weapon", content.get_item("light_crossbow"))
	var looter := _monster("store_looter")
	var e := _encounter(
		[sera, aldric],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	_force_turn(e, sera)
	var result := e.attack_active(looter_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_eq(
		int(attack["bonus"]),
		Rules.attack_bonus(sera, sera.equipment.get("weapon", {}), 5, "melee"),
		"an ally that does not threaten cannot help"
	)


## A paralyzed ally cannot make melee attacks, so it cannot flank. The decision is
## explicit: only a creature that can act and threatens counts.
func test_a_paralyzed_ally_does_not_complete_the_pair() -> void:
	var sera := _char("sera")
	var kaelen := _char("kaelen")
	kaelen.add_effect("paralyzed", "Paralyzed", 5)
	var looter := _monster("store_looter")
	var e := _encounter(
		[sera, kaelen],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	_force_turn(e, sera)
	var result := e.attack_active(looter_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	assert_eq(
		int(attack["bonus"]),
		Rules.attack_bonus(sera, sera.equipment.get("weapon", {}), 5, "melee"),
		"a paralyzed ally is not a flanker"
	)


## Sneak attack, genuine flank: Sera is one of the pair, so her 2d6 applies even
## though the looter has already acted (not flat-footed).
func test_a_flanking_rogue_sneaks_against_a_target_that_is_not_flat_footed() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, sera],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	assert_false(e.is_flat_footed(looter_index), "the looter has acted")
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var result := e.attack_active(looter_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_true(fresh.contains("sneak attack applies: +2d6"), fresh)
	var extra := false
	for raw_roll in Array(Dictionary(result["result"]).get("damage_rolls", [])):
		if String(raw_roll).begins_with("extra "):
			extra = true
	assert_true(extra, "the flanking rogue's damage includes the extra dice")


## Sneak attack, third party's flank: Sera is not one of the pair and the target is
## not flat-footed, so no extra dice.
func test_a_rogue_who_does_not_flank_gets_no_sneak_attack() -> void:
	var kaelen := _char("kaelen")
	var aldric := _char("aldric")
	var sera := _char("sera")
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, aldric, sera],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4), Vector2i(4, 3)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var result := e.attack_active(looter_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_false(fresh.contains("sneak attack applies"), fresh)
	var extra := false
	for raw_roll in Array(Dictionary(result["result"]).get("damage_rolls", [])):
		if String(raw_roll).begins_with("extra "):
			extra = true
	assert_false(extra, "no extra dice for a rogue who is not a flanker")


## Sneak attack, ranged: a crossbow shot while two allies flank the target gets no
## sneak damage. (The printed 30-foot ranged limit is a separate rule this batch
## does not model.)
func test_a_ranged_rogue_gets_no_sneak_attack_from_another_pair() -> void:
	var kaelen := _char("kaelen")
	var aldric := _char("aldric")
	var sera := _char("sera")
	sera.equip("weapon", content.get_item("light_crossbow"))
	var looter := _monster("store_looter")
	var e := _encounter(
		[kaelen, aldric, sera],
		[looter],
		[Vector2i(3, 4), Vector2i(5, 4), Vector2i(4, 3)],
		[Vector2i(4, 4)]
	)
	var looter_index := int(e.entry_for(looter)["index"])
	_force_turn(e, looter)
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var result := e.attack_active(looter_index, "ranged")
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_false(fresh.contains("sneak attack applies"), fresh)


## The same rule through Game.combat_attack, the path the action button calls, on
## the shipped storeroom encounter. Cells are seeded; the attack is ordinary.
func test_flanking_applies_through_game_combat_attack() -> void:
	var started := Game.new_game(["kaelen", "sera"], 4242)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))
	Game.start_encounter("storeroom_dead")
	var e := Game.encounter
	assert_not_null(e)
	if e == null:
		return
	_preload_ranged_weapons(e)
	var sera: Character = Game.party[1]
	var looter: Character = null
	for entry in e.combatants:
		var ch: Character = entry["char"]
		if ch != null and ch.is_monster and not ch.tags.has("undead"):
			looter = ch
	assert_not_null(looter, "the storeroom holds a living opponent")
	if looter == null:
		return
	var looter_index := int(e.entry_for(looter)["index"])
	e.combatants[looter_index]["cell"] = Vector2i(4, 1)
	_place(e, Game.party[0], Vector2i(3, 1))
	_place(e, sera, Vector2i(5, 1))
	_force_turn(e, looter)
	_force_turn(e, sera)
	var before := e.log_lines.size()
	var result := Game.combat_attack(looter_index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var attack: Dictionary = result["result"]
	var base := Rules.attack_bonus(sera, sera.equipment.get("weapon", {}), 5, "melee")
	assert_eq(int(attack["bonus"]), base + 2, "the ordinary attack path applies the +2")
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_true(fresh.contains("sneak attack applies: +2d6"), fresh)


## Monsters attack through the same shared bonus. Two zombies straddling Kaelen
## give the attacking zombie +2 on its slam, which is what parity means here: the
## rule is not a party-only bonus.
func test_monsters_get_the_flanking_bonus_through_the_ai_attack_path() -> void:
	var kaelen := _char("kaelen")
	var zombie_a := _monster("zombie")
	var zombie_b := _monster("zombie")
	var e := _encounter(
		[kaelen],
		[zombie_a, zombie_b],
		[Vector2i(4, 4)],
		[Vector2i(3, 4), Vector2i(5, 4)]
	)
	var z_index := int(e.entry_for(zombie_b)["index"])
	var k_index := int(e.entry_for(kaelen)["index"])
	_force_turn(e, zombie_b)
	var before := e.log_lines.size()
	e._monster_single_attack(e.combatants[z_index], e.combatants[k_index])
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	var bonus := -999
	var re := RegEx.new()
	re.compile("d20\\((\\d+)\\)\\+(-?\\d+)")
	var found := re.search(fresh)
	if found != null:
		bonus = int(found.get_string(2))
	var base := Rules.attack_bonus(zombie_b, zombie_b.attacks[0], 5, "melee")
	assert_eq(bonus, base + 2, "the monster's slam carries the +2: %s" % fresh)
