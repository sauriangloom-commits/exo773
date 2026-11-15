class_name Character
extends RefCounted

## A player character or monster.
##
## The same model serves both sides of combat so Rules/Encounter stay
## symmetric. Monsters simply carry natural attacks and no class skills.

var id := ""
var display_name := ""
var race := ""
var char_class := ""
var level := 1
var abilities: Dictionary = {"str": 10, "dex": 10, "con": 10, "int": 10, "wis": 10, "cha": 10}
var base_attack := 0
var base_saves: Dictionary = {"fort": 0, "ref": 0, "will": 0}
var max_hp := 1
var hp := 1
var temp_hp := 0
## Nonlethal damage (PHB p.139) is tracked separately and compared with current hit
## points; it never reduces hp directly. Undead and constructs are immune.
var nonlethal := 0
var speed_ft := 30
# Size category is the authoritative size data (PHB glossary p.312).
# `size_ac` is only its cached modifier and is recomputed on load.
var size_category := "medium"
var size_ac := 0
# Explicit trip properties (PHB p.158). Stability is the defender's +4 bonus
# for "more than two legs or otherwise more stable"; it is authored per
# creature and never inferred from a name, tag or monster type.
var stability_bonus := 0
var trip_immune := false
var ac_misc := 0
var natural_armor := 0
var skill_ranks: Dictionary = {}
var feats: Array[String] = []
## Authored weapon/armor/shield proficiency categories or exact item names.
## Class categories are authored, not inferred at runtime; proficiency feats
## add grants on top in `Feats.granted_proficiencies`.
var proficiencies: Array[String] = []
## Version 2 stores armor/shield categories explicitly. Older saves are
## migrated from their class once so they do not become retroactively
## non-proficient when the penalty rules are introduced.
var proficiency_schema := 2
var equipment: Dictionary = {}  # slot -> item data dictionary
var inventory: Array = []  # [{id, qty, item}]
var spells: Dictionary = {}
var effects: Array = []  # [{id, name, rounds_left, kind}]
var attacks: Array = []  # monster natural attacks [{name, ...weapon fields}]
var is_monster := false
var monster_type := ""
var challenge_rating := ""
var xp := 0
var tags: Array[String] = []
var portrait_hint := ""
var notes := ""
var dead := false
var damage_reduction: Dictionary = {}  # {amount:int, bypass:[damage types]}
var immunities: Array[String] = []
var single_actions_only := false
var sneak_attack_dice := ""
var reach_ft := 5
var finesse := false
var destroyed_at_zero := false
# Explicit undead statistics (never inferred from hit points). A monster's
# Hit Dice come from its stat block; turn resistance is a separate quality.
var hit_dice := 0
var turn_resistance := 0
# Daily turning attempts spent. Effective uses are 3 + Cha modifier (PHB p.159).
var turn_undead_used := 0

const SLOTS := ["weapon", "armor", "shield"]


func ability_mod(ability: String) -> int:
	return Rules.ability_mod(int(abilities.get(ability, 10)))


func is_alive() -> bool:
	return not has_condition("dead")


func is_conscious() -> bool:
	return not (
		has_condition("unconscious")
		or has_condition("nonlethal_unconscious")
		or has_condition("dying")
		or has_condition("dead")
	)


func can_act() -> bool:
	return is_conscious() and not has_condition("dead")


func has_condition(condition_id: String) -> bool:
	for effect in effects:
		if String(effect.get("id", "")) == condition_id:
			return true
	return false


func has_effect(effect_id: String) -> bool:
	return has_condition(effect_id)


## Prone is a condition with no duration (PHB Table 8-6, printed p.151); it is
## ended by standing up, not by time.
func is_prone() -> bool:
	return has_condition("prone")


func set_prone(value: bool) -> void:
	if value:
		add_effect("prone", "Prone", -1)
	else:
		remove_effect("prone")


