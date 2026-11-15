extends GutTest

## Threat follows actual melee capability.
##
## PHB printed p. 137: "You threaten all squares into which you can make a melee
## attack." Reach alone is therefore not enough, and a ranged-only weapon is never
## used as an improvised melee blow. PHB printed p. 140 defines engagement as
## "enemies of each other and either threatens the other", so an ally who cannot
## threaten can still be engaged when the target can strike back. Flat-footedness
## is a separate restriction (p. 133): a flat-footed creature still threatens, it
## just cannot take the reaction.

var content: ContentDB


func before_each() -> void:
	content = Game.content


func _sera() -> Character:
	var ch := Character.from_content(content.get_character("sera"), content.items)
	ch.id = "qa_threat_sera"
	ch.display_name = "QA Sera"
	ch.max_hp = 40
	ch.hp = 40
	return ch


func _zombie(id := "qa_threat_zombie") -> Character:
	var ch := Character.from_content(content.get_monster("zombie"), content.items)
	ch.id = id
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
	rng.seed = 445566
	var e := Encounter.new()
	e.setup(party, monsters, _map(), rng, party_cells, monster_cells, content.spells, "Test")
	e.begin()
	e.turn_ptr = e.order.find(int(e.entry_for(party[0])["index"]))
	e._begin_turn(e.entry_for(party[0]))
	return e


func _two_axes(first: Character, second: Character) -> Encounter:
	return _encounter([first], [second], [Vector2i(2, 3)], [Vector2i(3, 3)])


func _start_turn(e: Encounter, ch: Character) -> void:
	e.turn_ptr = e.order.find(int(e.entry_for(ch)["index"]))
	e._begin_turn(e.entry_for(ch))


func _log_text(e: Encounter) -> String:
	return "\n".join(e.log_lines)


func test_a_readied_melee_weapon_threatens_the_adjacent_square() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	assert_eq(String(sera.equipment["weapon"]["id"]), "short_sword", "the sword is readied")
	var threatening := e._threatening_enemies(e.entry_for(zombie))
	assert_eq(threatening.size(), 1, "a readied melee weapon threatens")
	assert_true(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "the adjacent square is threatened")
	assert_true(e._threatened_by_enemy(e.entry_for(zombie)), "the zombie is threatened")


func test_a_ranged_only_weapon_does_not_threaten() -> void:
	var sera := _sera()
	sera.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	assert_true(e.threat_capability(sera).is_empty(), "a crossbow offers no melee threat")
	assert_false(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "the crossbow does not threaten")
	assert_false(e._threatened_by_enemy(e.entry_for(zombie)), "the zombie is not threatened by a crossbow")
	assert_eq(e._threatening_enemies(e.entry_for(zombie)).size(), 0, "no threatened enemy is listed")


func test_an_unsupported_reaction_is_refused_and_consumes_nothing() -> void:
	var sera := _sera()
	sera.add_to_inventory(content.get_item("short_sword"))
	sera.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	zombie.hp = 60
	e._provoke_single_opportunity(sera, zombie)
	var text := _log_text(e)
	assert_true(text.contains("no melee attack ready"), "the refusal names the reason")
	assert_false(text.contains("Attack of opportunity by"), "no attack is rolled")
	assert_eq(zombie.hp, 60, "nothing is damaged by a ranged opportunity attack")
	assert_false(bool(e.aoo_used.get(int(e.entry_for(sera)["index"]), false)), "no reaction is consumed")
	# The reaction is still available once a melee weapon is readied again.
	_start_turn(e, sera)
	var sheathed: Dictionary = e.sheathe_weapon()
	assert_true(bool(sheathed["ok"]), String(sheathed.get("message", "")))
	_start_turn(e, sera)
	assert_true(bool(e.draw_weapon("short_sword")["ok"]), "the sword can be readied")
	assert_false(e.threat_capability(sera).is_empty(), "the character threatens again")
	e._provoke_single_opportunity(sera, zombie)
	assert_true(_log_text(e).contains("Attack of opportunity by"), "the reaction now resolves")


func test_switching_to_a_crossbow_removes_threat_and_back_restores_it() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	assert_true(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "armed with the sword")
	_start_turn(e, sera)
	assert_true(bool(e.sheathe_weapon()["ok"]), "sheathing costs a move action")
	_start_turn(e, sera)
	assert_true(bool(e.draw_weapon("light_crossbow")["ok"]), "the crossbow is readied")
	assert_false(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "a crossbow does not threaten")
	_start_turn(e, sera)
	assert_true(bool(e.sheathe_weapon()["ok"]), "the crossbow can be put away")
	_start_turn(e, sera)
	assert_true(bool(e.draw_weapon("short_sword")["ok"]), "the sword is readied again")
	assert_true(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "threat returns with the sword")


