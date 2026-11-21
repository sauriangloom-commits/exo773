extends GutTest

## Dialogue branching, quests, content validation, saves and graceful failure.

var content: ContentDB


func before_each() -> void:
	content = Game.content
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 777)


func after_each() -> void:
	for slot in ["slot1", "slot2"]:
		SaveSystem.delete_save_everywhere(slot)


func _find_choice(choices: Array, needle: String) -> int:
	for i in choices.size():
		if String(choices[i]["text"]).contains(needle):
			return i
	return -1


func _party_item_total(item_id: String) -> int:
	var total := 0
	for ch in Game.party:
		total += ch.inventory_count(item_id)
	return total


func test_content_loads_without_validation_errors() -> void:
	assert_eq(content.errors.size(), 0, "\n".join(content.errors))
	assert_gt(content.items.size(), 0)
	assert_gt(content.characters.size(), 0)
	assert_gt(content.dialogues.size(), 0)
	assert_false(content.get_dialogue("miruna").is_empty())


func test_missing_dialogue_fails_gracefully() -> void:
	var result := Game.start_dialogue("does_not_exist")
	assert_false(bool(result["ok"]))
	assert_eq(Game.mode, "explore", "failed dialogue must not trap the game")


func test_dialogue_accept_updates_quest_flags_and_inventory() -> void:
	var before := _party_item_total("potion_of_cure_light_wounds")
	var result := Game.start_dialogue("miruna")
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	assert_eq(Game.mode, "dialogue")
	var choices := Game.dialogue_choices()
	var index := _find_choice(choices, "find the clapper")
	assert_gte(index, 0, "the quest-accept choice should be listed")
	Game.dialogue_choose(index)
	assert_true(bool(Game.flags.get("met_miruna", false)))
	assert_eq(Game.quests.status("drowned_bell"), "active")
	assert_eq(_party_item_total("potion_of_cure_light_wounds"), before + 1)
	# The accept node has one exit choice; take it.
	var exits := Game.dialogue_choices()
	var exit_index := _find_choice(exits, "Stay here")
	assert_gte(exit_index, 0)
	Game.dialogue_choose(exit_index)
	assert_eq(Game.mode, "explore")


func test_dialogue_conditions_hide_repeatable_accept() -> void:
	Game.start_dialogue("miruna")
	var choices := Game.dialogue_choices()
	var index := _find_choice(choices, "find the clapper")
	Game.dialogue_choose(index)
	Game.dialogue_choose(_find_choice(Game.dialogue_choices(), "Stay here"))
	Game.start_dialogue("miruna")
	var again := Game.dialogue_choices()
	var gated := _find_choice(again, "find the clapper")
	assert_gte(gated, 0, "the option stays visible so its gating is explained")
	assert_false(bool(again[gated]["available"]), "met_miruna gates the accept option")


func test_skill_check_choice_resolves_with_an_actor() -> void:
	Game.start_dialogue("miruna")
	var choices := Game.dialogue_choices()
	var index := _find_choice(choices, "Sense Motive")
	assert_gte(index, 0)
	var result := Game.dialogue_choose(index)
	assert_true(bool(result["ok"]), String(result.get("message", "")))
	var check: Dictionary = result.get("check", {})
	assert_eq(String(check.get("skill", "")), "sense_motive")
	assert_true(result.has("messages"))


func test_corvin_attack_starts_encounter() -> void:
	Game.start_dialogue("corvin")
	var choices := Game.dialogue_choices()
	var index := _find_choice(choices, "Destroy it")
	assert_gte(index, 0)
	Game.dialogue_choose(index)
	assert_eq(Game.mode, "combat")
	assert_not_null(Game.encounter)
	assert_eq(Game.active_encounter_id, "crypt_warden")
	assert_eq(Game.encounter.enemies().size(), 2)


func test_quest_completes_when_all_flags_set() -> void:
	Game.flags["met_miruna"] = true
	Game.flags["found_clapper"] = true
	Game.flags["warden_resolved"] = true
	Game.flags["bell_rung"] = true
	Game.apply_effects([], "test")
	assert_true(Game.quests.is_complete("drowned_bell"))
	assert_true(Game.victory_pending)


func test_save_load_round_trip_preserves_world_state() -> void:
	Game.party[0].hp -= 7
	Game.party[1].add_to_inventory(content.get_item("bell_clapper"), 1)
	Game.flags["unit_test_flag"] = true
	Game.gold = 42
	Game.dungeon.set_door_open("crypt_door", true)
	Game.position = Vector2i(3, 9)
	Game.facing = Dungeon.EAST
	var expected_hp: int = Game.party[0].hp
	var expected_state: String = str(Game.rng.state)
	var saved := Game.save_game("slot1")
	assert_true(bool(saved["ok"]), String(saved.get("message", "")))
	Game.new_game(["kaelen"], 1)
	assert_eq(Game.party.size(), 1)
	var loaded := Game.load_game("slot1")
	assert_true(bool(loaded["ok"]), String(loaded.get("message", "")))
	assert_eq(Game.party.size(), 4)
	assert_eq(Game.party[0].hp, expected_hp)
	assert_true(bool(Game.flags.get("unit_test_flag", false)))
	assert_eq(Game.gold, 42)
	assert_true(bool(Game.dungeon.open_doors.get("crypt_door", false)))
	assert_eq(Game.position, Vector2i(3, 9))
	assert_eq(Game.facing, Dungeon.EAST)
	assert_eq(Game.party[1].inventory_count("bell_clapper"), 1)
	assert_eq(str(Game.rng.state), expected_state, "RNG state resumes exactly")


func test_saving_is_refused_during_combat() -> void:
	Game.start_encounter("storeroom_dead")
	assert_eq(Game.mode, "combat")
	var result := Game.save_game("slot1")
	assert_false(bool(result["ok"]))
	assert_true(String(result["message"]).contains("exploring"))


func test_invalid_content_is_reported() -> void:
	var before := content.errors.size()
	content.dialogues["broken"] = {
		"id": "broken",
		"start": "missing",
		"nodes": {"a": {"text": "Hello", "next": "nowhere"}},
	}
	content.validate()
	assert_gt(content.errors.size(), before, "validation must flag a broken dialogue")
	content.dialogues.erase("broken")
	content.errors.resize(before)


func test_missing_audio_asset_does_not_crash() -> void:
	Sfx.play("definitely_not_a_sound")
	Sfx.play_music("also_missing")
	assert_true(true, "missing placeholder audio is silently ignored")


func test_party_configuration_is_validated() -> void:
	var result := Game.new_game(["kaelen", "nobody"], 5)
	assert_false(bool(result["ok"]))
	var too_many := Game.new_game(["kaelen", "sera", "aldric", "ysolde", "mira"], 5)
	assert_false(bool(too_many["ok"]))
