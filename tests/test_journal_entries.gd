extends GutTest

## The Journal's authored notes: player-facing facts, open questions, spoiler
## gating, deterministic handling of contradictory flags, and the promise that
## none of it touches the save format.
##
## The notes are content (`content/campaigns/<id>/journal.json`); the rendering
## reads only `Game.flags`. These tests therefore cover both the data contract
## and the pure selection logic `Panels.journal_notes()`.

const ASHWICK := "ashwick_ferry"
const HOLLOW := "hollow_lantern"
const DEMO := "ravenloft_demo"
const SLOT := "journal_notes_qa"
const PARTY := ["kaelen", "sera", "aldric", "ysolde"]
const CAMPAIGNS := [DEMO, HOLLOW, ASHWICK]


func before_each() -> void:
	Game.playtest_mode = false
	Game.settings["text_scale"] = 1.0
	_cleanup()


func after_each() -> void:
	_cleanup()
	Game.playtest_mode = false
	Game.settings["text_scale"] = 1.0
	Game.reset_to_menu()
	Game.load_campaign(DEMO)


func _cleanup() -> void:
	for campaign in CAMPAIGNS:
		var path := SaveSystem.path_for(SLOT, campaign)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _start(campaign: String, seed := 4242) -> void:
	Game.reset_to_menu()
	var loaded := Game.load_campaign(campaign)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	var started := Game.new_game(PARTY, seed)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))


func _facts() -> Array:
	return Array(Panels.journal_notes(Game.flags)["facts"])


func _questions() -> Array:
	return Array(Panels.journal_notes(Game.flags)["questions"])


func _set_flags(names: Array) -> void:
	for name in names:
		Game.flags[String(name)] = true


func _journal_text() -> String:
	var panel := Panels.journal()
	panel.theme = ThemeBuilder.build(16)
	add_child_autofree(panel)
	panel.size = Vector2(720, 420)
	await wait_frames(3)
	var body := panel.find_children("*", "RichTextLabel", true, false)[0] as RichTextLabel
	return body.get_parsed_text()


## Every shipped campaign must load with a notes file that passes validation: a
## typo in a flag name would silently drop a fact the player earned.
func test_shipped_campaigns_have_valid_journal_notes() -> void:
	for campaign in CAMPAIGNS:
		var loaded := Game.load_campaign(campaign)
		assert_true(bool(loaded.get("ok", false)), "%s loads: %s" % [campaign, loaded.get("message", "")])
		assert_false(Game.content.journal.is_empty(), "%s ships journal notes" % campaign)
		assert_eq(
			int(Game.content.journal.get("format_version", 0)),
			ContentDB.JOURNAL_FORMAT_VERSION,
			"%s declares the supported notes format" % campaign
		)
		assert_eq(Game.content.errors.size(), 0, "%s has no content errors" % campaign)


## Coverage: every flag the campaign can set is either a fact with player-facing
## wording or explicitly internal. Nothing is allowed to fall through the gaps.
func test_every_authored_flag_is_a_fact_or_internal() -> void:
	for campaign in CAMPAIGNS:
		var loaded := Game.load_campaign(campaign)
		assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
		var authored := Game.content.authored_flags()
		assert_gt(authored.size(), 0, "%s sets flags" % campaign)
		var covered := {}
		for entry in Array(Game.content.journal.get("facts", [])):
			covered[String(Dictionary(entry).get("flag", ""))] = true
		for entry in Array(Game.content.journal.get("internal", [])):
			covered[String(entry)] = true
		for flag in authored.keys():
			assert_true(
				covered.has(String(flag)),
				"%s: flag '%s' is a fact or internal, never a raw journal id" % [campaign, flag]
			)


## Authored order, not alphabetical and not flag order: the journal is a record
## of the story, so the notice is read before the ledger is found.
func test_facts_follow_authored_order() -> void:
	_start(ASHWICK)
	_set_flags(["ledger_found", "ashwick_notice_read"])
	var facts := _facts()
	assert_eq(facts.size(), 2, "only the flags that are set render")
	assert_true(
		String(facts[0]).begins_with("The landing notice"),
		"the notice is authored first: %s" % String(facts[0])
	)
	assert_true(String(facts[1]).contains("ledger"), "the ledger follows it: %s" % String(facts[1]))


func test_raw_flag_ids_never_reach_the_player() -> void:
	_start(ASHWICK)
	_set_flags(["ashwick_notice_read", "ledger_found", "maela_trust"])
	var rendered := "\n".join(PackedStringArray(_facts()))
	for flag in ["ashwick_notice_read", "ledger_found", "maela_trust"]:
		assert_false(rendered.contains(flag), "raw id '%s' does not appear" % flag)


## A question stays hidden until the flag that puts it in the player's head is
## set, so the journal cannot spoil an unread notice or an unopened ledger.
func test_question_requires_its_reveal_flag() -> void:
	_start(HOLLOW)
	assert_eq(_questions().size(), 0, "nothing is asked before the notice is read")
	_set_flags(["lantern_notice_read"])
	var questions := _questions()
	assert_eq(questions.size(), 1, "reading the notice raises the question")
	assert_true(String(questions[0]).contains("watch notice"), String(questions[0]))