func is_undead() -> bool:
	if tags.has("undead"):
		return true
	return monster_type.to_lower().begins_with("undead")


## Cleric level used by turning. Non-clerics have no turning ability here.
func cleric_level() -> int:
	return level if char_class.to_lower() == "cleric" else 0


## 3 + Charisma modifier attempts per day (PHB p.159), plus four for each
## prerequisite-valid Extra Turning feat (PHB p.94).
func turn_undead_max_uses() -> int:
	if cleric_level() <= 0:
		return 0
	return maxi(0, 3 + ability_mod("cha") + Feats.extra_turning_uses(self))


func turn_undead_remaining() -> int:
	return maxi(0, turn_undead_max_uses() - turn_undead_used)


## +2 on turning checks with 5 or more ranks in Knowledge (religion)
## (PHB p.33, Cleric class features). Routed through the shared synergy table.
func turn_check_bonus() -> int:
	return Skills.synergy_bonus(self, "turn_undead")


func consume_turn_undead() -> bool:
	if turn_undead_remaining() <= 0:
		return false
	turn_undead_used += 1
	return true


## Hit Dice used to resolve a turn attempt. Turn resistance is added to the
## creature's Hit Dice total for that purpose only (MM glossary, "Turn
## Resistance"). Actual Hit Dice are never derived from current or maximum HP.
func turn_effective_hd() -> int:
	if hit_dice <= 0:
		return 0
	return hit_dice + turn_resistance


func get_effect(effect_id: String) -> Dictionary:
	for effect in effects:
		if String(effect.get("id", "")) == effect_id:
			return effect
	return {}


func add_effect(effect_id: String, effect_name: String, rounds_left: int, kind := "condition") -> bool:
	var existing := get_effect(effect_id)
	if not existing.is_empty():
		# Same-named effects do not stack (PHB p.153 on stacking bonuses).
		if rounds_left > 0:
			existing["rounds_left"] = maxi(int(existing.get("rounds_left", 0)), rounds_left)
		return false
	effects.append(
		{
			"id": effect_id,
			"name": effect_name,
			"rounds_left": rounds_left,
			"kind": kind,
		}
	)
	return true


func remove_effect(effect_id: String) -> void:
	for i in range(effects.size() - 1, -1, -1):
		if String(effects[i].get("id", "")) == effect_id:
			effects.remove_at(i)


## Decrements timed effects. Returns the ids that expired.
func tick_effects() -> Array[String]:
	var expired: Array[String] = []
	for i in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[i]
		var rounds := int(effect.get("rounds_left", -1))
		if rounds < 0:
			continue
		rounds -= 1
		effect["rounds_left"] = rounds
		if rounds <= 0:
			var expired_id := String(effect.get("id", ""))
			if expired_id == "aid":
				# Remaining temporary hit points from aid vanish with its duration.
				temp_hp = 0
			expired.append(expired_id)
			effects.remove_at(i)
	return expired


func equipped(slot: String) -> Dictionary:
	return equipment.get(slot, {})


func equip(slot: String, item: Dictionary) -> void:
	if not SLOTS.has(slot):
		return
	equipment[slot] = item.duplicate(true)


func unequip(slot: String) -> void:
	if SLOTS.has(slot):
		equipment.erase(slot)


func add_to_inventory(item: Dictionary, qty := 1) -> void:
	for entry in inventory:
		if String(entry.get("id", "")) == String(item.get("id", "")):
			entry["qty"] = int(entry.get("qty", 0)) + qty
			return
	inventory.append({"id": String(item.get("id", "")), "qty": qty, "item": item.duplicate(true)})


func remove_from_inventory(item_id: String, qty := 1) -> bool:
	for i in inventory.size():
		var entry: Dictionary = inventory[i]
		if String(entry.get("id", "")) == item_id:
			var have := int(entry.get("qty", 0))
			if have < qty:
				return false
			entry["qty"] = have - qty
			if int(entry["qty"]) <= 0:
				inventory.remove_at(i)
			return true
	return false


