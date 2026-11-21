class_name Encounter
extends RefCounted

## Turn-based, party-oriented combat on a 5-ft square grid.
##
## Supported: initiative order, standard/move/free action accounting,
## movement with attacks of opportunity, 5-ft steps, melee and ranged attacks
## with range increments, critical threats and confirmation, damage reduction,
## combat-start flat-footedness, sneak attack when flanking/helpless/flat-footed,
## paralysis, dying/stabilization, undead "single actions only", and a bounded
## spell set.
##
## Deferred: grapple, bull rush, trip, disarm, sunder, two-weapon fighting,
## readied/delayed actions, cover/concealment, turn undead, iterative attacks.
## See docs/SUPPORTED_FEATURES.md.

signal changed

const TEAM_PARTY := 0
const TEAM_ENEMY := 1

var map: BattleMap
var rng: RandomNumberGenerator
var spells_by_id: Dictionary = {}
var encounter_id := ""
var xp_award := 0
var name := "Encounter"

var combatants: Array = []  # {char, cell, team, initiative, index}
var order: Array[int] = []
var turn_ptr := 0
var round_number := 0
var finished := false
var outcome := ""
var log_lines: Array[String] = []
var aoo_used: Dictionary = {}
# Combat-start flat-footedness (PHB p.133): every combatant is flat-footed until
# the start of their first turn. A flat-footed creature loses its Dexterity
# modifier to AC, cannot make attacks of opportunity, and can be sneak attacked
# by a rogue. Keyed by combatant index; cleared in _begin_turn for that actor.
var flat_footed: Dictionary = {}
# Loaded ranged weapons, keyed by character id (PHB p.115). Encounter-scoped: a
# crossbow is treated as unloaded when combat starts and never leaks into a save.
var loaded_weapons: Dictionary = {}
# Encounter-local ground items. Each item is in exactly one place: the ground,
# an inventory, or an equipment slot (drop PHB p.144; pick up p.141).
var ground_items: Array = []  # [{id, item, cell}]
# A Trip resolution paused for a player decision. All rolls are already made;
# resuming must never reroll or spend a second action (PHB p.159).
var pending_trip: Dictionary = {}
# Cleave's granted attack is a separate decision, not a Trip state (PHB p.92).
var pending_cleave: Dictionary = {}
# Cleave is usable once per round; keyed by combatant index and cleared when a
# new round begins. The use is consumed by making the extra attack, not by
# being offered it.
var cleave_used: Dictionary = {}
# A bounded record of the action a decision interrupted. Only the enemy turn is
# resumable today: an opportunity attack can drop a moving creature and pause its
# route. The record holds the remaining squares, never a callable closure.
var off_turn_resume: Dictionary = {}
# Power Attack is committed per actor, not per attack. It remains in force
# through the actor's other melee attacks and opportunity attacks until the
# start of that actor's next turn (PHB p. 98).
var power_attack_committed: Dictionary = {}
# Combat Expertise has a pending selection and a committed effect. The pending
# amount is only a declaration; it grants nothing until a qualifying melee
# attack action resolves. The committed amount is keyed per actor and lives on
# the character as a temporary dodge effect until the actor's next turn.
var combat_expertise_pending: Dictionary = {}
var combat_expertise_committed: Dictionary = {}
## Fighting defensively has two states (selected, active), and only the active
## one grants anything. Selection is cancelled by a legal attack commitment;
## from then on the effect lasts until the start of the character's next turn
## and cannot be cancelled. Total defense is a standard action of its own.
var fight_defensively_selected: Dictionary = {}
var turn_state: Dictionary = _fresh_turn_state()
var last_message := ""
var auto_skip_guard := 0


func _fresh_turn_state() -> Dictionary:
	return {
		"standard_used": false,
		"move_used": false,
		"five_foot_used": false,
		"moved_ft": 0,
	}


func setup(
	party: Array,
	monsters: Array,
	battle_map: BattleMap,
	rng_ref: RandomNumberGenerator,
	party_cells: Array,
	monster_cells: Array,
	spell_defs: Dictionary,
	display_name := "Encounter"
) -> void:
	map = battle_map
	rng = rng_ref
	spells_by_id = spell_defs
	name = display_name
	for i in party.size():
		add_combatant(party[i], party_cells[i] if i < party_cells.size() else Vector2i(1, 1), TEAM_PARTY)
	for i in monsters.size():
		add_combatant(
			monsters[i], monster_cells[i] if i < monster_cells.size() else Vector2i(1, 0), TEAM_ENEMY
		)


func add_combatant(ch: Character, cell: Vector2i, team: int) -> void:
	combatants.append(
		{
			"char": ch,
			"cell": cell,
			"team": team,
			"initiative": 0,
			"index": combatants.size(),
		}
	)
	# A creature that joins a running encounter has not acted yet either, so it
	# starts flat-footed until its first turn (PHB p.133). `begin()` re-seeds the
	# whole set, so setup-time additions before round 1 are covered there.
	if round_number > 0:
		flat_footed[combatants.size() - 1] = true


func begin() -> void:
	round_number = 1
	finished = false
	outcome = ""
	cleave_used.clear()
	off_turn_resume.clear()
	power_attack_committed.clear()
	_clear_combat_expertise_states()
	order.clear()
	# PHB p.133: "A character who has not yet acted during a combat is
	# flat-footed." Awareness determines surprise rounds, not this state, so an
	# all-aware encounter still starts every combatant flat-footed.
	flat_footed.clear()
	for entry in combatants:
		flat_footed[int(entry["index"])] = true
	for entry in combatants:
		var ch: Character = entry["char"]
		var roll := Dice.d20(rng)
		# Improved Initiative is a feat bonus on the Dexterity-based check.
		var init_bonus := Rules.ability_modifier(ch, "dex") + Feats.initiative_bonus(ch)
		var init_value := roll + init_bonus
		entry["initiative"] = init_value
		_log("Initiative: %s d20(%d)%+d = %d" % [ch.display_name, roll, init_bonus, init_value])
		order.append(int(entry["index"]))
	order.sort_custom(
		func(a: int, b: int) -> bool:
			var ca: Character = combatants[a]["char"]
			var cb: Character = combatants[b]["char"]
			if int(combatants[a]["initiative"]) == int(combatants[b]["initiative"]):
				return Rules.ability_modifier(ca, "dex") > Rules.ability_modifier(cb, "dex")
			return int(combatants[a]["initiative"]) > int(combatants[b]["initiative"])
	)
	_log("— Round 1 —")
	_log("All combatants are flat-footed until they start their first turn (PHB p.133).")
	turn_ptr = 0
	_activate_or_skip()


func _log(text: String) -> void:
	log_lines.append(text)
	last_message = text


func active_entry() -> Dictionary:
	if order.is_empty() or turn_ptr < 0 or turn_ptr >= order.size():
		return {}
	return combatants[order[turn_ptr]]


func active_character() -> Character:
	var entry := active_entry()
	return entry.get("char") as Character if not entry.is_empty() else null


func is_player_turn() -> bool:
	var entry := active_entry()
	return (
		not entry.is_empty()
		and int(entry["team"]) == TEAM_PARTY
		and (entry["char"] as Character).can_act()
	)


func _activate_or_skip() -> void:
	auto_skip_guard = 0
	while not finished:
		auto_skip_guard += 1
		if auto_skip_guard > 400:
			finish("error")
			_log("Turn loop guard tripped; ending encounter (reported as an error).")
			return
		var entry := active_entry()
		if entry.is_empty():
			finish("error")
			return
		var ch: Character = entry["char"]
		_begin_turn(entry)
		if finished:
			return
		if ch.can_act() and not ch.has_condition("paralyzed"):
			return
		_advance()
		if finished:
			return


func _begin_turn(entry: Dictionary) -> void:
	var ch: Character = entry["char"]
	turn_state = _fresh_turn_state()
	last_message = ""
	_log("")
	_log("— %s's turn (round %d) —" % [ch.display_name, round_number])
	if not pending_trip.is_empty() or not pending_cleave.is_empty():
		pending_trip.clear()
		pending_cleave.clear()
		_log("  An unresolved combat decision is discarded at the start of the turn.")
	var index := int(entry["index"])
	# PHB p.133: the state lasts until the combatant's first turn, so it is
	# cleared here for every combatant whose turn begins, including those that
	# are skipped because they cannot act.
	if flat_footed.erase(index):
		_log("  %s is no longer flat-footed." % ch.display_name)
	if power_attack_committed.has(index):
		power_attack_committed.erase(index)
		_log("  %s's Power Attack ends at the start of this turn." % ch.display_name)
	if combat_expertise_pending.has(index):
		combat_expertise_pending.erase(index)
		_log("  %s's pending Combat Expertise choice expires unused." % ch.display_name)
	if combat_expertise_committed.has(index) or ch.has_effect("combat_expertise"):
		combat_expertise_committed.erase(index)
		ch.remove_effect("combat_expertise")
		_log("  %s's Combat Expertise ends at the start of this turn." % ch.display_name)
	if fight_defensively_selected.has(index):
		fight_defensively_selected.erase(index)
		_log("  %s's defensive selection expires unused." % ch.display_name)
	if ch.has_effect("fighting_defensively") or ch.has_effect("total_defense"):
		# PHB p.140/143: both last until the start of the character's next turn, and
		# an active stance cannot be cancelled early.
		ch.remove_effect("fighting_defensively")
		ch.remove_effect("total_defense")
		_log("  %s's defensive stance ends at the start of this turn." % ch.display_name)
	var expired := ch.tick_effects()
	for effect_id in expired:
		_log("  %s: effect '%s' expires." % [ch.display_name, effect_id])
	if ch.has_condition("dead"):
		return
	if ch.has_condition("dying"):
		var roll := Dice.percent(rng)
		if roll <= 10:
			ch.stabilize()
			_log("  %s stabilizes (d%% = %d, 10%% chance)." % [ch.display_name, roll])
		else:
			_log("  %s remains dying (d%% = %d; needs <= 10)." % [ch.display_name, roll])
			var wound := ch.take_damage(1)
			_log("  %s loses 1 hit point from dying (HP %d)." % [ch.display_name, ch.hp])
			if bool(wound["died"]):
				_log("  %s is dead." % ch.display_name)
				_check_end()
		return
	if ch.has_condition("stable") or ch.has_condition("unconscious"):
		_log("  %s is unconscious and cannot act." % ch.display_name)
		return
	if ch.has_condition("paralyzed"):
		_log("  %s is paralyzed and cannot act." % ch.display_name)


func _advance() -> void:
	if finished or order.is_empty():
		return
	turn_ptr += 1
	if turn_ptr >= order.size():
		turn_ptr = 0
		round_number += 1
		aoo_used.clear()
		cleave_used.clear()
		_log("")
		_log("— Round %d —" % round_number)


func end_turn() -> void:
	if finished:
		return
	if has_pending_decision():
		last_message = "Resolve the pending combat decision first."
		changed.emit()
		return
	_advance()
	_check_end()
	_activate_or_skip()


## Runs enemy turns until it is a player's turn, the encounter ends, or the
## guard trips. The UI calls this after the player ends their turn.
func auto_advance() -> void:
	# A paused Trip resolution belongs to the active player; no enemy turn and no
	# turn change may run underneath it.
	if has_pending_decision():
		return
	var guard := 0
	while not finished and guard < 200:
		guard += 1
		var entry := active_entry()
		if entry.is_empty():
			return
		var ch: Character = entry["char"]
		var able := ch.can_act() and not ch.has_condition("paralyzed")
		if int(entry["team"]) == TEAM_PARTY and able:
			return
		if able:
			_run_monster_turn(entry)
		if has_pending_decision():
			# An off-turn Cleave pauses the sequence. Do not run the same turn
			# again or advance past it; the decision resumes it.
			return
		if finished:
			return
		end_turn()


func party_members() -> Array:
	var result: Array = []
	for entry in combatants:
		if int(entry["team"]) == TEAM_PARTY:
			result.append(entry["char"])
	return result


func enemies() -> Array:
	var result: Array = []
	for entry in combatants:
		if int(entry["team"]) == TEAM_ENEMY:
			result.append(entry["char"])
	return result


## PHB p.133: a character who has not yet acted during a combat is flat-footed.
## The state ends at the start of that character's first turn, which is the
## reading the rest of the project documents as "before their first regular turn".
func is_flat_footed(index: int) -> bool:
	return (not finished) and bool(flat_footed.get(index, false))


func entry_for(ch: Character) -> Dictionary:
	for entry in combatants:
		if entry["char"] == ch:
			return entry
	return {}


func cell_of(ch: Character) -> Vector2i:
	var entry := entry_for(ch)
	return entry.get("cell", Vector2i(-1, -1)) if not entry.is_empty() else Vector2i(-1, -1)


func living_entries(team: int) -> Array:
	var result: Array = []
	for entry in combatants:
		var ch: Character = entry["char"]
		if int(entry["team"]) == team and ch.can_act():
			result.append(entry)
	return result


func occupied_except(except_index: int) -> Dictionary:
	var lookup := {}
	for entry in combatants:
		if int(entry["index"]) == except_index:
			continue
		var ch: Character = entry["char"]
		if ch.has_condition("dead"):
			continue
		lookup[entry["cell"]] = true
	return lookup


## Movement. Returns {ok, message}.
func move_active_to(dest: Vector2i, five_foot := false) -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if not ch.can_act():
		return _fail("%s cannot act." % ch.display_name)
	if ch.has_condition("paralyzed"):
		return _fail("%s is paralyzed and cannot move." % ch.display_name)
	# While prone the only supported movement is crawling 5 feet as a move
	# action, which provokes from any attacker who threatens the crawl
	# (PHB p.142). Ordinary movement is refused with an explanation.
	if ch.is_prone():
		if five_foot:
			return _fail("You cannot take a 5-foot step while prone; stand up or crawl.")
		if not map.is_adjacent(entry["cell"], dest):
			return _fail("While prone you can only crawl 5 feet as a move action.")
		if bool(turn_state["five_foot_used"]):
			return _fail("You cannot crawl after taking a 5-foot step.")
		if _staggered_blocks_move(ch) != "":
			return _fail(_staggered_blocks_move(ch))
		if bool(turn_state["move_used"]) and bool(turn_state["standard_used"]):
			return _fail("No move action remaining this turn.")
		if map.is_blocked(dest) or occupied_except(int(entry["index"])).has(dest):
			return _fail("That square is blocked or occupied.")
		if bool(turn_state["move_used"]):
			turn_state["standard_used"] = true
		else:
			turn_state["move_used"] = true
		_provoke_attacks_of_opportunity(int(entry["index"]), entry["cell"])
		if finished:
			_changed()
			return {"ok": true, "interrupted": true, "message": "%s is interrupted while crawling." % ch.display_name}
		if not ch.can_act() or ch.has_condition("paralyzed"):
			_changed()
			return {
				"ok": false,
				"interrupted": true,
				"message": "%s cannot finish crawling." % ch.display_name,
			}
		entry["cell"] = dest
		turn_state["moved_ft"] = int(turn_state["moved_ft"]) + BattleMap.CELL_FT
		_log("%s crawls 5 feet while prone." % ch.display_name)
		_after_action(ch)
		_check_end()
		changed.emit()
		return {"ok": true, "message": "Crawled 5 ft."}
	if five_foot:
		if bool(turn_state["five_foot_used"]):
			return _fail("You have already taken a 5-foot step this turn.")
		if bool(turn_state["move_used"]) or int(turn_state["moved_ft"]) > 0:
			return _fail("A 5-foot step is only allowed if you did not move this turn.")
		if not map.is_adjacent(entry["cell"], dest):
			return _fail("A 5-foot step must be to an adjacent square.")
		if map.is_blocked(dest) or occupied_except(int(entry["index"])).has(dest):
			return _fail("That square is blocked or occupied.")
		if not map.has_line_of_sight(entry["cell"], dest):
			return _fail("That square is not visible.")
		var step_from: Vector2i = entry["cell"]
		entry["cell"] = dest
		_check_turning_approach(ch, step_from, dest)
		turn_state["five_foot_used"] = true
		turn_state["moved_ft"] = BattleMap.CELL_FT
		_log("%s takes a 5-foot step." % ch.display_name)
		changed.emit()
		return {"ok": true, "message": "5-foot step taken."}

	if bool(turn_state["five_foot_used"]):
		return _fail("You cannot move after taking a 5-foot step.")
	if _staggered_blocks_move(ch) != "":
		return _fail(_staggered_blocks_move(ch))
	if bool(turn_state["move_used"]) and bool(turn_state["standard_used"]):
		return _fail("No move action remaining this turn.")

	var occupied := occupied_except(int(entry["index"]))
	if map.is_blocked(dest) or occupied.has(dest):
		return _fail("That square is blocked or occupied.")
	var path := map.find_path(entry["cell"], dest, occupied)
	if path.is_empty():
		return _fail("No path to that square.")
	var cost := path.size() * BattleMap.CELL_FT
	var budget := ch.speed_ft
	if cost > budget:
		return _fail(
			"That is %d ft. away; %s can move %d ft. with one move action."
			% [cost, ch.display_name, budget]
		)
	# A character may use a second move action by spending the standard action
	# (a double move); the action is spent even if an AoO interrupts the move.
	var using_standard := bool(turn_state["move_used"]) and not bool(turn_state["standard_used"])
	if using_standard:
		turn_state["standard_used"] = true
	else:
		turn_state["move_used"] = true
	# Provoke attacks of opportunity as the mover leaves threatened squares.
	for i in path.size():
		var step: Vector2i = path[i]
		_provoke_attacks_of_opportunity(int(entry["index"]), entry["cell"])
		if has_pending_decision():
			off_turn_resume = {
				"kind": "monster_move",
				"entry_index": int(entry["index"]),
				"remaining": path.slice(i),
				"target_index": -1,
				"attack_after": false,
			}
			changed.emit()
			return {
				"ok": true,
				"pending": true,
				"message": "The move pauses for a Cleave decision.",
			}
		if finished:
			changed.emit()
			return {"ok": true, "message": "The encounter ended during the move."}
		if not ch.can_act() or ch.has_condition("paralyzed"):
			changed.emit()
			return {"ok": true, "message": "%s cannot continue moving." % ch.display_name}
		var step_from: Vector2i = entry["cell"]
		entry["cell"] = step
		_check_turning_approach(ch, step_from, step)
	turn_state["moved_ft"] = int(turn_state["moved_ft"]) + cost
	_log("%s moves %d ft. (speed %d ft.)." % [ch.display_name, cost, budget])
	_after_action(ch)
	_check_end()
	changed.emit()
	return {"ok": true, "message": "Moved %d ft." % cost}


