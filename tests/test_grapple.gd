extends GutTest

## Grapple, player-initiated only (PHB pp. 155-157; SRD Combat, Special Attacks).
##
## Batch 8a of docs/GRAPPLE_PLAN.md: initiation, the grappled state and escape.
## No pin, no monster-initiated grapple, no spellcasting from a hold. The grid,
## turning, death and Escape Artist decisions are the plan's adaptations A-G, not
## printed rules.

const OPEN_ROWS := [
	"#########",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#########",
]
const A_CELL := Vector2i(2, 3)
const B_CELL := Vector2i(3, 3)

var content
var rng: RandomNumberGenerator


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 991


func after_each() -> void:
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _map(rows: Array = OPEN_ROWS) -> BattleMap:
	return BattleMap.from_rows(rows, "grapple_test")


func _encounter(
	party: Array, monsters: Array, party_cells: Array, monster_cells: Array, seed_value := 991
) -> Encounter:
	rng.seed = seed_value
	var e := Encounter.new()
	e.setup(
		party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Grapple"
	)
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _log(e: Encounter) -> String:
	return "\n".join(e.log_lines)


## One full attempt, rebuilt from content so nothing leaks between seeds.
func _attempt(seed_value: int, opts := {}) -> Dictionary:
	rng.seed = seed_value
	var attacker := _char(String(opts.get("attacker", "kaelen")))
	var defender: Character = _monster(String(opts.get("defender", "zombie")))
	if bool(opts.get("living_defender", false)):
		defender = _char("sera")
	attacker.base_attack = int(opts.get("attack_base", 12))
	for feat_text in Array(opts.get("attacker_feats", [])):
		attacker.feats.append(String(feat_text))
	if opts.has("attacker_weapon"):
		attacker.equipment["weapon"] = Dictionary(content.items[String(opts["attacker_weapon"])]).duplicate(true)
	if opts.has("defender_size"):
		defender.size_category = String(opts["defender_size"])
		defender.size_ac = Rules.size_modifier(defender.size_category)
	if bool(opts.get("defender_weak", false)):
		defender.abilities["str"] = 1
	if int(opts.get("defender_base", -1)) >= 0:
		defender.base_attack = int(opts["defender_base"])
	var e := _encounter([attacker], [defender], [A_CELL], [B_CELL], seed_value)
	_force_turn(e, attacker)
	var target_index := int(e.entry_for(defender)["index"])
	var result: Dictionary = e.grapple_active(target_index)
	return {
		"e": e,
		"attacker": attacker,
		"defender": defender,
		"result": result,
		"index": target_index,
		"seed": seed_value,
	}


## Finds the first seed whose attempt satisfies `cond`, so no test depends on a
## lucky roll. The found seed is reported on failure to keep it reproducible.
func _first_seed(cond: Callable, opts := {}) -> Dictionary:
	for seed_value in range(1, 400):
		var attempt := _attempt(seed_value, opts)
		if bool(cond.call(attempt)):
			return attempt
	fail_test("no seed in 1..399 produced the required grapple outcome")
	return {}


## A grappled pair, then the defender's turn, then one escape at the chosen skill.
func _first_escape_seed(want_success: bool, use_skill := false, opts := {}) -> Dictionary:
	for seed_value in range(1, 400):
		var attempt := _attempt(seed_value, opts)
		if not bool(attempt["result"].get("grappled", false)):
			continue
		var e: Encounter = attempt["e"]
		var defender: Character = attempt["defender"]
		defender.base_attack = 40 if want_success else 0
		if use_skill:
			defender.skill_ranks["escape_artist"] = 10
		_force_turn(e, defender)
		var escape: Dictionary = e.grapple_exit(use_skill)
		if bool(escape.get("escaped", false)) == want_success:
			attempt["escape"] = escape
			return attempt
	fail_test("no seed in 1..399 produced the required escape outcome")
	return {}


