extends GutTest

## Level-up core, batch 2 of docs/LEVEL_UP_PLAN.md section 12.
##
## The tests use the authored, still-unrepaired level-3 characters on purpose:
## aldric's sense motive 4, ysolde's search 4 and mira's diplomacy 4 are above the
## level-3 cross-class cap and must not block the step, and their point totals stay
## over budget until the separate content repair. Nothing here asserts that repair.
##
## Skill caps at 4th level: class 7; cross-class printed 3.5, enforced as 3 whole
## ranks because the engine stores whole ranks and buys a cross-class rank for two
## points (SRD Skills Summary; PHB p. 62).

const XP := 6000

var content: ContentDB


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	content = Game.content


func _character(id: String, xp: int = XP) -> Character:
	var data: Dictionary = content.characters[id]
	var ch := Character.from_content(data.duplicate(true), content.items)
	ch.xp = xp
	return ch


func _result(ch: Character, choices: Dictionary) -> Dictionary:
	return LevelUp.apply(ch, choices)


func _assert_refused(result: Dictionary, code: String) -> void:
	assert_false(bool(result.get("ok", true)), "the step is refused")
	assert_eq(String(result.get("code", "")), code, "the refusal code is %s" % code)
	assert_false(String(result.get("message", "")).is_empty(), "the refusal explains itself")


func _valid_choices(class_key: String) -> Dictionary:
	match class_key:
		"fighter":
			return {"ability": "str", "skills": {"climb": 1}, "feat": "Power Attack"}
		"rogue":
			return {"ability": "dex", "skills": {"climb": 1}}
		"cleric":
			return {"ability": "wis", "skills": {"heal": 1}}
		"wizard":
			return {"ability": "int", "skills": {"spellcraft": 1}}
		"sorcerer":
			return {"ability": "cha", "skills": {"bluff": 1}, "spell": "scorching_ray"}
	return {"ability": "str"}


# 1
func test_eligibility_is_inclusive_at_six_thousand_xp() -> void:
	assert_eq(String(LevelUp.eligibility(_character("kaelen", 5999))["code"]), "xp_below_threshold")
	assert_eq(String(LevelUp.eligibility(_character("kaelen", 6000))["code"]), "eligible")
	assert_eq(String(LevelUp.eligibility(_character("kaelen", 6001))["code"]), "eligible")
	assert_eq(int(LevelUp.XP_THRESHOLD), 6000)


# 2
func test_a_level_four_character_is_not_eligible() -> void:
	var ch := _character("kaelen")
	ch.level = 4
	var result := LevelUp.eligibility(ch)
	assert_false(bool(result["eligible"]))
	assert_eq(String(result["code"]), "already_level_4")


# 3
func test_a_level_two_character_is_not_eligible_even_with_six_thousand_xp() -> void:
	var ch := _character("kaelen")
	ch.level = 2
	var result := LevelUp.eligibility(ch)
	assert_false(bool(result["eligible"]))
	assert_eq(String(result["code"]), "not_level_3")


# 4
func test_an_untabled_class_is_refused_without_crashing() -> void:
	var ch := _character("kaelen")
	ch.char_class = "Bard"
	var result := LevelUp.eligibility(ch)
	assert_false(bool(result["eligible"]))
	assert_eq(String(result["code"]), "class_not_tabled")
	assert_false(String(result["message"]).is_empty())


# 5
func test_the_threshold_is_six_thousand_and_xp_is_never_changed() -> void:
	var ch := _character("kaelen")
	var result := _result(ch, _valid_choices("fighter"))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(ch.xp), XP, "level-up never spends or awards XP")
	assert_eq(int(result["xp"]), XP)
	assert_eq(int(result["threshold"]), 6000)


# 6
func test_preview_does_not_mutate_the_character() -> void:
	var ch := _character("kaelen")
	var before := ch.to_dict().duplicate(true)
	var preview := LevelUp.preview(ch, _valid_choices("fighter"))
	assert_true(bool(preview["ok"]), String(preview.get("message", "")))
	assert_eq(ch.to_dict(), before, "preview must be read-only")


