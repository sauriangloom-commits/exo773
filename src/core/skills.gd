class_name Skills
extends RefCounted

## Player's Handbook skill rules used by the slice (PHB pp.61-86).
##
## The catalog is the complete Table 4-2 list, including all ten Knowledge
## skills. Gameplay still resolves only the checks authored by content; a
## catalog entry is rules support, not proof that a world subsystem exists.
##
## Ranks are kept separate from modifiers: prerequisites and trained-only
## restrictions read ranks, while checks read the total. Totals combine ranks,
## the key ability modifier, armor check penalties (doubled for Swim), active
## feat bonuses, conditional synergies, and circumstance/miscellaneous
## modifiers. Typed bonuses stack through Rules.stack_bonuses.

const CATALOG := {
	"appraise": {"name": "Appraise", "ability": "int", "untrained": true, "armor": 0, "action": "1 round", "retry": true},
	"balance": {"name": "Balance", "ability": "dex", "untrained": true, "armor": 1, "action": "move action", "retry": true},
	"bluff": {"name": "Bluff", "ability": "cha", "untrained": true, "armor": 0, "action": "standard action", "retry": false, "retry_note": "A failed bluff cannot simply be repeated against the same target."},
	"climb": {"name": "Climb", "ability": "str", "untrained": true, "armor": 1, "action": "part of movement", "retry": true},
	"concentration": {"name": "Concentration", "ability": "con", "untrained": true, "armor": 0, "action": "instant", "retry": true},
	"craft": {"name": "Craft", "ability": "int", "untrained": true, "armor": 0, "action": "varies", "retry": true},
	"decipher_script": {"name": "Decipher Script", "ability": "int", "untrained": false, "armor": 0, "action": "1 minute", "retry": false},
	"diplomacy": {"name": "Diplomacy", "ability": "cha", "untrained": true, "armor": 0, "action": "1 minute or full-round action", "retry": false, "retry_note": "Retries after a failed negotiation are optional and generally worsen the attitude."},
	"disable_device": {"name": "Disable Device", "ability": "int", "untrained": false, "armor": 0, "action": "varies", "retry": true, "retry_note": "Retry rules depend on how badly the first check failed; a trap may trigger."},
	"disguise": {"name": "Disguise", "ability": "cha", "untrained": true, "armor": 0, "action": "1d3 x 10 minutes", "retry": true},
	"escape_artist": {"name": "Escape Artist", "ability": "dex", "untrained": true, "armor": 1, "action": "standard action", "retry": true},
	"forgery": {"name": "Forgery", "ability": "int", "untrained": true, "armor": 0, "action": "1d4 minutes", "retry": true},
	"gather_information": {"name": "Gather Information", "ability": "cha", "untrained": true, "armor": 0, "action": "1d4+1 hours", "retry": true},
	"handle_animal": {"name": "Handle Animal", "ability": "cha", "untrained": false, "armor": 0, "action": "varies", "retry": true},
	"heal": {"name": "Heal", "ability": "wis", "untrained": true, "armor": 0, "action": "standard action (first aid)", "retry": false, "retry_note": "A failed first aid or treatment attempt generally cannot be retried on the same subject."},
	"hide": {"name": "Hide", "ability": "dex", "untrained": true, "armor": 1, "action": "part of movement", "retry": true},
	"intimidate": {"name": "Intimidate", "ability": "cha", "untrained": true, "armor": 0, "action": "1 minute", "retry": false, "retry_note": "A failed intimidation cannot simply be repeated against the same target."},
	"jump": {"name": "Jump", "ability": "str", "untrained": true, "armor": 1, "action": "part of movement", "retry": true},
	"knowledge_arcana": {"name": "Knowledge (arcana)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_architecture": {"name": "Knowledge (architecture and engineering)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_dungeoneering": {"name": "Knowledge (dungeoneering)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_geography": {"name": "Knowledge (geography)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_history": {"name": "Knowledge (history)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_local": {"name": "Knowledge (local)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_nature": {"name": "Knowledge (nature)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_nobility": {"name": "Knowledge (nobility and royalty)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_religion": {"name": "Knowledge (religion)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"knowledge_planes": {"name": "Knowledge (the planes)", "ability": "int", "untrained": false, "armor": 0, "action": "no action", "retry": false},
	"listen": {"name": "Listen", "ability": "wis", "untrained": true, "armor": 0, "action": "free action", "retry": true},
	"move_silently": {"name": "Move Silently", "ability": "dex", "untrained": true, "armor": 1, "action": "part of movement", "retry": true},
	"open_lock": {"name": "Open Lock", "ability": "dex", "untrained": false, "armor": 0, "action": "full-round action", "retry": true},
	"perform": {"name": "Perform", "ability": "cha", "untrained": true, "armor": 0, "action": "varies", "retry": true},
	"profession": {"name": "Profession", "ability": "wis", "untrained": false, "armor": 0, "action": "varies", "retry": true},
	"ride": {"name": "Ride", "ability": "dex", "untrained": true, "armor": 0, "action": "varies", "retry": true},
	"search": {"name": "Search", "ability": "int", "untrained": true, "armor": 0, "action": "full-round action per 5-ft square", "retry": true},
	"sense_motive": {"name": "Sense Motive", "ability": "wis", "untrained": true, "armor": 0, "action": "1 minute", "retry": false, "retry_note": "A failed hunch cannot be retried on the same exchange."},
	"sleight_of_hand": {"name": "Sleight of Hand", "ability": "dex", "untrained": false, "armor": 1, "action": "standard action", "retry": true},
	"speak_language": {"name": "Speak Language", "ability": "none", "untrained": false, "armor": 0, "action": "none", "retry": false, "check": false},
	"spellcraft": {"name": "Spellcraft", "ability": "int", "untrained": false, "armor": 0, "action": "varies", "retry": true},
	"spot": {"name": "Spot", "ability": "wis", "untrained": true, "armor": 0, "action": "free action", "retry": true},
	"survival": {"name": "Survival", "ability": "wis", "untrained": true, "armor": 0, "action": "varies", "retry": true},
	"swim": {"name": "Swim", "ability": "str", "untrained": true, "armor": 2, "action": "part of movement", "retry": true},
	"tumble": {"name": "Tumble", "ability": "dex", "untrained": false, "armor": 1, "action": "part of movement", "retry": false},
	"use_magic_device": {"name": "Use Magic Device", "ability": "cha", "untrained": false, "armor": 0, "action": "varies", "retry": true},
	"use_rope": {"name": "Use Rope", "ability": "dex", "untrained": true, "armor": 0, "action": "varies", "retry": true},
}

## Table 4-5, PHB p.66. A context restricts a synergy to the listed use; an
## empty context applies to every check with the target skill.
const SYNERGIES := [
	{"source": "bluff", "target": "diplomacy"},
	{"source": "bluff", "target": "disguise", "context": "in_character"},
	{"source": "bluff", "target": "intimidate"},
	{"source": "bluff", "target": "sleight_of_hand"},
	{"source": "decipher_script", "target": "use_magic_device", "context": "scrolls"},
	{"source": "escape_artist", "target": "use_rope", "context": "bindings"},
	{"source": "handle_animal", "target": "ride"},
	{"source": "jump", "target": "tumble"},
	{"source": "knowledge_arcana", "target": "spellcraft"},
	{"source": "knowledge_architecture", "target": "search", "context": "secret_doors"},
	{"source": "knowledge_dungeoneering", "target": "survival", "context": "underground"},
	{"source": "knowledge_geography", "target": "survival", "context": "lost_or_hazards"},
	{"source": "knowledge_local", "target": "gather_information"},
	{"source": "knowledge_nature", "target": "survival", "context": "aboveground_natural"},
	{"source": "knowledge_nobility", "target": "diplomacy"},
	{"source": "knowledge_planes", "target": "survival", "context": "other_planes"},
	{"source": "knowledge_religion", "target": "turn_undead"},
	{"source": "search", "target": "survival", "context": "tracking"},
	{"source": "sense_motive", "target": "diplomacy"},
	{"source": "spellcraft", "target": "use_magic_device", "context": "scrolls"},
	{"source": "survival", "target": "knowledge_nature"},
	{"source": "tumble", "target": "balance"},
	{"source": "tumble", "target": "jump"},
	{"source": "use_magic_device", "target": "spellcraft", "context": "scrolls"},
	{"source": "use_rope", "target": "climb", "context": "ropes"},
	{"source": "use_rope", "target": "escape_artist", "context": "ropes"},
]

## PHB class skill lists for the five playable classes. A character with no
## listed class treats every skill as cross-class.
## Skills that involve moving for the non-proficiency armor rule. The normal
## armor-check multiplier is still read from CATALOG; Ride is included here
## because PHB p.89 names it explicitly.
const MOVEMENT_SKILLS := [
	"balance", "climb", "escape_artist", "hide", "jump", "move_silently",
	"ride", "sleight_of_hand", "swim", "tumble",
]

const CLASS_SKILLS := {
	"fighter": ["climb", "craft", "handle_animal", "intimidate", "jump", "ride", "swim"],
	"rogue": [
		"appraise", "balance", "bluff", "climb", "craft", "decipher_script", "diplomacy",
		"disable_device", "disguise", "escape_artist", "forgery", "gather_information",
		"hide", "intimidate", "jump", "knowledge_local", "listen", "move_silently",
		"open_lock", "perform", "profession", "search", "sense_motive", "sleight_of_hand",
		"spot", "swim", "tumble", "use_magic_device", "use_rope",
	],
	"cleric": [
		"concentration", "craft", "diplomacy", "heal", "knowledge_arcana",
		"knowledge_history", "knowledge_religion", "knowledge_planes", "profession",
		"spellcraft",
	],
	"wizard": [
		"concentration", "craft", "decipher_script", "knowledge_arcana",
		"knowledge_architecture", "knowledge_dungeoneering", "knowledge_geography",
		"knowledge_history", "knowledge_local", "knowledge_nature", "knowledge_nobility",
		"knowledge_religion", "knowledge_planes", "profession", "spellcraft",
	],
	"sorcerer": ["bluff", "concentration", "craft", "knowledge_arcana", "profession", "spellcraft"],
}


static func entry(skill: String) -> Dictionary:
	return CATALOG.get(skill, {})


static func exists(skill: String) -> bool:
	return CATALOG.has(skill)


static func name(skill: String) -> String:
	return String(CATALOG.get(skill, {}).get("name", skill.replace("_", " ").capitalize()))


static func ability(skill: String) -> String:
	return String(CATALOG.get(skill, {}).get("ability", "int"))


static func untrained_allowed(skill: String) -> bool:
	return bool(CATALOG.get(skill, {}).get("untrained", true))


static func is_trained_only(skill: String) -> bool:
	return not untrained_allowed(skill)


static func armor_multiplier(skill: String) -> int:
	return int(CATALOG.get(skill, {}).get("armor", 0))


static func is_movement_skill(skill: String) -> bool:
	return MOVEMENT_SKILLS.has(skill)


static func is_check(skill: String) -> bool:
	return bool(CATALOG.get(skill, {}).get("check", true))


static func retry_allowed(skill: String) -> bool:
	return bool(CATALOG.get(skill, {}).get("retry", true))


static func retry_note(skill: String) -> String:
	return String(CATALOG.get(skill, {}).get("retry_note", ""))


static func all_keys() -> Array:
	var keys: Array = CATALOG.keys()
	keys.sort()
	return keys


static func is_class_skill(ch: Character, skill: String) -> bool:
	var list: Array = CLASS_SKILLS.get(ch.char_class.to_lower(), [])
	return list.has(skill)


## Maximum ranks at the character's current level (PHB p.62): level + 3 for a
## class skill, half that for a cross-class skill.
static func max_ranks(ch: Character, skill: String) -> int:
	var cap := ch.level + 3
	if not is_class_skill(ch, skill):
		cap = floori(float(cap) / 2.0)
	return maxi(0, cap)


static func ranks_legal(ch: Character, skill: String) -> bool:
	return int(ch.skill_ranks.get(skill, 0)) <= max_ranks(ch, skill)


## Active feat and typed-modifier bonuses for a skill.
static func feat_bonus(ch: Character, skill: String, opts: Dictionary = {}) -> Dictionary:
	var typed: Array = []
	# The caller's options travel with the modifier lookup so a feat can apply a
	# bonus only in the circumstance its printed text names (for example Combat
	# Casting's defensive-casting clause).
	var feat_opts := opts.duplicate()
	feat_opts["skill"] = skill
	var from_feats := Feats.modifier(ch, "skill:" + skill, feat_opts)
	typed.append_array(from_feats.get("entries", []))
	typed.append_array(Array(opts.get("modifiers", [])))
	return Rules.stack_bonuses(typed)


## A synergy needs 5 or more ranks in the source skill. Context-sensitive
## synergies apply only when the caller names the matching use.
static func synergies(ch: Character, skill: String, context := "") -> Array:
	var result: Array = []
	for raw in SYNERGIES:
		var row: Dictionary = raw
		if String(row.get("target", "")) != skill:
			continue
		if int(ch.skill_ranks.get(String(row.get("source", "")), 0)) < 5:
			continue
		var required := String(row.get("context", ""))
		if required != "" and not context.split(",").has(required):
			continue
		result.append(
			{
				"source": String(row.get("source", "")),
				"label": "synergy (%s)" % name(String(row.get("source", ""))),
				"value": 2,
				"context": required,
			}
		)
	return result


static func synergy_bonus(ch: Character, skill: String, context := "") -> int:
	var total := 0
	for row in synergies(ch, skill, context):
		total += int(row["value"])
	return total


## Line-by-line modifier breakdown used by the character sheet and tests.
static func breakdown(ch: Character, skill: String, opts: Dictionary = {}) -> Array:
	var data := entry(skill)
	var lines: Array = []
	if data.is_empty():
		return lines
	var ranks := int(ch.skill_ranks.get(skill, 0))
	if ranks != 0:
		lines.append({"label": "ranks", "value": ranks, "type": "ranks"})
	var ability_key := String(data.get("ability", "int"))
	if ability_key != "none":
		lines.append(
			{
				"label": "%s modifier" % ability_key.to_upper(),
				"value": Rules.ability_modifier(ch, ability_key),
				"type": "ability",
			}
		)
	var armor_penalty := Rules.skill_armor_check_penalty(ch, skill)
	if armor_penalty != 0:
		lines.append(
			{
				"label": "armor check",
				"value": armor_penalty,
				"type": "armor_check",
			}
		)
	var stacked := feat_bonus(ch, skill, opts)
	for row in stacked.get("entries", []):
		lines.append({"label": String(row["source"]), "value": int(row["value"]), "type": String(row["type"])})
	for row in synergies(ch, skill, String(opts.get("context", ""))):
		lines.append({"label": String(row["label"]), "value": int(row["value"]), "type": "synergy"})
	var circumstance := int(opts.get("circumstance", 0))
	if circumstance != 0:
		lines.append({"label": "circumstance", "value": circumstance, "type": "circumstance"})
	var misc := int(opts.get("misc", 0))
	if misc != 0:
		lines.append({"label": "miscellaneous", "value": misc, "type": "misc"})
	if skill == "hide":
		var size_bonus := int(ch.size_ac) * 4
		if size_bonus != 0:
			lines.append({"label": "size", "value": size_bonus, "type": "size"})
	return lines


static func total(ch: Character, skill: String, opts: Dictionary = {}) -> int:
	var sum := 0
	for row in breakdown(ch, skill, opts):
		sum += int(row["value"])
	return sum


static func breakdown_text(ch: Character, skill: String, opts: Dictionary = {}) -> String:
	var parts: Array[String] = []
	for row in breakdown(ch, skill, opts):
		parts.append("%s %+d" % [String(row["label"]), int(row["value"])])
	if parts.is_empty():
		return "0"
	return "%+d (%s)" % [total(ch, skill, opts), ", ".join(parts)]


static func _unavailable(message: String) -> Dictionary:
	return {
		"ok": false,
		"available": false,
		"reason": message,
		"roll": 0,
		"bonus": 0,
		"total": 0,
		"dc": 0,
		"success": false,
		"mode": "unavailable",
		"breakdown": [],
	}


## opts:
##   take: 0 (roll), 10 or 20
##   threatened, distracted: block take 10/20
##   failure_penalty: blocks take 20
##   circumstance, misc, context, modifiers
##   retrying: true when this is a retry of a failed check
static func check(
	rng: RandomNumberGenerator, ch: Character, skill: String, dc: int, opts: Dictionary = {}
) -> Dictionary:
	var data := entry(skill)
	if data.is_empty():
		return _unavailable("Unknown skill '%s'." % skill)
	if not is_check(skill):
		return _unavailable("%s is learned, not checked." % name(skill))
	var ranks := int(ch.skill_ranks.get(skill, 0))
	if is_trained_only(skill) and ranks <= 0:
		return _unavailable(
			"%s is trained only; %s has no ranks in it." % [name(skill), ch.display_name]
		)
	if bool(opts.get("retrying", false)) and not retry_allowed(skill):
		var note := retry_note(skill)
		return _unavailable(
			"%s cannot be retried here.%s" % [name(skill), (" " + note) if note != "" else ""]
		)
	var take := int(opts.get("take", 0))
	if take != 0 and take != 10 and take != 20:
		return _unavailable("Take must be 0, 10 or 20.")
	if take != 0 and bool(opts.get("threatened", false)):
		return _unavailable("You cannot take %d while threatened or in combat." % take)
	if take != 0 and bool(opts.get("distracted", false)):
		return _unavailable("You cannot take %d while distracted." % take)
	if take == 20 and bool(opts.get("failure_penalty", false)):
		return _unavailable("Taking 20 is impossible when failure carries a penalty.")
	var bonus := total(ch, skill, opts)
	var roll := int(take) if take != 0 else Dice.d20(rng)
	var total_value := roll + bonus
	return {
		"ok": true,
		"available": true,
		"reason": "",
		"roll": roll,
		"bonus": bonus,
		"total": total_value,
		"dc": dc,
		"success": total_value >= dc,
		"skill": skill,
		"actor": ch.display_name,
		"mode": ("take %d" % take) if take != 0 else "roll",
		"take": take,
		"breakdown": breakdown(ch, skill, opts),
	}


## Aid Another (PHB p.65): a helper succeeds on DC 10 and grants +2.
## The helper must be able to attempt the same task; the caller decides who
## may help.
static func aid_another(
	rng: RandomNumberGenerator, helper: Character, skill: String, opts: Dictionary = {}
) -> Dictionary:
	var result := check(rng, helper, skill, 10, opts)
	var success := bool(result.get("available", false)) and bool(result.get("success", false))
	return {
		"ok": success,
		"bonus": 2 if success else 0,
		"check": result,
		"message": (
			"%s aids %s: %+d"
			% [helper.display_name, name(skill), 2 if success else 0]
		),
	}


## Opposed check (PHB p.64): higher total wins; on a tie the higher skill
## modifier wins; if those are equal, roll again. opts["ties"] may be
## "defender" for the Hide/Move Silently examples where the observer wins ties.
static func opposed_check(
	rng: RandomNumberGenerator,
	actor: Character,
	actor_skill: String,
	defender: Character,
	defender_skill: String,
	opts: Dictionary = {}
) -> Dictionary:
	var actor_opts: Dictionary = Dictionary(opts.get("actor", {}))
	var defender_opts: Dictionary = Dictionary(opts.get("defender", {}))
	var actor_check := check(rng, actor, actor_skill, 0, actor_opts)
	var defender_check := check(rng, defender, defender_skill, 0, defender_opts)
	if not bool(actor_check.get("available", false)):
		return {"ok": false, "reason": actor_check.get("reason", ""), "actor": actor_check, "defender": defender_check}
	if not bool(defender_check.get("available", false)):
		return {"ok": false, "reason": defender_check.get("reason", ""), "actor": actor_check, "defender": defender_check}
	var rerolls := 0
	var winner := ""
	while true:
		var actor_total := int(actor_check["total"])
		var defender_total := int(defender_check["total"])
		if actor_total > defender_total:
			winner = "actor"
		elif defender_total > actor_total:
			winner = "defender"
		elif String(opts.get("ties", "higher_modifier")) == "defender":
			winner = "defender"
		elif int(actor_check["bonus"]) > int(defender_check["bonus"]):
			winner = "actor"
		elif int(defender_check["bonus"]) > int(actor_check["bonus"]):
			winner = "defender"
		else:
			rerolls += 1
			if rerolls > 20:
				winner = "defender"
				break
			# A reroll is a real roll, never another take 10/20.
			actor_check = check(rng, actor, actor_skill, 0, _without_take(actor_opts))
			defender_check = check(rng, defender, defender_skill, 0, _without_take(defender_opts))
			continue
		break
	return {
		"ok": true,
		"success": winner == "actor",
		"winner": winner,
		"rerolls": rerolls,
		"actor": actor_check,
		"defender": defender_check,
	}


static func _without_take(opts: Dictionary) -> Dictionary:
	var copy := opts.duplicate(true)
	copy.erase("take")
	return copy


static func format_check(result: Dictionary) -> String:
	if not bool(result.get("available", true)):
		return String(result.get("reason", "Check unavailable."))
	var mode := String(result.get("mode", "roll"))
	var roll_text := "d20(%d)" % int(result["roll"])
	if mode.begins_with("take"):
		roll_text = "%s → %d" % [mode, int(result["roll"])]
	return "%s %s: %s%+d = %d vs DC %d — %s" % [
		String(result.get("actor", "")),
		name(String(result.get("skill", ""))),
		roll_text,
		int(result["bonus"]),
		int(result["total"]),
		int(result["dc"]),
		"success" if bool(result["success"]) else "failure",
	]
