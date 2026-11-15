extends GutTest

## Size and prone rules. Every expected value comes from the source tables:
## PHB glossary "size modifier" (printed p.312), Table 8-5 and Table 8-6
## (printed p.151), and the opposed-check tie procedure (printed p.64).
## Values are never copied from the implementation's output.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 20261104


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _authored(id: String) -> Dictionary:
	return content.get_character(id).duplicate(true)


## PHB p.312: size modifiers to Armor Class and attack rolls scale by one
## point per category around Medium.
func test_size_categories_follow_the_source_progression() -> void:
	var expected := {
		"fine": 8,
		"diminutive": 4,
		"tiny": 2,
		"small": 1,
		"medium": 0,
		"large": -1,
		"huge": -2,
		"gargantuan": -4,
		"colossal": -8,
	}
	for category in expected.keys():
		assert_eq(Rules.size_modifier(category), int(expected[category]), "size modifier for %s" % category)
		assert_true(Rules.is_valid_size_category(category))
	assert_false(Rules.is_valid_size_category("gigantic"), "unknown categories are rejected")
	assert_eq(Rules.normalize_size_category("Gigantic"), "medium", "unknown categories fall back to Medium")


## Older saves stored only `size_ac`; the category must be recovered from it.
func test_legacy_actor_without_size_category_migrates_from_size_ac() -> void:
	var medium := _authored("kaelen")
	medium.erase("size_category")
	medium["size_ac"] = 0
	var built := Character.from_dict(medium, content.items)
	assert_eq(built.size_category, "medium")
	assert_eq(built.size_ac, 0)

	var large := _authored("kaelen")
	large.erase("size_category")
	large["size_ac"] = -1
	var large_built := Character.from_dict(large, content.items)
	assert_eq(large_built.size_category, "large")
	assert_eq(large_built.size_ac, -1)

	var small := _authored("sera")
	small.erase("size_category")
	small["size_ac"] = 1
	var small_built := Character.from_dict(small, content.items)
	assert_eq(small_built.size_category, "small")
	assert_eq(small_built.size_ac, 1)


## The category is authoritative; the cached modifier is recomputed on load so
## a stale or contradictory `size_ac` cannot become a second source of truth.
func test_size_category_overrides_a_stale_derived_modifier() -> void:
	var data := _authored("kaelen")
	data["size_category"] = "small"
	data["size_ac"] = -8
	var built := Character.from_dict(data, content.items)
	assert_eq(built.size_category, "small")
	assert_eq(built.size_ac, 1)


func test_authored_content_size_data_is_consistent() -> void:
	for id in content.characters.keys():
		var actor: Dictionary = content.characters[id]
		var category := String(actor.get("size_category", "medium")).to_lower()
		assert_true(Rules.is_valid_size_category(category), "%s has a known size" % id)
		assert_eq(
			int(actor.get("size_ac", 0)),
			Rules.size_modifier(category),
			"%s size_ac matches its category" % id
		)
	for id in content.monsters.keys():
		var actor: Dictionary = content.monsters[id]
		var category := String(actor.get("size_category", "medium")).to_lower()
		assert_true(Rules.is_valid_size_category(category), "%s has a known size" % id)
		assert_eq(
			int(actor.get("size_ac", 0)),
			Rules.size_modifier(category),
			"%s size_ac matches its category" % id
		)


## Table 8-6 (printed p.151): prone is -4 AC vs melee, +4 AC vs ranged.
func test_prone_defender_ac_signs_follow_table_8_6() -> void:
	var kaelen := _char("kaelen")
	assert_eq(Rules.armor_class(kaelen), 17, "standing AC")
	assert_eq(Rules.armor_class(kaelen, {"attack_mode": "melee"}), 17, "standing AC vs melee")
	assert_eq(Rules.armor_class(kaelen, {"attack_mode": "ranged"}), 17, "standing AC vs ranged")

	kaelen.set_prone(true)
	assert_true(kaelen.is_prone())
	assert_eq(Rules.armor_class(kaelen), 17, "unknown attack type applies no prone modifier")
	assert_eq(Rules.armor_class(kaelen, {"attack_mode": "melee"}), 13, "17 - 4 vs melee")
	assert_eq(Rules.armor_class(kaelen, {"attack_mode": "ranged"}), 21, "17 + 4 vs ranged")
	assert_eq(Rules.armor_class(kaelen, {"attack_mode": "thrown"}), 21, "thrown attacks are ranged")

	assert_eq(Rules.touch_ac(kaelen, {"attack_mode": "melee"}), 7, "touch 11 - 4")
	assert_eq(Rules.touch_ac(kaelen, {"attack_mode": "ranged"}), 15, "touch 11 + 4")

	kaelen.set_prone(false)
	assert_false(kaelen.is_prone())
	assert_eq(Rules.armor_class(kaelen, {"attack_mode": "melee"}), 17, "standing up restores AC")


func test_prone_and_flat_footed_apply_separately() -> void:
	var kaelen := _char("kaelen")
	kaelen.set_prone(true)
	# 10 + chain shirt 4 + shield 2 + size 0 - prone 4, no Dexterity bonus.
	assert_eq(Rules.armor_class(kaelen, {"attack_mode": "melee", "flat_footed": true}), 12)