func inventory_count(item_id: String) -> int:
	var total := 0
	for entry in inventory:
		if String(entry.get("id", "")) == item_id:
			total += int(entry.get("qty", 0))
	return total


## PHB p.159: "You must present your holy symbol to turn undead."
## Weapons the character has equipped or carries within easy reach (inventory).
## The combat screen lists these; equipping still goes through the encounter so
## that drawing costs its move action (PHB p.142).
func carried_weapons() -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	var equipped: Dictionary = equipment.get("weapon", {})
	if not equipped.is_empty():
		var equipped_id := String(equipped.get("id", ""))
		seen[equipped_id] = true
		result.append(
			{
				"id": equipped_id,
				"name": String(equipped.get("name", equipped_id)),
				"equipped": true,
				"item": equipped,
			}
		)
	for entry in inventory:
		var item: Dictionary = entry.get("item", {})
		if String(item.get("kind", "")) != "weapon":
			continue
		var item_id := String(item.get("id", ""))
		if item_id == "" or seen.has(item_id):
			continue
		seen[item_id] = true
		result.append(
			{
				"id": item_id,
				"name": String(item.get("name", item_id)),
				"equipped": false,
				"item": item,
			}
		)
	return result


## The carried weapon with this id, or an empty dictionary.
func carried_weapon(item_id: String) -> Dictionary:
	for row in carried_weapons():
		if String(row["id"]) == item_id:
			return Dictionary(row["item"])
	return {}

## Shields the character can strap on: the readied one plus those carried in
## inventory (PHB p.142 - only a strapped shield grants its bonus).
func carried_shields() -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	var readied: Dictionary = equipment.get("shield", {})
	if not readied.is_empty():
		var readied_id := String(readied.get("id", ""))
		seen[readied_id] = true
		result.append(
			{
				"id": readied_id,
				"name": String(readied.get("name", readied_id)),
				"equipped": true,
				"item": readied,
			}
		)
	for entry in inventory:
		var item: Dictionary = entry.get("item", {})
		if String(item.get("kind", "")) != "shield":
			continue
		var item_id := String(item.get("id", ""))
		if item_id == "" or seen.has(item_id):
			continue
		seen[item_id] = true
		result.append(
			{
				"id": item_id,
				"name": String(item.get("name", item_id)),
				"equipped": false,
				"item": item,
			}
		)
	return result



## The symbol stays in inventory; presenting it does not consume the item.
func has_holy_symbol() -> bool:
	return inventory_count("holy_symbol") > 0


func find_inventory_entry(item_id: String) -> Dictionary:
	for entry in inventory:
		if String(entry.get("id", "")) == item_id:
			return entry
	return {}


## PHB p.147: nonlethal damage is a running total that is never deducted from hit
## points. "When your nonlethal damage equals your current hit points, you're
## staggered, and when it exceeds your current hit points, you fall unconscious."
## The comparison is against *current* hit points, so losing hit points can cross
## a threshold and healing can retreat back over it.
##
## Zero nonlethal damage never creates a state: a character at 0 hit points is
## already disabled, and "0 nonlethal equals 0 hit points" is not a staggered
## condition (the printed rules describe roughness, not the disabled state).
func nonlethal_state() -> String:
	if nonlethal <= 0:
		return "none"
	if nonlethal > hp:
		return "unconscious"
	if nonlethal == hp:
		return "staggered"
	return "none"


