extends GutTest

## Nonlethal damage state (PHB printed pp. 139, 147) and the Improved Unarmed
## Strike lethal choice (printed p. 97).
##
## p. 147: "When your nonlethal damage equals your current hit points, you're
## staggered, and when it exceeds your current hit points, you fall unconscious.
## It doesn't matter whether the nonlethal damage equals or exceeds your current
## hit points because the nonlethal damage has gone up or because your current hit
## points have gone down." Staggered: "you can only take a standard action or a
## move action in each round." Unconscious creatures are helpless.
##
## "When a spell or a magical power cures hit point damage, it also removes an
## equal amount of nonlethal damage."
##
## p. 97: Improved Unarmed Strike makes the character armed and lets unarmed
## strikes "deal lethal or nonlethal damage, at your option". Without the feat an
## unarmed strike deals only nonlethal damage; lethal damage with a weapon that
## deals nonlethal damage takes a -4 (p. 147).

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _sera() -> Character:
	var ch := Character.from_content(content.get_character("sera"), content.items)
	ch.id = "qa_state_sera"
	ch.display_name = "QA Sera"
	ch.max_hp = 30
	ch.hp = 30
	ch.equipment["weapon"] = {}
	return ch


func _kaelen() -> Character:
	var ch := Character.from_content(content.get_character("kaelen"), content.items)
	ch.id = "qa_state_kaelen"
	ch.display_name = "QA Kaelen"
	ch.max_hp = 30
	ch.hp = 30
	return ch


func _map() -> BattleMap:
	return BattleMap.from_rows(
		[
			"###########",
			"#.........#",
			"#.........#",
			"#.........#",
			"#.........#",
			"###########",
		],
		"test"
	)


func _encounter(party: Array, monsters: Array) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = 778899
	var e := Encounter.new()
	e.setup(
		party,
		monsters,
		_map(),
		rng,
		[Vector2i(2, 3)],
		[Vector2i(3, 3)],
		content.spells,
		"Test"
	)
	e.begin()
	e.turn_ptr = e.order.find(int(e.entry_for(party[0])["index"]))
	e._begin_turn(e.entry_for(party[0]))
	return e


func _start_turn(e: Encounter, ch: Character) -> void:
	e.turn_ptr = e.order.find(int(e.entry_for(ch)["index"]))
	e._begin_turn(e.entry_for(ch))


func _log_text(e: Encounter) -> String:
	return "\n".join(e.log_lines)


# ------------------------------------------------------------ thresholds

func test_nonlethal_below_current_hit_points_is_not_incapacitating() -> void:
	var ch := _kaelen()
	ch.hp = 10
	ch.apply_nonlethal(9)
	assert_eq(ch.nonlethal_state(), "none", "below the threshold is no state")
	assert_false(ch.has_condition("staggered"))
	assert_false(ch.has_condition("nonlethal_unconscious"))
	assert_true(ch.is_conscious())
	assert_true(ch.can_act())


func test_nonlethal_equal_to_current_hit_points_is_staggered() -> void:
	var ch := _kaelen()
	ch.hp = 10
	ch.apply_nonlethal(10)
	assert_eq(ch.nonlethal_state(), "staggered")
	assert_true(ch.has_condition("staggered"), "the staggered condition is recorded")
	assert_false(ch.has_condition("nonlethal_unconscious"))
	assert_true(ch.is_conscious(), "staggered characters are conscious")
	assert_true(ch.can_act(), "staggered characters still act, just once per round")


func test_nonlethal_above_current_hit_points_is_unconscious_and_helpless() -> void:
	var ch := _kaelen()
	ch.hp = 10
	ch.apply_nonlethal(11)
	assert_eq(ch.nonlethal_state(), "unconscious")
	assert_true(ch.has_condition("nonlethal_unconscious"))
	assert_false(ch.has_condition("staggered"), "unconsciousness replaces the staggered state")
	assert_false(ch.is_conscious())
	assert_false(ch.can_act())
	assert_true(Rules.is_helpless(ch), "unconscious creatures are helpless (PHB p.147)")


func test_zero_nonlethal_never_staggers_a_character_at_zero_hit_points() -> void:
	var ch := _kaelen()
	ch.hp = 0
	ch.add_effect("disabled", "Disabled", -1)
	ch.refresh_nonlethal_state()
	assert_eq(ch.nonlethal, 0)
	assert_eq(ch.nonlethal_state(), "none")
	assert_false(ch.has_condition("staggered"), "0 nonlethal vs 0 hit points is not staggered")
	assert_true(ch.has_condition("disabled"), "the disabled state is untouched")


