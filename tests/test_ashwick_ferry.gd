extends GutTest

## The Ashwick Ferry: original content regression coverage.
##
## These tests use the ordinary GameSession/content APIs and real content. They
## are a backend/focused probe, not the ordinary input acceptance run. No test
## writes a flag, adds an item or edits HP to manufacture a result.

const ASHWICK := "ashwick_ferry"
const SLOT := "ashwick_qa"

func before_each() -> void:
	Game.playtest_mode = false
	SaveSystem.delete_save(SLOT)
	SaveSystem.delete_save("auto")
	var loaded := Game.load_campaign(ASHWICK)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))


func after_each() -> void:
	SaveSystem.delete_save(SLOT)
	SaveSystem.delete_save("auto")
	Game.playtest_mode = false


func _start(seed := 4242) -> void:
	var started := Game.new_game(["kaelen", "sera", "aldric", "ysolde"], seed)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))


func _find_choice(needle: String) -> int:
	for i in Game.dialogue_choices().size():
		if String(Dictionary(Game.dialogue_choices()[i]).get("text", "")).contains(needle):
			return i
	return -1


func _leave_dialogue() -> void:
	if Game.mode != "dialogue":
		return
	var index := _find_choice("Not yet")
	if index < 0:
		index = _find_choice("return")
	if index >= 0:
		Game.dialogue_choose(index)
	elif Game.dialogue != null:
		Game.dialogue.finish_now()


func _talk_to_maela_and_check(seed: int) -> Dictionary:
	_start(seed)
	var key_before := _party_item_count("ashwick_tack_room_key")
	var potion_before := _party_item_count("potion_of_cure_light_wounds")
	var started := Game.start_dialogue("maela_vey")
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))
	var index := _find_choice("Sense Motive")
	assert_gte(index, 0, "the Sense Motive branch is offered")
	var result := Game.dialogue_choose(index)
	return {
		"trust": bool(Game.flags.get("maela_trust", false)),
		"refused": bool(Game.flags.get("maela_refused", false)),
		"key": _party_item_count("ashwick_tack_room_key") - key_before,
		"potion": _party_item_count("potion_of_cure_light_wounds") - potion_before,
		"result": result,
	}


func _seed_for_maela(want_trust: bool) -> int:
	for seed in range(1, 1000):
		var outcome := _talk_to_maela_and_check(seed)
		if bool(outcome["trust"]) == want_trust:
			return seed
	return -1


func _party_item_count(item_id: String) -> int:
	var count := 0
	for ch in Game.party:
		count += ch.inventory_count(item_id)
	return count


func _go(pos: Vector2i, facing: int) -> void:
	Game.position = pos
	Game.facing = facing


func _travel_boathouse() -> void:
	var result := Game.travel_to("ashwick_boathouse", Vector2i(4, 7), Dungeon.NORTH)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))


func _seed_for_failed_then_successful_ledger() -> int:
	for seed in range(1, 1000):
		_start(seed)
		_travel_boathouse()
		_go(Vector2i(4, 6), Dungeon.NORTH)
		var first := Game.interact()
		if bool(first.get("ok", false)):
			continue
		if Game.dungeon.is_removed("boathouse_ledger"):
			continue
		if bool(Game.flags.get("ledger_found", false)):
			continue
		var second := Game.interact()
		if bool(second.get("ok", false)) and bool(Game.flags.get("ledger_found", false)):
			return seed
	return -1


func _seed_for_failed_then_successful_spare() -> int:
	for seed in range(1, 1000):
		_start(seed)
		_travel_boathouse()
		_go(Vector2i(6, 6), Dungeon.NORTH)
		var first := Game.interact()
		if bool(first.get("ok", false)):
			continue
		if Game.dungeon.is_removed("spare_key_nail"):
			continue
		if _party_item_count("ashwick_tack_room_key") != 0:
			continue
		var second := Game.interact()
		if bool(second.get("ok", false)) and _party_item_count("ashwick_tack_room_key") == 1:
			return seed
	return -1


