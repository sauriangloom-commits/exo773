extends GutTest

## Bull rush, player-initiated only (PHB p. 154; SRD Combat, Special Attacks).
##
## The printed sequence is: declaring the standard action moves the rusher into
## the defender's space and provokes from every threatening opponent, then both
## sides make opposed Strength checks, and a win pushes the defender 5 ft plus
## 5 ft per full 5 points of excess while a loss sends the rusher back to his own
## square. The blocked-square and entry-movement details are recorded as
## adaptations in docs/ADAPTATION_LOG.md, not as printed rules.

const OPEN_ROWS := [
	"#########",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#########",
]

const WALL_BEHIND_ROWS := [
	"#########",
	"#.......#",
	"#.......#",
	"#....#..#",
	"#.......#",
	"#.......#",
	"#########",
]

const RUSHER_CELL := Vector2i(2, 3)
const TARGET_CELL := Vector2i(3, 3)

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


func _map(rows: Array = OPEN_ROWS) -> BattleMap:
	return BattleMap.from_rows(rows, "bull_rush_test")


func _encounter(
	party: Array,
	monsters: Array,
	party_cells: Array,
	monster_cells: Array,
	rows: Array = OPEN_ROWS
) -> Encounter:
	var e := Encounter.new()
	e.setup(party, monsters, _map(rows), rng, party_cells, monster_cells, content.spells, "Bull rush")
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


## One full attempt, rebuilt from content so nothing leaks between seeds.
func _attempt(
	seed_value: int,
	rows: Array,
	party_cells: Array,
	monster_cells: Array,
	tweak := Callable()
) -> Dictionary:
	rng.seed = seed_value
	var party: Array = []
	var monsters: Array = []
	for id in ["kaelen", "sera"]:
		if party_cells.size() > party.size():
			party.append(_char(id))
	monsters.append(_monster("zombie"))
	var e := _encounter(party, monsters, party_cells, monster_cells, rows)
	var ch: Character = party[0]
	var target: Character = monsters[0]
	_force_turn(e, ch)
	if tweak.is_valid():
		tweak.call(e, ch, target)
	var target_index := party.size()
	var result: Dictionary = e.bull_rush_active(target_index)
	return {"e": e, "ch": ch, "target": target, "result": result, "seed": seed_value}


## Finds the first seed whose attempt satisfies `cond`, so tests never depend on
## a lucky roll. The searched seed is printed on failure to keep it reproducible.
func _first_seed(
	cond: Callable,
	rows: Array = OPEN_ROWS,
	party_cells: Array = [RUSHER_CELL],
	monster_cells: Array = [TARGET_CELL],
	tweak := Callable()
) -> Dictionary:
	for seed_value in range(1, 300):
		var attempt := _attempt(seed_value, rows, party_cells, monster_cells, tweak)
		if bool(cond.call(attempt)):
			return attempt
	fail_test("no seed in 1..299 produced the required bull rush outcome")
	return {}


# ---------------------------------------------------------------- geometry

func test_push_chain_collects_legal_cells_in_a_clear_corridor() -> void:
	var e := _encounter([_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL])
	var chain: Dictionary = e._push_chain(TARGET_CELL, Vector2i(1, 0), 3, {})
	assert_eq(chain["cells"], [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3)])
	assert_eq(String(chain["stopped_by"]), "", "nothing stopped the chain")


func test_push_chain_stops_at_a_wall() -> void:
	var e := _encounter(
		[_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL], WALL_BEHIND_ROWS
	)
	var chain: Dictionary = e._push_chain(TARGET_CELL, Vector2i(1, 0), 3, {})
	assert_eq(chain["cells"], [Vector2i(4, 3)], "the wall ends the chain after one cell")
	assert_eq(String(chain["stopped_by"]), "wall")


func test_push_chain_stops_at_an_occupied_square() -> void:
	var e := _encounter([_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL])
	var chain: Dictionary = e._push_chain(TARGET_CELL, Vector2i(1, 0), 3, {Vector2i(5, 3): true})
	assert_eq(chain["cells"], [Vector2i(4, 3)])
	assert_eq(String(chain["stopped_by"]), "occupied")


func test_push_chain_stops_at_the_map_edge() -> void:
	var open_rows := [".........", ".........", ".........", ".........", ".........", ".........", "........."]
	var e := _encounter(
		[_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL], open_rows
	)
	var chain: Dictionary = e._push_chain(Vector2i(5, 3), Vector2i(1, 0), 5, {})
	assert_eq(chain["cells"], [Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3)])
	assert_eq(String(chain["stopped_by"]), "edge")


# ---------------------------------------------------------------- the push

