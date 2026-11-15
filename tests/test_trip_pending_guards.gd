extends GutTest

## The paused Trip decision is a rules/session boundary, not a disabled-button
## convention. While a weapon-release decision is waiting, every state-changing
## entry point must refuse, and only the decision itself may change state.

var content: ContentDB
var rng: RandomNumberGenerator
var saved_party: Array = []
var saved_mode := ""
var saved_encounter: Encounter = null
var saved_data: Dictionary = {}


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 9091
	saved_party = Game.party.duplicate()
	saved_mode = Game.mode
	saved_encounter = Game.encounter
	saved_data = Game.active_encounter_data


func after_each() -> void:
	Game.party.clear()
	for ch in saved_party:
		Game.party.append(ch)
	Game.mode = saved_mode
	Game.encounter = saved_encounter
	Game.active_encounter_data = saved_data


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
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


func _encounter(
	party: Array, monsters: Array, party_cell := Vector2i(2, 3), monster_cell := Vector2i(3, 3)
) -> Encounter:
	var party_cells: Array = []
	var monster_cells: Array = []
	for i in party.size():
		party_cells.append(Vector2i(party_cell.x + i, party_cell.y))
	for i in monsters.size():
		monster_cells.append(Vector2i(monster_cell.x, monster_cell.y + i))
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	return e


func _force_turn(e: Encounter, ch: Character) -> void:
	for i in e.order:
		if e.combatants[i]["char"] == ch:
			e.turn_ptr = e.order.find(i)
			e._begin_turn(e.combatants[i])
			return
	fail_test("character is not in the initiative order")


## Deterministic pending state: the touch attack always hits (very low AC) and
## the defender always wins the opposed check and counter-trip (stability).
func _pending() -> Dictionary:
	var kaelen := _char("kaelen")
	kaelen.equip("weapon", content.get_item("light_flail"))
	var zombie := _monster("zombie")
	zombie.max_hp = 200
	zombie.hp = 200
	zombie.ac_misc = -20
	zombie.stability_bonus = 40
	zombie.damage_reduction.clear()
	var e := _encounter([kaelen], [zombie])
	_force_turn(e, kaelen)
	var target_index := -1
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			target_index = int(entry["index"])
	var result := e.trip_active(target_index, {"use_weapon": true})
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(String(result.get("pending", "")), "weapon_release", "the decision pauses resolution")
	assert_true(e.has_pending_decision())
	assert_true(bool(e.turn_state["standard_used"]), "the standard action is already spent")
	return {"e": e, "actor": kaelen, "target": zombie, "target_index": target_index}


func test_spells_potions_first_aid_turning_and_feats_are_refused_while_pending() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var kaelen: Character = setup["actor"]
	var target_index := int(setup["target_index"])
	var ally := _char("sera")
	e.add_combatant(ally, Vector2i(2, 2), Encounter.TEAM_PARTY)
	ally.take_damage(ally.hp + 5)
	var potion := "potion_of_cure_light_wounds"
	kaelen.add_to_inventory(content.get_item(potion), 1)
	kaelen.feats.append("Power Attack")
	kaelen.abilities["int"] = 13
	kaelen.feats.append("Combat Expertise")
	var potions_before := kaelen.inventory_count(potion)
	var slots_before := kaelen.spell_slots_remaining(1)

	assert_false(bool(e.cast_active_spell("magic_missile", target_index)["ok"]), "casting is refused")
	assert_eq(kaelen.spell_slots_remaining(1), slots_before, "no spell slot is spent")
	assert_false(bool(e.use_potion_active(potion, target_index)["ok"]), "potions are refused")
	assert_eq(kaelen.inventory_count(potion), potions_before, "no potion is consumed")
	assert_false(bool(e.stabilize_active(2)["ok"]), "first aid is refused")
	assert_true(ally.has_condition("dying"), "the dying ally is untouched")
	assert_false(bool(e.set_active_power_attack(1)["ok"]), "Power Attack is refused")
	assert_eq(e.power_attack_amount_for(0), 0)
	assert_false(bool(e.set_active_combat_expertise(1)["ok"]), "Combat Expertise is refused")
	assert_eq(e.combat_expertise_pending_for(0), 0)
	assert_false(bool(e.can_active_turn_undead()["ok"]), "turning availability is refused")
	assert_true(
		String(e.can_active_turn_undead()["reason"]).contains("pending combat decision"),
		"the reason names the pending decision"
	)
	assert_false(bool(e.turn_undead()["ok"]), "turning is refused")
	assert_true(e.has_pending_decision(), "nothing cleared the decision")
	assert_true(bool(e.turn_state["standard_used"]), "no extra action was spent")


func test_equipment_and_inventory_use_are_refused_while_pending() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var kaelen: Character = setup["actor"]
	Game.encounter = e
	Game.mode = "combat"
	Game.party.clear()
	Game.party.append(kaelen)
	kaelen.add_to_inventory(content.get_item("dagger"), 1)
	kaelen.add_to_inventory(content.get_item("potion_of_cure_light_wounds"), 1)
	var daggers_before := kaelen.inventory_count("dagger")
	var potions_before := kaelen.inventory_count("potion_of_cure_light_wounds")
	var weapon_before := String(kaelen.equipment.get("weapon", {}).get("id", ""))
	var dagger_index := -1
	var potion_index := -1
	for i in kaelen.inventory.size():
		var id := String(kaelen.inventory[i]["id"])
		if id == "dagger":
			dagger_index = i
		if id == "potion_of_cure_light_wounds":
			potion_index = i
	assert_true(dagger_index >= 0 and potion_index >= 0)
	assert_false(bool(Game.equip_item(0, dagger_index)["ok"]), "equipment change is refused")
	assert_eq(String(kaelen.equipment.get("weapon", {}).get("id", "")), weapon_before)
	assert_eq(kaelen.inventory_count("dagger"), daggers_before, "the item stays in the inventory")
	assert_false(bool(Game.use_item(0, potion_index)["ok"]), "inventory use is refused")
	assert_eq(kaelen.inventory_count("potion_of_cure_light_wounds"), potions_before)


