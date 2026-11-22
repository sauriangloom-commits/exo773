class_name LevelChoices
extends RefCounted

## Choice data for the single 3rd-to-4th level step (docs/LEVEL_UP_PLAN.md 13).
##
## Pure data: nothing here mutates a character, writes a save or applies a step.
## `LevelUp.apply` remains the only authority, and every refusal code below is the
## one `LevelUp.stage(..., true)` already produces. Every rule is read from the
## module that owns it: caps and costs from `Skills`, slots from
## `ClassProgression`, prerequisites and the printed fighter markers from `Feats`,
## staging and the required-choice list from `LevelUp`.

const NEW_SPELL_LEVEL := LevelUp.NEW_SPELL_LEVEL


## Everything the level-up screen needs for one draft. `draft` is a partial choice
## (`{"ability": "dex"}`), so the options follow the pending ability increase and
## the ranks already allocated in the draft.
static func choices(ch: Character, draft: Dictionary = {}) -> Dictionary:
	var state := LevelUp.eligibility(ch)
	if not bool(state.get("eligible", false)):
		return _blocked(ch, String(state.get("code", "")), String(state.get("message", "")))
	var ability := String(draft.get("ability", "")).strip_edges()
	var staged_result := LevelUp.stage(ch, {"ability": ability}, false)
	if not bool(staged_result.get("ok", false)):
		return _blocked(
			ch, String(staged_result.get("code", "")), String(staged_result.get("message", ""))
		)
	var staged: Character = staged_result["staged"]
	var chosen_skills := _skill_choices(draft.get("skills", {}))
	for raw_skill in chosen_skills.keys():
		var skill := String(raw_skill)
		staged.skill_ranks[skill] = int(staged.skill_ranks.get(skill, 0)) + int(chosen_skills[skill])
	var class_key := String(ch.char_class).to_lower()
	var budget := _budget(staged, class_key)
	var spent := _spent(staged, chosen_skills)
	var remaining := maxi(0, budget - spent)
	var class_cap := LevelUp.TARGET_LEVEL + 3
	var cross_cap := floori(float(class_cap) / 2.0)
	var feat_granted := (
		ClassProgression.feat_slots(class_key, LevelUp.TARGET_LEVEL)
		- ClassProgression.feat_slots(class_key, 3)
	)
	var needs_spell := class_key == "sorcerer"
	var spell_rows := _spell_rows(ch, staged)
	var blockers := LevelUp.required_choices(ch, draft)
	if needs_spell and spell_rows.is_empty() and not blockers.has("spell"):
		blockers.append("spell")
	var ability_scores := {}
	for key in LevelUp.ABILITIES:
		var before := int(ch.abilities.get(key, 10))
		var after := int(staged.abilities.get(key, 10))
		ability_scores[String(key)] = {
			"before": before,
			"after": after,
			"modifier_before": Rules.ability_mod(before),
			"modifier_after": Rules.ability_mod(after),
		}
	return {
		"ok": true,
		"code": "eligible",
		"message": "",
		"from_level": int(ch.level),
		"to_level": LevelUp.TARGET_LEVEL,
		"ability": {
			"required": true,
			"chosen": ability,
			"options": Array(LevelUp.ABILITIES).duplicate(),
			"scores": ability_scores,
		},
		"skills": {
			"budget": budget,
			"spent": spent,
			"remaining": remaining,
			"class_cap": class_cap,
			"cross_cap": cross_cap,
			"chosen": chosen_skills.duplicate(),
			"options": _skill_rows(staged, remaining),
		},
		"feat": {
			"granted": feat_granted,
			"required": feat_granted > 0,
			"chosen": String(draft.get("feat", "")),
			"options": _feat_rows(staged, feat_granted),
		},
		"spell": {
			"new_level": NEW_SPELL_LEVEL,
			"required": needs_spell,
			"chosen": String(draft.get("spell", "")),
			"options": spell_rows,
		},
		"complete": blockers.is_empty(),
		"blockers": blockers,
	}


## The fighter's legal choices: the implemented catalog, filtered by the printed
## fighter markers and by the character's own list, each checked on the staged
## level-4 copy. Empty for every class without a feat at 4th level.
static func feat_options(ch: Character, draft: Dictionary = {}) -> Array[Dictionary]:
	var class_key := String(ch.char_class).to_lower()
	var granted := (
		ClassProgression.feat_slots(class_key, LevelUp.TARGET_LEVEL)
		- ClassProgression.feat_slots(class_key, 3)
	)
	if granted < 1:
		return [] as Array[Dictionary]
	var staged_result := LevelUp.stage(ch, {"ability": String(draft.get("ability", ""))}, false)
	if not bool(staged_result.get("ok", false)):
		return [] as Array[Dictionary]
	return _feat_rows(staged_result["staged"], granted)


