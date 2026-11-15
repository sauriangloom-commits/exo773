extends GutTest

## Ready or loose a shield.
##
## PHB printed p. 142: "Strapping a shield to your arm to gain its shield bonus to
## your AC, or unstrapping and dropping a shield so you can use your shield hand for
## another purpose, requires a move action." Loosing therefore drops the shield; it
## does not store it. Picking it up again uses the existing Pick up action. PHB
## printed p. 138: "You can take a move action in place of a standard action," so a
## second move-equivalent in one turn may spend the standard action instead.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _kaelen() -> Character:
	var ch := Character.from_content(content.get_character("kaelen"), content.items)
	ch.id = "qa_shield_kaelen"
	ch.display_name = "QA Kaelen"
	ch.max_hp = 40
	ch.hp = 40
	return ch


func _zombie() -> Character:
	var ch := Character.from_content(content.get_monster("zombie"), content.items)
	ch.id = "qa_shield_zombie"
	ch.display_name = "QA Zombie"
	ch.max_hp = 60
	ch.hp = 60
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


func _encounter(party: Array, monsters: Array, party_cells: Array, monster_cells: Array) -> Encounter:
	var rng := RandomNumberGenerator.new()
	rng.seed = 778899
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	e.turn_ptr = e.order.find(int(e.entry_for(party[0])["index"]))
	e._begin_turn(e.entry_for(party[0]))
	return e


func _two_axes(first: Character, second: Character) -> Encounter:
	return _encounter([first], [second], [Vector2i(2, 3)], [Vector2i(8, 3)])


func _start_turn(e: Encounter, ch: Character) -> void:
	e.turn_ptr = e.order.find(int(e.entry_for(ch)["index"]))
	e._begin_turn(e.entry_for(ch))


func _log_text(e: Encounter) -> String:
	return "\n".join(e.log_lines)


func test_the_shipped_fighter_starts_with_a_strapped_shield() -> void:
	var kaelen := _kaelen()
	var shield: Dictionary = kaelen.equipment.get("shield", {})
	assert_eq(String(shield.get("id", "")), "heavy_steel_shield", "the shield is strapped on")
	var rows := kaelen.carried_shields()
	assert_eq(rows.size(), 1, "one shield is listed")
	assert_true(bool(rows[0]["equipped"]), "and it is marked as strapped")
	assert_eq(Rules.armor_class(kaelen), 17, "AC includes the shield bonus, Dexterity cap and armor")


func test_loosing_a_shield_drops_it_and_lowers_ac() -> void:
	var kaelen := _kaelen()
	var zombie := _zombie()
	var e := _two_axes(kaelen, zombie)
	var ac_before := Rules.armor_class(kaelen)
	var result := e.loose_shield()
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_true(bool(result["spent_move"]), "loosing spends a move action")
	assert_true(kaelen.equipment.get("shield", {}).is_empty(), "no shield is strapped on")
	assert_eq(Rules.armor_class(kaelen), ac_before - 2, "the shield bonus leaves the AC")
	assert_eq(kaelen.inventory_count("heavy_steel_shield"), 0, "loosing is not storing")
	assert_eq(e.ground_items.size(), 1, "the shield is on the ground")
	assert_eq(String(e.ground_items[0]["id"]), "heavy_steel_shield", "the dropped shield is identified")
	assert_eq(Vector2i(e.ground_items[0]["cell"]), Vector2i(2, 3), "it lies on the character's square")
	assert_true(_log_text(e).contains("unstraps and drops Heavy Steel Shield"), "the log says what happened")


func test_dropped_shield_can_be_picked_up_and_strapped_on_again() -> void:
	var kaelen := _kaelen()
	var zombie := _zombie()
	var e := _two_axes(kaelen, zombie)
	var ac_with_shield := Rules.armor_class(kaelen)
	assert_true(bool(e.loose_shield()["ok"]), "loosed and dropped")
	_start_turn(e, kaelen)
	var picked := e.pick_up_active(0)
	assert_true(bool(picked["ok"]), String(picked.get("message", "")))
	assert_eq(kaelen.inventory_count("heavy_steel_shield"), 1, "the shield is carried again")
	assert_eq(e.ground_items.size(), 0, "nothing is left on the ground")
	_start_turn(e, kaelen)
	var readied := e.ready_shield("heavy_steel_shield")
	assert_true(bool(readied["ok"]), String(readied.get("message", "")))
	assert_true(bool(readied["spent_move"]), "strapping it on spends a move action")
	assert_eq(String(kaelen.equipment["shield"]["id"]), "heavy_steel_shield", "the shield is strapped on")
	assert_eq(kaelen.inventory_count("heavy_steel_shield"), 0, "it is no longer duplicated in inventory")
	assert_eq(Rules.armor_class(kaelen), ac_with_shield, "the shield bonus returns")
	assert_true(kaelen.carried_shields()[0]["equipped"], "the control reports it as strapped")


