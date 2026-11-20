extends GutTest

## The Journal overlay: player-visible regression coverage for the blank
## Journal seen after the exported Ashwick playthrough.
##
## The defect was layout, not quest data: the Journal's RichTextLabel had
## fit_content but no horizontal expansion, so it collapsed to 1 px wide and
## wrapped 6,831 px tall inside its ScrollContainer. The overlay therefore
## showed a heading, an empty body and a tiny scrollbar. These tests assert the
## rendered text and measured layout; checking quest flags alone would not have
## caught the defect.

const ASHWICK := "ashwick_ferry"
const HOLLOW := "hollow_lantern"
const SLOT := "journal_qa"
const PARTY := ["kaelen", "sera", "aldric", "ysolde"]


func before_each() -> void:
	Game.playtest_mode = false
	Game.settings["text_scale"] = 1.0
	SaveSystem.delete_save(SLOT)
	SaveSystem.delete_save("auto")


func after_each() -> void:
	SaveSystem.delete_save(SLOT)
	SaveSystem.delete_save("auto")
	Game.playtest_mode = false
	Game.settings["text_scale"] = 1.0
	# Later scripts assume the suite's ambient campaign is the default demo, so
	# the campaign switch these tests perform must not leak into them.
	Game.reset_to_menu()
	Game.load_campaign("ravenloft_demo")


func _load(campaign: String) -> void:
	var loaded := Game.load_campaign(campaign)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))


func _start(campaign: String, seed := 4242) -> void:
	_load(campaign)
	var started := Game.new_game(PARTY, seed)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))


## Builds the real panel at the size the Journal modal gives it: the modal is
## 800x560 with 18 px margins, so the content receives at least 720x420.
func _journal_view(panel_size := Vector2(720, 420)) -> Dictionary:
	var journal := Panels.journal()
	# Main._ready applies this theme; text scale comes from its default font size.
	journal.theme = ThemeBuilder.build(16)
	add_child_autofree(journal)
	journal.size = panel_size
	await wait_frames(3)
	var text := journal.find_children("*", "RichTextLabel", true, false)[0] as RichTextLabel
	var scroll := journal.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
	return {"root": journal, "text": text, "scroll": scroll}


func _assert_rendered(view: Dictionary, expected: Array, context: String) -> void:
	var text: RichTextLabel = view["text"]
	var scroll: ScrollContainer = view["scroll"]
	var rendered := text.get_parsed_text()
	for needle in expected:
		assert_true(
			rendered.contains(String(needle)),
			"%s: '%s' is rendered in the Journal" % [context, String(needle)]
		)
	assert_gt(text.size.x, 600.0, "%s: Journal text fills the panel width" % context)
	assert_gte(
		text.size.x,
		scroll.size.x - 24.0,
		"%s: Journal text uses the scroll area's width (%s of %s)" % [context, str(text.size.x), str(scroll.size.x)]
	)
	assert_lt(
		text.get_line_count(),
		60,
		"%s: lines wrap at panel width instead of one character per line" % context
	)
	assert_lt(
		text.get_content_height(),
		2400,
		"%s: wrapped content height stays bounded (%s px)" % [context, str(text.get_content_height())]
	)
	assert_true(
		text.get_global_rect().intersects(scroll.get_global_rect()),
		"%s: Journal text occupies the visible scroll area" % context
	)


func _go(pos: Vector2i, facing: int) -> void:
	Game.position = pos
	Game.facing = facing


func _travel_boathouse() -> void:
	var result := Game.travel_to("ashwick_boathouse", Vector2i(4, 7), Dungeon.NORTH)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))


func _travel_landing() -> void:
	var result := Game.travel_to("ashwick_landing", Vector2i(4, 7), Dungeon.NORTH)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))


func _find_choice(needle: String) -> int:
	for i in Game.dialogue_choices().size():
		if String(Dictionary(Game.dialogue_choices()[i]).get("text", "")).contains(needle):
			return i
	return -1


