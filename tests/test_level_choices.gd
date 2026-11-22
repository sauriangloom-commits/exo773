extends GutTest

## Batch 3 of docs/LEVEL_UP_PLAN.md section 13: the choice data the level-up screen
## renders. Pure data only; `LevelUp.apply` stays the only thing that applies a step.
##
## The fighter's bonus-feat list is the implemented catalog filtered by the printed
## fighter markers (PHB p. 38, which points at Table 5-1, p. 90, footnote 1),
## evaluated on the staged level-4 character. The sorcerer's spell list is the
## implemented 2nd-level spells open to the class, minus the known list.

const XP := 6000
const FIGHTER_DRAFT := {"ability": "str", "feat": "Power Attack"}

var content: ContentDB


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	content = Game.content


func _character(id: String, xp: int = XP) -> Character:
	var data: Dictionary = content.characters[id]
	var ch := Character.from_content(data.duplicate(true), content.items)
	ch.xp = xp
	return ch


func _weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	for raw_id in content.items.keys():
		var item := Dictionary(content.items[raw_id])
		if String(item.get("kind", "")) == "weapon":
			ids.append(String(raw_id))
	ids.sort()
	return ids


func _row_by_text(options: Array, text: String) -> Dictionary:
	for raw in options:
		var row := Dictionary(raw)
		if String(row.get("text", "")) == text:
			return row
	return {}


func _row_by_skill(options: Array, skill: String) -> Dictionary:
	for raw in options:
		var row := Dictionary(raw)
		if String(row.get("skill", "")) == skill:
			return row
	return {}


func _codes_equal(ch: Character, choices: Dictionary) -> void:
	var before := ch.to_dict().duplicate(true)
	var validated := LevelChoices.validate(ch, choices)
	assert_eq(ch.to_dict(), before, "validation applies nothing")
	var applied := LevelUp.apply(ch, choices)
	assert_eq(
		String(validated.get("code", "")),
		String(applied.get("code", "")),
		"LevelChoices and LevelUp agree on the code for %s" % str(choices)
	)
	if not bool(applied.get("ok", false)):
		assert_eq(ch.to_dict(), before, "a refusal applies nothing")


# 1
func test_fighter_options_come_from_the_catalog_and_are_sorted() -> void:
	var options := LevelChoices.feat_options(_character("kaelen"))
	assert_gt(options.size(), 0, "the fighter has options")
	var names: Array[String] = []
	for raw in options:
		var row := Dictionary(raw)
		var key := String(row.get("key", ""))
		assert_true(Feats.CATALOG.has(key), "%s is in the catalog" % key)
		assert_true(bool(Dictionary(Feats.CATALOG[key]).get("fighter_bonus", false)),
			"%s is a printed fighter bonus feat" % key)
		names.append("%s|%s" % [String(row.get("name", "")), String(row.get("param", ""))])
	var sorted := names.duplicate()
	sorted.sort()
	assert_eq(names, sorted, "options are ordered by name and then parameter")


# 2
func test_only_the_fighter_gets_a_feat_slot() -> void:
	for id in ["sera", "aldric", "ysolde", "mira"]:
		var choices := LevelChoices.choices(_character(id), {"ability": "str"})
		var feat: Dictionary = choices["feat"]
		assert_eq(int(feat.get("granted", -1)), 0, "%s gains no feat at 4th level" % id)
		assert_true(Array(feat.get("options", [])).is_empty(), "%s has no feat options" % id)
	var fighter: Dictionary = LevelChoices.choices(_character("kaelen"), FIGHTER_DRAFT)["feat"]
	assert_eq(int(fighter.get("granted", 0)), 1, "the fighter gains one feat")