## Every state-changing action runs through this while any resumable decision
## (Trip, Improved Trip, Cleave) is waiting. Disabled buttons are presentation
## only; this is the rules boundary. Encounter termination clears the decision
## explicitly in `finish`, and a changed/dead actor voids it in its resolver.
func _pending_guard() -> Dictionary:
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	return {}


func _fail(message: String) -> Dictionary:
	last_message = message
	return {"ok": false, "message": message}


func _primary_weapon(ch: Character) -> Dictionary:
	if ch.is_monster:
		if not ch.attacks.is_empty():
			return ch.attacks[0]
		return {
			"name": "slam",
			"damage": "1d3",
			"crit_range": 20,
			"crit_mult": 2,
			"damage_type": "bludgeoning",
		}
	var weapon: Dictionary = ch.equipment.get("weapon", {})
	if weapon.is_empty():
		return _unarmed_strike(ch)
	return weapon


## What melee attack this combatant could attempt right now (PHB p. 139, "Unarmed
## Attacks"): a readied weapon with a melee mode, a monster's natural attack, or the
## unarmed strike every character can attempt. This is an attack option, not a claim
## that the combatant is armed.
func available_melee_attack(ch: Character) -> Dictionary:
	if ch == null:
		return {}
	if ch.is_monster:
		for attack in ch.attacks:
			var row: Dictionary = attack
			if int(row.get("range_increment", 0)) > 0 or bool(row.get("ranged", false)):
				continue
			return row
		return {}
	var weapon: Dictionary = ch.equipment.get("weapon", {})
	if weapon.is_empty():
		return _unarmed_strike(ch)
	if Rules.weapon_attack_modes(weapon).has("melee"):
		return weapon
	return {}


## Whether the combatant is armed for threat purposes (PHB pp. 137, 139). "If you're
## unarmed, you don't normally threaten any squares and thus can't make attacks of
## opportunity." Armed means a readied weapon with a melee mode, a natural weapon, or
## an "armed" unarmed attack: "A monk, a character with the Improved Unarmed Strike
## feat, a spellcaster delivering a touch attack spell, and a creature with claws,
## fangs, and similar natural physical weapons all count as being armed." Empty hands
## alone therefore grant no threat, no flanking and no reaction - the ability to
## attempt a nonlethal unarmed strike is not the same as being armed. A ranged-only
## readied weapon is not armed either, and this build does not offer the printed
## unarmed strike a bow-holding character could still make. No monk class exists in
## this content, so the monk clause is recorded but unreachable.
func threat_capability(ch: Character) -> Dictionary:
	if ch == null:
		return {}
	if ch.is_monster:
		for attack in ch.attacks:
			var row: Dictionary = attack
			if int(row.get("range_increment", 0)) > 0 or bool(row.get("ranged", false)):
				continue
			return row
		return {}
	var weapon: Dictionary = ch.equipment.get("weapon", {})
	if not weapon.is_empty():
		if Rules.weapon_attack_modes(weapon).has("melee"):
			return weapon
		return {}
	if Feats.has_feat(ch, "improved_unarmed_strike"):
		return _unarmed_strike(ch)
	return {}


