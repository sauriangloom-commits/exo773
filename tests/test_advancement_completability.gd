extends GutTest

## Batch 6c of docs/DEMO_ADVANCEMENT_PLAN.md §10: does a legal, fully completed
## draft exist for every shipped 3rd-level character?
##
## What the check proves and what it does not: a completed draft exists in the
## rules layer - an ability increase, the whole skill budget spent inside the caps,
## a legal feat where one is granted and a legal unknown spell for the sorcerer. It
## proves nothing about the screen, the keyboard, or whether any campaign awards
## the XP.
##
## The search is exhaustive over the ability/feat/spell space and uses one
## deterministic full-budget skill allocation per combination, because skill
## legality depends only on the budget and the caps, not on which feat or spell is
## chosen. That limit is stated in the plan and in the check's own header.

const DEMO := "ravenloft_demo"


func before_each() -> void:
	var loaded := Game.load_campaign(DEMO)
	assert_true(bool(loaded.get("ok", false)), "the demo campaign loads")


func _character_data(id: String) -> Dictionary:
	return Dictionary(Game.content.characters[id]).duplicate(true)


func _character(id: String) -> Character:
	return Character.from_content(_character_data(id), Game.content.items)


## Every fighter-bonus feat the screen could offer, in every parameter variant, so
## a fighter owning all of them has an empty feat pool.
func _all_fighter_bonus_feats() -> Array[String]:
	var out: Array[String] = []
	var keys: Array = Feats.CATALOG.keys()
	keys.sort()
	for raw_key in keys:
		var data := Dictionary(Feats.CATALOG[String(raw_key)])
		if not bool(data.get("fighter_bonus", false)):
			continue
		var feat_name := String(data.get("name", raw_key))
		var parameters: Array[String] = [""]
		match String(data.get("parameter", "")):
			"weapon":
				parameters = []
				for item_id in Game.content.items.keys():
					if String(Dictionary(Game.content.items[item_id]).get("kind", "")) == "weapon":
						parameters.append(String(item_id))
			"skill":
				parameters = []
				for skill in Skills.all_keys():
					parameters.append(String(skill))
		for parameter in parameters:
			out.append(feat_name if parameter == "" else "%s (%s)" % [feat_name, parameter])
	return out


# -------------------------------------------------------------------- tests


## The positive case: all five shipped characters have a completed draft, and each
## recorded draft really stages with the whole skill budget spent.
func test_every_shipped_level_three_character_has_a_completed_draft() -> void:
	var report := AdvancementCheck.inspect_all(Game.content.characters, Game.content.items)
	assert_eq(int(report.get("checked", -1)), 5, "all five shipped 3rd-level characters are checked")
	assert_eq(int(report.get("failures", -1)), 0, "none of them is reported empty")
	assert_true(Array(report.get("empty", ["?"])).is_empty(), "the empty list is empty")

	for raw in Array(report.get("results", [])):
		var result := Dictionary(raw)
		var who := String(result.get("character", "?"))
		assert_true(bool(result.get("completable", false)), "%s has a completed draft" % who)
		var draft := Dictionary(result.get("draft", {}))
		assert_true(String(draft.get("ability", "")) != "", "%s's draft raises an ability" % who)
		assert_true(
			Dictionary(draft.get("skills", {})).size() > 0,
			"%s's draft spends skill points" % who,
		)
		var ch := _character(who)
		var staged := LevelUp.stage(ch, draft, true)
		assert_true(bool(staged.get("ok", false)), "%s's recorded draft stages" % who)
		assert_eq(
			int(staged.get("spent", -1)),
			int(staged.get("budget", -2)),
			"%s's draft spends the whole skill budget" % who,
		)


## The guarantee: a completed draft stages, while `LevelChoices.validate` still
## refuses the same character for being below the XP threshold. That is why the
## check may not route through validate.
func test_the_check_stages_a_draft_without_using_validate() -> void:
	var ch := _character("kaelen")
	assert_lt(int(ch.xp), LevelUp.XP_THRESHOLD, "the shipped fighter is below the threshold")
	var result := AdvancementCheck.inspect(ch)
	assert_true(bool(result.get("completable", false)), "the fighter has a completed draft")
	var draft := Dictionary(result.get("draft", {}))
	assert_true(String(draft.get("feat", "")) != "", "the fighter's draft answers the feat slot")
	assert_true(Dictionary(draft.get("skills", {})).size() > 0, "the draft spends skill points")
	assert_true(
		bool(LevelUp.stage(ch, draft, true).get("ok", false)),
		"the draft stages on the level-4 copy",
	)
	var refused := LevelChoices.validate(ch, draft)
	assert_false(bool(refused.get("ok", true)), "validate refuses the shipped character")
	assert_eq(
		String(refused.get("code", "")),
		"xp_below_threshold",
		"and the refusal is the threshold, not the draft",
	)