func _seed_for_open_lock_success() -> int:
	for seed in range(1, 1000):
		_start(seed)
		_travel_boathouse()
		_go(Vector2i(3, 4), Dungeon.NORTH)
		var result := Game.interact()
		if bool(result.get("ok", false)) and bool(Game.dungeon.open_doors.get("tack_room_door", false)):
			return seed
	return -1


func _open_door_with_key_or_spare() -> void:
	_go(Vector2i(3, 4), Dungeon.NORTH)
	var opened := Game.interact()
	assert_true(bool(opened.get("ok", false)), String(opened.get("message", "")))
	assert_true(bool(Game.dungeon.open_doors.get("tack_room_door", false)), "the tack-room door is open")


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
	assert_true(bool(Game.flags.get("drowned_cleared", false)), "victory set the combat flag")
	assert_true(bool(Game.flags.get("ivo_token_found", false)), "victory set the token flag")
	assert_eq(_party_item_count("ivo_token"), 1, "victory grants exactly one token")


func _reach_tack_room_via_spare() -> void:
	_travel_boathouse()
	_go(Vector2i(6, 6), Dungeon.NORTH)
	var found := Game.interact()
	assert_true(bool(found.get("ok", false)), String(found.get("message", "")))
	assert_eq(_party_item_count("ashwick_tack_room_key"), 1, "spare key obtained")
	_open_door_with_key_or_spare()
	_go(Vector2i(3, 3), Dungeon.NORTH)
	var entered := Game.move_forward()
	assert_true(bool(entered.get("ok", false)), String(entered.get("message", "")))
	assert_eq(Game.area_id, "ashwick_boathouse")
	assert_eq(Game.mode, "combat", "entering the tack room starts the real encounter")


func test_discovery_and_exact_objectives() -> void:
	assert_true(Game.campaigns.order.has(ASHWICK), "ordinary registry discovers Ashwick Ferry")
	assert_eq(Game.campaign_id, ASHWICK)
	_start(4242)
	assert_eq(Game.quests.status("ashwick_ferry"), "active")
	var definition: Dictionary = Game.content.get_quest("ashwick_ferry")
	assert_eq(Array(definition.get("objectives", [])).size(), 5)
	assert_eq(String(Dictionary(Array(definition["objectives"])[0]).get("flag", "")), "maela_spoken")
	assert_eq(String(Dictionary(Array(definition["objectives"])[4]).get("flag", "")), "maela_epilogue")
	assert_eq(Game.area_id, "ashwick_landing")
	assert_eq(Game.position, Vector2i(4, 7))


func test_maela_success_and_failure_are_distinct_and_do_not_softlock() -> void:
	var trust_seed := _seed_for_maela(true)
	var refuse_seed := _seed_for_maela(false)
	assert_gte(trust_seed, 0, "found a real Sense Motive success seed")
	assert_gte(refuse_seed, 0, "found a real Sense Motive failure seed")
	var success := _talk_to_maela_and_check(trust_seed)
	assert_true(bool(success["trust"]), "success sets maela_trust")
	assert_false(bool(success["refused"]), "success does not set maela_refused")
	assert_eq(int(success["key"]), 1, "success grants the tack-room key")
	assert_eq(int(success["potion"]), 1, "success grants one potion")
	var failure := _talk_to_maela_and_check(refuse_seed)
	assert_true(bool(failure["refused"]), "failure sets maela_refused")
	assert_false(bool(failure["trust"]), "failure does not set maela_trust")
	assert_eq(int(failure["key"]), 0, "failure withholds the tack-room key")
	assert_eq(int(failure["potion"]), 0, "failure withholds the potion")


func test_failed_ledger_search_keeps_the_clue_available() -> void:
	var seed := _seed_for_failed_then_successful_ledger()
	assert_gte(seed, 0, "found a real failed-then-successful Search seed")
	_start(seed)
	_travel_boathouse()
	_go(Vector2i(4, 6), Dungeon.NORTH)
	var failed := Game.interact()
	assert_false(bool(failed.get("ok", false)), "first Search fails")
	assert_false(bool(Game.flags.get("ledger_found", false)), "failure does not set the clue flag")
	assert_false(Game.dungeon.is_removed("boathouse_ledger"), "failure does not consume the ledger")
	var recovered := Game.interact()
	assert_true(bool(recovered.get("ok", false)), "second Search succeeds")
	assert_true(bool(Game.flags.get("ledger_found", false)), "recovery sets ledger_found")
	assert_true(Game.dungeon.is_removed("boathouse_ledger"), "success consumes the ledger object")


