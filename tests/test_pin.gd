extends GutTest

## Pin (PHB p. 156; SRD Combat, Special Attacks: Grapple), batch 8b-1 of
## docs/PIN_PLAN.md. One player-initiated pin inside the existing
## two-participant grapple. No pin damage, no break-another's-pin, no multiple
## grapplers, no casting/monster attack-policy change.
##
## Adaptations exercised here (plan section 3): the pin costs the standard action
## because there are no iteratives; the pin expires at the start of the pinner's
## next turn, with no fixed number of pinned turns promised; both escape methods
## cost the standard action; the pinner cannot attack while pinning; release ends
## the whole hold.

const OPEN_ROWS := [
	"#########",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#########",
]
const A_CELL := Vector2i(2, 3)
const B_CELL := Vector2i(3, 3)
const C_CELL := Vector2i(2, 4)

var content
var rng: RandomNumberGenerator


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 991


func after_each() -> void:
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _map(rows: Array = OPEN_ROWS) -> BattleMap:
	return BattleMap.from_rows(rows, "pin_test")


func _encounter(
	party: Array, monsters: Array, party_cells: Array, monster_cells: Array, seed_value := 991
) -> Encounter:
	rng.seed = seed_value
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Pin")
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


func _log(e: Encounter) -> String:
	return "\n".join(e.log_lines)


## A live pair with the holder's turn started, so a pin can actually be declared.
## The defender's Strength is minimal so the seeded hold succeeds, and the third
## party (when requested) is a party ally standing beside the pair.
func _pair(seed_value: int, opts := {}) -> Dictionary:
	rng.seed = seed_value
	var holder := _char(String(opts.get("holder", "kaelen")))
	var held: Character = (
		_char(String(opts.get("held", "sera")))
		if bool(opts.get("living_defender", false))
		else _monster(String(opts.get("held", "zombie")))
	)
	holder.base_attack = int(opts.get("holder_base", 12))
	if bool(opts.get("holder_weapon", false)):
		holder.equipment["weapon"] = Dictionary(content.items["masterwork_longsword"]).duplicate(true)
	held.abilities["str"] = 1
	if int(opts.get("held_base", -1)) >= 0:
		held.base_attack = int(opts["held_base"])
	var third: Character = null
	if bool(opts.get("with_third", false)):
		third = _char("sera")
		third.base_attack = int(opts.get("third_base", 3))
	var party: Array = [holder] if third == null else [holder, third]
	var party_cells: Array = [A_CELL] if third == null else [A_CELL, C_CELL]
	var e := _encounter(party, [held], party_cells, [B_CELL], seed_value)
	_force_turn(e, holder)
	var result: Dictionary = e.grapple_active(int(e.entry_for(held)["index"]))
	return {
		"e": e,
		"holder": holder,
		"held": held,
		"third": third,
		"result": result,
		"held_index": int(e.entry_for(held)["index"]),
		"holder_index": int(e.entry_for(holder)["index"]),
	}


## Finds a seed where the pair exists, then starts the holder's next turn and
## pins. `want_pinned` selects a success or a failure without editing the dice.
func _pinned(seed_value: int, opts := {}) -> Dictionary:
	var attempt := _pair(seed_value, opts)
	if not bool(attempt["result"].get("grappled", false)):
		return {}
	var e: Encounter = attempt["e"]
	var holder: Character = attempt["holder"]
	if not bool(opts.get("want_pinned", true)):
		holder.base_attack = -20
	_force_turn(e, holder)
	var pin: Dictionary = e.pin_active()
	if bool(e.is_pinned(int(attempt["held_index"]))) != bool(opts.get("want_pinned", true)):
		return {}
	attempt["pin"] = pin
	return attempt


func _first_pinned(opts := {}) -> Dictionary:
	for seed_value in range(1, 400):
		var attempt := _pinned(seed_value, opts)
		if not attempt.is_empty():
			attempt["seed"] = seed_value
			return attempt
	fail_test("no seed in 1..399 produced the required pin outcome")
	return {}