# ---------------------------------------------------------------- initiation

# 1
func test_a_won_hold_records_the_pair_and_spends_the_action() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	var holder_index := int(e.entry_for(attempt["attacker"])["index"])
	assert_true(e.is_grappled(int(attempt["index"])), "the defender is grappled")
	assert_true(e.is_grappled(holder_index), "the holder is grappled too")
	assert_eq(e.grapple_partner(int(attempt["index"])), holder_index, "the pair is linked both ways")
	assert_eq(e.grapple_partner(holder_index), int(attempt["index"]))
	assert_eq(e.grapples.size(), 1, "one pair is recorded")
	assert_true(bool(e.turn_state["standard_used"]), "the standard action is spent")
	assert_string_contains(_log(e), "grapples")


# 2
func test_the_hold_deals_unarmed_damage() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)),
		{"living_defender": true}
	)
	var defender: Character = attempt["defender"]
	assert_gt(defender.nonlethal, 0, "a living creature takes nonlethal unarmed damage")
	assert_eq(defender.hp, defender.max_hp, "unarmed hold damage is nonlethal, not lethal")
	assert_string_contains(_log(attempt["e"]), "nonlethal damage")


# 3
func test_an_undead_defender_takes_no_hold_damage() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var zombie: Character = attempt["defender"]
	assert_eq(zombie.hp, zombie.max_hp, "undead take no nonlethal hold damage")
	assert_eq(zombie.nonlethal, 0)
	assert_string_contains(_log(attempt["e"]), "immune to nonlethal")


# 4
func test_a_missed_touch_attack_ends_the_attempt() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return a["result"].has("touch") and not bool(a["result"]["touch"]["hit"])
	)
	assert_false(bool(attempt["result"].get("grappled", false)), "no hold without the touch")
	assert_true(bool(attempt["e"].turn_state["standard_used"]), "the action is spent either way")
	assert_string_contains(_log(attempt["e"]), "touch attack misses")


# 5
func test_a_damaging_reaction_fails_the_attempt_before_the_touch() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("failed_reaction", false)),
		{"defender_base": 30}
	)
	assert_false(attempt["result"].has("touch"), "no touch attack is rolled after damaging reaction")
	assert_false(bool(attempt["result"].get("grappled", false)))
	assert_string_contains(_log(attempt["e"]), "deals damage")
	assert_string_contains(_log(attempt["e"]), "grapple attempt fails")


# 6
func test_a_missed_reaction_allows_the_touch_attack() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool:
			return (
				a["result"].has("reaction")
				and not bool(a["result"]["reaction"].get("hit", true))
				and a["result"].has("touch")
			),
		{"defender_base": 0}
	)
	assert_true(attempt["result"].has("touch"), "the touch attack follows a missed reaction")
	assert_string_contains(_log(attempt["e"]), "Attack of opportunity by")


# 7
func test_improved_grapple_removes_the_reaction_and_adds_four() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return a["result"].has("opposed"),
		{"attacker_feats": ["Improved Grapple"], "defender_base": 30}
	)
	assert_false(attempt["result"].has("reaction"), "the reaction is skipped")
	assert_false(_log(attempt["e"]).contains("Attack of opportunity by"), "nothing is provoked")
	var attacker: Character = attempt["attacker"]
	var expected := (
		attacker.base_attack
		+ Rules.ability_modifier(attacker, "str")
		+ Rules.grapple_size_modifier(attacker.size_category)
		+ 4
	)
	assert_eq(int(attempt["result"]["opposed"]["attacker_modifier"]), expected, "Improved Grapple's +4")


# 8
func test_a_defender_two_size_categories_larger_loses_the_hold_automatically() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("auto_lost", false)),
		{"defender_size": "huge"}
	)
	assert_true(attempt["result"].has("touch"), "the touch attack still rolls")
	assert_false(attempt["result"].has("opposed"), "no opposed check is made")
	assert_false(bool(attempt["result"].get("grappled", false)))
	assert_true(bool(attempt["e"].turn_state["standard_used"]), "the attempt costs the action")
	assert_string_contains(_log(attempt["e"]), "automatically")


