extends GutTest

## Batch A of docs/REACHABLE_OPPOSITION_PLAN.md: the storeroom's second combatant
## is a living, armed looter, so Sera's authored 2d6 sneak attack has a legal
## target in ordinary play.
##
## Content-only batch. Nothing here asserts an engine, schema or validator change;
## the encounter keeps two combatants, its 300 XP and every award total.

var content: ContentDB
var rng: RandomNumberGenerator


func before_each() -> void:
	content = Game.content
	rng = RandomNumberGenerator.new()
	rng.seed = 991


func _storeroom() -> Encounter:
	var result := Game.new_game(["kaelen", "sera"], 991)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	Game.start_encounter("storeroom_dead")
	var e := Game.encounter
	assert_not_null(e, "the storeroom encounter started")
	return e


func _entry_for(e: Encounter, ch: Character) -> Dictionary:
	for entry in e.combatants:
		if entry["char"] == ch:
			return entry
	return {}


## The only enemy the sneak-attack rule can reach: no undead or construct tag.
func _living_enemy(e: Encounter) -> Dictionary:
	for entry in e.combatants:
		if int(entry["team"]) != Encounter.TEAM_ENEMY:
			continue
		var ch: Character = entry["char"]
		if ch != null and not Rules.nonlethal_immune(ch):
			return entry
	return {}


func _undead_enemy(e: Encounter) -> Dictionary:
	for entry in e.combatants:
		if int(entry["team"]) != Encounter.TEAM_ENEMY:
			continue
		var ch: Character = entry["char"]
		if ch != null and Rules.nonlethal_immune(ch):
			return entry
	return {}


func _force_turn(e: Encounter, ch: Character) -> void:
	var entry := _entry_for(e, ch)
	assert_false(entry.is_empty(), "%s is in the encounter" % ch.display_name)
	if entry.is_empty():
		return
	e.turn_ptr = e.order.find(int(entry["index"]))
	e._begin_turn(entry)


# ---------------------------------------------------------------- content shape


func test_store_looter_content_shape() -> void:
	assert_true(content.monsters.has("store_looter"), "content/shared/monsters.json defines store_looter")
	if not content.monsters.has("store_looter"):
		return
	var row: Dictionary = content.monsters["store_looter"]
	assert_true(bool(row.get("is_monster", false)), "it is authored as a monster")
	assert_false(Array(row.get("tags", [])).has("undead"), "a living creature is not undead-tagged")
	assert_false(Array(row.get("tags", [])).has("construct"), "a living creature is not construct-tagged")
	assert_eq(Array(row.get("immunities", [])), [], "it has no immunities")
	assert_false(bool(row.get("destroyed_at_zero", true)), "a living creature is not destroyed at 0 hp")
	assert_false(bool(row.get("single_actions_only", false)), "it is not restricted to one action like the zombie")
	assert_eq(Array(row.get("attacks", [])).size(), 1, "one authored weapon-shaped attack")
	assert_true(Array(row.get("inventory", [])).is_empty(), "it carries no loot")

	var ch := Character.from_content(row, content.items)
	assert_not_null(ch, "the stat block builds a Character")
	if ch == null:
		return
	assert_false(Rules.nonlethal_immune(ch), "nonlethal damage applies to a living creature")
	assert_false(ch.tags.has("undead"))
	assert_eq(ch.max_hp, 8)
	assert_eq(ch.ac(), 15, "chain shirt (+4) and Dex 12 (+1) give AC 15")
	assert_eq(ch.sneak_attack_dice, "", "only the rogue has sneak dice")
	assert_eq(String(ch.monster_type), "Humanoid (human)")
	assert_true(ch.equipment.has("armor"), "the armor is a real item reference")
	assert_eq(int(ch.equipment["armor"].get("armor_bonus", 0)), 4, "it wears a chain shirt")
	assert_false(ch.equipment.has("weapon"), "no equipment weapon is authored; the weapon lives in attacks")
	var attack: Dictionary = ch.attacks[0]
	assert_eq(String(attack.get("name", "")), "longsword")
	assert_eq(String(attack.get("damage", "")), "1d8")
	assert_eq(int(attack.get("crit_range", 20)), 19, "a longsword threatens on 19-20")
	assert_eq(int(Rules.damage_bonus(ch, attack)), 1, "Str 13 adds +1 to longsword damage")
	assert_eq(int(ch.total_attack_bonus(attack)), 2, "BAB 1 and Str 13 with martial proficiency give +2")