func test_pin_records_the_flag_and_spends_the_standard_action() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	var held_index := int(attempt["held_index"])
	assert_true(e.is_pinned(held_index), "the held creature is pinned (seed %d)" % int(attempt["seed"]))
	assert_eq(e.pin_holder(held_index), int(attempt["holder_index"]), "the holder owns the pin")
	assert_true(bool(e.turn_state["standard_used"]), "the pin spent the standard action")
	assert_string_contains(_log(e), "Pin check:", "the opposed pin check is logged")
	assert_string_contains(_log(e), "pins", "the pin is announced")


func test_failed_pin_leaves_the_grapple_intact_and_spends_the_action() -> void:
	var attempt := _first_pinned({"want_pinned": false})
	var e: Encounter = attempt["e"]
	var held_index := int(attempt["held_index"])
	assert_true(e.is_grappled(held_index), "the grapple survives a failed pin")
	assert_false(e.is_pinned(held_index), "the failed pin set no flag")
	assert_true(bool(e.turn_state["standard_used"]), "the failed pin still spent the standard action")
	assert_string_contains(_log(e), "fails to pin", "the failure is logged")


func test_second_pin_in_the_same_turn_is_refused() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	var second: Dictionary = e.pin_active()
	assert_false(bool(second.get("ok", true)), "a second pin in one turn is refused")
	assert_string_contains(String(second.get("message", "")), "standard action")


func test_pin_while_already_pinned_is_refused() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	e.turn_state["standard_used"] = false
	var again: Dictionary = e.pin_active()
	assert_false(bool(again.get("ok", true)), "a second pin on the same creature is refused")
	assert_string_contains(String(again.get("message", "")), "already pinned")


func test_held_creature_cannot_pin() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	var refused: Dictionary = e.pin_active()
	assert_false(bool(refused.get("ok", true)), "the pinned creature cannot declare a pin")
	assert_string_contains(String(refused.get("message", "")), "holding the grapple")


func test_third_party_cannot_pin() -> void:
	var attempt := _first_pinned({"with_third": true})
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["third"])
	var refused: Dictionary = e.pin_active()
	assert_false(bool(refused.get("ok", true)), "a non-participant cannot pin")
	assert_string_contains(String(refused.get("message", "")), "not grappling")


func test_pin_without_a_grapple_is_refused() -> void:
	var holder := _char("kaelen")
	var zombie := _monster("zombie")
	var e := _encounter([holder], [zombie], [A_CELL], [B_CELL], 5)
	var refused: Dictionary = e.pin_active()
	assert_false(bool(refused.get("ok", true)), "there is no hold to pin")
	assert_string_contains(String(refused.get("message", "")), "not grappling")


func test_pin_against_a_dead_partner_is_refused() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	attempt["held"].take_damage(attempt["held"].hp + 100)
	e.turn_state["standard_used"] = false
	var refused: Dictionary = e.pin_active()
	assert_false(bool(refused.get("ok", true)), "a dead creature cannot be pinned")


func test_pinned_penalty_lands_on_the_attack_resolution_not_only_the_helper() -> void:
	var attempt := _first_pinned({"with_third": true})
	var e: Encounter = attempt["e"]
	var held_index := int(attempt["held_index"])
	var third_index := int(e.entry_for(attempt["third"])["index"])
	assert_eq(e.pinned_ac_penalty(held_index, third_index), 4, "a third party takes the printed -4")
	assert_eq(e.pinned_ac_penalty(held_index, int(attempt["holder_index"])), 0, "the pinner is excluded")
	_force_turn(e, attempt["third"])
	var weapon: Dictionary = e._primary_weapon(attempt["third"])
	var pinned_ac := Rules.armor_class(
		attempt["held"], {"deny_dex": true, "pinned_penalty": 4, "attack_mode": "melee"}
	)
	var plain_ac := Rules.armor_class(
		attempt["held"], {"deny_dex": true, "attack_mode": "melee"}
	)
	assert_eq(pinned_ac, plain_ac - 4, "the penalty is a flat 4 beside Dexterity denial")
	var result := Rules.attack(
		rng,
		attempt["third"],
		attempt["held"],
		weapon,
		BattleMap.CELL_FT,
		{"deny_dex": true, "pinned_penalty": 4, "attack_mode": "melee"}
	)
	assert_eq(int(result["target_ac"]), pinned_ac, "the resolved attack uses the pinned AC")
	var same := Rules.attack(
		rng,
		attempt["third"],
		attempt["held"],
		weapon,
		BattleMap.CELL_FT,
		{"deny_dex": true, "attack_mode": "melee"}
	)
	assert_eq(int(same["target_ac"]), plain_ac, "without the pin the AC is 4 higher")


