extends GutTest

## Opportunity-attack eligibility: a creature that cannot act must not take the
## reaction, even though `Character.can_act()` alone returns true for paralysis.
##
## Printed basis (d20srd.org/srd/conditionSummary.htm): "A paralyzed character is
## frozen in place and unable to move or act" and is helpless; a helpless character
## is paralyzed, held, bound, sleeping, unconscious or otherwise at an opponent's
## mercy. The SRD attack-of-opportunity page defines the reaction as a single melee
## attack, one per round, but does not itself repeat an "able to act" clause;
## treating the condition's action prohibition as an opportunity-attack eligibility
## gate is the project's interpretation, consistent with its existing flat-footed
## and total-defense gates.
##
## Seeded state: these fixtures add `paralyzed`, `unconscious` or `total_defense`
## directly so the provoking reaction is deterministic. The ordinary-play paralysis
## path is the ghoul's slam -> `_try_paralysis` -> failed Fortitude save, covered by
## `test_combat.gd::test_ghoul_paralysis_affects_humans_but_not_elves`; this file
## does not claim a natural encounter produced the seeded condition.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _kaelen() -> Character:
	var ch := Character.from_content(content.get_character("kaelen"), content.items)
	ch.id = "qa_aoo_kaelen"
	ch.display_name = "QA Kaelen"
	ch.max_hp = 100
	ch.hp = 100
	return ch


func _zombie() -> Character:
	var ch := Character.from_content(content.get_monster("zombie"), content.items)
	ch.id = "qa_aoo_zombie"
	ch.display_name = "QA Zombie"
	ch.max_hp = 100
	ch.hp = 100
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


func _encounter(kaelen: Character, zombie: Character) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = 771122
	var e := Encounter.new()
	e.setup(
		[kaelen],
		[zombie],
		_map(),
		rng,
		[Vector2i(2, 2)],
		[Vector2i(1, 2)],
		content.spells,
		"AoO eligibility"
	)
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	var index := int(e.entry_for(ch)["index"])
	e.turn_ptr = e.order.find(index)
	e._begin_turn(e.combatants[index])


func _aoo_index(e: Encounter, ch: Character) -> int:
	return int(e.entry_for(ch)["index"])


func _log_since(e: Encounter, before: int) -> String:
	return "\n".join(e.log_lines.slice(before))


func _move_out(e: Encounter, actor: Character) -> Dictionary:
	var before := e.log_lines.size()
	var result := e.move_active_to(Vector2i(3, 2))
	return {"result": result, "segment": _log_since(e, before)}


func test_paralyzed_enemy_does_not_make_an_opportunity_attack_on_movement() -> void:
	var kaelen := _kaelen()
	var zombie := _zombie()
	var e := _encounter(kaelen, zombie)
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	# Seeded paralysis, not a natural ghoul save in this fixture.
	zombie.add_effect("paralyzed", "Paralyzed", 2)
	assert_true(zombie.can_act(), "can_act() alone still reports true for paralysis")
	assert_true(Rules.is_helpless(zombie), "the condition is the printed helpless state")
	var hp_before := kaelen.hp
	var moved := _move_out(e, kaelen)
	assert_true(bool(moved["result"].get("ok", false)), String(moved["result"].get("message", "")))
	assert_false(
		String(moved["segment"]).to_lower().contains("attack of opportunity by"),
		"a paralyzed creature must not roll the reaction"
	)
	assert_false(
		bool(e.aoo_used.get(_aoo_index(e, zombie), false)),
		"a paralyzed creature must not consume a reaction"
	)
	assert_eq(kaelen.hp, hp_before, "no damage is dealt by an ineligible reaction")
	assert_eq(e.combatants[0]["cell"], Vector2i(3, 2), "the provoking move completes")
	assert_true(bool(e.turn_state["move_used"]), "the move action is spent")
	assert_false(bool(e.turn_state["standard_used"]), "the standard action is untouched")
	assert_eq(int(e.turn_state["moved_ft"]), 5, "the move is charged normally")