func test_flat_footed_still_threatens_but_cannot_react() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _encounter([sera], [zombie], [Vector2i(2, 3)], [Vector2i(3, 3)])
	_start_turn(e, sera)
	assert_true(e.is_flat_footed(int(e.entry_for(zombie)["index"])), "the zombie has not acted yet")
	assert_true(e._threatens_cell(zombie, Vector2i(3, 3), Vector2i(2, 3)), "it still threatens")
	e._provoke_single_opportunity(zombie, sera)
	assert_true(_log_text(e).contains("flat-footed"), "the reaction is refused as flat-footed")
	assert_false(bool(e.aoo_used.get(int(e.entry_for(zombie)["index"]), false)), "nothing is consumed")


func test_engagement_survives_when_only_the_target_threatens() -> void:
	var sera := _sera()
	sera.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var zombie := _zombie()
	var archer := Character.from_content(content.get_character("sera"), content.items)
	archer.id = "qa_threat_archer"
	archer.display_name = "QA Archer"
	archer.max_hp = 40
	archer.hp = 40
	archer.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var e := _encounter(
		[archer, sera], [zombie], [Vector2i(1, 2), Vector2i(2, 3)], [Vector2i(3, 3)]
	)
	# Sera cannot threaten; the zombie's slam does, so the pair is still engaged.
	var penalty := e._into_melee_penalty(
		archer, zombie, e.entry_for(archer), e.entry_for(zombie)
	)
	assert_eq(int(penalty["penalty"]), -4, String(penalty.get("reason", "")))
	assert_true(String(penalty["reason"]).contains("engaged"), "the reason names the engagement")


func test_no_engagement_when_neither_side_can_strike() -> void:
	var sera := _sera()
	sera.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var other := _sera()
	other.id = "qa_threat_other"
	other.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var archer := Character.from_content(content.get_character("sera"), content.items)
	archer.id = "qa_threat_third"
	archer.display_name = "QA Third"
	archer.max_hp = 40
	archer.hp = 40
	archer.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var e := _encounter(
		[archer, sera], [other], [Vector2i(1, 2), Vector2i(2, 3)], [Vector2i(3, 3)]
	)
	var penalty := e._into_melee_penalty(
		archer, other, e.entry_for(archer), e.entry_for(other)
	)
	assert_eq(int(penalty["penalty"]), 0, "two crossbows across the way are not engaged")
	assert_true(String(penalty["reason"]).contains("no friendly character is engaged"))


func test_flanking_requires_both_attackers_to_threaten() -> void:
	var sera := _sera()
	sera.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var kaelen := Character.from_content(content.get_character("kaelen"), content.items)
	kaelen.id = "qa_threat_kaelen"
	kaelen.display_name = "QA Kaelen"
	var zombie := _zombie()
	var e := _encounter(
		[sera, kaelen], [zombie], [Vector2i(2, 3), Vector2i(4, 3)], [Vector2i(3, 3)]
	)
	assert_false(e._is_flanked(int(e.entry_for(zombie)["index"])), "a crossbow user does not flank")
	sera.equipment["weapon"] = content.get_item("short_sword").duplicate(true)
	assert_true(e._is_flanked(int(e.entry_for(zombie)["index"])), "two melee threats flank")


func test_loading_still_provokes_from_a_melee_capable_enemy() -> void:
	var sera := _sera()
	sera.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	_start_turn(e, zombie)
	_start_turn(e, sera)
	var before := e.log_lines.size()
	e.load_weapon()
	var segment := "\n".join(e.log_lines.slice(before))
	assert_true(segment.contains("Attack of opportunity by"), "a slam still threatens the loader")


## PHB p.137: "If you're unarmed, you don't normally threaten any squares and thus
## can't make attacks of opportunity (but see Unarmed Attacks, page 139)." p.139:
## "An unarmed character can't take attacks of opportunity (but see 'Armed' Unarmed
## Attacks, below)." Empty hands are therefore an attack option, not an armed state.
func _empty_handed() -> Character:
	var ch := _sera()
	ch.equipment["weapon"] = {}
	return ch