func test_lethal_damage_can_push_a_character_into_staggered() -> void:
	var ch := _kaelen()
	ch.hp = 10
	ch.nonlethal = 6
	ch.refresh_nonlethal_state()
	assert_eq(ch.nonlethal_state(), "none", "6 nonlethal against 10 hit points is safe")
	ch.take_damage(4)
	assert_eq(ch.hp, 6)
	assert_eq(ch.nonlethal_state(), "staggered", "losing hit points crossed the threshold")
	assert_true(ch.has_condition("staggered"))


func test_lethal_damage_can_push_a_staggered_character_to_unconscious() -> void:
	var ch := _kaelen()
	ch.hp = 8
	ch.nonlethal = 8
	ch.refresh_nonlethal_state()
	assert_eq(ch.nonlethal_state(), "staggered")
	ch.take_damage(1)
	assert_eq(ch.nonlethal_state(), "unconscious")
	assert_false(ch.is_conscious())


func test_hit_point_healing_can_reverse_the_thresholds() -> void:
	var ch := _kaelen()
	ch.hp = 6
	ch.nonlethal = 6
	ch.refresh_nonlethal_state()
	assert_true(ch.has_condition("staggered"))
	# Healing hit points without touching the nonlethal total moves the threshold
	# back over the total (PHB p.147 speaks of current hit points, not maximum).
	ch.heal(4)
	assert_eq(ch.hp, 10)
	assert_eq(ch.nonlethal, 6)
	assert_eq(ch.nonlethal_state(), "none")
	assert_false(ch.has_condition("staggered"))


# ------------------------------------------------------------ magical healing

func test_magical_healing_removes_nonlethal_damage_at_full_hit_points() -> void:
	var ch := _kaelen()
	ch.hp = ch.max_hp
	ch.nonlethal = 8
	ch.refresh_nonlethal_state()
	assert_eq(ch.nonlethal_state(), "none", "a high total is harmless while hit points are full")
	var healed := ch.magical_heal(5)
	assert_eq(int(healed["healed"]), 0, "no hit points were missing")
	assert_eq(int(healed["nonlethal_removed"]), 5, "the spell still removes nonlethal damage")
	assert_eq(ch.nonlethal, 3, "an amount equal to the healing is removed")


func test_magical_healing_can_restore_consciousness() -> void:
	var ch := _kaelen()
	ch.hp = 4
	ch.max_hp = 4
	ch.nonlethal = 6
	ch.refresh_nonlethal_state()
	assert_false(ch.is_conscious())
	var healed := ch.magical_heal(3)
	assert_eq(int(healed["nonlethal_removed"]), 3)
	assert_eq(ch.nonlethal, 3, "3 nonlethal against 4 hit points")
	assert_eq(ch.nonlethal_state(), "none")
	assert_true(ch.is_conscious())


func test_partial_magical_healing_can_leave_the_target_staggered() -> void:
	var ch := _kaelen()
	# Full hit points, so the healing cannot move the threshold by curing damage.
	ch.max_hp = 10
	ch.hp = 10
	ch.nonlethal = 13
	ch.refresh_nonlethal_state()
	assert_false(ch.is_conscious(), "13 exceeds 10 hit points")
	ch.magical_heal(2)
	assert_eq(ch.nonlethal, 11, "still above the hit point total")
	assert_eq(ch.nonlethal_state(), "unconscious")
	ch.magical_heal(2)
	assert_eq(ch.nonlethal, 9)
	assert_eq(ch.nonlethal_state(), "none", "9 is below 10 hit points")


func test_clearing_nonlethal_does_not_erase_another_incapacity() -> void:
	var ch := _kaelen()
	ch.hp = 10
	ch.nonlethal = 10
	ch.refresh_nonlethal_state()
	assert_true(ch.has_condition("staggered"))
	ch.add_effect("paralyzed", "Paralyzed", -1)
	ch.magical_heal(10)
	assert_false(ch.has_condition("staggered"), "the nonlethal state is cleared")
	assert_true(ch.has_condition("paralyzed"), "the independent paralysis remains")
	assert_true(Rules.is_helpless(ch), "paralysis still leaves the character helpless")


# ------------------------------------------------------------ persistence

func test_older_saves_without_a_nonlethal_field_load_cleanly() -> void:
	var ch := _kaelen()
	var data := ch.to_dict()
	data.erase("nonlethal")
	var loaded := Character.from_dict(data, content.items)
	assert_eq(loaded.nonlethal, 0, "a missing field means no nonlethal damage")
	assert_false(loaded.has_condition("staggered"))
	assert_false(loaded.has_condition("nonlethal_unconscious"))