## Whether `ch` threatens `to_cell` from `from_cell` with a legal melee attack.
func _threatens_cell(ch: Character, from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if threat_capability(ch).is_empty():
		return false
	return map.distance_ft(from_cell, to_cell) <= maxi(ch.reach_ft, BattleMap.CELL_FT)


## PHB p.139: 1d3 for a Medium character, 1d2 Small, 1d4 Large, plus Strength, and
## "All damage from unarmed strikes is nonlethal damage." Unarmed strikes also count
## as light weapons for two-weapon penalties, which is why `light_weapon` is set.
func _unarmed_strike(ch: Character = null) -> Dictionary:
	var damage := "1d3"
	var size := "medium"
	if ch != null:
		size = String(ch.size_category).to_lower()
		size = "medium" if size == "" else size
	if size == "small":
		damage = "1d2"
	elif size == "large":
		damage = "1d4"
	return {
		"id": "unarmed_strike",
		"name": "unarmed strike",
		"damage": damage,
		"crit_range": 20,
		"crit_mult": 2,
		"damage_type": "bludgeoning",
		"nonlethal": true,
		"unarmed": true,
		"light_weapon": true,
	}


## Player-issued attack against one target (single attack, standard action).
## attack_mode is optional only for single-mode weapons; a multi-mode weapon
## must choose explicitly through the combat screen.
func attack_active(target_index: int, attack_mode := "", unarmed_damage := "") -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot attack." % ch.display_name)
	# PHB p.143: total defense allows no attacks at all. The standard action is
	# also spent, so name the stance instead of only the action economy.
	if ch.has_effect("total_defense"):
		return _fail("%s is using total defense and cannot attack (PHB p.143)." % ch.display_name)
	if bool(turn_state["standard_used"]):
		return _fail("Your standard action is already spent this turn.")
	var staggered_attack := _staggered_blocks_standard(ch)
	if staggered_attack != "":
		return _fail(staggered_attack)
	if target_index < 0 or target_index >= combatants.size():
		return _fail("Invalid target.")
	var target_entry: Dictionary = combatants[target_index]
	var target: Character = target_entry["char"]
	if int(target_entry["team"]) == int(entry["team"]):
		return _fail("You cannot attack an ally.")
	if target.has_condition("dead"):
		return _fail("%s is already dead." % target.display_name)
	var weapon := _primary_weapon(ch)
	var unarmed_penalty := 0
	# PHB p.97: Improved Unarmed Strike lets the character "deal lethal or nonlethal
	# damage, at your option". Without the feat an unarmed strike deals only
	# nonlethal damage, and choosing lethal damage takes the printed -4 (PHB p.147,
	# "Lethal Damage with a Weapon that Deals Nonlethal Damage"). The feat never
	# changes the damage die; only the monk's class feature does, and no monk exists
	# here.
	if bool(weapon.get("unarmed", false)) and String(unarmed_damage) == "lethal":
		weapon = weapon.duplicate(true)
		weapon["nonlethal"] = false
		if not Feats.has_feat(ch, "improved_unarmed_strike"):
			unarmed_penalty = -4
			_log(
				"%s strikes to deal lethal damage with an unarmed strike: -4 on the attack roll (PHB p.147)."
				% ch.display_name
			)
		else:
			_log(
				"%s deals lethal damage with an unarmed strike (Improved Unarmed Strike, PHB p.97)."
				% ch.display_name
			)
	var distance := map.distance_ft(entry["cell"], target_entry["cell"])
	var mode := Rules.normalize_attack_mode(weapon, attack_mode)
	if mode == "":
		return _fail("%s cannot attack in that mode." % String(weapon.get("name", "That weapon")))
	var ranged := Rules.is_ranged_attack(weapon, mode)
	if String(weapon.get("reload", "")) != "" and not is_weapon_loaded(ch):
		return _fail(
			"%s is not loaded. Loading it takes a move action."
			% String(weapon.get("name", "That weapon"))
		)
	if ranged:
		var max_range := int(weapon.get("range_increment", 80)) * 10
		if distance > max_range:
			return _fail("%s is out of range (%d ft.; max %d ft.)." % [target.display_name, distance, max_range])
		if not map.has_line_of_sight(entry["cell"], target_entry["cell"]):
			return _fail("You have no line of sight to %s." % target.display_name)
		var threats := _threatening_enemies(entry)
		if not threats.is_empty():
			# PHB p. 135: making a ranged attack provokes from opponents that
			# threaten you. This is separate from the p. 140 into-melee penalty
			# below, which depends on the target's neighbours, not the attacker's.
			_log(
				"%s makes a ranged attack while threatened and provokes attacks of opportunity."
				% ch.display_name
			)
			for foe in threats:
				if finished or not ch.can_act() or ch.has_condition("paralyzed"):
					break
				_provoke_single_opportunity(foe["char"], ch)
	else:
		var reach := maxi(ch.reach_ft, BattleMap.CELL_FT)
		if distance > reach:
			return _fail(
				"%s is %d ft. away; melee reach is %d ft. Move closer first."
				% [target.display_name, distance, reach]
			)
		if bool(weapon.get("unarmed", false)) and not Feats.has_feat(
			ch, "improved_unarmed_strike"
		):
			# PHB p.139: "Attacking unarmed provokes an attack of opportunity from the
			# character you attack, provided she is armed... nor does it provoke an
			# attack of opportunity from an unarmed foe." Only the target reacts, and
			# Improved Unarmed Strike makes the attack armed for both offense and
			# defense.
			if not threat_capability(target).is_empty():
				_log(
					"%s attacks unarmed and provokes an attack of opportunity from %s."
					% [ch.display_name, target.display_name]
				)
				_provoke_single_opportunity(target, ch)
			else:
				_log(
					"%s attacks unarmed; %s is unarmed and cannot answer."
					% [ch.display_name, target.display_name]
				)
	if finished or not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s loses the attack to an opportunity attack." % ch.display_name)
	if bool(turn_state["standard_used"]):
		return _fail("Your standard action was lost to the opportunity attack.")
	if ranged and String(weapon.get("reload", "")) != "":
		# Firing spends the shot whether it hits or misses.
		loaded_weapons.erase(String(ch.id))
	if fight_defensively_selected.has(int(entry["index"])):
		# The attack is legal and about to commit, so this is the only point at
		# which a selection becomes an active stance. A refused or cancelled
		# attack never reaches here, so it grants no bonus.
		fight_defensively_selected.erase(int(entry["index"]))
		_activate_fighting_defensively(ch)
	if not ranged:
		_commit_pending_combat_expertise(int(entry["index"]))
	else:
		_discard_pending_combat_expertise(int(entry["index"]), "ranged attack")
	return _resolve_attack(
		int(entry["index"]),
		target_index,
		weapon,
		{"attack_mode": mode, "bonus": unarmed_penalty, "unarmed_lethal": unarmed_penalty != 0},
	)


## PHB p.142: drawing a weapon so that it can be used requires a move action.
## This build charges the whole move action; the printed free draw combined with
## a regular move (base attack bonus +1) is not modelled because it needs a
## combined move-and-draw action that does not exist here. Sheathing is not
## modelled, and a two-handed weapon cannot be readied while a shield is strapped
## on (nothing removes a shield yet).
## PHB p.138: "You can take a move action in place of a standard action." The
## draw, sheathe and load entries below all spend one move-equivalent slot: the
## move action if it is still free, otherwise the standard action. Returns the
## slot's name, or "" when neither is available.
func _spend_move_equivalent() -> String:
	if not bool(turn_state.get("move_used", false)):
		turn_state["move_used"] = true
		return "move action"
	if not bool(turn_state.get("standard_used", false)):
		turn_state["standard_used"] = true
		return "standard action"
	return ""


func _slot_label(slot: String, page: String) -> String:
	if slot == "move action":
		return "move action; PHB p.%s" % page
	return "standard action used as a move; PHB p.138, p.%s" % page


func draw_weapon(item_id: String) -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if ch.is_monster:
		return _fail("%s does not use equipment." % ch.display_name)
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot ready a weapon." % ch.display_name)
	var item := ch.carried_weapon(item_id)
	if item.is_empty():
		return _fail("%s is not carrying that weapon." % ch.display_name)
	var equipped: Dictionary = ch.equipment.get("weapon", {})
	if String(equipped.get("id", "")) == item_id:
		return {
			"ok": true,
			"spent_move": false,
			"message": "%s is already readied." % String(item.get("name", item_id)),
		}
	if not equipped.is_empty():
		return _fail(
			(
				"%s still has %s in hand; sheathing it is a separate move action "
				+ "(PHB p.142)."
			)
			% [ch.display_name, String(equipped.get("name", "a weapon"))]
		)
	var shield: Dictionary = ch.equipment.get("shield", {})
	if int(item.get("hands", 1)) >= 2 and not shield.is_empty():
		return _fail(
			(
				"%s needs two hands, and %s has a shield strapped on; removing a shield is "
				+ "not modelled."
			)
			% [String(item.get("name", item_id)), ch.display_name]
		)
	var slot := _spend_move_equivalent()
	if slot == "":
		return _fail("No move or standard action remains this turn, so you cannot draw a weapon.")
	turn_state["moved_ft"] = ch.speed_ft
	ch.equipment["weapon"] = item.duplicate(true)
	_log(
		"%s draws %s (%s)."
		% [
			ch.display_name,
			String(item.get("name", item_id)),
			_slot_label(slot, "142"),
		]
	)
	changed.emit()
	return {
		"ok": true,
		"spent_move": true,
		"weapon": item,
		"message": "%s readies %s." % [ch.display_name, String(item.get("name", item_id))],
	}


## PHB p.142 groups "Draw or Sheathe a Weapon" as one move action each. This build
## keeps them separate: putting the weapon away costs one move action, and readying
## the next one costs another, so a swap is never cheaper than the printed rules.
## The weapon stays carried, because sheathing is not dropping it.
func sheathe_weapon() -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if ch.is_monster:
		return _fail("%s does not use equipment." % ch.display_name)
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot put a weapon away." % ch.display_name)
	var weapon: Dictionary = ch.equipment.get("weapon", {})
	if weapon.is_empty():
		return _fail("%s has no weapon readied." % ch.display_name)
	var slot := _spend_move_equivalent()
	if slot == "":
		return _fail("No move or standard action remains this turn, so you cannot sheathe a weapon.")
	turn_state["moved_ft"] = ch.speed_ft
	var weapon_id := String(weapon.get("id", ""))
	if ch.inventory_count(weapon_id) <= 0:
		ch.add_to_inventory(weapon)
	ch.equipment["weapon"] = {}
	_log(
		"%s sheathes %s (%s)."
		% [
			ch.display_name,
			String(weapon.get("name", weapon_id)),
			_slot_label(slot, "142"),
		]
	)
	changed.emit()
	return {
		"ok": true,
		"spent_move": true,
		"message": "%s sheathes %s." % [ch.display_name, String(weapon.get("name", weapon_id))],
	}


## PHB p.142: "Strapping a shield to your arm to gain its shield bonus to your AC,
## or unstrapping and dropping a shield so you can use your shield hand for another
## purpose, requires a move action." Readying takes a carried shield; loosing is not
## storing it in a pack - the shield is dropped on the character's square and can be
## recovered with the ordinary Pick up action. A two-handed weapon needs both hands,
## so it and a strapped shield cannot coexist.
func _carried_shield(ch: Character, item_id: String) -> Dictionary:
	for row in ch.carried_shields():
		if String(row["id"]) == item_id and not bool(row.get("equipped", false)):
			return row["item"]
	return {}


func ready_shield(item_id: String) -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if ch.is_monster:
		return _fail("%s does not use equipment." % ch.display_name)
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot strap on a shield." % ch.display_name)
	var readied: Dictionary = ch.equipment.get("shield", {})
	if not readied.is_empty() and String(readied.get("id", "")) == item_id:
		return {
			"ok": true,
			"spent_move": false,
			"message": "%s is already strapped on." % String(readied.get("name", item_id)),
		}
	if not readied.is_empty():
		return _fail(
			("%s already has %s strapped on; loosing it is a separate move action (PHB p.142).")
			% [ch.display_name, String(readied.get("name", "a shield"))]
		)
	var item := _carried_shield(ch, item_id)
	if item.is_empty():
		return _fail("%s is not carrying that shield." % ch.display_name)
	var weapon: Dictionary = ch.equipment.get("weapon", {})
	if int(weapon.get("hands", 1)) >= 2:
		return _fail(
			"%s needs two hands, so a shield cannot be strapped on." % String(weapon.get("name", "The readied weapon"))
		)
	var slot := _spend_move_equivalent()
	if slot == "":
		return _fail("No move or standard action remains this turn, so you cannot strap on a shield.")
	turn_state["moved_ft"] = ch.speed_ft
	ch.remove_from_inventory(item_id)
	ch.equipment["shield"] = item.duplicate(true)
	_log(
		"%s straps %s to an arm (%s)."
		% [ch.display_name, String(item.get("name", item_id)), _slot_label(slot, "142")]
	)
	changed.emit()
	return {
		"ok": true,
		"spent_move": true,
		"shield": item,
		"message": "%s straps on %s." % [ch.display_name, String(item.get("name", item_id))],
	}


func loose_shield() -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if ch.is_monster:
		return _fail("%s does not use equipment." % ch.display_name)
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot loose a shield." % ch.display_name)
	var shield: Dictionary = ch.equipment.get("shield", {})
	if shield.is_empty():
		return _fail("%s has no shield strapped on." % ch.display_name)
	var slot := _spend_move_equivalent()
	if slot == "":
		return _fail("No move or standard action remains this turn, so you cannot loose a shield.")
	turn_state["moved_ft"] = ch.speed_ft
	ch.equipment["shield"] = {}
	ground_items.append(
		{
			"id": String(shield.get("id", "")),
			"item": shield.duplicate(true),
			"cell": entry["cell"],
		}
	)
	_log(
		"%s unstraps and drops %s (%s)."
		% [ch.display_name, String(shield.get("name", "the shield")), _slot_label(slot, "142")]
	)
	changed.emit()
	return {
		"ok": true,
		"spent_move": true,
		"message": "%s unstraps and drops %s." % [ch.display_name, String(shield.get("name", "the shield"))],
	}


## Whether the character's readied weapon is ready to fire. Weapons without a
## printed reload step are always ready.
func is_weapon_loaded(ch: Character) -> bool:
	var weapon := _primary_weapon(ch)
	if String(weapon.get("reload", "")) == "":
		return true
	return String(loaded_weapons.get(String(ch.id), "")) == String(weapon.get("id", ""))


## PHB p.115: loading a light crossbow is a move action that provokes attacks of
## opportunity. Bolts are drawn as a free action (p.142), so no ammunition is
## tracked. The loaded state is applied only if the character survives and can
## still act, but the move action is spent either way.
func load_weapon() -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot load a weapon." % ch.display_name)
	var weapon := _primary_weapon(ch)
	var weapon_name := String(weapon.get("name", "that weapon"))
	if String(weapon.get("reload", "")) == "":
		return _fail("%s does not need loading." % weapon_name)
	if is_weapon_loaded(ch):
		return {"ok": true, "spent_move": false, "message": "%s is already loaded." % weapon_name}
	var slot := _spend_move_equivalent()
	if slot == "":
		return _fail("No move or standard action remains this turn, so you cannot load.")
	turn_state["moved_ft"] = ch.speed_ft
	_log(
		"%s loads %s (%s; loading provokes attacks of opportunity; PHB p.115)."
		% [ch.display_name, weapon_name, _slot_label(slot, "115")]
	)
	var threats := _threatening_enemies(entry)
	if not threats.is_empty():
		_log("%s loading a crossbow provokes attacks of opportunity." % ch.display_name)
		for foe in threats:
			if finished or not ch.can_act() or ch.has_condition("paralyzed"):
				break
			_provoke_single_opportunity(foe["char"], ch)
	if finished or not ch.can_act() or ch.has_condition("paralyzed"):
		changed.emit()
		return _fail("%s cannot finish loading the weapon." % ch.display_name)
	loaded_weapons[String(ch.id)] = String(weapon.get("id", ""))
	changed.emit()
	return {
		"ok": true,
		"spent_move": true,
		"weapon": weapon,
		"message": "%s loads %s." % [ch.display_name, weapon_name],
	}


## Standing up from prone is a move action that provokes attacks of opportunity
## (PHB pp. 143, 159). The character is still prone while the reaction
## resolves, so those attacks use the prone AC; prone is cleared only if the
## character survives and can still complete the action.
func stand_up_active() -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot stand up." % ch.display_name)
	if not ch.is_prone():
		return _fail("%s is not prone." % ch.display_name)
	if bool(turn_state.get("move_used", false)):
		return _fail("Your move action is already spent this turn.")
	# The action is declared before the reaction: an interrupted character has
	# spent the move action and stays prone rather than getting a free stand-up.
	turn_state["move_used"] = true
	_log("%s starts to stand up (move action)." % ch.display_name)
	for foe in _threatening_enemies(entry):
		if finished or not ch.can_act() or ch.has_condition("paralyzed"):
			break
		_provoke_single_opportunity(foe["char"], ch)
	if finished:
		_changed()
		return {
			"ok": true,
			"interrupted": true,
			"message": "%s was interrupted while standing up." % ch.display_name,
		}
	if not ch.can_act() or ch.has_condition("paralyzed"):
		_changed()
		return {
			"ok": false,
			"interrupted": true,
			"message":
			"%s cannot finish standing up and remains prone." % ch.display_name,
		}
	ch.set_prone(false)
	_log("  %s is back on their feet." % ch.display_name)
	_changed()
	return {
		"ok": true,
		"interrupted": false,
		"message": "%s stands up." % ch.display_name,
	}


## PHB p.147: a staggered creature "can only take a standard action or a move
## action in each round" - never both. These two guards are the whole restriction;
## the conditions themselves stay derived from the nonlethal total.
func _staggered_blocks_standard(ch: Character) -> String:
	if ch.has_condition("staggered") and bool(turn_state.get("move_used", false)):
		return "You are staggered and have already used your move action (PHB p.147)."
	return ""


func _staggered_blocks_move(ch: Character) -> String:
	if ch.has_condition("staggered") and bool(turn_state.get("standard_used", false)):
		return "You are staggered and have already used your standard action (PHB p.147)."
	return ""


## Trip (PHB pp. 158-159). A standard-action melee touch attack followed by an
## opposed Strength check; size category gates eligibility and modifies both
## checks. `opts`: use_weapon, release_weapon, counter_trip (the defender's
## decision; NPC defenders counter-trip by default).
func trip_active(target_index: int, opts: Dictionary = {}) -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot trip." % ch.display_name)
	if bool(turn_state["standard_used"]):
		return _fail("Your standard action is already spent this turn.")
	var staggered_trip := _staggered_blocks_standard(ch)
	if staggered_trip != "":
		return _fail(staggered_trip)
	if target_index < 0 or target_index >= combatants.size():
		return _fail("Invalid target.")
	var target_entry: Dictionary = combatants[target_index]
	var target: Character = target_entry["char"]
	if int(target_entry["team"]) == int(entry["team"]):
		return _fail("You cannot trip an ally.")
	if target.has_condition("dead"):
		return _fail("%s is already dead." % target.display_name)
	var reach := maxi(ch.reach_ft, BattleMap.CELL_FT)
	var distance := map.distance_ft(entry["cell"], target_entry["cell"])
	if distance > reach:
		return _fail(
			"%s is %d ft. away; melee reach is %d ft. Move closer first."
			% [target.display_name, distance, reach]
		)
	var attacker_steps := Rules.size_category_steps(ch.size_category)
	var defender_steps := Rules.size_category_steps(target.size_category)
	if defender_steps > attacker_steps + 1:
		return _fail(
			"%s is too large to trip; you can trip a creature at most one size category larger."
			% target.display_name
		)
	if target.trip_immune:
		return _fail("%s cannot be tripped." % target.display_name)
	var use_weapon := bool(opts.get("use_weapon", false))
	var weapon := _primary_weapon(ch)
	if use_weapon and not bool(weapon.get("trip", false)):
		return _fail("%s is not a trip weapon (PHB p. 159)." % String(weapon.get("name", "That weapon")))
	# Declared before any reaction: an interrupted attempt still spends the
	# standard action, and the touch attack itself is the attack action.
	turn_state["standard_used"] = true
	var index := int(entry["index"])
	var mode := "melee"
	var power_attack := _committed_power_attack(index, weapon, mode)
	var combat_expertise := _committed_combat_expertise(index, weapon, mode)
	_commit_pending_combat_expertise(index)
	combat_expertise = _committed_combat_expertise(index, weapon, mode)
	if use_weapon:
		_log("%s trips with %s." % [ch.display_name, String(weapon.get("name", "a weapon"))])
	else:
		_log("%s makes an unarmed trip attempt against %s." % [ch.display_name, target.display_name])
		# PHB p.158: an unarmed trip provokes an opportunity attack from the
		# target as normal for unarmed attacks, before the touch attack.
		# Improved Trip removes that provocation (PHB p.96).
		if target.can_act() and not Feats.has_active(ch, "improved_trip"):
			_provoke_single_opportunity(target, ch)
		if finished:
			_changed()
			return {
				"ok": true,
				"interrupted": true,
				"message": "%s was interrupted before the trip attack." % ch.display_name,
			}
		if not ch.can_act() or ch.has_condition("paralyzed"):
			_after_action(ch)
			_changed()
			return {
				"ok": false,
				"interrupted": true,
				"message": "%s loses the trip attempt to an opportunity attack." % ch.display_name,
			}
	var touch := Rules.attack(
		rng,
		ch,
		target,
		weapon,
		distance,
		{
			"touch": true,
			"attack_mode": mode,
			"label": "trip touch attack",
			"power_attack": power_attack,
			"combat_expertise": combat_expertise,
			"flat_footed": is_flat_footed(int(target_entry["index"])),
		}
	)
	_log("  " + Rules.format_attack(touch))
	if not bool(touch["hit"]):
		# A missed touch attack ends the attempt: no opposed check and no
		# counter-trip (PHB p.158, "If your attack succeeds...").
		_log("  The touch attack misses; the trip attempt ends.")
		_after_action(ch)
		_check_end()
		changed.emit()
		return {
			"ok": true,
			"hit": false,
			"trip_success": false,
			"countered": false,
			"weapon_dropped": false,
			"touch": touch,
			"message": "Trip attempt missed.",
		}
	# PHB p.158: each combatant gets +-4 per size category from Medium, and the
	# defender adds +4 when more stable than a normal humanoid. Improved Trip's
	# +4 is on the attacker's own Strength check only (PHB p.96); it is not a
	# size bonus, so it must not leak into the defender's counter-trip check.
	var size_attacker_bonus := 4 * attacker_steps
	var attacker_bonus := size_attacker_bonus + Feats.improved_trip_check_bonus(ch)
	var defender_bonus := 4 * defender_steps + target.stability_bonus
	var opposed := Rules.opposed_ability_check(
		rng,
		ch,
		["str"],
		target,
		["str", "dex"],
		{
			"attacker_bonus": attacker_bonus,
			"defender_bonus": defender_bonus,
			"label": "trip",
		}
	)
	_log(
		"  Trip check: %s %s d20(%d)%+d = %d vs %s %s d20(%d)%+d = %d"
		% [
			ch.display_name,
			String(opposed["attacker_ability"]),
			int(opposed["attacker_roll"]),
			int(opposed["attacker_modifier"]),
			int(opposed["attacker_total"]),
			target.display_name,
			String(opposed["defender_ability"]),
			int(opposed["defender_roll"]),
			int(opposed["defender_modifier"]),
			int(opposed["defender_total"]),
		]
	)
	var tripped := String(opposed["winner"]) == "attacker"
	var countered := false
	var weapon_dropped := false
	var counter: Dictionary = {}
	if tripped:
		target.set_prone(true)
		_log("  %s is tripped and falls prone." % target.display_name)
		# PHB p.96: a successful trip grants an immediate melee attack against
		# that opponent, as if the attack had not been used for the trip. The
		# attack is the player's to take or decline, so pause instead of rolling
		# it automatically.
		if Feats.improved_trip_follow_up(ch):
			pending_trip = {
				"type": "improved_trip_attack",
				"actor_index": index,
				"target_index": target_index,
			}
			changed.emit()
			return {
				"ok": true,
				"hit": true,
				"trip_success": true,
				"countered": false,
				"weapon_dropped": false,
				"pending": "improved_trip_attack",
				"touch": touch,
				"opposed": opposed,
				"counter": {},
				"message":
				"%s is tripped. Improved Trip grants an immediate attack." % target.display_name,
			}
	elif bool(opts.get("counter_trip", true)) and target.can_act():
		_log("  %s reacts and tries to trip %s back." % [target.display_name, ch.display_name])
		counter = Rules.opposed_ability_check(
			rng,
			target,
			["str"],
			ch,
			["str", "dex"],
			{
				"attacker_bonus": defender_bonus,
				"defender_bonus": size_attacker_bonus,
				"label": "counter-trip",
			}
		)
		_log(
			"  Counter-trip: %s %s d20(%d)%+d = %d vs %s %s d20(%d)%+d = %d"
			% [
				target.display_name,
				String(counter["attacker_ability"]),
				int(counter["attacker_roll"]),
				int(counter["attacker_modifier"]),
				int(counter["attacker_total"]),
				ch.display_name,
				String(counter["defender_ability"]),
				int(counter["defender_roll"]),
				int(counter["defender_modifier"]),
				int(counter["defender_total"]),
			]
		)
		if String(counter["winner"]) == "attacker":
			countered = true
			# PHB p.159: a tripped weapon user may drop the weapon to avoid
			# being tripped. That choice belongs to the acting player, so pause
			# with every roll already final instead of choosing for them. A
			# caller may pre-decide (AI, tests) by supplying release_weapon.
			if use_weapon and not opts.has("release_weapon"):
				pending_trip = {
					"type": "weapon_release",
					"actor_index": index,
					"target_index": target_index,
					"weapon": weapon.duplicate(true),
					"touch": touch,
					"opposed": opposed,
					"counter": counter,
				}
				changed.emit()
				return {
					"ok": true,
					"hit": true,
					"trip_success": false,
					"countered": true,
					"weapon_dropped": false,
					"pending": "weapon_release",
					"touch": touch,
					"opposed": opposed,
					"counter": counter,
					"message": "%s may drop the weapon to avoid being tripped." % ch.display_name,
				}
			if use_weapon and bool(opts.get("release_weapon", false)):
				weapon_dropped = _drop_weapon(ch)
			else:
				ch.set_prone(true)
				_log("  %s is tripped and falls prone." % ch.display_name)
		else:
			_log("  The counter-trip fails.")
	_after_action(ch)
	_check_end()
	changed.emit()
	var message := "Trip attempt resolves."
	if tripped:
		message = "%s is tripped." % target.display_name
	elif countered:
		message = "%s is tripped by the counter-trip." % ch.display_name
	elif not counter.is_empty():
		message = "The counter-trip fails."
	return {
		"ok": true,
		"hit": true,
		"trip_success": tripped,
		"countered": countered,
		"weapon_dropped": weapon_dropped,
		"touch": touch,
		"opposed": opposed,
		"counter": counter,
		"message": message,
	}


## Drops the equipped weapon into the inventory (PHB p.159). Returns whether a
## weapon was actually dropped.
func _drop_weapon(ch: Character) -> bool:
	var weapon: Dictionary = ch.equipment.get("weapon", {})
	if weapon.is_empty():
		return false
	var entry := entry_for(ch)
	ch.unequip("weapon")
	# Dropping puts the item on the ground, not in the backpack (PHB p.144).
	ground_items.append(
		{
			"id": String(weapon.get("id", "weapon")),
			"item": weapon.duplicate(true),
			"cell": entry.get("cell", Vector2i.ZERO),
		}
	)
	_log(
		"  %s drops %s; it lies on the ground at their feet."
		% [ch.display_name, String(weapon.get("name", "the weapon"))]
	)
	return true


## Resumes the paused Trip resolution. All rolls were made before the pause, so
## this only applies the player's choice and never rerolls or respends.
func resolve_trip_decision(release_weapon: bool) -> Dictionary:
	if pending_trip.is_empty():
		return _fail("There is no pending Trip decision.")
	if String(pending_trip.get("type", "weapon_release")) != "weapon_release":
		return _fail("That pending decision is not a weapon-release choice.")
	var state := pending_trip
	pending_trip = {}
	var actor_index := int(state.get("actor_index", -1))
	if actor_index < 0 or actor_index >= combatants.size():
		return _fail("The pending Trip actor is no longer in this encounter.")
	var ch: Character = combatants[actor_index]["char"]
	var current := active_entry()
	if not current.is_empty() and int(current.get("index", -1)) != actor_index:
		_log("  The turn moved to another combatant; the Trip decision is void.")
		changed.emit()
		return _fail("That Trip decision no longer belongs to the active combatant.")
	if ch.has_condition("dead") or not ch.can_act():
		_log("  %s can no longer act; the Trip decision is void." % ch.display_name)
		changed.emit()
		return _fail("%s can no longer act; the Trip decision is void." % ch.display_name)
	var weapon_dropped := false
	if release_weapon:
		weapon_dropped = _drop_weapon(ch)
		if not weapon_dropped:
			_log("  There is no weapon to drop; %s is tripped." % ch.display_name)
			ch.set_prone(true)
		else:
			_log("  %s keeps their feet by dropping the weapon." % ch.display_name)
	else:
		ch.set_prone(true)
		_log("  %s keeps the weapon and is tripped." % ch.display_name)
	_after_action(ch)
	_check_end()
	changed.emit()
	return {
		"ok": true,
		"weapon_dropped": weapon_dropped,
		"prone": ch.is_prone(),
		"message":
		(
			"%s drops the weapon and stays standing." % ch.display_name
			if weapon_dropped
			else "%s is tripped." % ch.display_name
		),
	}


## Resumes the paused Improved Trip follow-up (PHB p.96). The trip itself is
## already resolved and its action spent; this only resolves or declines the
## granted melee attack. It never rerolls the trip and never grants a second
## follow-up, because the extra attack is an ordinary attack, not another trip.
func resolve_improved_trip_attack(take_attack: bool, choice := "") -> Dictionary:
	if pending_trip.is_empty():
		return _fail("There is no pending Trip decision.")
	if String(pending_trip.get("type", "")) != "improved_trip_attack":
		return _fail("That pending decision is not an Improved Trip follow-up.")
	# PHB p.96 grants "a melee attack", not necessarily the method used for the
	# trip. Choose among attacks the character can already make with what is in
	# hand; no draw, grip change or equip happens here. Validate before clearing so
	# an illegal choice leaves the decision available.
	var chosen := {"ok": true, "weapon": {}, "attack_mode": ""}
	var chooser_index := int(pending_trip.get("actor_index", -1))
	if take_attack:
		if chooser_index < 0 or chooser_index >= combatants.size():
			return _fail("The pending Trip actor is no longer in this encounter.")
		chosen = _improved_trip_weapon(combatants[chooser_index]["char"], choice)
		if not bool(chosen["ok"]):
			return _fail(String(chosen["message"]))
	var state := pending_trip
	pending_trip = {}
	var actor_index := int(state.get("actor_index", -1))
	var target_index := int(state.get("target_index", -1))
	if actor_index < 0 or actor_index >= combatants.size():
		return _fail("The pending Trip actor is no longer in this encounter.")
	var ch: Character = combatants[actor_index]["char"]
	var current := active_entry()
	if not current.is_empty() and int(current.get("index", -1)) != actor_index:
		_log("  The turn moved to another combatant; the Improved Trip attack is void.")
		changed.emit()
		return _fail("That Trip decision no longer belongs to the active combatant.")
	if ch.has_condition("dead") or not ch.can_act():
		_log("  %s can no longer act; the Improved Trip attack is void." % ch.display_name)
		changed.emit()
		return _fail("%s can no longer act; the Trip decision is void." % ch.display_name)
	if target_index < 0 or target_index >= combatants.size():
		return _fail("The tripped opponent is no longer in this encounter.")
	var target: Character = combatants[target_index]["char"]
	if target.has_condition("dead"):
		_log("  The tripped opponent is already down; there is nothing to attack.")
		_after_action(ch)
		_check_end()
		changed.emit()
		return {"ok": true, "attacked": false, "message": "There is no opponent left to attack."}
	if not take_attack:
		_log("  %s declines the Improved Trip follow-up attack." % ch.display_name)
		_after_action(ch)
		_check_end()
		changed.emit()
		return {
			"ok": true,
			"attacked": false,
			"message": "%s declines the extra attack." % ch.display_name,
		}
	_log("  Improved Trip grants an immediate melee attack against %s." % target.display_name)
	var result := _resolve_attack(
		actor_index,
		target_index,
		chosen["weapon"],
		{"attack_mode": String(chosen["attack_mode"])}
	)
	var response := {
		"ok": true,
		"attacked": true,
		"result": result.get("result", {}),
		"message": "Improved Trip attack resolves.",
	}
	# The follow-up can drop a creature and grant Cleave; the caller needs that
	# new decision rather than only the attack result.
	if String(result.get("pending", "")) != "":
		response["pending"] = String(result.get("pending", ""))
	return response


## The follow-up attack may use any melee attack the character can currently
## make: the equipped weapon's legal melee mode, or an unarmed strike. A ranged
## weapon cannot satisfy "a melee attack"; unarmed is the fallback.
func _improved_trip_weapon(ch: Character, choice: String) -> Dictionary:
	var requested := choice.to_lower()
	if requested == "unarmed":
		return {"ok": true, "weapon": _unarmed_strike(ch), "attack_mode": "melee"}
	var weapon := _primary_weapon(ch)
	var mode := Rules.normalize_attack_mode(weapon, requested)
	if requested != "" and mode == "":
		return {
			"ok": false,
			"message": "%s has no '%s' attack mode." % [String(weapon.get("name", "That weapon")), requested],
		}
	if mode == "" or Rules.is_ranged_attack(weapon, mode):
		if requested != "":
			return {"ok": false, "message": "The Improved Trip follow-up must be a melee attack (PHB p.96)."}
		return {"ok": true, "weapon": _unarmed_strike(ch), "attack_mode": "melee"}
	return {"ok": true, "weapon": weapon, "attack_mode": mode}


## Another living enemy within the attacker's melee reach, excluding the creature
## that was just dropped (PHB p.92). Allies are not offered, matching the slice's
## attack-target policy.
func cleave_targets(attacker_index: int, exclude_index: int) -> Array:
	var result: Array = []
	if attacker_index < 0 or attacker_index >= combatants.size():
		return result
	var entry: Dictionary = combatants[attacker_index]
	var ch: Character = entry["char"]
	var reach := maxi(ch.reach_ft, BattleMap.CELL_FT)
	for other in combatants:
		var other_index := int(other["index"])
		if other_index == attacker_index or other_index == exclude_index:
			continue
		if int(other["team"]) == int(entry["team"]):
			continue
		var target: Character = other["char"]
		if target.has_condition("dead"):
			continue
		if map.distance_ft(entry["cell"], other["cell"]) > reach:
			continue
		result.append(other)
	return result


## Offers Cleave after a resolved drop. Returns the pending type, or "" when the
## feat is absent, already used this round, or no other creature is in reach.
func _offer_cleave(
	attacker_index: int,
	dropped_index: int,
	weapon: Dictionary,
	attack_mode: String,
	label: String,
	attack_base: int
) -> String:
	var ch: Character = combatants[attacker_index]["char"]
	if not Feats.cleave_available(ch) or cleave_used.has(attacker_index):
		return ""
	if cleave_targets(attacker_index, dropped_index).is_empty():
		return ""
	pending_cleave = {
		"type": "cleave_attack",
		"actor_index": attacker_index,
		"dropped_index": dropped_index,
		"weapon": weapon.duplicate(true),
		"attack_mode": attack_mode,
		"attack_base": attack_base,
		"label": label,
		"off_turn": not is_player_turn(),
	}
	_log(
		"  Cleave: %s may make one extra melee attack against another creature within reach (PHB p.92)."
		% ch.display_name
	)
	return "cleave_attack"


## Resolves Cleave's granted attack: same weapon, same bonus, no 5-foot step and
## no extra action. The use is marked before rolling, so a drop caused by this
## attack cannot grant a second Cleave in the same round.
func resolve_cleave_attack(target_index: int) -> Dictionary:
	if pending_cleave.is_empty():
		return _fail("There is no pending Cleave attack.")
	var state := pending_cleave
	var actor_index := int(state.get("actor_index", -1))
	if actor_index < 0 or actor_index >= combatants.size():
		pending_cleave.clear()
		return _fail("The Cleave attacker is no longer in this encounter.")
	var ch: Character = combatants[actor_index]["char"]
	var current := active_entry()
	# On-turn Cleave belongs to the active combatant. An off-turn Cleave belongs
	# to the interrupted action: the active combatant is still the creature whose
	# turn was paused, so ownership comes from the stored state, not the turn.
	if (
		not bool(state.get("off_turn", false))
		and (current.is_empty() or int(current.get("index", -1)) != actor_index)
	):
		pending_cleave.clear()
		_log("  The turn moved; the Cleave attack is void.")
		changed.emit()
		return _fail("That Cleave decision no longer belongs to the active combatant.")
	if ch.has_condition("dead") or not ch.can_act():
		pending_cleave.clear()
		_log("  %s can no longer act; the Cleave attack is void." % ch.display_name)
		changed.emit()
		return _fail("%s can no longer act; the Cleave attack is void." % ch.display_name)
	var legal := cleave_targets(actor_index, int(state.get("dropped_index", -1)))
	var found := false
	for other in legal:
		if int(other["index"]) == target_index:
			found = true
			break
	if not found:
		return _fail("Cleave must target another living enemy within reach.")
	pending_cleave = {}
	cleave_used[actor_index] = true
	var target: Character = combatants[target_index]["char"]
	_log("  Cleave: %s follows through against %s." % [ch.display_name, target.display_name])
	var result := _resolve_attack(
		actor_index,
		target_index,
		state.get("weapon", {}),
		{
			"attack_mode": String(state.get("attack_mode", "")),
			"force_attack_base": int(state.get("attack_base", 0)),
			"reaction": bool(state.get("off_turn", false)),
		}
	)
	return {
		"ok": true,
		"attacked": true,
		"result": result.get("result", {}),
		"message": "Cleave attack resolves.",
	}


func decline_cleave() -> Dictionary:
	if pending_cleave.is_empty():
		return _fail("There is no pending Cleave attack.")
	var actor_index := int(pending_cleave.get("actor_index", -1))
	pending_cleave = {}
	if actor_index >= 0 and actor_index < combatants.size():
		var ch: Character = combatants[actor_index]["char"]
		_log("  %s declines the Cleave attack." % ch.display_name)
	changed.emit()
	return {"ok": true, "attacked": false, "message": "Cleave declined."}


func has_pending_decision() -> bool:
	return not pending_trip.is_empty() or not pending_cleave.is_empty()


## Pick up an item from the ground: move action that provokes (PHB Table 8-2,
## p.141). The item moves from the ground to the inventory, unequipped.
func pick_up_active(ground_index: int) -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot pick anything up." % ch.display_name)
	if ground_index < 0 or ground_index >= ground_items.size():
		return _fail("There is no such item on the ground.")
	if bool(turn_state["five_foot_used"]):
		return _fail("You cannot pick up an item after taking a 5-foot step.")
	if bool(turn_state["move_used"]) and bool(turn_state["standard_used"]):
		return _fail("No move action remaining this turn.")
	var ground: Dictionary = ground_items[ground_index]
	if Vector2i(ground["cell"]) != Vector2i(entry["cell"]):
		return _fail("You must be in the item's square to pick it up.")
	# Spent before the reaction, like any provoking action.
	if bool(turn_state["move_used"]):
		turn_state["standard_used"] = true
	else:
		turn_state["move_used"] = true
	var item_name := String(Dictionary(ground["item"]).get("name", "an item"))
	_log("%s picks up %s from the ground." % [ch.display_name, item_name])
	for foe in _threatening_enemies(entry):
		if finished or not ch.can_act() or ch.has_condition("paralyzed"):
			break
		_provoke_single_opportunity(foe["char"], ch)
	if finished:
		_changed()
		return {
			"ok": true,
			"interrupted": true,
			"message": "%s was interrupted while picking up the item." % ch.display_name,
		}
	if not ch.can_act() or ch.has_condition("paralyzed"):
		_changed()
		return {
			"ok": false,
			"interrupted": true,
			"message": "%s fails to pick the item up; it stays on the ground." % ch.display_name,
		}
	var item: Dictionary = Dictionary(ground["item"]).duplicate(true)
	ch.add_to_inventory(item, 1)
	ground_items.remove_at(ground_index)
	_log("  %s is now in %s's inventory (not equipped)." % [item_name, ch.display_name])
	_after_action(ch)
	_check_end()
	changed.emit()
	return {"ok": true, "interrupted": false, "message": "Picked up %s." % item_name}


## Returns items still on the ground and clears the list, so a finished
## encounter cannot silently lose them (postcombat recovery).
func collect_ground_items() -> Array:
	var recovered := ground_items.duplicate(true)
	ground_items.clear()
	return recovered


## Commits (or clears) the active character's Power Attack amount. This is a
## turn choice, not a per-attack value; it must be made before the turn's attack
## roll and lasts until the next turn starts.
func set_active_power_attack(amount: int) -> Dictionary:
	var blocked := _pending_guard()
	if not blocked.is_empty():
		return blocked
	var entry := active_entry()
	if entry.is_empty() or int(entry["team"]) != TEAM_PARTY:
		return _fail("It is not a party member's turn.")
	var ch: Character = entry["char"]
	if not is_player_turn():
		return _fail("%s cannot choose Power Attack now." % ch.display_name)
	if not Feats.has_active(ch, "power_attack"):
		return _fail("%s does not have Power Attack." % ch.display_name)
	var maximum := Feats.power_attack_max(ch)
	if amount < 0 or amount > maximum:
		return _fail("Power Attack must be between 0 and %d." % maximum)
	if bool(turn_state.get("standard_used", false)):
		return _fail("Power Attack must be chosen before the attack roll.")
	var index := int(entry["index"])
	if amount == 0:
		power_attack_committed.erase(index)
		_log("  %s's Power Attack is off." % ch.display_name)
	else:
		power_attack_committed[index] = amount
		_log(
			"  %s commits Power Attack -%d until the start of their next turn."
			% [ch.display_name, amount]
		)
	changed.emit()
	return {
		"ok": true,
		"amount": amount,
		"message": "Power Attack %s." % ("off" if amount == 0 else "-%d" % amount),
	}


func power_attack_amount_for(index: int) -> int:
	return int(power_attack_committed.get(index, 0))


func active_power_attack_amount() -> int:
	var entry := active_entry()
	return power_attack_amount_for(int(entry["index"])) if not entry.is_empty() else 0


## Stores a pending Combat Expertise amount for the active character. The
## amount is validated against the feat and its base-attack cap, but no AC or
## attack change happens until `attack_active` resolves a melee attack action.
func set_active_combat_expertise(amount: int) -> Dictionary:
	var blocked := _pending_guard()
	if not blocked.is_empty():
		return blocked
	var entry := active_entry()
	if entry.is_empty() or int(entry["team"]) != TEAM_PARTY:
		return _fail("It is not a party member's turn.")
	var ch: Character = entry["char"]
	if not is_player_turn():
		return _fail("%s cannot choose Combat Expertise now." % ch.display_name)
	if not Feats.has_active(ch, "combat_expertise"):
		return _fail("%s does not have Combat Expertise." % ch.display_name)
	var maximum := Feats.combat_expertise_max(ch)
	if amount < 0 or amount > maximum:
		return _fail("Combat Expertise must be between 0 and %d." % maximum)
	if bool(turn_state.get("standard_used", false)):
		return _fail("Combat Expertise must be chosen before the attack roll.")
	var index := int(entry["index"])
	if combat_expertise_amount_for(index) > 0:
		return _fail("Combat Expertise is already active until your next turn.")
	if amount == 0:
		combat_expertise_pending.erase(index)
		_log("  %s's Combat Expertise is off." % ch.display_name)
	else:
		combat_expertise_pending[index] = amount
		_log(
			"  %s prepares Combat Expertise -%d; it activates only on a melee attack action."
			% [ch.display_name, amount]
		)
	changed.emit()
	return {
		"ok": true,
		"amount": amount,
		"pending": amount > 0,
		"message": (
			"Combat Expertise off."
			if amount == 0
			else "Combat Expertise -%d pending; no effect until a melee attack." % amount
		),
	}


func combat_expertise_amount_for(index: int) -> int:
	return int(combat_expertise_committed.get(index, 0))


func combat_expertise_pending_for(index: int) -> int:
	return int(combat_expertise_pending.get(index, 0))


func active_combat_expertise_amount() -> int:
	var entry := active_entry()
	return combat_expertise_amount_for(int(entry["index"])) if not entry.is_empty() else 0


func active_combat_expertise_pending_amount() -> int:
	var entry := active_entry()
	return combat_expertise_pending_for(int(entry["index"])) if not entry.is_empty() else 0


## Commits the pending amount immediately before the qualifying melee attack.
## The effect is stored on the character so all AC calls (including incoming
## attacks while another actor is active) see the same dodge bonus.
func _commit_pending_combat_expertise(attacker_index: int) -> int:
	var amount := combat_expertise_pending_for(attacker_index)
	if amount <= 0:
		return 0
	var attacker: Character = combatants[attacker_index]["char"]
	var maximum := Feats.combat_expertise_max(attacker)
	if not Feats.has_active(attacker, "combat_expertise") or amount > maximum:
		combat_expertise_pending.erase(attacker_index)
		_log("  %s's Combat Expertise choice is no longer legal." % attacker.display_name)
		return 0
	combat_expertise_pending.erase(attacker_index)
	combat_expertise_committed[attacker_index] = amount
	attacker.remove_effect("combat_expertise")
	attacker.add_effect("combat_expertise", "Combat Expertise", -1, "feat")
	var effect := attacker.get_effect("combat_expertise")
	if not effect.is_empty():
		effect["value"] = amount
	_log(
		"  %s commits Combat Expertise -%d / +%d dodge AC until the start of their next turn."
		% [attacker.display_name, amount, amount]
	)
	return amount


func _discard_pending_combat_expertise(attacker_index: int, reason: String) -> void:
	var amount := combat_expertise_pending_for(attacker_index)
	if amount <= 0:
		return
	combat_expertise_pending.erase(attacker_index)
	var attacker: Character = combatants[attacker_index]["char"]
	_log(
		"  %s's pending Combat Expertise is not applied to the %s."
		% [attacker.display_name, reason]
	)


func _committed_combat_expertise(attacker_index: int, weapon: Dictionary, attack_mode: String) -> int:
	var amount := combat_expertise_amount_for(attacker_index)
	if amount <= 0 or Rules.is_ranged_attack(weapon, attack_mode):
		return 0
	var attacker: Character = combatants[attacker_index]["char"]
	if not Feats.has_active(attacker, "combat_expertise"):
		return 0
	return mini(amount, Feats.combat_expertise_max(attacker))


func _clear_combat_expertise_states() -> void:
	combat_expertise_pending.clear()
	combat_expertise_committed.clear()
	for entry in combatants:
		var ch: Character = entry["char"]
		ch.remove_effect("combat_expertise")


func _committed_power_attack(attacker_index: int, weapon: Dictionary, attack_mode: String) -> int:
	var amount := power_attack_amount_for(attacker_index)
	if amount <= 0 or Rules.is_ranged_attack(weapon, attack_mode):
		return 0
	var attacker: Character = combatants[attacker_index]["char"]
	if not Feats.has_active(attacker, "power_attack"):
		return 0
	return mini(amount, Feats.power_attack_max(attacker))


func _attack_label(
	weapon: Dictionary, power_attack: int, attack_mode := "", combat_expertise := 0
) -> String:
	var label := String(weapon.get("name", "attack"))
	if attack_mode == "thrown":
		label += " (thrown)"
	if power_attack > 0:
		label += " (Power Attack -%d)" % power_attack
	if combat_expertise > 0:
		label += " (Combat Expertise -%d)" % combat_expertise
	return label


func _resolve_attack(attacker_index: int, target_index: int, weapon: Dictionary, opts := {}) -> Dictionary:
	var entry: Dictionary = combatants[attacker_index]
	var target_entry: Dictionary = combatants[target_index]
	var ch: Character = entry["char"]
	var target: Character = target_entry["char"]
	var distance := map.distance_ft(entry["cell"], target_entry["cell"])
	var attack_mode := Rules.normalize_attack_mode(
		weapon, String(opts.get("attack_mode", ""))
	)
	var power_attack := _committed_power_attack(attacker_index, weapon, attack_mode)
	var combat_expertise := _committed_combat_expertise(attacker_index, weapon, attack_mode)
	var label := _attack_label(weapon, power_attack, attack_mode, combat_expertise)
	var target_flat_footed := is_flat_footed(target_index)
	# A reaction is never a fresh ranged attack (it is a melee opportunity
	# attack), and only a ranged attack can be shot into a melee.
	var into_melee := {"penalty": 0, "reason": ""}
	var cover := 0
	if Rules.is_ranged_attack(weapon, attack_mode) and not bool(opts.get("reaction", false)):
		into_melee = _into_melee_penalty(ch, target, entry, target_entry)
		cover = creature_cover(attacker_index, target_index)
	var extra := ""
	# A rogue can sneak attack a flat-footed opponent as well as a flanked or
	# helpless one (PHB p.133). Undead and constructs remain immune.
	if (
		ch.sneak_attack_dice != ""
		and (Rules.is_helpless(target) or _is_flanked(target_index) or target_flat_footed)
		and not target.tags.has("undead")
		and not target.tags.has("construct")
	):
		extra = ch.sneak_attack_dice
	var fight_defensively := -4 if ch.has_effect("fighting_defensively") else 0
	var attack_opts := {
		"label": label,
		"fight_defensively_penalty": fight_defensively,
		"touch": bool(opts.get("touch", false)),
		"flat_footed": target_flat_footed,
		"extra_damage": extra,
		"bonus": int(opts.get("bonus", 0)),
		"power_attack": power_attack,
		"combat_expertise": combat_expertise,
		"attack_mode": attack_mode,
		"into_melee_penalty": int(into_melee["penalty"]),
		"cover": cover,
	}
	if opts.has("force_attack_base"):
		attack_opts["force_attack_base"] = int(opts["force_attack_base"])
	var result := Rules.attack(rng, ch, target, weapon, distance, attack_opts)
	# PHB p.139: an unarmed strike's damage is nonlethal; carry that into the result so
	# damage application never has to guess from the damage type alone.
	result["nonlethal"] = bool(weapon.get("nonlethal", false))
	_log("  " + Rules.format_attack(result))
	if fight_defensively != 0:
		_log("  fighting defensively -4 on the attack roll (PHB p.140).")
	if int(into_melee["penalty"]) != 0:
		_log(
			"  shooting into melee %+d: %s (PHB p.140)."
			% [int(into_melee["penalty"]), String(into_melee["reason"])]
		)
	if cover > 0:
		_log(
			"  a creature is in the line: %s has cover, +%d AC (PHB p.151)."
			% [target.display_name, cover]
		)
	if target_flat_footed:
		_log("  %s is flat-footed: no Dexterity bonus to AC (PHB pp.133, 136)." % target.display_name)
	if extra != "":
		_log("  sneak attack applies: +%s" % extra)
	var hp_before := target.hp
	if bool(result["hit"]):
		_apply_damage(target, result)
		_try_paralysis(ch, target, weapon)
		if target.has_condition("dead"):
			_log("  %s is destroyed." % target.display_name)
	var cleave_pending := ""
	# Cleave is a resolved-damage event, not a target leaving the array: the hit
	# must drop the creature below 0 HP or kill it (PHB p.92). Any resolved melee
	# attack by a party member can qualify, including an opportunity attack, which
	# is a real melee attack rather than an "own turn" exception. A ranged attack,
	# a spell or another damage effect cannot qualify, and NPC attackers do not
	# take Cleave in this slice.
	if (
		bool(result["hit"])
		and not bool(result.get("ranged", false))
		and hp_before > 0
		and (target.hp < 0 or target.has_condition("dead"))
		and int(combatants[attacker_index]["team"]) == TEAM_PARTY
	):
		cleave_pending = _offer_cleave(
			attacker_index,
			target_index,
			weapon,
			attack_mode,
			label,
			int(result.get("bonus_base", result.get("bonus", 0))),
		)
	# A reaction (opportunity attack) must not spend the attacker's own action
	# economy; the interrupted action owns the turn.
	if not bool(opts.get("reaction", false)):
		turn_state["standard_used"] = true
		_after_action(ch)
	_check_end()
	changed.emit()
	var response := {"ok": true, "result": result, "message": Rules.format_attack(result)}
	if cleave_pending != "":
		response["pending"] = cleave_pending
	return response


func _apply_damage(target: Character, result: Dictionary) -> void:
	var damage := int(result.get("damage", 0))
	var damage_type := String(result.get("damage_type", "untyped"))
	if bool(result.get("nonlethal", false)) or damage_type == "nonlethal":
		# PHB p.139: unarmed strike damage is nonlethal, tracked apart from hit points.
		if Rules.nonlethal_immune(target):
			result["damage_applied"] = 0
			_log("  %s is immune to nonlethal damage." % target.display_name)
			return
		var nonlethal_applied := target.apply_nonlethal(damage)
		result["damage_applied"] = int(nonlethal_applied["applied"])
		_log(
			"  %s takes %d nonlethal damage (nonlethal %d, HP %d/%d)."
			% [
				target.display_name,
				int(nonlethal_applied["applied"]),
				target.nonlethal,
				target.hp,
				target.max_hp,
			]
		)
		if bool(nonlethal_applied["unconscious"]):
			_log(
				"  %s is unconscious and helpless from nonlethal damage (PHB p.147)."
				% target.display_name
			)
		elif bool(nonlethal_applied["staggered"]):
			_log(
				"  %s is staggered: one standard or one move action per round (PHB p.147)."
				% target.display_name
			)
		_check_end()
		return
	if not target.damage_reduction.is_empty():
		var amount := int(target.damage_reduction.get("amount", 0))
		var bypass: Array = target.damage_reduction.get("bypass", [])
		if amount > 0 and not bypass.has(damage_type):
			damage = maxi(0, damage - amount)
			_log("  damage reduction %d/%s applies (%s)." % [amount, "/".join(bypass), damage_type])
	var applied := target.take_damage(damage)
	result["damage_applied"] = damage
	_log(
		"  %s takes %d damage (HP %d/%d)."
		% [target.display_name, damage, target.hp, target.max_hp]
	)
	if bool(applied["died"]):
		pass
	elif target.has_condition("dying"):
		_log("  %s is dying (unconscious, -1 HP each round, 10%% stabilize chance)." % target.display_name)
	elif target.has_condition("disabled"):
		_log("  %s is disabled (0 HP)." % target.display_name)


func _try_paralysis(attacker: Character, target: Character, weapon: Dictionary) -> void:
	var dc := int(weapon.get("paralysis_dc", 0))
	if dc <= 0 or not target.can_act():
		return
	if target.tags.has("undead") or target.tags.has("elf") or target.immunities.has("paralysis"):
		_log("  %s is immune to paralysis." % target.display_name)
		return
	var save := Rules.saving_throw(rng, target, "fort", dc)
	_log(
		"  paralysis save: %s d20(%d)%+d = %d vs DC %d — %s"
		% [
			target.display_name,
			int(save["roll"]),
			int(save["bonus"]),
			int(save["total"]),
			dc,
			"success" if bool(save["success"]) else "FAILED",
		]
	)
	if not bool(save["success"]):
		var rounds := Dice.expression(rng, "1d4+1")
		target.add_effect("paralyzed", "Paralyzed", rounds)
		_log("  %s is paralyzed for %d rounds." % [target.display_name, rounds])


func _is_flanked(target_index: int) -> bool:
	var target_entry: Dictionary = combatants[target_index]
	var target_cell: Vector2i = target_entry["cell"]
	var team := int(target_entry["team"])
	var positions: Array[Vector2i] = []
	for entry in combatants:
		if int(entry["team"]) == team:
			continue
		var ch: Character = entry["char"]
		if not ch.can_act():
			continue
		var c: Vector2i = entry["cell"]
		if _threatens_cell(ch, c, target_cell):
			positions.append(c)
	for i in positions.size():
		for j in range(i + 1, positions.size()):
			var a := positions[i]
			var b := positions[j]
			if (a.x - target_cell.x) * (b.x - target_cell.x) < 0:
				return true
			if (a.y - target_cell.y) * (b.y - target_cell.y) < 0:
				return true
	return false


## PHB p. 140: "If you shoot or throw a ranged weapon at a target engaged in
## melee with a friendly character, you take a -4 penalty on your attack roll."
## "Two characters are engaged in melee if they are enemies of each other and
## either threatens the other. (An unconscious or otherwise immobilized
## character is not considered engaged unless he is actually being attacked.)"
## The penalty is avoided when the target is at least 10 ft. from the nearest
## friendly character, and Precise Shot (p. 98; ranged spells p. 73 of Complete
## Arcane) removes it. Helpless targets are treated as not engaged: this slice
## does not track whether the ally attacked them this round.
## Soft cover from creatures (PHB p.151). Ranged attacks only: the target has
## cover unless one of the attacker's four corners has all four lines to the
## target's corners clear, and a creature is cover only when a line crosses its
## square's interior (see `BattleMap.cells_crossed`).
func creature_cover(attacker_index: int, target_index: int) -> int:
	if attacker_index == target_index or attacker_index < 0 or target_index < 0:
		return 0
	if attacker_index >= combatants.size() or target_index >= combatants.size():
		return 0
	var occupied := {}
	for other in combatants:
		occupied[other["cell"]] = int(other["index"])
	return BattleMap.creature_cover(
		combatants[attacker_index]["cell"], combatants[target_index]["cell"], occupied
	)


## Selection is not activation: it only records the intent to fight defensively
## and can be cancelled, or replaced by total defense, until an attack commits.
func set_fight_defensively(enabled: bool) -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	var ch: Character = entry["char"]
	var index := int(entry["index"])
	if ch.has_effect("fighting_defensively") and not enabled:
		return _fail(
			"%s is already fighting defensively until the start of the next turn; it cannot be cancelled."
			% ch.display_name
		)
	if ch.has_effect("total_defense"):
		return _fail(
			"%s is using total defense; fighting defensively cannot be combined with it (PHB p.143)."
			% ch.display_name
		)
	if not enabled:
		fight_defensively_selected.erase(index)
		changed.emit()
		return {"ok": true, "message": "%s will not fight defensively." % ch.display_name}
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot fight defensively." % ch.display_name)
	if bool(turn_state["standard_used"]):
		return _fail(
			"Your standard action is already spent; fighting defensively must accompany an attack."
		)
	fight_defensively_selected[index] = true
	var bonus := 3 if int(ch.skill_ranks.get("tumble", 0)) >= 5 else 2
	changed.emit()
	return {
		"ok": true,
		"message": (
			"%s is ready to fight defensively: -4 on attack rolls and +%d dodge AC once an attack is committed."
			% [ch.display_name, bonus]
		),
	}


func fight_defensively_selected_for(index: int) -> bool:
	return fight_defensively_selected.has(index)


func fight_defensively_active_for(index: int) -> bool:
	if index < 0 or index >= combatants.size():
		return false
	return (combatants[index]["char"] as Character).has_effect("fighting_defensively")


func total_defense_active_for(index: int) -> bool:
	if index < 0 or index >= combatants.size():
		return false
	return (combatants[index]["char"] as Character).has_effect("total_defense")


func _activate_fighting_defensively(ch: Character) -> void:
	if ch.has_effect("fighting_defensively"):
		return
	ch.add_effect("fighting_defensively", "Fighting defensively", 1)
	_log(
		"%s fights defensively: -4 on attack rolls, +%d dodge AC until the start of the next turn (PHB p.140)."
		% [ch.display_name, Rules.defensive_dodge_bonus(ch)]
	)


## Total defense (PHB p.143) is a standard action: +4 dodge AC (+6 with 5 Tumble
## ranks), no attacks and no opportunity attacks, and it cannot be combined with
## fighting defensively or Combat Expertise. A mere selection is not a
## commitment, so it may be replaced by this action.
func total_defense() -> Dictionary:
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	if has_pending_decision():
		return _fail("Resolve the pending combat decision first.")
	var ch: Character = entry["char"]
	var index := int(entry["index"])
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot take total defense." % ch.display_name)
	if bool(turn_state["standard_used"]):
		return _fail("Your standard action is already spent this turn.")
	if ch.has_effect("combat_expertise") or combat_expertise_pending.has(index):
		return _fail("Total defense cannot be combined with Combat Expertise (PHB p.143).")
	if ch.has_effect("fighting_defensively"):
		return _fail(
			"Fighting defensively is already active this round; total defense cannot be combined with it."
		)
	fight_defensively_selected.erase(index)
	ch.add_effect("total_defense", "Total defense", 1)
	turn_state["standard_used"] = true
	var bonus := Rules.defensive_dodge_bonus(ch)
	_log(
		"%s takes total defense: +%d dodge bonus to AC for 1 round, no attacks or opportunity attacks (PHB p.143)."
		% [ch.display_name, bonus]
	)
	_after_action(ch)
	_check_end()
	changed.emit()
	return {
		"ok": true,
		"message": "%s uses total defense: +%d dodge AC until the start of the next turn." % [ch.display_name, bonus],
	}


func _into_melee_penalty(
	attacker: Character, target: Character, entry: Dictionary, target_entry: Dictionary
) -> Dictionary:
	if Feats.has_active(attacker, "precise_shot"):
		return {"penalty": 0, "reason": "Precise Shot"}
	if Rules.is_helpless(target):
		return {"penalty": 0, "reason": "%s is immobilized" % target.display_name}
	var nearest := 99999
	var engaged_with := ""
	for other in combatants:
		if int(other["index"]) == int(entry["index"]):
			continue
		if int(other["team"]) != int(entry["team"]):
			continue
		var ally: Character = other["char"]
		var distance := map.distance_ft(other["cell"], target_entry["cell"])
		nearest = mini(nearest, distance)
		if engaged_with != "" or not ally.can_act():
			continue
		# "Either threatens the other" (PHB p. 140): engagement can come from the
		# ally's melee capability or from the target's, so a crossbow-armed ally is
		# still engaged when the target can strike back.
		if (
			_threatens_cell(ally, other["cell"], target_entry["cell"])
			or _threatens_cell(target, target_entry["cell"], other["cell"])
		):
			engaged_with = ally.display_name
	if engaged_with == "":
		return {
			"penalty": 0,
			"reason": "no friendly character is engaged with %s" % target.display_name,
		}
	if nearest >= 10:
		return {
			"penalty": 0,
			"reason": "the nearest friendly character is 10 ft. or more from the target",
		}
	return {"penalty": -4, "reason": "%s is engaged with %s" % [target.display_name, engaged_with]}


func _threatening_enemies(entry: Dictionary) -> Array:
	var result: Array = []
	for other in combatants:
		if int(other["team"]) == int(entry["team"]):
			continue
		var ch: Character = other["char"]
		if not ch.can_act():
			continue
		# PHB p.143: a creature using total defense cannot make opportunity
		# attacks, so it is not a threat for the provocation checks either.
		if ch.has_effect("total_defense"):
			continue
		if threat_capability(ch).is_empty():
			continue
		if map.distance_ft(entry["cell"], other["cell"]) <= maxi(ch.reach_ft, BattleMap.CELL_FT):
			result.append(other)
	return result


func _threatened_by_enemy(entry: Dictionary) -> bool:
	return not _threatening_enemies(entry).is_empty()


func _provoke_single_opportunity(attacker: Character, target: Character) -> void:
	var attacker_entry := entry_for(attacker)
	var target_entry := entry_for(target)
	if attacker_entry.is_empty() or target_entry.is_empty():
		return
	if bool(aoo_used.get(int(attacker_entry["index"]), false)):
		return
	# PHB p.143: "You can't make attacks of opportunity while using total defense."
	if attacker.has_effect("total_defense"):
		_log(
			"  %s is using total defense and cannot make an opportunity attack (PHB p.143)."
			% attacker.display_name
		)
		return
	# Threat requires a legal melee attack (PHB p.137): a crossbow-armed character
	# cannot spend the reaction, and nothing is consumed when it is refused.
	if threat_capability(attacker).is_empty():
		_log(
			"  %s has no melee attack ready and cannot make an opportunity attack."
			% attacker.display_name
		)
		return
	# A flat-footed creature cannot make attacks of opportunity (PHB p.133).
	if is_flat_footed(int(attacker_entry["index"])):
		_log(
			"  %s is flat-footed and cannot make an attack of opportunity."
			% attacker.display_name
		)
		return
	aoo_used[int(attacker_entry["index"])] = true
	_log("  Attack of opportunity by %s!" % attacker.display_name)
	var weapon := _primary_weapon(attacker)
	var mode := Rules.default_attack_mode(weapon)
	var power_attack := _committed_power_attack(
		int(attacker_entry["index"]), weapon, mode
	)
	var combat_expertise := _committed_combat_expertise(
		int(attacker_entry["index"]), weapon, mode
	)
	var result := Rules.attack(
		rng,
		attacker,
		target,
		weapon,
		map.distance_ft(attacker_entry["cell"], target_entry["cell"]),
		{
			"label": _attack_label(weapon, power_attack, mode, combat_expertise),
			"power_attack": power_attack,
			"combat_expertise": combat_expertise,
			"attack_mode": mode,
			"flat_footed": is_flat_footed(int(target_entry["index"])),
		}
	)
	# PHB p.139: an unarmed strike's damage is nonlethal; carry that into the result so
	# damage application never has to guess from the damage type alone.
	result["nonlethal"] = bool(weapon.get("nonlethal", false))
	_log("  " + Rules.format_attack(result))
	if bool(result["hit"]):
		_apply_damage(target, result)
		_try_paralysis(attacker, target, weapon)
	_check_end()


func _provoke_attacks_of_opportunity(mover_index: int, from_cell: Vector2i) -> void:
	var mover: Character = combatants[mover_index]["char"]
	for entry in combatants:
		if int(entry["index"]) == mover_index:
			continue
		if int(entry["team"]) == int(combatants[mover_index]["team"]):
			continue
		var ch: Character = entry["char"]
		if not ch.can_act():
			continue
		# PHB p.143: total defense forbids opportunity attacks. The movement path
		# resolves reactions directly, so the gate lives here as well.
		if ch.has_effect("total_defense"):
			_log(
				"  %s is using total defense and cannot make an opportunity attack (PHB p.143)."
				% ch.display_name
			)
			continue
		if threat_capability(ch).is_empty():
			continue
		if map.distance_ft(from_cell, entry["cell"]) > maxi(ch.reach_ft, BattleMap.CELL_FT):
			continue
		if bool(aoo_used.get(int(entry["index"]), false)):
			continue
		if is_flat_footed(int(entry["index"])):
			_log(
				"  %s is flat-footed and cannot make an attack of opportunity."
				% ch.display_name
			)
			continue
		aoo_used[int(entry["index"])] = true
		_log(
			"  %s leaves a threatened square — attack of opportunity by %s!"
			% [mover.display_name, ch.display_name]
		)
		var weapon := _primary_weapon(ch)
		var mode := Rules.default_attack_mode(weapon)
		# An opportunity attack is an ordinary resolved melee attack, so a drop
		# from it can satisfy Cleave (PHB p.92). `reaction` keeps the attacker's
		# own action economy untouched and spends no standard action.
		_resolve_attack(
			int(entry["index"]), mover_index, weapon, {"attack_mode": mode, "reaction": true}
		)
		if has_pending_decision():
			# The Cleave decision pauses the move; the caller records the
			# remaining route so the interrupted action can resume.
			break
		if mover.has_condition("dead") or mover.has_condition("dying"):
			break
	_changed()


func _changed() -> void:
	changed.emit()


# ---------------------------------------------------------------- spells

## Casts a prepared spell. `opts.defensive` selects the printed Casting on the
## Defensive option (PHB p. 140): no attack of opportunity, but a Concentration
## check at DC 15 + spell level, and failure loses the spell. Ordinary casting in
## a threatened square provokes as before (p. 135); any damage dealt by those
## attacks forces a Concentration check at DC 10 + damage + spell level (p. 170),
## one check per damaging interruption (p. 70).
func cast_active_spell(spell_id: String, target_index: int, opts := {}) -> Dictionary:
	var blocked := _pending_guard()
	if not blocked.is_empty():
		return blocked
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	var ch: Character = entry["char"]
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot cast." % ch.display_name)
	if bool(turn_state["standard_used"]):
		return _fail("Your standard action is already spent this turn.")
	var staggered_cast := _staggered_blocks_standard(ch)
	if staggered_cast != "":
		return _fail(staggered_cast)
	var spell: Dictionary = spells_by_id.get(spell_id, {})
	if spell.is_empty():
		return _fail("Unknown spell '%s'." % spell_id)
	var level := int(spell.get("level", 1))
	if not ch.can_cast(level, spell_id):
		return _fail("%s has no prepared cast of %s remaining." % [ch.display_name, spell["name"]])
	var resolve := String(spell.get("resolve", ""))
	var target_entry: Dictionary = combatants[target_index] if target_index >= 0 and target_index < combatants.size() else {}
	var target: Character = target_entry.get("char") as Character
	if ["magic_missile", "scorching_ray"].has(resolve):
		if target == null or int(target_entry.get("team", -1)) != TEAM_ENEMY or target.has_condition("dead"):
			return _fail("%s must target a living enemy." % spell["name"])
	elif ["cure_light_wounds", "aid", "mage_armor"].has(resolve):
		if target == null or int(target_entry.get("team", -1)) != TEAM_PARTY:
			return _fail("%s must target an ally." % spell["name"])
		if target.has_condition("dead"):
			return _fail("%s cannot benefit a dead creature." % spell["name"])
		if resolve != "mage_armor" and (target.tags.has("undead") or target.tags.has("construct")):
			return _fail("%s can only benefit a living creature." % spell["name"])
	var range_ft := int(spell.get("range_ft", 0))
	if target != null and range_ft > 0:
		if map.distance_ft(entry["cell"], target_entry["cell"]) > range_ft:
			return _fail("%s is out of range (max %d ft.)." % [target.display_name, range_ft])
		if not map.has_line_of_sight(entry["cell"], target_entry["cell"]):
			return _fail("No line of sight to %s." % target.display_name)
	# Everything above is legality: an invalid selection returns before this
	# point and consumes nothing. From here the standard action is spent and the
	# prepared cast is expended even if an interruption disrupts the spell
	# (PHB p. 70: a failed check wastes the action and the spell is lost;
	# p. 140 for casting on the defensive).
	var defensive := bool(opts.get("defensive", false))
	turn_state["standard_used"] = true
	if not ch.consume_spell(level, spell_id):
		return _fail("%s has no prepared cast of %s remaining." % [ch.display_name, spell["name"]])
	var interruptions: Array[int] = []
	var concentration_checks: Array = []
	var concentration_failed := false
	var failed_check := {}
	if defensive:
		var defensive_dc := 15 + level
		_log(
			"%s casts %s defensively: no opportunity attack, Concentration DC 15 + %d = DC %d."
			% [ch.display_name, spell["name"], level, defensive_dc]
		)
		var defensive_check := _concentration_check(ch, defensive_dc, true)
		concentration_checks.append({
			"kind": "defensive", "damage": 0, "dc": defensive_dc, "check": defensive_check
		})
		if not bool(defensive_check.get("success", false)):
			concentration_failed = true
			failed_check = defensive_check
	else:
		var threats := _threatening_enemies(entry)
		if not threats.is_empty():
			_log(
				"%s casts %s while threatened and provokes attacks of opportunity (PHB p.135)."
				% [ch.display_name, spell["name"]]
			)
			for foe in threats:
				if finished or not ch.can_act() or ch.has_condition("paralyzed"):
					break
				var hp_before_attack := ch.hp
				_provoke_single_opportunity(foe["char"], ch)
				var dealt := hp_before_attack - ch.hp
				if dealt > 0:
					interruptions.append(dealt)
	if not finished and ch.can_act() and not ch.has_condition("paralyzed"):
		for damage in interruptions:
			var injury_dc := 10 + damage + level
			_log(
				"  injury while casting: %d damage + spell level %d: Concentration DC 10 + %d + %d = DC %d."
				% [damage, level, damage, level, injury_dc]
			)
			var injury_check := _concentration_check(ch, injury_dc)
			concentration_checks.append({
				"kind": "injury", "damage": damage, "dc": injury_dc, "check": injury_check
			})
			if not bool(injury_check.get("success", false)):
				concentration_failed = true
				failed_check = injury_check
				break
	if concentration_failed:
		_log(
			"  The spell is disrupted: %s loses %s, the prepared cast is expended and the action is spent."
			% [ch.display_name, spell["name"]]
		)
		_after_action(ch)
		_check_end()
		changed.emit()
		return {
			"ok": false,
			"disrupted": true,
			"concentration": failed_check,
			"concentration_checks": concentration_checks,
			"defensive": defensive,
			"message": "%s's spell is disrupted." % ch.display_name,
		}
	if finished or not ch.can_act() or ch.has_condition("paralyzed"):
		_log(
			"  %s cannot complete the spell; it is lost and the prepared cast is expended."
			% ch.display_name
		)
		_after_action(ch)
		_check_end()
		changed.emit()
		return {
			"ok": false,
			"disrupted": true,
			"concentration_checks": concentration_checks,
			"defensive": defensive,
			"message": "%s was interrupted before the spell completed." % ch.display_name,
		}
	_log("%s casts %s." % [ch.display_name, spell["name"]])
	match resolve:
		"magic_missile":
			_cast_magic_missile(ch, target, spell)
		"scorching_ray":
			_cast_scorching_ray(int(entry["index"]), target_index, spell)
		"cure_light_wounds":
			_cast_cure(ch, target, spell)
		"bless":
			_cast_bless(ch, spell)
		"mage_armor":
			_cast_mage_armor(ch, target, spell)
		"aid":
			_cast_aid(ch, target, spell)
		_:
			_log("  (No resolver implemented for '%s' — slot was consumed.)" % resolve)
	_after_action(ch)
	_check_end()
	changed.emit()
	return {
		"ok": true,
		"defensive": defensive,
		"concentration_checks": concentration_checks,
		"message": "%s cast %s%s." % [
			ch.display_name, spell["name"], " defensively" if defensive else ""
		],
	}


## One Concentration check, logged with its inputs so a failure is auditable
## rather than a bare "spell lost". Concentration is untrained-allowed (PHB
## p. 69), so a caster with no ranks still uses the Constitution modifier.
func _concentration_check(ch: Character, dc: int, defensive := false) -> Dictionary:
	var opts := {"threatened": true}
	if defensive:
		# Combat Casting (PHB p. 92) applies only to checks made to cast on the
		# defensive; marking the circumstance keeps that bonus off injury checks.
		opts["defensive_casting"] = true
	var check := Rules.skill_check(rng, ch, "concentration", dc, opts)
	if not bool(check.get("available", false)):
		_log("  Concentration unavailable: %s" % String(check.get("reason", "")))
		return check
	var parts: Array[String] = []
	for row in Array(check.get("breakdown", [])):
		parts.append("%s %+d" % [String(row["label"]), int(row["value"])])
	var breakdown := "" if parts.is_empty() else " [%s]" % ", ".join(parts)
	_log(
		"  Concentration check: d20(%d)%+d = %d vs DC %d%s — %s"
		% [
			int(check["roll"]),
			int(check["bonus"]),
			int(check["total"]),
			int(check["dc"]),
			breakdown,
			"success" if bool(check["success"]) else "FAILED",
		]
	)
	return check


func _caster_level(ch: Character) -> int:
	return int(ch.spells.get("caster_level", ch.level))


func _spell_dc(ch: Character, spell: Dictionary) -> int:
	var ability := String(spell.get("save_ability", ch.spells.get("ability", "wis")))
	return 10 + int(spell.get("level", 1)) + Rules.ability_modifier(ch, ability)


func _cast_magic_missile(ch: Character, target: Character, spell: Dictionary) -> void:
	if target == null or target.has_condition("dead"):
		_log("  The spell fizzles without a valid target.")
		return
	var count := mini(5, 1 + floori(float(_caster_level(ch) - 1) / 2.0))
	_log("  %d missile(s) at caster level %d." % [count, _caster_level(ch)])
	for i in count:
		var parsed := Dice.parse(rng, "1d4+1")
		_log("  missile %d: %s = %d damage" % [i + 1, Dice.describe(parsed), int(parsed["total"])])
		target.take_damage(int(parsed["total"]))
	_log("  %s HP: %d/%d" % [target.display_name, target.hp, target.max_hp])
	if target.has_condition("dead"):
		_log("  %s is destroyed." % target.display_name)


func _cast_scorching_ray(attacker_index: int, target_index: int, spell: Dictionary) -> void:
	if target_index < 0 or target_index >= combatants.size():
		_log("  The ray fizzles without a valid target.")
		return
	var pseudo := {
		"name": "scorching ray",
		"damage": String(spell.get("damage", "4d6")),
		"crit_range": 20,
		"crit_mult": 2,
		"range_increment": 1,
		"damage_type": "fire",
	}
	# Complete Arcane p. 85: a spell that requires an attack roll and deals
	# damage functions as a weapon, and p. 73 gives Precise Shot the same -4
	# exemption for ranged spells. The ray takes the into-melee penalty on the
	# same terms as a bow; the casting provocation above already happened once,
	# and firing the ray adds no second opportunity attack.
	var into_melee := _into_melee_penalty(
		combatants[attacker_index]["char"],
		combatants[target_index]["char"],
		combatants[attacker_index],
		combatants[target_index]
	)
	# The ray is a ranged attack, so a creature in the line grants soft cover
	# (+4 AC) on the touch AC it resolves against; the ray has its own resolver
	# rather than `_resolve_attack`, so the term is added here as well.
	var cover := creature_cover(attacker_index, target_index)
	var result := Rules.attack(
		rng,
		combatants[attacker_index]["char"],
		combatants[target_index]["char"],
		pseudo,
		0,
		{
			"label": "scorching ray (ranged touch)",
			"touch": true,
			"flat_footed": is_flat_footed(target_index),
			"into_melee_penalty": int(into_melee["penalty"]),
			"cover": cover,
		}
	)
	_log("  " + Rules.format_attack(result))
	if int(into_melee["penalty"]) != 0:
		_log(
			"  shooting into melee %+d: %s (PHB p.140; ranged spells, Complete Arcane p.73)."
			% [int(into_melee["penalty"]), String(into_melee["reason"])]
		)
	if cover > 0:
		_log(
			"  a creature is in the line: %s has cover, +%d AC (PHB p.151)."
			% [combatants[target_index]["char"].display_name, cover]
		)
	if bool(result["hit"]):
		var damage := int(result["damage"])
		pseudo["damage_type"] = "fire"
		combatants[target_index]["char"].take_damage(damage)
		_log(
			"  fire damage %d (HP %d/%d)."
			% [damage, combatants[target_index]["char"].hp, combatants[target_index]["char"].max_hp]
		)
		if target_index >= 0 and combatants[target_index]["char"].has_condition("dead"):
			_log("  %s is destroyed." % combatants[target_index]["char"].display_name)


func _cast_cure(ch: Character, target: Character, spell: Dictionary) -> void:
	if target == null:
		_log("  The spell has no valid target.")
		return
	var heal_roll := Dice.parse(rng, "1d8")
	var amount := int(heal_roll["total"]) + mini(_caster_level(ch), 5)
	var healed := target.magical_heal(amount)
	_log(
		"  cure light wounds: %s + %d = %d healing; %s regains %d HP (now %d/%d)."
		% [
			Dice.describe(heal_roll),
			mini(_caster_level(ch), 5),
			amount,
			target.display_name,
			int(healed["healed"]),
			target.hp,
			target.max_hp,
		]
	)
	if int(healed["nonlethal_removed"]) > 0:
		_log(
			"  magical healing also removes %d nonlethal damage (nonlethal %d; PHB p.147)."
			% [int(healed["nonlethal_removed"]), target.nonlethal]
		)


func _cast_bless(ch: Character, spell: Dictionary) -> void:
	var rounds := 10 * _caster_level(ch)
	var caster_entry := entry_for(ch)
	var affected := 0
	for entry in combatants:
		if int(entry["team"]) != TEAM_PARTY:
			continue
		var ally: Character = entry["char"]
		if ally.has_condition("dead"):
			continue
		if map.distance_ft(caster_entry["cell"], entry["cell"]) > int(spell.get("range_ft", 50)):
			continue
		ally.add_effect("bless", "Bless", rounds, "buff")
		affected += 1
	_log("  bless: +1 morale on attacks for %d allies, %d rounds (1 min./level)." % [affected, rounds])


func _cast_mage_armor(ch: Character, target: Character, spell: Dictionary) -> void:
	if target == null:
		_log("  The spell has no valid target.")
		return
	# 1 hour/level at 600 rounds per hour. PHB p. 225: range touch, creature touched.
	var rounds := 600 * _caster_level(ch)
	target.add_effect("mage_armor", "Mage Armor", rounds, "buff")
	_log("  mage armor on %s: +4 armor bonus, 1 hour/level (tracked as %d rounds)." % [target.display_name, rounds])


func _cast_aid(ch: Character, target: Character, spell: Dictionary) -> void:
	if target == null:
		_log("  The spell has no valid target.")
		return
	var caster_level := _caster_level(ch)
	var temp_bonus := mini(caster_level, 10)
	var rounds := 10 * caster_level
	var temp_roll := Dice.parse(rng, "1d8+%d" % temp_bonus)
	target.add_effect("aid", "Aid", rounds, "buff")
	if int(temp_roll["total"]) > target.temp_hp:
		target.temp_hp = int(temp_roll["total"])
	_log(
		"  aid: +1 attack, %d temporary HP for %s for %d rounds (temporary HP do not stack)."
		% [int(temp_roll["total"]), target.display_name, rounds]
	)


# ---------------------------------------------------------------- items, stabilise

func use_potion_active(item_id: String, target_index: int) -> Dictionary:
	var blocked := _pending_guard()
	if not blocked.is_empty():
		return blocked
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	var ch: Character = entry["char"]
	if bool(turn_state["standard_used"]):
		return _fail("Your standard action is already spent this turn.")
	var staggered_potion := _staggered_blocks_standard(ch)
	if staggered_potion != "":
		return _fail(staggered_potion)
	if ch.inventory_count(item_id) <= 0:
		return _fail("%s has no %s." % [ch.display_name, item_id])
	if target_index < 0 or target_index >= combatants.size():
		return _fail("Invalid target.")
	var target: Character = combatants[target_index]["char"]
	if int(combatants[target_index]["team"]) != int(entry["team"]):
		return _fail("A potion can only be given to an ally.")
	if target.has_condition("dead"):
		return _fail("%s is dead and cannot drink a potion." % target.display_name)
	# PHB p.140: drinking a potion or applying an oil provokes attacks of
	# opportunity. Resolve them before consuming the item; a caster disabled by
	# the reaction loses the action without spending the potion.
	var threats := _threatening_enemies(entry)
	if not threats.is_empty():
		_log("%s drinks a potion in melee and provokes attacks of opportunity." % ch.display_name)
		for foe in threats:
			if finished or not ch.can_act() or ch.has_condition("paralyzed"):
				break
			_provoke_single_opportunity(foe["char"], ch)
	if finished or not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s loses the potion to an opportunity attack." % ch.display_name)
	ch.remove_from_inventory(item_id, 1)
	var heal_roll := Dice.parse(rng, "1d8+3")
	var healed := target.magical_heal(int(heal_roll["total"]))
	_log(
		"%s drinks a potion: %s = %d; %s regains %d HP (now %d/%d)."
		% [
			ch.display_name,
			Dice.describe(heal_roll),
			int(heal_roll["total"]),
			target.display_name,
			int(healed["healed"]),
			target.hp,
			target.max_hp,
		]
	)
	if int(healed["nonlethal_removed"]) > 0:
		_log(
			"  the potion also removes %d nonlethal damage (nonlethal %d; PHB p.147)."
			% [int(healed["nonlethal_removed"]), target.nonlethal]
		)
	turn_state["standard_used"] = true
	_after_action(ch)
	_check_end()
	changed.emit()
	return {"ok": true, "message": "Potion used."}


func stabilize_active(target_index: int) -> Dictionary:
	var blocked := _pending_guard()
	if not blocked.is_empty():
		return blocked
	var entry := active_entry()
	if entry.is_empty():
		return _fail("No active combatant.")
	var ch: Character = entry["char"]
	if bool(turn_state["standard_used"]):
		return _fail("Your standard action is already spent this turn.")
	var staggered_first_aid := _staggered_blocks_standard(ch)
	if staggered_first_aid != "":
		return _fail(staggered_first_aid)
	if not ch.can_act() or ch.has_condition("paralyzed"):
		return _fail("%s cannot attempt first aid." % ch.display_name)
	if target_index < 0 or target_index >= combatants.size():
		return _fail("Invalid target.")
	var target_entry: Dictionary = combatants[target_index]
	var target: Character = target_entry["char"]
	if not target.has_condition("dying"):
		return _fail("%s is not dying." % target.display_name)
	if map.distance_ft(entry["cell"], target_entry["cell"]) > BattleMap.CELL_FT:
		return _fail("You must be adjacent to use Heal.")
	var check := Rules.skill_check(rng, ch, "heal", 15)
	_log(
		"%s attempts first aid: d20(%d)%+d = %d vs DC 15 — %s"
		% [
			ch.display_name,
			int(check["roll"]),
			int(check["bonus"]),
			int(check["total"]),
			"success" if bool(check["success"]) else "failure",
		]
	)
	turn_state["standard_used"] = true
	if bool(check["success"]):
		target.stabilize()
		_log("  %s is stabilized." % target.display_name)
	else:
		_log("  %s remains dying." % target.display_name)
	_after_action(ch)
	_check_end()
	changed.emit()
	return {"ok": true, "message": "First aid attempted."}


# ---------------------------------------------------------------- turn undead

## Undead a turn attempt can reach right now, closest first (PHB p.159).
## Already-turned undead stay listed so an attempt can skip over them.
func turn_candidates(ch: Character) -> Array:
	var entry := entry_for(ch)
	if entry.is_empty():
		return []
	var result: Array = []
	for other in combatants:
		if int(other["team"]) != TEAM_ENEMY:
			continue
		var target: Character = other["char"]
		if target.has_condition("dead") or not target.is_undead():
			continue
		if target.turn_effective_hd() <= 0:
			continue
		var distance := map.distance_ft(entry["cell"], other["cell"])
		if distance > 60:
			continue
		# Line of effect is required, not line of sight (PHB p.159); this grid
		# uses blocking walls, so a clear line is the same test here.
		if not map.has_line_of_sight(entry["cell"], other["cell"]):
			continue
		result.append(
			{
				"char": target,
				"index": int(other["index"]),
				"distance": distance,
				"hd": target.turn_effective_hd(),
			}
		)
	result.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["distance"]) == int(b["distance"]):
				return int(a["index"]) < int(b["index"])
			return int(a["distance"]) < int(b["distance"])
	)
	return result


