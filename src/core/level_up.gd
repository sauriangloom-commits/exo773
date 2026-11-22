class_name LevelUp
extends RefCounted

## One level step, 3rd to 4th (docs/LEVEL_UP_PLAN.md section 12).
##
## Pure data and rules: no scene, no save write, no XP award. `preview` is
## read-only; `apply` validates every choice on a staged level-4 copy and only then
## writes the staged values to the character in one block. A refusal leaves the
## character's serialization unchanged.
##
## Skill caps at 4th level follow the printed text (SRD Skills Summary; PHB p. 62):
## class 7, cross-class half of that "do not round up or down" = 3.5. The engine
## stores whole ranks and buys a cross-class rank for two points, so the enforceable
## cap is 3 whole cross-class ranks; `Skills.max_ranks` floors for that reason and
## is reused on the staged character.

const XP_THRESHOLD := 6000
const TARGET_LEVEL := 4
const NEW_SPELL_LEVEL := 2
const ABILITIES := ["str", "dex", "con", "int", "wis", "cha"]
const SPELL_SLOT_DELTAS := {
	"cleric": {1: 1, 2: 1},
	"wizard": {1: 1, 2: 1},
	"sorcerer": {2: 3},
}
const SAVES := ["fort", "ref", "will"]


## Whether the single supported step is open. Order is fixed so the message is
## deterministic: character, class, level, XP. The threshold is inclusive.
static func eligibility(ch: Character) -> Dictionary:
	if ch == null:
		return _eligibility(false, "no_character", "There is no character to advance.")
	var class_key := String(ch.char_class).to_lower()
	if not ClassProgression.CLASSES.has(class_key):
		return _eligibility(
			false,
			"class_not_tabled",
			"%s has no class progression table." % String(ch.char_class),
			ch
		)
	if int(ch.level) < 3:
		return _eligibility(false, "not_level_3", "Only the 3rd-to-4th level step is supported.", ch)
	if int(ch.level) >= TARGET_LEVEL:
		return _eligibility(false, "already_level_4", "The character is already 4th level.", ch)
	if int(ch.xp) < XP_THRESHOLD:
		return _eligibility(
			false,
			"xp_below_threshold",
			"Requires %d XP; the character has %d." % [XP_THRESHOLD, int(ch.xp)],
			ch
		)
	return _eligibility(true, "eligible", "", ch)


## What the step would change. Never mutates the character. Choices may be omitted
## so a caller can show the numbers first; `required` then names the missing ones.
static func preview(ch: Character, choices: Dictionary = {}) -> Dictionary:
	var built := _build(ch, choices, false)
	built.erase("_staged")
	return built


## Applies the step atomically. Returns the preview plus `applied` on success.
static func apply(ch: Character, choices: Dictionary) -> Dictionary:
	var built := _build(ch, choices, true)
	if not bool(built.get("ok", false)):
		built.erase("_staged")
		return built
	var staged: Character = built["_staged"]
	_commit(ch, staged)
	built.erase("_staged")
	built["applied"] = true
	return built


static func _build(ch: Character, choices: Dictionary, complete: bool) -> Dictionary:
	var state := eligibility(ch)
	if not bool(state.get("eligible", false)):
		if ch == null:
			return _blocked(null, String(state["code"]), String(state["message"]))
		return _blocked(ch, String(state["code"]), String(state["message"]))
	var staged_result := stage(ch, choices, complete)
	if not bool(staged_result.get("ok", false)):
		return _blocked(
			ch, String(staged_result["code"]), String(staged_result["message"])
		)
	var staged: Character = staged_result["staged"]
	var described := _describe(ch, staged, staged_result)
	described["ok"] = true
	described["code"] = "eligible"
	described["message"] = ""
	described["_staged"] = staged
	return described


