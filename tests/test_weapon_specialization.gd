extends GutTest

## Batch 7 of ROADMAP.md: Weapon Specialization as the fighter's 4th-level bonus
## feat (PHB 3.5 p. 102).
##
## Printed rules, confirmed before coding: prerequisites are proficiency with the
## selected weapon, Weapon Focus with the selected weapon, and fighter level 4th;
## the benefit is +2 on damage rolls with that weapon; the feat may be taken again
## for a new weapon and its effects do not stack; a fighter may select it as a bonus
## feat.
##
## How `class_level` is evaluated, pinned here. The requirement's `class` must equal
## the character's single `char_class` string case-insensitively, and then `ch.level`
## - character level, because this build stores exactly one level - must reach the
## printed value. The repository has no multiclass model: a character owns one class
## string and one level. Any string that is not the required class is refused, never
## parsed: a different class, an empty string, or a composite such as "Fighter/Rogue".
##
## Why "same weapon" is a weapon comparison and not text equality: the level-up
## screen offers weapon parameters as item ids ("masterwork_longsword"), while the
## authored Weapon Focus is written as "Weapon Focus (longsword)". The prerequisite
## therefore asks whether the character owns Weapon Focus for the selected weapon,
## using the same matcher the Weapon Focus bonus itself uses.

const SWORD := "masterwork_longsword"
const SPECIALIZATION := "Weapon Specialization (masterwork_longsword)"

var content: ContentDB


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	content = Game.content


func _char(id: String) -> Character:
	var ch := Character.from_content(
		Dictionary(content.characters[id]).duplicate(true), content.items
	)
	ch.hp = ch.max_hp
	return ch


func _weapon(id: String) -> Dictionary:
	return Dictionary(content.items[id]).duplicate(true)


func _with_feats(id: String, level: int, feats: Array) -> Character:
	var ch := _char(id)
	ch.level = level
	ch.xp = 6000 if level >= 4 else 3000
	ch.feats.clear()
	for feat in feats:
		ch.feats.append(String(feat))
	return ch


func _reasons(check: Dictionary) -> String:
	return "; ".join(PackedStringArray(check.get("reasons", [])))


# -------------------------------------------------------------------- catalog


func test_the_catalog_entry_carries_the_printed_rules() -> void:
	var data := Dictionary(Feats.CATALOG.get("weapon_specialization", {}))
	assert_false(data.is_empty(), "the feat is in the catalog")
	assert_eq(String(data.get("name", "")), "Weapon Specialization", "the printed name")
	assert_true(bool(data.get("fighter_bonus", false)), "a fighter may select it as a bonus feat")
	assert_eq(String(data.get("parameter", "")), "weapon", "it is chosen per weapon")
	assert_eq(int(data.get("page", 0)), 102, "PHB p. 102")
	assert_true(bool(data.get("repeatable", false)), "it may be taken for a new weapon")
	assert_false(bool(data.get("stacks", true)), "its effects do not stack")

	var types: Array[String] = []
	for raw in Array(data.get("prereqs", [])):
		types.append(String(Dictionary(raw).get("type", "")))
	assert_has(types, "proficient", "proficiency with the selected weapon")
	assert_has(types, "feat", "Weapon Focus with the selected weapon")
	assert_has(types, "class_level", "fighter level 4th")

	var modifiers := Array(data.get("modifiers", []))
	assert_eq(modifiers.size(), 1, "one modifier")
	var modifier := Dictionary(modifiers[0])
	assert_eq(String(modifier.get("target", "")), "damage", "+2 on damage rolls")
	assert_eq(int(modifier.get("value", 0)), 2, "the printed +2")
	assert_true(bool(modifier.get("weapon_parameter", false)), "only the selected weapon")


# ------------------------------------------------------------- prerequisite


func test_a_fourth_level_fighter_with_matching_weapon_focus_is_accepted() -> void:
	var ch := _with_feats("kaelen", 4, ["Iron Will", "Weapon Focus (longsword)"])
	var check := Feats.prereqs(ch, "weapon_specialization", SWORD)
	assert_true(bool(check.get("ok", false)), "accepted: %s" % _reasons(check))


func test_a_third_level_fighter_is_refused() -> void:
	var ch := _with_feats("kaelen", 3, ["Iron Will", "Weapon Focus (longsword)"])
	var check := Feats.prereqs(ch, "weapon_specialization", SWORD)
	assert_false(bool(check.get("ok", true)), "refused below fighter level 4")
	assert_true(_reasons(check).contains("fighter level 4"), "the reason is the class level: %s" % _reasons(check))


func test_weapon_focus_for_another_weapon_is_refused() -> void:
	var ch := _with_feats("kaelen", 4, ["Iron Will", "Weapon Focus (dagger)"])
	var sword := Feats.prereqs(ch, "weapon_specialization", SWORD)
	assert_false(bool(sword.get("ok", true)), "no Weapon Focus with the longsword")
	assert_true(sword.get("reasons", []).size() > 0, "and it states why")
	var dagger := Feats.prereqs(ch, "weapon_specialization", "dagger")
	assert_true(bool(dagger.get("ok", false)), "the dagger, which is focused, is accepted")


func test_no_weapon_focus_at_all_is_refused() -> void:
	var ch := _with_feats("kaelen", 4, ["Iron Will"])
	var check := Feats.prereqs(ch, "weapon_specialization", SWORD)
	assert_false(bool(check.get("ok", true)), "refused without Weapon Focus")