# ------------------------------------------------------- encounter and cell parity


func test_storeroom_has_one_living_opponent_and_matching_cells() -> void:
	var row: Dictionary = content.encounters.get("storeroom_dead", {})
	assert_false(row.is_empty(), "the storeroom encounter exists")
	if row.is_empty():
		return
	var monsters: Array = Array(row.get("monsters", []))
	var cells: Array = Array(row.get("monster_cells", []))
	assert_eq(monsters.size(), 2, "the encounter keeps two combatants")
	assert_eq(cells.size(), monsters.size(), "every monster has a cell (Encounter.setup otherwise falls back to (1, 0))")
	assert_eq(String(monsters[0]), "zombie", "the first zombie is unchanged")
	assert_eq(String(monsters[1]), "store_looter", "the second zombie is swapped for the looter")

	var map := BattleMap.from_rows(Array(row.get("rows", [])))
	var living := 0
	for raw_id in monsters:
		var ch := Character.from_content(content.get_monster(String(raw_id)), content.items)
		assert_not_null(ch, "monster %s resolves" % String(raw_id))
		if ch != null and not Rules.nonlethal_immune(ch):
			living += 1
	for cell in cells:
		var at := Vector2i(int(cell[0]), int(cell[1]))
		assert_false(map.is_blocked(at), "monster cell %s is open floor" % str(at))
	assert_eq(living, 1, "exactly one opponent is alive and sneakable")
	assert_eq(int(row.get("xp", 0)), 300, "the encounter award is untouched")

	var named := false
	for trigger in Array(content.dungeon_data.get("triggers", [])):
		if String(Dictionary(trigger).get("encounter", "")) == "storeroom_dead":
			named = true
	assert_true(named, "the storeroom_ambush trigger still names the encounter")


# ------------------------------------------------------------- sneak attack gate


## Sera (2d6 sneak dice, +1 Str damage, short sword) is placed next to the living
## looter on round 1. The looter has not acted, so it is flat-footed.
func test_sneak_attack_applies_to_the_living_looter() -> void:
	var e := _storeroom()
	var sera: Character = Game.party[1]
	assert_eq(String(sera.sneak_attack_dice), "2d6", "Sera is authored with 2d6")
	var looter := _living_enemy(e)
	assert_false(looter.is_empty(), "the storeroom holds a living opponent")
	if looter.is_empty():
		return
	_force_turn(e, sera)
	e.combatants[int(_entry_for(e, sera)["index"])]["cell"] = Vector2i(7, 3)
	e.combatants[int(looter["index"])]["cell"] = Vector2i(7, 2)
	assert_true(e.is_flat_footed(int(looter["index"])), "the looter has not acted yet")

	var hits := 0
	var extra_entry := ""
	var gate_line := false
	for attempt in 6:
		var before := e.log_lines.size()
		var result := e.attack_active(int(looter["index"]))
		assert_true(bool(result["ok"]), String(result.get("message", "")))
		var fresh := " ".join(Array(e.log_lines.slice(before)))
		assert_true(
			fresh.contains("sneak attack applies: +2d6"),
			"the sneak gate accepts a living flat-footed target: %s" % fresh
		)
		gate_line = true
		var inner: Dictionary = result.get("result", {})
		if bool(inner.get("hit", false)):
			hits += 1
			for raw_roll in Array(inner.get("damage_rolls", [])):
				if String(raw_roll).begins_with("extra "):
					extra_entry = String(raw_roll)
			# Sera: short sword 1d6+1 plus 2d6 sneak - 4 to 19 total.
			assert_between(int(inner.get("damage", 0)), 4, 19, "the hit rolls the short sword and the 2d6")
			break
		e.turn_state["standard_used"] = false
	assert_true(gate_line, "the sneak attack line is printed")
	assert_gt(hits, 0, "a seeded attack sequence hits at least once within six attempts")
	assert_ne(extra_entry, "", "a hit on the looter rolls the extra 2d6")


