extends GutTest

## Ordinary unarmed attacks.
##
## PHB printed p. 139: unarmed strike damage is 1d3 for a Medium character plus
## Strength, "All damage from unarmed strikes is nonlethal damage," and the strike
## counts as a light weapon. "Attacking unarmed provokes an attack of opportunity from
## the character you attack, provided she is armed... nor does it provoke an attack of
## opportunity from an unarmed foe." "A monk, a character with the Improved Unarmed
## Strike feat, a spellcaster delivering a touch attack spell, and a creature with
## claws, fangs, and similar natural physical weapons all count as being armed."
## Undead and constructs are immune to nonlethal damage.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _unarmed_sera() -> Character:
	var ch := Character.from_content(content.get_character("sera"), content.items)
	ch.id = "qa_unarmed_sera"
	ch.display_name = "QA Sera"
	ch.max_hp = 30
	ch.hp = 30
	ch.equipment["weapon"] = {}
	return ch


func _kaelen() -> Character:
	var ch := Character.from_content(content.get_character("kaelen"), content.items)
	ch.id = "qa_unarmed_kaelen"
	ch.display_name = "QA Kaelen"
	ch.max_hp = 30
	ch.hp = 30
	return ch


func _zombie() -> Character:
	var ch := Character.from_content(content.get_monster("zombie"), content.items)
	ch.id = "qa_unarmed_zombie"
	ch.display_name = "QA Zombie"
	ch.max_hp = 60
	ch.hp = 60
	return ch


func _map() -> BattleMap:
	return BattleMap.from_rows(
		[
			"###########",
			"#.........#",
			"#.........#",
			"#.........#",
			"#.........#",
			"###########",
		],
		"test"
	)


func _encounter(party: Array, monsters: Array, party_cells: Array, monster_cells: Array) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = 334455
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	e.turn_ptr = e.order.find(int(e.entry_for(party[0])["index"]))
	e._begin_turn(e.entry_for(party[0]))
	return e


func _start_turn(e: Encounter, ch: Character) -> void:
	e.turn_ptr = e.order.find(int(e.entry_for(ch)["index"]))
	e._begin_turn(e.entry_for(ch))


func _log_text(e: Encounter) -> String:
	return "\n".join(e.log_lines)


func test_an_unarmed_strike_is_nonlethal_and_leaves_hit_points_alone() -> void:
	var sera := _unarmed_sera()
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen], [Vector2i(2, 3)], [Vector2i(3, 3)])
	var hp_before := kaelen.hp
	var weapon := e._primary_weapon(sera)
	assert_eq(String(weapon.get("id", "")), "unarmed_strike", "the empty hand resolves as the strike")
	assert_eq(String(weapon.get("damage", "")), "1d3", "Medium unarmed damage is 1d3")
	assert_true(bool(weapon.get("nonlethal", false)), "the strike is flagged nonlethal")
	var applied := 0
	for attempt in 40:
		_start_turn(e, kaelen)
		_start_turn(e, sera)
		var result := e.attack_active(int(e.entry_for(kaelen)["index"]))
		assert_true(bool(result["ok"]), String(result.get("message", "")))
		if bool(result["result"]["hit"]):
			applied = int(result["result"]["damage_applied"])
			break
	assert_true(applied > 0, "a hit lands within the seeded attempts")
	assert_eq(kaelen.hp, hp_before, "hit points are untouched")
	assert_eq(kaelen.nonlethal, applied, "the damage is recorded as nonlethal")
	assert_true(_log_text(e).contains("nonlethal damage"), "the log says which kind of damage it is")


func test_unarmed_damage_makes_a_living_target_unconscious_only_past_its_hit_points() -> void:
	var sera := _unarmed_sera()
	var kaelen := _kaelen()
	kaelen.max_hp = 4
	kaelen.hp = 4
	var e := _encounter([sera], [kaelen], [Vector2i(2, 3)], [Vector2i(3, 3)])
	kaelen.nonlethal = 4
	assert_true(kaelen.is_conscious(), "equal to hit points is still conscious")
	kaelen.apply_nonlethal(1)
	assert_false(kaelen.is_conscious(), "more nonlethal than hit points makes it unconscious")
	assert_eq(kaelen.hp, 4, "hit points are still untouched")
	assert_true(kaelen.has_condition("nonlethal_unconscious"), "the condition is recorded")