## Builds the level-4 copy and validates every choice against it. Returns the copy
## only when all checks pass; the original character is untouched. Public so the
## choice data (batch 3) evaluates options on exactly the character `apply` will
## validate; `complete` asks for the same refusals `apply` makes.
static func stage(ch: Character, choices: Dictionary, complete := false) -> Dictionary:
	var class_key := String(ch.char_class).to_lower()
	var class_data := Dictionary(ClassProgression.CLASSES[class_key])
	var row := ClassProgression.row(class_key, TARGET_LEVEL)
	if row.is_empty():
		return _failure("class_not_tabled", "%s has no level %d row." % [class_key, TARGET_LEVEL])
	var staged := Character.from_dict(ch.to_dict(), {})
	staged.level = TARGET_LEVEL
	staged.base_attack = int(row["base_attack"])
	staged.base_saves = {
		"fort": int(row["fort"]), "ref": int(row["ref"]), "will": int(row["will"])
	}
	var ability_key := String(choices.get("ability", "")).strip_edges()
	if ability_key != "":
		if not ABILITIES.has(ability_key):
			return _failure("unknown_ability", "'%s' is not an ability score." % ability_key)
		staged.abilities[ability_key] = int(staged.abilities.get(ability_key, 10)) + 1
	elif complete:
		return _failure("missing_ability_increase", "Choose one ability score to increase.")
	var con_modifier := Rules.ability_mod(int(staged.abilities.get("con", 10)))
	staged.max_hp = ClassProgression.expected_hp(class_key, TARGET_LEVEL, con_modifier)
	var hp_delta := staged.max_hp - int(ch.max_hp)
	staged.hp = clampi(int(ch.hp) + hp_delta, 0, staged.max_hp)
	var budget := maxi(
		1,
		int(class_data.get("skill_points", 0))
		+ Rules.ability_mod(int(staged.abilities.get("int", 10)))
	)
	var skills_result := _stage_skills(staged, choices.get("skills", {}), budget)
	if not bool(skills_result["ok"]):
		return skills_result
	var spent := int(skills_result["spent"])
	var added: Dictionary = skills_result["added"]
	var feat_result := _stage_feat(
		staged, ch, class_key, String(choices.get("feat", "")), complete
	)
	if not bool(feat_result["ok"]):
		return feat_result
	var spell_result := _stage_spell(staged, class_key, String(choices.get("spell", "")), complete)
	if not bool(spell_result["ok"]):
		return spell_result
	_apply_slot_deltas(staged, class_key)
	return {
		"ok": true,
		"code": "",
		"message": "",
		"staged": staged,
		"ability": ability_key,
		"spent": spent,
		"added": added,
		"budget": budget,
		"feat": String(feat_result["feat"]),
		"spell": String(spell_result["spell"]),
	}


static func _stage_skills(staged: Character, raw: Variant, budget: int) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return _failure("unknown_skill", "Skill choices must be a mapping of skill to ranks.")
	var spent := 0
	var added: Dictionary = {}
	var keys: Array = Dictionary(raw).keys()
	keys.sort()
	for raw_skill in keys:
		var skill := String(raw_skill)
		if not Skills.CATALOG.has(skill):
			return _failure("unknown_skill", "'%s' is not an implemented skill." % skill)
		var rank := _rank_value(Dictionary(raw)[raw_skill])
		if rank < 0:
			return _failure("negative_rank", "%s needs a whole, non-negative number of ranks." % skill)
		if rank == 0:
			continue
		var cost := rank if Skills.is_class_skill(staged, skill) else rank * 2
		spent += cost
		var total := int(staged.skill_ranks.get(skill, 0)) + rank
		var cap := Skills.max_ranks(staged, skill)
		if total > cap:
			return _failure(
				"skill_rank_above_cap",
				"%s would reach %d ranks; the cap at level %d is %d (%s)."
				% [
					skill,
					total,
					TARGET_LEVEL,
					cap,
					"class skill" if Skills.is_class_skill(staged, skill) else "cross-class skill",
				]
			)
		added[skill] = rank
	if spent > budget:
		return _failure(
			"skill_points_over_budget",
			"The allocation costs %d skill points; %d are available." % [spent, budget]
		)
	for skill in added.keys():
		staged.skill_ranks[skill] = int(staged.skill_ranks.get(skill, 0)) + int(added[skill])
	return {"ok": true, "code": "", "message": "", "spent": spent, "added": added}