func test_save_load_preserves_the_total_and_the_derived_state() -> void:
	var ch := _kaelen()
	ch.hp = 10
	ch.apply_nonlethal(12)
	var data := ch.to_dict()
	var loaded := Character.from_dict(data, content.items)
	assert_eq(loaded.nonlethal, 12, "the total survives the round trip")
	assert_eq(loaded.hp, 10)
	assert_true(loaded.has_condition("nonlethal_unconscious"), "the derived state is rebuilt")
	assert_false(loaded.is_conscious())


func test_save_load_preserves_staggered_state() -> void:
	var ch := _kaelen()
	ch.hp = 10
	ch.apply_nonlethal(10)
	var loaded := Character.from_dict(ch.to_dict(), content.items)
	assert_true(loaded.has_condition("staggered"))
	assert_false(loaded.has_condition("nonlethal_unconscious"))


# ------------------------------------------------------------ action limits

func test_staggered_character_cannot_move_and_then_attack() -> void:
	var sera := _sera()
	var kaelen := _kaelen()
	sera.hp = 10
	sera.apply_nonlethal(10)
	assert_true(sera.has_condition("staggered"))
	var e := _encounter([sera], [kaelen])
	var move := e.move_active_to(Vector2i(2, 4))
	assert_true(bool(move["ok"]), String(move.get("message", "")))
	var attack := e.attack_active(int(e.entry_for(kaelen)["index"]))
	assert_false(bool(attack["ok"]), "a staggered character cannot also take a standard action")
	assert_true(String(attack["message"]).contains("staggered"), String(attack["message"]))


func test_staggered_character_cannot_attack_and_then_move() -> void:
	var sera := _sera()
	var kaelen := _kaelen()
	sera.hp = 10
	sera.apply_nonlethal(10)
	assert_true(sera.has_condition("staggered"))
	var e := _encounter([sera], [kaelen])
	var attack := e.attack_active(int(e.entry_for(kaelen)["index"]))
	assert_true(bool(attack["ok"]), String(attack.get("message", "")))
	var move := e.move_active_to(Vector2i(2, 4))
	assert_false(bool(move["ok"]), "a staggered character cannot also take a move action")
	assert_true(String(move["message"]).contains("staggered"), String(move["message"]))


func test_encounter_ends_when_every_enemy_is_nonlethally_unconscious() -> void:
	var sera := _sera()
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen])
	kaelen.apply_nonlethal(kaelen.hp + 1)
	e._check_end()
	assert_true(e.finished, "no enemy can still fight")
	assert_eq(e.outcome, "victory")


# ------------------------------------------------------------ Improved Unarmed Strike

func test_improved_unarmed_strike_can_deal_lethal_damage_without_a_penalty() -> void:
	var sera := _sera()
	sera.feats.append("Improved Unarmed Strike")
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen])
	var result := e.attack_active(int(e.entry_for(kaelen)["index"]), "", "lethal")
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(_log_text(e).contains("deals lethal damage with an unarmed strike"))
	assert_false(_log_text(e).contains("-4 on the attack roll"), "the feat removes the penalty")
	var resolved: Dictionary = result["result"]
	assert_false(bool(resolved.get("nonlethal", false)), "the strike is lethal this time")
	if bool(resolved["hit"]):
		assert_true(kaelen.hp < kaelen.max_hp, "lethal damage reduces hit points")


func test_lethal_unarmed_strike_without_the_feat_takes_the_printed_penalty() -> void:
	var sera := _sera()
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen])
	var result := e.attack_active(int(e.entry_for(kaelen)["index"]), "", "lethal")
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(_log_text(e).contains("-4 on the attack roll"), "the printed penalty is applied and logged")
	var resolved: Dictionary = result["result"]
	assert_false(bool(resolved.get("nonlethal", false)))
	if bool(resolved["hit"]):
		assert_true(kaelen.hp < kaelen.max_hp, "lethal damage reduces hit points")
		assert_eq(kaelen.nonlethal, 0, "and records no nonlethal damage")


func test_improved_unarmed_strike_still_defaults_to_nonlethal() -> void:
	var sera := _sera()
	sera.feats.append("Improved Unarmed Strike")
	var kaelen := _kaelen()
	var e := _encounter([sera], [kaelen])
	var result := e.attack_active(int(e.entry_for(kaelen)["index"]))
	assert_true(bool(result["ok"]))
	assert_true(bool(result["result"].get("nonlethal", false)), "the default stays nonlethal")
