extends GutTest

## Player's Handbook core feats and skills (PHB pp.61-102; MM p.304).
##
## Expected values come from Table 4-2, Table 4-5, the feat descriptions and
## the printed stat blocks. Dice are fixed with take 10/20 or seeded RNGs; no
## production rule is changed for a test.

## Printed PHB pages for the fourteen no-prerequisite +2/+2 skill feats.
const SKILL_FEATS := {
	"Acrobatic": {"page": 89, "skills": ["jump", "tumble"]},
	"Agile": {"page": 89, "skills": ["balance", "escape_artist"]},
	"Animal Affinity": {"page": 89, "skills": ["handle_animal", "ride"]},
	"Athletic": {"page": 89, "skills": ["climb", "swim"]},
	"Deceitful": {"page": 93, "skills": ["disguise", "forgery"]},
	"Deft Hands": {"page": 93, "skills": ["sleight_of_hand", "use_rope"]},
	"Diligent": {"page": 93, "skills": ["appraise", "decipher_script"]},
	"Investigator": {"page": 97, "skills": ["gather_information", "search"]},
	"Magical Aptitude": {"page": 97, "skills": ["spellcraft", "use_magic_device"]},
	"Negotiator": {"page": 98, "skills": ["diplomacy", "sense_motive"]},
	"Nimble Fingers": {"page": 98, "skills": ["disable_device", "open_lock"]},
	"Persuasive": {"page": 98, "skills": ["bluff", "intimidate"]},
	"Self-Sufficient": {"page": 100, "skills": ["heal", "survival"]},
	"Stealthy": {"page": 101, "skills": ["hide", "move_silently"]},
}

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 5150


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _fixture(feats: Array = []) -> Character:
	var ch := Character.new()
	ch.id = "fixture"
	ch.display_name = "Fixture"
	ch.char_class = "Fighter"
	ch.level = 3
	ch.base_attack = 3
	ch.abilities = {"str": 14, "dex": 13, "con": 12, "int": 14, "wis": 12, "cha": 10}
	ch.max_hp = 20
	ch.hp = 20
	ch.feats.assign(feats)
	ch.proficiencies = ["simple", "martial", "light_armor", "medium_armor", "heavy_armor", "shield"]
	return ch


func _map(width := 9, height := 7) -> BattleMap:
	var rows: Array = []
	for y in height:
		var row := ""
		for x in width:
			var edge := y == 0 or y == height - 1 or x == 0 or x == width - 1
			row += "#" if edge else "."
		rows.append(row)
	return BattleMap.from_rows(rows, "feats and skills")


func _encounter(party: Array, monsters: Array) -> Encounter:
	var e := Encounter.new()
	var party_cells: Array = []
	var monster_cells: Array = []
	for i in party.size():
		party_cells.append(Vector2i(1 + i, 5))
	for i in monsters.size():
		monster_cells.append(Vector2i(6, 1 + i))
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Feats and skills")
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in initiative order")


func _button_texts(node: Node, out: Array[String]) -> void:
	if node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		_button_texts(child, out)


# ------------------------------------------------------------------- catalog

func test_skill_catalog_covers_table_4_2() -> void:
	assert_eq(Skills.CATALOG.size(), 45, "every Table 4-2 skill is cataloged")
	for key in Skills.CATALOG.keys():
		assert_true(Skills.exists(String(key)))
	assert_eq(Skills.ability("open_lock"), "dex")
	assert_eq(Skills.ability("search"), "int")
	assert_true(Skills.is_trained_only("knowledge_religion"))
	assert_true(Skills.is_trained_only("open_lock"))
	assert_false(Skills.is_trained_only("search"))
	assert_eq(Skills.armor_multiplier("swim"), 2, "Swim doubles the armor check penalty")
	assert_eq(Skills.armor_multiplier("climb"), 1)
	assert_eq(Skills.armor_multiplier("open_lock"), 0)


