extends GutTest

## Class progression tables, levels 1-4 (PHB Table 3-1 and 3-2, p. 22; Table 3-6
## p. 31; Table 3-9 p. 39; Table 3-15 p. 49; Table 3-16 p. 52; Table 3-17 p. 54;
## Table 3-18 p. 55).
##
## This batch is data and validation only. It must not change a character, a save,
## XP or any rule; the tests therefore also pin the authored level-3 party as
## accepted inconsistencies rather than silent repairs.

const SHIPPED := ["cleric", "fighter", "rogue", "sorcerer", "wizard"]


func _table() -> Dictionary:
	return ClassProgression.CLASSES


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")


func test_the_five_shipped_classes_are_tabled_for_levels_one_to_four() -> void:
	for key in SHIPPED:
		assert_true(_table().has(key), "%s has a table" % key)
		var rows := Dictionary(Dictionary(_table()[key]).get("rows", {}))
		for level in [1, 2, 3, 4]:
			assert_true(rows.has(level), "%s has a level %d row" % [key, level])


func test_level_three_and_four_rows_match_the_printed_tables() -> void:
	# [base attack, fort, ref, will] at levels 3 and 4 (Table 3-1).
	var expected := {
		"fighter": [[3, 3, 1, 1], [4, 4, 1, 1]],
		"rogue": [[2, 1, 3, 1], [3, 1, 4, 1]],
		"cleric": [[2, 3, 1, 3], [3, 4, 1, 4]],
		"wizard": [[1, 1, 1, 3], [2, 1, 1, 4]],
		"sorcerer": [[1, 1, 1, 3], [2, 1, 1, 4]],
	}
	for key in expected:
		var rows := Dictionary(Dictionary(_table()[key]).get("rows", {}))
		for index in 2:
			var row := Dictionary(rows[3 + index])
			var want: Array = expected[key][index]
			assert_eq(int(row.get("base_attack", -1)), int(want[0]), "%s level %d BAB" % [key, 3 + index])
			assert_eq(int(row.get("fort", -1)), int(want[1]), "%s level %d Fort" % [key, 3 + index])
			assert_eq(int(row.get("ref", -1)), int(want[2]), "%s level %d Ref" % [key, 3 + index])
			assert_eq(int(row.get("will", -1)), int(want[3]), "%s level %d Will" % [key, 3 + index])


func test_hit_dice_and_skill_points_match_the_printed_class_entries() -> void:
	var expected := {"fighter": [10, 2], "rogue": [6, 8], "cleric": [8, 2], "wizard": [4, 2], "sorcerer": [4, 2]}
	for key in expected:
		var data := Dictionary(_table()[key])
		assert_eq(int(data.get("hit_die", 0)), int(expected[key][0]), "%s hit die" % key)
		assert_eq(int(data.get("skill_points", 0)), int(expected[key][1]), "%s skill points per level" % key)


func test_feat_slots_match_the_printed_progression() -> void:
	# General feats at 1st and 3rd; the fighter's class bonus feats at 1st, 2nd, 4th.
	assert_eq(ClassProgression.feat_slots("fighter", 3), 4, "fighter has four feats by level 3")
	assert_eq(ClassProgression.feat_slots("fighter", 4), 5, "fighter gains one at level 4")
	for key in ["rogue", "cleric", "wizard", "sorcerer"]:
		assert_eq(ClassProgression.feat_slots(key, 3), 2, "%s has two feats by level 3" % key)
		assert_eq(ClassProgression.feat_slots(key, 4), 2, "%s gains no feat at level 4" % key)


