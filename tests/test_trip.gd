extends GutTest

## Prone recovery and (later) Trip. Expected behaviour comes from the PHB:
## standing up is a move action that provokes attacks of opportunity and the
## character is still prone while that reaction resolves (pp.143, 159;
## Table 8-6 on p.151 for the AC the reaction uses).

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 771


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
	party: Array, monsters: Array, party_cell := Vector2i(2, 3), monster_cell := Vector2i(3, 3)
) -> Encounter:
	var party_cells: Array = []
	var monster_cells: Array = []
	for i in party.size():
		party_cells.append(Vector2i(party_cell.x + i, party_cell.y))
	for i in monsters.size():
		monster_cells.append(Vector2i(monster_cell.x, monster_cell.y + i))
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


func test_standing_up_is_a_move_action_that_ends_prone() -> void:
	var kaelen := _char("kaelen")
	var e := _encounter([kaelen], [_monster("zombie")])
	_force_turn(e, kaelen)
	kaelen.set_prone(true)
	var result := e.stand_up_active()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_false(kaelen.is_prone(), "standing up clears prone")
	assert_true(bool(e.turn_state["move_used"]), "standing up spends the move action")
	assert_false(bool(e.turn_state["standard_used"]), "standing up does not spend the standard action")
	assert_eq(e.active_character(), kaelen, "standing up does not end the turn")


## The reaction must resolve against the prone AC (17 - 4 = 13) and the
## character only stands if it survives that reaction.
func test_standing_up_provokes_an_opportunity_attack_while_still_prone() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([kaelen], [zombie])
	# The zombie must have taken its first turn: a flat-footed creature cannot
	# make attacks of opportunity (PHB p.133).
	_force_turn(e, zombie)
	_force_turn(e, kaelen)
	kaelen.set_prone(true)
	var result := e.stand_up_active()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var opportunity := -1
	var feet := -1
	for i in e.log_lines.size():
		var line := String(e.log_lines[i])
		if opportunity < 0 and line.contains("vs AC"):
			opportunity = i
			assert_true(
				line.contains("vs AC 13"),
				"the reaction uses the prone AC of 13, not the standing AC of 17: %s" % line
			)
		if feet < 0 and line.contains("back on their feet"):
			feet = i
	assert_true(opportunity >= 0, "an adjacent enemy threatens the standing character")
	assert_true(feet > opportunity, "prone is cleared only after the reaction resolves")
	assert_false(kaelen.is_prone())


func test_standing_up_requires_prone_and_an_unused_move_action() -> void:
	var kaelen := _char("kaelen")
	var e := _encounter([kaelen], [_monster("zombie")])
	_force_turn(e, kaelen)
	assert_false(bool(e.stand_up_active()["ok"]), "a standing character cannot stand up")

	kaelen.set_prone(true)
	assert_true(bool(e.stand_up_active()["ok"]))
	# The move action is spent, so a second attempt in the same turn is refused
	# even if the character is prone again.
	kaelen.set_prone(true)
	var again := e.stand_up_active()
	assert_false(bool(again["ok"]))
	assert_true(String(again["message"]).contains("move action"))
	assert_true(kaelen.is_prone(), "the refused action changes nothing")


## `target_has_acted` lets the defender's first turn begin, which ends its
## combat-start flat-footed state (PHB p.133) so that reactions the target makes
## can be exercised. Without it the target is still flat-footed and, correctly,
## cannot make attacks of opportunity.
func _trip_setup(attacker_str := 16, target_ac_misc := -30, target_has_acted := false) -> Array:
	var kaelen := _char("kaelen")
	kaelen.abilities["str"] = attacker_str
	var zombie := _monster("zombie")
	zombie.ac_misc = target_ac_misc
	var e := _encounter([kaelen], [zombie])
	_force_turn(e, kaelen)
	if target_has_acted:
		_force_turn(e, zombie)
		_force_turn(e, kaelen)
	return [e, kaelen, zombie]


func test_trip_rejects_a_target_more_than_one_size_larger() -> void:
	var fixture := _trip_setup()
	var e: Encounter = fixture[0]
	var zombie: Character = fixture[2]
	zombie.size_category = "huge"
	zombie.size_ac = Rules.size_modifier("huge")
	var result := e.trip_active(1)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("too large"))
	assert_false(bool(e.turn_state["standard_used"]), "a refused trip spends nothing")