func test_a_second_shield_cannot_be_strapped_over_the_first() -> void:
	var kaelen := _kaelen()
	kaelen.add_to_inventory(content.get_item("light_wooden_shield"))
	var zombie := _zombie()
	var e := _two_axes(kaelen, zombie)
	var result := e.ready_shield("light_wooden_shield")
	assert_false(bool(result["ok"]), "only one shield can be strapped on")
	assert_true(String(result["message"]).contains("loosing it"), "the reason names the loose action")
	assert_false(bool(e.turn_state["move_used"]), "the refusal spends nothing")
	assert_eq(String(kaelen.equipment["shield"]["id"]), "heavy_steel_shield", "the first shield stays")


func test_loosing_without_a_shield_is_refused() -> void:
	var sera := Character.from_content(content.get_character("sera"), content.items)
	sera.id = "qa_shield_sera"
	sera.display_name = "QA Sera"
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	var result := e.loose_shield()
	assert_false(bool(result["ok"]), "there is nothing to loose")
	assert_true(String(result["message"]).contains("no shield"), "the reason is explicit")
	assert_false(bool(e.turn_state["move_used"]), "nothing is spent")


func test_a_shield_cannot_be_strapped_on_around_a_two_handed_weapon() -> void:
	var sera := Character.from_content(content.get_character("sera"), content.items)
	sera.id = "qa_shield_two_hand"
	sera.display_name = "QA Sera"
	sera.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	sera.add_to_inventory(content.get_item("light_wooden_shield"))
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	var result := e.ready_shield("light_wooden_shield")
	assert_false(bool(result["ok"]), "a two-handed weapon leaves no shield hand")
	assert_true(String(result["message"]).contains("two hands"), "the reason names the hands")
	assert_false(bool(e.turn_state["move_used"]), "the refusal spends nothing")
	assert_eq(sera.inventory_count("light_wooden_shield"), 1, "the shield stays carried")


func test_loose_then_ready_uses_the_standard_action_in_one_turn() -> void:
	var kaelen := _kaelen()
	kaelen.add_to_inventory(content.get_item("light_wooden_shield"))
	var zombie := _zombie()
	var e := _two_axes(kaelen, zombie)
	assert_true(bool(e.loose_shield()["ok"]), "loosing spends the move action")
	assert_true(bool(e.turn_state["move_used"]), "the move action is gone")
	var readied := e.ready_shield("light_wooden_shield")
	assert_true(bool(readied["ok"]), String(readied.get("message", "")))
	assert_true(bool(e.turn_state["standard_used"]), "the second move-equivalent spends the standard action")
	assert_true(_log_text(e).contains("standard action used as a move; PHB p.138"), "the log names the slot")
	assert_eq(String(kaelen.equipment["shield"]["id"]), "light_wooden_shield", "the smaller shield is strapped on")
	var third := e.loose_shield()
	assert_false(bool(third["ok"]), "no third move-equivalent exists in the turn")
	assert_true(String(third["message"]).contains("No move or standard action"), "the reason is explicit")


func test_shield_state_is_saved_and_loaded_by_item_id() -> void:
	var kaelen := _kaelen()
	var zombie := _zombie()
	var e := _two_axes(kaelen, zombie)
	assert_true(bool(e.loose_shield()["ok"]))
	var picked := kaelen.to_dict()
	var restored := Character.from_dict(picked, content.items)
	assert_true(restored.equipment.get("shield", {}).is_empty(), "a loosed shield is absent from the save")
	assert_eq(restored.inventory_count("heavy_steel_shield"), 0, "the dropped copy is not duplicated")
	_start_turn(e, kaelen)
	e.pick_up_active(0)
	_start_turn(e, kaelen)
	assert_true(bool(e.ready_shield("heavy_steel_shield")["ok"]))
	var saved := Character.from_dict(kaelen.to_dict(), content.items)
	assert_eq(
		String(saved.equipment.get("shield", {}).get("id", "")),
		"heavy_steel_shield",
		"a strapped shield survives the save round trip",
	)
	assert_eq(saved.inventory_count("heavy_steel_shield"), 0, "and is not also stored in inventory")


func test_shield_state_does_not_leak_between_characters() -> void:
	var kaelen := _kaelen()
	var sera := Character.from_content(content.get_character("sera"), content.items)
	sera.id = "qa_shield_sera2"
	sera.display_name = "QA Sera"
	var zombie := _zombie()
	var e := _encounter(
		[kaelen, sera], [zombie], [Vector2i(2, 3), Vector2i(2, 4)], [Vector2i(8, 3)]
	)
	assert_true(bool(e.loose_shield()["ok"]))
	assert_true(sera.equipment.get("shield", {}).is_empty(), "the other character is untouched")