func test_answered_question_disappears() -> void:
	_start(HOLLOW)
	_set_flags(["lantern_notice_read", "lantern_trusted"])
	assert_eq(_questions().size(), 0, "the keeper's confidence answers it")
	var facts := _facts()
	assert_true(
		not facts.is_empty() and String(facts[-1]).contains("brother"),
		"the answer is recorded as a fact instead"
	)


## Two mutually exclusive flags in one save must not print two contradictory
## facts. The authored order decides, deterministically, every time.
func test_conflicting_flags_render_one_fact_in_authored_order() -> void:
	_start(ASHWICK)
	_set_flags(["maela_truth", "maela_mercy"])
	var facts := _facts()
	var truth_lines: Array = []
	for line in facts:
		if String(line).contains("Ivo's debt was real"):
			truth_lines.append(line)
	assert_eq(truth_lines.size(), 1, "the truth is recorded once")
	var mercy := 0
	for line in facts:
		if String(line).contains("let her keep that"):
			mercy += 1
	assert_eq(mercy, 0, "the suppressed half of the pair is not shown")
	# Same inputs, same output: the rule is order, not dictionary iteration.
	assert_eq(_facts(), facts, "selection is stable across calls")


func test_conflict_does_not_hide_a_lone_flag() -> void:
	_start(ASHWICK)
	_set_flags(["maela_mercy"])
	var rendered := "\n".join(PackedStringArray(_facts()))
	assert_true(rendered.contains("let her keep that"), "a lone mercy fact still renders")
	assert_false(rendered.contains("Ivo's debt was real"), "its partner stays absent")


func test_no_earned_flags_explains_itself() -> void:
	_start(ASHWICK)
	assert_eq(_facts().size(), 0, "a new game has no facts")
	assert_eq(_questions().size(), 0, "and asks nothing yet")
	var text := await _journal_text()
	assert_true(text.contains("Quest Journal"), "the quest log is still there")
	assert_true(text.contains("Nothing recorded yet."), "the notes area explains its emptiness")
	assert_false(text.contains("Recorded world events"), "the raw flag dump is gone")


## A campaign authored before journal.json existed must keep working: the notes
## sections are absent rather than empty headings.
func test_missing_notes_file_hides_the_sections() -> void:
	_start(ASHWICK)
	var saved: Dictionary = Game.content.journal
	Game.content.journal = {}
	var text := await _journal_text()
	Game.content.journal = saved
	assert_false(text.contains("What you know"), "no facts heading")
	assert_false(text.contains("Still open"), "no questions heading")
	assert_false(text.contains("Nothing recorded yet."), "no empty-state line either")
	assert_true(text.contains("Quest Journal"), "the quest log still renders")


## The save format is untouched: flags and quests round-trip, no notes are
## persisted, and an existing slot from before this feature loads as it did.
## The loader must refuse notes it cannot trust: a newer format, a flag the
## campaign never sets, an entry of the wrong type, a flag listed twice, and a
## question that is revealed and resolved by the same flag.
func test_validation_rejects_malformed_notes() -> void:
	_start(ASHWICK)
	Game.content.journal = {
		"format_version": 2,
		"facts": [
			{"flag": "no_such_flag", "text": "A fact about nothing."},
			{"flag": "ledger_found"},
			"junk",
			{"flag": "maela_trust", "text": "Twice-recorded flag."},
			{"flag": "maela_trust", "text": "Twice-recorded flag."},
		],
		"questions": [
			{"text": "Already answered and unanswered at once?", "revealed_by": "maela_epilogue", "resolved_by": "maela_epilogue"},
		],
		"internal": ["ledger_found"],
	}
	Game.content.errors.clear()
	Game.content.validate()
	var joined := "\n".join(PackedStringArray(Game.content.errors))
	assert_true(joined.contains("format_version 2 is not supported"), joined)
	assert_true(joined.contains("no_such_flag"), joined)
	assert_true(joined.contains("has no text"), joined)
	assert_true(joined.contains("facts entries must be objects"), joined)
	assert_true(joined.contains("as a fact twice"), joined)
	assert_true(joined.contains("both a fact and internal"), joined)
	assert_true(joined.contains("revealed and resolved by the same flag"), joined)


func test_save_round_trip_preserves_flags_and_the_save_format() -> void:
	_start(ASHWICK)
	_set_flags(["ledger_found", "maela_trust"])
	var facts_before := _facts()
	var flags_before: Dictionary = Game.flags.duplicate(true)
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var path := SaveSystem.path_for(SLOT, ASHWICK)
	assert_true(FileAccess.file_exists(path), "the save was written")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "the slot is JSON")
	var payload: Dictionary = parsed
	assert_eq(int(payload.get("save_version", -1)), SaveSystem.SAVE_VERSION, "save version unchanged")
	assert_false(payload.has("journal"), "no journal state is written into the save")
	assert_true(payload.get("flags", null) is Dictionary, "flags are still saved as before")
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.flags, flags_before, "flags survive the round trip")
	assert_eq(_facts(), facts_before, "the journal renders the same lines after loading")