# 3
func test_owned_feat_parameters_are_not_offered() -> void:
	var options := LevelChoices.feat_options(_character("kaelen"))
	assert_true(_row_by_text(options, "Weapon Focus (longsword)").is_empty(),
		"the authored Weapon Focus parameter is not offered again")
	var other := ""
	for weapon in _weapon_ids():
		if weapon != "longsword":
			other = weapon
			break
	assert_ne(other, "", "content ships a second weapon")
	assert_false(_row_by_text(options, "Weapon Focus (%s)" % other).is_empty(),
		"a different weapon parameter is offered")


# 4
func test_parameterized_feats_expand_per_shipped_weapon() -> void:
	var options := LevelChoices.feat_options(_character("kaelen"))
	var weapons := 0
	for raw in options:
		if String(Dictionary(raw).get("key", "")) == "weapon_focus":
			weapons += 1
	assert_eq(weapons, _weapon_ids().size(), "one Weapon Focus row per shipped weapon")


# 5
func test_option_text_round_trips_through_feats_parse() -> void:
	for raw in LevelChoices.feat_options(_character("kaelen")):
		var row := Dictionary(raw)
		var parsed := Feats.parse(String(row.get("text", "")))
		assert_eq(String(parsed.get("key", "")), String(row.get("key", "")), "key round-trips")
		assert_eq(
			String(parsed.get("param", "")).to_lower(),
			String(row.get("param", "")).to_lower(),
			"parameter round-trips for %s" % String(row.get("text", ""))
		)


# 6
func test_prerequisites_are_evaluated_on_the_staged_level_four_character() -> void:
	var options := LevelChoices.feat_options(_character("kaelen"))
	var cleave := _row_by_text(options, "Cleave")
	assert_false(cleave.is_empty(), "Cleave is a fighter bonus feat and is offered")
	assert_false(bool(cleave.get("eligible", true)), "Cleave needs Power Attack")
	assert_true(
		String(" ".join(PackedStringArray(cleave.get("reasons", [])))).contains("Power Attack"),
		"the refusal names the missing feat"
	)


# 7
func test_pending_ability_increase_changes_the_feat_options() -> void:
	var data: Dictionary = content.characters["kaelen"].duplicate(true)
	Dictionary(data["abilities"])["dex"] = 12
	var ch := Character.from_content(data, content.items)
	ch.xp = XP
	var without := _row_by_text(LevelChoices.feat_options(ch), "Dodge")
	assert_false(bool(without.get("eligible", true)), "Dodge needs Dex 13 at Dex 12")
	var with_draft := _row_by_text(LevelChoices.feat_options(ch, {"ability": "dex"}), "Dodge")
	assert_true(bool(with_draft.get("eligible", false)), "the pending increase satisfies it")
	assert_false(
		bool(_row_by_text(LevelChoices.feat_options(ch, {"ability": "str"}), "Dodge").get("eligible", true)),
		"another ability does not"
	)


# 8
func test_fighter_bonus_flag_filters_the_slot() -> void:
	var options := LevelChoices.feat_options(_character("kaelen"))
	for text in ["Iron Will", "Toughness", "Alertness", "Great Fortitude"]:
		assert_true(_row_by_text(options, text).is_empty(), "%s is not a fighter bonus feat" % text)
	for text in ["Power Attack", "Dodge", "Point Blank Shot", "Combat Expertise"]:
		assert_false(_row_by_text(options, text).is_empty(), "%s is a fighter bonus feat" % text)


# 9
func test_sorcerer_options_are_the_implemented_second_level_arcane_spells() -> void:
	var mira := LevelChoices.spell_options(_character("mira"))
	assert_eq(mira.size(), 1, "content ships one 2nd-level arcane spell")
	assert_eq(String(Dictionary(mira[0]).get("id", "")), "scorching_ray")
	assert_eq(int(Dictionary(mira[0]).get("level", 0)), 2)
	assert_eq(String(Dictionary(mira[0]).get("name", "")), "Scorching Ray")
	for id in ["aldric", "ysolde", "kaelen"]:
		assert_true(LevelChoices.spell_options(_character(id)).is_empty(), "%s chooses no spell" % id)