func test_skill_totals_separate_ranks_ability_and_armor() -> void:
	var sera := _char("sera")
	assert_eq(Skills.total(sera, "open_lock"), 9, "6 ranks + Dex 3")
	assert_eq(Skills.total(sera, "search"), 8, "6 ranks + Int 2")
	var kaelen := _char("kaelen")
	assert_eq(Skills.total(kaelen, "climb"), 3, "4 ranks + Str 3 - chain shirt 2 - shield 2")
	var text := Skills.breakdown_text(kaelen, "climb")
	assert_string_contains(text, "ranks +4")
	assert_string_contains(text, "STR modifier +3")
	assert_string_contains(text, "armor check -4")


func test_skill_focus_adds_three_to_only_the_selected_skill() -> void:
	var plain := _fixture()
	plain.skill_ranks = {"search": 3}
	var focused := _fixture(["Skill Focus (search)"])
	focused.skill_ranks = {"search": 3}
	assert_eq(Skills.total(focused, "search"), Skills.total(plain, "search") + 3)
	assert_eq(Skills.total(focused, "listen"), Skills.total(plain, "listen"))
	assert_true(Feats.has_active(focused, "skill_focus", "search"))
	assert_false(Feats.has_active(focused, "skill_focus", "listen"))


func test_alertness_adds_two_to_listen_and_spot() -> void:
	var plain := _fixture()
	plain.skill_ranks = {"listen": 1, "spot": 1}
	var alert := _fixture(["Alertness"])
	alert.skill_ranks = {"listen": 1, "spot": 1}
	assert_eq(Skills.total(alert, "listen"), Skills.total(plain, "listen") + 2)
	assert_eq(Skills.total(alert, "spot"), Skills.total(plain, "spot") + 2)


func test_skill_feat_catalog_matches_the_printed_descriptions() -> void:
	for feat_name in SKILL_FEATS:
		var expected: Dictionary = SKILL_FEATS[feat_name]
		assert_true(Feats.is_known(String(feat_name)), String(feat_name))
		var parsed := Feats.parse(String(feat_name))
		var data := Feats.entry(String(parsed["key"]))
		assert_eq(int(data.get("page", 0)), int(expected["page"]), String(feat_name))
		assert_eq(Array(data.get("prereqs", [])).size(), 0, String(feat_name))
		assert_false(bool(data.get("repeatable", false)), String(feat_name))
		var targets: Array[String] = []
		for raw in Array(data.get("modifiers", [])):
			var mod: Dictionary = raw
			assert_eq(String(mod.get("type", "")), "untyped", String(feat_name))
			assert_eq(int(mod.get("value", 0)), 2, String(feat_name))
			targets.append(String(mod.get("target", "")))
		var expected_targets: Array[String] = []
		for skill in Array(expected["skills"]):
			expected_targets.append("skill:" + String(skill))
		targets.sort()
		expected_targets.sort()
		assert_eq(targets, expected_targets, String(feat_name))


func test_skill_feats_add_two_to_exactly_their_two_skills() -> void:
	var plain := _fixture()
	for feat_name in SKILL_FEATS:
		var with_feat := _fixture([String(feat_name)])
		var printed: Array = SKILL_FEATS[feat_name]["skills"]
		for skill in Skills.all_keys():
			var key := String(skill)
			var delta := (
				int(Skills.feat_bonus(with_feat, key)["total"])
				- int(Skills.feat_bonus(plain, key)["total"])
			)
			var expected := 2 if printed.has(key) else 0
			assert_eq(delta, expected, "%s on %s" % [feat_name, key])
		var parsed := Feats.parse(String(feat_name))
		assert_true(Feats.has_active(with_feat, String(parsed["key"])), String(feat_name))
		var rows := Feats.describe(with_feat)
		assert_eq(rows.size(), 1, String(feat_name))
		assert_true(bool(rows[0]["active"]), String(feat_name))