## Availability and the player-facing reason when turning is not possible.
func can_active_turn_undead() -> Dictionary:
	var entry := active_entry()
	if finished:
		return {"ok": false, "reason": "The encounter is over."}
	if has_pending_decision():
		return {"ok": false, "reason": "Resolve the pending combat decision first."}
	if entry.is_empty() or int(entry["team"]) != TEAM_PARTY:
		return {"ok": false, "reason": "It is not a party member's turn."}
	var ch: Character = entry["char"]
	if ch.cleric_level() <= 0:
		return {"ok": false, "reason": "%s has no turning ability." % ch.display_name}
	if not ch.has_holy_symbol():
		return {
			"ok": false,
			"reason": "%s must present a holy symbol to turn undead." % ch.display_name,
		}
	if not is_player_turn():
		return {"ok": false, "reason": "%s cannot act." % ch.display_name}
	if bool(turn_state.get("standard_used", false)):
		return {"ok": false, "reason": "The standard action is already spent this turn."}
	if ch.turn_undead_remaining() <= 0:
		return {"ok": false, "reason": "No turning attempts remain today."}
	if turn_candidates(ch).is_empty():
		return {"ok": false, "reason": "No undead within 60 ft."}
	return {"ok": true, "reason": ""}


## One turn attempt: a standard action that does not provoke (PHB p.159).
## The attempt (and its daily use) is spent once the turning check is made.
func turn_undead() -> Dictionary:
	var blocked := _pending_guard()
	if not blocked.is_empty():
		return blocked
	var allowed := can_active_turn_undead()
	if not bool(allowed["ok"]):
		return _fail(String(allowed["reason"]))
	var entry := active_entry()
	var ch: Character = entry["char"]
	var candidates := turn_candidates(ch)
	turn_state["standard_used"] = true
	ch.consume_turn_undead()
	var cha_mod := ch.ability_mod("cha")
	var level := ch.cleric_level() + Feats.turn_level_bonus(ch)
	var check_bonus := cha_mod + ch.turn_check_bonus()
	var roll := _turn_roll(20)
	var total := roll + check_bonus
	var max_hd := Rules.turn_max_hd(level, total)
	_log("%s presents a holy symbol and turns undead." % ch.display_name)
	if Feats.turn_level_bonus(ch) > 0:
		_log("  Improved Turning: effective cleric level %d." % level)
	_log(
		"  Turning check: d20(%d)%+d = %d; can affect undead of up to %d HD."
		% [roll, check_bonus, total, max_hd]
	)
	_log(
		"  Turning attempts left today: %d/%d."
		% [ch.turn_undead_remaining(), ch.turn_undead_max_uses()]
	)
	var eligible: Array = []
	var eligible_index := {}
	for candidate in candidates:
		if int(candidate["hd"]) <= max_hd:
			eligible.append(candidate)
			eligible_index[int(candidate["index"])] = true
	if eligible.is_empty():
		_log("  Nothing in range is weak enough to be affected.")
		_after_action(ch)
		_check_end()
		changed.emit()
		return {"ok": true, "message": "Turning check %d affects no undead in range." % total}
	var die_a := _turn_roll(6)
	var die_b := _turn_roll(6)
	var capacity := Rules.turn_damage(level, cha_mod, die_a, die_b)
	_log(
		"  Turning damage: 2d6(%d, %d)%+d = %d Hit Dice."
		% [die_a, die_b, level + cha_mod, capacity]
	)
	var turned: Array[String] = []
	var destroyed: Array[String] = []
	var unaffected: Array[String] = []
	var skipped: Array[String] = []
	for candidate in candidates:
		var target: Character = candidate["char"]
		var ehd := int(candidate["hd"])
		# Already-turned undead may be skipped without spending capacity.
		if target.has_condition("turned"):
			skipped.append(target.display_name)
			continue
		if not eligible_index.has(int(candidate["index"])) or capacity < ehd:
			unaffected.append("%s (%d HD)" % [target.display_name, ehd])
			continue
		capacity -= ehd
		# Twice the cleric's level in Hit Dice or less is destroyed (PHB p.159).
		if level >= ehd * 2:
			_destroy_undead(target)
			destroyed.append(target.display_name)
			_log("  %s is destroyed (%d HD)." % [target.display_name, ehd])
		else:
			target.remove_effect("cowering")
			target.add_effect("turned", "Turned", 10, "condition")
			# Remember who turned it: only that cleric's approach within 10 ft
			# overcomes the effect (PHB p.159).
			var turned_effect := target.get_effect("turned")
			if not turned_effect.is_empty():
				turned_effect["turner_id"] = ch.id
				turned_effect["turner_name"] = ch.display_name
			turned.append(target.display_name)
			_log("  %s is turned for 10 rounds (%d HD)." % [target.display_name, ehd])
	if not turned.is_empty():
		_log("  Turned: %s." % ", ".join(turned))
	if not destroyed.is_empty():
		_log("  Destroyed: %s." % ", ".join(destroyed))
	if not skipped.is_empty():
		_log("  Skipped (already turned): %s." % ", ".join(skipped))
	if not unaffected.is_empty():
		_log("  Unaffected: %s." % ", ".join(unaffected))
	_after_action(ch)
	_check_end()
	changed.emit()
	var summary: Array[String] = []
	if not turned.is_empty():
		summary.append("turned " + ", ".join(turned))
	if not destroyed.is_empty():
		summary.append("destroyed " + ", ".join(destroyed))
	if summary.is_empty():
		summary.append("nothing affected")
	return {"ok": true, "message": "Turn undead: %s." % "; ".join(summary)}