func test_failed_spare_key_search_keeps_the_fallback_available() -> void:
	var seed := _seed_for_failed_then_successful_spare()
	assert_gte(seed, 0, "found a real failed-then-successful spare-key Search seed")
	_start(seed)
	_travel_boathouse()
	_go(Vector2i(6, 6), Dungeon.NORTH)
	var failed := Game.interact()
	assert_false(bool(failed.get("ok", false)), "first spare-key Search fails")
	assert_eq(_party_item_count("ashwick_tack_room_key"), 0, "failure grants no spare key")
	assert_false(Game.dungeon.is_removed("spare_key_nail"), "failure does not consume the spare-key object")
	var recovered := Game.interact()
	assert_true(bool(recovered.get("ok", false)), "second spare-key Search succeeds")
	assert_eq(_party_item_count("ashwick_tack_room_key"), 1, "recovery grants the spare key")
	assert_true(Game.dungeon.is_removed("spare_key_nail"), "success consumes the spare-key object")


func test_npc_key_open_lock_and_spare_key_each_open_the_door() -> void:
	var trust_seed := _seed_for_maela(true)
	_start(trust_seed)
	_talk_to_maela_and_check(trust_seed)
	_leave_dialogue()
	assert_eq(_party_item_count("ashwick_tack_room_key"), 1)
	_travel_boathouse()
	_open_door_with_key_or_spare()

	var lock_seed := _seed_for_open_lock_success()
	assert_gte(lock_seed, 0, "found a real Open Lock success seed")
	_start(lock_seed)
	_travel_boathouse()
	_go(Vector2i(3, 4), Dungeon.NORTH)
	var locked := Game.interact()
	assert_true(bool(locked.get("ok", false)), "Open Lock success opens the door")
	assert_true(bool(Game.dungeon.open_doors.get("tack_room_door", false)))

	var spare_seed := _seed_for_failed_then_successful_spare()
	assert_gte(spare_seed, 0)
	_start(spare_seed)
	_travel_boathouse()
	_go(Vector2i(6, 6), Dungeon.NORTH)
	var first_spare := Game.interact()
	assert_false(bool(first_spare.get("ok", false)), "spare-key first attempt fails")
	var second_spare := Game.interact()
	assert_true(bool(second_spare.get("ok", false)), "spare key recovery succeeds")
	_open_door_with_key_or_spare()


func test_bell_cannot_finish_before_token_and_ledger() -> void:
	_start(4242)
	_go(Vector2i(3, 7), Dungeon.WEST)
	var early := Game.interact()
	assert_true(bool(early.get("ok", false)), "the bell can be inspected before it is ready")
	assert_false(bool(Game.flags.get("ferry_bell_rung", false)))
	assert_false(bool(Game.flags.get("bell_resolved", false)))
	assert_false(bool(Game.victory_pending), "early bell cannot end the campaign")
	var step := _choose_available("Step away")
	assert_gte(step, 0)
	Game.dialogue_choose(step)


func _ring_once() -> void:
	_go(Vector2i(3, 7), Dungeon.WEST)
	var started := Game.interact()
	assert_true(bool(started.get("ok", false)), "the bell dialogue starts")
	var index := _choose_available("Ring once")
	assert_gte(index, 0, "ring once is available after the account decision")
	Game.dialogue_choose(index)
	var step := _choose_available("Step away")
	assert_gte(step, 0)
	Game.dialogue_choose(step)
	assert_eq(Game.mode, "explore")


func _choose_available(needle: String) -> int:
	for i in Game.dialogue_choices().size():
		var entry: Dictionary = Game.dialogue_choices()[i]
		if String(entry.get("text", "")).contains(needle) and bool(entry.get("available", false)):
			return i
	return -1


func _open_account_decision() -> void:
	var index := _choose_available("what the ledger shows")
	assert_gte(index, 0, "the account decision is entered from a named option")
	Game.dialogue_choose(index)


