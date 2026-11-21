class_name ClassProgression
extends RefCounted

## Class progression for the five shipped classes, levels 1-4.
##
## Data only: nothing reads this table for play yet (no level-up batch consumes
## it), so it changes no XP, level, save, UI or rules behaviour. `validate()` is
## the authority for the rows; `authored_inconsistencies()` reports, without
## repairing, where the authored level-3 party already disagrees with the printed
## tables.
##
## Sources: PHB Table 3-1 and Table 3-2, p. 22 (base attack, base saves, feats,
## ability increases, skill rank caps); Table 3-6, p. 31 (cleric); Table 3-9,
## p. 39 (fighter); Table 3-15, p. 49 (rogue); Table 3-16, p. 52 and Table 3-17,
## p. 54 (sorcerer); Table 3-18, p. 55 (wizard). Spell rows are the printed slots
## per day, 0-level included; the cleric row folds in its domain "+1" column as
## printed, and no row includes a high-ability bonus slot.

const LEVELS := [1, 2, 3, 4]
const HIT_DICE := [4, 6, 8, 10, 12]
const GENERAL_FEAT_LEVELS := [1, 3]

const CLASSES := {
	"cleric": {
		"name": "Cleric",
		"hit_die": 8,
		"skill_points": 2,
		"base_attack": "average",
		"good_saves": ["fort", "will"],
		"feat_levels": {"general": [1, 3], "class": []},
		"source": "PHB Table 3-6, p. 31",
		"rows": {
			1: {"base_attack": 0, "fort": 2, "ref": 0, "will": 2, "spells": {0: 3, 1: 2}},
			2: {"base_attack": 1, "fort": 3, "ref": 0, "will": 3, "spells": {0: 4, 1: 3}},
			3: {"base_attack": 2, "fort": 3, "ref": 1, "will": 3, "spells": {0: 4, 1: 3, 2: 2}},
			4: {"base_attack": 3, "fort": 4, "ref": 1, "will": 4, "spells": {0: 5, 1: 4, 2: 3}},
		},
	},
	"fighter": {
		"name": "Fighter",
		"hit_die": 10,
		"skill_points": 2,
		"base_attack": "good",
		"good_saves": ["fort"],
		"feat_levels": {"general": [1, 3], "class": [1, 2, 4]},
		"source": "PHB Table 3-9, p. 39",
		"rows": {
			1: {"base_attack": 1, "fort": 2, "ref": 0, "will": 0},
			2: {"base_attack": 2, "fort": 3, "ref": 0, "will": 0},
			3: {"base_attack": 3, "fort": 3, "ref": 1, "will": 1},
			4: {"base_attack": 4, "fort": 4, "ref": 1, "will": 1},
		},
	},
	"rogue": {
		"name": "Rogue",
		"hit_die": 6,
		"skill_points": 8,
		"base_attack": "average",
		"good_saves": ["ref"],
		"feat_levels": {"general": [1, 3], "class": []},
		"source": "PHB Table 3-15, p. 49",
		"rows": {
			1: {"base_attack": 0, "fort": 0, "ref": 2, "will": 0},
			2: {"base_attack": 1, "fort": 0, "ref": 3, "will": 0},
			3: {"base_attack": 2, "fort": 1, "ref": 3, "will": 1},
			4: {"base_attack": 3, "fort": 1, "ref": 4, "will": 1},
		},
	},
	"sorcerer": {
		"name": "Sorcerer",
		"hit_die": 4,
		"skill_points": 2,
		"base_attack": "poor",
		"good_saves": ["will"],
		"feat_levels": {"general": [1, 3], "class": []},
		"source": "PHB Table 3-16, p. 52; Table 3-17, p. 54",
		"rows": {
			1: {"base_attack": 0, "fort": 0, "ref": 0, "will": 2, "spells": {0: 5, 1: 3}, "known": {0: 4, 1: 2}},
			2: {"base_attack": 1, "fort": 0, "ref": 0, "will": 3, "spells": {0: 6, 1: 4}, "known": {0: 5, 1: 2}},
			3: {"base_attack": 1, "fort": 1, "ref": 1, "will": 3, "spells": {0: 6, 1: 5}, "known": {0: 5, 1: 3}},
			4: {"base_attack": 2, "fort": 1, "ref": 1, "will": 4, "spells": {0: 6, 1: 6, 2: 3}, "known": {0: 6, 1: 3, 2: 1}},
		},
	},
	"wizard": {
		"name": "Wizard",
		"hit_die": 4,
		"skill_points": 2,
		"base_attack": "poor",
		"good_saves": ["will"],
		"feat_levels": {"general": [1, 3], "class": []},
		"source": "PHB Table 3-18, p. 55",
		"rows": {
			1: {"base_attack": 0, "fort": 0, "ref": 0, "will": 2, "spells": {0: 3, 1: 1}},
			2: {"base_attack": 1, "fort": 0, "ref": 0, "will": 3, "spells": {0: 4, 1: 2}},
			3: {"base_attack": 1, "fort": 1, "ref": 1, "will": 3, "spells": {0: 4, 1: 2, 2: 1}},
			4: {"base_attack": 2, "fort": 1, "ref": 1, "will": 4, "spells": {0: 4, 1: 3, 2: 2}},
		},
	},
}