## Keeps the derived conditions in step with the numeric state. Staggered and
## nonlethal unconsciousness use their own effect ids so that clearing them can
## never erase a different reason the character cannot act (dying, paralysis,
## a spell's unconsciousness, death).
func refresh_nonlethal_state() -> void:
	if dead or hp <= -10:
		remove_effect("staggered")
		remove_effect("nonlethal_unconscious")
		return
	match nonlethal_state():
		"unconscious":
			remove_effect("staggered")
			add_effect("nonlethal_unconscious", "Unconscious (nonlethal damage)", -1)
		"staggered":
			remove_effect("nonlethal_unconscious")
			add_effect("staggered", "Staggered (nonlethal damage)", -1)
		_:
			remove_effect("nonlethal_unconscious")
			remove_effect("staggered")


## PHB p.139: "All damage from unarmed strikes is nonlethal damage." Immunity
## belongs to the creature, so callers check it first.
func apply_nonlethal(amount: int) -> Dictionary:
	var result := {"applied": 0, "staggered": false, "unconscious": false}
	if amount <= 0 or dead:
		return result
	nonlethal += amount
	result["applied"] = amount
	refresh_nonlethal_state()
	result["staggered"] = has_condition("staggered")
	result["unconscious"] = has_condition("nonlethal_unconscious")
	return result


## PHB p.147: "When a spell or a magical power cures hit point damage, it also
## removes an equal amount of nonlethal damage." The nonlethal removal is keyed to
## the amount the effect cures, not to the hit points actually restored: a
## full-hit-point target with nonlethal damage still benefits.
func magical_heal(amount: int) -> Dictionary:
	var result := {"healed": 0, "nonlethal_removed": 0}
	if amount <= 0 or dead:
		return result
	result["healed"] = heal(amount)
	var removed := mini(amount, nonlethal)
	if removed > 0:
		nonlethal -= removed
		result["nonlethal_removed"] = removed
	refresh_nonlethal_state()
	return result


func take_damage(amount: int) -> Dictionary:
	# Losing hit points can cross a nonlethal threshold in either direction
	# (PHB p.147), so the derived state is refreshed after every damage event.
	var result := _take_damage_unchecked(amount)
	refresh_nonlethal_state()
	return result


func _take_damage_unchecked(amount: int) -> Dictionary:
	var result := {"damage": amount, "temp_absorbed": 0, "dropped": false, "died": false}
	if amount <= 0:
		return result
	var remaining := amount
	if temp_hp > 0:
		var absorbed := mini(temp_hp, remaining)
		temp_hp -= absorbed
		remaining -= absorbed
		result["temp_absorbed"] = absorbed
	if remaining <= 0:
		return result
	hp -= remaining
	if destroyed_at_zero and hp <= 0:
		# Undead and constructs are destroyed at 0 hit points; they do not go
		# through the dying/stabilization rules (MM p.317 undead traits).
		hp = mini(hp, 0)
		add_effect("dead", "Destroyed", -1)
		remove_effect("dying")
		remove_effect("stable")
		remove_effect("disabled")
		dead = true
		result["died"] = true
		result["dropped"] = true
		return result
	if hp <= -10:
		hp = -10
		add_effect("dead", "Dead", -1)
		remove_effect("dying")
		remove_effect("stable")
		remove_effect("disabled")
		add_effect("unconscious", "Unconscious", -1)
		dead = true
		result["died"] = true
	elif hp <= -1:
		add_effect("dying", "Dying", -1)
		add_effect("unconscious", "Unconscious", -1)
		remove_effect("disabled")
		result["dropped"] = true
	elif hp == 0:
		add_effect("disabled", "Disabled", -1)
		result["dropped"] = true
	return result


func heal(amount: int) -> int:
	if amount <= 0 or dead:
		return 0
	var before := hp
	hp = mini(max_hp, hp + amount)
	# Any healing stops a dying character's hit point loss (PHB p.145).
	remove_effect("dying")
	if hp > 0:
		remove_effect("unconscious")
		remove_effect("disabled")
		remove_effect("stable")
	elif hp == 0:
		# Healing to exactly 0 leaves the character disabled, not stable and
		# unconscious; 0 HP is a conscious but fragile state (PHB p.145).
		remove_effect("unconscious")
		remove_effect("stable")
		add_effect("disabled", "Disabled", -1)
	else:
		add_effect("unconscious", "Unconscious", -1)
		add_effect("stable", "Stable (unconscious)", -1)
		remove_effect("disabled")
	refresh_nonlethal_state()
	return hp - before