func _commit_account(truth := true) -> void:
	var talked := Game.start_dialogue("maela_vey")
	assert_true(bool(talked.get("ok", false)), String(talked.get("message", "")))
	_open_account_decision()
	var needle := "ledger is Ivo" if truth else "passenger home"
	var index := _choose_available(needle)
	assert_gte(index, 0, "the chosen account option is available")
	var opened := Game.dialogue_choose(index)
	assert_true(bool(opened.get("ok", false)), String(opened.get("message", "")))
	assert_false(bool(Game.flags.get("maela_decision", false)), "reading a statement does not commit it")
	var commit := _choose_available("This commits")
	assert_gte(commit, 0, "the statement page offers an explicit commitment")
	var chosen := Game.dialogue_choose(commit)
	assert_true(bool(chosen.get("ok", false)), String(chosen.get("message", "")))
	assert_true(bool(Game.flags.get("maela_decision", false)), "the account decision is committed")
	assert_true(bool(Game.flags.get("maela_truth" if truth else "maela_mercy", false)))
	var chosen_quest := "maela_truth" if truth else "maela_mercy"
	var unchosen_quest := "maela_mercy" if truth else "maela_truth"
	assert_eq(Game.quests.status(chosen_quest), "active", "only the chosen side quest starts")
	assert_eq(Game.quests.status(unchosen_quest), "not_started")
	var exit_index := _choose_available("Let her")
	assert_gte(exit_index, 0)
	Game.dialogue_choose(exit_index)
	var leave_index := _choose_available("Not yet")
	assert_gte(leave_index, 0)
	Game.dialogue_choose(leave_index)
	assert_eq(Game.mode, "explore")


func _deliver_epilogue(truth := true) -> void:
	var talked := Game.start_dialogue("maela_vey")
	assert_true(bool(talked.get("ok", false)), String(talked.get("message", "")))
	var final_index := _choose_available("Tell me how the crossing ended")
	assert_gte(final_index, 0, "the final account option is unmistakable")
	var opened := Game.dialogue_choose(final_index)
	assert_true(bool(opened.get("ok", false)), String(opened.get("message", "")))
	var account_index := _choose_available(
		"What will you tell the village?" if truth else "Let her keep the story"
	)
	assert_gte(account_index, 0)
	var delivered := Game.dialogue_choose(account_index)
	assert_true(bool(delivered.get("ok", false)), String(delivered.get("message", "")))
	assert_true(bool(Game.flags.get("maela_epilogue", false)), "the epilogue is delivered")
	var leave_index := _choose_available("Leave her")
	assert_gte(leave_index, 0)
	Game.dialogue_choose(leave_index)