# 9
func test_grapple_size_modifiers_match_the_printed_table() -> void:
	assert_eq(Rules.grapple_size_modifier("fine"), -16)
	assert_eq(Rules.grapple_size_modifier("diminutive"), -12)
	assert_eq(Rules.grapple_size_modifier("tiny"), -8)
	assert_eq(Rules.grapple_size_modifier("small"), -4)
	assert_eq(Rules.grapple_size_modifier("medium"), 0)
	assert_eq(Rules.grapple_size_modifier("large"), 4)
	assert_eq(Rules.grapple_size_modifier("huge"), 8)
	assert_eq(Rules.grapple_size_modifier("gargantuan"), 12)
	assert_eq(Rules.grapple_size_modifier("colossal"), 16)


# 10
func test_the_grapple_check_uses_base_attack_strength_and_size() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return a["result"].has("opposed"), {"attack_base": 4}
	)
	var ch: Character = attempt["attacker"]
	var expected := 4 + Rules.ability_modifier(ch, "str") + 0
	assert_eq(attempt["e"].grapple_check_modifier(ch), expected)
	assert_eq(int(attempt["result"]["opposed"]["attacker_modifier"]), expected, "no double-counted Strength")


# 11
func test_a_tie_with_equal_modifiers_rerolls_and_a_higher_modifier_wins() -> void:
	var plain := _char("kaelen")
	plain.abilities["str"] = 10
	var plain_defender := _char("sera")
	plain_defender.abilities["str"] = 10
	var equal_found := false
	for seed_value in range(1, 400):
		var r := RandomNumberGenerator.new()
		r.seed = seed_value
		var res := Rules.opposed_ability_check(
			r, plain, ["str"], plain_defender, ["str"], {"label": "grapple"}
		)
		if int(res["rerolls"]) > 0:
			equal_found = true
			assert_true(["attacker", "defender"].has(String(res["winner"])), "a reroll still names a winner")
			assert_eq(int(res["attacker_modifier"]), int(res["defender_modifier"]))
			break
	assert_true(equal_found, "a seed with equal rolls exists")
	var strong := _char("kaelen")
	strong.abilities["str"] = 20
	var weak := _char("sera")
	weak.abilities["str"] = 10
	var modifier_found := false
	for seed_value in range(1, 400):
		var r2 := RandomNumberGenerator.new()
		r2.seed = seed_value
		var res2 := Rules.opposed_ability_check(
			r2, strong, ["str"], weak, ["str"], {"label": "grapple"}
		)
		if int(res2["attacker_roll"]) == int(res2["defender_roll"]):
			modifier_found = true
			assert_eq(String(res2["winner"]), "attacker", "the higher grapple modifier wins the tie")
			assert_eq(int(res2["rerolls"]), 0, "no reroll when the modifier decides")
			break
	assert_true(modifier_found)


# ---------------------------------------------------------------- escape

# 12
func test_escape_succeeds_and_clears_the_pair() -> void:
	var attempt := _first_escape_seed(true)
	var e: Encounter = attempt["e"]
	assert_true(e.grapples.is_empty(), "the pair is cleared")
	assert_string_contains(_log(e), "escapes")
	assert_true(bool(e.turn_state["standard_used"]), "escape is a standard action")


# 13
func test_escape_fails_and_keeps_the_hold() -> void:
	var attempt := _first_escape_seed(false)
	var e: Encounter = attempt["e"]
	assert_eq(e.grapples.size(), 1, "the hold survives a failed escape")
	assert_string_contains(_log(e), "fails to break free")
	assert_true(bool(e.turn_state["standard_used"]))