## Disclosed rolls for tests and the QA scenario. Only the die source changes;
## modifiers and every rule outcome still come from Rules/Encounter.
var deterministic_rolls: Array[int] = []


func _turn_roll(sides: int) -> int:
	if not deterministic_rolls.is_empty():
		return clampi(int(deterministic_rolls.pop_front()), 1, sides)
	return Dice.roll(rng, 1, sides)


func _destroy_undead(target: Character) -> void:
	target.remove_effect("turned")
	target.remove_effect("cowering")
	target.take_damage(target.hp + target.max_hp + 1000)
	target.dead = true


# ---------------------------------------------------------------- enemy AI

func _run_monster_turn(entry: Dictionary) -> void:
	var ch: Character = entry["char"]
	if ch.has_condition("turned"):
		if _run_turned_turn(entry):
			return
	var targets := living_entries(TEAM_PARTY)
	if targets.is_empty():
		_check_end()
		return
	var target_entry := _nearest_target(entry, targets)
	if target_entry.is_empty():
		return
	var target: Character = target_entry["char"]
	var start_cell: Vector2i = entry["cell"]
	var adjacent := map.distance_ft(start_cell, target_entry["cell"]) <= maxi(ch.reach_ft, BattleMap.CELL_FT)
	if adjacent:
		if ch.single_actions_only:
			_monster_single_attack(entry, target_entry)
		else:
			_monster_full_attack(entry, target_entry)
		return
	var reachable := map.find_path(start_cell, target_entry["cell"], occupied_except(int(entry["index"])))
	if reachable.is_empty():
		_log("%s cannot find a path to %s." % [ch.display_name, target.display_name])
		return
	var budget := ch.speed_ft
	var moved := 0
	for i in reachable.size():
		if moved + BattleMap.CELL_FT > budget:
			break
		var next_cell: Vector2i = reachable[i]
		if next_cell == target_entry["cell"]:
			break
		_provoke_attacks_of_opportunity(int(entry["index"]), entry["cell"])
		if has_pending_decision():
			# Keep the interrupted route instead of silently dropping the rest of
			# the move; the stored plan is bounded data, not a recursive call.
			off_turn_resume = {
				"kind": "monster_move",
				"entry_index": int(entry["index"]),
				"remaining": reachable.slice(i),
				"target_index": int(target_entry["index"]),
				"attack_after": not ch.single_actions_only,
			}
			return
		if ch.has_condition("dead") or ch.has_condition("dying"):
			return
		entry["cell"] = next_cell
		moved += BattleMap.CELL_FT
		if map.distance_ft(entry["cell"], target_entry["cell"]) <= maxi(ch.reach_ft, BattleMap.CELL_FT):
			break
	_log("%s moves %d ft. toward %s." % [ch.display_name, moved, target.display_name])
	if ch.single_actions_only:
		_log("  %s can take only a single action each round." % ch.display_name)
		return
	if map.distance_ft(entry["cell"], target_entry["cell"]) <= maxi(ch.reach_ft, BattleMap.CELL_FT):
		# A full attack requires a full-round action and cannot follow a move.
		# After closing the distance, the monster gets one attack instead.
		_monster_single_attack(entry, target_entry)