func test_pinned_penalty_applies_to_touch_ac() -> void:
	var attempt := _first_pinned({"with_third": true})
	var e: Encounter = attempt["e"]
	var held_index := int(attempt["held_index"])
	var third_index := int(e.entry_for(attempt["third"])["index"])
	var plain := Rules.touch_ac(
		attempt["held"], {"deny_dex": true, "attack_mode": "ranged"}
	)
	var pinned := Rules.touch_ac(
		attempt["held"],
		{
			"deny_dex": true,
			"pinned_penalty": e.pinned_ac_penalty(held_index, third_index),
			"attack_mode": "ranged",
		}
	)
	assert_eq(pinned, plain - 4, "touch AC carries the same -4")


func test_pinner_keeps_the_pinned_creatures_dexterity() -> void:
	var attempt := _first_pinned({"living_defender": true})
	var e: Encounter = attempt["e"]
	var held_index := int(attempt["held_index"])
	var holder_index := int(attempt["holder_index"])
	assert_false(e.denies_dex_to(held_index, holder_index), "the pinner does not deny Dexterity")
	assert_true(e.denies_dex_to(held_index, 99), "everyone else denies it")
	# The pin must not create the flat-footed state that would open sneak attack.
	_force_turn(e, attempt["held"])
	assert_false(e.is_flat_footed(held_index), "a pin is not flat-footed and grants no sneak attack")
	assert_false(Rules.is_helpless(attempt["held"]), "a pin is not helpless either")
	var with_dex := Rules.armor_class(
		attempt["held"], {"deny_dex": false, "pinned_penalty": 0, "attack_mode": "melee"}
	)
	var denied := Rules.armor_class(
		attempt["held"], {"deny_dex": true, "pinned_penalty": 0, "attack_mode": "melee"}
	)
	assert_true(with_dex > denied, "the Dexterity bonus is present against the pinner")


func test_pinned_creature_cannot_attack() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	attempt["held"].base_attack = 40
	var refused: Dictionary = e.attack_active(int(attempt["holder_index"]))
	assert_false(bool(refused.get("ok", true)), "a pinned creature cannot attack its holder")
	assert_string_contains(String(refused.get("message", "")), "pinned")


func test_pinner_cannot_attack_while_pinning() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	e.turn_state["standard_used"] = false
	var refused: Dictionary = e.attack_active(int(attempt["held_index"]))
	assert_false(bool(refused.get("ok", true)), "the pinner cannot use the partner attack")
	assert_string_contains(String(refused.get("message", "")), "pinning")


func test_pinned_movement_actions_are_refused() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	assert_string_contains(
		String(e.move_active_to(Vector2i(1, 3)).get("message", "")), "grappling", "move is refused"
	)
	assert_string_contains(
		String(e.move_active_to(Vector2i(1, 3), true).get("message", "")), "grappling",
		"the 5-ft step is refused"
	)
	assert_string_contains(
		String(e.stand_up_active().get("message", "")), "grappling", "standing up is refused"
	)


func test_pinned_item_actions_are_refused() -> void:
	var attempt := _first_pinned({"living_defender": true, "held": "kaelen"})
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	assert_string_contains(
		String(e.pick_up_active(0).get("message", "")), "grappling", "picking up is refused"
	)
	assert_string_contains(
		String(e.sheathe_weapon().get("message", "")), "grappling", "sheathing is refused"
	)
	assert_string_contains(
		String(e.load_weapon().get("message", "")), "grappling", "loading is refused"
	)


func test_pinned_casting_and_turning_are_refused_by_name() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	var cast: Dictionary = e.cast_active_spell("cure_light_wounds", int(attempt["holder_index"]))
	assert_false(bool(cast.get("ok", true)), "a pinned creature cannot cast")
	assert_string_contains(String(cast.get("message", "")), "pinned", "the pin is named, not the scope limit")
	var turn: Dictionary = e.turn_undead()
	assert_false(bool(turn.get("ok", true)), "a pinned creature cannot turn undead")
	assert_string_contains(String(turn.get("message", "")), "pinned", "turning names the pin")


