extends GutTest

## Combat Casting (PHB printed p. 92): "You get a +4 bonus on Concentration
## checks made to cast a spell or use a spell-like ability while on the defensive
## (see Casting on the Defensive, page 140) or while you are grappling or
## pinned." Grappling and pinning are not modeled, so only the defensive clause is
## implemented; these tests pin down that the +4 never reaches an injury check or
## any other Concentration use.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _wizard_id() -> String:
	for id in content.character_ids():
		var data := content.get_character(id)
		var prepared: Dictionary = data.get("spells", {}).get("prepared", {})
		for level in prepared.keys():
			if Array(prepared[level]).has("scorching_ray"):
				return id
	return ""


func _caster(feats: Array = []) -> Character:
	var ch := Character.from_content(content.get_character(_wizard_id()), content.items)
	ch.id = "qa_combat_casting_caster"
	ch.display_name = "QA Combat Casting Caster"
	ch.max_hp = 90
	ch.hp = 90
	ch.skill_ranks["concentration"] = 0
	if not feats.is_empty():
		ch.feats.clear()
		for feat_text in feats:
			ch.feats.append(String(feat_text))
	return ch


func _zombie(id := "qa_zombie", name := "QA Zombie") -> Character:
	var ch := Character.from_content(content.get_monster("zombie"), content.items)
	ch.id = id
	ch.display_name = name
	ch.max_hp = 200
	ch.hp = 200
	return ch


func _ghoul() -> Character:
	var ch := Character.from_content(content.get_monster("ghoul"), content.items)
	ch.id = "qa_cc_target"
	ch.display_name = "QA Target"
	ch.max_hp = 200
	ch.hp = 200
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


func _encounter(caster: Character, enemies: Array, cells: Array, seed := 918273) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var e := Encounter.new()
	e.setup([caster], enemies, _map(), rng, [Vector2i(1, 3)], cells, content.spells, "Test")
	e.begin()
	for entry in e.combatants:
		if entry["char"] == caster:
			continue
		for i in e.order:
			if e.combatants[i]["char"] == entry["char"]:
				e.turn_ptr = e.order.find(i)
				e._begin_turn(e.combatants[i])
				break
	for i in e.order:
		if e.combatants[i]["char"] == caster:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			break
	return e


func _logs(e: Encounter, needle: String) -> bool:
	for line in e.log_lines:
		if String(line).contains(needle):
			return true
	return false


func _feat_rows(breakdown: Array) -> Array:
	var rows: Array = []
	for row in breakdown:
		if String(row.get("label", "")) == "Combat Casting":
			rows.append(row)
	return rows


func test_defensive_check_gains_four_and_names_it_in_the_breakdown() -> void:
	var caster := _caster(["Combat Casting"])
	var e := _encounter(caster, [_zombie()], [Vector2i(2, 3)])
	var result := e.cast_active_spell("magic_missile", 1, {"defensive": true})
	var check: Dictionary = result["concentration_checks"][0]["check"]
	assert_eq(
		int(check["bonus"]),
		Rules.ability_modifier(caster, "con") + 4,
		"untrained Constitution modifier plus the feat's +4"
	)
	var rows := _feat_rows(check["breakdown"])
	assert_eq(rows.size(), 1, "the breakdown names the feat once")
	assert_eq(int(rows[0]["value"]), 4, "the row carries the printed +4")
	assert_eq(String(rows[0]["type"]), "untyped", "the printed bonus is untyped")
	assert_true(
		_logs(e, "Combat Casting +4"), "the rendered check line shows the feat's contribution"
	)


func test_without_the_feat_the_defensive_check_has_no_bonus() -> void:
	var caster := _caster()
	var e := _encounter(caster, [_zombie()], [Vector2i(2, 3)])
	var result := e.cast_active_spell("magic_missile", 1, {"defensive": true})
	var check: Dictionary = result["concentration_checks"][0]["check"]
	assert_eq(int(check["bonus"]), Rules.ability_modifier(caster, "con"), "Constitution only")
	assert_eq(_feat_rows(check["breakdown"]).size(), 0, "nothing to name")