func test_trip_respects_explicit_immunity_and_reach() -> void:
	var fixture := _trip_setup()
	var e: Encounter = fixture[0]
	var zombie: Character = fixture[2]
	zombie.trip_immune = true
	var immune := e.trip_active(1)
	assert_false(bool(immune["ok"]))
	assert_true(String(immune["message"]).contains("cannot be tripped"))

	zombie.trip_immune = false
	var far := _encounter([fixture[1]], [zombie], Vector2i(1, 3), Vector2i(7, 3))
	_force_turn(far, fixture[1])
	var out_of_reach := far.trip_active(1)
	assert_false(bool(out_of_reach["ok"]))
	assert_true(String(out_of_reach["message"]).contains("reach"))


## PHB p.158: an unarmed trip provokes from the target before the touch attack.
func test_unarmed_trip_provokes_the_target_before_the_touch_attack() -> void:
	for seed_value in range(1, 12):
		rng.seed = seed_value
		var fixture := _trip_setup(16, -30, true)
		var e: Encounter = fixture[0]
		var result: Dictionary = e.trip_active(1)
		if not bool(result.get("hit", false)):
			continue
		var opportunity := -1
		var touch := -1
		for i in e.log_lines.size():
			var line := String(e.log_lines[i])
			if opportunity < 0 and line.contains("Attack of opportunity"):
				opportunity = i
			if touch < 0 and line.contains("trip touch attack"):
				touch = i
		assert_true(opportunity >= 0, "the target's opportunity attack is logged")
		assert_true(touch > opportunity, "the reaction resolves before the touch attack")
		assert_true(bool(e.turn_state["standard_used"]))
		return
	fail_test("no seed produced a successful touch attack")


func test_successful_trip_knocks_the_defender_prone() -> void:
	for seed_value in range(1, 30):
		rng.seed = seed_value
		var fixture := _trip_setup()
		var e: Encounter = fixture[0]
		var zombie: Character = fixture[2]
		var result: Dictionary = e.trip_active(1)
		if not bool(result.get("trip_success", false)):
			continue
		assert_true(zombie.is_prone(), "a won opposed check trips the defender")
		assert_true(bool(e.turn_state["standard_used"]))
		return
	fail_test("no seed produced a successful trip")


## PHB p.159: only listed weapons make a weapon trip, and it does not provoke.
func test_only_listed_trip_weapons_can_make_a_weapon_trip() -> void:
	var fixture := _trip_setup()
	var e: Encounter = fixture[0]
	var kaelen: Character = fixture[1]
	var refused := e.trip_active(1, {"use_weapon": true})
	assert_false(bool(refused["ok"]), "a longsword is not a trip weapon")
	assert_true(String(refused["message"]).contains("not a trip weapon"))
	assert_false(bool(e.turn_state["standard_used"]) )

	kaelen.equip("weapon", content.items["light_flail"])
	var armed := e.trip_active(1, {"use_weapon": true})
	assert_true(bool(armed["ok"]), String(armed.get("message", "")))
	for line in e.log_lines:
		assert_false(
			String(line).contains("Attack of opportunity"), "a weapon trip does not provoke"
		)


## PHB p.159: a tripped weapon user may drop the weapon to avoid being tripped.
func test_a_tripped_weapon_user_may_drop_the_weapon_and_stay_standing() -> void:
	var found := false
	for seed_value in range(1, 60):
		rng.seed = seed_value
		var kaelen := _char("kaelen")
		kaelen.abilities["str"] = 1
		kaelen.equip("weapon", content.items["light_flail"])
		var zombie := _monster("zombie")
		zombie.ac_misc = -30
		var e: Encounter = _encounter([kaelen], [zombie])
		_force_turn(e, kaelen)
		var result: Dictionary = e.trip_active(1, {"use_weapon": true, "release_weapon": true})
		if not bool(result.get("weapon_dropped", false)):
			continue
		found = true
		assert_false(kaelen.is_prone(), "dropping the weapon avoids being tripped")
		assert_true(kaelen.equipped("weapon").is_empty(), "the weapon is no longer equipped")
		assert_eq(kaelen.inventory_count("light_flail"), 0, "a dropped weapon is not also in the inventory")
		assert_eq(e.ground_items.size(), 1, "the weapon is on the ground exactly once")
		assert_eq(String(e.ground_items[0]["id"]), "light_flail")
		assert_eq(Vector2i(e.ground_items[0]["cell"]), Vector2i(2, 3))
		break
	assert_true(found, "a lost opposed check and counter-trip should occur in the sample")


