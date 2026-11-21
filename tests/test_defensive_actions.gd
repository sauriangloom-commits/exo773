extends GutTest

## Fighting defensively (PHB p.140) and total defense (PHB p.143), with the
## Tumble replacement bonus (PHB p.84) and the interaction with Combat Expertise
## (RC p.54: fighting defensively stacks with it; total defense forbids both).
##
## The state machine under test has two distinct states:
##   selected - an intent that grants nothing and can be cancelled;
##   active   - created only when a legal attack commits, then locked until the
##              start of the character's next turn.
## A refused or cancelled attack must therefore never leave a bonus behind.

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
		],
		"defensive"
	)


func _encounter(
	party: Array, party_cells: Array, monsters: Array, monster_cells: Array
) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	return e


func _index_of(e: Encounter, ch: Character) -> int:
	for entry in e.combatants:
		if entry["char"] == ch:
			return int(entry["index"])
	fail_test("character is not a combatant")
	return -1


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _logged(lines: Array, needle: String) -> bool:
	for line in lines:
		if String(line).contains(needle):
			return true
	return false


## Kaelen is adjacent to the ghoul so a melee attack is legal; Sera waits far
## away. Every test starts from this board and forces the fighter's turn.
func _fight() -> Array:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var ghoul := _monster("ghoul")
	var e := _encounter(
		[kaelen, sera], [Vector2i(1, 3), Vector2i(6, 3)], [ghoul], [Vector2i(2, 3)]
	)
	_force_turn(e, kaelen)
	return [e, kaelen, sera, ghoul]


# ---------------------------------------------------------------- selection

func test_a_selection_grants_nothing_and_can_be_cancelled() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var index := _index_of(e, kaelen)
	var base_ac := Rules.armor_class(kaelen)
	var result := e.set_fight_defensively(true)
	assert_true(bool(result["ok"]), String(result["message"]))
	assert_true(e.fight_defensively_selected_for(index), "the choice is recorded")
	assert_false(e.fight_defensively_active_for(index), "but it is not active yet")
	assert_eq(Rules.armor_class(kaelen), base_ac, "a selection alone grants no AC")
	assert_false(_logged(e.log_lines, "fights defensively"), "and writes no stance line")
	assert_false(bool(e.turn_state["standard_used"]), "and spends nothing")
	var cancelled := e.set_fight_defensively(false)
	assert_true(bool(cancelled["ok"]), String(cancelled["message"]))
	assert_false(e.fight_defensively_selected_for(index), "deselection before commitment works")
	assert_eq(Rules.armor_class(kaelen), base_ac, "still no AC")


# ---------------------------------------------------------------- activation

func test_a_legal_attack_commits_the_stance() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	var index := _index_of(e, kaelen)
	var base_ac := Rules.armor_class(kaelen)
	var base_touch := Rules.touch_ac(kaelen)
	var control := _fight()
	var control_shot: Dictionary = control[0].attack_active(_index_of(control[0], control[3]))
	e.set_fight_defensively(true)
	var shot := e.attack_active(_index_of(e, ghoul))
	assert_true(bool(shot.get("ok", false)), String(shot.get("message", "")))
	assert_false(e.fight_defensively_selected_for(index), "the selection becomes the stance")
	assert_true(e.fight_defensively_active_for(index), "the stance is active")
	assert_eq(
		int(shot["result"]["fight_defensively_penalty"]),
		-4,
		"the committing attack takes the -4 (PHB p.140)",
	)
	assert_eq(
		int(shot["result"]["bonus"]),
		int(control_shot["result"]["bonus"]) - 4,
		"the -4 is exactly the difference from the same attack without the stance",
	)
	assert_eq(Rules.armor_class(kaelen), base_ac + 2, "+2 dodge AC while active")
	assert_eq(Rules.touch_ac(kaelen), base_touch + 2, "touch AC keeps the dodge bonus")
	assert_true(_logged(e.log_lines, "fights defensively"), "the log names the stance")


func test_a_refused_attack_grants_no_bonus() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var index := _index_of(e, kaelen)
	var base_ac := Rules.armor_class(kaelen)
	e.set_fight_defensively(true)
	var refused := e.attack_active(99)
	assert_false(bool(refused["ok"]), "an invalid target is refused")
	assert_true(e.fight_defensively_selected_for(index), "the selection survives a refusal")
	assert_false(e.fight_defensively_active_for(index), "a refused attack never activates it")
	assert_eq(Rules.armor_class(kaelen), base_ac, "no AC from a refused attack")
	assert_false(bool(e.turn_state["standard_used"]), "and nothing is spent")