func test_conscious_enemy_makes_an_opportunity_attack_on_movement() -> void:
	var kaelen := _kaelen()
	var zombie := _zombie()
	var e := _encounter(kaelen, zombie)
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	var moved := _move_out(e, kaelen)
	assert_true(bool(moved["result"].get("ok", false)), String(moved["result"].get("message", "")))
	assert_true(
		String(moved["segment"]).to_lower().contains("attack of opportunity by"),
		"the positive control rolls the reaction"
	)
	assert_true(
		bool(e.aoo_used.get(_aoo_index(e, zombie), false)),
		"the conscious enemy consumes its reaction"
	)
	assert_eq(e.combatants[0]["cell"], Vector2i(3, 2), "the provoking move completes")
	assert_true(bool(e.turn_state["move_used"]), "the move action is spent")
	assert_false(bool(e.turn_state["standard_used"]), "the standard action is untouched")


func test_paralyzed_enemy_does_not_make_an_opportunity_attack_on_loading() -> void:
	var kaelen := _kaelen()
	kaelen.add_to_inventory(content.get_item("light_crossbow"))
	kaelen.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var zombie := _zombie()
	var e := _encounter(kaelen, zombie)
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	zombie.add_effect("paralyzed", "Paralyzed", 2)
	var before := e.log_lines.size()
	var loaded := e.load_weapon()
	var segment := _log_since(e, before)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_false(
		segment.to_lower().contains("attack of opportunity by"),
		"the single-opportunity path must also refuse a paralyzed creature"
	)
	assert_false(
		bool(e.aoo_used.get(_aoo_index(e, zombie), false)),
		"the single-opportunity path consumes no reaction"
	)
	assert_true(e.is_weapon_loaded(kaelen), "the loader completes the action")
	assert_true(bool(e.turn_state["move_used"]), "loading spends the move equivalent")
	assert_false(bool(e.turn_state["standard_used"]), "loading leaves the standard untouched")


func test_conscious_enemy_makes_an_opportunity_attack_on_loading() -> void:
	var kaelen := _kaelen()
	kaelen.add_to_inventory(content.get_item("light_crossbow"))
	kaelen.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var zombie := _zombie()
	var e := _encounter(kaelen, zombie)
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	var before := e.log_lines.size()
	var loaded := e.load_weapon()
	var segment := _log_since(e, before)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_true(segment.to_lower().contains("attack of opportunity by"), "the positive control reacts")
	assert_true(
		bool(e.aoo_used.get(_aoo_index(e, zombie), false)),
		"the conscious enemy consumes its reaction"
	)
	assert_true(e.is_weapon_loaded(kaelen), "the loader completes after the reaction")
	assert_true(bool(e.turn_state["move_used"]), "loading spends the move equivalent")
	assert_false(bool(e.turn_state["standard_used"]), "loading leaves the standard untouched")


func test_total_defense_enemy_does_not_make_an_opportunity_attack_on_movement() -> void:
	var kaelen := _kaelen()
	var zombie := _zombie()
	var e := _encounter(kaelen, zombie)
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	zombie.add_effect("total_defense", "Total Defense", 1)
	var moved := _move_out(e, kaelen)
	assert_true(bool(moved["result"].get("ok", false)), String(moved["result"].get("message", "")))
	assert_false(String(moved["segment"]).to_lower().contains("attack of opportunity by"), "total defense forbids the reaction")
	assert_true(String(moved["segment"]).contains("total defense"), "the existing refusal is explained")
	assert_false(bool(e.aoo_used.get(_aoo_index(e, zombie), false)), "the reaction is not consumed")


func test_unconscious_enemy_does_not_make_an_opportunity_attack_on_movement() -> void:
	var kaelen := _kaelen()
	var zombie := _zombie()
	var e := _encounter(kaelen, zombie)
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	zombie.add_effect("unconscious", "Unconscious", 2)
	var moved := _move_out(e, kaelen)
	assert_true(bool(moved["result"].get("ok", false)), String(moved["result"].get("message", "")))
	assert_false(String(moved["segment"]).to_lower().contains("attack of opportunity by"), "unconscious is already filtered")
	assert_false(bool(e.aoo_used.get(_aoo_index(e, zombie), false)), "no reaction is consumed")
