extends GutTest

## Focused acceptance for the original Ashwick expansion. These tests use the
## real campaign content through GameSession and the ordinary dialogue/interaction
## APIs. They cover state transitions, not the exported-window route.

const ASHWICK := "ashwick_ferry"
const SLOT := "ashwick_second_ring"
const PARTY := ["kaelen", "sera", "aldric", "ysolde"]
const BELL_POS := Vector2i(3, 7)


func before_each() -> void:
	Game.playtest_mode = false
	SaveSystem.delete_save_everywhere(SLOT)
	SaveSystem.delete_save_everywhere("auto")
	var loaded := Game.load_campaign(ASHWICK)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))


func after_each() -> void:
	SaveSystem.delete_save_everywhere(SLOT)
	SaveSystem.delete_save_everywhere("auto")
	Game.playtest_mode = false


func _start(seed := 4242) -> void:
	var started := Game.new_game(PARTY, seed)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))


func _travel_boathouse() -> void:
	var result := Game.travel_to("ashwick_boathouse", Vector2i(4, 7), Dungeon.NORTH)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))


func _travel_landing() -> void:
	var result := Game.travel_to("ashwick_landing", Vector2i(4, 7), Dungeon.NORTH)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))


func _go(pos: Vector2i, facing: int) -> void:
	Game.position = pos
	Game.facing = facing


func _find_choice(needle: String) -> int:
	for i in Game.dialogue_choices().size():
		if String(Dictionary(Game.dialogue_choices()[i]).get("text", "")).contains(needle):
			return i
	return -1


func _choose_available(needle: String) -> int:
	for i in Game.dialogue_choices().size():
		var entry: Dictionary = Game.dialogue_choices()[i]
		if String(entry.get("text", "")).contains(needle) and bool(entry.get("available", false)):
			return i
	return -1


func _item_count(item_id: String) -> int:
	var count := 0
	for ch in Game.party:
		count += ch.inventory_count(item_id)
	return count


func _open_ledger() -> void:
	_go(Vector2i(4, 6), Dungeon.NORTH)
	var result := Game.interact()
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))
	assert_true(bool(Game.flags.get("ledger_found", false)))


func _open_strongbox() -> void:
	_go(Vector2i(7, 6), Dungeon.NORTH)
	var result := Game.interact_with_take(10)
	if not bool(result.get("ok", false)):
		result = Game.interact_with_take(20)
	assert_true(bool(result.get("ok", false)), "the optional strongbox opens")
	assert_true(bool(Game.flags.get("last_page_found", false)))
	assert_true(Game.dungeon.is_removed("boathouse_strongbox"))


func _open_tack_room_and_clear() -> void:
	_go(Vector2i(6, 6), Dungeon.NORTH)
	var spare := Game.interact()
	assert_true(bool(spare.get("ok", false)), "the spare key is found")
	_go(Vector2i(3, 4), Dungeon.NORTH)
	var door := Game.interact()
	assert_true(bool(door.get("ok", false)), "the tack-room door opens")
	_go(Vector2i(3, 3), Dungeon.NORTH)
	assert_true(bool(Game.move_forward().get("ok", false)), "entering the tack room starts combat")
	_finish_combat()
	assert_true(bool(Game.flags.get("ivo_token_found", false)))
	assert_eq(_item_count("ivo_token"), 1)


func _finish_combat() -> void:
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


func _commit_account(truth := true, with_page := false) -> void:
	var started := Game.start_dialogue("maela_vey")
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))
	var entry := _choose_available("what the ledger shows")
	assert_gte(entry, 0, "the account decision is entered from a named option")
	Game.dialogue_choose(entry)
	var needle := "ledger is Ivo" if truth else "passenger home"
	if with_page:
		needle = "Show her the last page"
		assert_gte(
			_choose_available(needle),
			0,
			"the evidence-aware statement is offered once the last page is found",
		)
	var index := _choose_available(needle)
	assert_gte(index, 0, "the account choice is available")
	var opened := Game.dialogue_choose(index)
	assert_true(bool(opened.get("ok", false)), String(opened.get("message", "")))
	assert_false(bool(Game.flags.get("maela_decision", false)), "reading a statement does not commit it")
	var commit := _choose_available("This commits")
	assert_gte(commit, 0, "the statement page offers an explicit commitment")
	var chosen := Game.dialogue_choose(commit)
	assert_true(bool(chosen.get("ok", false)), String(chosen.get("message", "")))
	assert_true(bool(Game.flags.get("maela_decision", false)))
	assert_true(bool(Game.flags.get("maela_truth" if truth else "maela_mercy", false)))
	assert_eq(Game.quests.status("maela_truth" if truth else "maela_mercy"), "active")
	assert_eq(Game.quests.status("maela_mercy" if truth else "maela_truth"), "not_started")
	var exit_index := _choose_available("Let her")
	assert_gte(exit_index, 0)
	Game.dialogue_choose(exit_index)
	var leave_index := _choose_available("Not yet")
	assert_gte(leave_index, 0)
	Game.dialogue_choose(leave_index)
	assert_eq(Game.mode, "explore")