func test_spell_slots_match_the_printed_tables() -> void:
	# Printed slots per day, 0-level included; the cleric row folds in its domain
	# "+1" column exactly as the table prints it.
	assert_eq(ClassProgression.spell_slots("cleric", 3), {0: 4, 1: 3, 2: 2}, "cleric level 3")
	assert_eq(ClassProgression.spell_slots("cleric", 4), {0: 5, 1: 4, 2: 3}, "cleric level 4")
	assert_eq(ClassProgression.spell_slots("wizard", 3), {0: 4, 1: 2, 2: 1}, "wizard level 3")
	assert_eq(ClassProgression.spell_slots("wizard", 4), {0: 4, 1: 3, 2: 2}, "wizard level 4")
	assert_eq(ClassProgression.spell_slots("sorcerer", 3), {0: 6, 1: 5}, "sorcerer level 3")
	assert_eq(ClassProgression.spell_slots("sorcerer", 4), {0: 6, 1: 6, 2: 3}, "sorcerer level 4")
	assert_eq(ClassProgression.spells_known("sorcerer", 3), {0: 5, 1: 3}, "sorcerer knows at 3")
	assert_eq(ClassProgression.spells_known("sorcerer", 4), {0: 6, 1: 3, 2: 1}, "sorcerer knows at 4")
	assert_eq(ClassProgression.spell_slots("fighter", 4), {}, "a fighter has no spell slots")


func test_the_shipped_table_validates() -> void:
	assert_eq(ClassProgression.validate(), [], "the shipped table has no errors")


func test_validate_rejects_a_missing_class() -> void:
	var table := _table().duplicate(true)
	table.erase("rogue")
	var errors := ClassProgression.validate(table)
	assert_false(errors.is_empty(), "a missing class is an error")
	assert_true(_joined(errors).contains("rogue"), "the error names the missing class")


func test_validate_rejects_a_missing_level_row() -> void:
	var table := _table().duplicate(true)
	Dictionary(table["wizard"])["rows"].erase(3)
	var errors := ClassProgression.validate(table)
	assert_false(errors.is_empty(), "a missing level row is an error")
	assert_true(_joined(errors).contains("wizard"), "the error names the class")
	assert_true(_joined(errors).contains("level 3"), "the error names the missing level")
	Dictionary(table["wizard"])["rows"].erase(4)
	assert_false(ClassProgression.validate(table).is_empty(), "a gap may not crash the validator")


func test_validate_rejects_non_monotonic_base_attack() -> void:
	var table := _table().duplicate(true)
	Dictionary(Dictionary(table["fighter"])["rows"][4])["base_attack"] = 2
	var errors := ClassProgression.validate(table)
	assert_false(errors.is_empty(), "a decreasing base attack is an error")
	assert_true(_joined(errors).contains("base_attack"), "the error names the field")


func test_validate_rejects_non_monotonic_saving_throws() -> void:
	var table := _table().duplicate(true)
	Dictionary(Dictionary(table["cleric"])["rows"][4])["will"] = 2
	var errors := ClassProgression.validate(table)
	assert_false(errors.is_empty(), "a decreasing save is an error")
	assert_true(_joined(errors).contains("will"), "the error names the save")


func test_validate_rejects_an_inconsistent_base_attack_rate() -> void:
	var table := _table().duplicate(true)
	Dictionary(Dictionary(table["wizard"])["rows"][4])["base_attack"] = 3
	var errors := ClassProgression.validate(table)
	assert_false(errors.is_empty(), "a poor-BAB class cannot reach +3 at level 4")
	assert_true(_joined(errors).contains("wizard"), "the error names the class")


func test_validate_rejects_an_inconsistent_save_bonus() -> void:
	var table := _table().duplicate(true)
	Dictionary(Dictionary(table["fighter"])["rows"][3])["fort"] = 2
	var errors := ClassProgression.validate(table)
	assert_false(errors.is_empty(), "a good save mismatching 2 + level/2 is an error")
	assert_true(_joined(errors).contains("fort"), "the error names the save")


func test_validate_rejects_a_bad_hit_die_or_skill_points() -> void:
	var table := _table().duplicate(true)
	Dictionary(table["fighter"])["hit_die"] = 7
	var errors := ClassProgression.validate(table)
	assert_false(errors.is_empty(), "a non-standard hit die is an error")
	var second := _table().duplicate(true)
	Dictionary(second["rogue"])["skill_points"] = -1
	assert_false(ClassProgression.validate(second).is_empty(), "negative skill points are an error")