func test_a_counter_trip_trips_the_attacker_when_the_weapon_is_kept() -> void:
	var found := false
	for seed_value in range(1, 60):
		rng.seed = seed_value
		var kaelen := _char("kaelen")
		kaelen.abilities["str"] = 1
		kaelen.equip("weapon", content.items["light_flail"])
		var zombie := _monster("zombie")
		zombie.ac_misc = -30
		var e: Encounter = _encounter([kaelen], [zombie])
		_force_turn(e, kaelen)
		var result: Dictionary = e.trip_active(1, {"use_weapon": true, "release_weapon": false})
		if not bool(result.get("countered", false)):
			continue
		found = true
		assert_true(kaelen.is_prone(), "the attacker is tripped by the counter-trip")
		assert_false(kaelen.equipped("weapon").is_empty(), "the weapon is retained")
		assert_eq(kaelen.inventory_count("light_flail"), 0)
		break
	assert_true(found, "a counter-trip should occur in the seeded sample")


## A weapon-release choice belongs to the acting player: resolution pauses with
## all rolls final, and no other action can be taken until it is answered.
func test_a_weapon_release_decision_pauses_then_resumes_without_rerolling() -> void:
	var found := false
	for seed_value in range(1, 80):
		rng.seed = seed_value
		var kaelen := _char("kaelen")
		kaelen.abilities["str"] = 1
		kaelen.equip("weapon", content.items["light_flail"])
		var zombie := _monster("zombie")
		zombie.ac_misc = -30
		var e := _encounter([kaelen], [zombie])
		_force_turn(e, kaelen)
		var result: Dictionary = e.trip_active(1, {"use_weapon": true})
		if String(result.get("pending", "")) != "weapon_release":
			continue
		found = true
		assert_true(e.has_pending_decision())
		assert_false(kaelen.is_prone(), "prone is not applied before the choice")
		assert_true(bool(e.turn_state["standard_used"]), "the action is spent once")
		assert_false(bool(e.attack_active(1)["ok"]), "no unrelated attack while pending")
		assert_false(bool(e.move_active_to(Vector2i(2, 2))["ok"]), "no movement while pending")
		var turn_before := e.turn_ptr
		e.end_turn()
		assert_eq(e.turn_ptr, turn_before, "the turn cannot advance while pending")
		var counter_logs := 0
		for line in e.log_lines:
			if String(line).contains("Counter-trip:"):
				counter_logs += 1
		var resolved: Dictionary = e.resolve_trip_decision(true)
		assert_true(bool(resolved["ok"]))
		assert_false(e.has_pending_decision())
		assert_false(kaelen.is_prone())
		assert_eq(e.ground_items.size(), 1)
		assert_false(bool(e.resolve_trip_decision(true)["ok"]), "a decision cannot be submitted twice")
		var after := 0
		for line in e.log_lines:
			if String(line).contains("Counter-trip:"):
				after += 1
		assert_eq(after, counter_logs, "resuming never rerolls the counter-trip")
		break
	assert_true(found, "a lost weapon trip should occur in the seeded sample")


func test_keeping_the_weapon_on_a_lost_counter_trip_trips_the_attacker() -> void:
	var found := false
	for seed_value in range(1, 80):
		rng.seed = seed_value
		var kaelen := _char("kaelen")
		kaelen.abilities["str"] = 1
		kaelen.equip("weapon", content.items["light_flail"])
		var zombie := _monster("zombie")
		zombie.ac_misc = -30
		var e := _encounter([kaelen], [zombie])
		_force_turn(e, kaelen)
		var result: Dictionary = e.trip_active(1, {"use_weapon": true})
		if String(result.get("pending", "")) != "weapon_release":
			continue
		found = true
		e.resolve_trip_decision(false)
		assert_true(kaelen.is_prone())
		assert_false(kaelen.equipped("weapon").is_empty(), "the weapon is kept")
		assert_eq(e.ground_items.size(), 0)
		break
	assert_true(found, "a lost weapon trip should occur in the seeded sample")


