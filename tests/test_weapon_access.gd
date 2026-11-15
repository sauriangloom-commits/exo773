extends GutTest

## Weapon access in combat.
##
## PHB printed p. 142: "Drawing a weapon so that you can use it in combat ...
## requires a move action," and sheathing one is the same entry: "Draw or Sheathe
## a Weapon" is a move action either way. This build charges both separately, so a
## swap costs two move actions over two turns and is never cheaper than the page.
## The printed free draw combined with a regular move (base attack bonus +1) is not
## modelled, and a move action cannot be traded for a standard action here, which
## is recorded in ADAPTATIONS.
## PHB printed p. 115: "Loading a light crossbow is a move action that provokes
## attacks of opportunity" and "Normally, operating a light crossbow requires two
## hands." Bolts are drawn as a free action (p. 142), so ammunition is not
## tracked. The tests use the shipped rogue exactly as authored: short sword
## readied, light crossbow carried.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _sera() -> Character:
	var ch := Character.from_content(content.get_character("sera"), content.items)
	ch.id = "qa_sera"
	ch.display_name = "QA Sera"
	ch.max_hp = 40
	ch.hp = 40
	return ch


func _zombie(cell_name := "qa_zombie") -> Character:
	var ch := Character.from_content(content.get_monster("zombie"), content.items)
	ch.id = cell_name
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


func _encounter(party: Array, enemies: Array, party_cells: Array, enemy_cells: Array, seed := 112233) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var e := Encounter.new()
	e.setup(party, enemies, _map(), rng, party_cells, enemy_cells, content.spells, "Test")
	e.begin()
	for entry in e.combatants:
		for i in e.order:
			if e.combatants[i]["char"] == entry["char"]:
				e.turn_ptr = e.order.find(i)
				e._begin_turn(e.combatants[i])
				break
	_start_turn(e, party[0])
	return e


## Starts a fresh turn for `ch` without running anyone else's turn.
func _start_turn(e: Encounter, ch: Character) -> void:
	e.turn_ptr = e.order.find(int(e.entry_for(ch)["index"]))
	e._begin_turn(e.entry_for(ch))


## The printed switch is two move actions: sheathe, then draw on a later turn.
func _switch_to(e: Encounter, ch: Character, item_id: String) -> Dictionary:
	_start_turn(e, ch)
	var sheathed := e.sheathe_weapon()
	assert_true(bool(sheathed.get("ok", false)), String(sheathed.get("message", "")))
	_start_turn(e, ch)
	var drawn := e.draw_weapon(item_id)
	_start_turn(e, ch)
	return drawn


func _logs(e: Encounter, needle: String) -> bool:
	for line in e.log_lines:
		if String(line).contains(needle):
			return true
	return false


func test_shipped_rogue_carries_the_crossbow_but_has_the_short_sword_readied() -> void:
	var sera := _sera()
	var rows := sera.carried_weapons()
	var ids: Array = []
	for row in rows:
		ids.append(String(row["id"]))
	assert_true(ids.has("light_crossbow"), "the crossbow she carries is listed")
	assert_true(ids.has("short_sword"), "the readied sword is listed too")
	assert_eq(String(sera.equipment["weapon"]["id"]), "short_sword", "the sword stays readied")
	for row in rows:
		if String(row["id"]) == "light_crossbow":
			assert_false(bool(row["equipped"]), "the crossbow is carried, not readied")