func test_actions_before_maela_count_and_full_route_persists() -> void:
	# The main quest is active from new game because the package contract requires
	# a start quest. This exercises the supported ordering: boathouse actions
	# happen before the player first speaks with Maela.
	_start(4242)
	_travel_boathouse()
	_go(Vector2i(4, 6), Dungeon.NORTH)
	var ledger := Game.interact()
	assert_true(bool(ledger.get("ok", false)), "ledger search succeeds")
	assert_true(bool(Game.flags.get("ledger_found", false)))
	assert_true(Game.quests.objective_done("ashwick_ferry", "find_ledger"))
	_go(Vector2i(6, 6), Dungeon.NORTH)
	assert_true(bool(Game.interact().get("ok", false)), "spare key search succeeds")
	_open_door_with_key_or_spare()
	_go(Vector2i(3, 3), Dungeon.NORTH)
	assert_true(bool(Game.move_forward().get("ok", false)), "entering the tack room starts combat")
	_finish_encounter()
	assert_true(Game.quests.objective_done("ashwick_ferry", "clear_tack_room"))
	assert_true(Game.quests.objective_done("ashwick_ferry", "recover_token"))
	assert_eq(Game.quests.status("ashwick_ferry"), "active", "three objectives are done before Maela")
	assert_false(Game.quests.objective_done("ashwick_ferry", "speak_maela"))
	assert_false(Game.quests.objective_done("ashwick_ferry", "hear_epilogue"))
	_travel_boathouse_return()
	_commit_account(true)
	assert_true(Game.quests.objective_done("ashwick_ferry", "speak_maela"))
	assert_eq(Game.quests.status("ashwick_ferry"), "active", "four objectives are done before the bell")
	assert_false(Game.quests.objective_done("ashwick_ferry", "hear_epilogue"))
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.area_id, "ashwick_landing")
	assert_true(bool(Game.flags.get("maela_spoken", false)))
	assert_true(bool(Game.flags.get("drowned_cleared", false)))
	assert_true(bool(Game.flags.get("ledger_found", false)))
	assert_true(bool(Game.flags.get("maela_decision", false)))
	assert_true(bool(Game.flags.get("maela_truth", false)))
	assert_eq(Game.quests.status("maela_truth"), "active", "chosen account survives reload")
	assert_eq(Game.quests.status("maela_mercy"), "not_started")
	assert_true(bool(Game.flags.get("trigger_tack_room_drowned", false)))
	assert_eq(_party_item_count("ivo_token"), 1)
	assert_true(Game.quests.objective_done("ashwick_ferry", "recover_token"))
	assert_eq(Game.quests.status("ashwick_ferry"), "active")
	_travel_boathouse()
	assert_true(Game.dungeon.open_doors.get("tack_room_door", false), "door state survives reload")
	assert_true(Game.dungeon.is_removed("boathouse_ledger"), "ledger removal survives reload")
	assert_true(Game.dungeon.is_removed("spare_key_nail"), "spare-key removal survives reload")
	_travel_boathouse_return()
	_ring_once()
	assert_true(bool(Game.flags.get("ferry_bell_rung", false)))
	assert_true(bool(Game.flags.get("bell_resolved", false)))
	assert_true(bool(Game.flags.get("ivo_rested", false)))
	assert_eq(_party_item_count("ivo_token"), 0, "ring once consumes the token")
	assert_eq(Game.quests.status("ashwick_ferry"), "active", "victory waits for Maela's account")
	assert_false(Game.victory_pending)
	_deliver_epilogue(true)
	assert_eq(Game.quests.status("ashwick_ferry"), "complete")
	assert_eq(Game.quests.status("maela_truth"), "complete")
	assert_true(Game.victory_pending, "completion raises victory once")
	Game.take_victory_pending()
	assert_true(bool(Game.save_game(SLOT).get("ok", false)), "save after victory")
	var reloaded := Game.load_game(SLOT)
	assert_true(bool(reloaded.get("ok", false)), String(reloaded.get("message", "")))
	assert_true(Game.quests.is_complete("ashwick_ferry"))
	assert_false(Game.victory_pending, "victory is not pending again after reload")
	assert_true(bool(Game.flags.get("victory_shown", false)))
	assert_eq(_party_item_count("ivo_token"), 0, "token stays consumed after reload")
	_go(Vector2i(3, 7), Dungeon.WEST)
	var again := Game.interact()
	assert_true(bool(again.get("ok", false)), "a completed bell falls back to inspection")
	assert_false(Game.victory_pending, "inspection does not raise victory again")
	assert_eq(Game.quests.status("ashwick_ferry"), "complete")
	assert_false(bool(Game.flags.get("bell_silenced", false)), "inspection does not choose another ending")


func _travel_boathouse_return() -> void:
	var result := Game.travel_to("ashwick_landing", Vector2i(4, 7), Dungeon.NORTH)
	assert_true(bool(result.get("ok", false)), String(result.get("message", "")))

func _reach_the_ledger() -> void:
	_start(4242)
	_travel_boathouse()
	_go(Vector2i(4, 6), Dungeon.NORTH)
	var read_ledger := Game.interact()
	assert_true(bool(read_ledger.get("ok", false)), String(read_ledger.get("message", "")))
	assert_true(bool(Game.flags.get("ledger_found", false)), "the ledger was read on the ordinary Search")