func test_auto_advance_cannot_run_monster_turns_while_pending() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var pointer := e.turn_ptr
	var round_number := e.round_number
	e.auto_advance()
	assert_eq(e.turn_ptr, pointer, "the turn pointer does not move")
	assert_eq(e.round_number, round_number)
	assert_true(e.has_pending_decision())
	assert_eq(e.active_character(), setup["actor"])


func test_duplicate_resolution_is_refused_and_effects_apply_once() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var kaelen: Character = setup["actor"]
	var first := e.resolve_trip_decision(false)
	assert_true(bool(first["ok"]), String(first.get("message", "")))
	assert_true(kaelen.is_prone(), "keeping the weapon means falling prone")
	var second := e.resolve_trip_decision(true)
	assert_false(bool(second["ok"]), "a duplicate submission is refused")
	assert_true(kaelen.is_prone(), "the second submission changes nothing")
	assert_eq(e.ground_items.size(), 0, "nothing is dropped twice")
	var applied := 0
	for line in e.log_lines:
		if String(line).contains("keeps the weapon and is tripped"):
			applied += 1
	assert_eq(applied, 1, "the effect is applied exactly once")


func test_encounter_end_voids_the_decision_without_applying_effects() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var kaelen: Character = setup["actor"]
	e.finish("victory")
	assert_false(e.has_pending_decision(), "termination clears the decision")
	assert_false(kaelen.is_prone(), "the void decision does not trip the actor")
	assert_eq(e.ground_items.size(), 0, "no weapon is dropped by the void decision")
	assert_false(bool(e.resolve_trip_decision(true)["ok"]), "it cannot be resolved afterwards")
	var logged := false
	for line in e.log_lines:
		if String(line).contains("pending combat decision is void"):
			logged = true
	assert_true(logged, "the cancellation is logged, not silent")


func test_dead_actor_voids_the_decision_without_effects() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var kaelen: Character = setup["actor"]
	kaelen.take_damage(kaelen.hp + 50)
	var result := e.resolve_trip_decision(false)
	assert_false(bool(result["ok"]), "a dead actor cannot complete the decision")
	assert_false(kaelen.is_prone())
	assert_eq(e.ground_items.size(), 0)
	assert_false(e.has_pending_decision(), "the stale decision is not left locking combat")


func test_turn_change_voids_the_decision() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var kaelen: Character = setup["actor"]
	e._advance()
	e._begin_turn(e.combatants[e.order[e.turn_ptr]])
	assert_false(e.has_pending_decision(), "the next turn start clears the stale decision")
	var result := e.resolve_trip_decision(false)
	assert_false(bool(result["ok"]))
	assert_false(kaelen.is_prone(), "no late effect is applied to the previous actor")


func test_dropped_weapon_exists_only_on_the_ground() -> void:
	var setup := _pending()
	var e: Encounter = setup["e"]
	var kaelen: Character = setup["actor"]
	assert_true(bool(e.resolve_trip_decision(true)["ok"]))
	assert_eq(e.ground_items.size(), 1, "the weapon is on the ground")
	assert_eq(kaelen.inventory_count("light_flail"), 0, "it is not in the backpack")
	assert_true(Dictionary(kaelen.equipment.get("weapon", {})).is_empty(), "it is not equipped")
	assert_false(kaelen.is_prone(), "dropping kept the actor standing")


func test_ground_items_are_recovered_only_on_victory() -> void:
	# A real session is needed because the victory path autosaves, and saving
	# serializes the dungeon. Only the encounter itself is test-local.
	Game.new_game(["kaelen"], 424242)
	var item := content.get_item("dagger")
	var carrier := _char("kaelen")
	carrier.inventory.clear()

	var win := _encounter([carrier], [_monster("zombie")])
	win.ground_items.append({"id": "dagger", "item": item.duplicate(true), "cell": Vector2i(2, 3)})
	Game.party.clear()
	Game.party.append(carrier)
	Game.encounter = win
	Game.mode = "combat"
	Game.active_encounter_data = {}
	Game._encounter_resolved = false
	win.finish("victory")
	Game._resolve_encounter()
	assert_eq(carrier.inventory_count("dagger"), 1, "victory recovers the dropped item")
	assert_eq(win.ground_items.size(), 0, "the ground entry is cleared, not duplicated")

	var lose := _encounter([carrier], [_monster("zombie")])
	lose.ground_items.append({"id": "dagger", "item": item.duplicate(true), "cell": Vector2i(2, 3)})
	carrier.inventory.clear()
	Game.encounter = lose
	Game.mode = "combat"
	Game._encounter_resolved = false
	lose.finish("defeat")
	Game._resolve_encounter()
	assert_eq(carrier.inventory_count("dagger"), 0, "defeat grants nothing")
	assert_eq(lose.ground_items.size(), 1, "defeat leaves the item on the battlefield")