func test_a_won_check_pushes_five_feet_and_takes_the_square() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and String(a["result"].get("pending", "")) == ""
	)
	assert_false(attempt.is_empty(), "a winnable seed without a follow offer exists")
	var e: Encounter = attempt["e"]
	var ch: Character = attempt["ch"]
	var target: Character = attempt["target"]
	var result: Dictionary = attempt["result"]
	assert_eq(String(result["opposed"]["winner"]), "attacker")
	assert_eq(int(result["excess"]), int(result["opposed"]["attacker_total"]) - int(result["opposed"]["defender_total"]))
	assert_eq(int(result["pushed_ft"]), 5, "a minimal win pushes 5 ft")
	assert_eq(Vector2i(e.combatants[1]["cell"]), Vector2i(4, 3), "defender moved one square")
	assert_eq(Vector2i(e.combatants[0]["cell"]), TARGET_CELL, "rusher took the vacated square")
	assert_true(bool(e.turn_state["standard_used"]), "the standard action is spent")
	assert_eq(int(e.turn_state["moved_ft"]), 5, "the entry step costs 5 ft")
	assert_true(str(e.get_log_text()).contains("bull rushes"), "the log names the action")


func test_extra_push_is_five_feet_per_five_points() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return (
				bool(a["result"].get("ok", false))
				and String(a["result"].get("pending", "")) == "follow"
				and int(a["result"]["excess"]) >= 15
			)
	)
	assert_false(attempt.is_empty(), "a seed with at least 15 points of excess exists")
	var e: Encounter = attempt["e"]
	var result: Dictionary = attempt["result"]
	var excess := int(result["excess"])
	assert_eq(
		int(result["push_ft"]),
		5 + 5 * (excess / 5),
		"5 ft plus 5 ft per full 5 points of excess"
	)
	var resolved: Dictionary = e.resolve_bull_rush_decision(true)
	assert_true(bool(resolved["ok"]), String(resolved.get("message", "")))
	assert_eq(int(resolved["pushed_ft"]), int(result["push_ft"]), "the offered distance is the pushed distance")


func test_the_follow_is_capped_by_remaining_movement() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and int(a["result"]["excess"]) >= 15,
		OPEN_ROWS,
		[RUSHER_CELL],
		[TARGET_CELL],
		func(e: Encounter, _ch: Character, _target: Character) -> void:
			e.turn_state["moved_ft"] = 25
	)
	assert_false(attempt.is_empty(), "a capped attempt exists")
	var result: Dictionary = attempt["result"]
	assert_eq(int(result["pushed_ft"]), 5, "only the 5-ft push fits the remaining 5 ft")
	assert_eq(String(result.get("pending", "")), "", "no follow decision when no follow is possible")
	assert_true(str(attempt["e"].get_log_text()).contains("movement left"))


func test_a_wall_stops_the_push() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and int(a["result"]["excess"]) >= 10,
		WALL_BEHIND_ROWS
	)
	var result: Dictionary = attempt["result"]
	assert_eq(int(result["pushed_ft"]), 5, "the wall limits the push to the first square")
	assert_eq(String(result["stopped_by"]), "wall")
	assert_true(str(attempt["e"].get_log_text()).contains("stopped by the wall"))


func test_an_occupied_square_stops_the_push() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and int(a["result"]["excess"]) >= 15,
		OPEN_ROWS,
		[RUSHER_CELL, Vector2i(6, 3)],
		[TARGET_CELL]
	)
	assert_false(attempt.is_empty(), "an attempt with an ally behind the defender exists")
	var e: Encounter = attempt["e"]
	var result: Dictionary = attempt["result"]
	assert_eq(String(result["stopped_by"]), "occupied", "the ally's square ends the push")
	var resolved: Dictionary = e.resolve_bull_rush_decision(true)
	assert_true(bool(resolved["ok"]), String(resolved.get("message", "")))
	assert_eq(int(resolved["pushed_ft"]), 10, "the push stops one square short of the ally")


func test_no_space_behind_the_defender_is_refused_before_the_roll() -> void:
	var e := _encounter(
		[_char("kaelen"), _char("sera")], [_monster("zombie")],
		[RUSHER_CELL, Vector2i(4, 3)], [TARGET_CELL]
	)
	var ch: Character = e.combatants[0]["char"]
	_force_turn(e, ch)
	var before := int(e.turn_state["moved_ft"])
	var result: Dictionary = e.bull_rush_active(2)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("no space behind"))
	assert_false(bool(e.turn_state["standard_used"]), "a refused rush spends nothing")
	assert_eq(int(e.turn_state["moved_ft"]), before)


func test_a_spent_standard_action_is_refused() -> void:
	var e := _encounter([_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL])
	var ch: Character = e.combatants[0]["char"]
	_force_turn(e, ch)
	e.turn_state["standard_used"] = true
	var result: Dictionary = e.bull_rush_active(1)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("standard action"))