func test_undead_are_immune_to_nonlethal_damage() -> void:
	var sera := _unarmed_sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(2, 3)], [Vector2i(3, 3)])
	assert_true(Rules.nonlethal_immune(zombie), "the zombie is undead")
	var hit := false
	for attempt in 40:
		_start_turn(e, zombie)
		_start_turn(e, sera)
		var result := e.attack_active(int(e.entry_for(zombie)["index"]))
		assert_true(bool(result["ok"]), String(result.get("message", "")))
		if bool(result["result"]["hit"]):
			hit = true
			break
	assert_true(hit, "a hit lands within the seeded attempts")
	assert_eq(zombie.nonlethal, 0, "no nonlethal damage is recorded")
	assert_eq(zombie.hp, 60, "and no hit points are lost")
	assert_true(_log_text(e).contains("immune to nonlethal"), "the immunity is logged")


func test_attacking_unarmed_provokes_from_an_armed_target_only() -> void:
	var sera := _unarmed_sera()
	var kaelen := _kaelen()
	kaelen.max_hp = 60
	kaelen.hp = 60
	var e := _encounter([sera], [kaelen], [Vector2i(2, 3)], [Vector2i(3, 3)])
	var hp_before := sera.hp
	_start_turn(e, kaelen)
	_start_turn(e, sera)
	var result := e.attack_active(int(e.entry_for(kaelen)["index"]))
	assert_true(_log_text(e).contains("attacks unarmed and provokes an attack of opportunity"), "the armed target reacts")
	assert_true(_log_text(e).contains("Attack of opportunity by QA Kaelen"), "the reaction is resolved")
	if sera.hp < hp_before:
		assert_eq(sera.hp, int(result.get("attacker_hp", sera.hp)), "the reaction lands before the strike")
	var other := _kaelen()
	var empty := _unarmed_sera()
	empty.id = "qa_unarmed_empty_target"
	var e2 := _encounter([sera], [empty], [Vector2i(2, 3)], [Vector2i(3, 3)])
	e2.attack_active(int(e2.entry_for(empty)["index"]))
	assert_true(_log_text(e2).contains("is unarmed and cannot answer"), "an unarmed foe cannot answer")
	assert_false(_log_text(e2).contains("Attack of opportunity by"), "and no reaction is rolled")


func test_improved_unarmed_strike_does_not_provoke() -> void:
	var sera := _unarmed_sera()
	sera.feats.append("Improved Unarmed Strike")
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen], [Vector2i(2, 3)], [Vector2i(3, 3)])
	e.attack_active(int(e.entry_for(kaelen)["index"]))
	assert_false(_log_text(e).contains("attacks unarmed and provokes"), "the armed unarmed attack provokes nothing")
	assert_false(_log_text(e).contains("Attack of opportunity by"), "no reaction is rolled")


func test_nonlethal_damage_survives_a_save_round_trip() -> void:
	var sera := _unarmed_sera()
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen], [Vector2i(2, 3)], [Vector2i(3, 3)])
	e.attack_active(int(e.entry_for(kaelen)["index"]))
	var saved := Character.from_dict(kaelen.to_dict(), content.items)
	assert_eq(saved.nonlethal, kaelen.nonlethal, "nonlethal damage is persisted")
	assert_eq(saved.hp, kaelen.hp, "and hit points are still separate")


func test_empty_hands_still_do_not_threaten_while_attacking() -> void:
	var sera := _unarmed_sera()
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen], [Vector2i(2, 3)], [Vector2i(3, 3)])
	assert_true(e.threat_capability(sera).is_empty(), "attacking unarmed is not an armed state")
	assert_false(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "no threatened square")