## Every skill the character could spend a point on, with the cost, cap and the
## ranks the remaining points buy.
static func skill_options(ch: Character, draft: Dictionary = {}) -> Array[Dictionary]:
	var staged_result := LevelUp.stage(ch, {"ability": String(draft.get("ability", ""))}, false)
	if not bool(staged_result.get("ok", false)):
		return [] as Array[Dictionary]
	var staged: Character = staged_result["staged"]
	var chosen_skills := _skill_choices(draft.get("skills", {}))
	for raw_skill in chosen_skills.keys():
		var skill := String(raw_skill)
		staged.skill_ranks[skill] = int(staged.skill_ranks.get(skill, 0)) + int(chosen_skills[skill])
	var remaining := maxi(0, _budget(staged, String(ch.char_class).to_lower()) - _spent(staged, chosen_skills))
	return _skill_rows(staged, remaining)


## The sorcerer's new known spell: implemented spells of the new spell level that
## are open to the class, minus the ones already known. Empty for every other class.
static func spell_options(ch: Character, draft: Dictionary = {}) -> Array[Dictionary]:
	if String(ch.char_class).to_lower() != "sorcerer":
		return [] as Array[Dictionary]
	var staged_result := LevelUp.stage(ch, {"ability": String(draft.get("ability", ""))}, false)
	if not bool(staged_result.get("ok", false)):
		return [] as Array[Dictionary]
	return _spell_rows(ch, staged_result["staged"])


## Advisory refusal check: the same refusal code `LevelUp.apply` would return,
## with the choice group the screen should mark. Never mutates the character.
static func validate(ch: Character, choices: Dictionary) -> Dictionary:
	var staged := LevelUp.stage(ch, choices, true)
	if bool(staged.get("ok", false)):
		return {"ok": true, "code": "eligible", "message": "", "fields": {}}
	var code := String(staged.get("code", ""))
	var message := String(staged.get("message", ""))
	var field := _field_for(code)
	var fields := {}
	if field != "":
		fields[field] = message
	return {"ok": false, "code": code, "message": message, "fields": fields}


static func _feat_rows(staged: Character, granted: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if granted < 1:
		return rows
	var keys: Array = Feats.CATALOG.keys()
	keys.sort()
	for raw_key in keys:
		var key := String(raw_key)
		var data := Dictionary(Feats.CATALOG[key])
		if not bool(data.get("fighter_bonus", false)):
			continue
		var parameters := _parameters(data)
		if parameters.is_empty():
			var single := _feat_row(staged, key, "")
			if not single.is_empty():
				rows.append(single)
			continue
		for parameter in parameters:
			var row := _feat_row(staged, key, parameter)
			if not row.is_empty():
				rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var left := String(a["name"])
		var right := String(b["name"])
		if left != right:
			return left < right
		return String(a["param"]) < String(b["param"])
	)
	return rows


static func _feat_row(staged: Character, key: String, parameter: String) -> Dictionary:
	if _owns(staged, key, parameter):
		return {}
	var data := Dictionary(Feats.CATALOG[key])
	var name := String(data.get("name", key))
	var text := name if parameter == "" else "%s (%s)" % [name, parameter]
	var check := Feats.prereqs(staged, key, parameter)
	return {
		"text": text,
		"key": key,
		"param": parameter,
		"name": name,
		"group": "fighter_bonus",
		"eligible": bool(check.get("ok", false)),
		"reasons": Array(check.get("reasons", [])).duplicate(),
		"owned": false,
	}


## Legible choices for a parameterized feat, taken from the content that ships.
static func _parameters(data: Dictionary) -> Array[String]:
	var parameters: Array[String] = []
	match String(data.get("parameter", "")):
		"weapon":
			return _weapon_ids()
		"skill":
			for raw_skill in Skills.all_keys():
				parameters.append(String(raw_skill))
	return parameters


static func _weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	if Game.content == null:
		return ids
	for raw_id in Game.content.items.keys():
		var item := Dictionary(Game.content.items[raw_id])
		if String(item.get("kind", "")) == "weapon":
			ids.append(String(raw_id))
	ids.sort()
	return ids