func test_no_movement_left_is_refused() -> void:
	var e := _encounter([_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL])
	var ch: Character = e.combatants[0]["char"]
	_force_turn(e, ch)
	e.turn_state["moved_ft"] = ch.speed_ft
	var result: Dictionary = e.bull_rush_active(1)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("movement"))
	assert_false(bool(e.turn_state["standard_used"]))


func test_a_defender_two_size_categories_larger_is_refused() -> void:
	var e := _encounter([_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL])
	var ch: Character = e.combatants[0]["char"]
	var target: Character = e.combatants[1]["char"]
	_force_turn(e, ch)
	target.size_category = "huge"
	var result: Dictionary = e.bull_rush_active(1)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("too large to bull rush"))
	assert_false(bool(e.turn_state["standard_used"]))


# ---------------------------------------------------------------- the check

func test_size_modifiers_are_four_per_category_from_medium() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("ok", false)),
		OPEN_ROWS,
		[RUSHER_CELL],
		[TARGET_CELL],
		func(_e: Encounter, ch: Character, _target: Character) -> void:
			ch.size_category = "small"
	)
	var opposed: Dictionary = attempt["result"]["opposed"]
	var ch: Character = attempt["ch"]
	var target: Character = attempt["target"]
	var expected_attacker := (
		Rules.ability_modifier(ch, "str") + 4 * Rules.size_category_steps(ch.size_category)
	)
	var expected_defender := (
		Rules.ability_modifier(target, "str")
		+ 4 * Rules.size_category_steps(target.size_category)
		+ target.stability_bonus
	)
	assert_eq(int(opposed["attacker_modifier"]), expected_attacker)
	assert_eq(int(opposed["defender_modifier"]), expected_defender)
	assert_eq(int(opposed["attacker_modifier"]) - Rules.ability_modifier(ch, "str"), -4)
	assert_eq(int(opposed["defender_modifier"]) - Rules.ability_modifier(target, "str"), 0)


func test_a_stable_defender_adds_four() -> void:
	var plain := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("ok", false))
	)
	var stable := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("ok", false)),
		OPEN_ROWS,
		[RUSHER_CELL],
		[TARGET_CELL],
		func(_e: Encounter, _ch: Character, target: Character) -> void:
			target.stability_bonus = 4
	)
	assert_eq(int(stable["result"]["opposed"]["defender_modifier"]), int(plain["result"]["opposed"]["defender_modifier"]) + 4)


func test_the_defender_makes_an_opportunity_attack_on_entry() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and bool(a["e"].aoo_used.get(1, false)),
		OPEN_ROWS,
		[RUSHER_CELL],
		[TARGET_CELL],
		func(e: Encounter, _ch: Character, _target: Character) -> void:
			# A defender that has not yet acted is flat-footed and cannot react.
			e.flat_footed.clear()
	)
	assert_false(attempt.is_empty(), "a seed where the defender's reaction resolves exists")
	assert_true(bool(attempt["e"].aoo_used.get(1, false)), "the defender's reaction is consumed")
	assert_true(str(attempt["e"].get_log_text()).contains("Attack of opportunity"))


func test_an_opportunity_attack_that_drops_the_rusher_ends_the_push() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			var ch: Character = a["ch"]
			var result: Dictionary = a["result"]
			var stopped := not bool(result.get("ok", false)) or bool(result.get("interrupted", false))
			return stopped and (ch.has_condition("dying") or ch.has_condition("dead")),
		OPEN_ROWS,
		[RUSHER_CELL],
		[TARGET_CELL],
		func(e: Encounter, ch: Character, _target: Character) -> void:
			ch.hp = 1
			e.flat_footed.clear()
	)
	assert_false(attempt.is_empty(), "a seed where the reaction drops the rusher exists")
	var e: Encounter = attempt["e"]
	assert_eq(Vector2i(e.combatants[0]["cell"]), RUSHER_CELL, "the dropped rusher never moved")
	assert_eq(Vector2i(e.combatants[1]["cell"]), TARGET_CELL, "the defender is not pushed")
	assert_true(bool(e.turn_state["standard_used"]), "the declared action is still spent")


# ---------------------------------------------------------------- failure

func test_a_lost_check_costs_the_action_and_leaves_the_rusher_where_he_stood() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and String(a["result"]["opposed"]["winner"]) == "defender"
	)
	assert_false(attempt.is_empty(), "a seed where the check is lost exists")
	var e: Encounter = attempt["e"]
	assert_eq(Vector2i(e.combatants[0]["cell"]), RUSHER_CELL)
	assert_eq(Vector2i(e.combatants[1]["cell"]), TARGET_CELL)
	assert_true(bool(e.turn_state["standard_used"]))
	assert_true(str(e.get_log_text()).contains("staggers back"))


