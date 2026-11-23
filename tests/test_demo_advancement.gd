extends GutTest

## Batch 6a of docs/DEMO_ADVANCEMENT_PLAN.md: the demo's award ledger and the route
## that reaches 4th level.
##
## The ledger is read from the shipped content, not from this file: every XP effect
## is found by walking the campaign's area and dialogue dictionaries, and every
## encounter award from `encounters.json`. The numbers below are therefore pins on
## the content - a changed award fails here rather than drifting unnoticed.
##
## Pre-milestone ledger (plan §2, verified at `6e556cc`): authored 2,200,
## ordinary 2,050, best single route 1,850, least-awarding completion 700.
## Batch 6a adds the 2,300 XP milestone to the bell, so every route that rings the
## bell rises by 2,300 and the pins below are the post-6a ones. The non-bell
## figures (pact 200, storeroom 300, crypt 450, town square 600, QA 150) are
## unchanged.
##
## What these tests do not establish: that a player can walk the route (that is
## `--advancement-probe`), that the level-up screen renders it, or that the
## guarantees hold by any path other than the recorded one.

const CAMPAIGN := "ravenloft_demo"
const START_XP := 3000
const THRESHOLD := 6000

var content: ContentDB


func before_each() -> void:
	Game.load_campaign(CAMPAIGN)
	content = Game.content


# ------------------------------------------------------------------ helpers


## Every dictionary in `node` whose `type` is `xp`, in content order.
func _xp_effects(node: Variant, out: Array) -> void:
	if node is Dictionary:
		var dictionary: Dictionary = node
		if String(dictionary.get("type", "")) == "xp":
			out.append(dictionary)
		for key in dictionary.keys():
			_xp_effects(dictionary[key], out)
	elif node is Array:
		for item in node:
			_xp_effects(item, out)


## The total XP carried by every `xp` effect under `node`.
func _effects_xp(node: Variant) -> int:
	var effects: Array = []
	_xp_effects(node, effects)
	var total := 0
	for effect in effects:
		total += int(Dictionary(effect).get("amount", 0))
	return total


## Every dictionary under `node` that sets `flag` to a truthy value.
func _flag_setters(node: Variant, flag: String, out: Array) -> void:
	if node is Dictionary:
		var dictionary: Dictionary = node
		if (
			String(dictionary.get("type", "")) == "set_flag"
			and String(dictionary.get("flag", "")) == flag
			and bool(dictionary.get("value", false))
		):
			out.append(dictionary)
		for key in dictionary.keys():
			_flag_setters(dictionary[key], flag, out)
	elif node is Array:
		for item in node:
			_flag_setters(item, flag, out)


func _encounter_xp() -> int:
	var total := 0
	for encounter_id in content.encounters.keys():
		total += int(Dictionary(content.encounters[encounter_id]).get("xp", 0))
	return total


## Effects live in areas (`areas` already contains `dungeon.json`) and dialogue.
func _effect_xp() -> int:
	return _effects_xp(content.areas) + _effects_xp(content.dialogues)


func _area(area_id: String) -> Dictionary:
	return Dictionary(content.areas.get(area_id, {}))


func _object(area_id: String, object_id: String) -> Dictionary:
	for raw in Array(_area(area_id).get("objects", [])):
		var object: Dictionary = raw
		if String(object.get("id", "")) == object_id:
			return object
	return {}


## The XP carried by one object interaction's own effect list.
func _interaction_xp(object: Dictionary, interaction_id: String) -> int:
	for raw in Array(object.get("interactions", [])):
		var interaction: Dictionary = raw
		if String(interaction.get("id", "")) == interaction_id:
			return _effects_xp(interaction.get("effects", []))
	return -1


func _objective_flags(quest_id: String) -> Array:
	var flags: Array = []
	var quest := Dictionary(content.quests.get(quest_id, {}))
	for raw in Array(quest.get("objectives", [])):
		flags.append(String(Dictionary(raw).get("flag", "")))
	return flags


func _dialogues_corpus() -> String:
	return JSON.stringify([content.areas, content.dialogues, content.quests])


# -------------------------------------------------------------------- tests