func _approach_bell() -> void:
	_go(BELL_POS, Dungeon.WEST)


func _choose_bell(needle: String) -> void:
	_approach_bell()
	var started := Game.interact()
	assert_true(bool(started.get("ok", false)), "the bell dialogue starts")
	var index := _choose_available(needle)
	assert_gte(index, 0, "bell option '%s' is available" % needle)
	Game.dialogue_choose(index)


func _ring_once() -> void:
	_choose_bell("Ring once")
	var step := _choose_available("Step away")
	assert_gte(step, 0)
	Game.dialogue_choose(step)
	assert_eq(Game.mode, "explore")


func _silence_bell() -> void:
	_choose_bell("Break the token")
	var step := _choose_available("Step away")
	assert_gte(step, 0)
	Game.dialogue_choose(step)
	assert_eq(Game.mode, "explore")


func _deliver_epilogue(truth := true, with_page := false) -> void:
	var started := Game.start_dialogue("maela_vey")
	assert_true(bool(started.get("ok", false)))
	var final_index := _choose_available("Tell me how the crossing ended")
	if final_index < 0:
		final_index = _choose_available("Tell me what answered")
	if final_index < 0:
		final_index = _choose_available("Tell me what the silence")
	assert_gte(final_index, 0)
	Game.dialogue_choose(final_index)
	var account_needle := "What will you tell the village?" if truth else "Let her keep the story"
	if with_page:
		account_needle = "What did the last page change?"
	var account_index := _choose_available(account_needle)
	assert_gte(account_index, 0)
	Game.dialogue_choose(account_index)
	assert_true(bool(Game.flags.get("maela_epilogue", false)))
	var leave_index := _choose_available("Leave her")
	assert_gte(leave_index, 0)
	Game.dialogue_choose(leave_index)
	assert_eq(Game.mode, "explore")


func _reach_bell(truth := true, page := false) -> void:
	_start()
	_travel_boathouse()
	_open_ledger()
	if page:
		_open_strongbox()
	_open_tack_room_and_clear()
	_travel_landing()
	_commit_account(truth)
	_approach_bell()


func test_ordinary_entry_to_epilogue_truth_ring_once() -> void:
	_start()
	var talked := Game.start_dialogue("maela_vey")
	assert_true(bool(talked.get("ok", false)))
	var accept := _choose_available("I will find Ivo")
	assert_gte(accept, 0)
	Game.dialogue_choose(accept)
	Game.dialogue_choose(_choose_available("I will return."))
	_travel_boathouse()
	_open_ledger()
	_open_tack_room_and_clear()
	_travel_landing()
	_commit_account(true)
	assert_false(bool(Game.flags.get("last_page_found", false)), "the optional page is genuinely absent")
	_ring_once()
	assert_true(bool(Game.flags.get("ivo_rested", false)))
	assert_eq(_item_count("ivo_token"), 0)
	assert_eq(Game.quests.status(ASHWICK), "active", "the epilogue is still required")
	assert_false(Game.victory_pending)
	_deliver_epilogue(true)
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_eq(Game.quests.status("maela_truth"), "complete")
	assert_true(Game.victory_pending)
	Game.take_victory_pending()
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_eq(Game.quests.status("maela_truth"), "complete")
	assert_eq(_item_count("ivo_token"), 0)
	assert_false(Game.victory_pending)


func test_truth_and_mercy_are_exclusive_and_persist() -> void:
	_reach_bell(true)
	Game.start_dialogue("maela_vey")
	var entry := _find_choice("what the ledger shows")
	assert_gte(entry, 0, "the committed entry stays visible as a gated row")
	var refused := Game.dialogue_choose(entry)
	assert_false(bool(refused.get("ok", false)), "the engine refuses to reopen a committed decision")
	assert_eq(_choose_available("what the ledger shows"), -1, "the entry cannot be taken again")
	assert_eq(_choose_available("passenger home"), -1, "a second account cannot be chosen")
	assert_false(bool(Game.flags.get("maela_mercy", false)))
	assert_eq(Game.quests.status("maela_mercy"), "not_started")
	Game.dialogue_choose(_choose_available("Not yet"))
	_ring_once()
	_deliver_epilogue(true)
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_true(Game.quests.is_complete("maela_truth"))
	assert_false(Game.quests.is_complete("maela_mercy"))