static func _stage_feat(
	staged: Character, original: Character, class_key: String, feat_text: String, complete: bool
) -> Dictionary:
	var gained := (
		ClassProgression.feat_slots(class_key, TARGET_LEVEL)
		- ClassProgression.feat_slots(class_key, 3)
	)
	var text := feat_text.strip_edges()
	if text == "":
		if gained > 0 and complete:
			return _failure("feat_required", "The fighter gains a feat at 4th level; choose one.")
		return {"ok": true, "code": "", "message": "", "feat": ""}
	if gained < 1:
		return _failure("feat_slot_unavailable", "This class gains no feat at 4th level.")
	var parsed := Feats.parse(text)
	var key := String(parsed.get("key", ""))
	var parameter := String(parsed.get("param", ""))
	if not Feats.CATALOG.has(key):
		return _failure("feat_not_implemented", "'%s' is not an implemented feat." % key)
	if _owns_feat(original, key, parameter):
		return _failure("feat_already_owned", "The character already has %s." % text)
	var check := Feats.prereqs(staged, key, parameter)
	if not bool(check.get("ok", false)):
		return _failure(
			"feat_prerequisites_unmet",
			"%s: %s" % [text, "; ".join(PackedStringArray(check.get("reasons", [])))]
		)
	staged.feats.append(text)
	return {"ok": true, "code": "", "message": "", "feat": text}


static func _stage_spell(
	staged: Character, class_key: String, spell_id: String, complete: bool
) -> Dictionary:
	var spell := spell_id.strip_edges()
	var is_sorcerer := class_key == "sorcerer"
	if spell == "":
		if is_sorcerer and complete:
			return _failure(
				"spell_required", "The sorcerer learns a 2nd-level spell at 4th level; choose one."
			)
		return {"ok": true, "code": "", "message": "", "spell": ""}
	if not is_sorcerer:
		return _failure("spell_choice_unavailable", "Only the sorcerer chooses a known spell.")
	var db: Dictionary = {}
	if Game.content != null:
		db = Game.content.spells
	if not db.has(spell):
		return _failure("spell_not_implemented", "'%s' is not an implemented spell." % spell)
	var data := Dictionary(db[spell])
	if int(data.get("level", 0)) != NEW_SPELL_LEVEL:
		return _failure(
			"spell_level_not_new",
			"%s is not a %dnd-level spell." % [String(data.get("name", spell)), NEW_SPELL_LEVEL]
		)
	_ensure_spell_state(staged, is_sorcerer)
	var known := Array(staged.spells.get("known", []))
	if known.has(spell):
		return _failure("spell_already_known", "The character already knows %s." % spell)
	known.append(spell)
	staged.spells["known"] = known
	return {"ok": true, "code": "", "message": "", "spell": spell}


static func _apply_slot_deltas(staged: Character, class_key: String) -> void:
	var deltas: Dictionary = SPELL_SLOT_DELTAS.get(class_key, {})
	if deltas.is_empty():
		return
	_ensure_spell_state(staged, class_key == "sorcerer")
	var slots := Dictionary(staged.spells.get("slots", {}))
	for raw_level in deltas.keys():
		var key := str(raw_level)
		var entry: Dictionary
		if slots.has(key):
			entry = Dictionary(slots[key]).duplicate(true)
		else:
			entry = {"max": 0, "used": 0}
		entry["max"] = int(entry.get("max", 0)) + int(deltas[raw_level])
		slots[key] = entry
	staged.spells["slots"] = slots


static func _ensure_spell_state(staged: Character, spontaneous: bool) -> void:
	if staged.spells.is_empty():
		staged.spells = {"slots": {}, "known": [], "spontaneous": spontaneous}
		return
	if not staged.spells.has("slots"):
		staged.spells["slots"] = {}
	if not staged.spells.has("known"):
		staged.spells["known"] = []