func test_an_out_of_reach_attack_grants_no_bonus() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	var index := _index_of(e, kaelen)
	e.entry_for(ghoul)["cell"] = Vector2i(6, 1)
	var base_ac := Rules.armor_class(kaelen)
	e.set_fight_defensively(true)
	var refused := e.attack_active(_index_of(e, ghoul))
	assert_false(bool(refused["ok"]), "a target beyond reach is refused")
	assert_true(e.fight_defensively_selected_for(index), "the selection is still pending")
	assert_false(e.fight_defensively_active_for(index), "and still grants nothing")
	assert_eq(Rules.armor_class(kaelen), base_ac, "AC unchanged")
	assert_false(bool(e.turn_state["standard_used"]), "standard action unchanged")


func test_a_selection_made_after_the_standard_action_is_refused() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	var shot := e.attack_active(_index_of(e, ghoul))
	assert_true(bool(shot.get("ok", false)), String(shot.get("message", "")))
	var refused := e.set_fight_defensively(true)
	assert_false(bool(refused["ok"]), "the stance must accompany an attack, not follow it")
	assert_true(String(refused["message"]).contains("standard action"), "the reason names the cost")


# ------------------------------------------------------------------- locking

func test_an_active_stance_cannot_be_cancelled() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	var index := _index_of(e, kaelen)
	e.set_fight_defensively(true)
	e.attack_active(_index_of(e, ghoul))
	var locked_ac := Rules.armor_class(kaelen)
	var refused := e.set_fight_defensively(false)
	assert_false(bool(refused["ok"]), "an active stance refuses cancellation")
	assert_true(String(refused["message"]).contains("cannot be cancelled"), "the reason is explicit")
	assert_true(e.fight_defensively_active_for(index), "the effect is untouched")
	assert_eq(Rules.armor_class(kaelen), locked_ac, "and so is its AC")


# ------------------------------------------------------------- total defense

func test_total_defense_replaces_a_selection() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var index := _index_of(e, kaelen)
	var base_ac := Rules.armor_class(kaelen)
	var base_touch := Rules.touch_ac(kaelen)
	e.set_fight_defensively(true)
	var result := e.total_defense()
	assert_true(bool(result["ok"]), String(result["message"]))
	assert_false(e.fight_defensively_selected_for(index), "the selection is dropped, not committed")
	assert_true(e.total_defense_active_for(index), "total defense is active")
	assert_false(e.fight_defensively_active_for(index), "fighting defensively never activated")
	assert_eq(Rules.armor_class(kaelen), base_ac + 4, "+4 dodge AC (PHB p.143)")
	assert_eq(Rules.touch_ac(kaelen), base_touch + 4, "touch AC keeps it")
	assert_true(bool(e.turn_state["standard_used"]), "it costs the standard action")
	assert_false(bool(e.turn_state["move_used"]), "and not the move action")
	var refused := e.attack_active(1)
	assert_false(bool(refused["ok"]), "no attacks while using total defense")
	assert_true(_logged(e.log_lines, "total defense"), "the log names the action")


func test_total_defense_allows_a_move_afterwards() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var cell_before: Vector2i = e.entry_for(kaelen)["cell"]
	e.total_defense()
	var moved := e.move_active_to(Vector2i(1, 1))
	assert_true(bool(moved.get("ok", true)), String(moved.get("message", "")))
	assert_ne(e.entry_for(kaelen)["cell"], cell_before, "the move action remains available")


func test_total_defense_refuses_combat_expertise() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	kaelen.add_effect("combat_expertise", "Combat Expertise", 1)
	var refused := e.total_defense()
	assert_false(bool(refused["ok"]), "the printed exclusion is enforced")
	assert_true(String(refused["message"]).contains("Combat Expertise"), "the reason names it")
	assert_false(e.total_defense_active_for(_index_of(e, kaelen)), "nothing is applied")
	assert_false(bool(e.turn_state["standard_used"]), "nothing is spent")


func test_total_defense_prevents_opportunity_attacks() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var sera: Character = parts[2]
	var ghoul: Character = parts[3]
	# Sera stands beside the ghoul and uses total defense on her own turn.
	e.entry_for(sera)["cell"] = Vector2i(2, 2)
	_force_turn(e, sera)
	var result := e.total_defense()
	assert_true(bool(result["ok"]), String(result["message"]))
	assert_true(
		not e._threatening_enemies(e.entry_for(ghoul)).any(
			func(entry: Dictionary) -> bool: return entry["char"] == sera
		),
		"a total-defending creature is not a threat for provocation",
	)
	e._provoke_single_opportunity(sera, ghoul)
	assert_false(bool(e.aoo_used.get(_index_of(e, sera), false)), "no reaction is spent")
	assert_true(
		_logged(e.log_lines, "cannot make an opportunity attack"),
		"the refusal is explained",
	)


# ------------------------------------------------------- round scope and expiry