## Pick up: move action, provokes, and the item moves to the inventory
## unequipped (PHB Table 8-2 p.141).
func test_pick_up_costs_a_move_action_and_provokes() -> void:
	var fixture := _trip_setup(16, -30, true)
	var e: Encounter = fixture[0]
	var kaelen: Character = fixture[1]
	assert_true(e._drop_weapon(kaelen))
	var result: Dictionary = e.pick_up_active(0)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(e.turn_state["move_used"]))
	assert_eq(e.ground_items.size(), 0, "the item left the ground")
	assert_eq(kaelen.inventory_count("masterwork_longsword"), 1)
	assert_true(kaelen.equipped("weapon").is_empty(), "picking up does not equip")
	var provoked := false
	for line in e.log_lines:
		if String(line).contains("Attack of opportunity"):
			provoked = true
	assert_true(provoked, "picking up an item provokes")
	assert_false(bool(e.pick_up_active(0)["ok"]), "there is nothing left to pick up")


func test_pick_up_requires_the_items_square() -> void:
	var fixture := _trip_setup()
	var e: Encounter = fixture[0]
	e.ground_items.append(
		{"id": "dagger", "item": content.items["dagger"], "cell": Vector2i(7, 5)}
	)
	var result: Dictionary = e.pick_up_active(0)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("square"))
	assert_eq(e.ground_items.size(), 1)


func test_an_interrupted_pickup_leaves_the_item_on_the_ground() -> void:
	var found := false
	for seed_value in range(1, 40):
		rng.seed = seed_value
		var kaelen := _char("kaelen")
		kaelen.hp = 1
		var zombie := _monster("zombie")
		zombie.attacks[0]["attack_bonus"] = 50
		var e := _encounter([kaelen], [zombie])
		_force_turn(e, kaelen)
		e._drop_weapon(kaelen)
		e.pick_up_active(0)
		if kaelen.can_act():
			continue
		found = true
		assert_eq(e.ground_items.size(), 1, "the item stays on the ground")
		assert_eq(kaelen.inventory_count("masterwork_longsword"), 0, "no duplication into the inventory")
		break
	assert_true(found, "the boosted opportunity attack should drop the 1 HP picker")


func test_a_dropped_item_is_never_duplicated_and_can_be_collected() -> void:
	var fixture := _trip_setup()
	var e: Encounter = fixture[0]
	var kaelen: Character = fixture[1]
	assert_true(e._drop_weapon(kaelen))
	assert_false(e._drop_weapon(kaelen), "there is no second weapon to drop")
	assert_eq(e.ground_items.size(), 1)
	assert_eq(kaelen.inventory_count("masterwork_longsword"), 0)
	var recovered := e.collect_ground_items()
	assert_eq(recovered.size(), 1)
	assert_eq(e.ground_items.size(), 0, "recovery clears the ground list")
	assert_eq(kaelen.inventory_count("masterwork_longsword"), 0, "recovery does not double-add")


## PHB p.142: crawling is 5 feet as a move action and provokes; ordinary
## movement is refused while prone.
func test_prone_movement_is_limited_to_a_five_foot_crawl() -> void:
	var fixture := _trip_setup()
	var e: Encounter = fixture[0]
	var kaelen: Character = fixture[1]
	kaelen.set_prone(true)
	var far := e.move_active_to(Vector2i(2, 5))
	assert_false(bool(far["ok"]))
	assert_true(String(far["message"]).contains("crawl"))
	var crawl := e.move_active_to(Vector2i(2, 4))
	assert_true(bool(crawl["ok"]), String(crawl.get("message", "")))
	assert_true(bool(e.turn_state["move_used"]))
	assert_true(kaelen.is_prone(), "crawling does not end prone")
	assert_false(bool(e.move_active_to(Vector2i(2, 5), true)["ok"]), "no 5-foot step while prone")


func test_a_character_who_cannot_act_cannot_stand_up() -> void:
	var kaelen := _char("kaelen")
	var e := _encounter([kaelen], [_monster("zombie")])
	_force_turn(e, kaelen)
	kaelen.set_prone(true)
	kaelen.add_effect("paralyzed", "Paralyzed", 2)
	var result := e.stand_up_active()
	assert_false(bool(result["ok"]))
	assert_true(kaelen.is_prone(), "prone remains when the action cannot be taken")
	assert_false(bool(e.turn_state["move_used"]), "no action is spent when the action is refused")