func test_silence_is_exclusive_and_saves_after_ending() -> void:
	_reach_bell(false)
	_choose_bell("Break the token")
	var step := _choose_available("Step away")
	assert_gte(step, 0)
	Game.dialogue_choose(step)
	assert_true(bool(Game.flags.get("bell_silenced", false)))
	assert_true(bool(Game.flags.get("bell_resolved", false)))
	assert_false(bool(Game.flags.get("bell_answer_survived", false)))
	assert_eq(_item_count("ivo_token"), 0)
	assert_eq(Game.quests.status(ASHWICK), "active")
	_approach_bell()
	Game.interact()
	var ring_again := _find_choice("Ring once")
	assert_gte(ring_again, 0)
	assert_false(bool(Game.dialogue_choose(ring_again).get("ok", false)), "another ending is unavailable")
	Game.dialogue_choose(_choose_available("Step away"))
	_deliver_epilogue(false)
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_true(Game.quests.is_complete("maela_mercy"))
	assert_true(Game.victory_pending)
	Game.take_victory_pending()
	assert_true(bool(Game.save_game(SLOT).get("ok", false)))
	assert_true(bool(Game.load_game(SLOT).get("ok", false)))
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_true(bool(Game.flags.get("bell_silenced", false)))
	assert_eq(_item_count("ivo_token"), 0)


func test_ring_twice_starts_once_and_requires_victory() -> void:
	_reach_bell(true)
	_choose_bell("Ring twice")
	assert_eq(Game.mode, "combat")
	assert_eq(Game.active_encounter_id, "ashwick_bell_answer")
	assert_true(bool(Game.flags.get("bell_called", false)))
	assert_false(bool(Game.flags.get("bell_resolved", false)))
	assert_eq(_item_count("ivo_token"), 1, "the token is not spent before victory")
	_finish_combat()
	assert_true(bool(Game.flags.get("bell_answer_survived", false)))
	assert_true(bool(Game.flags.get("bell_resolved", false)))
	assert_eq(_item_count("ivo_token"), 0, "victory consumes the token")
	assert_eq(Game.quests.status(ASHWICK), "active", "the epilogue is still required")
	_deliver_epilogue(true)
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_true(Game.victory_pending)
	Game.take_victory_pending()
	assert_true(bool(Game.save_game(SLOT).get("ok", false)))
	assert_true(bool(Game.load_game(SLOT).get("ok", false)))
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_true(bool(Game.flags.get("bell_answer_survived", false)))
	assert_eq(_item_count("ivo_token"), 0)


func test_ring_twice_defeat_does_not_complete_and_pre_bell_save_retries() -> void:
	_reach_bell(true)
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)))
	_choose_bell("Ring twice")
	assert_eq(Game.mode, "combat")
	var guard := 0
	while Game.mode == "combat" and guard < 300:
		guard += 1
		Game.combat_end_turn()
	assert_eq(Game.mode, "defeat", "the real encounter can end in defeat")
	assert_false(bool(Game.flags.get("bell_resolved", false)))
	assert_false(bool(Game.flags.get("bell_answer_survived", false)))
	assert_eq(_item_count("ivo_token"), 1, "defeat does not consume the token")
	assert_false(Game.quests.is_complete(ASHWICK))
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_false(bool(Game.flags.get("bell_called", false)), "the pre-bell save is before the attempt")
	assert_eq(Game.mode, "explore")
	_silence_bell()
	assert_true(bool(Game.flags.get("bell_silenced", false)))
	_deliver_epilogue(true)
	assert_true(Game.quests.is_complete(ASHWICK))


func test_optional_page_can_be_shown_before_commitment() -> void:
	_start()
	_travel_boathouse()
	_open_ledger()
	_open_strongbox()
	_open_tack_room_and_clear()
	_travel_landing()
	_commit_account(true, true)
	assert_true(bool(Game.flags.get("last_page_shared", false)))
	assert_eq(Game.quests.status("maela_truth"), "active")
	_approach_bell()
	_ring_once()
	_deliver_epilogue(true, true)
	assert_true(Game.quests.is_complete(ASHWICK))


