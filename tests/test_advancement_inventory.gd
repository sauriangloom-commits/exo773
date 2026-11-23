extends GutTest

## Batch 6b of docs/DEMO_ADVANCEMENT_PLAN.md: the informational award inventory
## printed by `--validate-diagnostics`.
##
## The inventory is a static sum over the campaign's authored awards. It is not a
## route and it is not reachability: `test_demo_xp_ledger_matches_the_content`
## pins the ledger, `--advancement-probe` is the only thing that walks a route, and
## this line only tells an author what the content contains.
##
## Classification rule pinned here: an encounter is **ordinary** when a shipped
## trigger, effect or dialogue choice names it, and **QA-only** when nothing in the
## content does. "No map trigger" is not the test - `crypt_warden` has no trigger at
## all and is entered from Corvin's dialogue, so a trigger-only heuristic would
## miscount it as QA-only.

const DEMO := "ravenloft_demo"
const SHORT := "hollow_lantern"


func _inventory(campaign_id: String) -> Dictionary:
	var loaded := Game.load_campaign(campaign_id)
	assert_true(bool(loaded.get("ok", false)), "%s loads" % campaign_id)
	return Game.content.advancement_inventory()


func _line(campaign_id: String, inventory: Dictionary) -> String:
	return ContentDiagnostics.advancement_line(campaign_id, inventory)


# -------------------------------------------------------------------- tests


## The demo's authored awards after batch 6a: encounters 1,500 (300 + 450 + 600 +
## 150 + 0), effects 3,000 (bell 500 + 2,300, pact 200), QA-only 150.
func test_the_demo_inventory_reports_the_authored_awards() -> void:
	var inventory := _inventory(DEMO)
	assert_eq(int(inventory.get("encounters", -1)), 1500, "encounters hold 1,500")
	assert_eq(int(inventory.get("effects", -1)), 3000, "effects hold 3,000")
	assert_eq(int(inventory.get("authored", -1)), 4500, "authored total is 4,500")
	assert_eq(int(inventory.get("qa", -1)), 150, "QA-only awards are 150")
	assert_eq(int(inventory.get("ordinary", -1)), 4350, "ordinary awards are 4,350")
	assert_eq(int(inventory.get("start", -1)), 3000, "the default party starts at 3,000")
	assert_eq(
		int(inventory.get("ordinary", 0)) + int(inventory.get("qa", 0)),
		int(inventory.get("authored", -1)),
		"ordinary plus QA-only adds up to the authored total",
	)

	var line := _line(DEMO, inventory)
	assert_true(
		line.begins_with("ADVANCEMENT AWARDS ravenloft_demo "),
		"the line names the campaign and the report",
	)
	for field in [
		"authored=4500", "ordinary=4350", "qa=150", "encounters=1500", "effects=3000",
		"start=3000", "threshold=6000",
	]:
		assert_true(line.contains(field), "the line carries %s" % field)
	assert_true(line.contains("not a route"), "the line denies being a route")
	assert_true(line.contains("not reachability"), "the line denies proving reachability")
	assert_true(
		line.contains("mutually exclusive"),
		"the line warns that exclusive awards are both counted",
	)
	assert_true(
		line.contains("static inventory"),
		"the line calls itself a static inventory",
	)


## The classification, and the case that forbids a trigger-only heuristic.
func test_qa_only_encounters_are_excluded_from_the_ordinary_total() -> void:
	var inventory := _inventory(DEMO)
	var qa_ids: Array = inventory.get("qa_ids", [])
	assert_has(qa_ids, "qa_victory", "qa_victory has no content entry point")
	assert_has(qa_ids, "qa_turn_undead", "qa_turn_undead has no content entry point")
	assert_false(qa_ids.has("storeroom_dead"), "the storeroom trigger makes it ordinary")
	assert_false(qa_ids.has("town_square_zombies"), "the town square trigger makes it ordinary")
	assert_false(
		qa_ids.has("crypt_warden"),
		"a dialogue-started encounter is ordinary although no map trigger names it",
	)
	var classification: Dictionary = inventory.get("classification", {})
	assert_eq(
		String(classification.get("crypt_warden", "")),
		"ordinary",
		"the classification records why crypt_warden counts",
	)
	assert_eq(String(classification.get("qa_victory", "")), "qa_only", "qa_victory is QA-only")
	assert_eq(
		int(inventory.get("ordinary", 0)) + int(inventory.get("qa", 0)),
		int(inventory.get("authored", -1)),
		"the ordinary total excludes exactly the QA-only awards",
	)


## A campaign that cannot reach 6,000 is legitimate: the line is information, not a
## gate, and it raises no diagnostic.
func test_a_short_campaign_still_passes_although_it_cannot_reach_the_threshold() -> void:
	var inventory := _inventory(SHORT)
	var line := _line(SHORT, inventory)
	assert_lt(
		int(inventory.get("start", 0)) + int(inventory.get("ordinary", 0)),
		6000,
		"%s cannot reach the threshold from its authored awards" % SHORT,
	)
	assert_true(line.contains("ADVANCEMENT AWARDS hollow_lantern "), "the short campaign still reports")
	assert_true(line.contains("threshold=6000"), "and still names the unchanged threshold")
	assert_eq(int(inventory.get("qa", -1)), 0, "it authors no QA-only encounter")
	assert_false(
		ContentDiagnostics.has_errors(Game.content.diagnostics),
		"the shortfall is not a diagnostic and cannot fail the validator",
	)