func _finish_encounter() -> void:
	var guard := 0
	while Game.mode == "combat" and guard < 500:
		guard += 1
		var e := Game.encounter
		if e == null or e.finished:
			break
		if not e.is_player_turn():
			Game.combat_end_turn()
			continue
		var target := -1
		var target_cell := Vector2i(-1, -1)
		for entry in e.combatants:
			if int(entry.get("team", -1)) == Encounter.TEAM_ENEMY:
				var ch: Character = entry["char"]
				if not ch.has_condition("dead"):
					target = int(entry["index"])
					target_cell = Vector2i(entry["cell"])
					break
		if target < 0:
			Game.combat_end_turn()
			continue
		if bool(e.turn_state.get("standard_used", false)):
			Game.combat_end_turn()
			continue
		var active := e.active_entry()
		var active_cell := Vector2i(active["cell"])
		if not e.map.is_within_reach(active_cell, target_cell, 5):
			var occupied := e.occupied_except(int(active["index"]))
			var actor: Character = active["char"]
			var reachable := e.map.reachable(active_cell, actor.speed_ft, occupied)
			var best := Vector2i(-1, -1)
			var best_distance := 1 << 30
			for raw_cell in reachable.keys():
				var cell: Vector2i = raw_cell
				var distance := e.map.distance_ft(cell, target_cell)
				if distance < best_distance:
					best_distance = distance
					best = cell
			if best.x >= 0:
				Game.combat_move(best)
				continue
			Game.combat_end_turn()
			continue
		Game.combat_attack(target)
	assert_eq(Game.mode, "explore", "combat ends in exploration")


## A log where no quest has started reaches the empty branch. Re-initialising the
## QuestLog after starting a campaign is exactly the state a fresh package has
## before any start quest fires, so the Journal is asked to render that state.
func test_journal_explains_an_empty_quest_log() -> void:
	_start(ASHWICK)
	Game.quests.setup(Game.content.quests)
	assert_true(Game.quests.active_quests().is_empty(), "no quest is active")
	var view := await _journal_view()
	_assert_rendered(
		view,
		["Quest Journal", "No active objectives. Explore, and speak with anyone you meet."],
		"no quests"
	)


func test_active_ashwick_journal_lists_every_objective() -> void:
	_start(ASHWICK)
	var view := await _journal_view()
	_assert_rendered(
		view,
		[
			"Quest Journal",
			"The Ashwick Ferry",
			"[ ] Speak with Maela Vey at the landing.",
			"[ ] Find and read the ferryman's ledger.",
			"[ ] Clear the drowned dead from the tack room.",
			"[ ] Recover Ivo's bell token.",
			"[ ] Hear Maela's account of the crossing.",
			"Nothing recorded yet.",
		],
		"active Ashwick quest"
	)


## The original pre-bell save is gone (both retained slots were overwritten by
## the completed landing save), so this reconstructs an equivalent in-progress
## state through ordinary play and an ordinary save/load round trip.
func test_loaded_in_progress_ashwick_save_keeps_journal_entries() -> void:
	_start(ASHWICK)
	_travel_boathouse()
	_go(Vector2i(4, 6), Dungeon.NORTH)
	assert_true(bool(Game.interact().get("ok", false)), "the ledger search succeeds on this seed")
	_go(Vector2i(6, 6), Dungeon.NORTH)
	assert_true(bool(Game.interact().get("ok", false)), "the spare-key search succeeds on this seed")
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.quests.status(ASHWICK), "active", "the reloaded quest is still in progress")
	var view := await _journal_view()
	_assert_rendered(
		view,
		[
			"[x] Find and read the ferryman's ledger.",
			"[ ] Speak with Maela Vey at the landing.",
			"[ ] Hear Maela's account of the crossing.",
		],
		"reloaded in-progress save"
	)