func test_skill_feats_stack_with_skill_focus_in_the_breakdown() -> void:
	var plain := _fixture()
	plain.skill_ranks = {"jump": 2}
	var trained := _fixture(["Acrobatic", "Skill Focus (jump)"])
	trained.skill_ranks = {"jump": 2}
	assert_eq(Skills.total(trained, "jump"), Skills.total(plain, "jump") + 5)
	var text := Skills.breakdown_text(trained, "jump")
	assert_string_contains(text, "Acrobatic +2")
	assert_string_contains(text, "Skill Focus (jump) +3")
	assert_eq(int(Skills.feat_bonus(trained, "tumble")["total"]), 2)


func test_skill_feats_do_not_bypass_trained_only_skills() -> void:
	var ch := _fixture(["Magical Aptitude"])
	var result := Skills.check(rng, ch, "spellcraft", 15)
	assert_false(bool(result["available"]))
	assert_string_contains(String(result["reason"]), "trained only")


func test_all_skill_feats_are_valid_content_choices() -> void:
	var ch := _fixture(SKILL_FEATS.keys())
	var errors := Feats.validate_for_character(ch)
	assert_eq(errors.size(), 0, "; ".join(errors))
	assert_eq(Feats.describe(ch).size(), SKILL_FEATS.size())
	for row in Feats.describe(ch):
		assert_true(bool(row["active"]), String(row["name"]))


func test_weapon_proficiency_gates_the_minus_four_penalty() -> void:
	var sword: Dictionary = content.get_item("masterwork_longsword")
	var plain := _fixture()
	plain.proficiencies.clear()
	assert_eq(Rules.weapon_nonproficiency_penalty(plain, sword), -4)
	assert_eq(Rules.attack_bonus(plain, sword, 5), 2, "BAB 3 + Str 2 + masterwork 1 - 4")
	plain.feats.assign(["Martial Weapon Proficiency (longsword)"])
	assert_true(Feats.has_active(plain, "martial_weapon_proficiency", "longsword"))
	assert_eq(Rules.weapon_nonproficiency_penalty(plain, sword), 0)
	assert_eq(Rules.attack_bonus(plain, sword, 5), 6)
	var short_sword: Dictionary = content.get_item("short_sword")
	assert_eq(Rules.weapon_nonproficiency_penalty(plain, short_sword), -4, "a selected martial weapon does not leak")
	var simple := _fixture()
	simple.proficiencies.clear()
	var mace: Dictionary = content.get_item("heavy_mace")
	assert_eq(Rules.weapon_nonproficiency_penalty(simple, mace), -4)
	simple.feats.assign(["Simple Weapon Proficiency"])
	assert_eq(Rules.weapon_nonproficiency_penalty(simple, mace), 0)
	assert_eq(Rules.attack_bonus(simple, mace, 5), 5)


func test_exotic_weapon_proficiency_has_bab_and_strength_exceptions() -> void:
	var weapon := {
		"id": "bastard_sword",
		"name": "Bastard Sword",
		"kind": "weapon",
		"category": "exotic",
		"damage": "1d10",
		"crit_range": 19,
		"crit_mult": 2,
	}
	var ch := _fixture(["Exotic Weapon Proficiency (bastard sword)"])
	ch.proficiencies.clear()
	assert_true(Feats.has_active(ch, "exotic_weapon_proficiency", "bastard sword"))
	assert_eq(Rules.weapon_nonproficiency_penalty(ch, weapon), 0)
	ch.abilities["str"] = 12
	assert_false(Feats.has_active(ch, "exotic_weapon_proficiency", "bastard sword"))
	assert_eq(Rules.weapon_nonproficiency_penalty(ch, weapon), -4, "bastard sword needs Str 13")
	var low_bab := _fixture(["Exotic Weapon Proficiency (bastard sword)"])
	low_bab.base_attack = 0
	assert_false(Feats.has_active(low_bab, "exotic_weapon_proficiency", "bastard sword"))