# 10
func test_known_spells_are_excluded_and_both_modules_agree() -> void:
	var data: Dictionary = content.characters["mira"].duplicate(true)
	Array(Dictionary(data["spells"])["known"]).append("scorching_ray")
	var ch := Character.from_content(data, content.items)
	ch.xp = XP
	assert_true(LevelChoices.spell_options(ch).is_empty(), "a known spell is not offered")
	assert_true(LevelChoices.choices(ch, {"ability": "cha"})["spell"]["options"].is_empty(),
		"and the step's own data agrees")
	_codes_equal(ch, {"ability": "cha", "spell": "scorching_ray"})


# 11
func test_skill_options_report_cost_cap_and_affordable_ranks() -> void:
	var aldric := LevelChoices.choices(_character("aldric"), {})
	var heal := _row_by_skill(aldric["skills"]["options"], "heal")
	assert_eq(int(heal.get("cost_per_rank", 0)), 1, "heal is a cleric class skill")
	assert_eq(int(heal.get("ranks", 0)), 4, "the repaired heal rank")
	assert_eq(int(heal.get("cap", 0)), 7, "class cap at level 4")
	assert_eq(int(heal.get("max_new_ranks", 0)), 2, "the 2-point budget limits the rank")
	assert_eq(int(aldric["skills"]["budget"]), 2)
	var spend := LevelChoices.choices(_character("aldric"), {"ability": "wis", "skills": {"heal": 1}})
	assert_eq(int(spend["skills"]["spent"]), 1)
	assert_eq(int(spend["skills"]["remaining"]), 1)
	assert_eq(int(_row_by_skill(spend["skills"]["options"], "heal").get("max_new_ranks", -1)), 1)
	var listen := _row_by_skill(LevelChoices.choices(_character("kaelen"), {})["skills"]["options"], "listen")
	assert_eq(int(listen.get("cost_per_rank", 0)), 2, "listen is cross-class for a fighter")
	assert_eq(int(listen.get("cap", 0)), 3, "cross-class cap at level 4")
	assert_eq(int(listen.get("max_new_ranks", 0)), 1, "one more rank fits the 2-point budget")


# 12
func test_intelligence_increase_raises_the_budget_and_max_ranks() -> void:
	var plain := LevelChoices.choices(_character("ysolde"), {"ability": "wis"})
	assert_eq(int(plain["skills"]["budget"]), 5, "Int 17 gives 2 + 3 points")
	assert_eq(int(_row_by_skill(plain["skills"]["options"], "spellcraft").get("max_new_ranks", 0)), 5)
	var drafted := LevelChoices.choices(_character("ysolde"), {"ability": "int"})
	assert_eq(int(drafted["skills"]["budget"]), 6, "Int 18 gives 2 + 4 points")
	assert_eq(int(_row_by_skill(drafted["skills"]["options"], "spellcraft").get("max_new_ranks", 0)), 6)


# 13
func test_choices_do_not_mutate_the_character_and_are_deterministic() -> void:
	var ch := _character("kaelen")
	var before := ch.to_dict().duplicate(true)
	var first := LevelChoices.choices(ch, FIGHTER_DRAFT)
	var second := LevelChoices.choices(ch, FIGHTER_DRAFT)
	assert_eq(ch.to_dict(), before, "choices never touch the character")
	assert_eq(first, second, "two calls return the same data")


# 14
func test_blockers_match_level_up_required_for_every_class() -> void:
	var drafts := {
		"kaelen": [{}, FIGHTER_DRAFT],
		"sera": [{}, {"ability": "dex"}],
		"aldric": [{}, {"ability": "wis"}],
		"ysolde": [{}, {"ability": "int"}],
		"mira": [{}, {"ability": "cha", "spell": "scorching_ray"}],
	}
	for id in drafts:
		for raw_draft in Array(drafts[id]):
			var draft := Dictionary(raw_draft)
			var ch := _character(id)
			var blockers := Array(LevelChoices.choices(ch, draft)["blockers"])
			var required := Array(LevelUp.preview(ch, draft)["required"])
			assert_eq(blockers, required, "%s blockers match preview(...).required" % id)