func test_pinned_potion_first_aid_and_total_defense_are_refused() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	var held: Character = attempt["held"]
	held.add_to_inventory(Dictionary(content.items["potion_of_cure_light_wounds"]), 1)
	_force_turn(e, held)
	var potion: Dictionary = e.use_potion_active("potion_of_cure_light_wounds", int(attempt["held_index"]))
	assert_false(bool(potion.get("ok", true)), "a pinned creature cannot drink a potion")
	assert_string_contains(String(potion.get("message", "")), "pinned", "the potion refusal names the pin")
	var aid: Dictionary = e.stabilize_active(int(attempt["held_index"]))
	assert_false(bool(aid.get("ok", true)), "a pinned creature cannot attempt first aid")
	assert_string_contains(String(aid.get("message", "")), "pinned", "the first-aid refusal names the pin")
	var defense: Dictionary = e.total_defense()
	assert_false(bool(defense.get("ok", true)), "a pinned creature cannot take total defense")
	assert_string_contains(String(defense.get("message", "")), "pinned", "the defense refusal names the pin")


## A pinned ally cannot arise from play (the AI never pins and an ally cannot be
## grappled), so the pair is seeded to prove the potion path stays usable for a
## non-pinned actor and the team rule still applies.
func test_potion_given_to_a_pinned_ally_still_works() -> void:
	rng.seed = 7
	var holder := _char("kaelen")
	var pinned := _char("sera")
	var zombie := _monster("zombie")
	var e := _encounter([holder, pinned], [zombie], [A_CELL, B_CELL], [Vector2i(1, 3)], 7)
	e.grapples.append({"holder": 0, "held": 1, "pinned": true})
	holder.add_to_inventory(Dictionary(content.items["potion_of_cure_light_wounds"]), 1)
	pinned.hp = 1
	_force_turn(e, holder)
	var given: Dictionary = e.use_potion_active(
		"potion_of_cure_light_wounds", int(e.entry_for(pinned)["index"])
	)
	assert_true(bool(given.get("ok", false)), "an ally can administer a potion to a pinned creature")
	assert_true(pinned.hp > 1, "the pinned creature is healed")


func test_pin_escape_success_clears_the_pin_and_keeps_the_grapple() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	attempt["held"].base_attack = 40
	var escape: Dictionary = e.grapple_exit()
	assert_true(bool(escape.get("escaped", false)), "the pin escape succeeds")
	assert_true(e.is_grappled(int(attempt["held_index"])), "the grapple survives the pin escape")
	assert_false(e.is_pinned(int(attempt["held_index"])), "the pin itself is cleared")
	assert_string_contains(_log(e), "escapes the pin", "the pin escape is logged")
	assert_true(bool(e.turn_state["standard_used"]), "the pin escape spent the standard action")


func test_pin_escape_failure_stays_pinned() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	attempt["held"].base_attack = -20
	var escape: Dictionary = e.grapple_exit()
	assert_false(bool(escape.get("escaped", false)), "the pin escape fails")
	assert_true(e.is_pinned(int(attempt["held_index"])), "the pin remains")
	assert_true(e.is_grappled(int(attempt["held_index"])), "the grapple remains")
	assert_string_contains(_log(e), "fails to escape the pin", "the failure is logged")


func test_escape_artist_pin_escape_keeps_the_grapple() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	attempt["held"].skill_ranks["escape_artist"] = 20
	var escape: Dictionary = e.grapple_exit(true)
	assert_true(bool(escape.get("escaped", false)), "Escape Artist escapes the pin")
	assert_true(e.is_grappled(int(attempt["held_index"])), "the grapple remains after the skill escape")
	assert_false(e.is_pinned(int(attempt["held_index"])), "the pin flag is cleared")
	assert_true(bool(escape.get("escape_artist", false)), "the skill path is recorded")


func test_holder_release_clears_the_whole_grapple() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	e.turn_state["standard_used"] = false
	var release: Dictionary = e.grapple_exit()
	assert_true(bool(release.get("released", false)), "the holder releases")
	assert_true(e.grapples.is_empty(), "releasing a pin ends the whole hold")
	assert_false(bool(e.turn_state["standard_used"]), "the release is free")
	assert_string_contains(_log(e), "lets go of", "the release is logged")