func test_account_decision_is_deliberate_and_cancellable() -> void:
	_reach_the_ledger()
	var started := Game.start_dialogue("maela_vey")
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))
	assert_eq(_choose_available("ledger is Ivo"), -1, "the truth statement is not a general conversation row")
	assert_eq(_choose_available("passenger home"), -1, "the mercy statement is not a general conversation row")
	_open_account_decision()
	assert_eq(String(Game.dialogue.node_id), "account_decision", "the entry opens the dedicated decision")
	assert_false(bool(Game.flags.get("maela_decision", false)), "opening the decision commits no account")
	assert_false(bool(Game.flags.get("maela_truth", false)))
	assert_false(bool(Game.flags.get("maela_mercy", false)))
	assert_eq(Game.quests.status("maela_truth"), "not_started", "no account quest starts on entry")
	assert_eq(Game.quests.status("maela_mercy"), "not_started")
	assert_gte(_choose_available("ledger is Ivo"), 0, "the truthful account is offered")
	assert_gte(_choose_available("passenger home"), 0, "the fabricated account is offered")
	assert_eq(
		_choose_available("Show her the last page"),
		-1,
		"the evidence-aware account is gated until the last page is found",
	)
	var cancel := _choose_available("say nothing about the ledger")
	assert_gte(cancel, 0, "a noncommitting way back is offered")
	Game.dialogue_choose(cancel)
	assert_eq(String(Game.dialogue.node_id), "root", "cancelling returns to the conversation")
	assert_false(bool(Game.flags.get("maela_decision", false)), "cancelling commits no account")
	assert_gte(_choose_available("what the ledger shows"), 0, "the entry is offered again after cancelling")


func test_account_statement_commits_only_on_the_explicit_choice() -> void:
	_reach_the_ledger()
	Game.start_dialogue("maela_vey")
	_open_account_decision()
	Game.dialogue_choose(_choose_available("ledger is Ivo"))
	assert_eq(String(Game.dialogue.node_id), "account_truth_confirm", "the truth opens its own statement page")
	assert_false(bool(Game.flags.get("maela_decision", false)), "the statement page alone commits nothing")
	assert_eq(Game.quests.status("maela_truth"), "not_started")
	var back := _choose_available("step back")
	assert_gte(back, 0, "the statement page can be left without committing")
	Game.dialogue_choose(back)
	assert_eq(String(Game.dialogue.node_id), "account_decision", "stepping back returns to the choice")
	assert_false(bool(Game.flags.get("maela_decision", false)))
	Game.dialogue_choose(_choose_available("ledger is Ivo"))
	Game.dialogue_choose(_choose_available("This commits"))
	assert_eq(String(Game.dialogue.node_id), "truth_account")
	assert_true(bool(Game.flags.get("maela_decision", false)), "the explicit choice commits the account")
	assert_true(bool(Game.flags.get("maela_truth", false)))
	assert_false(bool(Game.flags.get("maela_mercy", false)))
	assert_eq(Game.quests.status("maela_truth"), "active")
	assert_eq(Game.quests.status("maela_mercy"), "not_started")
	Game.dialogue_choose(_choose_available("Let her have the rest"))
	assert_eq(String(Game.dialogue.node_id), "root")
	assert_eq(_choose_available("what the ledger shows"), -1, "the account entry is gone once committed")
	assert_eq(_choose_available("ledger is Ivo"), -1)
	assert_eq(_choose_available("passenger home"), -1, "the other account cannot be chosen afterwards")


func test_mercy_account_commits_mutually_exclusively() -> void:
	_reach_the_ledger()
	Game.start_dialogue("maela_vey")
	_open_account_decision()
	Game.dialogue_choose(_choose_available("passenger home"))
	assert_eq(String(Game.dialogue.node_id), "account_mercy_confirm")
	assert_false(bool(Game.flags.get("maela_decision", false)), "the fabricated statement alone commits nothing")
	Game.dialogue_choose(_choose_available("This commits"))
	assert_true(bool(Game.flags.get("maela_mercy", false)), "the fabricated account is committed")
	assert_false(bool(Game.flags.get("maela_truth", false)), "the truthful account stays uncommitted")
	assert_eq(Game.quests.status("maela_mercy"), "active")
	assert_eq(Game.quests.status("maela_truth"), "not_started")
	Game.dialogue_choose(_choose_available("Let her keep it"))
	assert_eq(_choose_available("what the ledger shows"), -1, "the decision cannot be taken twice")