static func _skill_rows(staged: Character, remaining: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw_skill in Skills.all_keys():
		var skill := String(raw_skill)
		var is_class := Skills.is_class_skill(staged, skill)
		var cost := 1 if is_class else 2
		var ranks := int(staged.skill_ranks.get(skill, 0))
		var cap := Skills.max_ranks(staged, skill)
		var max_new := mini(maxi(0, cap - ranks), remaining / cost)
		rows.append({
			"skill": skill,
			"name": Skills.name(skill),
			"ability": Skills.ability(skill),
			"class_skill": is_class,
			"cost_per_rank": cost,
			"ranks": ranks,
			"cap": cap,
			"max_new_ranks": max_new,
			"trained_only": Skills.is_trained_only(skill),
			"affordable": max_new > 0,
		})
	return rows


static func _spell_rows(ch: Character, staged: Character) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if String(ch.char_class).to_lower() != "sorcerer" or Game.content == null:
		return rows
	var known := Array(staged.spells.get("known", []))
	var ids: Array = Game.content.spells.keys()
	ids.sort()
	for raw_id in ids:
		var spell_id := String(raw_id)
		var data := Dictionary(Game.content.spells[spell_id])
		if int(data.get("level", 0)) != NEW_SPELL_LEVEL:
			continue
		if not _open_to_class(data, "sorcerer"):
			continue
		if known.has(spell_id):
			continue
		rows.append({
			"id": spell_id,
			"name": String(data.get("name", spell_id)),
			"level": int(data.get("level", 0)),
			"school": String(data.get("school", "")),
			"eligible": true,
			"reason": "",
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var left := String(a["name"])
		var right := String(b["name"])
		if left != right:
			return left < right
		return String(a["id"]) < String(b["id"])
	)
	return rows


static func _open_to_class(data: Dictionary, class_key: String) -> bool:
	for raw_class in Array(data.get("classes", [])):
		if String(raw_class).to_lower() == class_key:
			return true
	return false


static func _budget(staged: Character, class_key: String) -> int:
	var points := int(Dictionary(ClassProgression.class_data(class_key)).get("skill_points", 0))
	return maxi(1, points + Rules.ability_mod(int(staged.abilities.get("int", 10))))


static func _spent(staged: Character, chosen: Dictionary) -> int:
	var spent := 0
	for raw_skill in chosen.keys():
		var skill := String(raw_skill)
		var ranks := int(chosen[raw_skill])
		spent += ranks if Skills.is_class_skill(staged, skill) else ranks * 2
	return spent


static func _skill_choices(raw: Variant) -> Dictionary:
	var chosen := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return chosen
	for raw_skill in Dictionary(raw).keys():
		var skill := String(raw_skill)
		var ranks := int(Dictionary(raw)[raw_skill])
		if ranks > 0:
			chosen[skill] = ranks
	return chosen


static func _owns(ch: Character, key: String, parameter: String) -> bool:
	for raw in ch.feats:
		var parsed := Feats.parse(String(raw))
		if String(parsed.get("key", "")) != key:
			continue
		if String(parsed.get("param", "")).to_lower() == parameter.to_lower():
			return true
	return false


static func _field_for(code: String) -> String:
	if code.begins_with("feat"):
		return "feat"
	if code.begins_with("spell"):
		return "spell"
	if code.begins_with("skill") or code == "negative_rank" or code == "unknown_skill":
		return "skills"
	if code.contains("ability"):
		return "ability"
	return ""


static func _blocked(ch: Character, code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"code": code,
		"message": message,
		"from_level": 0 if ch == null else int(ch.level),
		"to_level": LevelUp.TARGET_LEVEL,
		"ability": {
			"required": true,
			"chosen": "",
			"options": Array(LevelUp.ABILITIES).duplicate(),
			"scores": {},
		},
		"skills": {
			"budget": 0,
			"spent": 0,
			"remaining": 0,
			"class_cap": LevelUp.TARGET_LEVEL + 3,
			"cross_cap": floori(float(LevelUp.TARGET_LEVEL + 3) / 2.0),
			"chosen": {},
			"options": [],
		},
		"feat": {"granted": 0, "required": false, "chosen": "", "options": []},
		"spell": {"new_level": NEW_SPELL_LEVEL, "required": false, "chosen": "", "options": []},
		"complete": false,
		"blockers": [],
	}