## Test 1 of plan §11: the ledger, summed from the content and pinned.
func test_demo_xp_ledger_matches_the_content() -> void:
	var encounters := _encounter_xp()
	var effects := _effect_xp()
	var authored := encounters + effects
	var qa := 0
	for qa_id in ["qa_victory", "qa_turn_undead"]:
		qa += int(Dictionary(content.encounters.get(qa_id, {})).get("xp", 0))

	assert_eq(encounters, 1500, "the authored encounters award 1,500 (300 + 450 + 600 + 150 + 0)")
	assert_eq(effects, 3000, "the authored effects award 3,000 (bell 500 + 2,300, pact 200)")
	assert_eq(authored, 4500, "the authored inventory is 4,500")
	assert_eq(qa, 150, "the QA encounter holds 150 of it")
	assert_eq(authored - qa, 4350, "the ordinary-only inventory is 4,350")
	assert_eq(
		300 + 450 + 500 + 2300 + 600,
		4150,
		"one ordinary route can carry 4,150: storeroom + crypt + bell + town square",
	)
	assert_eq(
		0 + 200 + 500 + 2300,
		3000,
		"the least-awarding completion carries 3,000: crate + pact + bell",
	)


## Test 2 of plan §11: the named routes, each summed from the content's own bell
## award so the test fails while the milestone is missing.
func test_the_named_route_reaches_the_threshold() -> void:
	var bell := _object("old_gatehouse", "bell")
	assert_eq(bell.get("id", ""), "bell", "the gatehouse bell exists")
	var bell_xp := _interaction_xp(bell, "ring")
	assert_eq(bell_xp, 2800, "ringing the bell awards 500 + the 2,300 milestone")

	var combat_route := START_XP + 300 + 450 + bell_xp
	var parley_route := START_XP + 0 + 200 + bell_xp
	var unresolved := START_XP + 0 + 0 + bell_xp

	assert_eq(
		combat_route,
		6550,
		"the named combat route (storeroom, crypt, bell) totals 6,550",
	)
	assert_eq(
		parley_route,
		6000,
		"the parley route (crate, pact, bell) totals exactly 6,000",
	)
	assert_true(combat_route >= THRESHOLD and parley_route >= THRESHOLD, "both reach the threshold")
	assert_eq(
		unresolved,
		5800,
		"ringing the bell without resolving the warden stops at 5,800, below the threshold",
	)
	assert_lt(unresolved, THRESHOLD, "the bypass is not eligible at the bell")


## Test 3 of plan §11: no shipped content names the QA encounters.
func test_the_qa_encounters_have_no_content_entry_point() -> void:
	assert_true(content.encounters.has("qa_victory"), "the QA victory encounter is authored")
	assert_true(content.encounters.has("qa_turn_undead"), "the QA turn-undead encounter is authored")
	var corpus := _dialogues_corpus()
	assert_false(corpus.contains("qa_victory"), "no area, dialogue or quest names qa_victory")
	assert_false(
		corpus.contains("qa_turn_undead"),
		"no area, dialogue or quest names qa_turn_undead",
	)


## Test 4 of plan §11: the quest needs the crate's flag, which only the crate sets.
func test_drowned_bell_needs_the_crate_flag() -> void:
	var flags := _objective_flags("drowned_bell")
	assert_true(flags.has("found_clapper"), "the quest has a found_clapper objective")
	assert_true(flags.has("warden_resolved"), "the quest also needs the warden resolved")
	assert_true(flags.has("bell_rung"), "and the bell rung")

	var setters: Array = []
	_flag_setters(content.areas, "found_clapper", setters)
	_flag_setters(content.dialogues, "found_clapper", setters)
	assert_eq(setters.size(), 1, "exactly one effect in the shipped content sets found_clapper")

	var crate := _object("old_gatehouse", "supply_crate")
	var crate_setters: Array = []
	_flag_setters(crate.get("interactions", []), "found_clapper", crate_setters)
	assert_eq(crate_setters.size(), 1, "the crate's search is the effect that sets it")

	# The pact hands over the clapper item but not the quest flag, which is why the
	# crate is on every completion route and the 700 pre-milestone floor held.
	var corvin := Dictionary(content.dialogues.get("corvin", {}))
	var nodes := Dictionary(corvin.get("nodes", {}))
	var pact := Dictionary(nodes.get("pact", {}))
	var pact_setters: Array = []
	_flag_setters(pact.get("effects", []), "found_clapper", pact_setters)
	assert_eq(pact_setters.size(), 0, "Corvin's pact gives the clapper but sets no quest flag")
	assert_true(
		JSON.stringify(pact.get("effects", [])).contains("bell_clapper"),
		"the pact does hand over the clapper item",
	)