func _choose_available(needle: String) -> int:
	for i in Game.dialogue_choices().size():
		var entry: Dictionary = Game.dialogue_choices()[i]
		if String(entry.get("text", "")).contains(needle) and bool(entry.get("available", false)):
			return i
	return -1


func _commit_account() -> void:
	assert_true(bool(Game.start_dialogue("maela_vey").get("ok", false)))
	Game.dialogue_choose(_choose_available("what the ledger shows"))
	var index := _choose_available("ledger is Ivo")
	assert_gte(index, 0)
	Game.dialogue_choose(index)
	var commit := _choose_available("This commits")
	assert_gte(commit, 0, "the statement page offers an explicit commitment")
	Game.dialogue_choose(commit)
	Game.dialogue_choose(_choose_available("Let her"))
	Game.dialogue_choose(_choose_available("Not yet"))
	assert_eq(Game.mode, "explore")


func _ring_once() -> void:
	_go(Vector2i(3, 7), Dungeon.WEST)
	assert_true(bool(Game.interact().get("ok", false)))
	Game.dialogue_choose(_choose_available("Ring once"))
	Game.dialogue_choose(_choose_available("Step away"))


func _deliver_epilogue() -> void:
	assert_true(bool(Game.start_dialogue("maela_vey").get("ok", false)))
	Game.dialogue_choose(_choose_available("Tell me how the crossing ended"))
	Game.dialogue_choose(_choose_available("What will you tell the village?"))
	assert_true(bool(Game.flags.get("maela_epilogue", false)))
	Game.dialogue_choose(_choose_available("Leave her"))


func test_completed_ashwick_quest_after_reload_shows_completion() -> void:
	_start(ASHWICK)
	_travel_boathouse()
	_go(Vector2i(4, 6), Dungeon.NORTH)
	assert_true(bool(Game.interact().get("ok", false)), "the ledger search succeeds")
	_go(Vector2i(6, 6), Dungeon.NORTH)
	assert_true(bool(Game.interact().get("ok", false)), "the spare-key search succeeds")
	_go(Vector2i(3, 4), Dungeon.NORTH)
	assert_true(bool(Game.interact().get("ok", false)), "the tack-room door opens")
	_go(Vector2i(3, 3), Dungeon.NORTH)
	assert_true(bool(Game.move_forward().get("ok", false)), "entering the tack room starts combat")
	_finish_encounter()
	_travel_landing()
	_commit_account()
	_ring_once()
	assert_eq(Game.quests.status(ASHWICK), "active", "the account is still required")
	_deliver_epilogue()
	assert_true(Game.quests.is_complete(ASHWICK))
	Game.take_victory_pending()
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_true(Game.quests.is_complete(ASHWICK), "the reloaded quest is complete")
	var view := await _journal_view()
	_assert_rendered(
		view,
		["Quest Journal", "Completed: The Ashwick Ferry"],
		"completed quest after reload"
	)


func test_second_campaign_journal_is_not_blank() -> void:
	_start(HOLLOW)
	assert_eq(Game.campaign_id, HOLLOW)
	var view := await _journal_view()
	_assert_rendered(
		view,
		[
			"The Hollow Lantern",
			"Speak with Ivy, the lantern keeper.",
			"Read the watch notice in the yard.",
			"Clear the cistern below the yard.",
		],
		"hollow lantern campaign"
	)


## Supported minimum window (1280x720) with the largest text scale (1.6): the
## modal content still has to wrap at panel width and stay readable.
func test_journal_layout_at_minimum_window_and_maximum_text_scale() -> void:
	_start(ASHWICK)
	Game.settings["text_scale"] = 1.6
	var view := await _journal_view(Vector2(720, 420))
	_assert_rendered(
		view,
		["The Ashwick Ferry", "[ ] Hear Maela's account of the crossing.", "Nothing recorded yet."],
		"1.6 text scale"
	)