# 7
func test_preview_lists_required_choices_without_choices() -> void:
	assert_eq(LevelUp.preview(_character("kaelen"))["required"], ["ability", "feat"])
	assert_eq(LevelUp.preview(_character("ysolde"))["required"], ["ability"])
	assert_eq(LevelUp.preview(_character("mira"))["required"], ["ability", "spell"])
	assert_eq(LevelUp.preview(_character("sera"))["required"], ["ability"])


# 8
func test_preview_matches_the_printed_level_four_rows() -> void:
	var expected := {
		"kaelen": [36, 4, {"fort": 4, "ref": 1, "will": 1}],
		"sera": [22, 3, {"fort": 1, "ref": 4, "will": 1}],
		"aldric": [27, 3, {"fort": 4, "ref": 1, "will": 4}],
		"ysolde": [17, 2, {"fort": 1, "ref": 1, "will": 4}],
		"mira": [17, 2, {"fort": 1, "ref": 1, "will": 4}],
	}
	for id in expected:
		var preview := LevelUp.preview(_character(id))
		assert_eq(int(Dictionary(preview["hit_points"])["max_after"]), int(expected[id][0]), "%s HP at 4" % id)
		assert_eq(int(Dictionary(preview["base_attack"])["after"]), int(expected[id][1]), "%s BAB at 4" % id)
		var saves := Dictionary(preview["base_saves"])
		for save in ["fort", "ref", "will"]:
			assert_eq(
				int(Dictionary(saves[save])["after"]),
				int(Dictionary(expected[id][2])[save]),
				"%s %s at 4" % [id, save]
			)


# 9
func test_redirected_slot_readings_are_per_class() -> void:
	var aldric := Dictionary(Dictionary(LevelUp.preview(_character("aldric"))["spells"])["slots_after"])
	assert_eq(int(aldric["1"]["max"]), 4, "cleric 1st-level slots at 4")
	assert_eq(int(aldric["2"]["max"]), 3, "cleric 2nd-level slots at 4")
	var ysolde := Dictionary(Dictionary(LevelUp.preview(_character("ysolde"))["spells"])["slots_after"])
	assert_eq(int(ysolde["1"]["max"]), 4, "wizard 1st-level slots at 4 keep the Intelligence bonus")
	assert_eq(int(ysolde["2"]["max"]), 3, "wizard 2nd-level slots at 4 keep the Intelligence bonus")
	var mira := Dictionary(Dictionary(LevelUp.preview(_character("mira"))["spells"])["slots_after"])
	assert_eq(int(mira["1"]["max"]), 6, "sorcerer 1st-level slots stay at 6")
	assert_eq(int(mira["2"]["max"]), 3, "the new 2nd-level sorcerer row is 3")


# 10
func test_apply_fighter_sets_level_bab_saves_hp_and_feat() -> void:
	var ch := _character("kaelen")
	var result := _result(ch, _valid_choices("fighter"))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(ch.level, 4)
	assert_eq(ch.base_attack, 4)
	assert_eq(ch.base_saves, {"fort": 4, "ref": 1, "will": 1})
	assert_eq(ch.max_hp, 36)
	assert_eq(ch.hp, 36)
	assert_true(ch.feats.has("Power Attack"))
	assert_eq(int(ch.skill_ranks.get("climb", 0)), 5)


# 11
func test_apply_cleric_adds_the_domain_inclusive_slots() -> void:
	var ch := _character("aldric")
	var result := _result(ch, _valid_choices("cleric"))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(ch.spells["slots"]["1"]["max"]), 4)
	assert_eq(int(ch.spells["slots"]["2"]["max"]), 3)
	assert_eq(ch.base_attack, 3)
	assert_eq(ch.max_hp, 27)


# 12
func test_apply_wizard_keeps_the_intelligence_bonus_slots() -> void:
	var ch := _character("ysolde")
	var result := _result(ch, _valid_choices("wizard"))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(ch.abilities["int"]), 18)
	assert_eq(int(ch.spells["slots"]["1"]["max"]), 4)
	assert_eq(int(ch.spells["slots"]["2"]["max"]), 3)
	assert_eq(int(ch.skill_ranks.get("spellcraft", 0)), 1)


