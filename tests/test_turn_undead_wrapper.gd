extends GutTest

## Regression coverage for the player-facing Turn Undead wrapper.
##
## Turn undead is a standard action (PHB p.159), so a pre-action refusal must
## leave the turn and every resource untouched, and a legal attempt must spend
## the standard action and one daily use without silently ending the player's
## turn (the move action still belongs to the player). The wrapper is the path
## the combat screen uses; `Encounter.turn_undead()` alone does not prove it.

var content: ContentDB
var rng: RandomNumberGenerator
var saved_party: Array = []
var saved_mode := ""
var saved_encounter: Encounter = null
var saved_data: Dictionary = {}


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 1207
	saved_party = Game.party.duplicate()
	saved_mode = Game.mode
	saved_encounter = Game.encounter
	saved_data = Game.active_encounter_data


func after_each() -> void:
	Game.party.clear()
	for ch in saved_party:
		Game.party.append(ch)
	Game.mode = saved_mode
	Game.encounter = saved_encounter
	Game.active_encounter_data = saved_data
	Game.last_ui_message = ""


func _cleric() -> Character:
	var ch := Character.from_content(content.get_character("aldric"), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _map(width := 12, height := 7) -> BattleMap:
	var rows: Array = []
	for y in height:
		var row := ""
		for x in width:
			var edge := y == 0 or y == height - 1 or x == 0 or x == width - 1
			row += "#" if edge else "."
		rows.append(row)
	return BattleMap.from_rows(rows, "turn undead wrapper")


func _encounter(
	party: Array, monsters: Array, party_cells: Array = [], monster_cells: Array = [], battle_map = null
) -> Encounter:
	var cells_party := party_cells.duplicate()
	var cells_monsters := monster_cells.duplicate()
	if cells_party.is_empty():
		for i in party.size():
			cells_party.append(Vector2i(1 + i, 5))
	if cells_monsters.is_empty():
		for i in monsters.size():
			cells_monsters.append(Vector2i(4, 1 + i))
	var e := Encounter.new()
	e.setup(
		party,
		monsters,
		battle_map if battle_map != null else _map(),
		rng,
		cells_party,
		cells_monsters,
		content.spells,
		"Turn undead wrapper"
	)
	e.begin()
	return e


func _index_of(e: Encounter, ch: Character) -> int:
	var entry := e.entry_for(ch)
	return int(entry["index"]) if not entry.is_empty() else -1


func _force_turn(e: Encounter, ch: Character) -> void:
	var index := _index_of(e, ch)
	assert_true(index >= 0, "the character is in the encounter")
	e.turn_ptr = e.order.find(index)
	e._begin_turn(e.combatants[index])


func _bind(e: Encounter, actor: Character) -> void:
	Game.encounter = e
	Game.mode = "combat"
	Game.party.clear()
	Game.party.append(actor)


func _state(e: Encounter, actor: Character) -> Dictionary:
	return {
		"pointer": e.turn_ptr,
		"round": e.round_number,
		"active": e.active_character(),
		"standard_used": bool(e.turn_state.get("standard_used", false)),
		"uses": actor.turn_undead_remaining(),
		"finished": e.finished,
		"grapples": e.grapples.size(),
	}


func _assert_state_unchanged(before: Dictionary, after: Dictionary, why: String) -> void:
	assert_eq(after["pointer"], before["pointer"], "turn pointer unchanged: " + why)
	assert_eq(after["round"], before["round"], "round unchanged: " + why)
	assert_eq(after["active"], before["active"], "same active creature: " + why)
	assert_eq(after["standard_used"], before["standard_used"], "no standard action spent: " + why)
	assert_eq(after["uses"], before["uses"], "no daily use spent: " + why)
	assert_eq(after["grapples"], before["grapples"], "the grapple state is unchanged: " + why)
	assert_false(bool(after["finished"]), "the encounter continues: " + why)


func test_grappled_cleric_refusal_keeps_the_turn_and_spends_nothing() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	e.grapples.append(
		{"holder": _index_of(e, ghoul), "held": _index_of(e, aldric), "pinned": false}
	)
	_bind(e, aldric)
	var before := _state(e, aldric)
	var result := Game.combat_turn_undead()
	assert_false(bool(result.get("ok", true)), "the grappled attempt is refused")
	assert_true(
		String(result.get("message", "")).contains("grappling"),
		"the refusal names the grapple: " + String(result.get("message", "")),
	)
	_assert_state_unchanged(before, _state(e, aldric), "grappled refusal")
	assert_eq(e.grapples.size(), 1, "the grapple survives a refusal")


func test_pinned_cleric_refusal_keeps_the_turn_and_spends_nothing() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	e.grapples.append(
		{"holder": _index_of(e, ghoul), "held": _index_of(e, aldric), "pinned": true}
	)
	_bind(e, aldric)
	var before := _state(e, aldric)
	var result := Game.combat_turn_undead()
	assert_false(bool(result.get("ok", true)), "the pinned attempt is refused")
	assert_true(
		String(result.get("message", "")).contains("pinned"),
		"the refusal names the pin: " + String(result.get("message", "")),
	)
	_assert_state_unchanged(before, _state(e, aldric), "pinned refusal")
	assert_true(e.is_pinned(_index_of(e, aldric)), "the pin survives a refusal")


func test_no_undead_in_range_refusal_keeps_the_turn_and_spends_nothing() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter(
		[aldric], [ghoul], [Vector2i(1, 7)], [Vector2i(14, 7)], _map(15, 15)
	)
	_force_turn(e, aldric)
	assert_eq(e.map.distance_ft(Vector2i(1, 7), Vector2i(14, 7)), 65)
	_bind(e, aldric)
	var before := _state(e, aldric)
	var result := Game.combat_turn_undead()
	assert_false(bool(result.get("ok", true)), "the out-of-range attempt is refused")
	assert_true(
		String(result.get("message", "")).contains("60 ft"),
		"the refusal names the range: " + String(result.get("message", "")),
	)
	_assert_state_unchanged(before, _state(e, aldric), "range refusal")


func test_spent_standard_refusal_keeps_the_turn_and_spends_nothing() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	e.turn_state["standard_used"] = true
	_bind(e, aldric)
	var before := _state(e, aldric)
	var result := Game.combat_turn_undead()
	assert_false(bool(result.get("ok", true)), "the spent-standard attempt is refused")
	assert_true(
		String(result.get("message", "")).contains("standard action"),
		"the refusal names the spent action: " + String(result.get("message", "")),
	)
	_assert_state_unchanged(before, _state(e, aldric), "spent-standard refusal")


func test_missing_holy_symbol_refusal_keeps_the_turn_and_spends_nothing() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	aldric.remove_from_inventory("holy_symbol", 1)
	assert_false(aldric.has_holy_symbol())
	_bind(e, aldric)
	var before := _state(e, aldric)
	var result := Game.combat_turn_undead()
	assert_false(bool(result.get("ok", true)), "the symbol-less attempt is refused")
	assert_true(
		String(result.get("message", "")).contains("holy symbol"),
		"the refusal names the symbol: " + String(result.get("message", "")),
	)
	_assert_state_unchanged(before, _state(e, aldric), "holy-symbol refusal")


func test_valid_attempt_that_affects_no_undead_spends_the_attempt_but_keeps_the_turn() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	# Check 1 + 1 = 2: below the ghoul's effective 4 Hit Dice.
	e.deterministic_rolls = [1]
	_bind(e, aldric)
	var before := _state(e, aldric)
	var result := Game.combat_turn_undead()
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	assert_true(
		String(result.get("message", "")).contains("affects no undead"),
		"a legal attempt that affects nothing is still an attempt: "
		+ String(result.get("message", "")),
	)
	assert_true(bool(e.turn_state["standard_used"]), "the standard action is spent")
	assert_eq(aldric.turn_undead_remaining(), int(before["uses"]) - 1, "one daily use is spent")
	assert_false(ghoul.has_condition("turned"), "nothing was turned")
	assert_eq(e.turn_ptr, int(before["pointer"]), "the turn pointer is unchanged")
	assert_eq(e.round_number, int(before["round"]), "the round is unchanged")
	assert_eq(e.active_character(), aldric, "the player still owns the turn")
	assert_false(e.finished, "the encounter continues")


func test_valid_turn_leaves_the_move_action_with_the_player() -> void:
	var aldric := _cleric()
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	# Check 13 + 1 = 14: up to 4 effective Hit Dice, so the ghoul is turned.
	e.deterministic_rolls = [13, 4, 5]
	_bind(e, aldric)
	var before := _state(e, aldric)
	var result := Game.combat_turn_undead()
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	assert_true(ghoul.has_condition("turned"), "the ghoul is turned")
	assert_true(bool(e.turn_state["standard_used"]), "the standard action is spent")
	assert_eq(aldric.turn_undead_remaining(), int(before["uses"]) - 1, "one daily use is spent")
	assert_eq(e.turn_ptr, int(before["pointer"]), "the turn pointer is unchanged")
	assert_eq(e.round_number, int(before["round"]), "the round is unchanged")
	assert_eq(e.active_character(), aldric, "the player keeps the move action")
	assert_false(e.finished, "the encounter continues")