static func _describe(ch: Character, staged: Character, staged_result: Dictionary) -> Dictionary:
	var class_key := String(ch.char_class).to_lower()
	var ability_key := String(staged_result.get("ability", ""))
	var ability_before := 0
	var ability_after := 0
	var modifier_before := 0
	var modifier_after := 0
	if ability_key != "":
		ability_before = int(ch.abilities.get(ability_key, 10))
		ability_after = int(staged.abilities.get(ability_key, 10))
		modifier_before = Rules.ability_mod(ability_before)
		modifier_after = Rules.ability_mod(ability_after)
	var saves := {}
	for save in SAVES:
		saves[save] = {
			"before": int(Dictionary(ch.base_saves).get(save, 0)),
			"after": int(Dictionary(staged.base_saves).get(save, 0)),
		}
	var before_slots := Dictionary(ch.spells.get("slots", {})).duplicate(true)
	var after_slots := Dictionary(staged.spells.get("slots", {})).duplicate(true)
	var before_known := Array(ch.spells.get("known", [])).duplicate()
	var after_known := Array(staged.spells.get("known", [])).duplicate()
	var spent := int(staged_result.get("spent", 0))
	var budget := int(staged_result.get("budget", 0))
	return {
		"ok": true,
		"code": "eligible",
		"message": "",
		"eligible": true,
		"from_level": int(ch.level),
		"to_level": TARGET_LEVEL,
		"xp": int(ch.xp),
		"threshold": XP_THRESHOLD,
		"hit_points": {
			"max_before": int(ch.max_hp),
			"max_after": int(staged.max_hp),
			"hp_before": int(ch.hp),
			"hp_after": int(staged.hp),
			"delta": int(staged.max_hp) - int(ch.max_hp),
		},
		"base_attack": {"before": int(ch.base_attack), "after": int(staged.base_attack)},
		"base_saves": saves,
		"ability": {
			"key": ability_key,
			"before": ability_before,
			"after": ability_after,
			"modifier_before": modifier_before,
			"modifier_after": modifier_after,
		},
		"skills": {
			"budget": budget,
			"spent": spent,
			"remaining": budget - spent,
			"class_cap": TARGET_LEVEL + 3,
			"cross_cap": floori(float(TARGET_LEVEL + 3) / 2.0),
			"ranks": Dictionary(staged_result.get("added", {})),
		},
		"feat": {
			"slots_before": ClassProgression.feat_slots(class_key, 3),
			"slots_after": ClassProgression.feat_slots(class_key, TARGET_LEVEL),
			"granted": String(staged_result.get("feat", "")),
		},
		"spells": {
			"slots_before": before_slots,
			"slots_after": after_slots,
			"known_before": before_known,
			"known_after": after_known,
		},
		"required": _required(ch, staged_result),
		"notices": _notices(ch, staged),
	}


## Which choices the step still needs, without judging their values. `preview`,
## `apply` and the batch-3 choice data all read this list, so it cannot drift.
static func required_choices(ch: Character, choices: Dictionary = {}) -> Array[String]:
	var required: Array[String] = []
	if ch == null:
		return required
	if String(choices.get("ability", "")).strip_edges() == "":
		required.append("ability")
	var class_key := String(ch.char_class).to_lower()
	var gained := (
		ClassProgression.feat_slots(class_key, TARGET_LEVEL)
		- ClassProgression.feat_slots(class_key, 3)
	)
	if gained > 0 and String(choices.get("feat", "")).strip_edges() == "":
		required.append("feat")
	if class_key == "sorcerer" and String(choices.get("spell", "")).strip_edges() == "":
		required.append("spell")
	return required


static func _required(ch: Character, staged_result: Dictionary) -> Array[String]:
	return required_choices(ch, {
		"ability": String(staged_result.get("ability", "")),
		"feat": String(staged_result.get("feat", "")),
		"spell": String(staged_result.get("spell", "")),
	})