func test_a_non_fighter_is_refused() -> void:
	var ch := _with_feats("sera", 4, ["Weapon Focus (dagger)"])
	var check := Feats.prereqs(ch, "weapon_specialization", "dagger")
	assert_false(bool(check.get("ok", true)), "a rogue is not a fighter")
	assert_true(_reasons(check).contains("fighter level 4"), "the reason is the class level: %s" % _reasons(check))


## The only multiclass the repository can express is a class *string*. It is not
## parsed: a composite never equals the required class and is refused.
func test_a_composite_class_string_is_not_parsed() -> void:
	var ch := _with_feats("kaelen", 4, ["Weapon Focus (dagger)"])
	ch.char_class = "Fighter/Rogue"
	var check := Feats.prereqs(ch, "weapon_specialization", "dagger")
	assert_false(bool(check.get("ok", true)), "a composite string is refused")
	assert_true(_reasons(check).contains("Fighter/Rogue"), "and names the character's own string: %s" % _reasons(check))

	ch.char_class = ""
	var empty := Feats.prereqs(ch, "weapon_specialization", "dagger")
	assert_false(bool(empty.get("ok", true)), "an empty class is refused too")


func test_the_feat_is_refused_without_a_selected_weapon() -> void:
	var ch := _with_feats("kaelen", 4, ["Weapon Focus (longsword)"])
	var check := Feats.prereqs(ch, "weapon_specialization", "")
	assert_false(bool(check.get("ok", true)), "the parameter is required")


# ------------------------------------------------------------------ damage


## The bonus must reach the combat damage path, not just the character's feat list.
func test_the_bonus_reaches_damage_only_for_the_selected_weapon() -> void:
	var plain := _with_feats("kaelen", 4, ["Weapon Focus (longsword)"])
	var specialized := _with_feats("kaelen", 4, ["Weapon Focus (longsword)", SPECIALIZATION])
	var sword := _weapon(SWORD)
	var dagger := _weapon("dagger")

	assert_eq(
		Rules.damage_bonus(specialized, sword) - Rules.damage_bonus(plain, sword),
		2,
		"Rules.damage_bonus adds the printed +2 with the selected weapon",
	)
	assert_eq(
		Rules.damage_bonus(specialized, dagger),
		Rules.damage_bonus(plain, dagger),
		"another weapon's damage is unchanged",
	)
	assert_eq(
		int(Feats.modifier(specialized, "damage", {"weapon": sword}).get("total", 0)),
		2,
		"Feats.modifier reports the +2 for the selected weapon",
	)
	assert_eq(
		int(Feats.modifier(specialized, "damage", {"weapon": dagger}).get("total", 0)),
		0,
		"and nothing for another weapon",
	)


## Prerequisites are re-checked at every use, so a character who no longer qualifies
## gets nothing.
func test_the_bonus_is_suspended_when_the_class_prerequisite_is_lost() -> void:
	var demoted := _with_feats("kaelen", 3, ["Weapon Focus (longsword)", SPECIALIZATION])
	var plain := _with_feats("kaelen", 3, ["Weapon Focus (longsword)"])
	var sword := _weapon(SWORD)
	assert_eq(
		Rules.damage_bonus(demoted, sword),
		Rules.damage_bonus(plain, sword),
		"a 3rd-level fighter gets no specialization damage",
	)


# ------------------------------------------------------------------ screen


func test_the_level_up_screen_offers_it_for_the_selected_weapon() -> void:
	var ch := _with_feats("kaelen", 3, ["Iron Will", "Weapon Focus (longsword)"])
	var rows := LevelChoices.feat_options(ch, {"ability": "str"})
	var eligible: Array[String] = []
	var ineligible: Array[String] = []
	for raw in rows:
		var row := Dictionary(raw)
		if String(row.get("key", "")) != "weapon_specialization":
			continue
		if bool(row.get("eligible", false)):
			eligible.append(String(row.get("text", "")))
		else:
			ineligible.append(String(row.get("text", "")))
	assert_has(eligible, SPECIALIZATION, "the same-weapon row is offered and eligible")
	assert_true(
		ineligible.has("Weapon Specialization (dagger)"),
		"a weapon without Weapon Focus is listed but not eligible",
	)

	ch.xp = 6000
	var choices := LevelChoices.choices(ch, {})
	var offered: Array[String] = []
	for raw in Array(choices.get("feat", {}).get("options", [])):
		offered.append(String(Dictionary(raw).get("text", "")))
	assert_has(offered, SPECIALIZATION, "an eligible fighter's screen data offers it")


func test_a_completed_draft_stages_with_the_feat() -> void:
	var ch := _with_feats("kaelen", 3, ["Iron Will", "Weapon Focus (longsword)"])
	var skills := AdvancementCheck.full_skill_spend(ch, "str")
	var draft := {
		"ability": "str",
		"skills": skills,
		"feat": SPECIALIZATION,
	}
	var staged := LevelUp.stage(ch, draft, true)
	assert_true(bool(staged.get("ok", false)), "the draft stages: %s" % String(staged.get("code", "")))
	if not bool(staged.get("ok", false)):
		return
	var after: Character = staged["staged"]
	assert_true(after.feats.has(SPECIALIZATION), "the staged character holds the feat")