func test_switching_weapons_costs_two_move_actions() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	var refused := e.draw_weapon("light_crossbow")
	assert_false(bool(refused["ok"]), "a readied weapon has to be put away first")
	assert_true(String(refused["message"]).contains("separate move action"), "the reason states the cost")
	assert_false(bool(e.turn_state["move_used"]), "the refusal spends nothing")
	assert_eq(String(sera.equipment["weapon"]["id"]), "short_sword", "nothing changed")
	var sheathed := e.sheathe_weapon()
	assert_true(bool(sheathed["ok"]), String(sheathed.get("message", "")))
	assert_true(bool(sheathed["spent_move"]), "sheathing spends the move action")
	assert_true(sera.equipment["weapon"].is_empty(), "the hand is empty")
	assert_eq(sera.inventory_count("short_sword"), 1, "the sword stays carried, not dropped")
	assert_true(_logs(e, "sheathes Short Sword (move action; PHB p.142)"), "the cost is logged")
	# PHB p.138: "You can take a move action in place of a standard action", so the
	# draw can still happen this turn, at the cost of the standard action.
	var same_turn := e.draw_weapon("light_crossbow")
	assert_true(bool(same_turn["ok"]), String(same_turn.get("message", "")))
	assert_true(bool(e.turn_state["standard_used"]), "the standard action stood in for the move")
	assert_eq(String(sera.equipment["weapon"]["id"]), "light_crossbow", "the crossbow is readied")
	assert_true(
		_logs(e, "draws Light Crossbow (standard action used as a move; PHB p.138, p.142)"),
		"the log names the slot actually spent",
	)
	var blocked := e.sheathe_weapon()
	assert_false(bool(blocked["ok"]), "no third move-equivalent exists in the turn")
	assert_true(String(blocked["message"]).contains("No move or standard action"), "the reason is explicit")
	assert_eq(String(sera.equipment["weapon"]["id"]), "light_crossbow", "nothing changed")


func test_unloaded_crossbow_cannot_be_fired_and_spends_nothing() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	_switch_to(e, sera, "light_crossbow")
	var hp_before := zombie.hp
	var result := e.attack_active(int(e.entry_for(zombie)["index"]), "ranged")
	assert_false(bool(result["ok"]), "an unloaded crossbow cannot fire")
	assert_true(String(result["message"]).contains("not loaded"), "the reason names loading")
	assert_false(bool(e.turn_state["standard_used"]), "no standard action is spent")
	assert_eq(zombie.hp, hp_before, "nothing is damaged")


func test_loading_costs_a_move_and_firing_spends_the_shot() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	_switch_to(e, sera, "light_crossbow")
	var loaded := e.load_weapon()
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_true(bool(loaded["spent_move"]), "loading spends the move action")
	assert_true(e.is_weapon_loaded(sera), "the crossbow is loaded")
	assert_true(_logs(e, "loads Light Crossbow (move action"), "the cost is logged")
	var before := e.log_lines.size()
	var attack := e.attack_active(int(e.entry_for(zombie)["index"]), "ranged")
	assert_true(bool(attack["ok"]), String(attack.get("message", "")))
	var segment := "\n".join(e.log_lines.slice(before))
	assert_true(segment.contains("Light Crossbow"), "the resolved weapon is the crossbow")
	assert_false(e.is_weapon_loaded(sera), "firing spends the shot")
	var again := e.attack_active(int(e.entry_for(zombie)["index"]), "ranged")
	assert_false(bool(again["ok"]), "a second shot needs another load")


func test_loading_provokes_when_threatened() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(2, 3)])
	_switch_to(e, sera, "light_crossbow")
	var before := e.log_lines.size()
	e.load_weapon()
	var segment := "\n".join(e.log_lines.slice(before))
	assert_true(segment.contains("loading a crossbow provokes"), "loading in reach provokes")
	assert_true(segment.contains("Attack of opportunity by"), "the reaction is rolled")
	assert_eq(
		e.is_weapon_loaded(sera), sera.can_act(), "loaded only if the reaction left her able to act"
	)


func test_loading_spends_the_standard_action_when_the_move_is_gone() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	_switch_to(e, sera, "light_crossbow")
	e.move_active_to(Vector2i(2, 3))
	var result := e.load_weapon()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(e.turn_state["standard_used"]), "the standard action stood in for the move")
	assert_true(e.is_weapon_loaded(sera), "the crossbow is loaded")
	assert_true(
		_logs(e, "loads Light Crossbow (standard action used as a move; PHB p.138, p.115"),
		"the log names the slot actually spent",
	)
	var shot := e.attack_active(int(e.entry_for(zombie)["index"]), "ranged")
	assert_false(bool(shot["ok"]), "firing still needs its own standard action")
	assert_true(e.is_weapon_loaded(sera), "the shot is not spent by the refused attack")