# 14
func test_escape_artist_uses_the_skill_without_the_grapple_bonus() -> void:
	var attempt := _first_escape_seed(true, true, {"living_defender": true})
	var escape: Dictionary = attempt["escape"]
	var defender: Character = attempt["defender"]
	assert_true(bool(escape.get("escape_artist", false)), "the skill path is recorded")
	assert_eq(
		int(escape["check"]["modifier"]),
		Skills.total(defender, "escape_artist"),
		"Escape Artist uses the skill modifier, not the grapple check"
	)


# 15
func test_release_is_free_and_needs_no_roll() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	var holder: Character = attempt["attacker"]
	_force_turn(e, holder)
	var released: Dictionary = e.grapple_exit()
	assert_true(bool(released.get("released", false)), "the holder lets go")
	assert_true(e.grapples.is_empty())
	assert_false(bool(e.turn_state["standard_used"]), "release costs no action")
	assert_false(bool(e.turn_state["move_used"]))
	assert_string_contains(_log(e), "lets go")


# ---------------------------------------------------------------- state

# 16
func test_a_grappled_creature_cannot_move_or_step() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	var moved: Dictionary = e.move_active_to(Vector2i(2, 2))
	assert_false(bool(moved.get("ok", true)))
	assert_string_contains(String(moved["message"]), "grappling")
	var stepped: Dictionary = e.move_active_to(Vector2i(2, 2), true)
	assert_false(bool(stepped.get("ok", true)))
	assert_string_contains(String(stepped["message"]), "grappling")
	var stood: Dictionary = e.stand_up_active()
	assert_false(bool(stood.get("ok", true)))
	assert_string_contains(String(stood["message"]), "grappling")


# 17
func test_a_grappled_creature_cannot_attack_a_third_party() -> void:
	rng.seed = 17
	var attacker := _char("kaelen")
	var zombie := _monster("zombie")
	var ghoul := _monster("ghoul")
	var e := _encounter([attacker], [zombie, ghoul], [A_CELL], [B_CELL, Vector2i(4, 3)], 17)
	_force_turn(e, attacker)
	var zombie_index := int(e.entry_for(zombie)["index"])
	var ghoul_index := int(e.entry_for(ghoul)["index"])
	var attempt: Dictionary = e.grapple_active(zombie_index)
	if not bool(attempt.get("grappled", false)):
		# Seeds are not guaranteed here; a refusal still needs a live pair.
		e.grapples = [{"holder": int(e.entry_for(attacker)["index"]), "held": zombie_index}]
	e.turn_state = e._fresh_turn_state()
	var refused: Dictionary = e.attack_active(ghoul_index)
	assert_false(bool(refused.get("ok", true)))
	assert_string_contains(String(refused["message"]), "can attack only")
	assert_string_contains(String(refused["message"]), zombie.display_name)


# 18
func test_attacking_the_partner_takes_four_and_requires_a_light_weapon() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	var attacker: Character = attempt["attacker"]
	e.turn_state = e._fresh_turn_state()
	var with_longsword: Dictionary = e.attack_active(int(attempt["index"]))
	assert_false(bool(with_longsword.get("ok", true)), "a longsword is not a light weapon")
	assert_string_contains(String(with_longsword["message"]), "light weapon")
	attacker.equipment["weapon"] = Dictionary(content.items["dagger"]).duplicate(true)
	attacker.equipment["weapon"]["light_weapon"] = true
	var with_dagger: Dictionary = e.attack_active(int(attempt["index"]))
	assert_true(bool(with_dagger.get("ok", false)), String(with_dagger.get("message", "")))
	assert_string_contains(_log(e), "-4")
	assert_string_contains(_log(e), "grappling")


# 19
func test_a_grappled_creature_threatens_nothing() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	var attacker: Character = attempt["attacker"]
	assert_true(e.threat_capability(attacker).is_empty(), "no threatened squares while grappling")
	assert_false(e._threatens_cell(attacker, A_CELL, B_CELL), "and no reach threat")


