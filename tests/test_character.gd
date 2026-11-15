extends GutTest

## Character state, inventory, spells and condition lifecycle.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _char(id: String) -> Character:
	var ch := Character.from_content(content.get_character(id), content.items)
	ch.hp = ch.max_hp
	return ch


func test_damage_and_disabled_at_zero() -> void:
	var kaelen := _char("kaelen")
	var result := kaelen.take_damage(5)
	assert_eq(kaelen.hp, 23)
	assert_false(bool(result["died"]))
	kaelen.take_damage(23)
	assert_eq(kaelen.hp, 0)
	assert_true(kaelen.has_condition("disabled"))


func test_dying_and_death_thresholds() -> void:
	var kaelen := _char("kaelen")
	kaelen.take_damage(29)
	assert_eq(kaelen.hp, -1)
	assert_true(kaelen.has_condition("dying"))
	assert_true(kaelen.has_condition("unconscious"))
	assert_false(kaelen.can_act())
	kaelen.take_damage(20)
	assert_eq(kaelen.hp, -10)
	assert_true(kaelen.has_condition("dead"))
	assert_true(kaelen.dead)


func test_healing_stabilizes_then_revives() -> void:
	var kaelen := _char("kaelen")
	kaelen.take_damage(33)
	assert_eq(kaelen.hp, -5)
	kaelen.heal(3)
	assert_eq(kaelen.hp, -2)
	assert_false(kaelen.has_condition("dying"), "any healing stops the dying condition")
	assert_true(kaelen.has_condition("stable"))
	kaelen.heal(10)
	assert_eq(kaelen.hp, 8)
	assert_false(kaelen.has_condition("unconscious"))
	assert_true(kaelen.can_act())


func test_stabilize_action() -> void:
	var kaelen := _char("kaelen")
	kaelen.take_damage(30)
	assert_true(kaelen.has_condition("dying"))
	kaelen.stabilize()
	assert_false(kaelen.has_condition("dying"))
	assert_true(kaelen.has_condition("stable"))


func test_temporary_hit_points_absorb_first() -> void:
	var kaelen := _char("kaelen")
	kaelen.temp_hp = 5
	var result := kaelen.take_damage(8)
	assert_eq(int(result["temp_absorbed"]), 5)
	assert_eq(kaelen.temp_hp, 0)
	assert_eq(kaelen.hp, 25)


func test_equipment_and_inventory_management() -> void:
	var sera := _char("sera")
	var torch: Dictionary = content.get_item("torch")
	sera.add_to_inventory(torch, 1)
	assert_eq(sera.inventory_count("torch"), 1)
	sera.equip("weapon", content.get_item("light_crossbow"))
	assert_eq(String(sera.equipped("weapon")["id"]), "light_crossbow")
	assert_true(sera.remove_from_inventory("torch", 1))
	assert_eq(sera.inventory_count("torch"), 0)
	assert_false(sera.remove_from_inventory("torch", 1), "cannot remove absent items")


func test_equipment_changes_ac() -> void:
	var ysolde := _char("ysolde")
	assert_eq(Rules.armor_class(ysolde), 13)
	var leather: Dictionary = content.get_item("leather_armor")
	ysolde.equip("armor", leather)
	assert_eq(Rules.armor_class(ysolde), 15)


func test_spell_preparation_and_consumption() -> void:
	var ysolde := _char("ysolde")
	assert_eq(ysolde.spell_slots_remaining(1), 3)
	assert_eq(ysolde.spell_slots_remaining(2), 2)
	assert_true(ysolde.can_cast(1, "magic_missile"))
	assert_true(ysolde.consume_spell(1, "magic_missile"))
	assert_eq(ysolde.spell_slots_remaining(1), 2)
	assert_eq(Array(ysolde.spells["prepared"]["1"]).count("magic_missile"), 1)
	assert_false(ysolde.can_cast(1, "cure_light_wounds"), "cleric spell is not prepared")


func test_spontaneous_caster_uses_slots_without_preparation() -> void:
	var mira := _char("mira")
	assert_true(bool(mira.spells["spontaneous"]))
	assert_true(mira.can_cast(1, "magic_missile"))
	assert_eq(mira.spell_slots_remaining(1), 6)
	mira.consume_spell(1, "magic_missile")
	assert_eq(mira.spell_slots_remaining(1), 5)
	assert_true(mira.can_cast(1, "magic_missile"))


func test_rest_restores_hp_slots_and_prepared_list() -> void:
	var ysolde := _char("ysolde")
	ysolde.consume_spell(1, "magic_missile")
	ysolde.take_damage(9)
	ysolde.rest()
	assert_eq(ysolde.hp, ysolde.max_hp)
	assert_eq(ysolde.spell_slots_remaining(1), 3)
	assert_eq(Array(ysolde.spells["prepared"]["1"]).count("magic_missile"), 2)


func test_effects_do_not_stack_and_expire() -> void:
	var kaelen := _char("kaelen")
	assert_true(kaelen.add_effect("bless", "Bless", 30, "buff"))
	assert_false(kaelen.add_effect("bless", "Bless", 30, "buff"), "same effect refreshes, does not stack")
	assert_eq(kaelen.effects.size(), 1)
	for i in 30:
		kaelen.tick_effects()
	assert_false(kaelen.has_effect("bless"), "bless expires after 30 rounds")


func test_experience_and_serialization_round_trip() -> void:
	var sera := _char("sera")
	sera.xp = 3300
	sera.hp = 9
	sera.add_effect("bless", "Bless", 4, "buff")
	sera.add_to_inventory(content.get_item("torch"), 2)
	var data := sera.to_dict()
	var restored := Character.from_dict(data, content.items)
	assert_eq(restored.display_name, sera.display_name)
	assert_eq(restored.hp, 9)
	assert_eq(restored.xp, 3300)
	assert_eq(restored.inventory_count("torch"), 2)
	assert_true(restored.has_effect("bless"))
	assert_eq(String(restored.equipped("weapon")["id"]), String(sera.equipped("weapon")["id"]))