# 13
func test_apply_sorcerer_adds_one_second_level_spell_and_no_first_level_slot() -> void:
	var ch := _character("mira")
	var before_known := Array(ch.spells["known"]).size()
	var result := _result(ch, _valid_choices("sorcerer"))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(ch.spells["slots"]["1"]["max"]), 6)
	assert_eq(int(ch.spells["slots"]["2"]["max"]), 3)
	assert_eq(Array(ch.spells["known"]).size(), before_known + 1)
	assert_true(Array(ch.spells["known"]).has("scorching_ray"))


# 14
func test_constitution_increase_is_retroactive() -> void:
	var ch := _character("aldric")
	var result := _result(ch, {"ability": "con", "skills": {"heal": 1}})
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(ch.abilities["con"]), 14)
	assert_eq(ch.max_hp, 31, "all four hit dice gain the new Constitution modifier")
	assert_eq(Rules.saving_throw_bonus(ch, "fort"), 6)
	assert_eq(int(Dictionary(result["hit_points"])["delta"]), 10)


# 15
func test_hp_after_preserves_damage_taken() -> void:
	var ch := _character("kaelen")
	ch.hp = 10
	var result := _result(ch, _valid_choices("fighter"))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(ch.max_hp, 36)
	assert_eq(ch.hp, 18, "18 points of damage stay 18 points of damage")
	assert_eq(int(Dictionary(result["hit_points"])["hp_after"]), 18)


# 16
func test_skill_points_use_the_budget_at_level_four() -> void:
	var ch := _character("kaelen")
	var preview := LevelUp.preview(ch, {"ability": "str", "feat": "Power Attack"})
	assert_eq(int(Dictionary(preview["skills"])["budget"]), 2)
	assert_eq(int(Dictionary(preview["skills"])["remaining"]), 2)
	var result := _result(ch, {"ability": "str", "skills": {"climb": 2}, "feat": "Power Attack"})
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(ch.skill_ranks.get("climb", 0)), 6)
	assert_eq(int(Dictionary(result["skills"])["spent"]), 2)
	assert_eq(int(Dictionary(result["skills"])["remaining"]), 0)


# 17
func test_intelligence_increase_raises_the_skill_budget() -> void:
	var ch := _character("ysolde")
	var preview := LevelUp.preview(ch, {"ability": "int"})
	assert_eq(int(Dictionary(preview["skills"])["budget"]), 6, "Int 18 gives 2 + 4 points")
	var result := _result(
		ch,
		{"ability": "int", "skills": {"listen": 1, "spot": 1, "sense_motive": 1}}
	)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(Dictionary(result["skills"])["spent"]), 6, "three cross-class ranks cost six points")


# 18
func test_class_and_cross_class_caps_are_enforced_on_new_ranks() -> void:
	var sera := _character("sera")
	var class_ok := _result(sera, {"ability": "dex", "skills": {"climb": 5}})
	assert_true(bool(class_ok["ok"]), "climb 2 + 5 reaches the class cap 7")
	assert_eq(int(sera.skill_ranks.get("climb", 0)), 7)
	var sera_cap := _result(_character("sera"), {"ability": "dex", "skills": {"climb": 6}})
	_assert_refused(sera_cap, "skill_rank_above_cap")
	assert_true(String(sera_cap["message"]).contains("7"))
	var cross_ok := _result(_character("kaelen"), {"ability": "str", "skills": {"listen": 1}, "feat": "Power Attack"})
	assert_true(bool(cross_ok["ok"]), "listen 2 + 1 reaches the cross-class cap 3")
	var cross_cap := _result(_character("kaelen"), {"ability": "str", "skills": {"listen": 2}, "feat": "Power Attack"})
	_assert_refused(cross_cap, "skill_rank_above_cap")
	assert_true(String(cross_cap["message"]).contains("3"))


# 19
func test_existing_over_cap_ranks_do_not_block_level_up() -> void:
	var ch := _character("aldric")
	assert_eq(int(ch.skill_ranks.get("sense_motive", 0)), 4, "the authored rank is still unrepaired")
	var preview := LevelUp.preview(ch, {"ability": "wis"})
	assert_true(bool(preview["ok"]), String(preview.get("message", "")))
	assert_true(String(" ".join(PackedStringArray(preview["notices"]))).contains("sense_motive"))
	var result := _result(ch, {"ability": "wis", "skills": {"heal": 1}})
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(int(ch.skill_ranks.get("sense_motive", 0)), 4, "level-up never audits existing ranks")