func test_armor_and_shield_nonproficiency_apply_attack_and_movement_penalties() -> void:
	var ch := _fixture()
	ch.proficiencies.clear()
	ch.equip("armor", content.get_item("chain_shirt"))
	assert_eq(Rules.armor_attack_penalty(ch), -2)
	assert_eq(Rules.skill_armor_check_penalty(ch, "climb"), -2)
	assert_eq(Rules.skill_armor_check_penalty(ch, "ride"), -2, "Ride is explicitly a movement skill")
	assert_eq(Rules.skill_armor_check_penalty(ch, "search"), 0, "Search does not involve moving")
	ch.feats.assign(["Armor Proficiency (light)"])
	assert_eq(Rules.armor_attack_penalty(ch), 0)
	assert_eq(Rules.skill_armor_check_penalty(ch, "climb"), -2, "standard light-armor penalty remains")
	assert_eq(Rules.skill_armor_check_penalty(ch, "ride"), 0, "proficient armor does not hit Ride")
	var combined := _fixture()
	combined.proficiencies.clear()
	combined.equip("armor", content.get_item("scale_mail"))
	combined.equip("shield", content.get_item("heavy_steel_shield"))
	assert_eq(Rules.armor_attack_penalty(combined), -6, "armor and shield penalties stack on attacks")
	assert_eq(Rules.skill_armor_check_penalty(combined, "ride"), -6)
	ch.equip("armor", content.get_item("scale_mail"))
	assert_eq(Rules.armor_attack_penalty(ch), -4, "light proficiency does not cover medium armor")
	ch.feats.assign(["Armor Proficiency (light)", "Armor Proficiency (medium)"])
	assert_eq(Rules.armor_attack_penalty(ch), 0)
	assert_eq(Rules.skill_armor_check_penalty(ch, "climb"), -4)
	ch.equip("shield", content.get_item("heavy_steel_shield"))
	assert_eq(Rules.armor_attack_penalty(ch), -2)
	assert_eq(Rules.skill_armor_check_penalty(ch, "climb"), -6)
	ch.feats.append("Shield Proficiency")
	assert_eq(Rules.armor_attack_penalty(ch), 0)
	assert_eq(Rules.skill_armor_check_penalty(ch, "climb"), -6, "standard shield penalty remains")


func test_class_proficiencies_keep_shipped_attacks_unchanged() -> void:
	var kaelen := _char("kaelen")
	var sera := _char("sera")
	var ysolde := _char("ysolde")
	assert_eq(Rules.armor_attack_penalty(kaelen), 0)
	assert_eq(Rules.armor_attack_penalty(sera), 0)
	assert_eq(Rules.weapon_nonproficiency_penalty(kaelen, content.get_item("masterwork_longsword")), 0)
	assert_eq(Rules.weapon_nonproficiency_penalty(sera, content.get_item("short_sword")), 0)
	assert_eq(Rules.weapon_nonproficiency_penalty(ysolde, content.get_item("dagger")), 0)
	assert_eq(Rules.attack_bonus(kaelen, content.get_item("masterwork_longsword"), 5), 8)


func test_armor_proficiency_prerequisites_are_enforced() -> void:
	var ch := _fixture(["Armor Proficiency (heavy)"])
	ch.proficiencies.clear()
	var errors := Feats.validate_for_character(ch)
	assert_gt(errors.size(), 0)
	var joined := "; ".join(errors)
	assert_string_contains(joined, "Armor Proficiency (light)")
	assert_string_contains(joined, "Armor Proficiency (medium)")