## Continues the action a Cleave decision interrupted. The record is bounded data
## (remaining squares and a target), never a recursive call. The original active
## combatant keeps the turn while the decision is pending; the interrupted action
## resumes only if it is still legal, and otherwise the turn ends normally rather
## than skipping what remains.
func resume_interrupted() -> Dictionary:
	if off_turn_resume.is_empty():
		return {"ok": true, "resumed": false}
	if finished:
		off_turn_resume.clear()
		return {"ok": true, "resumed": false}
	var resume := off_turn_resume
	off_turn_resume = {}
	var resumed_index := int(resume.get("entry_index", -1))
	if resumed_index < 0 or resumed_index >= combatants.size():
		return {"ok": false, "resumed": false, "message": "The interrupted combatant is gone."}
	var entry: Dictionary = combatants[resumed_index]
	var ch: Character = entry["char"]
	var current := active_entry()
	if current.is_empty() or int(current.get("index", -1)) != resumed_index:
		_log("  The interrupted turn has already passed; nothing resumes.")
		changed.emit()
		return {"ok": true, "resumed": false}
	var guard := 0
	if (
		String(resume.get("kind", "")) == "monster_move"
		and ch.can_act()
		and not ch.has_condition("paralyzed")
	):
		var target_index := int(resume.get("target_index", -1))
		var target_entry: Dictionary = {}
		if target_index >= 0 and target_index < combatants.size():
			var candidate: Character = combatants[target_index]["char"]
			if candidate.can_act():
				target_entry = combatants[target_index]
		var steps: Array = resume.get("remaining", [])
		for i in steps.size():
			guard += 1
			if guard > 128 or finished or has_pending_decision():
				break
			if not ch.can_act():
				break
			var step: Vector2i = steps[i]
			if map.is_blocked(step) or occupied_except(resumed_index).has(step):
				_log("  The interrupted route is blocked; %s stops." % ch.display_name)
				break
			if map.distance_ft(entry["cell"], step) > BattleMap.CELL_FT:
				break
			_provoke_attacks_of_opportunity(resumed_index, entry["cell"])
			if has_pending_decision():
				off_turn_resume = {
					"kind": "monster_move",
					"entry_index": resumed_index,
					"remaining": steps.slice(i),
					"target_index": target_index,
					"attack_after": bool(resume.get("attack_after", false)),
				}
				changed.emit()
				return {"ok": true, "resumed": true, "pending": true}
			if ch.has_condition("dead") or ch.has_condition("dying"):
				break
			entry["cell"] = step
			if (
				not target_entry.is_empty()
				and map.distance_ft(entry["cell"], target_entry["cell"])
				<= maxi(ch.reach_ft, BattleMap.CELL_FT)
			):
				if bool(resume.get("attack_after", false)):
					_monster_single_attack(entry, target_entry)
				break
		if finished:
			changed.emit()
			return {"ok": true, "resumed": true}
	_log("  The interrupted turn resumes and finishes.")
	_check_end()
	if not finished:
		end_turn()
	changed.emit()
	return {"ok": true, "resumed": true}