## Table 8-5 (printed p.151): prone attackers take -4 on melee attack rolls.
func test_prone_attacker_takes_minus_four_on_melee_attacks() -> void:
	var kaelen := _char("kaelen")
	var sword: Dictionary = kaelen.equipped("weapon")
	var standing := Rules.attack_bonus(kaelen, sword, 0, "melee")
	kaelen.set_prone(true)
	assert_eq(Rules.attack_bonus(kaelen, sword, 0, "melee"), standing - 4)


## Table 8-5 footnote 3 (printed p.151): only a crossbow or shuriken may be
## used while prone, at no penalty.
func test_prone_attacker_may_only_use_a_crossbow_or_shuriken() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var crossbow: Dictionary = content.items["light_crossbow"]
	var longbow := {
		"name": "Longbow",
		"damage": "1d8",
		"crit_range": 20,
		"crit_mult": 2,
		"range_increment": 100,
		"attack_modes": ["ranged"],
	}
	var standing_crossbow := Rules.attack(rng, kaelen, zombie, crossbow, 60, {"attack_mode": "ranged"})
	kaelen.set_prone(true)
	assert_false(
		Rules.prone_ranged_attack_allowed(longbow), "an unmarked ranged weapon is not prone-usable"
	)
	var blocked := Rules.attack(rng, kaelen, zombie, longbow, 60, {"attack_mode": "ranged"})
	assert_false(bool(blocked["available"]))
	assert_false(bool(blocked["hit"]))
	assert_eq(int(blocked["damage"]), 0)
	assert_true(String(blocked["reason"]).contains("prone"))

	var fired := Rules.attack(rng, kaelen, zombie, crossbow, 60, {"attack_mode": "ranged"})
	assert_true(bool(fired["available"]), "a crossbow remains usable while prone")
	# Table 8-5 gives no ranged penalty while prone, so the attack bonus matches
	# the standing crossbow attack.
	assert_eq(int(fired["bonus"]), int(standing_crossbow["bonus"]))


func test_prone_melee_attack_result_reports_the_reduced_bonus() -> void:
	var kaelen := _char("kaelen")
	var zombie := _monster("zombie")
	var sword: Dictionary = kaelen.equipped("weapon")
	var standing := Rules.attack(rng, kaelen, zombie, sword, 5, {"attack_mode": "melee"})
	kaelen.set_prone(true)
	var prone := Rules.attack(rng, kaelen, zombie, sword, 5, {"attack_mode": "melee"})
	assert_true(bool(prone["available"]))
	assert_eq(int(prone["bonus"]), int(standing["bonus"]) - 4)
	# The defender is standing, so its AC is unchanged by the attacker's state.
	assert_eq(int(prone["target_ac"]), int(standing["target_ac"]))


func test_prone_has_no_duration() -> void:
	var kaelen := _char("kaelen")
	kaelen.set_prone(true)
	kaelen.tick_effects()
	assert_true(kaelen.is_prone(), "prone only ends by standing up")


## PHB p.64: tied totals go to the higher modifier; equal modifiers reroll.
func test_opposed_tie_goes_to_the_higher_modifier() -> void:
	var attacker := Character.new()
	attacker.display_name = "Attacker"
	attacker.abilities["str"] = 16
	var defender := Character.new()
	defender.display_name = "Defender"
	defender.abilities["str"] = 10
	var ties := 0
	for _i in 300:
		var result := Rules.opposed_ability_check(rng, attacker, ["str"], defender, ["str"])
		assert_true(bool(result["ok"]))
		if int(result["attacker_total"]) == int(result["defender_total"]):
			ties += 1
			assert_eq(String(result["winner"]), "attacker", "higher modifier wins a tied total")
			assert_eq(String(result["tie_broken_by"]), "modifier")
	assert_true(ties > 0, "the seeded sample must contain tied totals")


func test_opposed_tie_with_equal_modifiers_rerolls_until_resolved() -> void:
	var attacker := Character.new()
	attacker.display_name = "Attacker"
	var defender := Character.new()
	defender.display_name = "Defender"
	for _i in 200:
		var result := Rules.opposed_ability_check(rng, attacker, ["str"], defender, ["str"])
		assert_true(bool(result["ok"]))
		assert_true(["attacker", "defender"].has(String(result["winner"])), "no drawn result")
		assert_ne(String(result["tie_broken_by"]), "modifier", "equal modifiers never decide a tie")
		if String(result["tie_broken_by"]) == "reroll":
			assert_true(int(result["rerolls"]) > 0)
		# Equal totals must have been rerolled, so unequal totals decided it.
		if int(result["attacker_total"]) == int(result["defender_total"]):
			assert_eq(String(result["tie_broken_by"]), "reroll")


func test_save_round_trip_preserves_size_and_prone() -> void:
	var kaelen := _char("kaelen")
	kaelen.size_category = "small"
	kaelen.size_ac = Rules.size_modifier("small")
	kaelen.set_prone(true)
	var loaded := Character.from_dict(kaelen.to_dict(), content.items)
	assert_eq(loaded.size_category, "small")
	assert_eq(loaded.size_ac, 1)
	assert_true(loaded.is_prone())
	# small (+1 size) and prone (+4 vs ranged): 17 + 1 + 4
	assert_eq(Rules.armor_class(loaded, {"attack_mode": "ranged"}), 22)
	assert_eq(
		Rules.armor_class(loaded, {"attack_mode": "ranged"}),
		Rules.armor_class(kaelen, {"attack_mode": "ranged"}),
		"a save round trip changes no derived value"
	)