func test_proficiency_grants_and_legacy_saves_survive_round_trip() -> void:
	var ch := _fixture(["Martial Weapon Proficiency (longsword)"])
	ch.proficiencies.clear()
	var data := ch.to_dict()
	assert_eq(int(data["proficiency_schema"]), 2)
	var restored := Character.from_dict(data, content.items)
	assert_true(
		Feats.is_weapon_proficient(restored, content.get_item("masterwork_longsword")),
		"the feat grant survives serialization"
	)
	var legacy := ch.to_dict()
	legacy.erase("proficiency_schema")
	legacy["proficiencies"] = ["simple", "martial"]
	var migrated := Character.from_dict(legacy, content.items)
	assert_true(migrated.proficiencies.has("light_armor"), "legacy fighter gets armor proficiency once")
	assert_true(migrated.proficiencies.has("shield"))
	assert_eq(int(migrated.proficiency_schema), 2)


func test_synergies_need_five_ranks_and_match_the_context() -> void:
	var ch := _fixture()
	ch.skill_ranks = {"search": 5, "knowledge_religion": 5}
	assert_eq(Skills.total(ch, "survival"), 1, "Wis 12 only without the tracking use")
	assert_eq(Skills.total(ch, "survival", {"context": "tracking"}), 3)
	assert_eq(Skills.synergy_bonus(ch, "turn_undead"), 2)
	ch.skill_ranks["knowledge_religion"] = 4
	assert_eq(Skills.synergy_bonus(ch, "turn_undead"), 0, "four ranks is not enough")


func test_typed_bonuses_stack_by_type_dodge_and_circumstance() -> void:
	var stacked := Rules.stack_bonuses(
		[
			{"value": 1, "type": "morale", "source": "bless"},
			{"value": 2, "type": "morale", "source": "heroism"},
			{"value": 1, "type": "dodge", "source": "dodge"},
			{"value": 1, "type": "dodge", "source": "haste"},
			{"value": 2, "type": "circumstance", "source": "high ground"},
			{"value": 2, "type": "circumstance", "source": "aid"},
			{"value": 1, "type": "circumstance", "source": "high ground"},
			{"value": 1, "type": "untyped", "source": "luck"},
			{"value": 2, "type": "untyped", "source": "insight"},
		]
	)
	assert_eq(int(stacked["total"]), 11)
	assert_eq(Array(stacked["entries"]).size(), 7)  # two untyped, two dodge, two circumstance, one morale
	var penalties := Rules.stack_bonuses(
		[
			{"value": -1, "type": "morale", "source": "shaken"},
			{"value": -2, "type": "morale", "source": "sickened"},
		]
	)
	assert_eq(int(penalties["total"]), -3, "penalties of the same type stack")


func test_trained_only_checks_explain_the_missing_ranks() -> void:
	var mira := _char("mira")
	var check := Skills.check(rng, mira, "disable_device", 10)
	assert_false(bool(check["available"]))
	assert_string_contains(String(check["reason"]), "trained only")
	var untrained := _fixture()
	assert_eq(Skills.total(untrained, "search"), 2, "untrained Search is Int only")


func test_take_10_and_20_follow_the_retry_restrictions() -> void:
	var sera := _char("sera")
	var ten := Skills.check(rng, sera, "open_lock", 20, {"take": 10})
	assert_eq(int(ten["roll"]), 10)
	assert_eq(int(ten["total"]), 19)
	assert_false(bool(ten["success"]))
	var twenty := Skills.check(rng, sera, "open_lock", 20, {"take": 20})
	assert_eq(int(twenty["roll"]), 20)
	assert_eq(int(twenty["total"]), 29)
	assert_true(bool(twenty["success"]))
	var threatened := Skills.check(rng, sera, "open_lock", 20, {"take": 10, "threatened": true})
	assert_false(bool(threatened["available"]))
	assert_string_contains(String(threatened["reason"]), "threatened")
	var risky := Skills.check(
		rng, sera, "open_lock", 20, {"take": 20, "failure_penalty": true}
	)
	assert_false(bool(risky["available"]))
	assert_string_contains(String(risky["reason"]), "failure carries a penalty")


