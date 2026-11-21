extends GutTest

## Encounter resolution: victory and defeat are not "nobody can act this instant".
##
## PHB p.147 makes nonlethal unconsciousness a helpless state, and the supported
## nonlethal defeat path treats it as out of the fight. Ghoul paralysis (MM p.119,
## 1d4+1 rounds) and timed unconsciousness effects expire, so neither may end an
## encounter, grant XP, apply victory effects or set campaign flags.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 5150


func after_each() -> void:
	SaveSystem.delete_save_everywhere("slot1")
	SaveSystem.delete_save_everywhere("auto")


func _monster(id: String) -> Character:
	var ch := Character.from_content(content.get_monster(id), content.items)
	ch.hp = ch.max_hp
	ch.speed_ft = 0
	return ch


func _fighter() -> Character:
	var ch := Character.from_content(content.get_character("kaelen"), content.items)
	ch.hp = ch.max_hp
	ch.equipment["weapon"] = {}
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
		"resolution"
	)


func _encounter(party: Array, monsters: Array) -> Encounter:
	var cells_party: Array = []
	var cells_monsters: Array = []
	for i in party.size():
		cells_party.append(Vector2i(2 + i, 3))
	for i in monsters.size():
		cells_monsters.append(Vector2i(2 + i, 1))
	var e := Encounter.new()
	e.setup(
		party,
		monsters,
		_map(),
		rng,
		cells_party,
		cells_monsters,
		content.spells,
		"Resolution"
	)
	e.begin()
	e.turn_ptr = e.order.find(int(e.entry_for(party[0])["index"]))
	e._begin_turn(e.entry_for(party[0]))
	return e


# ------------------------------------------------------------ enemy side

func test_a_paralysed_enemy_does_not_end_the_encounter() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var e := _encounter([hero], [zombie])
	zombie.add_effect("paralyzed", "Paralyzed", 3)
	e._check_end()
	assert_false(e.finished, "paralysis is temporary and recoverable")
	assert_eq(e.outcome, "")
	assert_eq(zombie.nonlethal_state(), "none")


func test_timed_unconsciousness_on_an_enemy_does_not_end_the_encounter() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var e := _encounter([hero], [zombie])
	zombie.add_effect("unconscious", "Sleep (temporary)", 5)
	e._check_end()
	assert_false(e.finished, "a timed unconsciousness effect can expire")
	assert_eq(e.outcome, "")


func test_nonlethal_incapacitation_ends_the_encounter_in_victory() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var e := _encounter([hero], [zombie])
	zombie.apply_nonlethal(zombie.hp + 1)
	e._check_end()
	assert_true(e.finished)
	assert_eq(e.outcome, "victory")


func test_a_dead_enemy_still_counts_as_defeated() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var e := _encounter([hero], [zombie])
	zombie.take_damage(zombie.hp + 20)
	e._check_end()
	assert_true(e.finished)
	assert_eq(e.outcome, "victory")


func test_mixed_groups_resolve_only_when_every_enemy_is_defeated() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var ghoul := _monster("ghoul")
	var e := _encounter([hero], [zombie, ghoul])
	zombie.take_damage(zombie.hp + 20)
	ghoul.add_effect("paralyzed", "Paralyzed", 2)
	e._check_end()
	assert_false(e.finished, "one dead enemy and one paralysed enemy is not a win")
	ghoul.apply_nonlethal(ghoul.hp + 1)
	e._check_end()
	assert_true(e.finished, "the last enemy is now out of the fight")
	assert_eq(e.outcome, "victory")


# ------------------------------------------------------------ party side

func test_party_paralysis_is_not_an_irreversible_defeat() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var e := _encounter([hero], [zombie])
	hero.add_effect("paralyzed", "Paralyzed", 3)
	e._check_end()
	assert_false(e.finished, "the party is temporarily unable to act, not beaten")
	assert_eq(e.outcome, "")


func test_a_whole_party_paralysed_keeps_the_encounter_running() -> void:
	var a := _fighter()
	var b := _fighter()
	b.id = "qa_second_fighter"
	var zombie := _monster("zombie")
	var e := _encounter([a, b], [zombie])
	a.add_effect("paralyzed", "Paralyzed", 2)
	b.add_effect("paralyzed", "Paralyzed", 2)
	e._check_end()
	assert_false(e.finished, "nobody can act, but the paralysis expires")
	# The turn loop skips the paralysed combatants and lets the effect run down.
	var guard := 0
	while not e.finished and guard < 12:
		guard += 1
		e.end_turn()
		e.auto_advance()
		if not a.has_condition("paralyzed") and not b.has_condition("paralyzed"):
			break
	assert_false(a.has_condition("paralyzed"), "paralysis wore off")
	assert_false(b.has_condition("paralyzed"), "paralysis wore off")
	assert_false(e.finished, "the encounter survived the temporary incapacity")


func test_a_nonlethally_knocked_out_party_is_defeated() -> void:
	var a := _fighter()
	var b := _fighter()
	b.id = "qa_second_fighter"
	var zombie := _monster("zombie")
	var e := _encounter([a, b], [zombie])
	a.apply_nonlethal(a.hp + 1)
	b.apply_nonlethal(b.hp + 1)
	e._check_end()
	assert_true(e.finished)
	assert_eq(e.outcome, "defeat")


func test_a_dead_party_is_defeated() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var e := _encounter([hero], [zombie])
	hero.take_damage(hero.hp + 20)
	e._check_end()
	assert_true(e.finished)
	assert_eq(e.outcome, "defeat")


func test_a_dying_party_member_does_not_keep_the_encounter_alive_alone() -> void:
	var hero := _fighter()
	var zombie := _monster("zombie")
	var e := _encounter([hero], [zombie])
	hero.hp = -3
	hero.add_effect("dying", "Dying", -1)
	hero.add_effect("unconscious", "Unconscious", -1)
	e._check_end()
	assert_true(e.finished)
	assert_eq(e.outcome, "defeat")


# ------------------------------------------------------------ rewards

func test_temporary_incapacity_grants_no_victory_xp_or_flags() -> void:
	Game.new_game(["kaelen", "aldric"], 4242)
	Game.start_encounter("qa_victory")
	var e := Game.encounter
	var xp_before: int = int(Game.party[0].xp)
	var flags_before := Game.flags.duplicate(true)
	var zombie: Character = null
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			zombie = entry["char"]
	assert_not_null(zombie, "the QA encounter has an enemy")
	zombie.add_effect("paralyzed", "Paralyzed", 3)
	e._check_end()
	assert_false(e.finished, "no victory from paralysis")
	assert_eq(Game.mode, "combat", "the game stays in combat")
	assert_eq(int(Game.party[0].xp), xp_before, "no XP for a temporary incapacity")
	assert_eq(Game.flags, flags_before, "no campaign flag changes")
	# Now the supported nonlethal path does finish it, and rewards land once.
	zombie.apply_nonlethal(zombie.hp + 1)
	e._check_end()
	assert_true(e.finished)
	assert_eq(e.outcome, "victory")
	assert_eq(int(Game.party[0].xp), xp_before + int(e.xp_award), "XP is granted on the real victory")
	var xp_after: int = int(Game.party[0].xp)
	e.changed.emit()
	assert_eq(int(Game.party[0].xp), xp_after, "the same resolution never awards twice")