func stabilize() -> void:
	if has_condition("dying"):
		remove_effect("dying")
		add_effect("stable", "Stable (unconscious)", -1)


func rest() -> void:
	if dead:
		return
	hp = max_hp
	temp_hp = 0
	remove_effect("dying")
	remove_effect("unconscious")
	remove_effect("stable")
	remove_effect("disabled")
	remove_effect("paralyzed")
	# A full night's rest is eight hours; nonlethal damage heals at 1 point per
	# hour per character level (PHB p.147), which clears any ordinary total. The
	# hourly schedule itself is not modelled, so rest clears the total instead of
	# pretending to track elapsed hours.
	nonlethal = 0
	refresh_nonlethal_state()
	turn_undead_used = 0
	for effect_id in ["bless", "mage_armor", "aid"]:
		remove_effect(effect_id)
	var prepared: Dictionary = spells.get("daily_prepared", {})
	var slots: Dictionary = spells.get("slots", {})
	for key in slots.keys():
		slots[key]["used"] = 0
	if not prepared.is_empty():
		spells["prepared"] = prepared.duplicate(true)


func spell_slots_remaining(spell_level: int) -> int:
	var slot: Dictionary = spells.get("slots", {}).get(str(spell_level), {})
	return int(slot.get("max", 0)) - int(slot.get("used", 0))


func can_cast(spell_level: int, spell_id: String) -> bool:
	if spell_slots_remaining(spell_level) <= 0:
		return false
	if bool(spells.get("spontaneous", false)):
		return Array(spells.get("known", [])).has(spell_id)
	var prepared: Array = spells.get("prepared", {}).get(str(spell_level), [])
	return prepared.has(spell_id)


func consume_spell(spell_level: int, spell_id: String) -> bool:
	if not can_cast(spell_level, spell_id):
		return false
	var slots: Dictionary = spells.get("slots", {})
	slots[str(spell_level)]["used"] = int(slots[str(spell_level)].get("used", 0)) + 1
	if not bool(spells.get("spontaneous", false)):
		var prepared: Array = spells.get("prepared", {}).get(str(spell_level), [])
		prepared.erase(spell_id)
	return true


## Legacy save migration: class armor/shield categories were not stored before
## proficiency_schema 2. Add them once; exact/custom entries are preserved.
func apply_legacy_proficiency_defaults() -> void:
	var defaults: Array[String] = []
	match char_class.to_lower():
		"fighter":
			defaults = ["simple", "martial", "light_armor", "medium_armor", "heavy_armor", "shield"]
		"rogue":
			defaults = ["simple", "light_armor", "shield"]
		"cleric":
			defaults = ["simple", "light_armor", "medium_armor", "heavy_armor", "shield"]
		"wizard":
			defaults = ["club", "dagger", "heavy_crossbow", "light_crossbow", "quarterstaff"]
		"sorcerer":
			defaults = ["simple"]
	for value in defaults:
		if not proficiencies.has(value):
			proficiencies.append(value)


func total_attack_bonus(weapon: Dictionary = {}) -> int:
	return Rules.attack_bonus(self, weapon, 0)


func ac() -> int:
	return Rules.armor_class(self)


func touch_ac() -> int:
	return Rules.touch_ac(self)


func display_class() -> String:
	if is_monster:
		return monster_type.capitalize()
	if char_class == "":
		return "Adventurer"
	return "%s %d" % [char_class, level]