# 20
func test_a_grappled_defender_loses_dex_to_third_parties_only() -> void:
	rng.seed = 20
	var attacker := _char("kaelen")
	attacker.base_attack = 12
	var zombie := _monster("zombie")
	var stranger := _char("sera")
	var e := _encounter([attacker], [zombie, stranger], [A_CELL], [B_CELL, Vector2i(4, 3)], 20)
	_force_turn(e, attacker)
	var zombie_index := int(e.entry_for(zombie)["index"])
	var holder_index := int(e.entry_for(attacker)["index"])
	var stranger_index := int(e.entry_for(stranger)["index"])
	var attempt: Dictionary = e.grapple_active(zombie_index)
	if not bool(attempt.get("grappled", false)):
		e.grapples = [{"holder": holder_index, "held": zombie_index}]
	zombie.abilities["dex"] = 16
	var dex_bonus := Rules.ability_modifier(zombie, "dex")
	assert_eq(
		Rules.armor_class(zombie) - Rules.armor_class(zombie, {"deny_dex": true}),
		dex_bonus,
		"deny_dex removes the Dexterity bonus without flat-footing"
	)
	assert_false(e.denies_dex_to(zombie_index, holder_index), "the partner does not deny Dexterity")
	assert_true(e.denies_dex_to(zombie_index, stranger_index), "a third party does")


# ---------------------------------------------------------------- AI and cleanup

# 21
func test_a_grappled_monster_escapes_and_does_not_attack() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	var zombie: Character = attempt["defender"]
	_force_turn(e, zombie)
	var before := e.log_lines.size()
	e._run_monster_turn(e.entry_for(zombie))
	var turn_log := "\n".join(e.log_lines.slice(before))
	assert_string_contains(turn_log, "break free")
	assert_false(turn_log.contains("attacks"), "a grappled monster does not attack")
	assert_true(bool(e.turn_state["standard_used"]), "the escape attempt spends its action")


# 22
func test_turning_a_held_monster_clears_the_grapple_first() -> void:
	var attempt := _first_seed(
		func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)),
		{"defender": "ghoul"}
	)
	var e: Encounter = attempt["e"]
	var ghoul: Character = attempt["defender"]
	ghoul.add_effect("turned", "Turned", 10, "condition")
	e._run_turned_turn(e.entry_for(ghoul))
	assert_false(e.is_grappled(int(attempt["index"])), "turning ends the hold before the flee")
	assert_string_contains(_log(e), "grapple ends")


# 23
func test_death_of_either_participant_clears_the_grapple() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	var zombie: Character = attempt["defender"]
	zombie.take_damage(zombie.hp + 10)
	e._check_end()
	assert_true(e.grapples.is_empty(), "a dead participant ends the hold")
	assert_string_contains(_log(e), "grapple ends")


# 24
func test_finish_clears_grapples_and_logs() -> void:
	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	e.finish("victory")
	assert_true(e.grapples.is_empty(), "the encounter clears its grapples")
	assert_string_contains(_log(e), "grapple")


# 25
func test_pending_decisions_and_existing_grapples_block_a_new_attempt() -> void:
	var pending_attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var pending_e: Encounter = pending_attempt["e"]
	pending_e.pending_bull_rush = {"type": "follow"}
	pending_e.turn_state = pending_e._fresh_turn_state()
	var blocked: Dictionary = pending_e.grapple_active(int(pending_attempt["index"]))
	assert_false(bool(blocked.get("ok", true)))
	assert_string_contains(String(blocked["message"]), "pending combat decision")

	var attempt := _first_seed(func(a: Dictionary) -> bool: return bool(a["result"].get("grappled", false)))
	var e: Encounter = attempt["e"]
	e.turn_state = e._fresh_turn_state()
	var again: Dictionary = e.grapple_active(int(attempt["index"]))
	assert_false(bool(again.get("ok", true)))
	assert_string_contains(String(again["message"]), "already")