func test_ordinary_empty_hands_do_not_threaten() -> void:
	var sera := _empty_handed()
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	assert_eq(String(e.available_melee_attack(sera).get("name", "")), "unarmed strike", "the strike can still be attempted")
	assert_true(e.threat_capability(sera).is_empty(), "but an ordinary unarmed character is not armed")
	assert_false(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "no square is threatened")
	assert_false(e._threatened_by_enemy(e.entry_for(zombie)), "the zombie is not threatened")
	e._provoke_single_opportunity(sera, zombie)
	var text := _log_text(e)
	assert_true(text.contains("no melee attack ready"), "the reaction is refused with a reason")
	assert_false(text.contains("Attack of opportunity by"), "no attack is rolled")
	assert_false(bool(e.aoo_used.get(int(e.entry_for(sera)["index"]), false)), "no reaction is consumed")


func test_improved_unarmed_strike_makes_empty_hands_armed() -> void:
	var sera := _empty_handed()
	sera.feats.append("Improved Unarmed Strike")
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	assert_false(e.threat_capability(sera).is_empty(), "the feat makes the unarmed attack armed")
	assert_true(e._threatens_cell(sera, Vector2i(2, 3), Vector2i(3, 3)), "the adjacent square is threatened")
	_start_turn(e, zombie)
	_start_turn(e, sera)
	e._provoke_single_opportunity(sera, zombie)
	assert_true(_log_text(e).contains("Attack of opportunity by"), "the armed unarmed attack can react")


func test_a_natural_weapon_threatens() -> void:
	var sera := _sera()
	var zombie := _zombie()
	var e := _two_axes(sera, zombie)
	assert_eq(String(e.threat_capability(zombie).get("name", "")), "slam", "the zombie's natural attack is armed")
	assert_true(e._threatens_cell(zombie, Vector2i(3, 3), Vector2i(2, 3)), "it threatens the fighter")
	assert_true(e._threatened_by_enemy(e.entry_for(sera)), "and the fighter is threatened by it")


func test_empty_handed_actor_does_not_flank() -> void:
	var sera := _empty_handed()
	var kaelen := Character.from_content(content.get_character("kaelen"), content.items)
	kaelen.id = "qa_threat_kaelen_empty"
	kaelen.display_name = "QA Kaelen"
	var zombie := _zombie()
	var e := _encounter(
		[sera, kaelen], [zombie], [Vector2i(2, 3), Vector2i(4, 3)], [Vector2i(3, 3)]
	)
	assert_false(e._is_flanked(int(e.entry_for(zombie)["index"])), "one empty-handed enemy cannot complete a flank")
	sera.equipment["weapon"] = content.get_item("short_sword").duplicate(true)
	assert_true(e._is_flanked(int(e.entry_for(zombie)["index"])), "an armed enemy on the other side does")


func test_empty_hands_across_the_way_are_not_engaged() -> void:
	var sera := _empty_handed()
	var other := _empty_handed()
	other.id = "qa_threat_other_empty"
	var archer := Character.from_content(content.get_character("sera"), content.items)
	archer.id = "qa_threat_archer_empty"
	archer.display_name = "QA Archer"
	archer.max_hp = 40
	archer.hp = 40
	archer.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var e := _encounter(
		[archer, sera], [other], [Vector2i(1, 2), Vector2i(2, 3)], [Vector2i(3, 3)]
	)
	var penalty := e._into_melee_penalty(
		archer, other, e.entry_for(archer), e.entry_for(other)
	)
	assert_eq(int(penalty["penalty"]), 0, "neither side threatens, so there is no melee to shoot into")
	assert_true(String(penalty["reason"]).contains("no friendly character is engaged"))


func test_loading_does_not_provoke_from_an_ordinary_empty_handed_enemy() -> void:
	var kaelen := Character.from_content(content.get_character("kaelen"), content.items)
	kaelen.id = "qa_threat_loader"
	kaelen.display_name = "QA Loader"
	kaelen.add_to_inventory(content.get_item("light_crossbow"))
	kaelen.equipment["weapon"] = content.get_item("light_crossbow").duplicate(true)
	var empty_enemy := _empty_handed()
	empty_enemy.id = "qa_threat_empty_enemy"
	empty_enemy.display_name = "QA Empty Enemy"
	var e := _encounter([kaelen], [empty_enemy], [Vector2i(2, 3)], [Vector2i(3, 3)])
	_start_turn(e, empty_enemy)
	_start_turn(e, kaelen)
	var before := e.log_lines.size()
	var loaded := e.load_weapon()
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	var segment := "
".join(e.log_lines.slice(before))
	assert_false(segment.contains("loading a crossbow provokes"), "an unarmed enemy does not threaten the loader")
	assert_false(segment.contains("Attack of opportunity by"), "and rolls no reaction")
	assert_true(e.is_weapon_loaded(kaelen), "the load completes")
