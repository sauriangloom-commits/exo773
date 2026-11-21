extends GutTest

## Rule-calculation tests. Every expected value is derived from the PHB
## formulas documented in src/core/rules.gd and docs/TRACEABILITY.md.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 4242


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func test_ability_modifiers_follow_table_1_1() -> void:
	assert_eq(Rules.ability_mod(1), -5)
	assert_eq(Rules.ability_mod(8), -1)
	assert_eq(Rules.ability_mod(9), -1)
	assert_eq(Rules.ability_mod(10), 0)
	assert_eq(Rules.ability_mod(11), 0)
	assert_eq(Rules.ability_mod(12), 1)
	assert_eq(Rules.ability_mod(16), 3)
	assert_eq(Rules.ability_mod(18), 4)
	assert_eq(Rules.ability_mod(20), 5)


func test_fighter_armor_class_with_armor_shield_and_dex() -> void:
	var kaelen := _char("kaelen")
	# 10 + chain shirt 4 + heavy shield 2 + Dex 1
	assert_eq(Rules.armor_class(kaelen), 17)
	assert_eq(Rules.touch_ac(kaelen), 11)
	assert_eq(Rules.armor_class(kaelen, {"flat_footed": true}), 16)


func test_rogue_dodge_and_light_armor() -> void:
	var sera := _char("sera")
	# 10 + leather 2 + Dex 3 + Dodge 1
	assert_eq(Rules.armor_class(sera), 16)
	# Touch AC includes dodge bonus: 10 + Dex 3 + Dodge 1
	assert_eq(Rules.touch_ac(sera), 14)


func test_mage_armor_is_an_armor_bonus_and_does_not_stack() -> void:
	var ysolde := _char("ysolde")
	assert_eq(Rules.armor_class(ysolde), 13, "10 + Dex 2 + Dodge 1")
	ysolde.add_effect("mage_armor", "Mage Armor", 1800, "buff")
	assert_eq(Rules.armor_class(ysolde), 17, "10 + mage armor 4 + Dex 2 + Dodge 1")


func test_helpless_target_has_dexterity_zero() -> void:
	var sera := _char("sera")
	sera.add_effect("paralyzed", "Paralyzed", 2)
	# PHB p.153: helpless Dexterity is 0 (-5), not merely denied. PHB p.136: a
	# denied Dexterity bonus also denies dodge bonuses, so Sera's Dodge feat does
	# not apply either: 10 + leather 2 - 5 = 7.
	assert_eq(Rules.armor_class(sera), 7)


func test_skill_totals_include_ability_and_armor_check_penalty() -> void:
	var sera := _char("sera")
	assert_eq(Rules.skill_total(sera, "open_lock"), 9, "6 ranks + Dex 3")
	assert_eq(Rules.skill_total(sera, "search"), 8, "6 ranks + Int 2")
	var kaelen := _char("kaelen")
	# Climb 4 + Str 3 + armor check (-2 chain shirt, -2 heavy shield)
	assert_eq(Rules.skill_total(kaelen, "climb"), 3)


func test_attack_bonus_melee_includes_masterwork_and_weapon_focus() -> void:
	var kaelen := _char("kaelen")
	var sword: Dictionary = content.get_item("masterwork_longsword")
	# BAB 3 + Str 3 + masterwork 1 + Weapon Focus 1
	assert_eq(Rules.attack_bonus(kaelen, sword, 0), 8)


func test_weapon_finesse_uses_dex_for_light_weapons() -> void:
	var sera := _char("sera")
	var sword: Dictionary = content.get_item("short_sword")
	# BAB 2 + Dex 3 (finesse), not Str 1
	assert_eq(Rules.attack_bonus(sera, sword, 0), 5)


func test_range_increment_penalties() -> void:
	var sera := _char("sera")
	var bow: Dictionary = content.get_item("light_crossbow")
	# BAB 2 + Dex 3 = 5
	assert_eq(Rules.attack_bonus(sera, bow, 80), 5, "first 80 ft. increment has no penalty")
	assert_eq(Rules.attack_bonus(sera, bow, 85), 3, "second increment -2")
	assert_eq(Rules.attack_bonus(sera, bow, 240), 1, "third increment -4")


func test_saving_throw_bonuses_include_feats() -> void:
	var kaelen := _char("kaelen")
	assert_eq(Rules.saving_throw_bonus(kaelen, "fort"), 5, "base 3 + Con 2")
	assert_eq(Rules.saving_throw_bonus(kaelen, "ref"), 2, "base 1 + Dex 1")
	assert_eq(Rules.saving_throw_bonus(kaelen, "will"), 4, "base 1 + Wis 1 + Iron Will 2")


func test_attack_result_is_auditable_against_seeded_die() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var sword: Dictionary = content.get_item("masterwork_longsword")
	var result := Rules.attack(rng, kaelen, zombie, sword, 5)
	# Replay the same first d20 from the same seed.
	var replay := RandomNumberGenerator.new()
	replay.seed = 4242
	assert_eq(int(result["roll"]), replay.randi_range(1, 20))
	assert_eq(int(result["bonus"]), Rules.attack_bonus(kaelen, sword, 5))
	assert_eq(int(result["total"]), int(result["roll"]) + int(result["bonus"]))
	assert_eq(bool(result["hit"]), int(result["total"]) >= int(result["target_ac"]) and int(result["roll"]) != 1)


func test_natural_one_always_misses() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var sword: Dictionary = content.get_item("masterwork_longsword")
	var found := false
	for i in 400:
		var result := Rules.attack(rng, kaelen, zombie, sword, 5)
		if int(result["roll"]) == 1:
			found = true
			assert_false(bool(result["hit"]), "natural 1 must miss")
	assert_true(found, "expected a natural 1 within 400 seeded rolls")


func test_critical_threat_has_confirmation_and_multiplied_dice() -> void:
	var kaelen := _char("kaelen")
	# Use a living target: undead are immune to critical hits (MM p.317), so a
	# zombie cannot exercise the confirmation path.
	var target := _char("sera")
	var sword: Dictionary = content.get_item("masterwork_longsword")
	var found_confirmed := false
	for i in 600:
		var result := Rules.attack(rng, kaelen, target, sword, 5)
		if bool(result["hit"]) and bool(result.get("critical", false)):
			assert_true(result.has("confirm_roll"), "critical threats roll confirmation")
			if bool(result.get("critical_confirmed", false)):
				found_confirmed = true
				assert_eq(int(result.get("damage_multiplier", 1)), 2)
				assert_eq(Array(result["damage_rolls"]).size(), 2, "crit rolls damage dice twice")
	assert_true(found_confirmed, "expected at least one confirmed critical within 600 rolls")


func test_skill_check_reports_dc_and_actor() -> void:
	var sera := _char("sera")
	var check := Rules.skill_check(rng, sera, "open_lock", 15)
	assert_eq(int(check["bonus"]), 9)
	assert_eq(int(check["dc"]), 15)
	assert_eq(String(check["actor"]), "Sera Vane")
	assert_eq(bool(check["success"]), int(check["total"]) >= 15)
