class_name Rules
extends RefCounted

## D&D 3.5 rules calculations used by the vertical slice.
##
## Supported scope is documented in docs/SUPPORTED_FEATURES.md and traced to
## source pages in docs/TRACEABILITY.md. Anything not modelled here is either
## authored as content data or listed as deferred.

const ABILITIES := ["str", "dex", "con", "int", "wis", "cha"]

## PHB glossary "size modifier" (printed p. 312): a creature's size category
## yields a modifier to Armor Class and attack rolls. The progression is the
## same one printed for size-dependent checks on pp. 76 and 101. Size category
## is authored data; `Character.size_ac` is only its cached derived value.
const SIZE_CATEGORIES := {
	"fine": 8,
	"diminutive": 4,
	"tiny": 2,
	"small": 1,
	"medium": 0,
	"large": -1,
	"huge": -2,
	"gargantuan": -4,
	"colossal": -8,
}
const SIZE_ORDER := [
	"fine", "diminutive", "tiny", "small", "medium", "large", "huge", "gargantuan", "colossal"
]


static func is_valid_size_category(category: String) -> bool:
	return SIZE_CATEGORIES.has(category.to_lower())


static func normalize_size_category(category: String) -> String:
	var value := category.to_lower()
	return value if SIZE_CATEGORIES.has(value) else "medium"


static func size_modifier(category: String) -> int:
	return int(SIZE_CATEGORIES.get(normalize_size_category(category), 0))


## Legacy saves and older content authored only `size_ac`. Recover its size
## category so the category, not the cached modifier, stays authoritative.
static func size_category_for_modifier(modifier: int) -> String:
	for category in SIZE_ORDER:
		if int(SIZE_CATEGORIES[category]) == modifier:
			return category
	return "medium"


## Signed distance in size categories from Medium. Trip's +-4 per category
## bonus is based on this relationship (PHB p. 158).
static func size_category_steps(category: String) -> int:
	return SIZE_ORDER.find(normalize_size_category(category)) - SIZE_ORDER.find("medium")


## Grapple's special size modifier (PHB p.155): +16 for Colossal down to -16 for
## Fine, four points per size category away from Medium. This is not the size AC
## modifier in SIZE_CATEGORIES; it is derived from the same category order.
static func grapple_size_modifier(category: String) -> int:
	return 4 * size_category_steps(category)

## Skill data (key ability, armor multiplier, trained-only, synergies) lives
## in Skills.CATALOG. Rules keeps only the shared check and stacking formulas.


static func ability_mod(score: int) -> int:
	# PHB Table 1-1 (printed p.8): modifier = floor((score - 10) / 2).
	return floori((float(score) - 10.0) / 2.0)


static func ability_modifier(ch: Character, ability: String) -> int:
	return ability_mod(int(ch.abilities.get(ability, 10)))


## PHB p.153 stacking: bonuses of the same type do not stack (keep the best),
## while penalties of the same type do stack. Dodge bonuses always stack;
## circumstance bonuses stack when they come from different sources; untyped
## bonuses stack. entries: [{value:int, type:String, source:String}]
static func stack_bonuses(entries: Array) -> Dictionary:
	var chosen: Array = []
	var untyped := 0
	var dodge := 0
	var typed: Dictionary = {}
	var typed_order: Array[String] = []
	var circumstance_sources: Dictionary = {}
	for raw in entries:
		var entry: Dictionary = raw
		var value := int(entry.get("value", 0))
		if value == 0:
			continue
		var value_type := String(entry.get("type", "untyped")).to_lower()
		var source := String(entry.get("source", ""))
		if value_type == "" or value_type == "untyped":
			untyped += value
			chosen.append({"value": value, "type": "untyped", "source": source})
		elif value_type == "dodge":
			dodge += value
			chosen.append({"value": value, "type": "dodge", "source": source})
		elif value_type == "circumstance":
			if circumstance_sources.has(source):
				continue
			circumstance_sources[source] = true
			chosen.append({"value": value, "type": "circumstance", "source": source})
		elif value < 0:
			if typed.has(value_type):
				typed[value_type]["value"] = int(typed[value_type]["value"]) + value
				typed[value_type]["source"] = "%s, %s" % [typed[value_type]["source"], source]
			else:
				typed[value_type] = {"value": value, "type": value_type, "source": source}
				typed_order.append(value_type)
		elif not typed.has(value_type) or value > int(typed[value_type]["value"]):
			if not typed.has(value_type):
				typed_order.append(value_type)
			typed[value_type] = {"value": value, "type": value_type, "source": source}
	for value_type in typed_order:
		chosen.append(typed[value_type])
	var total := 0
	for entry in chosen:
		total += int(entry["value"])
	return {"total": total, "entries": chosen}


static func skill_total(ch: Character, skill: String, opts: Dictionary = {}) -> int:
	return Skills.total(ch, skill, opts)