func test_an_active_stance_penalises_the_opportunity_attack() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	e.set_fight_defensively(true)
	e.attack_active(_index_of(e, ghoul))
	var weapon: Dictionary = kaelen.equipment.get("weapon", {})
	var reaction := e._resolve_attack(
		_index_of(e, kaelen), _index_of(e, ghoul), weapon, {"reaction": true}
	)
	assert_eq(
		int(reaction["result"]["fight_defensively_penalty"]),
		-4,
		"\"all attacks in a round\" includes the reaction (PHB p.140)",
	)


func test_the_stance_expires_at_the_start_of_the_next_turn() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	var index := _index_of(e, kaelen)
	var base_ac := Rules.armor_class(kaelen)
	e.set_fight_defensively(true)
	e.attack_active(_index_of(e, ghoul))
	assert_eq(Rules.armor_class(kaelen), base_ac + 2, "active before expiry")
	for _i in e.combatants.size():
		e.end_turn()
		if e.active_character() == kaelen:
			break
	assert_false(e.fight_defensively_active_for(index), "the effect is gone")
	assert_eq(Rules.armor_class(kaelen), base_ac, "and so is the AC")
	assert_true(_logged(e.log_lines, "defensive stance ends"), "the expiry is logged")


# ----------------------------------------------------------- rules interplay

func test_fighting_defensively_stacks_with_combat_expertise() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	kaelen.feats.append("Combat Expertise")
	kaelen.abilities["int"] = 13
	var base_ac := Rules.armor_class(kaelen)
	var chosen := e.set_active_combat_expertise(3)
	assert_true(bool(chosen["ok"]), String(chosen["message"]))
	e.set_fight_defensively(true)
	var shot := e.attack_active(_index_of(e, ghoul))
	assert_true(bool(shot.get("ok", false)), String(shot.get("message", "")))
	assert_eq(
		Rules.armor_class(kaelen), base_ac + 5, "both dodge bonuses apply (RC p.54: 2 + 3)"
	)
	assert_eq(
		Rules.touch_ac(kaelen),
		Rules.armor_class(kaelen) - Rules.armor_bonus(kaelen) - Rules.shield_bonus(kaelen)
		- kaelen.natural_armor,
		"touch AC carries both dodge bonuses too",
	)


func test_tumble_ranks_replace_the_defensive_bonus() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	var base_ac := Rules.armor_class(kaelen)
	kaelen.skill_ranks["tumble"] = 5
	e.set_fight_defensively(true)
	e.attack_active(_index_of(e, ghoul))
	assert_eq(Rules.armor_class(kaelen), base_ac + 3, "+3 instead of +2 with 5 ranks (PHB p.84)")
	# Total defense on a fresh turn: +6 instead of +4.
	var total := _fight()
	var kaelen2: Character = total[1]
	kaelen2.skill_ranks["tumble"] = 5
	var base2 := Rules.armor_class(kaelen2)
	total[0].total_defense()
	assert_eq(Rules.armor_class(kaelen2), base2 + 6, "+6 instead of +4 with 5 ranks")


func test_four_tumble_ranks_keep_the_base_bonus() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	var base_ac := Rules.armor_class(kaelen)
	kaelen.skill_ranks["tumble"] = 4
	e.set_fight_defensively(true)
	e.attack_active(_index_of(e, ghoul))
	assert_eq(Rules.armor_class(kaelen), base_ac + 2, "four ranks are not enough")


func test_the_dodge_bonus_is_denied_while_dexterity_is_denied() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	e.set_fight_defensively(true)
	e.attack_active(_index_of(e, ghoul))
	var with_stance := Rules.armor_class(kaelen, {"flat_footed": true})
	kaelen.remove_effect("fighting_defensively")
	var without_stance := Rules.armor_class(kaelen, {"flat_footed": true})
	assert_eq(
		with_stance,
		without_stance,
		"a character denied Dexterity gains nothing from the stance (PHB p.136)",
	)


func test_normal_and_touch_ac_parity_and_cover_stacking() -> void:
	var parts := _fight()
	var e: Encounter = parts[0]
	var kaelen: Character = parts[1]
	var ghoul: Character = parts[3]
	e.set_fight_defensively(true)
	e.attack_active(_index_of(e, ghoul))
	assert_eq(
		CombatScreen.effective_ac(kaelen, false), Rules.armor_class(kaelen),
		"the inspector's normal AC is the resolver's",
	)
	assert_eq(
		CombatScreen.effective_ac(kaelen, false, 0, true), Rules.touch_ac(kaelen),
		"the inspector's touch AC is the resolver's",
	)
	assert_eq(
		CombatScreen.effective_ac(kaelen, false, 4), Rules.armor_class(kaelen) + 4,
		"cover stacks on top of the stance",
	)
	assert_eq(
		CombatScreen.effective_ac(kaelen, false, 4, true), Rules.touch_ac(kaelen) + 4,
		"and on touch AC too",
	)