func test_ability_check_supports_take_10() -> void:
	var ch := _fixture()
	var check := Rules.ability_check(rng, ch, "str", 15, {"take": 10})
	assert_true(bool(check["available"]))
	assert_eq(int(check["roll"]), 10)
	assert_eq(int(check["total"]), 12, "Str 14 modifier +2")


func test_aid_another_grants_two_only_on_a_dc_10_check() -> void:
	var sera := _char("sera")
	var helped := Skills.aid_another(rng, sera, "search", {"take": 10})
	assert_eq(int(helped["bonus"]), 2)
	var weak := _fixture()
	weak.abilities["int"] = 8
	var failed := Skills.aid_another(rng, weak, "search", {"take": 10})
	assert_eq(int(failed["bonus"]), 0, "Int 8 take 10 is a 9, short of DC 10")


func test_opposed_checks_use_totals_and_defender_on_a_tie() -> void:
	var sera := _char("sera")
	var kaelen := _char("kaelen")
	var result := Skills.opposed_check(
		rng,
		sera,
		"move_silently",
		kaelen,
		"listen",
		{"actor": {"take": 10}, "defender": {"take": 10}}
	)
	assert_eq(String(result["winner"]), "actor", "9 beats 3")
	var a := _fixture()
	var b := _fixture()
	var tie := Skills.opposed_check(
		rng,
		a,
		"hide",
		b,
		"hide",
		{"actor": {"take": 10}, "defender": {"take": 10}, "ties": "defender"}
	)
	assert_eq(String(tie["winner"]), "defender", "the observer wins Hide ties")
	assert_eq(int(tie["rerolls"]), 0)


func test_rank_caps_distinguish_class_and_cross_class_skills() -> void:
	var sera := _char("sera")
	var ysolde := _char("ysolde")
	assert_eq(Skills.max_ranks(sera, "search"), 6, "level 3 + 3, class skill")
	assert_eq(Skills.max_ranks(ysolde, "search"), 3, "half the class-skill cap")
	assert_eq(Skills.max_ranks(_char("kaelen"), "climb"), 6)
	var illegal := _fixture()
	illegal.skill_ranks = {"search": 7}
	assert_false(Skills.ranks_legal(illegal, "search"))


# ---------------------------------------------------------------------- feats

func test_save_feats_add_two_to_the_matching_save() -> void:
	var plain := _fixture()
	var iron_will := _fixture(["Iron Will"])
	var lightning := _fixture(["Lightning Reflexes"])
	var fortitude := _fixture(["Great Fortitude"])
	assert_eq(Rules.saving_throw_bonus(iron_will, "will"), Rules.saving_throw_bonus(plain, "will") + 2)
	assert_eq(Rules.saving_throw_bonus(lightning, "ref"), Rules.saving_throw_bonus(plain, "ref") + 2)
	assert_eq(Rules.saving_throw_bonus(fortitude, "fort"), Rules.saving_throw_bonus(plain, "fort") + 2)
	assert_eq(Rules.saving_throw_bonus(iron_will, "fort"), Rules.saving_throw_bonus(plain, "fort"))


func test_dodge_requires_dexterity_13_and_adds_one_dodge_bonus() -> void:
	var ch := _fixture()
	var base := Rules.armor_class(ch)
	ch.feats.assign(["Dodge"])
	assert_eq(Rules.armor_class(ch), base + 1)
	assert_eq(Rules.touch_ac(ch), 11 + 1, "Dodge also applies to touch AC")
	var low := _fixture(["Dodge"])
	low.abilities["dex"] = 12
	assert_eq(Rules.armor_class(low), 11, "Dex 12 does not qualify for Dodge")
	var rows := Feats.describe(low)
	assert_false(bool(rows[0]["active"]))
	assert_string_contains(String(rows[0]["reason"]), "DEX 13")