func test_injury_check_does_not_receive_the_defensive_bonus() -> void:
	# The same feat-holder makes an ordinary cast that is interrupted for damage:
	# that check is not "while on the defensive", so the +4 must be absent.
	var found := {}
	for seed in range(1, 300):
		var caster := _caster(["Combat Casting"])
		var zombie := _zombie()
		zombie.base_attack = 50
		var e := _encounter(caster, [zombie, _ghoul()], [Vector2i(2, 3), Vector2i(1, 1)], seed)
		var result := e.cast_active_spell("magic_missile", 2)
		var checks: Array = result.get("concentration_checks", [])
		if not checks.is_empty() and String(checks[0]["kind"]) == "injury":
			found = {"result": result, "encounter": e, "caster": caster}
			break
	assert_false(found.is_empty(), "a damaging interruption is reachable")
	var check: Dictionary = found["result"]["concentration_checks"][0]["check"]
	var caster: Character = found["caster"]
	assert_eq(
		int(check["bonus"]),
		Rules.ability_modifier(caster, "con"),
		"an injury check gets the Constitution modifier only"
	)
	assert_eq(_feat_rows(check["breakdown"]).size(), 0, "the feat stays out of it")


func test_duplicate_feat_text_does_not_stack_the_bonus() -> void:
	var caster := _caster(["Combat Casting", "Combat Casting"])
	var e := _encounter(caster, [_zombie()], [Vector2i(2, 3)])
	var result := e.cast_active_spell("magic_missile", 1, {"defensive": true})
	var check: Dictionary = result["concentration_checks"][0]["check"]
	assert_eq(
		int(check["bonus"]),
		Rules.ability_modifier(caster, "con") + 4,
		"untyped bonuses take the best value, so the +4 never doubles"
	)
	assert_eq(_feat_rows(check["breakdown"]).size(), 1, "one row, not two")


func test_failed_defensive_cast_with_the_feat_still_spends_the_cast() -> void:
	var found := {}
	for seed in range(1, 300):
		var caster := _caster(["Combat Casting"])
		caster.abilities["con"] = 1
		var zombie := _zombie()
		zombie.base_attack = 50
		var e := _encounter(caster, [zombie], [Vector2i(2, 3)], seed)
		var result := e.cast_active_spell("scorching_ray", 1, {"defensive": true})
		if bool(result.get("disrupted", false)):
			found = {"result": result, "encounter": e, "caster": caster}
			break
	assert_false(found.is_empty(), "a failed defensive check is reachable")
	var caster: Character = found["caster"]
	var e: Encounter = found["encounter"]
	assert_eq(
		int(found["result"]["concentration_checks"][0]["check"]["bonus"]),
		-1,
		"Constitution 1 (-5) plus the feat"
	)
	assert_true(bool(e.turn_state["standard_used"]), "the standard action is still spent")
	assert_eq(int(caster.spells["slots"]["2"]["used"]), 1, "the level-2 slot is spent")
	assert_eq(caster.spells["prepared"]["2"].count("scorching_ray"), 1, "one ray remains prepared")
	assert_true(_logs(e, "The spell is disrupted"), "the log states the disruption")


func test_content_contract_accepts_the_feat_through_the_catalog() -> void:
	assert_true(Feats.CATALOG.has("combat_casting"), "the feat is cataloged")
	var data: Dictionary = Feats.CATALOG["combat_casting"]
	assert_eq(int(data["page"]), 92, "printed page 92")
	assert_true(
		String(data["benefit"]).contains("defensive"), "the benefit names its actual scope"
	)
	var caster := _caster(["Combat Casting"])
	assert_eq(Feats.validate_for_character(caster), [] as Array[String], "valid for a character")
	assert_true(Feats.has_active(caster, "combat_casting"), "active with no prerequisites")
	assert_eq(
		Rules.skill_total(caster, "concentration", {"defensive_casting": true}),
		Rules.ability_modifier(caster, "con") + 4,
		"the defensive circumstance raises the total by four"
	)
	assert_eq(
		Rules.skill_total(caster, "concentration"),
		Rules.ability_modifier(caster, "con"),
		"without the circumstance nothing is added"
	)
	var broken := _caster(["Great Cleave"])
	assert_gt(
		Feats.validate_for_character(broken).size(), 0, "unimplemented feats are still rejected"
	)
	var described := Feats.describe(caster)
	var found_row := false
	for row in described:
		if String(row["name"]) == "Combat Casting":
			found_row = true
			assert_true(bool(row["active"]), "the sheet shows it active")
	assert_true(found_row, "the sheet lists the feat")