func test_validate_rejects_spells_on_a_non_caster_and_decreasing_slots() -> void:
	var table := _table().duplicate(true)
	Dictionary(Dictionary(table["fighter"])["rows"][4])["spells"] = {1: 1}
	assert_false(ClassProgression.validate(table).is_empty(), "a fighter cannot have spell slots")
	var second := _table().duplicate(true)
	Dictionary(Dictionary(second["wizard"])["rows"][4])["spells"] = {0: 4, 1: 3, 2: 0}
	assert_false(ClassProgression.validate(second).is_empty(), "a slot may not shrink with level")


func test_expected_hp_matches_every_authored_character() -> void:
	var expected := {"kaelen": 28, "sera": 17, "aldric": 21, "ysolde": 13, "mira": 13}
	for id in expected:
		var data: Dictionary = Game.content.characters[id]
		var con := Rules.ability_mod(int(Dictionary(data["abilities"]).get("con", 10)))
		assert_eq(
			ClassProgression.expected_hp(String(data["class"]).to_lower(), int(data["level"]), con),
			int(expected[id]),
			"%s authored HP follows max-at-1st plus the fixed average" % id
		)


func test_authored_level_three_characters_report_their_accepted_inconsistencies() -> void:
	var found := ClassProgression.authored_inconsistencies(Game.content.characters)
	var keys: Array[String] = []
	for entry in found:
		keys.append("%s/%s" % [String(entry["id"]), String(entry["field"])])
		assert_false(String(entry.get("note", "")).is_empty(), "every finding explains itself")
	keys.sort()
	assert_eq(
		keys,
		[
			"aldric/feats",
			"kaelen/feats",
			"mira/feats",
			"mira/spells.known",
			"mira/spells.slots.1",
			"ysolde/feats",
			"ysolde/spells.slots.1",
			"ysolde/spells.slots.2",
		],
		"the accepted authored inconsistencies are exactly these"
	)


func test_repaired_skill_blocks_fit_the_level_three_budget() -> void:
	# The content repair rebuilt aldric's and mira's blocks inside 12 points and
	# lowered ysolde's search to the cross-class cap; this pins the arithmetic.
	var expected := {
		"aldric": {"spent": 12, "budget": 12},
		"ysolde": {"spent": 18, "budget": 30},
		"mira": {"spent": 12, "budget": 12},
	}
	for id in expected:
		var data: Dictionary = Game.content.characters[id]
		var class_key := String(data["class"]).to_lower()
		var level := int(data["level"])
		var int_modifier := Rules.ability_mod(int(Dictionary(data["abilities"]).get("int", 10)))
		var per_level := int(ClassProgression.class_data(class_key)["skill_points"]) + int_modifier
		var budget := per_level * (level + 3)
		var class_skills: Array = Skills.CLASS_SKILLS.get(class_key, [])
		var spent := 0
		var ranks := Dictionary(data["skill_ranks"])
		for raw_skill in ranks.keys():
			var skill := String(raw_skill)
			var value := int(ranks[raw_skill])
			var is_class := class_skills.has(skill)
			var cap := level + 3 if is_class else (level + 3) / 2
			assert_lte(value, cap, "%s %s %d is within the level-%d cap %d" % [id, skill, value, level, cap])
			spent += value if is_class else value * 2
		assert_eq(budget, int(expected[id]["budget"]), "%s earns the class budget at level %d" % [id, level])
		assert_eq(spent, int(expected[id]["spent"]), "%s spends exactly these points" % id)
		assert_lte(spent, budget, "%s spends no more than the class earns" % id)


func test_no_character_has_a_wrong_base_attack_save_or_hit_points() -> void:	for entry in ClassProgression.authored_inconsistencies(Game.content.characters):
		var field := String(entry["field"])
		assert_false(
			field == "base_attack" or field.begins_with("base_saves.") or field == "max_hp",
			"%s has no table mismatch in %s" % [String(entry["id"]), field]
		)


func _joined(errors: Array) -> String:
	return "\n".join(PackedStringArray(errors))