func test_weapon_focus_is_exact_and_requires_proficiency_and_bab() -> void:
	var kaelen := _char("kaelen")
	var sword: Dictionary = content.get_item("masterwork_longsword")
	assert_eq(Rules.attack_bonus(kaelen, sword, 5), 8, "BAB 3 + Str 3 + masterwork 1 + feat 1")
	kaelen.feats.erase("Weapon Focus (longsword)")
	assert_eq(Rules.attack_bonus(kaelen, sword, 5), 7)
	var short_sword: Dictionary = content.get_item("short_sword")
	assert_eq(
		Rules.attack_bonus(_char("kaelen"), short_sword, 5),
		Rules.attack_bonus(kaelen, short_sword, 5),
		"longsword focus does not leak onto a short sword"
	)
	var unproficient := _fixture(["Weapon Focus (longsword)"])
	unproficient.proficiencies.clear()
	assert_false(Feats.has_active(unproficient, "weapon_focus", "longsword"))
	var errors := Feats.validate_for_character(unproficient)
	assert_gt(errors.size(), 0)
	assert_string_contains(String(errors[0]), "proficiency")
	var low_bab := _fixture(["Weapon Focus (longsword)"])
	low_bab.proficiencies = ["martial"]
	low_bab.base_attack = 0
	assert_false(Feats.has_active(low_bab, "weapon_focus", "longsword"))
	var short_only := _fixture(["Weapon Focus (sword)"])
	short_only.proficiencies = ["short_sword"]
	assert_true(Feats.is_proficient(short_only, "short sword"))
	assert_false(Feats.is_proficient(short_only, "sword"), "a short sword is not a sword focus")
	assert_false(Feats.has_active(short_only, "weapon_focus", "sword"))


func test_weapon_finesse_swaps_strength_for_dexterity() -> void:
	var sera := _char("sera")
	var sword: Dictionary = content.get_item("short_sword")
	assert_eq(Rules.attack_bonus(sera, sword, 5), 5, "BAB 2 + Dex 3")
	sera.feats.erase("Weapon Finesse")
	assert_eq(Rules.attack_bonus(sera, sword, 5), 3, "BAB 2 + Str 1")


func test_point_blank_shot_applies_only_within_thirty_feet() -> void:
	var archer := _fixture(["Point Blank Shot"])
	archer.base_attack = 2
	archer.abilities["dex"] = 14
	var bow: Dictionary = content.get_item("light_crossbow")
	assert_eq(Rules.attack_bonus(archer, bow, 10), 5, "BAB 2 + Dex 2 + feat 1")
	assert_eq(Rules.attack_bonus(archer, bow, 40), 4)
	assert_eq(Rules.damage_bonus(archer, bow, 10), 1)
	assert_eq(Rules.damage_bonus(archer, bow, 40), 0)


func test_improved_initiative_reaches_the_encounter_roll() -> void:
	var ch := _fixture(["Improved Initiative"])
	assert_eq(Feats.initiative_bonus(ch), 4)
	var e := _encounter([ch], [_monster("zombie")])
	var found := false
	for line in e.log_lines:
		if String(line).begins_with("Initiative: Fixture") and String(line).contains("+5 ="):
			found = true
	assert_true(found, "Dex 13 + Improved Initiative 4 is the logged initiative bonus")


func test_toughness_adds_three_hit_points_once() -> void:
	var data := {
		"id": "tough",
		"name": "Tough",
		"class": "Fighter",
		"level": 1,
		"abilities": {"str": 10, "dex": 10, "con": 10, "int": 10, "wis": 10, "cha": 10},
		"max_hp": 20,
		"hp": 20,
		"feats": ["Toughness"],
	}
	var ch := Character.from_content(data, content.items)
	assert_eq(ch.max_hp, 23)
	assert_eq(ch.hp, 23)
	var loaded := Character.from_dict(ch.to_dict(), content.items)
	assert_eq(loaded.max_hp, 23, "loading a save must not add Toughness again")
	assert_eq(loaded.hp, 23)
	var twice := data.duplicate(true)
	twice["id"] = "tough_twice"
	twice["feats"] = ["Toughness", "Toughness"]
	assert_eq(Character.from_content(twice, content.items).max_hp, 26, "Toughness is repeatable")
	var raw: Dictionary = content.get_monster("infected_zombie")
	assert_eq(int(raw["max_hp"]), 39, "the stat block's authored base without the feat")
	assert_eq(_monster("infected_zombie").max_hp, 42, "39 base + Toughness 3")