func summary_line() -> String:
	var status := ""
	if has_condition("dead"):
		status = " [DEAD]"
	elif has_condition("dying"):
		status = " [DYING]"
	elif has_condition("stable"):
		status = " [STABLE]"
	elif has_condition("unconscious"):
		status = " [UNCONSCIOUS]"
	elif has_condition("disabled"):
		status = " [DISABLED]"
	return "%s — %s, HP %d/%d%s" % [display_name, display_class(), hp, max_hp, status]


## Serializes IDs only; GameSession rehydrates item and spell data on load.
func to_dict() -> Dictionary:
	var equipment_ids := {}
	for slot in equipment.keys():
		equipment_ids[slot] = String(equipment[slot].get("id", ""))
	var inv: Array = []
	for entry in inventory:
		inv.append({"id": String(entry.get("id", "")), "qty": int(entry.get("qty", 0))})
	return {
		"id": id,
		"name": display_name,
		"race": race,
		"class": char_class,
		"level": level,
		"abilities": abilities.duplicate(true),
		"base_attack": base_attack,
		"base_saves": base_saves.duplicate(true),
		"max_hp": max_hp,
		"hp": hp,
		"temp_hp": temp_hp,
		"nonlethal": nonlethal,
		"speed_ft": speed_ft,
		"size_ac": size_ac,
		"size_category": size_category,
		"stability_bonus": stability_bonus,
		"trip_immune": trip_immune,
		"ac_misc": ac_misc,
		"natural_armor": natural_armor,
		"skill_ranks": skill_ranks.duplicate(true),
		"feats": feats.duplicate(),
		"proficiencies": proficiencies.duplicate(),
		"proficiency_schema": proficiency_schema,
		"equipment": equipment_ids,
		"inventory": inv,
		"spells": spells.duplicate(true),
		"effects": effects.duplicate(true),
		"attacks": attacks.duplicate(true),
		"is_monster": is_monster,
		"monster_type": monster_type,
		"challenge_rating": challenge_rating,
		"xp": xp,
		"tags": tags.duplicate(),
		"portrait_hint": portrait_hint,
		"notes": notes,
		"dead": dead,
		"damage_reduction": damage_reduction.duplicate(true),
		"immunities": immunities.duplicate(),
		"single_actions_only": single_actions_only,
		"sneak_attack_dice": sneak_attack_dice,
		"reach_ft": reach_ft,
		"finesse": finesse,
		"destroyed_at_zero": destroyed_at_zero,
		"hit_dice": hit_dice,
		"turn_resistance": turn_resistance,
		"turn_undead_used": turn_undead_used,
	}