# 15
func test_validate_agrees_with_apply_on_every_refusal_code() -> void:
	_codes_equal(_character("kaelen"), {})
	_codes_equal(_character("kaelen"), {"ability": "luck"})
	_codes_equal(_character("kaelen"), {"ability": "str", "feat": "Power Attack", "skills": {"bogus": 1}})
	_codes_equal(_character("kaelen"), {"ability": "str", "feat": "Power Attack", "skills": {"climb": -1}})
	_codes_equal(_character("kaelen"), {"ability": "str", "feat": "Power Attack", "skills": {"climb": 1, "listen": 1}})
	_codes_equal(_character("kaelen"), {"ability": "str", "feat": "Power Attack", "skills": {"listen": 2}})
	_codes_equal(_character("kaelen"), {"ability": "str"})
	_codes_equal(_character("kaelen"), {"ability": "str", "feat": "Cleave"})
	_codes_equal(_character("kaelen"), {"ability": "str", "feat": "Bogus Feat"})
	_codes_equal(_character("kaelen"), {"ability": "str", "feat": "Weapon Focus (longsword)"})
	_codes_equal(_character("aldric"), {"ability": "wis", "feat": "Power Attack"})
	_codes_equal(_character("aldric"), {"ability": "wis", "spell": "scorching_ray"})
	_codes_equal(_character("mira"), {"ability": "cha"})
	_codes_equal(_character("mira"), {"ability": "cha", "spell": "magic_missile"})
	_codes_equal(_character("mira"), {"ability": "cha", "spell": "bogus_spell"})
	_codes_equal(_character("mira"), {"ability": "cha", "spell": "scorching_ray"})


# 16
func test_ineligible_character_gets_the_level_up_code() -> void:
	var low := _character("kaelen")
	low.level = 2
	var below := _character("kaelen", 5999)
	var done := _character("kaelen")
	done.level = 4
	for pair in [[low, "not_level_3"], [below, "xp_below_threshold"], [done, "already_level_4"]]:
		var ch: Character = pair[0]
		var choices := LevelChoices.choices(ch, {})
		assert_false(bool(choices["ok"]), "the step is closed")
		assert_eq(String(choices.get("code", "")), String(pair[1]), "the code is LevelUp's")
		assert_false(bool(choices["complete"]), "nothing is completable")


# 17
func test_the_step_still_goes_through_level_up_apply() -> void:
	var ch := _character("kaelen")
	var choices := LevelChoices.choices(ch, FIGHTER_DRAFT)
	assert_true(bool(choices["ok"]), "the draft is legal")
	assert_true(bool(choices["complete"]), "nothing is missing")
	assert_eq(int(ch.level), 3, "the data alone applies nothing")
	var applied := LevelUp.apply(ch, FIGHTER_DRAFT)
	assert_true(bool(applied.get("ok", false)), String(applied.get("message", "")))
	assert_eq(int(ch.level), 4, "apply is still the only thing that levels")


# 18
func test_an_empty_pool_blocks_completion() -> void:
	var ch := _character("mira")
	var saved: Dictionary = Dictionary(content.spells["scorching_ray"]).duplicate(true)
	Dictionary(content.spells["scorching_ray"])["level"] = 3
	var choices := LevelChoices.choices(ch, {"ability": "cha"})
	content.spells["scorching_ray"] = saved
	assert_true(Array(Dictionary(choices["spell"])["options"]).is_empty(), "no 2nd-level spell remains")
	assert_false(bool(choices["complete"]), "the step cannot complete")
	assert_true(Array(choices["blockers"]).has("spell"), "the missing spell stays a blocker")