## The same attack against the zombie, also flat-footed, must not sneak: the
## project refuses sneak damage on the undead tag (PHB pp. 49-50).
func test_sneak_attack_is_refused_on_the_zombie() -> void:
	var e := _storeroom()
	var sera: Character = Game.party[1]
	var zombie := _undead_enemy(e)
	assert_false(zombie.is_empty(), "the storeroom still holds a zombie")
	if zombie.is_empty():
		return
	_force_turn(e, sera)
	e.combatants[int(_entry_for(e, sera)["index"])]["cell"] = Vector2i(6, 3)
	e.combatants[int(zombie["index"])]["cell"] = Vector2i(6, 2)
	assert_true(e.is_flat_footed(int(zombie["index"])), "the zombie has not acted yet")
	var before := e.log_lines.size()
	var result := e.attack_active(int(zombie["index"]))
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var fresh := " ".join(Array(e.log_lines.slice(before)))
	assert_true(fresh.contains("is flat-footed"), "the zombie is flat-footed, so the refusal is the tag: %s" % fresh)
	assert_false(fresh.contains("sneak attack applies"), "an undead target gets no sneak damage")
	assert_false(fresh.contains("extra 2d6"), "no extra dice are rolled against the undead")


# --------------------------------------------------------------- knockout result


func test_living_looter_can_be_knocked_out_nonlethally() -> void:
	var e := _storeroom()
	var looter := _living_enemy(e)
	var zombie := _undead_enemy(e)
	assert_false(looter.is_empty(), "the living opponent is present")
	assert_false(zombie.is_empty(), "the zombie is present")
	if looter.is_empty() or zombie.is_empty():
		return
	var living: Character = looter["char"]
	var undead: Character = zombie["char"]
	assert_false(Rules.nonlethal_immune(living), "nonlethal damage tracks on the looter")
	assert_true(Rules.nonlethal_immune(undead), "the zombie stays nonlethal-immune")

	var outcome: Dictionary = living.apply_nonlethal(living.hp + 1)
	assert_true(bool(outcome["unconscious"]), "nonlethal damage above its hit points knocks it out")
	assert_true(living.has_condition("nonlethal_unconscious"))
	assert_true(e._enemy_defeated(living), "a knockout counts as defeat")

	undead.hp = 1
	undead.take_damage(5)
	e._check_end()
	assert_true(e.finished, "the encounter ends once both opponents are down")
	assert_eq(String(e.outcome), "victory", "a knockout is a victory")


# ------------------------------------------------------------ unchanged XP ledger


func test_encounter_xp_and_award_totals_are_unchanged() -> void:
	var e := _storeroom()
	assert_eq(int(e.xp_award), 300, "the encounter still pays 300")
	var inventory: Dictionary = content.advancement_inventory()
	assert_eq(int(inventory["encounters"]), 1500, "encounter awards are unchanged")
	assert_eq(int(inventory["effects"]), 3000, "effect awards (the bell) are unchanged")
	assert_eq(int(inventory["authored"]), 4500, "authored total is unchanged")
	assert_eq(int(inventory["ordinary"]), 4350, "ordinary total is unchanged")
	assert_eq(int(inventory["qa"]), 150, "QA total is unchanged")
	assert_eq(int(inventory["start"]), 3000, "the authored start is unchanged")
	var line := ContentDiagnostics.advancement_line("ravenloft_demo", inventory)
	assert_true(line.contains("encounters=1500"), line)
	assert_true(line.contains("threshold=6000"), line)
	assert_false(Array(inventory["qa_ids"]).has("storeroom_dead"), "the storeroom stays an ordinary encounter")