static func from_dict(data: Dictionary, items_by_id: Dictionary) -> Character:
	var ch := Character.new()
	ch.id = String(data.get("id", ""))
	ch.display_name = String(data.get("name", "Unknown"))
	ch.race = String(data.get("race", ""))
	ch.char_class = String(data.get("class", ""))
	ch.level = int(data.get("level", 1))
	ch.abilities = Dictionary(data.get("abilities", {})).duplicate(true)
	ch.base_attack = int(data.get("base_attack", 0))
	ch.base_saves = Dictionary(data.get("base_saves", {})).duplicate(true)
	ch.max_hp = int(data.get("max_hp", 1))
	ch.hp = int(data.get("hp", ch.max_hp))
	ch.temp_hp = int(data.get("temp_hp", 0))
	ch.nonlethal = int(data.get("nonlethal", 0))
	ch.speed_ft = int(data.get("speed_ft", 30))
	var authored_size := String(data.get("size_category", "")).to_lower()
	if authored_size == "":
		# Legacy saves and older content authored only the derived modifier.
		authored_size = Rules.size_category_for_modifier(int(data.get("size_ac", 0)))
	ch.size_category = Rules.normalize_size_category(authored_size)
	# The category is authoritative; this cached value keeps AC, attack and
	# Hide calculations consistent without a second source of truth.
	ch.size_ac = Rules.size_modifier(ch.size_category)
	ch.stability_bonus = int(data.get("stability_bonus", 0))
	ch.trip_immune = bool(data.get("trip_immune", false))
	ch.ac_misc = int(data.get("ac_misc", 0))
	ch.natural_armor = int(data.get("natural_armor", 0))
	ch.skill_ranks = Dictionary(data.get("skill_ranks", {})).duplicate(true)
	ch.feats.assign(data.get("feats", []))
	ch.proficiencies.assign(data.get("proficiencies", []))
	ch.proficiency_schema = int(data.get("proficiency_schema", 1))
	if ch.proficiency_schema < 2:
		ch.apply_legacy_proficiency_defaults()
		ch.proficiency_schema = 2
	ch.spells = Dictionary(data.get("spells", {})).duplicate(true)
	ch.effects = Array(data.get("effects", [])).duplicate(true)
	ch.attacks = Array(data.get("attacks", [])).duplicate(true)
	ch.is_monster = bool(data.get("is_monster", false))
	ch.monster_type = String(data.get("monster_type", ""))
	ch.challenge_rating = String(data.get("challenge_rating", ""))
	ch.xp = int(data.get("xp", 0))
	ch.tags.assign(data.get("tags", []))
	ch.portrait_hint = String(data.get("portrait_hint", ""))
	ch.notes = String(data.get("notes", ""))
	ch.dead = bool(data.get("dead", false))
	ch.damage_reduction = Dictionary(data.get("damage_reduction", {})).duplicate(true)
	ch.immunities.assign(data.get("immunities", []))
	ch.single_actions_only = bool(data.get("single_actions_only", false))
	ch.sneak_attack_dice = String(data.get("sneak_attack_dice", ""))
	ch.reach_ft = int(data.get("reach_ft", 5))
	ch.finesse = bool(data.get("finesse", false))
	ch.destroyed_at_zero = bool(data.get("destroyed_at_zero", false))
	ch.hit_dice = int(data.get("hit_dice", 0))
	ch.turn_resistance = int(data.get("turn_resistance", 0))
	ch.turn_undead_used = int(data.get("turn_undead_used", 0))
	var equipment_ids: Dictionary = data.get("equipment", {})
	for slot in equipment_ids.keys():
		var item: Dictionary = items_by_id.get(String(equipment_ids[slot]), {})
		if not item.is_empty():
			ch.equipment[slot] = item.duplicate(true)
	for entry in Array(data.get("inventory", [])):
		var item_id := String(entry.get("id", ""))
		var item: Dictionary = items_by_id.get(item_id, {})
		if not item.is_empty():
			ch.inventory.append(
				{"id": item_id, "qty": int(entry.get("qty", 1)), "item": item.duplicate(true)}
			)
	# Older saves predate the nonlethal field; `.get` already defaults the total to
	# zero, and the derived conditions are rebuilt so a save never depends on having
	# stored them.
	ch.refresh_nonlethal_state()
	return ch


## Builds a character from authored content.
## items_by_id: id -> item data.
static func from_content(data: Dictionary, items_by_id: Dictionary) -> Character:
	var payload := data.duplicate(true)
	payload["equipment"] = data.get("equipment", {})
	payload["inventory"] = data.get("inventory", [])
	# Authored content already declares the complete list; do not run the
	# legacy class migration on it.
	payload["proficiency_schema"] = int(data.get("proficiency_schema", 2))
	var ch := from_dict(payload, items_by_id)
	# Toughness adds +3 hit points when the character enters play. Authored
	# monster HP already includes the feat (for example the infected zombie),
	# so those stat blocks set hp_includes_feats to avoid a second +3.
	if not bool(data.get("hp_includes_feats", false)):
		var feat_hp := Feats.hit_point_bonus(ch)
		if feat_hp != 0:
			ch.max_hp += feat_hp
			if ch.hp > 0:
				ch.hp = mini(ch.max_hp, ch.hp + feat_hp)
	return ch