func test_a_lost_check_falls_prone_when_the_starting_square_is_occupied() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and String(a["result"]["opposed"]["winner"]) == "defender",
		OPEN_ROWS,
		[RUSHER_CELL],
		[TARGET_CELL],
		func(e: Encounter, ch: Character, target: Character) -> void:
			# A third creature standing where the rusher began makes the printed
			# fall-back square illegal; the printed consequence is falling prone.
			var blocker: Character = Character.from_content(content.get_character("mira"), content.items)
			e.combatants.append(
				{"index": 2, "team": Encounter.TEAM_PARTY, "char": blocker, "cell": RUSHER_CELL}
			)
	)
	assert_false(attempt.is_empty())
	var ch: Character = attempt["ch"]
	assert_true(ch.is_prone(), "an occupied fall-back square leaves the rusher prone")
	assert_true(str(attempt["e"].get_log_text()).contains("falls prone"))


# ---------------------------------------------------------------- decisions

func test_declining_the_follow_pushes_only_five_feet() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and String(a["result"].get("pending", "")) == "follow"
	)
	assert_false(attempt.is_empty(), "a follow decision is offered when the excess allows it")
	var e: Encounter = attempt["e"]
	assert_true(e.has_pending_decision(), "the follow decision blocks other actions")
	var before := Vector2i(e.combatants[1]["cell"])
	var resolved: Dictionary = e.resolve_bull_rush_decision(false)
	assert_true(bool(resolved["ok"]), String(resolved.get("message", "")))
	assert_false(e.has_pending_decision(), "the decision is cleared")
	assert_eq(Vector2i(e.combatants[1]["cell"]), before + Vector2i(1, 0))
	assert_eq(Vector2i(e.combatants[0]["cell"]), before, "the rusher takes the vacated square")


func test_following_pushes_the_full_distance_and_moves_the_rusher() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and String(a["result"].get("pending", "")) == "follow"
	)
	assert_false(attempt.is_empty())
	var e: Encounter = attempt["e"]
	var push_ft := int(e.pending_bull_rush["push_ft"])
	var resolved: Dictionary = e.resolve_bull_rush_decision(true)
	assert_true(bool(resolved["ok"]), String(resolved.get("message", "")))
	assert_eq(int(resolved["pushed_ft"]), push_ft)
	assert_eq(Vector2i(e.combatants[1]["cell"]), TARGET_CELL + Vector2i(push_ft / 5, 0))
	assert_eq(Vector2i(e.combatants[0]["cell"]), TARGET_CELL + Vector2i(push_ft / 5 - 1, 0))
	assert_eq(int(e.turn_state["moved_ft"]), push_ft, "entry plus follow steps draw on movement")


func test_the_follow_decision_voids_when_the_turn_changes() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return bool(a["result"].get("ok", false)) and String(a["result"].get("pending", "")) == "follow"
	)
	assert_false(attempt.is_empty())
	var e: Encounter = attempt["e"]
	var target_before := Vector2i(e.combatants[1]["cell"])
	var rusher_before := Vector2i(e.combatants[0]["cell"])
	e.turn_ptr = (e.turn_ptr + 1) % e.order.size()
	var resolved: Dictionary = e.resolve_bull_rush_decision(true)
	assert_false(bool(resolved["ok"]))
	assert_true(str(resolved["message"]).contains("no longer belongs"))
	assert_true(str(e.get_log_text()).contains("void"))
	assert_false(e.has_pending_decision())
	assert_eq(Vector2i(e.combatants[1]["cell"]), target_before)
	assert_eq(Vector2i(e.combatants[0]["cell"]), rusher_before)


func test_a_pending_cleave_blocks_a_bull_rush() -> void:
	var e := _encounter([_char("kaelen")], [_monster("zombie")], [RUSHER_CELL], [TARGET_CELL])
	var ch: Character = e.combatants[0]["char"]
	_force_turn(e, ch)
	e.pending_cleave = {"type": "cleave", "actor_index": 0, "dropped_index": 1}
	var result: Dictionary = e.bull_rush_active(1)
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("pending combat decision"))


func test_a_bull_rush_does_not_commit_the_defensive_stances() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("ok", false)),
		OPEN_ROWS,
		[RUSHER_CELL],
		[TARGET_CELL],
		func(e: Encounter, ch: Character, _target: Character) -> void:
			e.fight_defensively_selected[0] = true
			e.combat_expertise_pending[0] = {}
	)
	assert_false(attempt.is_empty())
	var e: Encounter = attempt["e"]
	var ch: Character = attempt["ch"]
	assert_false(e.fight_defensively_selected.has(0), "the selection expires without an attack")
	assert_false(e.combat_expertise_pending.has(0), "a pending Combat Expertise declaration expires")
	assert_false(ch.has_effect("fighting_defensively"), "no stance activates")
	assert_false(ch.has_effect("combat_expertise"), "no Combat Expertise activates")