func test_two_handed_weapon_is_refused_while_a_shield_is_strapped_on() -> void:
	var sera := _sera()
	sera.equipment["shield"] = content.get_item("light_wooden_shield").duplicate(true)
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	assert_true(bool(e.sheathe_weapon()["ok"]), "the sword is put away first")
	_start_turn(e, sera)
	var result := e.draw_weapon("light_crossbow")
	assert_false(bool(result["ok"]), "a two-handed weapon cannot be readied with a shield")
	assert_true(String(result["message"]).contains("two hands"), "the reason names the hands")
	assert_true(sera.equipment["weapon"].is_empty(), "nothing was readied")
	assert_false(bool(e.turn_state["move_used"]), "no action was spent on a refusal")


func test_equipment_state_does_not_leak_between_characters() -> void:
	var sera := _sera()
	var kaelen := Character.from_content(content.get_character("kaelen"), content.items)
	kaelen.id = "qa_kaelen"
	kaelen.display_name = "QA Kaelen"
	var zombie := _zombie()
	var e := _encounter(
		[sera, kaelen], [zombie], [Vector2i(1, 3), Vector2i(1, 2)], [Vector2i(9, 3)]
	)
	_switch_to(e, sera, "light_crossbow")
	assert_eq(String(sera.equipment["weapon"]["id"]), "light_crossbow", "Sera drew her crossbow")
	assert_eq(
		String(kaelen.equipment["weapon"]["id"]), "masterwork_longsword", "Kaelen is unaffected"
	)
	_start_turn(e, kaelen)
	var result := e.draw_weapon("light_crossbow")
	assert_false(bool(result["ok"]), "Kaelen is not carrying that crossbow")


func test_returning_to_melee_after_firing() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	_switch_to(e, sera, "light_crossbow")
	e.load_weapon()
	e.attack_active(int(e.entry_for(zombie)["index"]), "ranged")
	var back := _switch_to(e, sera, "short_sword")
	assert_true(bool(back["ok"]), String(back.get("message", "")))
	assert_eq(String(sera.equipment["weapon"]["id"]), "short_sword", "the sword is readied again")
	assert_true(
		Rules.weapon_attack_modes(sera.equipment["weapon"]).has("melee"),
		"the readied weapon offers a melee attack",
	)


func test_a_loaded_crossbow_stays_loaded_while_it_is_put_away() -> void:
	var sera := _sera()
	var zombie := _zombie()
	zombie.max_hp = 100
	zombie.hp = 100
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	_switch_to(e, sera, "light_crossbow")
	assert_true(bool(e.load_weapon()["ok"]), String(e.last_message))
	_switch_to(e, sera, "short_sword")
	assert_eq(
		String(e.loaded_weapons.get(sera.id, "")),
		"light_crossbow",
		"the shot belongs to the crossbow, not to the character's hands",
	)
	_switch_to(e, sera, "light_crossbow")
	assert_true(e.is_weapon_loaded(sera), "the stowed crossbow is still loaded")
	var attack := e.attack_active(int(e.entry_for(zombie)["index"]), "ranged")
	assert_true(bool(attack["ok"]), String(attack.get("message", "")))
	assert_false(e.is_weapon_loaded(sera), "the shot is spent once")
	_switch_to(e, sera, "short_sword")
	_switch_to(e, sera, "light_crossbow")
	assert_false(e.is_weapon_loaded(sera), "putting it away and back cannot restore a spent shot")


func test_a_refused_attack_does_not_unload_the_weapon() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(1, 3)], [Vector2i(9, 3)])
	_switch_to(e, sera, "light_crossbow")
	assert_true(bool(e.load_weapon()["ok"]), String(e.last_message))
	e.turn_state["standard_used"] = true
	var refused := e.attack_active(int(e.entry_for(zombie)["index"]), "ranged")
	assert_false(bool(refused["ok"]), "no standard action remains")
	assert_true(String(refused["message"]).contains("standard action"), "the reason is explicit")
	assert_true(e.is_weapon_loaded(sera), "the refused attack left the crossbow loaded")
	assert_eq(zombie.hp, zombie.max_hp, "nothing was damaged")