# 20
func test_unspent_skill_points_are_discarded() -> void:
	var ch := _character("kaelen")
	var before := Dictionary(ch.skill_ranks).duplicate(true)
	var result := _result(ch, {"ability": "str", "feat": "Power Attack"})
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(ch.skill_ranks, before)
	assert_eq(int(Dictionary(result["skills"])["remaining"]), 2)
	assert_eq(int(Dictionary(result["skills"])["spent"]), 0)


# 21
func test_over_budget_skill_allocation_is_refused_atomically() -> void:
	var ch := _character("kaelen")
	var before := ch.to_dict().duplicate(true)
	var result := _result(
		ch, {"ability": "str", "skills": {"climb": 1, "listen": 1}, "feat": "Power Attack"}
	)
	_assert_refused(result, "skill_points_over_budget")
	assert_eq(ch.to_dict(), before)


# 22
func test_a_new_rank_above_the_cap_is_refused() -> void:
	var ch := _character("kaelen")
	var before := ch.to_dict().duplicate(true)
	var result := _result(ch, {"ability": "str", "skills": {"listen": 2}, "feat": "Power Attack"})
	_assert_refused(result, "skill_rank_above_cap")
	assert_eq(ch.to_dict(), before)


# 23
func test_unknown_skill_and_negative_rank_are_refused() -> void:
	var ch := _character("kaelen")
	_assert_refused(
		_result(ch, {"ability": "str", "skills": {"basketweaving": 1}, "feat": "Power Attack"}),
		"unknown_skill"
	)
	_assert_refused(
		_result(ch, {"ability": "str", "skills": {"climb": -1}, "feat": "Power Attack"}),
		"negative_rank"
	)


# 24
func test_missing_ability_increase_is_refused() -> void:
	var ch := _character("kaelen")
	var before := ch.to_dict().duplicate(true)
	_assert_refused(_result(ch, {"feat": "Power Attack"}), "missing_ability_increase")
	assert_eq(ch.to_dict(), before)


# 25
func test_non_fighter_feat_choice_is_refused() -> void:
	var ch := _character("sera")
	var before := ch.to_dict().duplicate(true)
	_assert_refused(_result(ch, {"ability": "dex", "feat": "Dodge"}), "feat_slot_unavailable")
	assert_eq(ch.to_dict(), before)


# 26
func test_fighter_without_a_feat_is_refused() -> void:
	var ch := _character("kaelen")
	var before := ch.to_dict().duplicate(true)
	_assert_refused(_result(ch, {"ability": "str"}), "feat_required")
	assert_eq(ch.to_dict(), before)


# 27
func test_feat_prerequisites_are_evaluated_on_the_staged_character() -> void:
	var ch := _character("kaelen")
	_assert_refused(
		_result(ch, {"ability": "str", "feat": "Combat Expertise"}),
		"feat_prerequisites_unmet"
	)
	var result := _result(ch, {"ability": "str", "feat": "Weapon Focus (short sword)"})
	assert_true(
		bool(result["ok"]),
		"a second weapon choice is a different parameter and meets the staged +4 base attack"
	)
	assert_true(ch.feats.has("Weapon Focus (short sword)"))
	assert_true(ch.feats.has("Weapon Focus (longsword)"))


# 28
func test_an_already_owned_feat_is_refused() -> void:
	var ch := _character("kaelen")
	_assert_refused(_result(ch, {"ability": "str", "feat": "Iron Will"}), "feat_already_owned")


# 29
func test_sorcerer_requires_a_level_two_known_spell() -> void:
	var ch := _character("mira")
	_assert_refused(_result(ch, {"ability": "cha"}), "spell_required")
	var result := _result(ch, {"ability": "cha", "spell": "scorching_ray"})
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(Array(ch.spells["known"]).has("scorching_ray"))