const SAVES := ["fort", "ref", "will"]


static func class_data(class_key: String) -> Dictionary:
	return CLASSES.get(class_key.to_lower(), {})


static func row(class_key: String, level: int) -> Dictionary:
	var data := class_data(class_key)
	var rows := Dictionary(data.get("rows", {}))
	return Dictionary(rows.get(level, {}))


## Base attack progression for levels 1-4 (Table 3-1): good = level, average =
## three quarters of level, poor = half of level, rounded down.
static func expected_base_attack(rate: String, level: int) -> int:
	match rate:
		"good":
			return level
		"average":
			return (level * 3) / 4
		"poor":
			return level / 2
	return -1


## Base save bonus (Table 3-1): good = 2 + half of level, poor = a third of level,
## both rounded down.
static func expected_save(good: bool, level: int) -> int:
	return 2 + level / 2 if good else level / 3


## Hit points at a level: maximum die at 1st level, fixed average (half the die
## plus one) after it, each plus the Constitution modifier. Fixed averages match
## the authored pregens and keep progression deterministic.
static func expected_hp(class_key: String, level: int, con_modifier: int) -> int:
	var die := int(class_data(class_key).get("hit_die", 0))
	if die <= 0 or level < 1:
		return 0
	var total := die + con_modifier
	for _level in range(2, level + 1):
		total += die / 2 + 1 + con_modifier
	return maxi(level, total)


## Feat slots earned by a level: the general feats from Table 3-2 plus the
## class's own bonus feats.
static func feat_slots(class_key: String, level: int) -> int:
	var data := class_data(class_key)
	var levels := Dictionary(data.get("feat_levels", {}))
	var total := 0
	for feat_level in Array(levels.get("general", [])):
		if int(feat_level) <= level:
			total += 1
	for feat_level in Array(levels.get("class", [])):
		if int(feat_level) <= level:
			total += 1
	return total


static func spell_slots(class_key: String, level: int) -> Dictionary:
	return Dictionary(row(class_key, level).get("spells", {})).duplicate()


static func spells_known(class_key: String, level: int) -> Dictionary:
	return Dictionary(row(class_key, level).get("known", {})).duplicate()


## Errors for a table that is missing a row, moves backwards, or disagrees with
## the printed progressions. An empty result means the table is usable.
static func validate(table: Dictionary = {}) -> Array[String]:
	var source: Dictionary = table if not table.is_empty() else CLASSES
	var errors: Array[String] = []
	for key in CLASSES:
		if not source.has(key):
			errors.append("%s: class is missing" % key)
	for key in source.keys():
		var class_key := String(key)
		errors.append_array(_validate_class(class_key, Dictionary(source[key])))
	return errors


