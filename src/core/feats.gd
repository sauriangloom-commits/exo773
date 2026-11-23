class_name Feats
extends RefCounted

## Player's Handbook feats that this slice actually resolves.
##
## The full PHB feat list is cataloged in docs/FEATS_SKILLS_COVERAGE.md. Only
## feats listed here can be selected or applied; an unknown name is a content
## error, never a silent bonus. Prerequisites are re-evaluated on every use, so
## a temporarily lost prerequisite (for example Strength damage) also suspends
## the feat's benefit (PHB p.87).
##
## Source pages are printed PHB pages. PHB PDF page = printed + 1.

const CATALOG := {
	"iron_will": {
		"name": "Iron Will",
		"fighter_bonus": false,
		"page": 95,
		"benefit": "+2 bonus on Will saves",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [{"target": "save:will", "value": 2, "type": "untyped"}],
	},
	"lightning_reflexes": {
		"name": "Lightning Reflexes",
		"fighter_bonus": false,
		"page": 96,
		"benefit": "+2 bonus on Reflex saves",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [{"target": "save:ref", "value": 2, "type": "untyped"}],
	},
	"great_fortitude": {
		"name": "Great Fortitude",
		"fighter_bonus": false,
		"page": 94,
		"benefit": "+2 bonus on Fortitude saves",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [{"target": "save:fort", "value": 2, "type": "untyped"}],
	},
	"combat_casting": {
		"name": "Combat Casting",
		"fighter_bonus": false,
		"page": 92,
		"benefit": "+4 on Concentration checks made to cast on the defensive (grappling and pinned are not modeled)",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		# PHB p. 92: the bonus applies only to checks made to cast a spell or
		# spell-like ability while on the defensive, or while grappling or
		# pinned. Grappling and pinning are not modeled, so the condition keeps
		# the bonus off ordinary injury checks and off every other use.
		"modifiers": [
			{
				"target": "skill:concentration",
				"value": 4,
				"type": "untyped",
				"condition": {"defensive_casting": true},
			}
		],
	},
	"dodge": {
		"name": "Dodge",
		"fighter_bonus": true,
		"page": 92,
		"benefit": "+1 dodge bonus to AC",
		"prereqs": [{"type": "ability", "ability": "dex", "value": 13}],
		"repeatable": false,
		"stacks": false,
		"modifiers": [{"target": "ac", "value": 1, "type": "dodge"}],
	},
	"improved_initiative": {
		"name": "Improved Initiative",
		"fighter_bonus": false,
		"page": 95,
		"benefit": "+4 bonus on initiative checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [{"target": "initiative", "value": 4, "type": "untyped"}],
	},
	"alertness": {
		"name": "Alertness",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "+2 bonus on Listen and Spot checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:listen", "value": 2, "type": "untyped"},
			{"target": "skill:spot", "value": 2, "type": "untyped"},
		],
	},
	"armor_proficiency_light": {
		"name": "Armor Proficiency (light)",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "Wear light armor with only the standard armor check penalties",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
		"grants_proficiency": "light_armor",
	},
	"armor_proficiency_medium": {
		"name": "Armor Proficiency (medium)",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "Wear medium armor with only the standard armor check penalties",
		"prereqs": [{"type": "feat", "value": "armor_proficiency_light"}],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
		"grants_proficiency": "medium_armor",
	},
	"armor_proficiency_heavy": {
		"name": "Armor Proficiency (heavy)",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "Wear heavy armor with only the standard armor check penalties",
		"prereqs": [
			{"type": "feat", "value": "armor_proficiency_light"},
			{"type": "feat", "value": "armor_proficiency_medium"},
		],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
		"grants_proficiency": "heavy_armor",
	},
	"shield_proficiency": {
		"name": "Shield Proficiency",
		"fighter_bonus": false,
		"page": 100,
		"benefit": "Use bucklers, small shields and large shields with standard penalties",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
		"grants_proficiency": "shield",
	},
	"simple_weapon_proficiency": {
		"name": "Simple Weapon Proficiency",
		"fighter_bonus": false,
		"page": 100,
		"benefit": "No -4 non-proficiency penalty with simple weapons",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
		"grants_proficiency": "simple",
	},
	"martial_weapon_proficiency": {
		"name": "Martial Weapon Proficiency",
		"fighter_bonus": false,
		"page": 97,
		"benefit": "No -4 non-proficiency penalty with the selected martial weapon",
		"parameter": "weapon",
		"prereqs": [],
		"repeatable": true,
		"stacks": false,
		"modifiers": [],
		"grants_selected_proficiency": true,
	},
	"exotic_weapon_proficiency": {
		"name": "Exotic Weapon Proficiency",
		"fighter_bonus": true,
		"page": 94,
		"benefit": "No -4 non-proficiency penalty with the selected exotic weapon",
		"parameter": "weapon",
		"prereqs": [{"type": "bab", "value": 1}],
		"repeatable": true,
		"stacks": false,
		"modifiers": [],
		"grants_selected_proficiency": true,
	},
	"extra_turning": {
		"name": "Extra Turning",
		"fighter_bonus": false,
		"page": 94,
		"benefit": "+4 turning attempts per day, stacking each time it is taken",
		"prereqs": [{"type": "turn_undead"}],
		"repeatable": true,
		"stacks": true,
		"modifiers": [],
	},
	"improved_turning": {
		"name": "Improved Turning",
		"fighter_bonus": false,
		"page": 96,
		"benefit": "Turn or rebuke undead as if one cleric level higher",
		"prereqs": [{"type": "turn_undead"}],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
	"acrobatic": {
		"name": "Acrobatic",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "+2 bonus on all Jump and Tumble checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:jump", "value": 2, "type": "untyped"},
			{"target": "skill:tumble", "value": 2, "type": "untyped"},
		],
	},
	"agile": {
		"name": "Agile",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "+2 bonus on all Balance and Escape Artist checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:balance", "value": 2, "type": "untyped"},
			{"target": "skill:escape_artist", "value": 2, "type": "untyped"},
		],
	},
	"animal_affinity": {
		"name": "Animal Affinity",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "+2 bonus on all Handle Animal and Ride checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:handle_animal", "value": 2, "type": "untyped"},
			{"target": "skill:ride", "value": 2, "type": "untyped"},
		],
	},
	"athletic": {
		"name": "Athletic",
		"fighter_bonus": false,
		"page": 89,
		"benefit": "+2 bonus on all Climb and Swim checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:climb", "value": 2, "type": "untyped"},
			{"target": "skill:swim", "value": 2, "type": "untyped"},
		],
	},
	"deceitful": {
		"name": "Deceitful",
		"fighter_bonus": false,
		"page": 93,
		"benefit": "+2 bonus on all Disguise and Forgery checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:disguise", "value": 2, "type": "untyped"},
			{"target": "skill:forgery", "value": 2, "type": "untyped"},
		],
	},
	"deft_hands": {
		"name": "Deft Hands",
		"fighter_bonus": false,
		"page": 93,
		"benefit": "+2 bonus on all Sleight of Hand and Use Rope checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:sleight_of_hand", "value": 2, "type": "untyped"},
			{"target": "skill:use_rope", "value": 2, "type": "untyped"},
		],
	},
	"diligent": {
		"name": "Diligent",
		"fighter_bonus": false,
		"page": 93,
		"benefit": "+2 bonus on all Appraise and Decipher Script checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:appraise", "value": 2, "type": "untyped"},
			{"target": "skill:decipher_script", "value": 2, "type": "untyped"},
		],
	},
	"investigator": {
		"name": "Investigator",
		"fighter_bonus": false,
		"page": 97,
		"benefit": "+2 bonus on all Gather Information and Search checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:gather_information", "value": 2, "type": "untyped"},
			{"target": "skill:search", "value": 2, "type": "untyped"},
		],
	},
	"magical_aptitude": {
		"name": "Magical Aptitude",
		"fighter_bonus": false,
		"page": 97,
		"benefit": "+2 bonus on all Spellcraft and Use Magic Device checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:spellcraft", "value": 2, "type": "untyped"},
			{"target": "skill:use_magic_device", "value": 2, "type": "untyped"},
		],
	},
	"negotiator": {
		"name": "Negotiator",
		"fighter_bonus": false,
		"page": 98,
		"benefit": "+2 bonus on all Diplomacy and Sense Motive checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:diplomacy", "value": 2, "type": "untyped"},
			{"target": "skill:sense_motive", "value": 2, "type": "untyped"},
		],
	},
	"nimble_fingers": {
		"name": "Nimble Fingers",
		"fighter_bonus": false,
		"page": 98,
		"benefit": "+2 bonus on all Disable Device and Open Lock checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:disable_device", "value": 2, "type": "untyped"},
			{"target": "skill:open_lock", "value": 2, "type": "untyped"},
		],
	},
	"persuasive": {
		"name": "Persuasive",
		"fighter_bonus": false,
		"page": 98,
		"benefit": "+2 bonus on all Bluff and Intimidate checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:bluff", "value": 2, "type": "untyped"},
			{"target": "skill:intimidate", "value": 2, "type": "untyped"},
		],
	},
	"self_sufficient": {
		"name": "Self-Sufficient",
		"fighter_bonus": false,
		"page": 100,
		"benefit": "+2 bonus on all Heal and Survival checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:heal", "value": 2, "type": "untyped"},
			{"target": "skill:survival", "value": 2, "type": "untyped"},
		],
	},
	"stealthy": {
		"name": "Stealthy",
		"fighter_bonus": false,
		"page": 101,
		"benefit": "+2 bonus on all Hide and Move Silently checks",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{"target": "skill:hide", "value": 2, "type": "untyped"},
			{"target": "skill:move_silently", "value": 2, "type": "untyped"},
		],
	},
	"skill_focus": {
		"name": "Skill Focus",
		"fighter_bonus": false,
		"page": 100,
		"benefit": "+3 bonus on checks with the selected skill",
		"parameter": "skill",
		"prereqs": [],
		"repeatable": true,
		"stacks": false,
		"modifiers": [{"target": "skill", "value": 3, "type": "untyped"}],
	},
	"weapon_focus": {
		"name": "Weapon Focus",
		"fighter_bonus": true,
		"page": 102,
		"benefit": "+1 bonus on attack rolls with the selected weapon",
		"parameter": "weapon",
		"prereqs": [
			{"type": "bab", "value": 1},
			{"type": "proficient", "parameter": true},
		],
		"repeatable": true,
		"stacks": false,
		"modifiers": [
			{"target": "attack", "value": 1, "type": "untyped", "weapon_parameter": true}
		],
	},
	"weapon_specialization": {
		"name": "Weapon Specialization",
		"fighter_bonus": true,
		"page": 102,
		"benefit": "+2 bonus on damage rolls with the selected weapon",
		"parameter": "weapon",
		"prereqs": [
			{"type": "proficient", "parameter": true},
			{"type": "feat", "value": "weapon_focus", "same_weapon": true},
			{"type": "class_level", "class": "fighter", "value": 4},
		],
		"repeatable": true,
		"stacks": false,
		"modifiers": [
			{"target": "damage", "value": 2, "type": "untyped", "weapon_parameter": true}
		],
	},
	"weapon_finesse": {
		"name": "Weapon Finesse",
		"fighter_bonus": true,
		"page": 102,
		"benefit": "Use Dexterity instead of Strength on attack rolls with light melee weapons",
		"prereqs": [
			{"type": "bab", "value": 1},
			{"type": "light_weapon_proficiency"},
		],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
	"power_attack": {
		"name": "Power Attack",
		"fighter_bonus": true,
		"page": 98,
		"benefit": "Trade melee attack bonus for damage, up to base attack bonus",
		"prereqs": [{"type": "ability", "ability": "str", "value": 13}],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
	"combat_expertise": {
		"name": "Combat Expertise",
		"fighter_bonus": true,
		"page": 92,
		"benefit": "Trade up to 5 points of melee attack bonus for the same dodge bonus to AC",
		"prereqs": [{"type": "ability", "ability": "int", "value": 13}],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
	"cleave": {
		"name": "Cleave",
		"fighter_bonus": true,
		"page": 92,
		"benefit": "One extra melee attack after dropping a creature with a melee attack",
		"prereqs": [
			{"type": "ability", "ability": "str", "value": 13},
			{"type": "feat", "value": "power_attack"},
		],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
	"improved_trip": {
		"name": "Improved Trip",
		"fighter_bonus": true,
		"page": 96,
		"benefit": "Trip unarmed without provoking, +4 on the trip check, and an immediate melee attack after a successful trip",
		"prereqs": [
			{"type": "ability", "ability": "int", "value": 13},
			{"type": "feat", "value": "combat_expertise"},
		],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
	"point_blank_shot": {
		"name": "Point Blank Shot",
		"fighter_bonus": true,
		"page": 98,
		"benefit": "+1 bonus on ranged attack and damage rolls within 30 ft.",
		"prereqs": [],
		"repeatable": false,
		"stacks": false,
		"modifiers": [
			{
				"target": "attack",
				"value": 1,
				"type": "untyped",
				"condition": {"ranged": true, "max_distance_ft": 30},
			},
			{
				"target": "damage",
				"value": 1,
				"type": "untyped",
				"condition": {"ranged": true, "max_distance_ft": 30},
			},
		],
	},
	# Precise Shot has no passive modifier: it removes the -4 penalty for
	# shooting or throwing into a melee, which the encounter evaluates against
	# the target's neighbours (PHB pp. 98, 140). Kept in the catalog so content
	# can take it, its prerequisite is enforced, and the rules code can ask
	# `has_active`. Complete Arcane p. 73 extends the same feat to ranged spells.
	"precise_shot": {
		"name": "Precise Shot",
		"fighter_bonus": true,
		"page": 98,
		"benefit": "No -4 penalty for shooting or throwing into a melee, or for a ranged spell fired into a melee",
		"prereqs": [{"type": "feat", "value": "point_blank_shot"}],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
	"toughness": {
		"name": "Toughness",
		"fighter_bonus": false,
		"page": 101,
		"benefit": "+3 hit points",
		"prereqs": [],
		"repeatable": true,
		"stacks": true,
		"modifiers": [{"target": "hit_points", "value": 3, "type": "untyped"}],
	},
	"multiattack": {
		"name": "Multiattack",
		"fighter_bonus": false,
		"page": 304,
		"benefit": "Secondary natural attacks take only a -2 penalty",
		"prereqs": [{"type": "natural_attacks", "value": 3}],
		"repeatable": false,
		"stacks": false,
		"modifiers": [],
	},
}


## Splits "Weapon Focus (longsword)" into a stable key and a parameter.
## Feats without parentheses have an empty parameter.
static func parse(feat_text: String) -> Dictionary:
	var raw := feat_text.strip_edges()
	var base := raw
	var parameter := ""
	var open := raw.find("(")
	if open >= 0:
		base = raw.substr(0, open).strip_edges()
		parameter = raw.substr(open + 1).strip_edges()
		if parameter.ends_with(")"):
			parameter = parameter.substr(0, parameter.length() - 1).strip_edges()
	var key := base.to_lower().replace("-", " ").replace(" ", "_")
	# Armor proficiency is three distinct feats whose printed names include the
	# selected category in parentheses (PHB p.89). Prefer the base key when it
	# exists (Weapon Focus, Skill Focus), otherwise resolve the complete name.
	if not CATALOG.has(key) and parameter != "":
		var complete := (base + " " + parameter).to_lower().replace("-", " ").replace(" ", "_")
		if CATALOG.has(complete):
			key = complete
	return {"key": key, "name": base, "param": parameter, "raw": raw}


## True for the feats Table 5-1 marks with footnote 1 (PHB p. 90): "A fighter may
## select this feat as one of his fighter bonus feats." The fighter's Bonus Feats
## entry on p. 38 points at that table. Metadata only: no rules path reads it yet.
static func is_fighter_bonus(key: String) -> bool:
	return bool(CATALOG.get(key, {}).get("fighter_bonus", false))


static func entry(key: String) -> Dictionary:
	return CATALOG.get(key, {})


static func is_known(feat_text: String) -> bool:
	return not CATALOG.get(String(parse(feat_text).get("key", "")), {}).is_empty()


## Player-facing feat text. The stored text is "Name (parameter)", and for a weapon
## parameter the parameter is an item id, so the display resolves the shipped item's
## own name ("masterwork_longsword" -> "Masterwork Longsword"). It is read from
## content, never from a table: an id with no item entry, a bare authored name and an
## unknown id all fall back to the text as written. Weapon parameters only - a skill
## parameter keeps the content id it already showed.
static func display_label(feat_text: String) -> String:
	var parsed := parse(feat_text)
	var data: Dictionary = CATALOG.get(parsed["key"], {})
	if data.is_empty():
		return String(parsed["raw"])
	var name := String(data.get("name", parsed["name"]))
	var parameter := String(parsed["param"])
	if parameter == "":
		return name
	if String(data.get("parameter", "")) == "weapon":
		var item := _selected_weapon(parameter)
		var item_name := String(item.get("name", "")).strip_edges()
		if item_name != "":
			return "%s (%s)" % [name, item_name]
	return "%s (%s)" % [name, parameter]


## Display name of a stored feat. Kept as the one entry point for surfaces that
## already used it; it is the same text `display_label` returns.
static func display_name(feat_text: String) -> String:
	return display_label(feat_text)


## True when the character's list contains this feat, whether or not the catalog
## implements it. "Armed" unarmed status (PHB p. 139) depends on possessing Improved
## Unarmed Strike, whose damage rules are not part of this build, so the raw text is
## what matters here.
static func has_feat(ch: Character, key: String) -> bool:
	for feat_text in ch.feats:
		if String(parse(String(feat_text))["key"]) == key:
			return true
	return false


## True when the character owns the feat for this specific weapon. The authored
## parameter and the screen's parameter can differ in form - "longsword" against
## the item id "masterwork_longsword" - so the match uses the same weapon matcher
## the weapon-parameterised modifier uses. A copy whose own prerequisites no longer
## hold does not count.
static func has_feat_for_weapon(ch: Character, key: String, weapon_id: String) -> bool:
	var selected := _selected_weapon(weapon_id)
	for feat_text in ch.feats:
		var parsed := parse(String(feat_text))
		if String(parsed["key"]) != key:
			continue
		var parameter := String(parsed["param"])
		if parameter == "":
			continue
		var matches := (
			_weapon_matches(parameter, selected)
			if not selected.is_empty()
			else parameter.to_lower() == weapon_id.to_lower()
		)
		if not matches:
			continue
		if bool(prereqs(ch, key, parameter)["ok"]):
			return true
	return false


static func _selected_weapon(weapon_id: String) -> Dictionary:
	if Game.content == null:
		return {}
	var item: Variant = Game.content.items.get(weapon_id)
	if item == null:
		return {}
	return Dictionary(item)


## True when the character has the feat and still meets its prerequisites.
static func has_active(ch: Character, key: String, parameter := "") -> bool:
	for feat_text in ch.feats:
		var parsed := parse(String(feat_text))
		if String(parsed["key"]) != key:
			continue
		if parameter != "" and String(parsed["param"]).to_lower() != parameter.to_lower():
			continue
		if bool(prereqs(ch, key, String(parsed["param"]))["ok"]):
			return true
	return false


## Evaluates every prerequisite, with player-facing reasons for each failure.
static func prereqs(ch: Character, key: String, parameter := "") -> Dictionary:
	var data: Dictionary = CATALOG.get(key, {})
	if data.is_empty():
		return {"ok": false, "reasons": ["'%s' is not an implemented feat." % key]}
	var reasons: Array[String] = []
	var requires_parameter := String(data.get("parameter", ""))
	if requires_parameter != "" and parameter.strip_edges() == "":
		reasons.append("requires a %s selection" % requires_parameter)
	for req in Array(data.get("prereqs", [])):
		var reason := _check_requirement(ch, req, parameter)
		if reason != "":
			reasons.append(reason)
	if key == "exotic_weapon_proficiency":
		var selected := _normalize_proficiency(parameter)
		if selected in ["bastard sword", "dwarven waraxe"] and int(ch.abilities.get("str", 10)) < 13:
			reasons.append("requires STR 13 for %s" % parameter)
	if key == "martial_weapon_proficiency" and parameter.strip_edges() != "":
		var category := _lookup_weapon_category(parameter)
		if category != "" and category != "martial":
			reasons.append("%s is not a martial weapon" % parameter)
	if key == "exotic_weapon_proficiency" and parameter.strip_edges() != "":
		var category := _lookup_weapon_category(parameter)
		if category != "" and category != "exotic":
			reasons.append("%s is not an exotic weapon" % parameter)
	return {"ok": reasons.is_empty(), "reasons": reasons}


static func _check_requirement(ch: Character, req: Dictionary, parameter: String) -> String:
	match String(req.get("type", "")):
		"ability":
			var ability := String(req.get("ability", "str"))
			var needed := int(req.get("value", 10))
			var score := int(ch.abilities.get(ability, 10))
			if score < needed:
				return "requires %s %d (has %d)" % [ability.to_upper(), needed, score]
		"bab":
			var needed_bab := int(req.get("value", 1))
			if ch.base_attack < needed_bab:
				return "requires base attack bonus +%d (has +%d)" % [needed_bab, ch.base_attack]
		"level":
			var needed_level := int(req.get("value", 1))
			if ch.level < needed_level:
				return "requires character level %d (has %d)" % [needed_level, ch.level]
		"feat":
			var needed_feat := String(req.get("value", ""))
			if bool(req.get("same_weapon", false)):
				if not has_feat_for_weapon(ch, needed_feat, parameter):
					return "requires %s with the selected weapon" % display_name(needed_feat)
			elif not has_active(ch, needed_feat):
				return "requires the %s feat" % display_name(needed_feat)
		"class_level":
			# `char_class` is free text and `ch.level` is the character's one level;
			# there is no multiclass model, so the class must match exactly (case
			# aside) and nothing is parsed out of a composite string.
			var needed_class := String(req.get("class", "")).to_lower()
			var needed_class_level := int(req.get("value", 1))
			if ch.char_class.to_lower() != needed_class:
				return "requires %s level %d (this character is '%s')" % [
					needed_class, needed_class_level, ch.char_class
				]
			if ch.level < needed_class_level:
				return "requires %s level %d (has %d)" % [
					needed_class, needed_class_level, ch.level
				]
		"turn_undead":
			if ch.cleric_level() <= 0:
				return "requires the ability to turn or rebuke undead"
		"skill_ranks":
			var skill := String(req.get("skill", ""))
			var needed_ranks := int(req.get("value", 1))
			var ranks := int(ch.skill_ranks.get(skill, 0))
			if ranks < needed_ranks:
				return "requires %d ranks in %s (has %d)" % [
					needed_ranks, Skills.name(skill), ranks
				]
		"natural_attacks":
			var needed_attacks := int(req.get("value", 3))
			if ch.attacks.size() < needed_attacks:
				return "requires %d natural attacks (has %d)" % [needed_attacks, ch.attacks.size()]
		"proficient":
			if not is_proficient(ch, parameter):
				return "requires proficiency with %s" % (
					parameter if parameter != "" else "the selected weapon"
				)
		"light_weapon_proficiency":
			if not has_light_weapon_proficiency(ch):
				return "requires proficiency with a light melee weapon"
		_:
			return "has an unsupported prerequisite type '%s'" % req.get("type", "")
	return ""


## Proficiencies are authored data so class-specific exceptions stay visible.
## Feats that grant proficiencies are added on top of the authored list; the
## original list is never rewritten by a feat.
static func granted_proficiencies(ch: Character) -> Array[String]:
	var result: Array[String] = []
	for feat_text in ch.feats:
		var parsed := parse(String(feat_text))
		var key := String(parsed["key"])
		var data: Dictionary = CATALOG.get(key, {})
		if data.is_empty():
			continue
		# Skip unrelated feats before evaluating prerequisites. In particular,
		# Weapon Finesse's prerequisite itself asks for weapon proficiency, so
		# evaluating every feat here would recurse back into this function.
		if not data.has("grants_proficiency") and not bool(data.get("grants_selected_proficiency", false)):
			continue
		if not bool(prereqs(ch, key, String(parsed["param"]))["ok"]):
			continue
		if data.has("grants_proficiency"):
			var category := _normalize_proficiency(String(data["grants_proficiency"]))
			if category != "" and not result.has(category):
				result.append(category)
		elif bool(data.get("grants_selected_proficiency", false)):
			var parameter := _normalize_proficiency(String(parsed["param"]))
			if parameter != "" and not result.has(parameter):
				result.append(parameter)
	return result


## A category (simple, martial, light_armor, shield) or an exact weapon name.
static func _has_proficiency(ch: Character, value: String) -> bool:
	var needle := _normalize_proficiency(value)
	if needle == "":
		return false
	for raw in ch.proficiencies:
		if _normalize_proficiency(String(raw)) == needle:
			return true
	for raw in granted_proficiencies(ch):
		if _normalize_proficiency(raw) == needle:
			return true
	return false


static func is_armor_proficient(ch: Character, armor: Dictionary) -> bool:
	var category := _normalize_proficiency(
		String(armor.get("armor_category", armor.get("proficiency", "")))
	)
	if category == "":
		return true  # legacy content without metadata is not retroactively penalised
	return _has_proficiency(ch, category)


static func is_shield_proficient(ch: Character, shield: Dictionary) -> bool:
	var category := _normalize_proficiency(
		String(shield.get("proficiency", shield.get("armor_category", "")))
	)
	if category == "":
		return true
	return _has_proficiency(ch, category)


## Proficiency for an actual weapon dictionary. Natural attacks and unarmed
## strikes are always proficient; manufactured weapons use their authored
## category (simple/martial/exotic), an exact item name, or a proficiency feat.
static func is_weapon_proficient(ch: Character, weapon: Dictionary) -> bool:
	if weapon.is_empty():
		return true
	if ch.is_monster or bool(weapon.get("natural", false)):
		return true
	var name := String(weapon.get("name", weapon.get("id", "")))
	var item_id := String(weapon.get("id", ""))
	if _normalize_proficiency(name) == "unarmed strike":
		return true
	var category := _normalize_proficiency(String(weapon.get("category", "")))
	if category == "":
		category = _lookup_weapon_category(name)
	if _has_proficiency(ch, "all"):
		return true
	if category != "" and _has_proficiency(ch, category):
		return true
	if category == "simple" and has_active(ch, "simple_weapon_proficiency"):
		return true
	for value in ch.proficiencies:
		if _proficiency_matches(value, name) or _proficiency_matches(value, item_id):
			return true
	for value in granted_proficiencies(ch):
		if _proficiency_matches(value, name) or _proficiency_matches(value, item_id):
			return true
	return false


## Name-level check used by Weapon Focus prerequisites. The item catalogue is
## consulted only to resolve a name to its category; authored categories still
## work when content has not been assigned yet.
static func is_proficient(ch: Character, weapon_name: String) -> bool:
	if weapon_name.strip_edges() == "":
		return false
	var needle := _normalize_proficiency(weapon_name)
	for value in ch.proficiencies:
		if _proficiency_matches(value, needle):
			return true
	for value in granted_proficiencies(ch):
		if _proficiency_matches(value, needle):
			return true
	var category := _lookup_weapon_category(weapon_name)
	if category != "":
		if _has_proficiency(ch, category):
			return true
		if category == "simple" and has_active(ch, "simple_weapon_proficiency"):
			return true
	else:
		# "all" is the only category that can satisfy an unresolved name;
		# silently treating every unknown name as martial would let Weapon
		# Focus (sword) pass from a short-sword proficiency.
		return _has_proficiency(ch, "all")
	return false


static func _normalize_proficiency(value: String) -> String:
	return value.to_lower().replace("_", " ").replace("-", " ").strip_edges()


static func _proficiency_matches(value: String, needle: String) -> bool:
	var owned := _normalize_proficiency(value)
	var wanted := _normalize_proficiency(needle)
	if owned == "" or wanted == "":
		return false
	if owned == wanted:
		return true
	# The one permitted qualifier in shipped data is a masterwork item prefix.
	# Do not use arbitrary substring matching: "short sword" must not satisfy
	# a proficiency or Weapon Focus for "sword".
	for prefix in ["masterwork ", "mwk "]:
		if owned == prefix + wanted or wanted == prefix + owned:
			return true
	return false


static func _lookup_weapon_category(weapon_name: String) -> String:
	var needle := _normalize_proficiency(weapon_name)
	if needle == "" or Game.content == null:
		return ""
	for item_id in Game.content.items.keys():
		var item: Dictionary = Game.content.items[item_id]
		if String(item.get("kind", "")) != "weapon":
			continue
		if _proficiency_matches(String(item_id), needle) or _proficiency_matches(
			String(item.get("name", "")), needle
		):
			return _normalize_proficiency(String(item.get("category", "")))
	return ""


static func has_light_weapon_proficiency(ch: Character) -> bool:
	var weapon: Dictionary = ch.equipment.get("weapon", {})
	if weapon.is_empty() or not bool(weapon.get("light_weapon", false)):
		return false
	return is_weapon_proficient(ch, weapon)


## Extra Turning is repeatable; every prerequisite-valid copy adds four uses
## per day (PHB p.94).
static func extra_turning_uses(ch: Character) -> int:
	var count := 0
	for feat_text in ch.feats:
		var parsed := parse(String(feat_text))
		if String(parsed["key"]) != "extra_turning":
			continue
		if bool(prereqs(ch, "extra_turning", String(parsed["param"]))["ok"]):
			count += 1
	return count * 4


## Improved Turning adds one effective cleric level for turning checks,
## turning damage and the destruction threshold (PHB p.96).
static func turn_level_bonus(ch: Character) -> int:
	return 1 if has_active(ch, "improved_turning") else 0


## Power Attack's trade is bounded by base attack bonus (PHB p.98). The
## encounter validates the player's chosen amount before resolving the attack.
static func power_attack_max(ch: Character) -> int:
	if not has_active(ch, "power_attack"):
		return 0
	return maxi(0, ch.base_attack)


static func power_attack_attack_penalty(ch: Character, amount: int) -> int:
	return -clampi(amount, 0, power_attack_max(ch))


## Combat Expertise is bounded by both its printed +5 limit and base attack
## bonus (PHB p. 92). The committed value is stored on the combatant as a
## temporary effect so AC uses can see it without a separate per-attack flag.
static func combat_expertise_max(ch: Character) -> int:
	if not has_active(ch, "combat_expertise"):
		return 0
	return mini(5, maxi(0, ch.base_attack))


static func combat_expertise_attack_penalty(ch: Character, amount: int) -> int:
	return -clampi(amount, 0, combat_expertise_max(ch))


## The committed amount is a dodge bonus. Re-check the feat and cap on every
## AC calculation, so a temporary prerequisite loss suspends the benefit.
## Improved Trip's +4 applies to the attacker's own Strength check to trip an
## opponent (PHB p.96). It is not a size bonus and does not apply to the touch
## attack, the defender's opposed check, or a counter-trip.
static func improved_trip_check_bonus(ch: Character) -> int:
	return 4 if has_active(ch, "improved_trip") else 0


static func improved_trip_follow_up(ch: Character) -> bool:
	return has_active(ch, "improved_trip")


## Cleave (PHB p.92) is usable once per round; the encounter tracks the use.
static func cleave_available(ch: Character) -> bool:
	return has_active(ch, "cleave")


static func combat_expertise_dodge_bonus(ch: Character) -> int:
	if not has_active(ch, "combat_expertise"):
		return 0
	var effect := ch.get_effect("combat_expertise")
	if effect.is_empty():
		return 0
	return clampi(int(effect.get("value", 0)), 0, combat_expertise_max(ch))


## Light weapons gain no Power Attack damage (except unarmed/natural attacks),
## and two-handed weapons gain twice the amount subtracted (PHB p.98).
static func power_attack_damage_bonus(
	ch: Character, weapon: Dictionary, amount: int, attack_mode := ""
) -> int:
	if amount <= 0 or weapon.is_empty():
		return 0
	var max_amount := power_attack_max(ch)
	if max_amount <= 0 or Rules.is_ranged_weapon(weapon, attack_mode):
		return 0
	var value := clampi(amount, 0, max_amount)
	var name := _normalize_proficiency(String(weapon.get("name", "")))
	var unarmed_or_natural := bool(weapon.get("natural", false)) or name == "unarmed strike"
	if bool(weapon.get("light_weapon", false)) and not unarmed_or_natural:
		return 0
	var multiplier := 2 if bool(weapon.get("two_handed", false)) else 1
	return value * multiplier


## Weapon Finesse is an attack-roll substitution, not a bonus. It requires a
## light melee weapon and proficiency with that weapon (PHB p.102).
static func can_use_weapon_finesse(ch: Character, weapon: Dictionary) -> bool:
	if not has_active(ch, "weapon_finesse"):
		return false
	if weapon.is_empty() or Rules.is_ranged_weapon(weapon):
		return false
	if not bool(weapon.get("light_weapon", false)):
		return false
	return is_weapon_proficient(ch, weapon)


## Stacks the active feat bonuses for one target. Every use re-checks
## prerequisites, so a lost prerequisite suspends the benefit.
## targets: save:fort|ref|will, ac, initiative, hit_points, attack, damage,
##          skill:<key>, skill (parameterised Skill Focus)
static func modifier(ch: Character, target: String, opts: Dictionary = {}) -> Dictionary:
	var entries: Array = []
	# A feat that is not repeatable contributes once even if its text appears
	# twice in a save; content validation still reports the duplicate as an error.
	var counted: Dictionary = {}
	for feat_text in ch.feats:
		var parsed := parse(String(feat_text))
		var key := String(parsed["key"])
		var data: Dictionary = CATALOG.get(key, {})
		if data.is_empty():
			continue
		var instance := key + "|" + String(parsed["param"]).to_lower()
		if not bool(data.get("repeatable", false)):
			if counted.has(instance):
				continue
			counted[instance] = true
		if not bool(prereqs(ch, key, String(parsed["param"]))["ok"]):
			continue
		for raw_mod in Array(data.get("modifiers", [])):
			var mod: Dictionary = raw_mod
			var mod_target := String(mod.get("target", ""))
			if mod_target == "skill":
				mod_target = "skill:" + String(parsed["param"]).to_lower().replace(" ", "_")
			if mod_target != target:
				continue
			if bool(mod.get("weapon_parameter", false)):
				if not _weapon_matches(String(parsed["param"]), Dictionary(opts.get("weapon", {}))):
					continue
			if not _condition_ok(mod, opts):
				continue
			var source := String(data.get("name", key))
			if String(parsed["param"]) != "":
				source += " (%s)" % parsed["param"]
			entries.append(
				{
					"value": int(mod.get("value", 0)),
					"type": String(mod.get("type", "untyped")),
					"source": source,
				}
			)
	return Rules.stack_bonuses(entries)


static func _weapon_matches(parameter: String, weapon: Dictionary) -> bool:
	if parameter.strip_edges() == "" or weapon.is_empty():
		return false
	var needle := parameter.to_lower().replace("_", " ").strip_edges()
	var haystack := (
		String(weapon.get("id", "")).to_lower().replace("_", " ")
		+ " "
		+ String(weapon.get("name", "")).to_lower()
	)
	return haystack.contains(needle)


static func _condition_ok(mod: Dictionary, opts: Dictionary) -> bool:
	var condition: Dictionary = mod.get("condition", {})
	if condition.is_empty():
		return true
	if bool(condition.get("ranged", false)) and not bool(opts.get("ranged", false)):
		return false
	if condition.has("max_distance_ft"):
		if int(opts.get("distance_ft", 0)) > int(condition["max_distance_ft"]):
			return false
	if condition.has("defensive_casting"):
		if bool(condition["defensive_casting"]) != bool(opts.get("defensive_casting", false)):
			return false
	return true


static func initiative_bonus(ch: Character) -> int:
	return int(modifier(ch, "initiative")["total"])


static func hit_point_bonus(ch: Character) -> int:
	return int(modifier(ch, "hit_points")["total"])


## Secondary natural attacks take -5 without Multiattack and -2 with it
## (MM p.304). The penalty is applied by Rules.attack_bonus, never baked into
## authored attack data.
static func secondary_attack_penalty(ch: Character) -> int:
	return -2 if has_active(ch, "multiattack") else -5


## Rows for the character sheet: name, active state, reason and benefit.
static func describe(ch: Character) -> Array:
	var rows: Array = []
	for feat_text in ch.feats:
		var parsed := parse(String(feat_text))
		var key := String(parsed["key"])
		var data: Dictionary = CATALOG.get(key, {})
		if data.is_empty():
			rows.append(
				{
					"name": parsed["raw"],
					"active": false,
					"reason": "not implemented in this build",
					"benefit": "",
					"page": 0,
				}
			)
			continue
		var check := prereqs(ch, key, String(parsed["param"]))
		rows.append(
			{
				"name": display_name(feat_text),
				"active": bool(check["ok"]),
				"reason": "; ".join(check["reasons"]),
				"benefit": String(data.get("benefit", "")),
				"page": int(data.get("page", 0)),
			}
		)
	return rows


## Content validation: unknown names, missing parameters and unmet
## prerequisites are errors rather than silently inert feats.
static func validate_for_character(ch: Character) -> Array[String]:
	var errors: Array[String] = []
	for feat_text in ch.feats:
		var parsed := parse(String(feat_text))
		var key := String(parsed["key"])
		var data: Dictionary = CATALOG.get(key, {})
		if data.is_empty():
			errors.append("%s has unimplemented feat '%s'." % [ch.id, feat_text])
			continue
		var check := prereqs(ch, key, String(parsed["param"]))
		if not bool(check["ok"]):
			errors.append(
				"%s does not meet the prerequisites for '%s': %s."
				% [ch.id, feat_text, "; ".join(check["reasons"])]
			)
	return errors