## Turned undead flee for 10 rounds by the best legal route their movement
## allows; if they cannot increase the distance they cower instead (PHB p.159).
## Returns true when the turning behavior consumed the creature's turn.
func _run_turned_turn(entry: Dictionary) -> bool:
	var ch: Character = entry["char"]
	var effect := ch.get_effect("turned")
	var turner := _combatant_by_id(String(effect.get("turner_id", "")))
	var threat_cell: Vector2i = entry["cell"]
	var threat_name := ""
	if not turner.is_empty() and (turner["char"] as Character).can_act():
		threat_cell = turner["cell"]
		threat_name = (turner["char"] as Character).display_name
	else:
		var nearest := _nearest_target(entry, living_entries(TEAM_PARTY))
		if nearest.is_empty():
			return false
		threat_cell = nearest["cell"]
		threat_name = (nearest["char"] as Character).display_name
	var occupied := occupied_except(int(entry["index"]))
	var best_cell: Vector2i = entry["cell"]
	var best_distance := map.distance_ft(entry["cell"], threat_cell)
	var start_distance := best_distance
	# Best legal escape within one move action, around walls and occupied squares.
	for cell in map.reachable(entry["cell"], ch.speed_ft, occupied).keys():
		var candidate_distance := map.distance_ft(cell, threat_cell)
		if candidate_distance > best_distance:
			best_distance = candidate_distance
			best_cell = cell
	if best_cell != entry["cell"]:
		var path := map.find_path(entry["cell"], best_cell, occupied)
		for i in path.size():
			_provoke_attacks_of_opportunity(int(entry["index"]), entry["cell"])
			if has_pending_decision():
				off_turn_resume = {
					"kind": "monster_move",
					"entry_index": int(entry["index"]),
					"remaining": path.slice(i),
					"target_index": -1,
					"attack_after": false,
				}
				return true
			if finished or ch.has_condition("dead"):
				return true
			entry["cell"] = path[i]
		_log(
			"%s flees from %s (%d ft. to %d ft. away, %d ft. of movement)."
			% [ch.display_name, threat_name, start_distance, best_distance, path.size() * BattleMap.CELL_FT]
		)
		return true
	# No legal route increases the distance this turn (cornered, blocked, or out
	# of movement): it cowers. The condition lasts until its next turn, when it
	# tries to flee again if the turning still holds.
	ch.remove_effect("cowering")
	ch.add_effect("cowering", "Cowering", 1, "condition")
	_log(
		"%s cannot flee from %s and cowers (+2 to attacks against it)."
		% [ch.display_name, threat_name]
	)
	return true