static func armor_check_penalty(ch: Character) -> int:
	var penalty := 0
	for slot in ["armor", "shield"]:
		var item: Dictionary = ch.equipment.get(slot, {})
		penalty += int(item.get("armor_check_penalty", 0))
	return penalty


## Armor check penalty for one skill. A proficient wearer applies the normal
## catalog multiplier; a non-proficient wearer applies the full penalty to every
## movement skill, including Ride (PHB p.89 armor proficiency; p.100 shield).
static func skill_armor_check_penalty(ch: Character, skill: String) -> int:
	var multiplier := Skills.armor_multiplier(skill)
	if multiplier <= 0 and not Skills.is_movement_skill(skill):
		return 0
	var total := 0
	var armor: Dictionary = ch.equipment.get("armor", {})
	if not armor.is_empty():
		var armor_penalty := int(armor.get("armor_check_penalty", 0))
		if armor_penalty != 0:
			if Feats.is_armor_proficient(ch, armor):
				if multiplier > 0:
					total += armor_penalty * multiplier
			else:
				total += armor_penalty * maxi(1, multiplier)
	var shield: Dictionary = ch.equipment.get("shield", {})
	if not shield.is_empty():
		var shield_penalty := int(shield.get("armor_check_penalty", 0))
		if shield_penalty != 0:
			if Feats.is_shield_proficient(ch, shield):
				if multiplier > 0:
					total += shield_penalty * multiplier
			else:
				total += shield_penalty * maxi(1, multiplier)
	return total


## Non-proficient armor and shields apply their armor check penalty to attack
## rolls (PHB p.89 armor proficiency; p.100 shield proficiency).
static func armor_attack_penalty(ch: Character) -> int:
	var total := 0
	var armor: Dictionary = ch.equipment.get("armor", {})
	if not armor.is_empty() and not Feats.is_armor_proficient(ch, armor):
		total += int(armor.get("armor_check_penalty", 0))
	var shield: Dictionary = ch.equipment.get("shield", {})
	if not shield.is_empty() and not Feats.is_shield_proficient(ch, shield):
		total += int(shield.get("armor_check_penalty", 0))
	return total


## A manufactured weapon used without proficiency takes a -4 attack penalty.
## Natural attacks and unarmed strikes never take it (PHB p.97/100/94).
static func weapon_nonproficiency_penalty(ch: Character, weapon: Dictionary) -> int:
	if weapon.is_empty() or ch.is_monster or bool(weapon.get("natural", false)):
		return 0
	return 0 if Feats.is_weapon_proficient(ch, weapon) else -4


static func max_dex_for_armor(ch: Character) -> int:
	var armor: Dictionary = ch.equipment.get("armor", {})
	return int(armor.get("max_dex", 99))


## Effective armor bonus including mage armor (armor bonuses do not stack;
## mage armor provides a +4 armor bonus, PHB p.225).
static func armor_bonus(ch: Character) -> int:
	var bonus := int(ch.equipment.get("armor", {}).get("armor_bonus", 0))
	if ch.has_effect("mage_armor"):
		bonus = maxi(bonus, 4)
	return bonus


## Undead and constructs are immune to nonlethal damage (MM "Undead Traits",
## "Construct Traits"; PHB p.139 tracks unarmed strikes as nonlethal).
static func nonlethal_immune(ch: Character) -> bool:
	if ch == null:
		return false
	for tag in ["undead", "construct"]:
		if ch.tags.has(tag):
			return true
	var kind := String(ch.monster_type).to_lower()
	return kind.contains("undead") or kind.contains("construct")


static func shield_bonus(ch: Character) -> int:
	return int(ch.equipment.get("shield", {}).get("shield_bonus", 0))


static func is_helpless(ch: Character) -> bool:
	return (
		ch.has_condition("paralyzed")
		or ch.has_condition("unconscious")
		or ch.has_condition("nonlethal_unconscious")
		or ch.has_condition("dying")
		or ch.has_condition("dead")
	)


static func _ac_dex_bonus(ch: Character) -> int:
	if is_helpless(ch):
		# Helpless defenders have Dexterity 0, a -5 modifier, not merely no
		# Dexterity bonus (PHB p.153 and Table 8-6).
		return -5
	return mini(ability_modifier(ch, "dex"), max_dex_for_armor(ch))


## Table 8-6 (printed p. 151): a prone defender has -4 AC against melee
## attacks and +4 AC against ranged attacks. An empty attack_mode means the
## attacker's type is unknown, so no prone modifier is applied.
static func prone_ac_modifier(ch: Character, attack_mode: String) -> int:
	if not ch.is_prone():
		return 0
	var mode := attack_mode.to_lower()
	if mode == "melee":
		return -4
	if mode == "ranged" or mode == "thrown":
		return 4
	return 0