## Authored facts that stay visible without refusing the step: a rank above the
## new cap is not audited or clamped (section 11.3), and its repair is deferred.
static func _notices(ch: Character, staged: Character) -> Array[String]:
	var notices: Array[String] = []
	var names: Array = Dictionary(ch.skill_ranks).keys()
	names.sort()
	for raw_skill in names:
		var skill := String(raw_skill)
		var value := int(ch.skill_ranks[raw_skill])
		var cap := Skills.max_ranks(staged, skill)
		if value > cap:
			notices.append(
				"%s %d exceeds the %s cap %d; the content repair is deferred"
				% [
					skill,
					value,
					"class" if Skills.is_class_skill(staged, skill) else "cross-class",
					cap,
				]
			)
	return notices


static func _commit(ch: Character, staged: Character) -> void:
	ch.level = staged.level
	ch.abilities = staged.abilities.duplicate(true)
	ch.base_attack = staged.base_attack
	ch.base_saves = staged.base_saves.duplicate(true)
	ch.max_hp = staged.max_hp
	ch.hp = staged.hp
	ch.skill_ranks = staged.skill_ranks.duplicate(true)
	ch.feats.assign(staged.feats)
	ch.spells = staged.spells.duplicate(true)


static func _eligibility(
	eligible: bool, code: String, message: String, ch: Character = null
) -> Dictionary:
	return {
		"eligible": eligible,
		"code": code,
		"message": message,
		"level": 0 if ch == null else int(ch.level),
		"xp": 0 if ch == null else int(ch.xp),
		"threshold": XP_THRESHOLD,
	}


static func _blocked(ch: Character, code: String, message: String) -> Dictionary:
	var level := 0 if ch == null else int(ch.level)
	var xp := 0 if ch == null else int(ch.xp)
	var max_hp := 0 if ch == null else int(ch.max_hp)
	var hp := 0 if ch == null else int(ch.hp)
	var bab := 0 if ch == null else int(ch.base_attack)
	var saves := {}
	for save in SAVES:
		var value := 0 if ch == null else int(Dictionary(ch.base_saves).get(save, 0))
		saves[save] = {"before": value, "after": value}
	var slots := {}
	var known: Array = []
	if ch != null:
		slots = Dictionary(ch.spells.get("slots", {})).duplicate(true)
		known = Array(ch.spells.get("known", [])).duplicate()
	return {
		"ok": false,
		"code": code,
		"message": message,
		"eligible": false,
		"from_level": level,
		"to_level": TARGET_LEVEL,
		"xp": xp,
		"threshold": XP_THRESHOLD,
		"hit_points": {
			"max_before": max_hp,
			"max_after": max_hp,
			"hp_before": hp,
			"hp_after": hp,
			"delta": 0,
		},
		"base_attack": {"before": bab, "after": bab},
		"base_saves": saves,
		"ability": {
			"key": "",
			"before": 0,
			"after": 0,
			"modifier_before": 0,
			"modifier_after": 0,
		},
		"skills": {
			"budget": 0,
			"spent": 0,
			"remaining": 0,
			"class_cap": TARGET_LEVEL + 3,
			"cross_cap": floori(float(TARGET_LEVEL + 3) / 2.0),
			"ranks": {},
		},
		"feat": {"slots_before": 0, "slots_after": 0, "granted": ""},
		"spells": {
			"slots_before": slots,
			"slots_after": slots.duplicate(true),
			"known_before": known,
			"known_after": known.duplicate(),
		},
		"required": [],
		"notices": [],
	}


static func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}


static func _rank_value(value: Variant) -> int:
	var kind := typeof(value)
	if kind == TYPE_INT:
		return int(value)
	if kind == TYPE_FLOAT:
		var number := float(value)
		if is_equal_approx(number, roundf(number)):
			return int(number)
	return -1


static func _owns_feat(ch: Character, key: String, parameter: String) -> bool:
	for text in ch.feats:
		var parsed := Feats.parse(String(text))
		if String(parsed.get("key", "")) != key:
			continue
		if String(parsed.get("param", "")).to_lower() == parameter.to_lower():
			return true
	return false