func _combatant_by_id(character_id: String) -> Dictionary:
	if character_id == "":
		return {}
	for entry in combatants:
		if (entry["char"] as Character).id == character_id and not (entry["char"] as Character).has_condition("dead"):
			return entry
	return {}


## "If you approach within 10 feet of them, they overcome being turned and act
## normally. (You can stand within 10 feet without breaking the turning effect —
## you just can't approach them.)" (PHB p.159)
## Only the cleric that turned the creature matters, and only a move that crosses
## from outside 10 ft to inside 10 ft breaks it; standing close does not.
func _check_turning_approach(mover: Character, from_cell: Vector2i, to_cell: Vector2i) -> void:
	for entry in combatants:
		if int(entry["team"]) != TEAM_ENEMY:
			continue
		var target: Character = entry["char"]
		var effect := target.get_effect("turned")
		if effect.is_empty():
			continue
		if String(effect.get("turner_id", "")) != mover.id:
			continue
		var before := map.distance_ft(from_cell, entry["cell"])
		var after := map.distance_ft(to_cell, entry["cell"])
		if before > 10 and after <= 10:
			target.remove_effect("turned")
			target.remove_effect("cowering")
			_log(
				"%s overcomes the turning as %s comes within 10 ft."
				% [target.display_name, mover.display_name]
			)


func _nearest_target(entry: Dictionary, targets: Array) -> Dictionary:
	var best := {}
	var best_distance := 99999
	for target_entry in targets:
		var target_cell: Vector2i = target_entry["cell"]
		var path := map.find_path(entry["cell"], target_cell, occupied_except(int(entry["index"])))
		var score := path.size() if not path.is_empty() else 9999
		if score < best_distance:
			best_distance = score
			best = target_entry
	return best


func _monster_single_attack(entry: Dictionary, target_entry: Dictionary) -> void:
	var ch: Character = entry["char"]
	var attacks := ch.attacks if not ch.attacks.is_empty() else [_primary_weapon(ch)]
	var attack_data: Dictionary = attacks[0]
	var result := Rules.attack(
		rng,
		ch,
		target_entry["char"],
		attack_data,
		map.distance_ft(entry["cell"], target_entry["cell"]),
		{"flat_footed": is_flat_footed(int(target_entry["index"]))}
	)
	_log("%s attacks %s." % [ch.display_name, target_entry["char"].display_name])
	_log("  " + Rules.format_attack(result))
	if bool(result["hit"]):
		_apply_damage(target_entry["char"], result)
		_try_paralysis(ch, target_entry["char"], attack_data)
	_check_end()


func _monster_full_attack(entry: Dictionary, target_entry: Dictionary) -> void:
	var ch: Character = entry["char"]
	_log("%s makes a full attack against %s." % [ch.display_name, target_entry["char"].display_name])
	var attacks := ch.attacks if not ch.attacks.is_empty() else [_primary_weapon(ch)]
	for attack_data in attacks:
		if target_entry["char"].has_condition("dead"):
			break
		var result := Rules.attack(
			rng,
			ch,
			target_entry["char"],
			attack_data,
			map.distance_ft(entry["cell"], target_entry["cell"]),
			{"flat_footed": is_flat_footed(int(target_entry["index"]))}
		)
		result["nonlethal"] = bool(attack_data.get("nonlethal", false))
		_log("  " + Rules.format_attack(result))
		if bool(result["hit"]):
			_apply_damage(target_entry["char"], result)
			_try_paralysis(ch, target_entry["char"], attack_data)
	_check_end()


# ---------------------------------------------------------------- resolution

func _after_action(ch: Character) -> void:
	# A pending Combat Expertise choice cannot survive the standard action that
	# would have carried the qualifying melee attack. The attack path commits it
	# before this helper runs; spells, items, turning and other standard actions
	# arrive here with no melee attack and discard the unused declaration.
	if bool(turn_state.get("standard_used", false)):
		var entry := entry_for(ch)
		if not entry.is_empty():
			var index := int(entry["index"])
			if combat_expertise_pending.has(index):
				combat_expertise_pending.erase(index)
				_log("  %s's pending Combat Expertise expires without a melee attack." % ch.display_name)
			if fight_defensively_selected.has(index):
				fight_defensively_selected.erase(index)
				_log("  %s's defensive selection expires without an attack." % ch.display_name)
	if ch.has_condition("disabled"):
		var wound := ch.take_damage(1)
		_log("  %s is disabled and takes 1 damage after acting." % ch.display_name)
		if bool(wound["died"]):
			_log("  %s is dead." % ch.display_name)


func _check_end() -> void:
	if finished:
		return
	# "Cannot act this instant" is not the same as "defeated". Paralysis from a
	# ghoul's attack lasts 1d4+1 rounds and expires by itself, and a temporary
	# unconsciousness effect can end, so both keep the encounter running with the
	# affected combatants' turns skipped. Only these remove a combatant from the
	# fight for good: death/destruction, and the supported nonlethal knockout - a
	# nonlethal total above current hit points making the creature unconscious and
	# helpless (PHB p.147).
	var any_enemy := false
	for entry in combatants:
		if int(entry["team"]) == TEAM_ENEMY and not _enemy_defeated(entry["char"]):
			any_enemy = true
			break
	var any_party := false
	for entry in combatants:
		if int(entry["team"]) == TEAM_PARTY and not _party_defeated(entry["char"]):
			any_party = true
			break
	if not any_enemy:
		finish("victory")
	elif not any_party:
		finish("defeat")


## An enemy is out of the fight for good when it is dead/destroyed or knocked out
## by the supported nonlethal path. Paralysis and timed unconsciousness are
## deliberately excluded: they are recoverable states, not defeat.
func _enemy_defeated(ch: Character) -> bool:
	return ch.has_condition("dead") or ch.has_condition("nonlethal_unconscious")


## The party has lost when no member can recover on its own: dead, dying,
## stabilized-but-unconscious, or nonlethally knocked out. A wholly paralysed
## party is *not* defeated - its turns are skipped until the paralysis expires.
func _party_defeated(ch: Character) -> bool:
	return (
		ch.has_condition("dead")
		or ch.has_condition("dying")
		or ch.has_condition("stable")
		or ch.has_condition("nonlethal_unconscious")
	)


func finish(result: String) -> void:
	if finished:
		return
	finished = true
	outcome = result
	# Encounter termination is a legitimate cancellation: the paused choice can
	# no longer happen, so it is void. It is logged rather than silently cleared.
	if not pending_trip.is_empty() or not pending_cleave.is_empty():
		pending_trip.clear()
		pending_cleave.clear()
		_log("The encounter ends; any pending combat decision is void and has no effect.")
	off_turn_resume.clear()
	_clear_combat_expertise_states()
	_log("")
	match result:
		"victory":
			_log("VICTORY — all enemies are destroyed or defeated.")
		"defeat":
			_log("DEFEAT — the party can no longer fight.")
		_:
			_log("Encounter ended: %s" % result)
	changed.emit()


func get_log_text() -> String:
	return "\n".join(log_lines)


func status_summary() -> String:
	var lines: Array[String] = []
	for i in order:
		var entry: Dictionary = combatants[i]
		var ch: Character = entry["char"]
		var marker := "▶" if order[turn_ptr] == i else " "
		lines.append(
			"%s %s (init %d, %s) — %s"
			% [
				marker,
				ch.display_name,
				int(entry["initiative"]),
				"party" if int(entry["team"]) == TEAM_PARTY else "enemy",
				"%d/%d HP%s" % [ch.hp, ch.max_hp, " — DEAD" if ch.has_condition("dead") else ""],
			]
		)
	return "\n".join(lines)