# 30
func test_an_unknown_or_already_known_spell_is_refused() -> void:
	var ch := _character("mira")
	_assert_refused(_result(ch, {"ability": "cha", "spell": "fireball"}), "spell_not_implemented")
	_assert_refused(_result(ch, {"ability": "cha", "spell": "magic_missile"}), "spell_level_not_new")
	var known := _character("mira")
	known.spells["known"] = ["scorching_ray"]
	_assert_refused(_result(known, {"ability": "cha", "spell": "scorching_ray"}), "spell_already_known")
	_assert_refused(
		_result(_character("ysolde"), {"ability": "int", "spell": "scorching_ray"}),
		"spell_choice_unavailable"
	)


# 31
func test_second_apply_is_refused_and_changes_nothing() -> void:
	var ch := _character("kaelen")
	var first := _result(ch, _valid_choices("fighter"))
	assert_true(bool(first["ok"]), String(first.get("message", "")))
	var snapshot := ch.to_dict().duplicate(true)
	var second := _result(ch, _valid_choices("fighter"))
	_assert_refused(second, "already_level_4")
	assert_eq(ch.to_dict(), snapshot, "a second apply changes nothing")


# 32
func test_refusal_codes_and_messages_are_stable() -> void:
	assert_eq(String(LevelUp.eligibility(null)["code"]), "no_character")
	var bard := _character("kaelen")
	bard.char_class = "Bard"
	assert_eq(String(LevelUp.eligibility(bard)["code"]), "class_not_tabled")
	var low := _character("kaelen")
	low.level = 2
	assert_eq(String(LevelUp.eligibility(low)["code"]), "not_level_3")
	var high := _character("kaelen")
	high.level = 4
	assert_eq(String(LevelUp.eligibility(high)["code"]), "already_level_4")
	assert_eq(String(LevelUp.eligibility(_character("kaelen", 5999))["code"]), "xp_below_threshold")
	_assert_refused(_result(_character("kaelen"), {"ability": "luck", "feat": "Power Attack"}), "unknown_ability")
	_assert_refused(
		_result(_character("kaelen"), {"ability": "str", "feat": "Nonexistent Feat"}),
		"feat_not_implemented"
	)
	for result in [
		_result(_character("kaelen"), {"ability": "str", "skills": {"climb": 3}, "feat": "Power Attack"}),
		_result(_character("kaelen"), {"ability": "str", "skills": {"listen": 2}, "feat": "Power Attack"}),
	]:
		assert_false(String(result.get("code", "")).is_empty())
		assert_false(String(result.get("message", "")).is_empty())


# 33
func test_a_level_three_save_with_six_thousand_xp_is_eligible_after_load() -> void:
	var data: Dictionary = content.characters["kaelen"].duplicate(true)
	data["xp"] = XP
	var ch := Character.from_dict(data, content.items)
	assert_eq(String(LevelUp.eligibility(ch)["code"]), "eligible")
	var result := _result(ch, _valid_choices("fighter"))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(ch.level, 4)
	assert_eq(ch.xp, XP)
	var reloaded := Character.from_dict(ch.to_dict(), content.items)
	assert_eq(reloaded.level, 4)
	assert_eq(reloaded.xp, XP)
	assert_eq(reloaded.max_hp, ch.max_hp)


# 34
func test_a_level_four_save_loads_without_migration() -> void:
	var ch := _character("kaelen")
	assert_true(bool(_result(ch, _valid_choices("fighter"))["ok"]))
	var state := ch.to_dict().duplicate(true)
	var loaded := Character.from_dict(state, content.items)
	assert_eq(String(LevelUp.eligibility(loaded)["code"]), "already_level_4")
	var before := loaded.to_dict().duplicate(true)
	assert_false(bool(_result(loaded, _valid_choices("fighter"))["ok"]))
	assert_eq(loaded.to_dict(), before, "loading a level-4 save changes nothing")


# 35
func test_a_levelled_character_round_trips_through_to_dict_and_from_dict() -> void:
	var ch := _character("mira")
	assert_true(bool(_result(ch, _valid_choices("sorcerer"))["ok"]))
	var state := ch.to_dict().duplicate(true)
	var reloaded := Character.from_dict(state, content.items)
	assert_eq(reloaded.to_dict(), state)
	assert_true(Array(reloaded.spells["known"]).has("scorching_ray"))
	assert_eq(int(reloaded.spells["slots"]["2"]["max"]), 3)