static func _validate_class(class_key: String, data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var die := int(data.get("hit_die", 0))
	if not die in HIT_DICE:
		errors.append("%s: hit die %d is not a standard die" % [class_key, die])
	if int(data.get("skill_points", 0)) < 1:
		errors.append("%s: skill points must be at least 1" % class_key)
	var rate := String(data.get("base_attack", ""))
	if rate not in ["good", "average", "poor"]:
		errors.append("%s: unknown base attack rate '%s'" % [class_key, rate])
	var good_saves := Array(data.get("good_saves", []))
	for save in good_saves:
		if String(save) not in SAVES:
			errors.append("%s: unknown save '%s'" % [class_key, save])
	var feat_levels := Dictionary(data.get("feat_levels", {}))
	var general := Array(feat_levels.get("general", []))
	if general != GENERAL_FEAT_LEVELS:
		errors.append("%s: general feat levels must be %s" % [class_key, str(GENERAL_FEAT_LEVELS)])
	var class_feats := Array(feat_levels.get("class", []))
	var previous_feat := 0
	for feat_level in class_feats:
		if int(feat_level) <= previous_feat or int(feat_level) < 1 or int(feat_level) > LEVELS[-1]:
			errors.append("%s: class feat levels are not ascending within 1-4" % class_key)
		previous_feat = int(feat_level)
	var rows := Dictionary(data.get("rows", {}))
	var is_caster := false
	for level in LEVELS:
		if not rows.has(level):
			errors.append("%s: level %d row is missing" % [class_key, level])
			continue
		var row_data := Dictionary(rows[level])
		for field in ["base_attack"] + SAVES:
			if not row_data.has(field):
				errors.append("%s level %d: '%s' is missing" % [class_key, level, field])
		if not row_data.has("base_attack"):
			continue
		var bab := int(row_data["base_attack"])
		var want_bab := expected_base_attack(rate, level)
		if bab != want_bab:
			errors.append(
				"%s level %d: base_attack %d is inconsistent with the %s progression (%d)"
				% [class_key, level, bab, rate, want_bab]
			)
		for save in SAVES:
			if not row_data.has(save):
				continue
			var value := int(row_data[save])
			var want_save := expected_save(save in good_saves, level)
			if value != want_save:
				errors.append(
					"%s level %d: %s save %d is inconsistent with the class progression (%d)"
					% [class_key, level, save, value, want_save]
				)
		var slots := Dictionary(row_data.get("spells", {}))
		if not slots.is_empty():
			is_caster = true
			var max_spell: int = (int(level) + 1) / 2
			for spell_level in slots.keys():
				if int(spell_level) > max_spell:
					errors.append(
						"%s level %d: spell level %d is above what the level can cast"
						% [class_key, level, int(spell_level)]
					)
				if int(slots[spell_level]) < 0:
					errors.append("%s level %d: negative spell slots" % [class_key, level])
		if row_data.has("known"):
			if class_key != "sorcerer":
				errors.append("%s level %d: only the sorcerer records spells known" % [class_key, level])
			var known := Dictionary(row_data["known"])
			for spell_level in known.keys():
				if int(known[spell_level]) < 0:
					errors.append("%s level %d: negative spells known" % [class_key, level])
		if level > 1 and rows.has(level - 1):
			var previous := Dictionary(rows[level - 1])
			for field in ["base_attack"] + SAVES:
				if row_data.has(field) and previous.has(field):
					if int(row_data[field]) < int(previous[field]):
						errors.append(
							"%s: %s decreases from level %d to %d" % [class_key, field, level - 1, level]
						)
			var previous_slots := Dictionary(previous.get("spells", {}))
			for spell_level in slots.keys():
				if previous_slots.has(spell_level) and int(slots[spell_level]) < int(previous_slots[spell_level]):
					errors.append(
						"%s: spell level %d slots decrease from level %d to %d"
						% [class_key, int(spell_level), level - 1, level]
					)
			var previous_known := Dictionary(previous.get("known", {}))
			for spell_level in Dictionary(row_data.get("known", {})).keys():
				if (
					previous_known.has(spell_level)
					and int(Dictionary(row_data["known"])[spell_level]) < int(previous_known[spell_level])
				):
					errors.append(
						"%s: spells known at level %d decrease from level %d to %d"
						% [class_key, int(spell_level), level - 1, level]
					)
	if is_caster:
		for level in LEVELS:
			if not rows.has(level):
				continue
			if not Dictionary(rows[level]).has("spells"):
				errors.append("%s level %d: a caster must have a spell row" % [class_key, level])
	return errors


## Differences between the tables and the authored characters. These are content
## facts that are accepted as they are; nothing here edits a character or a save.
static func authored_inconsistencies(characters: Dictionary) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var ids: Array = characters.keys()
	ids.sort()
	for raw_id in ids:
		var id := String(raw_id)
		var ch := Dictionary(characters[raw_id])
		var class_key := String(ch.get("class", "")).to_lower()
		if not CLASSES.has(class_key):
			continue
		var level := int(ch.get("level", 1))
		if not row(class_key, level):
			continue
		var row_data := row(class_key, level)
		var abilities := Dictionary(ch.get("abilities", {}))
		var con_modifier := Rules.ability_mod(int(abilities.get("con", 10)))
		var bab := int(ch.get("base_attack", 0))
		if bab != int(row_data.get("base_attack", -1)):
			found.append(_finding(id, "base_attack", int(row_data["base_attack"]), bab,
				"authored base attack differs from %s" % String(CLASSES[class_key]["source"])))
		var saves := Dictionary(ch.get("base_saves", {}))
		for save in SAVES:
			var authored_save := int(saves.get(save, 0))
			if authored_save != int(row_data.get(save, -1)):
				found.append(_finding(id, "base_saves.%s" % save, int(row_data[save]), authored_save,
					"authored %s save differs from the class row" % save))
		var hp := int(ch.get("max_hp", 0))
		var want_hp := expected_hp(class_key, level, con_modifier)
		if hp != want_hp:
			found.append(_finding(id, "max_hp", want_hp, hp,
				"authored HP differs from max-at-1st plus fixed averages"))
		var feats := Array(ch.get("feats", []))
		var slots := feat_slots(class_key, level)
		if feats.size() != slots:
			found.append(_finding(id, "feats", slots, feats.size(),
				"authored feat list does not use every printed slot; no retroactive audit is applied"))
		found.append_array(_skill_findings(id, ch, class_key, level, abilities))
		found.append_array(_spell_findings(id, ch, class_key, level))
	return found


static func _skill_findings(
	id: String, ch: Dictionary, class_key: String, level: int, abilities: Dictionary
) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var ranks := Dictionary(ch.get("skill_ranks", {}))
	var class_skills := Array(Skills.CLASS_SKILLS.get(class_key, []))
	var spent := 0
	var names: Array = ranks.keys()
	names.sort()
	for raw_skill in names:
		var skill := String(raw_skill)
		var value := int(ranks[raw_skill])
		var is_class := class_skills.has(skill)
		var cap := level + 3 if is_class else (level + 3) / 2
		if value > cap:
			found.append(_finding(id, "skill_ranks.%s" % skill, cap, value,
				"rank cap at level %d is %d for %s" % [level, cap, "a class skill" if is_class else "a cross-class skill"]))
		spent += value if is_class else value * 2
	var per_level := int(CLASSES[class_key].get("skill_points", 0)) + Rules.ability_mod(int(abilities.get("int", 10)))
	var earned := per_level * (level + 3)
	if spent > earned:
		found.append(_finding(id, "skill_points", earned, spent,
			"authored ranks cost more points than the class earns by level %d" % level))
	return found


static func _spell_findings(id: String, ch: Dictionary, class_key: String, level: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var spells := Dictionary(ch.get("spells", {}))
	if spells.is_empty():
		return found
	var slots := Dictionary(spells.get("slots", {}))
	var printed := spell_slots(class_key, level)
	var slot_levels: Array = slots.keys()
	slot_levels.sort()
	for raw_level in slot_levels:
		var spell_level := int(raw_level)
		var actual := int(Dictionary(slots[raw_level]).get("max", 0))
		var expected := int(printed.get(spell_level, 0))
		if actual != expected:
			found.append(_finding(id, "spells.slots.%d" % spell_level, expected, actual,
				"authored slots include ability or domain bonuses the class table does not model"))
	if bool(spells.get("spontaneous", false)):
		var known := Array(spells.get("known", []))
		var printed_known := spells_known(class_key, level)
		var total := 0
		for spell_level in printed_known.keys():
			total += int(printed_known[spell_level])
		if known.size() != total:
			found.append(_finding(id, "spells.known", total, known.size(),
				"authored known list does not match the printed spells known, including 0-level spells"))
	return found


static func _finding(id: String, field: String, expected: int, actual: int, note: String) -> Dictionary:
	return {
		"id": id,
		"field": field,
		"expected": expected,
		"actual": actual,
		"note": note,
	}
