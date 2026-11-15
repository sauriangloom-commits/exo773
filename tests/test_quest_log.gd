extends GutTest

## Quest progress bookkeeping. A quest completion is a transition, not a
## condition to report on every later flag synchronization.


func _quest_def() -> Dictionary:
	return {
		"id": "watch",
		"title": "The Watch",
		"objectives": [
			{"id": "speak", "text": "Speak with the keeper.", "flag": "keeper_spoken"},
			{"id": "clear", "text": "Clear the cistern.", "flag": "cistern_cleared"},
		],
	}


func test_quest_completion_is_reported_once() -> void:
	var log := QuestLog.new()
	log.setup({"watch": _quest_def()})
	assert_true(log.start("watch"), "the quest starts")

	var flags := {"keeper_spoken": true}
	var first := log.sync_flags(flags)
	assert_eq(log.status("watch"), "active", "one objective is not completion")
	assert_true(first.has("Objective complete: Speak with the keeper."))
	assert_false(first.has("Quest complete: The Watch"))

	flags["cistern_cleared"] = true
	var completed := log.sync_flags(flags)
	assert_eq(log.status("watch"), "complete")
	assert_true(completed.has("Objective complete: Clear the cistern."))
	assert_true(completed.has("Quest complete: The Watch"))

	var repeated := log.sync_flags(flags)
	assert_eq(repeated, [], "an already completed quest reports no new transition")
	assert_eq(log.status("watch"), "complete")


func test_objective_flags_are_not_credited_before_the_quest_starts() -> void:
	var log := QuestLog.new()
	log.setup({"watch": _quest_def()})
	var flags := {"keeper_spoken": true, "cistern_cleared": true}
	assert_eq(log.sync_flags(flags), [], "not_started quests do not sync flags")
	assert_eq(log.status("watch"), "not_started")
	assert_false(log.objective_done("watch", "speak"))

	assert_true(log.start("watch"))
	var changes := log.sync_flags(flags)
	assert_eq(log.status("watch"), "complete")
	assert_true(changes.has("Quest complete: The Watch"))