## Table 8-5 footnote 3 (printed p. 151): only a crossbow or shuriken can be
## used while prone. Content marks those weapons explicitly; names are never
## inspected to decide this.
static func prone_ranged_attack_allowed(weapon: Dictionary) -> bool:
	return bool(weapon.get("prone_usable", false))


static func armor_class(ch: Character, opts: Dictionary = {}) -> int:
	var dex_bonus := _ac_dex_bonus(ch)
	var ac := (
		10
		+ armor_bonus(ch)
		+ shield_bonus(ch)
		+ ch.natural_armor
		+ ch.ac_misc
		+ ch.size_ac
		+ dex_bonus
	)
	ac += prone_ac_modifier(ch, String(opts.get("attack_mode", "")))
	var flat_footed := bool(opts.get("flat_footed", false))
	# PHB p.156: a grappling creature loses its Dexterity bonus against opponents
	# it is not grappling. `deny_dex` is that case; it never implies flat-footed,
	# so it does not open the creature to a sneak attack.
	var deny_dex := bool(opts.get("deny_dex", false))
	# PHB p.136: "If you can't react to a blow, you can't use your Dexterity
	# bonus to AC. (If you don't have a Dexterity bonus, nothing happens.)" Only
	# a positive modifier is denied; a Dexterity penalty is not a bonus and stays.
	# Helpless already uses Dexterity 0, so it is not subtracted a second time.
	if (flat_footed or deny_dex) and not is_helpless(ch):
		ac -= maxi(0, dex_bonus)
	# Feat AC bonuses (Dodge's +1 dodge, PHB p.92). PHB p.136: "Any situation that
	# denies you your Dexterity bonus also denies you dodge bonuses." Tabletop
	# applies Dodge against one designated opponent; this slice applies it
	# generally (documented adaptation). Prerequisites are re-checked on every use.
	ac += _feat_ac_bonus(ch, flat_footed or deny_dex or is_helpless(ch))
	# Combat Expertise's dodge bonus is lost while flat-footed or helpless,
	# matching the dodge-bonus condition on PHB p.136.
	if not is_helpless(ch) and not flat_footed and not deny_dex:
		ac += Feats.combat_expertise_dodge_bonus(ch)
		ac += defensive_dodge_bonus(ch)
	# PHB p.156: a pinned creature takes -4 AC from opponents other than the one
	# pinning it. The encounter decides who that is; 0 means no penalty.
	ac -= maxi(0, int(opts.get("pinned_penalty", 0)))
	return ac


static func touch_ac(ch: Character, opts: Dictionary = {}) -> int:
	# Touch AC excludes armor, shield and natural armor, but keeps Dexterity,
	# dodge, deflection and size modifiers. Natural armor is separate from
	# ac_misc precisely so it cannot leak into touch AC.
	var dex_bonus := _ac_dex_bonus(ch)
	var ac := 10 + dex_bonus + ch.ac_misc + ch.size_ac
	ac += prone_ac_modifier(ch, String(opts.get("attack_mode", "")))
	var flat_footed := bool(opts.get("flat_footed", false))
	var deny_dex := bool(opts.get("deny_dex", false))
	# Same denial as normal AC (PHB p.136): a Dexterity penalty still applies.
	if (flat_footed or deny_dex) and not is_helpless(ch):
		ac -= maxi(0, dex_bonus)
	ac += _feat_ac_bonus(ch, flat_footed or deny_dex or is_helpless(ch))
	if not is_helpless(ch) and not flat_footed and not deny_dex:
		ac += Feats.combat_expertise_dodge_bonus(ch)
		# Touch AC keeps dodge bonuses (Rules Compendium, "Touch Attacks").
		ac += defensive_dodge_bonus(ch)
	# The printed pin penalty applies to touch AC as well.
	ac -= maxi(0, int(opts.get("pinned_penalty", 0)))
	return ac


## Dodge AC from the defensive actions (PHB p.140, p.143). Fighting defensively
## gives +2, or +3 with 5 or more Tumble ranks; total defense gives +4, or +6
## with 5 or more Tumble ranks (PHB p.84: the Tumble clause replaces the usual
## bonus). Only the active effect counts: a selection that has not been carried
## by a committed attack grants nothing. Callers apply the same dodge denial as
## Combat Expertise, so this returns nothing while Dexterity is denied.
static func defensive_dodge_bonus(ch: Character) -> int:
	var tumble := int(ch.skill_ranks.get("tumble", 0))
	if ch.has_effect("total_defense"):
		return 6 if tumble >= 5 else 4
	if ch.has_effect("fighting_defensively"):
		return 3 if tumble >= 5 else 2
	return 0