## Negative fixture 1: a sorcerer who already knows the only implemented
## 2nd-level spell has no spell to choose, so no completed draft exists.
func test_a_sorcerer_who_knows_the_only_second_level_spell_has_no_draft() -> void:
	var data := _character_data("mira")
	var spells := Dictionary(data.get("spells", {})).duplicate(true)
	var known := Array(spells.get("known", []))
	assert_false(known.has("scorching_ray"), "the authored sorcerer does not know it")
	known.append("scorching_ray")
	spells["known"] = known
	data["spells"] = spells

	var report := AdvancementCheck.inspect_all(
		{"mira_without_a_spell": data}, Game.content.items
	)
	var result := Dictionary(Array(report.get("results", [{}]))[0])
	assert_true(bool(result.get("checked", false)), "the synthetic sorcerer is checked")
	assert_false(bool(result.get("completable", true)), "no completed draft exists")
	assert_eq(String(result.get("group", "")), "spell", "the spell group is the empty one")
	assert_eq(int(report.get("failures", -1)), 1, "and it counts as one validation failure")

	var line := ContentDiagnostics.advancement_completable_line(DEMO, result)
	assert_true(line.contains("class=sorcerer"), "the line names the class")
	assert_true(line.contains("group=spell"), "the line names the empty group")
	assert_true(line.contains("result=EMPTY"), "the line reports EMPTY")


## Negative fixture 2: a fighter owning every fighter-bonus feat has no feat left
## to choose, so no completed draft exists.
func test_a_fighter_owning_every_fighter_bonus_feat_has_no_draft() -> void:
	var data := _character_data("kaelen")
	data["feats"] = _all_fighter_bonus_feats()
	assert_gt(Array(data["feats"]).size(), 0, "the fixture owns a non-empty feat list")

	var report := AdvancementCheck.inspect_all(
		{"kaelen_without_a_feat": data}, Game.content.items
	)
	var result := Dictionary(Array(report.get("results", [{}]))[0])
	assert_true(bool(result.get("checked", false)), "the synthetic fighter is checked")
	assert_false(bool(result.get("completable", true)), "no completed draft exists")
	assert_eq(String(result.get("group", "")), "feat", "the feat group is the empty one")
	assert_eq(int(report.get("failures", -1)), 1, "and it counts as one validation failure")


## The inherited 6b question: can a prose-only mention of an encounter id count as
## an ordinary reference? It cannot - classification reads trigger fields and
## `start_combat` effects, not text - so the recorded debt was too pessimistic.
func test_a_prose_mention_does_not_make_an_encounter_ordinary() -> void:
	var db := ContentDB.new()
	db.encounters = {"qa_named_in_prose": {"xp": 50}}
	db.areas = {
		"a": {
			"triggers": [],
			"objects": [
				{
					"id": "o",
					"interactions": [
						{
							"id": "i",
							"effects": [
								{"type": "narration", "text": "the words qa_named_in_prose"},
							],
						}
					],
				}
			],
		}
	}
	db.dialogues = {}
	db.quests = {}
	db.journal = {}
	db.characters = {}
	db.campaign = {}

	var inventory := db.advancement_inventory()
	assert_has(Array(inventory.get("qa_ids", [])), "qa_named_in_prose", "prose is not a reference")
	assert_eq(int(inventory.get("qa", -1)), 50, "the award stays QA-only")

	# The same id in a structured `start_combat` effect is a reference.
	db.areas["a"]["objects"][0]["interactions"][0]["effects"].append(
		{"type": "start_combat", "encounter": "qa_named_in_prose"}
	)
	var second := db.advancement_inventory()
	assert_false(
		Array(second.get("qa_ids", [])).has("qa_named_in_prose"),
		"a start_combat effect makes it ordinary",
	)