func test_multiattack_changes_only_secondary_natural_attacks() -> void:
	var ghoul := _monster("ghoul")
	var bite: Dictionary = ghoul.attacks[0]
	var claw: Dictionary = ghoul.attacks[1]
	assert_eq(Rules.attack_bonus(ghoul, bite, 5), 2, "bite +2")
	assert_eq(Rules.attack_bonus(ghoul, claw, 5), 0, "claw +0 with Multiattack")
	ghoul.feats.clear()
	assert_eq(Rules.attack_bonus(ghoul, bite, 5), 2, "the primary bite is unaffected")
	assert_eq(Rules.attack_bonus(ghoul, claw, 5), -3, "secondary attack without Multiattack")


func test_unknown_feats_are_inert_and_reported() -> void:
	var ch := _fixture(["Great Cleave"])
	assert_false(Feats.is_known("Great Cleave"))
	assert_eq(int(Feats.modifier(ch, "attack")["total"]), 0)
	var rows := Feats.describe(ch)
	assert_false(bool(rows[0]["active"]))
	assert_string_contains(String(rows[0]["reason"]), "not implemented")
	var errors := Feats.validate_for_character(ch)
	assert_gt(errors.size(), 0)
	assert_string_contains(String(errors[0]), "unimplemented")


func test_shipped_characters_and_monsters_have_legal_feats() -> void:
	assert_eq(content.errors.size(), 0, "\n".join(content.errors))
	for id in content.characters.keys():
		var ch := Character.from_content(content.get_character(String(id)), content.items)
		var errors := Feats.validate_for_character(ch)
		assert_eq(errors.size(), 0, "%s: %s" % [id, "; ".join(errors)])
	for id in content.monsters.keys():
		var ch := Character.from_content(content.get_monster(String(id)), content.items)
		var errors := Feats.validate_for_character(ch)
		assert_eq(errors.size(), 0, "%s: %s" % [id, "; ".join(errors)])


func test_turn_undead_requires_a_presented_holy_symbol() -> void:
	var aldric := _char("aldric")
	var ghoul := _monster("ghoul")
	var e := _encounter([aldric], [ghoul])
	_force_turn(e, aldric)
	assert_true(bool(e.can_active_turn_undead()["ok"]))
	aldric.remove_from_inventory("holy_symbol", 1)
	var status := e.can_active_turn_undead()
	assert_false(bool(status["ok"]))
	assert_string_contains(String(status["reason"]), "holy symbol")
	aldric.add_to_inventory(content.get_item("holy_symbol"), 1)
	assert_true(bool(e.can_active_turn_undead()["ok"]), "presenting the symbol restores the option")


# --------------------------------------------------------------- exploration

func test_exploration_exposes_take_10_and_20_controls() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 2027)
	var screen := ExplorationScreen.new()
	add_child_autofree(screen)
	await wait_frames(3)
	var labels: Array[String] = []
	_button_texts(screen, labels)
	assert_true(labels.has("Take 10 check"), "the player can choose take 10")
	assert_true(labels.has("Take 20 check"), "the player can choose take 20")


func test_take_20_searches_the_crate_without_a_roll() -> void:
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 2028)
	Game.position = Vector2i(8, 7)
	Game.facing = Dungeon.NORTH
	var result := Game.interact_with_take(20)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(Game.flags.get("found_clapper", false)))
	assert_true(Game.dungeon.is_removed("supply_crate"))
	var text := "\n".join(Game.log_lines)
	assert_string_contains(text, "take 20 → 20")
