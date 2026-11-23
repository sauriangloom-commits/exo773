class_name AdvancementCheck
extends RefCounted

## Choice-completability for shipped 3rd-level characters - batch 6c of
## docs/DEMO_ADVANCEMENT_PLAN.md §10.
##
## What it proves: for a character authored at 3rd level whose class has a 4th-level
## row, at least one *completed* draft is accepted by
## the engine's completed stage call, `LevelChoices.stage_completed` - one ability
## increase, the whole skill
## budget spent inside the caps, a legal feat where the class grants one, and a
## legal unknown 2nd-level spell for the sorcerer.
##
## What it does not prove: that the screen can render the draft, that the keyboard
## can reach it, that a player will find it, or that any campaign awards the XP. It
## is not reachability; `--advancement-probe` is the only thing that walks a route.
##
## Why `stage` and not `LevelChoices.validate`: `validate` asks eligibility first,
## and every shipped character sits at 3,000 XP against a 6,000 threshold, so it
## would refuse every one of them before looking at a draft.
##
## Search strategy and its limit. The ability, feat and spell spaces are exhaustive:
## all six abilities, every feat the level-up screen would offer for that ability
## (`LevelChoices.feat_options`, so implemented, fighter-bonus, unowned, and graded
## against the staged level-4 copy - the ability increase is applied before
## prerequisites are checked), and every spell the screen would offer
## (`LevelChoices.spell_options`, which removes known spells). The skill allocation
## is one deterministic full-budget allocation per combination, because skill
## legality depends only on the budget (class points plus the Int modifier after the
## increase) and on the caps, neither of which depends on the feat or the spell. A
## second allocation is therefore not needed to prove the skill group legal; when
## this one cannot spend the budget, the character is reported rather than passed.

const TARGET_LEVEL := LevelUp.TARGET_LEVEL


## Every authored character in the table, sorted by id. Builds each one from its
## content dictionary through the ordinary constructor.
static func inspect_all(characters: Dictionary, items: Dictionary) -> Dictionary:
	var ids: Array = characters.keys()
	ids.sort()
	var results: Array = []
	var empty: Array[String] = []
	var checked := 0
	for raw_id in ids:
		var data := Dictionary(characters[raw_id]).duplicate(true)
		var ch := Character.from_content(data, items)
		if ch == null:
			continue
		var result := inspect(ch)
		results.append(result)
		if bool(result["checked"]):
			checked += 1
			if not bool(result["completable"]):
				empty.append(String(result["character"]))
	return {"results": results, "checked": checked, "empty": empty, "failures": empty.size()}


## One character's verdict. `group` names the choice group that emptied when no
## draft exists: ability, skill, feat, spell, or `combination` when each group had
## candidates but no combination staged.
static func inspect(ch: Character) -> Dictionary:
	var out := {
		"character": String(ch.id),
		"class": String(ch.char_class).to_lower(),
		"level": int(ch.level),
		"checked": false,
		"completable": false,
		"group": "",
		"attempts": 0,
		"draft": {},
		"reason": "",
	}
	var class_key := String(ch.char_class).to_lower()
	if int(ch.level) != 3:
		out["reason"] = "not_level_3"
		return out
	if not ClassProgression.CLASSES.has(class_key):
		out["reason"] = "class_not_tabled"
		return out
	if ClassProgression.row(class_key, TARGET_LEVEL).is_empty():
		out["reason"] = "no_level_4_row"
		return out
	out["checked"] = true

	var feat_slot := (
		ClassProgression.feat_slots(class_key, TARGET_LEVEL)
		- ClassProgression.feat_slots(class_key, 3)
	)
	var needs_spell := class_key == "sorcerer"
	var any_feat := false
	var any_spell := false
	var any_skill := false

	for raw_ability in LevelUp.ABILITIES:
		var ability := String(raw_ability)
		var base := {"ability": ability}
		var feats := _feat_candidates(ch, base)
		var spells := _spell_candidates(ch, base)
		var skills := full_skill_spend(ch, ability)
		if not feats.is_empty():
			any_feat = true
		if not spells.is_empty():
			any_spell = true
		if not skills.is_empty():
			any_skill = true
		if feat_slot > 0 and feats.is_empty():
			continue
		if needs_spell and spells.is_empty():
			continue
		if skills.is_empty():
			continue
		var feat_choices: Array = feats if feat_slot > 0 else [""]
		var spell_choices: Array = spells if needs_spell else [""]
		for feat in feat_choices:
			for spell in spell_choices:
				var draft := {
					"ability": ability,
					"skills": skills.duplicate(true),
					"feat": String(feat),
					"spell": String(spell),
				}
				out["attempts"] = int(out["attempts"]) + 1
				# Staged by the choice module, which owns the call; `validate` is not
				# usable here because it refuses on eligibility first.
				var staged := LevelChoices.stage_completed(ch, draft)
				if (
					bool(staged.get("ok", false))
					and int(staged.get("spent", -1)) == int(staged.get("budget", -2))
				):
					out["completable"] = true
					out["draft"] = draft
					return out

	if feat_slot > 0 and not any_feat:
		out["group"] = "feat"
	elif needs_spell and not any_spell:
		out["group"] = "spell"
	elif not any_skill:
		out["group"] = "skill"
	else:
		out["group"] = "combination"
	return out


## One full-budget skill allocation for this ability, or {} when the budget cannot
## be spent at all. One rank at a time, class skills first, so a leftover point is
## never stranded behind a cross-class rank that costs two.
static func full_skill_spend(ch: Character, ability: String) -> Dictionary:
	var remaining := LevelChoices.skill_budget(ch, ability)
	if remaining <= 0:
		return {}
	var allocation := {}
	var guard := 0
	while remaining > 0 and guard < 64:
		guard += 1
		var rows := LevelChoices.skill_options(ch, {"ability": ability, "skills": allocation})
		var best := {}
		for raw in rows:
			var row := Dictionary(raw)
			if int(row.get("max_new_ranks", 0)) <= 0:
				continue
			if best.is_empty() or _prefer(row, best):
				best = row
		if best.is_empty():
			return {}
		var skill := String(best["skill"])
		allocation[skill] = int(allocation.get(skill, 0)) + 1
		remaining -= int(best["cost_per_rank"])
	return allocation if remaining == 0 else {}


## Class skills before cross-class, then the widest remaining capacity, then name,
## so the allocation is deterministic.
static func _prefer(candidate: Dictionary, best: Dictionary) -> bool:
	var candidate_class := bool(candidate.get("class_skill", false))
	var best_class := bool(best.get("class_skill", false))
	if candidate_class != best_class:
		return candidate_class
	var candidate_room := int(candidate.get("max_new_ranks", 0))
	var best_room := int(best.get("max_new_ranks", 0))
	if candidate_room != best_room:
		return candidate_room > best_room
	return String(candidate.get("skill", "")) < String(best.get("skill", ""))


static func _feat_candidates(ch: Character, draft: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw in LevelChoices.feat_options(ch, draft):
		var row := Dictionary(raw)
		if bool(row.get("eligible", false)):
			out.append(String(row.get("text", "")))
	return out


static func _spell_candidates(ch: Character, draft: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw in LevelChoices.spell_options(ch, draft):
		out.append(String(Dictionary(raw).get("id", "")))
	return out