func test_pinned_ai_attempts_a_pin_escape_and_does_not_attack() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	_force_turn(e, attempt["held"])
	var entry: Dictionary = e.combatants[int(attempt["held_index"])]
	var before := e.log_lines.size()
	e._run_monster_turn(entry)
	var text := "\n".join(e.log_lines.slice(before))
	assert_string_contains(text, "tries to escape the pin", "the pinned AI attempts the pin escape")
	assert_false(text.contains("attacks"), "the pinned AI takes no attack")
	if bool(e.is_pinned(int(attempt["held_index"]))):
		assert_string_contains(text, "fails to escape the pin", "a failed pin escape is logged")
	else:
		assert_true(e.is_grappled(int(attempt["held_index"])), "a successful pin escape leaves it grappled")


func test_pin_expires_at_the_start_of_the_pinners_next_turn() -> void:
	for pinned_first in [false, true]:
		var attempt := _first_pinned()
		var e: Encounter = attempt["e"]
		assert_true(e.is_pinned(int(attempt["held_index"])), "the pin exists")
		var pinned_entry := e.order.find(int(attempt["held_index"]))
		var holder_entry := e.order.find(int(attempt["holder_index"]))
		if pinned_first:
			e.order.remove_at(holder_entry)
			e.order.insert(0, int(attempt["holder_index"]))
			pinned_entry = e.order.find(int(attempt["held_index"]))
			e.turn_ptr = pinned_entry
		else:
			e.turn_ptr = pinned_entry
		e._begin_turn(e.combatants[int(attempt["held_index"])])
		assert_true(e.is_pinned(int(attempt["held_index"])), "the pin is still on during the defender's turn")
		_force_turn(e, attempt["holder"])
		assert_false(e.is_pinned(int(attempt["held_index"])), "the pin ends at the pinner's next turn")
		assert_string_contains(_log(e), "pin ends", "the expiry is logged")
		assert_true(e.is_grappled(int(attempt["held_index"])), "the grapple itself remains")


func test_pin_expires_even_when_the_pinner_cannot_act() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	attempt["holder"].add_effect("paralyzed", "Paralyzed", 3, "condition")
	_force_turn(e, attempt["holder"])
	assert_false(e.is_pinned(int(attempt["held_index"])), "the expiry runs at the start of the turn")
	assert_true(e.is_grappled(int(attempt["held_index"])), "the grapple remains")
	var refused: Dictionary = e.pin_active()
	assert_false(bool(refused.get("ok", true)), "a paralyzed pinner cannot pin again")


func test_pinned_dying_creature_cannot_escape() -> void:
	var attempt := _first_pinned({"living_defender": true})
	var e: Encounter = attempt["e"]
	attempt["held"].hp = 1
	attempt["held"].take_damage(1)
	_force_turn(e, attempt["held"])
	var refused: Dictionary = e.grapple_exit()
	assert_false(bool(refused.get("ok", true)), "a dying pinned creature cannot escape")
	assert_true(e.is_pinned(int(attempt["held_index"])), "the pin persists on a creature that cannot act")


func test_death_clears_a_pinned_pair() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	attempt["held"].take_damage(attempt["held"].hp + 100)
	e._check_end()
	assert_true(e.grapples.is_empty(), "death clears the pinned pair")
	assert_string_contains(_log(e), "is dead", "the death reason is logged")


func test_turning_clears_a_pinned_pair() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	attempt["held"].add_effect("turned", "Turned", 10, "condition")
	e._run_turned_turn(e.combatants[int(attempt["held_index"])])
	assert_true(e.grapples.is_empty(), "turning clears the pinned pair")


func test_encounter_finish_clears_a_pinned_pair() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	e.finish("victory")
	assert_true(e.grapples.is_empty(), "finish clears the pinned pair")
	assert_string_contains(_log(e), "any grapple is released", "the finish reason is logged")


func test_encounter_begin_clears_a_pinned_pair() -> void:
	var attempt := _first_pinned()
	var e: Encounter = attempt["e"]
	e.begin()
	assert_true(e.grapples.is_empty(), "a new encounter starts with no pair")