func test_page_found_after_commitment_adds_detail_without_reversing() -> void:
	_start()
	_travel_boathouse()
	_open_ledger()
	_open_tack_room_and_clear()
	_travel_landing()
	_commit_account(true)
	_travel_boathouse()
	_open_strongbox()
	_travel_landing()
	var started := Game.start_dialogue("maela_vey")
	assert_true(bool(started.get("ok", false)))
	var page_index := _choose_available("Show her the page you found")
	assert_gte(page_index, 0)
	Game.dialogue_choose(page_index)
	assert_true(bool(Game.flags.get("last_page_shared", false)))
	assert_true(bool(Game.flags.get("maela_truth", false)))
	assert_false(bool(Game.flags.get("maela_mercy", false)))
	assert_eq(Game.quests.status("maela_truth"), "active")
	assert_eq(Game.quests.status("maela_mercy"), "not_started")
	Game.dialogue_choose(_choose_available("Let her keep the page"))
	Game.dialogue_choose(_choose_available("Not yet"))


func test_page_can_be_kept_after_a_mercy_commitment() -> void:
	_start()
	_travel_boathouse()
	_open_ledger()
	_open_tack_room_and_clear()
	_travel_landing()
	_commit_account(false)
	_travel_boathouse()
	_open_strongbox()
	_travel_landing()
	Game.start_dialogue("maela_vey")
	var keep_index := _choose_available("Keep the last page")
	assert_gte(keep_index, 0)
	Game.dialogue_choose(keep_index)
	assert_true(bool(Game.flags.get("last_page_shared", false)))
	assert_true(bool(Game.flags.get("maela_mercy", false)))
	assert_false(bool(Game.flags.get("maela_truth", false)))
	assert_eq(Game.quests.status("maela_mercy"), "active")
	Game.dialogue_choose(_choose_available("Leave it folded"))
	Game.dialogue_choose(_choose_available("Not yet"))


func test_optional_page_search_failure_remains_recoverable() -> void:
	var found_seed := -1
	for seed in range(1, 120):
		_start(seed)
		_travel_boathouse()
		_open_ledger()
		_go(Vector2i(7, 6), Dungeon.NORTH)
		var first := Game.interact()
		if bool(first.get("ok", false)):
			continue
		if bool(Game.flags.get("last_page_found", false)):
			continue
		if Game.dungeon.is_removed("boathouse_strongbox"):
			continue
		var second := Game.interact()
		if bool(second.get("ok", false)) and bool(Game.flags.get("last_page_found", false)):
			found_seed = seed
			break
	assert_gte(found_seed, 0, "a failed strongbox attempt can be retried")
	assert_true(Game.dungeon.is_removed("boathouse_strongbox"))


func test_repeat_interactions_do_not_repeat_effects_or_epilogue() -> void:
	_reach_bell(true)
	_ring_once()
	_deliver_epilogue(true)
	Game.take_victory_pending()
	var token_after := _item_count("ivo_token")
	_approach_bell()
	assert_true(bool(Game.interact().get("ok", false)))
	var ring_index := _find_choice("Ring once")
	assert_gte(ring_index, 0)
	assert_false(bool(Game.dialogue_choose(ring_index).get("ok", false)))
	Game.dialogue_choose(_choose_available("Step away"))
	assert_eq(_item_count("ivo_token"), token_after)
	Game.start_dialogue("maela_vey")
	var final_index := _find_choice("Tell me how the crossing ended")
	assert_gte(final_index, 0)
	assert_false(bool(Game.dialogue_choose(final_index).get("ok", false)), "the epilogue is once only")
	var post_index := _choose_available("How is the landing now?")
	assert_gte(post_index, 0)
	Game.dialogue_choose(post_index)
	Game.dialogue_choose(_choose_available("Leave her"))
	assert_true(Game.quests.is_complete(ASHWICK))
	assert_false(Game.victory_pending, "a repeat conversation does not raise victory again")


func test_v1_save_is_refused_without_byte_changes() -> void:
	_start()
	var payload := Game.serialize()
	payload["content_version"] = 1
	var written := SaveSystem.write_save(SLOT, payload, ASHWICK)
	assert_true(bool(written.get("ok", false)), String(written.get("message", "")))
	var path := SaveSystem.path_for(SLOT, ASHWICK)
	var before := FileAccess.get_file_as_string(path)
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_true(String(loaded.get("message", "")).contains("content version"))
	assert_eq(FileAccess.get_file_as_string(path), before, "the v1 save bytes are preserved")
	assert_eq(Game.position, Vector2i(4, 7), "the live session is unchanged")