## Feat-granted AC, minus dodge bonuses when Dexterity is denied (PHB p.136).
## Non-dodge feat AC (for example a future deflection or natural-armor feat) is
## kept: the denial is about dodge bonuses specifically, never every bonus.
static func _feat_ac_bonus(ch: Character, deny_dodge: bool) -> int:
	var result := Feats.modifier(ch, "ac")
	if not deny_dodge:
		return int(result.get("total", 0))
	var total := 0
	for raw_entry in Array(result.get("entries", [])):
		var entry: Dictionary = raw_entry
		if String(entry.get("type", "untyped")).to_lower() == "dodge":
			continue
		total += int(entry.get("value", 0))
	return total


## A weapon may explicitly support melee and/or thrown/ranged attacks. Legacy
## data with only range_increment is treated as ranged-only; ordinary weapons
## default to melee. Dagger explicitly supports both (PHB p. 113).
static func weapon_attack_modes(weapon: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var authored = weapon.get("attack_modes", [])
	if authored is Array:
		for raw in authored:
			var mode := String(raw).to_lower()
			if ["melee", "thrown", "ranged"].has(mode) and not result.has(mode):
				result.append(mode)
	if result.is_empty():
		result.append("ranged" if int(weapon.get("range_increment", 0)) > 0 else "melee")
	return result


static func default_attack_mode(weapon: Dictionary) -> String:
	var modes := weapon_attack_modes(weapon)
	return "melee" if modes.has("melee") else (modes[0] if not modes.is_empty() else "")


static func normalize_attack_mode(weapon: Dictionary, attack_mode := "") -> String:
	var requested := String(attack_mode).to_lower()
	if requested == "":
		return default_attack_mode(weapon)
	return requested if weapon_attack_modes(weapon).has(requested) else ""


static func is_ranged_attack(weapon: Dictionary, attack_mode := "") -> bool:
	var mode := normalize_attack_mode(weapon, attack_mode)
	return mode == "ranged" or mode == "thrown"


static func is_thrown_attack(weapon: Dictionary, attack_mode := "") -> bool:
	return normalize_attack_mode(weapon, attack_mode) == "thrown"


## Total attack bonus with the equipped weapon. Ranged attacks use Dexterity.
static func attack_bonus(
	ch: Character, weapon: Dictionary = {}, distance_ft: int = 0, attack_mode := ""
) -> int:
	var w: Dictionary = weapon if not weapon.is_empty() else ch.equipment.get("weapon", {})
	var mode := normalize_attack_mode(w, attack_mode)
	var ranged := is_ranged_attack(w, mode)
	var use_dex := ranged
	if not ranged and (bool(w.get("use_dexterity", false)) or Feats.can_use_weapon_finesse(ch, w)):
		use_dex = true
	var ability: String = "dex" if use_dex else "str"
	var bonus := ch.base_attack + ability_modifier(ch, ability)
	bonus += int(w.get("attack_bonus", 0))
	# Weapon Focus is parameterised by exact weapon; Point Blank Shot needs a
	# ranged weapon within 30 ft. Both re-check their prerequisites.
	bonus += int(
		Feats.modifier(
			ch,
			"attack",
			{
				"weapon": w,
				"ranged": ranged,
				"distance_ft": distance_ft,
				"attack_mode": mode,
			}
		)["total"]
	)
	# Manufactured weapons without proficiency take -4; non-proficient armor
	# and shields add their armor check penalties to attack rolls.
	bonus += weapon_nonproficiency_penalty(ch, w)
	bonus += armor_attack_penalty(ch)
	# Secondary natural attacks take -5, or -2 with Multiattack (MM p.304).
	# The penalty is applied here, never baked into authored attack data.
	if bool(w.get("secondary", false)):
		bonus += Feats.secondary_attack_penalty(ch)
	# Bless and aid both grant a +1 morale bonus on attack rolls (PHB pp.205,
	# 196). Morale bonuses do not stack, so either effect adds +1 once.
	if ch.has_effect("bless") or ch.has_effect("aid"):
		bonus += 1
	# Table 8-5 (printed p. 151): a prone attacker takes -4 on melee attack
	# rolls; ranged attacks while prone are restricted instead (footnote 3).
	if ch.is_prone() and not ranged:
		bonus -= 4
	if not ranged and is_helpless_target_bonus_applicable(ch):
		pass
	var increment := int(w.get("range_increment", 0))
	if ranged and increment > 0 and distance_ft > increment:
		var increments := ceili(float(distance_ft) / float(increment))
		bonus -= 2 * maxi(0, increments - 1)
	return bonus


static func is_helpless_target_bonus_applicable(_ch: Character) -> bool:
	return false


static func is_ranged_weapon(weapon: Dictionary, attack_mode := "") -> bool:
	return is_ranged_attack(weapon, attack_mode)


static func damage_bonus(
	ch: Character,
	weapon: Dictionary = {},
	distance_ft := 0,
	power_attack := 0,
	attack_mode := ""
) -> int:
	var w: Dictionary = weapon if not weapon.is_empty() else ch.equipment.get("weapon", {})
	var mode := normalize_attack_mode(w, attack_mode)
	var ranged := is_ranged_attack(w, mode)
	var thrown := is_thrown_attack(w, mode)
	var bonus := int(w.get("damage_bonus", 0))
	# Projectile weapons do not add Strength; thrown weapons do (PHB p. 113).
	if not ranged or thrown or bool(w.get("add_strength_to_damage", false)):
		var str_bonus := ability_modifier(ch, "str")
		# Secondary natural attacks add only half the Strength bonus; the ghoul's
		# claws are secondary to its bite (MM p.119).
		if bool(w.get("secondary", false)):
			str_bonus = floori(float(str_bonus) / 2.0)
		bonus += str_bonus
	bonus += int(
		Feats.modifier(
			ch,
			"damage",
			{
				"weapon": w,
				"ranged": ranged,
				"distance_ft": distance_ft,
				"attack_mode": mode,
			}
		)["total"]
	)
	bonus += Feats.power_attack_damage_bonus(ch, w, power_attack, mode)
	return bonus


## Bonus to a saving throw. Bless and aid grant +1 morale on saves vs. fear
## (PHB pp.205, 197); no fear effects are implemented in this slice, so the
## bonus is logged but has no target to apply to.
static func saving_throw_bonus(ch: Character, save_type: String) -> int:
	var ability: String = "con" if save_type == "fort" else ("dex" if save_type == "ref" else "wis")
	var total := int(ch.base_saves.get(save_type, 0)) + ability_modifier(ch, ability)
	# Iron Will, Lightning Reflexes and Great Fortitude are typed bonuses; the
	# stacking rule keeps the best of each type and re-checks prerequisites.
	total += int(Feats.modifier(ch, "save:" + save_type)["total"])
	return total


static func saving_throw(
	rng: RandomNumberGenerator, ch: Character, save_type: String, dc: int
) -> Dictionary:
	var roll := Dice.d20(rng)
	var bonus := saving_throw_bonus(ch, save_type)
	var total := roll + bonus
	var success := total >= dc
	# Natural 20 / natural 1 are not automatic for saving throws (PHB p.136).
	return {
		"roll": roll,
		"bonus": bonus,
		"total": total,
		"dc": dc,
		"success": success,
		"type": save_type,
	}


static func skill_check(
	rng: RandomNumberGenerator, ch: Character, skill: String, dc: int, opts: Dictionary = {}
) -> Dictionary:
	return Skills.check(rng, ch, skill, dc, opts)


## Ability check (PHB p.62) used for e.g. forcing a door with Strength.
## Take 10/20 is available on ability checks under the same conditions as
## skill checks (PHB p.65).
static func ability_check(
	rng: RandomNumberGenerator, ch: Character, ability: String, dc: int, opts: Dictionary = {}
) -> Dictionary:
	var take := int(opts.get("take", 0))
	if take != 0 and take != 10 and take != 20:
		return {"ok": false, "available": false, "reason": "Take must be 0, 10 or 20.", "roll": 0, "bonus": 0, "total": 0, "dc": dc, "success": false, "skill": ability, "actor": ch.display_name, "mode": "unavailable"}
	if take != 0 and bool(opts.get("threatened", false)):
		return {"ok": false, "available": false, "reason": "You cannot take %d while threatened or in combat." % take, "roll": 0, "bonus": 0, "total": 0, "dc": dc, "success": false, "skill": ability, "actor": ch.display_name, "mode": "unavailable"}
	if take == 20 and bool(opts.get("failure_penalty", false)):
		return {"ok": false, "available": false, "reason": "Taking 20 is impossible when failure carries a penalty.", "roll": 0, "bonus": 0, "total": 0, "dc": dc, "success": false, "skill": ability, "actor": ch.display_name, "mode": "unavailable"}
	var roll := int(take) if take != 0 else Dice.d20(rng)
	var bonus := ability_modifier(ch, ability)
	return {
		"ok": true,
		"available": true,
		"reason": "",
		"roll": roll,
		"bonus": bonus,
		"total": roll + bonus,
		"dc": dc,
		"success": roll + bonus >= dc,
		"skill": ability,
		"actor": ch.display_name,
		"mode": ("take %d" % take) if take != 0 else "roll",
		"take": take,
	}


## Attack rejected before any roll (for example a prone archer). The shape
## matches a normal result so callers never have to special-case missing keys.
static func _unavailable_attack(
	attacker: Character, target: Character, label: String, reason: String
) -> Dictionary:
	return {
		"available": false,
		"reason": reason,
		"label": label,
		"attacker": attacker.display_name,
		"target": target.display_name,
		"roll": 0,
		"bonus": 0,
		"total": 0,
		"target_ac": 0,
		"touch": false,
		"hit": false,
		"critical": false,
		"critical_confirmed": false,
		"damage": 0,
		"damage_rolls": [],
		"ranged": false,
		"distance_ft": 0,
		"details": reason,
		"attack_mode": "",
	}


## Opposed ability check with the general tie procedure from PHB p. 64:
## "In an opposed check, the higher result succeeds, while the lower result
## fails. In case of a tie, the higher skill modifier wins. If these scores are
## the same, roll again to break the tie." Trip opposes Strength checks
## (PHB p. 158), so the ability modifier takes the place of the skill modifier.
## A tie is never awarded to the defender without this comparison.
static func opposed_ability_check(
	rng: RandomNumberGenerator,
	attacker: Character,
	attacker_abilities: Array,
	defender: Character,
	defender_abilities: Array,
	opts: Dictionary = {}
) -> Dictionary:
	var attacker_pick := best_ability_modifier(attacker, attacker_abilities)
	var defender_pick := best_ability_modifier(defender, defender_abilities)
	if String(attacker_pick["ability"]) == "" or String(defender_pick["ability"]) == "":
		return {
			"ok": false,
			"reason": "An opposed check needs at least one valid ability on each side.",
			"winner": "",
		}
	var attacker_modifier := int(attacker_pick["modifier"]) + int(opts.get("attacker_bonus", 0))
	var defender_modifier := int(defender_pick["modifier"]) + int(opts.get("defender_bonus", 0))
	var result := {
		"ok": true,
		"label": String(opts.get("label", "opposed check")),
		"attacker": attacker.display_name,
		"defender": defender.display_name,
		"attacker_ability": String(attacker_pick["ability"]),
		"defender_ability": String(defender_pick["ability"]),
		"attacker_modifier": attacker_modifier,
		"defender_modifier": defender_modifier,
		"attacker_roll": 0,
		"defender_roll": 0,
		"attacker_total": 0,
		"defender_total": 0,
		"winner": "",
		"tie_broken_by": "",
		"rerolls": 0,
	}
	# A tie with equal modifiers is rerolled, so bound the loop instead of
	# trusting an unbounded while. Twenty rerolls cannot occur in practice.
	for attempt in range(1, 21):
		var attacker_roll := Dice.d20(rng)
		var defender_roll := Dice.d20(rng)
		var attacker_total := attacker_roll + attacker_modifier
		var defender_total := defender_roll + defender_modifier
		result["attacker_roll"] = attacker_roll
		result["defender_roll"] = defender_roll
		result["attacker_total"] = attacker_total
		result["defender_total"] = defender_total
		result["rerolls"] = attempt - 1
		if attacker_total > defender_total:
			result["winner"] = "attacker"
			result["tie_broken_by"] = "reroll" if attempt > 1 else "result"
			return result
		if defender_total > attacker_total:
			result["winner"] = "defender"
			result["tie_broken_by"] = "reroll" if attempt > 1 else "result"
			return result
		if attacker_modifier != defender_modifier:
			result["winner"] = "attacker" if attacker_modifier > defender_modifier else "defender"
			result["tie_broken_by"] = "modifier"
			return result
	result["ok"] = false
	result["reason"] = "Tied totals and modifiers for twenty rerolls."
	return result


## Best modifier among the allowed abilities. PHB p. 158 Trip uses the
## defender's better of Dexterity or Strength.
static func best_ability_modifier(ch: Character, abilities: Array) -> Dictionary:
	var best_ability := ""
	var best_modifier := -999
	for raw in abilities:
		var ability := String(raw).to_lower()
		if not ABILITIES.has(ability):
			continue
		var modifier := ability_modifier(ch, ability)
		if best_ability == "" or modifier > best_modifier:
			best_ability = ability
			best_modifier = modifier
	return {"ability": best_ability, "modifier": best_modifier}


## Resolves one attack. Returns a fully auditable result dictionary.
##
## weapon: item data with damage/crit_range/crit_mult/range_increment.
## opts: {touch: bool, label: String, bonus: int, extra_damage: String}.
static func attack(
	rng: RandomNumberGenerator,
	attacker: Character,
	target: Character,
	weapon: Dictionary,
	distance_ft: int,
	opts: Dictionary = {}
) -> Dictionary:
	var w: Dictionary = weapon
	var power_attack := int(opts.get("power_attack", 0))
	var combat_expertise := int(opts.get("combat_expertise", 0))
	var attack_mode := normalize_attack_mode(w, String(opts.get("attack_mode", "")))
	var label := String(opts.get("label", w.get("name", "attack")))
	var melee := not is_ranged_attack(w, attack_mode)
	if attacker.is_prone() and not melee and not prone_ranged_attack_allowed(w):
		return _unavailable_attack(
			attacker,
			target,
			label,
			"%s is prone and cannot use %s; only a crossbow or shuriken can be used while prone (PHB p. 151)."
			% [attacker.display_name, label]
		)
	var attack_bonus_value := attack_bonus(attacker, w, distance_ft, attack_mode) + int(opts.get("bonus", 0))
	# PHB p. 140: shooting or throwing into a melee takes -4. The encounter
	# decides whether it applies (engagement, 10-ft escape, Precise Shot) and
	# passes it here so the penalty is part of the auditable roll.
	attack_bonus_value += int(opts.get("into_melee_penalty", 0))
	# PHB p.140: fighting defensively is -4 on all attacks in the round. The
	# encounter passes it only once the stance is active, and it sits before
	# `bonus_base` so Cleave's same-bonus copy carries it.
	attack_bonus_value += int(opts.get("fight_defensively_penalty", 0))
	if melee:
		attack_bonus_value += Feats.power_attack_attack_penalty(attacker, power_attack)
		attack_bonus_value += Feats.combat_expertise_attack_penalty(attacker, combat_expertise)
	# Cleave's extra attack is "with the same weapon and at the same bonus as the
	# attack that dropped the previous creature" (PHB p.92). Only the attack's
	# own base (BAB, ability, feats, weapon, committed trades) is preserved;
	# target-specific circumstances are evaluated again against the new target
	# below, so a bonus that no longer applies is not copied and one that does
	# still applies (helpless, cowering) is added back.
	if opts.has("force_attack_base"):
		attack_bonus_value = int(opts["force_attack_base"])
	var bonus_base := attack_bonus_value
	# +4 bonus on melee attacks against helpless defenders (PHB p.151).
	if melee and is_helpless(target):
		attack_bonus_value += 4
	# A cowering creature (a turned undead that cannot flee) gives attackers
	# a +2 bonus (PHB p.159, "Effect and Duration of Turning").
	if target.has_condition("cowering"):
		attack_bonus_value += 2
	# PHB p.153: an attacker whose opponent is threatened by a friendly creature
	# on its opposite border or corner has a +2 flanking bonus. The encounter
	# decides whether *this* attacker flanks and passes it here, after
	# `bonus_base`, so a Cleave follow-up evaluates its own new target.
	if melee:
		attack_bonus_value += int(opts.get("flank_bonus", 0))
	var flat_footed := bool(opts.get("flat_footed", false))
	var deny_dex := bool(opts.get("deny_dex", false))
	var pinned_penalty := maxi(0, int(opts.get("pinned_penalty", 0)))
	var target_ac := (
		touch_ac(
			target,
			{
				"flat_footed": flat_footed,
				"deny_dex": deny_dex,
				"pinned_penalty": pinned_penalty,
				"attack_mode": attack_mode,
			}
		)
		if bool(opts.get("touch", false))
		else armor_class(
			target,
			{
				"flat_footed": flat_footed,
				"deny_dex": deny_dex,
				"pinned_penalty": pinned_penalty,
				"attack_mode": attack_mode,
			}
		)
	)
	# Soft cover from creatures (PHB p.151) is +4 AC, and to touch AC as well
	# because a touch attack keeps every modifier except armor, shield and natural
	# armor. The encounter reads it from the grid and passes it in, so the term is
	# part of the auditable roll like the into-melee penalty.
	var cover_bonus := maxi(0, int(opts.get("cover", 0)))
	target_ac += cover_bonus
	var roll := Dice.d20(rng)
	var total := roll + attack_bonus_value
	var natural_20 := roll == 20
	var natural_1 := roll == 1
	var hit := (total >= target_ac or natural_20) and not natural_1

	var result := {
		"available": true,
		"label": label,
		"attack_mode": attack_mode,
		"power_attack": power_attack,
		"power_attack_penalty": Feats.power_attack_attack_penalty(attacker, power_attack) if melee else 0,
		"combat_expertise": combat_expertise if melee else 0,
		"combat_expertise_penalty": Feats.combat_expertise_attack_penalty(attacker, combat_expertise) if melee else 0,
		"attacker": attacker.display_name,
		"target": target.display_name,
		"roll": roll,
		"bonus": attack_bonus_value,
		"bonus_base": bonus_base,
		"total": total,
		"target_ac": target_ac,
		"touch": bool(opts.get("touch", false)),
		"hit": hit,
		"critical": false,
		"critical_confirmed": false,
		"damage": 0,
		"damage_rolls": [],
		"ranged": not melee,
		"distance_ft": distance_ft,
		"into_melee_penalty": int(opts.get("into_melee_penalty", 0)),
		"cover": cover_bonus,
		"fight_defensively_penalty": int(opts.get("fight_defensively_penalty", 0)),
		"details": "",
	}
	if not hit:
		if natural_1:
			result["details"] = "natural 1 — automatic miss"
		return result

	var crit_range := int(w.get("crit_range", 20))
	var crit_mult := int(w.get("crit_mult", 2))
	# Undead and constructs are not subject to critical hits (MM p.317).
	var crit_immune := target.tags.has("undead") or target.tags.has("construct")
	var critical_threat := not crit_immune and roll >= crit_range
	if critical_threat:
		result["critical"] = true
		var confirm_roll := Dice.d20(rng)
		var confirm_total := confirm_roll + attack_bonus_value
		# Confirmation is another attack roll: natural 20 always hits, natural 1
		# always misses (PHB pp.134, 140).
		var confirmed := confirm_roll == 20 or (confirm_total >= target_ac and confirm_roll != 1)
		result["critical_confirmed"] = confirmed
		result["confirm_roll"] = confirm_roll
		result["confirm_total"] = confirm_total
		if confirmed:
			result["damage_multiplier"] = crit_mult
	if not bool(result["critical_confirmed"]) and critical_threat and int(w.get("crit_mult", 2)) == 1:
		result["critical"] = false

	var multiplier := int(result.get("damage_multiplier", 1))
	var rolled := roll_damage(
		rng,
		attacker,
		w,
		{
			"distance_ft": distance_ft,
			"power_attack": power_attack,
			"attack_mode": attack_mode,
			"multiplier": multiplier,
			"extra_damage": String(opts.get("extra_damage", "")),
		}
	)
	result["damage"] = int(rolled["damage"])
	result["damage_rolls"] = rolled["damage_rolls"]
	result["damage_type"] = String(rolled["damage_type"])
	return result


## One damage roll for a weapon, shared by `attack` and by the automatic
## unarmed-strike damage a won grapple deals (PHB p.155). The caller owns the
## target; damage reduction and nonlethal tracking stay in the encounter.
## opts: {distance_ft, power_attack, attack_mode, multiplier, extra_damage}.
static func roll_damage(
	rng: RandomNumberGenerator, attacker: Character, weapon: Dictionary, opts: Dictionary = {}
) -> Dictionary:
	var distance_ft := int(opts.get("distance_ft", 0))
	var power_attack := int(opts.get("power_attack", 0))
	var attack_mode := normalize_attack_mode(weapon, String(opts.get("attack_mode", "")))
	var multiplier := maxi(1, int(opts.get("multiplier", 1)))
	var damage_total := 0
	var all_rolls: Array = []
	for _m in multiplier:
		var parsed := Dice.parse(rng, String(weapon.get("damage", "1d3")))
		damage_total += int(parsed["total"]) + damage_bonus(
			attacker, weapon, distance_ft, power_attack, attack_mode
		)
		all_rolls.append(Dice.describe(parsed))
	var extra := String(opts.get("extra_damage", ""))
	if extra != "":
		var extra_parsed := Dice.parse(rng, extra)
		damage_total += int(extra_parsed["total"])
		all_rolls.append("extra " + Dice.describe(extra_parsed))
	return {
		"damage": maxi(0, damage_total),
		"damage_rolls": all_rolls,
		"damage_type": String(weapon.get("damage_type", "untyped")),
	}


static func format_attack(result: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(
		"%s attacks %s with %s: d20(%d)%+d = %d vs AC %d"
		% [
			result["attacker"],
			result["target"],
			result["label"],
			int(result["roll"]),
			int(result["bonus"]),
			int(result["total"]),
			int(result["target_ac"]),
		]
	)
	if int(result.get("into_melee_penalty", 0)) != 0:
		parts.append("shooting into melee %+d" % int(result["into_melee_penalty"]))
	if bool(result.get("critical", false)):
		if bool(result.get("critical_confirmed", false)):
			parts.append("CRITICAL (threat confirmed) x%d" % int(result.get("damage_multiplier", 2)))
		else:
			parts.append("critical threat not confirmed")
	if bool(result["hit"]):
		parts.append("%d damage" % int(result["damage"]))
	else:
		parts.append("MISS")
	return " | ".join(parts)


## Table 8-9: Turning Undead (PHB p.159). Returns the Hit Dice of the most
## powerful undead a cleric can affect for a given turning-check total.
static func turn_max_hd(cleric_level: int, check_total: int) -> int:
	var delta := -4
	if check_total >= 22:
		delta = 4
	elif check_total >= 19:
		delta = 3
	elif check_total >= 16:
		delta = 2
	elif check_total >= 13:
		delta = 1
	elif check_total >= 10:
		delta = 0
	elif check_total >= 7:
		delta = -1
	elif check_total >= 4:
		delta = -2
	elif check_total >= 1:
		delta = -3
	return maxi(0, cleric_level + delta)


## Turning damage: 2d6 + cleric level + Charisma modifier (PHB p.159).
## This is the total Hit Dice of undead the attempt can affect.
static func turn_damage(cleric_level: int, cha_mod: int, die_a: int, die_b: int) -> int:
	return die_a + die_b + cleric_level + cha_mod
