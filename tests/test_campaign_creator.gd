extends GutTest

## User campaign creation, discovery, validation and playtest isolation.
##
## These exercise the same CampaignStore and loader the creator screen and the
## probe use, without depending on window layout.

const CREATOR_ID := "test_creator_alpha"
const OTHER_ID := "test_creator_beta"


func before_each() -> void:
	_cleanup()
	Game.load_campaign("ravenloft_demo")


func after_each() -> void:
	_cleanup()
	Game.playtest_mode = false
	Game.load_campaign("ravenloft_demo")


func _cleanup() -> void:
	for id in [CREATOR_ID, OTHER_ID, "probe_campaign"]:
		CampaignStore.delete_user_campaign(String(id))
		SaveSystem.delete_save_everywhere("slot1")
	Game.refresh_campaigns()


func _create(id := CREATOR_ID) -> Dictionary:
	return CampaignStore.create("Test Campaign", id)


func test_create_campaign_is_discovered_and_reopens() -> void:
	var created := _create()
	assert_true(bool(created.get("ok", false)), String(created.get("message", "")))
	assert_true(FileAccess.file_exists(CampaignStore.package_dir(CREATOR_ID).path_join("campaign.json")))
	Game.refresh_campaigns()
	assert_true(Game.campaigns.has(CREATOR_ID), "user campaign is discovered by scanning")
	assert_eq(String(Game.campaigns.get_campaign(CREATOR_ID).get("source", "")), "user")
	assert_true(bool(Game.campaigns.get_campaign(CREATOR_ID).get("writable", false)))
	var loaded := CampaignStore.load_package(CREATOR_ID)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	var draft: Dictionary = Dictionary(loaded.get("draft", {}))
	assert_eq(Array(draft.get("areas", [])).size(), 1)
	CampaignStore.add_area(draft, "Second Area")
	var link := CampaignStore.add_transition(draft, "area_01", Vector2i(4, 4), "area_02")
	assert_true(bool(link.get("ok", false)), String(link.get("message", "")))
	assert_true(bool(CampaignStore.set_entry(draft, "area_01", Vector2i(4, 5), 2).get("ok", false)))
	var saved := CampaignStore.write_package(draft)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var reopened: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	assert_eq(Array(reopened.get("areas", [])).size(), 2, "added area survives save and reopen")
	var entry: Dictionary = reopened.get("entry", {})
	assert_eq(int(entry.get("facing", -1)), 2)
	assert_eq(Vector2i(int(Array(entry.get("pos", [0, 0]))[0]), int(Array(entry.get("pos", [0, 0]))[1])), Vector2i(4, 5))


func test_invalid_ids_and_paths_are_rejected() -> void:
	for bad_id in ["", "A", "Bad Id", "../escape", "a/b", ".hidden", "1abc", "ravenloft_demo"]:
		var result := CampaignStore.create("Title", String(bad_id))
		assert_false(bool(result.get("ok", false)), "id '%s' must be rejected" % bad_id)
	assert_true(CampaignStore.is_valid_id("valid_campaign_1"))
	assert_false(CampaignStore.is_valid_id("bad/../id"))


func test_duplicate_user_id_is_rejected_without_overwrite() -> void:
	var first := _create()
	assert_true(bool(first.get("ok", false)))
	var path := CampaignStore.package_dir(CREATOR_ID).path_join("campaign.json")
	var before := FileAccess.get_file_as_string(path)
	var second := _create()
	assert_false(bool(second.get("ok", false)))
	assert_true(String(second.get("message", "")).contains("already exists"))
	assert_eq(FileAccess.get_file_as_string(path), before)


func test_bundled_campaigns_are_read_only() -> void:
	var bundled_path := "res://content/campaigns/ravenloft_demo/campaign.json"
	var before := FileAccess.get_file_as_string(bundled_path)
	var draft := CampaignStore.make_draft("Hijacked", "ravenloft_demo")
	var written := CampaignStore.write_package(draft)
	assert_false(bool(written.get("ok", false)))
	assert_true(String(written.get("message", "")).contains("bundled"))
	assert_eq(FileAccess.get_file_as_string(bundled_path), before, "bundled manifest is untouched")
	assert_false(bool(CampaignStore.load_package("ravenloft_demo").get("ok", false)))
	assert_false(DirAccess.dir_exists_absolute(CampaignStore.package_dir("ravenloft_demo")))


func test_map_entry_and_transition_validation() -> void:
	assert_true(bool(_create().get("ok", false)))
	var draft: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	# Entry in a wall.
	draft["entry"] = {"area": "area_01", "pos": [0, 0], "facing": 0}
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "not walkable"))
	# Uneven row.
	draft = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	var area: Dictionary = Dictionary(Array(draft["areas"])[0])
	var rows: Array = Array(area["rows"])
	rows[4] = "...."
	area["rows"] = rows
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "cells wide"))
	# Duplicate area ids.
	draft = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	var areas: Array = Array(draft["areas"])
	areas.append(Dictionary(Array(draft["areas"])[0]).duplicate(true))
	draft["areas"] = areas
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "Duplicate area id"))
	# Transition to a missing area is refused by the editor helper.
	draft = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	assert_false(bool(CampaignStore.add_transition(draft, "area_01", Vector2i(4, 4), "missing_area").get("ok", false)))
	# A wall cannot host a passage.
	assert_false(bool(CampaignStore.add_transition(draft, "area_01", Vector2i(0, 0), "area_01").get("ok", false)))


func test_local_instances_are_allowed_but_cannot_shadow_shared() -> void:
	assert_true(bool(_create().get("ok", false)))
	var dir := CampaignStore.package_dir(CREATOR_ID)
	var shared_monsters = JSON.parse_string(FileAccess.get_file_as_string("res://content/shared/monsters.json"))
	var variant: Dictionary = Dictionary(Dictionary(shared_monsters)["zombie"]).duplicate(true)
	variant["id"] = "lantern_drowned"
	variant["name"] = "Lantern-Drowned"
	_write_json(dir.path_join("monsters.json"), {"lantern_drowned": variant})
	var shared_characters = JSON.parse_string(FileAccess.get_file_as_string("res://content/shared/characters.json"))
	var npc: Dictionary = Dictionary(Dictionary(shared_characters)["kaelen"]).duplicate(true)
	npc["id"] = "keeper_npc"
	npc["name"] = "Keeper NPC"
	npc["playable"] = false
	_write_json(dir.path_join("characters.json"), {"keeper_npc": npc})
	_write_json(dir.path_join("items.json"), {
		"lantern_charm": {"id": "lantern_charm", "name": "Lantern Charm", "kind": "gear", "description": "(USER) A unique charm."}
	})
	var loaded := Game.load_campaign(CREATOR_ID)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_true(Game.content.is_local_instance("monster", "lantern_drowned"))
	assert_true(Game.content.is_local_instance("item", "lantern_charm"))
	assert_true(Game.content.is_local_instance("character", "keeper_npc"))
	assert_false(Game.content.playable_character_ids().has("keeper_npc"), "NPC instances are not party options")
	assert_true(Game.content.playable_character_ids().has("kaelen"), "shared pregens remain playable")
	# A local instance may not replace a shared id.
	_write_json(dir.path_join("items.json"), {
		"bell_clapper": {"id": "bell_clapper", "name": "Fake Clapper", "kind": "quest"}
	})
	var invalid := Game.load_campaign(CREATOR_ID)
	assert_false(bool(invalid.get("ok", false)))
	assert_true(_has_error(Array(invalid.get("errors", [])), "may not redefine shared item"))


func test_playtest_cannot_write_or_overwrite_campaign_saves() -> void:
	assert_true(bool(_create().get("ok", false)))
	Game.refresh_campaigns()
	assert_true(bool(Game.load_campaign(CREATOR_ID).get("ok", false)))
	Game.new_game([], 21)
	var ordinary := Game.save_game("slot1")
	assert_true(bool(ordinary.get("ok", false)), String(ordinary.get("message", "")))
	var path := SaveSystem.path_for("slot1", CREATOR_ID)
	var before := FileAccess.get_file_as_string(path)
	Game.playtest_mode = true
	Game.new_game([], 22)
	Game.flags["playtest_only"] = true
	var blocked := Game.save_game("slot1")
	assert_false(bool(blocked.get("ok", false)))
	assert_true(String(blocked.get("message", "")).contains("playtest"))
	assert_eq(FileAccess.get_file_as_string(path), before, "ordinary save is untouched")
	Game.abandon_playtest()
	assert_false(Game.playtest_mode)
	assert_eq(Game.mode, "menu")


func test_authoring_files_stay_unchanged_during_playtest() -> void:
	assert_true(bool(_create().get("ok", false)))
	Game.refresh_campaigns()
	assert_true(bool(Game.load_campaign(CREATOR_ID).get("ok", false)))
	var path := CampaignStore.package_dir(CREATOR_ID).path_join("areas").path_join("area_01.json")
	var before := FileAccess.get_file_as_string(path)
	Game.playtest_mode = true
	Game.new_game([], 33)
	Game.move_forward()
	Game.flags["draft_probe"] = true
	Game.abandon_playtest()
	assert_eq(FileAccess.get_file_as_string(path), before, "playtest never rewrites the authored draft")
	var draft: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	assert_eq(Array(draft.get("areas", [])).size(), 1)


func test_existing_bundled_campaigns_still_play_and_save() -> void:
	Game.load_campaign("hollow_lantern")
	var started := Game.new_game([], 44)
	assert_true(bool(started.get("ok", false)))
	assert_eq(Game.area_id, "lantern_yard")
	var saved := Game.save_game("slot1")
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	Game.new_game([], 45)
	assert_true(bool(Game.load_game("slot1").get("ok", false)))
	assert_eq(Game.campaign_id, "hollow_lantern")


func _new_draft() -> Dictionary:
	assert_true(bool(_create().get("ok", false)))
	return Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))


## Authors the same conversation shape the creator builds: an introduction, a
## loop back to it, a Search check with guarded retry, a success flag, and a
## later response that only appears once that flag is set.
func _build_story(draft: Dictionary, talk_id := "keeper_talk") -> void:
	var created := CampaignStore.add_dialogue(draft, talk_id, "The Keeper")
	assert_true(bool(created.get("ok", false)), String(created.get("message", "")))
	for node_name in ["lore", "success", "failure", "recall"]:
		var added := CampaignStore.add_dialogue_node(draft, talk_id)
		assert_true(bool(added.get("ok", false)), String(added.get("message", "")))
		var renamed := CampaignStore.rename_dialogue_node(draft, talk_id, String(added.get("id", "")), node_name)
		assert_true(bool(renamed.get("ok", false)), String(renamed.get("message", "")))
	assert_true(bool(CampaignStore.set_dialogue_node(
		draft, talk_id, "lore", "The keeper remembers every watch.", "The Keeper", "start", "", ""
	).get("ok", false)))
	assert_true(bool(CampaignStore.set_dialogue_node(
		draft, talk_id, "success", "You find the keeper's ledger.", "The Keeper", "start",
		"The ledger names the last three keepers.", "watcher_studied"
	).get("ok", false)))
	assert_true(bool(CampaignStore.set_dialogue_node(
		draft, talk_id, "failure", "The keeper closes the ledger before you can read it.", "The Keeper", "start", "", ""
	).get("ok", false)))
	assert_true(bool(CampaignStore.set_dialogue_node(
		draft, talk_id, "recall", "You ask about the names in the ledger.", "The Keeper", "", "", ""
	).get("ok", false)))
	assert_true(bool(CampaignStore.set_dialogue_node(
		draft, talk_id, "start", "The keeper watches the lamp, not you.", "The Keeper", "", "", ""
	).get("ok", false)))
	var choices := [
		{"text": "Ask about the watch.", "next": "lore"},
		{
			"text": "Search the counter. [Search DC 12]",
			"check": {"skill": "search", "dc": 12, "actor": "kaelen", "success": "success", "failure": "failure"},
			"guard_flag": "watcher_studied",
		},
		{"text": "Ask what you found.", "next": "recall", "require_flag": "watcher_studied"},
		{"text": "Leave.", "next": ""},
	]
	for i in choices.size():
		var added_choice := CampaignStore.add_dialogue_choice(draft, talk_id, "start")
		assert_true(bool(added_choice.get("ok", false)), String(added_choice.get("message", "")))
		var fields: Dictionary = Dictionary(choices[i]).duplicate(true)
		fields["guard_flag"] = String(fields.get("guard_flag", ""))
		fields["require_flag"] = String(fields.get("require_flag", ""))
		fields["effect_flag"] = ""
		var updated := CampaignStore.update_dialogue_choice(draft, talk_id, "start", i, fields)
		assert_true(bool(updated.get("ok", false)), String(updated.get("message", "")))
	var placed := CampaignStore.place_npc(
		draft, "area_01", Vector2i(4, 3), "keeper_npc", "The Keeper",
		"(USER CAMPAIGN) A keeper waits beside a cold lamp.", talk_id
	)
	assert_true(bool(placed.get("ok", false)), String(placed.get("message", "")))


func _authored_campaign() -> Dictionary:
	var draft := _new_draft()
	_build_story(draft)
	var saved := CampaignStore.write_package(draft)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	return draft


func test_npc_placement_validity_duplicates_move_and_remove() -> void:
	var draft := _new_draft()
	_build_story(draft)
	assert_false(bool(CampaignStore.place_npc(
		draft, "area_01", Vector2i(0, 0), "npc_02", "Wall", "", "keeper_talk"
	).get("ok", false)), "a wall cell is refused")
	assert_false(bool(CampaignStore.place_npc(
		draft, "area_01", Vector2i(4, 4), "npc_02", "Entry", "", "keeper_talk"
	).get("ok", false)), "the entry cell is refused")
	assert_false(bool(CampaignStore.place_npc(
		draft, "area_01", Vector2i(3, 3), "keeper_npc", "Duplicate", "", "keeper_talk"
	).get("ok", false)), "a duplicate campaign NPC id is refused")
	assert_false(bool(CampaignStore.place_npc(
		draft, "area_01", Vector2i(4, 3), "npc_02", "Overlap", "", "keeper_talk"
	).get("ok", false)), "an occupied cell is refused")
	assert_false(bool(CampaignStore.place_npc(
		draft, "area_01", Vector2i(3, 3), "npc_02", "Missing", "", "no_such_dialogue"
	).get("ok", false)), "a missing dialogue reference is refused")
	assert_true(bool(CampaignStore.move_npc(draft, "area_01", "keeper_npc", Vector2i(3, 3)).get("ok", false)))
	var moved := CampaignStore.find_npc(draft, "area_01", "keeper_npc")
	assert_eq(Array(moved.get("pos", [])), [3, 3])
	assert_false(bool(CampaignStore.move_npc(draft, "area_01", "keeper_npc", Vector2i(4, 4)).get("ok", false)), "cannot move onto the entry")
	var removed := CampaignStore.remove_npc(draft, "area_01", "keeper_npc")
	assert_true(bool(removed.get("ok", false)))
	assert_true(String(removed.get("message", "")).contains("dialogue 'keeper_talk' was kept"))
	assert_true(CampaignStore.dialogues_of(draft).has("keeper_talk"), "removing the placement keeps the conversation")


func test_dialogue_links_start_and_unreachable_nodes() -> void:
	var draft := _new_draft()
	var created := CampaignStore.add_dialogue(draft, "talk", "Speaker")
	assert_true(bool(created.get("ok", false)))
	var added := CampaignStore.add_dialogue_node(draft, "talk")
	var second_id := String(added.get("id", ""))
	assert_true(bool(CampaignStore.rename_dialogue_node(draft, "talk", second_id, "second").get("ok", false)))
	assert_true(bool(CampaignStore.set_dialogue_node(
		draft, "talk", "second", "Second line.", "Speaker", "start", "", ""
	).get("ok", false)))
	assert_true(bool(CampaignStore.set_dialogue_start(draft, "talk", "second").get("ok", false)))
	var errors := CampaignStore.validate_draft_shape(draft)
	assert_false(_has_error(errors, "unreachable"), "a loop back to the start is legal: %s" % [errors])
	var orphan := CampaignStore.add_dialogue_node(draft, "talk")
	var orphan_id := String(orphan.get("id", ""))
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "unreachable node(s): " + orphan_id))
	# Deleting the start while another node links to it must be refused, not silently broken.
	var refused := CampaignStore.delete_dialogue_node(draft, "talk", "start")
	assert_false(bool(refused.get("ok", false)))
	assert_true(String(refused.get("message", "")).contains("still referenced"))
	var renamed := CampaignStore.rename_dialogue_node(draft, "talk", "start", "root")
	assert_true(bool(renamed.get("ok", false)), String(renamed.get("message", "")))
	assert_eq(String(CampaignStore.dialogue_by_id(draft, "talk").get("start", "")), "second")
	var second: Dictionary = Dictionary(Dictionary(CampaignStore.dialogue_by_id(draft, "talk").get("nodes", {}))["second"])
	assert_eq(String(second.get("next", "")), "root", "rename updates inbound links")
	assert_true(bool(CampaignStore.delete_dialogue_node(draft, "talk", orphan_id).get("ok", false)))


func test_dialogue_rename_and_delete_refuse_live_references() -> void:
	var draft := _new_draft()
	_build_story(draft)
	var refused := CampaignStore.delete_dialogue(draft, "keeper_talk")
	assert_false(bool(refused.get("ok", false)))
	assert_true(String(refused.get("message", "")).contains("keeper_npc"), "refusal names the NPC")
	var renamed := CampaignStore.rename_dialogue(draft, "keeper_talk", "keeper_conversation")
	assert_true(bool(renamed.get("ok", false)), String(renamed.get("message", "")))
	var npc := CampaignStore.find_npc(draft, "area_01", "keeper_npc")
	assert_eq(String(npc.get("dialogue", "")), "keeper_conversation", "rename updates the NPC reference")
	assert_true(CampaignStore.dialogues_of(draft).has("keeper_conversation"))
	assert_false(CampaignStore.dialogues_of(draft).has("keeper_talk"))
	assert_true(bool(CampaignStore.remove_npc(draft, "area_01", "keeper_npc").get("ok", false)))
	assert_true(bool(CampaignStore.delete_dialogue(draft, "keeper_conversation").get("ok", false)))


func test_check_effect_and_condition_palette_validation() -> void:
	var draft := _new_draft()
	_build_story(draft)
	var bad_skill := CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", 1, {
		"text": "Bad.", "check": {"skill": "not_a_skill", "dc": 12, "actor": "kaelen", "success": "success", "failure": "failure"}
	})
	assert_false(bool(bad_skill.get("ok", false)))
	var bad_dc := CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", 1, {
		"text": "Bad.", "check": {"skill": "search", "dc": 0, "actor": "kaelen", "success": "success", "failure": "failure"}
	})
	assert_false(bool(bad_dc.get("ok", false)))
	var bad_actor := CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", 1, {
		"text": "Bad.", "check": {"skill": "search", "dc": 12, "actor": "nobody", "success": "success", "failure": "failure"}
	})
	assert_false(bool(bad_actor.get("ok", false)))
	var bad_dest := CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", 1, {
		"text": "Bad.", "check": {"skill": "search", "dc": 12, "actor": "kaelen", "success": "missing", "failure": "failure"}
	})
	assert_false(bool(bad_dest.get("ok", false)))
	var choice: Dictionary = Dictionary(Array(Dictionary(CampaignStore.dialogue_by_id(draft, "keeper_talk")["nodes"])["start"].get("choices", []))[1])
	var check: Dictionary = Dictionary(choice.get("check", {}))
	assert_eq(String(check.get("skill", "")), "search")
	assert_eq(int(check.get("dc", 0)), 12)
	assert_eq(String(check.get("actor", "")), "kaelen")
	assert_true(Array(choice.get("conditions", [])).size() > 0, "the retry guard is stored as a condition")
	# An unsupported effect is rejected by shape validation; narration and set_flag are accepted.
	var nodes: Dictionary = Dictionary(CampaignStore.dialogue_by_id(draft, "keeper_talk").get("nodes", {}))
	var success: Dictionary = Dictionary(nodes["success"])
	success["effects"] = [{"type": "teleport_everyone", "flag": "x"}]
	nodes["success"] = success
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "unknown effect type"))
	success["effects"] = [{"type": "narration", "text": "The ledger opens."}, {"type": "set_flag", "flag": "watcher_studied"}]
	nodes["success"] = success
	assert_false(_has_error(CampaignStore.validate_draft_shape(draft), "unknown effect type"))


func test_authored_interaction_survives_save_reopen_playtest_and_normal_play() -> void:
	var draft := _authored_campaign()
	var reopened := Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	assert_eq(Dictionary(reopened.get("dialogues", {})).size(), 1, "dialogue survives save/reopen")
	var dialogue: Dictionary = CampaignStore.dialogue_by_id(reopened, "keeper_talk")
	assert_eq(String(dialogue.get("start", "")), "start")
	assert_eq(Dictionary(dialogue.get("nodes", {})).keys().size(), 5)
	var npc := CampaignStore.find_npc(reopened, "area_01", "keeper_npc")
	assert_eq(Vector2i(4, 3), Vector2i(int(Array(npc.get("pos", [0, 0]))[0]), int(Array(npc.get("pos", [0, 0]))[1])))
	assert_eq(String(npc.get("dialogue", "")), "keeper_talk")
	assert_true(FileAccess.file_exists(CampaignStore.package_dir(CREATOR_ID).path_join("dialogue").path_join("keeper_talk.json")))
	assert_false(FileAccess.get_file_as_string(CampaignStore.package_dir(CREATOR_ID).path_join("campaign.json")).contains("keeper_talk"), "dialogue content is not in the manifest")
	Game.refresh_campaigns()
	Game.playtest_mode = true
	assert_true(bool(Game.load_campaign(CREATOR_ID).get("ok", false)))
	assert_true(bool(Game.new_game([], 77).get("ok", false)))
	var interact := Game.interact()
	assert_true(bool(interact.get("ok", false)), "the NPC starts its conversation from the entry cell")
	assert_eq(Game.mode, "dialogue")
	var actor: Character = Game.party[0]
	for member in Game.party:
		if member.id == "kaelen":
			actor = member
	var success_seed := _find_check_seed(actor, "search", 12, true)
	var failure_seed := _find_check_seed(actor, "search", 12, false)
	assert_true(success_seed > 0 and failure_seed > 0, "both outcomes have a deterministic seed")
	Game.rng.seed = failure_seed
	var failed := Game.dialogue_choose(1)
	assert_true(bool(failed.get("ok", false)), String(failed.get("message", "")))
	assert_false(bool(Dictionary(failed.get("check", {})).get("success", true)), "failure seed rolls a failure")
	assert_false(bool(Game.flags.get("watcher_studied", false)), "a failed check does not set the flag")
	assert_eq(Game.mode, "dialogue", "the failure node returns to the introduction")
	Game.rng.seed = success_seed
	var succeeded := Game.dialogue_choose(1)
	assert_true(bool(Dictionary(succeeded.get("check", {})).get("success", false)), "success seed rolls a success")
	assert_true(bool(Game.flags.get("watcher_studied", false)), "the success node sets the persistent flag")
	var choices := Game.dialogue_choices()
	var check_available := false
	var recall_available := false
	for choice in choices:
		if int(choice.get("index", -1)) == 1:
			check_available = bool(choice.get("available", false))
		if int(choice.get("index", -1)) == 2:
			recall_available = bool(choice.get("available", false))
	assert_false(check_available, "the guarded check is hidden after success")
	assert_true(recall_available, "the later response appears because the flag is set")
	var blocked := Game.save_game("slot1")
	assert_false(bool(blocked.get("ok", false)), "playtest cannot write a campaign save")
	Game.abandon_playtest()
	# Ordinary play: the same package, no playtest mode.
	assert_true(bool(Game.load_campaign(CREATOR_ID).get("ok", false)))
	Game.playtest_mode = false
	assert_true(bool(Game.new_game([], 88).get("ok", false)))
	assert_true(bool(Game.interact().get("ok", false)))
	Game.rng.seed = success_seed
	assert_true(bool(Game.dialogue_choose(1).get("ok", false)))
	assert_true(bool(Game.flags.get("watcher_studied", false)))
	Game.dialogue_choose(2)
	assert_eq(Game.mode, "explore", "the authored exit returns to exploration")
	var saved := Game.save_game("slot1")
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	Game.new_game([], 99)
	assert_false(bool(Game.flags.get("watcher_studied", false)), "a new playthrough starts without the flag")
	assert_true(bool(Game.load_game("slot1").get("ok", false)))
	assert_true(bool(Game.flags.get("watcher_studied", false)), "the saved consequence survives quit and load")
	# Cross-campaign: a second campaign's save and flags are independent.
	var other := CampaignStore.create("Other Campaign", OTHER_ID)
	assert_true(bool(other.get("ok", false)))
	assert_true(bool(Game.load_campaign(OTHER_ID).get("ok", false)))
	assert_true(bool(Game.new_game([], 100).get("ok", false)))
	Game.flags["other_campaign_marker"] = true
	assert_true(bool(Game.save_game("slot1").get("ok", false)))
	assert_true(bool(Game.load_campaign(CREATOR_ID).get("ok", false)))
	assert_true(bool(Game.load_game("slot1").get("ok", false)))
	assert_true(bool(Game.flags.get("watcher_studied", false)))
	assert_false(bool(Game.flags.get("other_campaign_marker", false)), "another campaign's flags do not leak")
	assert_true(bool(Game.load_campaign(OTHER_ID).get("ok", false)))
	assert_true(bool(Game.load_game("slot1").get("ok", false)))
	assert_true(bool(Game.flags.get("other_campaign_marker", false)))
	assert_false(bool(Game.flags.get("watcher_studied", false)))


func _find_check_seed(actor: Character, skill: String, dc: int, want_success: bool) -> int:
	for seed in range(1, 1000):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var result := Rules.skill_check(rng, actor, skill, dc)
		if bool(result.get("success", false)) == want_success:
			return seed
	return -1


func _find_diag(diagnostics: Array, code: String) -> Dictionary:
	for raw in diagnostics:
		if raw is Dictionary and String(Dictionary(raw).get("code", "")) == code:
			return Dictionary(raw)
	return {}


func _diagnostic_draft() -> Dictionary:
	assert_true(bool(_create().get("ok", false)))
	var draft: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	draft["entry"] = {"area": "area_01", "pos": [0, 0], "facing": 0}
	var area: Dictionary = Dictionary(Array(draft["areas"])[0])
	area["npcs"] = [
		{"id": "guide_a", "name": "Guide A", "look": "", "pos": [2, 2], "dialogue": "guide_a_talk"},
		{"id": "guide_b", "name": "Guide B", "look": "", "pos": [3, 2], "dialogue": "missing_b"},
	]
	Array(draft["areas"])[0] = area
	assert_true(bool(CampaignStore.add_dialogue(draft, "guide_a_talk", "Guide A").get("ok", false)))
	var dialogue: Dictionary = CampaignStore.dialogue_by_id(draft, "guide_a_talk")
	var nodes: Dictionary = Dictionary(dialogue.get("nodes", {}))
	var start: Dictionary = Dictionary(nodes["start"])
	start["next"] = "gone_node"
	nodes["start"] = start
	dialogue["nodes"] = nodes
	return draft


func test_draft_diagnostics_have_stable_codes_and_locations() -> void:
	var draft := _diagnostic_draft()
	var result := Game.validate_campaign_draft_diagnostics(draft)
	assert_false(bool(result.get("ok", false)))
	var entry := _find_diag(Array(result["diagnostics"]), "entry.pos.wall")
	assert_false(entry.is_empty(), "entry error has a stable code")
	assert_eq(String(entry["severity"]), "error")
	assert_eq(String(entry["campaign"]), CREATOR_ID)
	assert_eq(String(entry["entity_type"]), "campaign")
	assert_eq(String(entry["field"]), "entry.pos")
	assert_eq(String(entry["section"]), "entry")
	assert_eq(String(entry["area_id"]), "area_01")
	var npc := _find_diag(Array(result["diagnostics"]), "npc.dialogue.missing")
	assert_eq(String(npc["entity_id"]), "guide_b")
	assert_eq(String(npc["section"]), "npc")
	assert_true(Array(npc["refs"]).has("missing_b"))
	var node := _find_diag(Array(result["diagnostics"]), "dialogue.node.destination")
	assert_eq(String(node["entity_id"]), "start")
	assert_eq(String(node["node_id"]), "start")
	assert_eq(String(node["field"]), "next")
	assert_eq(String(Array(node["refs"])[0]), "guide_a_talk", "node navigation carries its owning dialogue")


func test_diagnostic_navigation_selects_the_right_similar_entity_and_preserves_dirty_state() -> void:
	var draft := _diagnostic_draft()
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	screen.title_edit.text = "Unsaved title"
	screen.dirty = true
	screen._validate()
	for i in 2:
		await get_tree().process_frame
	assert_true(screen.diagnostics_panel.visible, "validation results are shown")
	assert_true(screen.diagnostics_panel.get_child_count() > 1)
	var npc := _find_diag(screen.diagnostics, "npc.dialogue.missing")
	assert_eq(String(npc["entity_id"]), "guide_b")
	await screen._navigate_diagnostic(npc)
	assert_eq(screen._selected_npc_id, "guide_b", "the diagnostic selects its own NPC, not the first similar one")
	assert_eq(screen.last_focused_control, screen.npc_dialogue_option, "the missing-dialogue field receives focus")
	assert_eq(screen.title_edit.text, "Unsaved title", "navigation does not discard unsaved form input")
	assert_true(screen.dirty, "navigation does not silently save or clean the draft")
	Array(screen.draft["areas"][0]["npcs"]).remove_at(1)
	await screen._navigate_diagnostic(npc)
	assert_true(screen.status_label.text.contains("no longer exists"), "stale diagnostics explain revalidation")
	var entry := _find_diag(screen.diagnostics, "entry.pos.wall")
	await screen._navigate_diagnostic(entry)
	assert_eq(screen.last_focused_control, screen.set_entry_button, "entry diagnostics reach the entry control")
	await screen._navigate_diagnostic(ContentDiagnostics.make("content.rule", "error", "File-only rule.", {
		"section": "advanced", "advanced": true, "source": "user://campaigns/demo",
	}))
	assert_true(screen.status_label.text.contains("outside the form editor"), "advanced results explain file editing instead of pretending to navigate")
	screen.draft["entry"] = {"area": "area_01", "pos": [4, 4], "facing": 0}
	screen._validate()
	assert_true(_find_diag(screen.diagnostics, "entry.pos.wall").is_empty(), "revalidation clears the corrected error")


func test_a_plain_choice_is_not_pending_after_a_check_at_a_custom_dc() -> void:
	var draft: Dictionary = CampaignStore.make_draft("Pending Choice", "probe_choice_pending")
	assert_true(bool(CampaignStore.add_dialogue(draft, "keeper_talk", "Keeper").get("ok", false)))
	var first := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	assert_true(bool(first.get("ok", false)))
	var second := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	assert_true(bool(second.get("ok", false)))
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	assert_true(screen._select_dialogue_by_id("keeper_talk"), "the authored conversation is listed")
	var start_index := -1
	for i in screen.node_option.item_count:
		if String(screen.node_option.get_item_metadata(i)) == "start":
			start_index = i
	assert_true(start_index >= 0, "the start node is listed")
	screen._select_node(start_index)
	screen._select_choice(0)
	screen.choice_text_edit.text = "Search the altar. [Search DC 5]"
	screen.choice_check_toggle.button_pressed = true
	screen._select_by_meta(screen.choice_skill_option, "search")
	screen.choice_dc_spin.value = 5
	screen._select_by_meta(screen.choice_actor_option, "best")
	screen._select_by_meta(screen.choice_success_option, "start")
	screen._select_by_meta(screen.choice_failure_option, "start")
	assert_true(screen._apply_choice(), "the skill check is stored")
	assert_false(screen._choice_form_pending(), "the applied check is not pending")
	# The DC field still holds 5. A plain choice beside it is not edited by that
	# leftover value, so it must not block validate, save or playtest.
	screen._add_choice()
	await get_tree().process_frame
	screen._select_choice(1)
	assert_eq(screen._selected_choice, 1, "the new choice is selected")
	screen.choice_text_edit.text = "Leave."
	screen.choice_check_toggle.button_pressed = false
	screen._select_by_meta(screen.choice_dest_option, "")
	assert_true(screen._apply_choice(), "the plain choice is stored")
	assert_false(screen._choice_form_pending(), "a leftover check DC is not an edit to a plain choice")
	assert_true(screen.pending_form_keys().is_empty(), "nothing stays pending: %s" % [str(screen.pending_form_keys())])
	var node: Dictionary = Dictionary(Dictionary(CampaignStore.dialogue_by_id(draft, "keeper_talk").get("nodes", {}))["start"])
	var stored: Dictionary = Dictionary(Array(node.get("choices", []))[1])
	assert_eq(String(stored.get("text", "")), "Leave.")
	assert_true(Dictionary(stored.get("check", {})).is_empty(), "the plain choice stores no check")


func test_pending_form_policy_protects_npc_and_apply_discard() -> void:
	var draft := _diagnostic_draft()
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	assert_true(screen.pending_form_keys().is_empty(), "a freshly refreshed form has no pending edits")
	var applied_name := String(CampaignStore.find_npc(draft, "area_01", "guide_a").get("name", ""))
	screen.npc_name_edit.text = "Pending Guide"
	assert_true(screen.pending_form_keys().has("npc"), "the NPC form is pending")
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")), applied_name, "typing does not change the applied draft")
	screen.last_focused_control = screen.npc_name_edit
	screen._select_npc(1)
	assert_eq(screen._selected_npc_id, "guide_a", "Cancel keeps the selection")
	assert_eq(screen.npc_name_edit.text, "Pending Guide", "Cancel keeps the text")
	assert_eq(screen.last_focused_control, screen.npc_name_edit, "Cancel keeps focus")
	assert_true(screen.status_label.text.contains("Pending form edits"), "the blocked transition explains why")
	screen._validate()
	var npc_diag := _find_diag(screen.diagnostics, "npc.dialogue.missing")
	await screen._navigate_diagnostic(npc_diag)
	assert_eq(screen._selected_npc_id, "guide_a", "diagnostic navigation waits for a pending resolution")
	assert_true(screen.apply_pending_forms(), "Apply failed: " + screen.status_label.text)
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")), "Pending Guide")
	assert_true(screen.pending_form_keys().is_empty(), "Apply makes the form match the draft")
	await screen._navigate_diagnostic(npc_diag)
	assert_eq(screen._selected_npc_id, "guide_b", "diagnostic navigation resumes after Apply")
	screen._select_npc(0)
	screen.npc_name_edit.text = ""
	assert_false(screen.apply_pending_forms(), "an empty NPC name is refused")
	assert_eq(screen.npc_name_edit.text, "", "failed Apply preserves the entered text")
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")), "Pending Guide", "failed Apply preserves the applied draft")
	assert_true(screen.status_label.text.contains("cannot be empty"), "failed Apply explains the error")
	await screen._navigate_diagnostic(npc_diag)
	assert_eq(screen._selected_npc_id, "guide_a", "no navigation occurs after failed Apply")
	screen.discard_pending_forms()
	assert_eq(screen.npc_name_edit.text, "Pending Guide", "Discard restores the applied value")
	assert_true(screen.pending_form_keys().is_empty(), "Discard clears the pending state")
	screen.npc_name_edit.text = "Another Pending"
	assert_false(screen._save(), "Save refuses pending form text")
	assert_true(screen.status_label.text.contains("Pending form edits"))
	screen._playtest()
	assert_true(screen.status_label.text.contains("Pending form edits"), "Playtest refuses pending form text")
	screen._back()
	assert_true(screen.status_label.text.contains("Pending form edits"), "Leave refuses pending form text")


func test_pending_form_guards_cover_entity_selection_and_validation_agreement() -> void:
	var story := _story_campaign()
	var draft: Dictionary = story["draft"]
	var quest_id := String(story["quest"])
	assert_true(bool(CampaignStore.add_dialogue(draft, "second_talk", "Second Speaker").get("ok", false)))
	var extra_node := CampaignStore.add_dialogue_node(draft, "keeper_talk")
	assert_true(bool(extra_node.get("ok", false)))
	var extra_choice := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	assert_true(bool(extra_choice.get("ok", false)))
	assert_true(bool(CampaignStore.update_dialogue_choice(
		draft, "keeper_talk", "start", int(extra_choice.get("index", 0)),
		{"text": "Continue.", "next": String(extra_node.get("id", ""))}
	).get("ok", false)), "the extra node is reachable")
	assert_true(bool(CampaignStore.add_quest(draft, "Second Quest").get("ok", false)))
	assert_true(bool(CampaignStore.add_objective(draft, quest_id).get("ok", false)))
	assert_true(bool(CampaignStore.add_encounter(draft).get("ok", false)))
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	assert_true(screen.pending_form_keys().is_empty(), "the full story form starts clean")

	var dialogue_id := screen._selected_dialogue_id
	screen.speaker_edit.text = "Pending Speaker"
	assert_true(screen.pending_form_keys().has("dialogue"))
	screen._select_dialogue(1)
	assert_eq(screen._selected_dialogue_id, dialogue_id, "dirty conversation does not switch")
	assert_eq(screen.speaker_edit.text, "Pending Speaker", "dirty conversation text is preserved")
	screen.discard_pending_forms()

	var node_id := screen._selected_node_id
	screen.node_text_edit.text = "Pending node"
	assert_true(screen.pending_form_keys().has("node"))
	screen._select_node(1)
	assert_eq(screen._selected_node_id, node_id, "dirty node does not switch")
	assert_eq(screen.node_text_edit.text, "Pending node", "dirty node text is preserved")
	screen.discard_pending_forms()

	var choice_before := screen._selected_choice
	screen.choice_text_edit.text = "Pending choice"
	assert_true(screen.pending_form_keys().has("choice"))
	screen._select_choice(1)
	assert_eq(screen._selected_choice, choice_before, "dirty response does not switch")
	assert_eq(screen.choice_text_edit.text, "Pending choice", "dirty response text is preserved")
	screen.discard_pending_forms()

	var quest_before := screen._selected_quest_id
	screen.quest_title_edit.text = "Pending quest"
	assert_true(screen.pending_form_keys().has("quest"))
	screen._select_quest(1)
	assert_eq(screen._selected_quest_id, quest_before, "dirty quest does not switch")
	assert_eq(screen.quest_title_edit.text, "Pending quest", "dirty quest text is preserved")
	screen.discard_pending_forms()

	var objective_before := screen._selected_objective_id
	screen.objective_text_edit.text = "Pending objective"
	assert_true(screen.pending_form_keys().has("objective"))
	screen._select_objective(1)
	assert_eq(screen._selected_objective_id, objective_before, "dirty objective does not switch")
	screen.discard_pending_forms()

	var encounter_before := screen._selected_encounter_id
	screen.encounter_name_edit.text = "Pending encounter"
	assert_true(screen.pending_form_keys().has("encounter"))
	screen._select_encounter(1)
	assert_eq(screen._selected_encounter_id, encounter_before, "dirty encounter does not switch")
	assert_eq(screen.encounter_name_edit.text, "Pending encounter", "dirty encounter text is preserved")
	screen.discard_pending_forms()

	screen.npc_name_edit.text = "Pending NPC"
	assert_true(screen.pending_form_keys().has("npc"))
	screen._select_area(1)
	assert_eq(screen._area_id(), "area_01", "dirty NPC form blocks an area change")
	assert_eq(screen.npc_name_edit.text, "Pending NPC")
	screen.discard_pending_forms()

	screen._select_quest(0)
	var selected_quest := screen._selected_quest_id
	var selected_title := String(Dictionary(Dictionary(screen.draft["quests"])[selected_quest]).get("title", ""))
	screen.quest_title_edit.text = "Pending Quest Title"
	assert_true(screen.pending_form_keys().has("quest"))
	screen._validate()
	assert_true(screen.status_label.text.contains("Applied draft validates, but pending form edits"), "validation does not announce the unapplied text as valid: " + screen.status_label.text)
	assert_eq(String(Dictionary(Dictionary(screen.draft["quests"])[selected_quest]).get("title", "")), selected_title, "validation does not apply the form")
	var quests_path := CampaignStore.package_dir(CREATOR_ID).path_join("quests.json")
	var saved_before := FileAccess.get_file_as_string(quests_path)
	assert_false(screen._save(), "Save refuses pending quest text")
	assert_eq(FileAccess.get_file_as_string(quests_path), saved_before, "Save does not write a pending form")
	screen._playtest()
	assert_true(screen.status_label.text.contains("Pending form edits"), "Playtest refuses pending quest text")
	screen._back()
	assert_true(screen.status_label.text.contains("Pending form edits"), "Leave refuses pending quest text")
	assert_true(screen.apply_pending_forms(), "Apply failed: " + screen.status_label.text)
	assert_eq(String(Dictionary(Dictionary(screen.draft["quests"])[selected_quest]).get("title", "")), "Pending Quest Title", screen.status_label.text)
	screen._validate()
	assert_true(screen.status_label.text.contains("Draft validates"), "validation agrees once the form is applied")
	assert_true(screen._save(), "Save succeeds after Apply")
	assert_ne(FileAccess.get_file_as_string(quests_path), saved_before, "the resolved edit is deliberately saved")


func _atomic_draft() -> Dictionary:
	var draft := CampaignStore.make_draft("Atomic Probe", "atomic_probe")
	var area: Dictionary = Dictionary(Array(draft["areas"])[0])
	area["npcs"] = [
		{"id": "guide_a", "name": "Guide A", "look": "", "pos": [2, 2], "dialogue": "guide_talk"},
		{"id": "guide_b", "name": "Guide B", "look": "", "pos": [3, 2], "dialogue": "missing_talk"},
	]
	Array(draft["areas"])[0] = area
	assert_true(bool(CampaignStore.add_dialogue(draft, "guide_talk", "Guide").get("ok", false)))
	return draft


func test_failed_multi_form_apply_is_atomic_and_preserves_all_input() -> void:
	CampaignStore.delete_user_campaign("atomic_probe")
	var draft := _atomic_draft()
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	screen.dirty = false
	var before: Dictionary = screen.draft.duplicate(true)
	screen.npc_name_edit.text = "Attempted Name"
	screen.speaker_edit.text = "   "
	assert_true(screen.pending_form_keys().has("npc"))
	assert_true(screen.pending_form_keys().has("dialogue"))
	assert_false(screen.apply_pending_forms(), "the later invalid conversation refuses the whole Apply")
	assert_eq(screen.draft, before, "the complete applied draft is unchanged after failure")
	assert_eq(screen.npc_name_edit.text, "Attempted Name", "earlier entered text remains available")
	assert_eq(screen.speaker_edit.text, "   ", "later entered text remains available")
	assert_eq(screen._selected_npc_id, "guide_a", "selection does not advance")
	assert_eq(screen._selected_dialogue_id, "guide_talk", "dialogue selection does not advance")
	assert_false(screen.dirty, "dirty state is restored when the starting draft was clean")
	assert_true(screen.status_label.text.contains("cannot be empty"), "the validation explanation stays visible")
	assert_true(screen.pending_form_keys().has("npc") and screen.pending_form_keys().has("dialogue"))
	assert_false(DirAccess.dir_exists_absolute(CampaignStore.package_dir("atomic_probe")), "no campaign files are written")
	CampaignStore.delete_user_campaign("atomic_probe")


func test_successful_multi_form_apply_then_navigation_uses_all_changes() -> void:
	var draft := _atomic_draft()
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	screen._validate()
	var npc_diag := _find_diag(screen.diagnostics, "npc.dialogue.missing")
	assert_false(npc_diag.is_empty(), "guide_b has an actionable missing-reference diagnostic")
	screen.npc_name_edit.text = "Applied Name"
	screen.speaker_edit.text = "Applied Speaker"
	assert_true(screen.apply_pending_forms(), String(screen.status_label.text))
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_a").get("name", "")), "Applied Name")
	assert_eq(String(CampaignStore.dialogue_by_id(screen.draft, "guide_talk").get("speaker", "")), "Applied Speaker")
	assert_true(screen.pending_form_keys().is_empty())
	await screen._navigate_diagnostic(npc_diag)
	assert_eq(screen._selected_npc_id, "guide_b", "navigation runs after all pending forms are applied")


func test_unresolved_reference_is_visible_and_preserved_by_unrelated_apply() -> void:
	var draft := _atomic_draft()
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	assert_true(screen._select_npc_by_id("guide_b"))
	assert_eq(screen._selected_meta(screen.npc_dialogue_option), "missing_talk", "the stored missing id is not replaced by a valid option")
	assert_true(screen.npc_dialogue_option.get_item_text(screen.npc_dialogue_option.selected).contains("Unresolved reference"), "the picker names the unresolved reference")
	assert_true(screen.pending_form_keys().is_empty(), "opening the entity is not a creator edit")
	screen.npc_name_edit.text = "Guide B Renamed"
	assert_true(screen.apply_pending_forms(), String(screen.status_label.text))
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_b").get("name", "")), "Guide B Renamed")
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_b").get("dialogue", "")), "missing_talk", "unrelated Apply preserves the invalid reference")
	assert_eq(screen._selected_meta(screen.npc_dialogue_option), "missing_talk")
	var diagnostics: Array = Array(Game.validate_campaign_draft_diagnostics(screen.draft).get("diagnostics", []))
	assert_false(_find_diag(diagnostics, "npc.dialogue.missing").is_empty(), "the unresolved reference stays actionable")


func test_intentional_reference_repair_updates_draft_and_clears_diagnostic() -> void:
	var draft := _atomic_draft()
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	assert_true(screen._select_npc_by_id("guide_b"))
	screen._select_by_meta(screen.npc_dialogue_option, "guide_talk")
	assert_eq(screen._selected_meta(screen.npc_dialogue_option), "guide_talk")
	assert_true(screen.pending_form_keys().has("npc"))
	assert_true(screen.apply_pending_forms(), String(screen.status_label.text))
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_b").get("dialogue", "")), "guide_talk")
	var diagnostics: Array = Array(Game.validate_campaign_draft_diagnostics(screen.draft).get("diagnostics", []))
	assert_true(_find_diag(diagnostics, "npc.dialogue.missing").is_empty(), "intentional repair clears the missing-reference diagnostic")


func test_saving_an_unresolved_reference_is_refused_without_overwrite() -> void:
	CampaignStore.delete_user_campaign("atomic_probe")
	var draft := _atomic_draft()
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, draft)
	for i in 3:
		await get_tree().process_frame
	assert_true(screen._select_npc_by_id("guide_b"))
	screen.npc_name_edit.text = "Saved Guide B"
	assert_true(screen.apply_pending_forms(), String(screen.status_label.text))
	var written := CampaignStore.write_package(screen.draft)
	assert_false(bool(written.get("ok", false)), "an unresolved reference blocks saving")
	assert_true(String(written.get("message", "")).contains("missing_talk"), "the save refusal names the unresolved id")
	assert_false(DirAccess.dir_exists_absolute(CampaignStore.package_dir("atomic_probe")), "no package is written")
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_b").get("dialogue", "")), "missing_talk", "the in-memory reference is not repaired")
	assert_eq(String(CampaignStore.find_npc(screen.draft, "area_01", "guide_b").get("name", "")), "Saved Guide B")
	CampaignStore.delete_user_campaign("atomic_probe")


func test_malformed_json_syntax_is_distinct_from_wrong_shape_and_never_rewrites() -> void:
	assert_true(bool(_create().get("ok", false)))
	var dir := CampaignStore.package_dir(CREATOR_ID).path_join("areas")
	var files := DirAccess.get_files_at(dir)
	files.sort()
	assert_false(files.is_empty())
	var area_path := dir.path_join(String(files[0]))
	var draft: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	var draft_before := JSON.stringify(draft)
	var invalid_source := "{ this is not json"
	var file := FileAccess.open(area_path, FileAccess.WRITE)
	file.store_string(invalid_source)
	file.close()
	var malformed := CampaignStore.load_package(CREATOR_ID)
	assert_false(bool(malformed.get("ok", false)))
	assert_true(String(malformed.get("message", "")).contains(String(files[0])), "the malformed source file is named")
	assert_eq(FileAccess.get_file_as_string(area_path), invalid_source, "the invalid original is not overwritten")
	assert_eq(JSON.stringify(draft), draft_before, "a valid open draft is not mutated")
	var wrong_shape := FileAccess.open(area_path, FileAccess.WRITE)
	wrong_shape.store_string("[]")
	wrong_shape.close()
	var shaped := CampaignStore.load_package(CREATOR_ID)
	assert_false(bool(shaped.get("ok", false)))
	assert_true(String(shaped.get("message", "")).contains("not a JSON object"), "valid JSON with the wrong shape is reported separately")


func _has_error(errors: Array, needle: String) -> bool:
	for error in errors:
		if String(error).contains(needle):
			return true
	return false


## Builds the same scenario a creator assembles from the controls: one quest
## with a flag-bound objective, a second area, a placed encounter trigger,
## victory consequences and a keeper whose response changes afterwards.
func _story_campaign() -> Dictionary:
	assert_true(bool(_create().get("ok", false)))
	var draft: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	var quest_id := CREATOR_ID + "_quest"
	assert_true(bool(CampaignStore.set_quest_fields(
		draft, quest_id, "The Cold Beacon", "(USER CAMPAIGN) Light the beacon.", quest_id, quest_id
	).get("ok", false)))
	assert_true(bool(CampaignStore.update_objective(
		draft, quest_id, "look_around", "light_beacon", "Light the beacon in the east chapel.", "beacon_lit"
	).get("ok", false)))
	assert_true(bool(CampaignStore.add_flag_definition(draft, "beacon_lit", "The beacon is lit.").get("ok", false)))
	var chapel := CampaignStore.add_area(draft, "East Chapel")
	var chapel_id := String(chapel.get("id", ""))
	assert_true(bool(CampaignStore.add_transition(draft, "area_01", Vector2i(4, 5), chapel_id).get("ok", false)))
	assert_true(bool(CampaignStore.add_transition(draft, chapel_id, Vector2i(4, 5), "area_01").get("ok", false)))
	var encounter := CampaignStore.add_encounter(draft)
	var encounter_id := String(encounter.get("id", ""))
	assert_true(bool(encounter.get("ok", false)), String(encounter.get("message", "")))
	assert_true(bool(CampaignStore.set_encounter_fields(
		draft, encounter_id, "Chapel Shade", 150, "(USER CAMPAIGN) Something cold turns."
	).get("ok", false)))
	assert_true(bool(CampaignStore.set_encounter_victory(
		draft, encounter_id, "beacon_lit", "(USER CAMPAIGN) The beacon catches.", quest_id
	).get("ok", false)))
	assert_true(bool(CampaignStore.add_encounter_trigger(
		draft, chapel_id, Vector2i(4, 3), encounter_id, "beacon_lit", "(USER CAMPAIGN) A shape unfolds."
	).get("ok", false)))
	assert_true(bool(CampaignStore.add_dialogue(draft, "keeper_talk", "The Keeper").get("ok", false)))
	CampaignStore.set_dialogue_node(draft, "keeper_talk", "start", "\"The beacon has been out for three nights.\"", "The Keeper", "", "", "")
	var accept := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	assert_true(bool(CampaignStore.update_dialogue_choice(
		draft, "keeper_talk", "start", int(accept.get("index", 0)),
		{"text": "I will light it.", "next": "", "quest_id": quest_id}
	).get("ok", false)))
	var changed := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	assert_true(bool(CampaignStore.update_dialogue_choice(
		draft, "keeper_talk", "start", int(changed.get("index", 0)),
		{"text": "The beacon is lit.", "next": "", "require_flag": "beacon_lit"}
	).get("ok", false)))
	var leave := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	assert_true(bool(CampaignStore.update_dialogue_choice(
		draft, "keeper_talk", "start", int(leave.get("index", 0)), {"text": "Leave.", "next": ""}
	).get("ok", false)))
	assert_true(bool(CampaignStore.place_npc(
		draft, "area_01", Vector2i(4, 3), "keeper_npc", "The Keeper", "(USER CAMPAIGN) A keeper waits.", "keeper_talk"
	).get("ok", false)))
	var saved := CampaignStore.write_package(draft)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	return {"draft": draft, "quest": quest_id, "chapel": chapel_id, "encounter": encounter_id}


func test_quest_flags_and_reference_safe_editing() -> void:
	var draft := _new_draft()
	var quest_id := CREATOR_ID + "_quest"
	var updated := CampaignStore.update_objective(
		draft, quest_id, "look_around", "light_beacon", "Light the beacon.", "beacon_lit"
	)
	assert_true(bool(updated.get("ok", false)), String(updated.get("message", "")))
	assert_false(bool(CampaignStore.update_objective(
		draft, quest_id, "light_beacon", "light_beacon", "Text", "Bad Flag"
	).get("ok", false)), "an invalid flag name is refused")
	assert_false(bool(CampaignStore.update_objective(
		draft, quest_id, "light_beacon", "light_beacon", " ", "beacon_lit"
	).get("ok", false)), "empty objective text is refused")
	assert_true(bool(CampaignStore.add_flag_definition(draft, "beacon_lit", "The beacon is lit.").get("ok", false)))
	assert_true(CampaignStore.flags_of(draft).has("beacon_lit"))
	assert_false(bool(CampaignStore.add_flag_definition(draft, "Bad Flag", "").get("ok", false)))
	assert_true(CampaignStore.known_flags(draft).has("beacon_lit"))
	assert_true(_has_reference(CampaignStore.flag_references(draft, "beacon_lit"), "objective"), "flag references name the objective")
	var second := CampaignStore.add_quest(draft, "Second Quest")
	assert_true(bool(second.get("ok", false)))
	var second_id := String(second.get("id", ""))
	assert_false(bool(CampaignStore.remove_flag_definition(draft, "beacon_lit").get("ok", false)), "a used flag cannot be dropped")
	assert_true(bool(CampaignStore.set_quest_fields(
		draft, quest_id, "The Cold Beacon", "Summary", quest_id, quest_id
	).get("ok", false)))
	var renamed := CampaignStore.rename_quest(draft, quest_id, "beacon_quest")
	assert_true(bool(renamed.get("ok", false)), String(renamed.get("message", "")))
	assert_eq(String(draft.get("start_quest", "")), "beacon_quest", "start quest reference follows the rename")
	assert_eq(String(draft.get("completion_quest", "")), "beacon_quest", "completion reference follows the rename")
	assert_true(CampaignStore.quest_references(draft, "beacon_quest").size() >= 2)
	assert_false(bool(CampaignStore.delete_quest(draft, "beacon_quest").get("ok", false)), "a referenced quest is not deleted")
	assert_true(bool(CampaignStore.delete_quest(draft, second_id).get("ok", false)), "an unreferenced quest is deleted")
	assert_false(bool(CampaignStore.remove_objective(draft, "beacon_quest", "light_beacon").get("ok", false)), "a quest keeps one objective")
	assert_false(bool(CampaignStore.remove_objective(draft, "beacon_quest", "objective_01").get("ok", false)), "the old objective id no longer exists")


func _has_reference(refs: Array, needle: String) -> bool:
	for reference in refs:
		if String(reference).contains(needle):
			return true
	return false


func test_encounter_authoring_and_layout_validation() -> void:
	var draft := _new_draft()
	var added := CampaignStore.add_encounter(draft, "room_7x5")
	assert_true(bool(added.get("ok", false)), String(added.get("message", "")))
	var encounter_id := String(added.get("id", ""))
	assert_false(bool(CampaignStore.add_encounter(draft, "no_such_layout").get("ok", false)), "only supported layouts are offered")
	assert_true(bool(CampaignStore.set_encounter_fields(draft, encounter_id, "Chapel Shade", 125, "Intro.").get("ok", false)))
	assert_false(bool(CampaignStore.set_encounter_fields(draft, encounter_id, " ", 125, "").get("ok", false)))
	assert_false(bool(CampaignStore.set_encounter_fields(draft, encounter_id, "Name", -5, "").get("ok", false)))
	for i in 3:
		assert_true(bool(CampaignStore.add_encounter_monster(draft, encounter_id, "ghoul").get("ok", false)))
	assert_eq(Array(CampaignStore.encounter_by_id(draft, encounter_id).get("monsters", [])).size(), 4)
	assert_false(bool(CampaignStore.add_encounter_monster(draft, encounter_id, "zombie").get("ok", false)), "the layout caps the monster count")
	assert_true(bool(CampaignStore.set_encounter_template(draft, encounter_id, "crypt_9x7").get("ok", false)))
	assert_eq(Array(CampaignStore.encounter_by_id(draft, encounter_id).get("monster_cells", [])).size(), 4)
	assert_false(bool(CampaignStore.remove_encounter_monster(draft, encounter_id, 9).get("ok", false)))
	var encounter: Dictionary = CampaignStore.encounter_by_id(draft, encounter_id)
	var good_cells: Array = Array(encounter.get("monster_cells", [])).duplicate(true)
	encounter["monster_cells"] = [[0, 0], [5, 5], [6, 5], [7, 5]]
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "not walkable"), "a wall cell is rejected")
	encounter["monster_cells"] = [[5, 1], [5, 1], [6, 1], [7, 1]]
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "more than once"), "a duplicated cell is rejected")
	encounter["monster_cells"] = good_cells
	encounter["party_cells"] = [[1, 5], [2, 5]]
	assert_true(_has_error(CampaignStore.validate_draft_shape(draft), "at least 4 party cells"))
	encounter["party_cells"] = [[1, 5], [2, 5], [3, 5], [4, 5]]
	assert_false(_has_error(CampaignStore.validate_draft_shape(draft), "Encounter '" + encounter_id), "the restored layout validates")
	assert_true(bool(CampaignStore.set_encounter_victory(draft, encounter_id, "beacon_lit", "Lit.", "").get("ok", false)))
	assert_false(bool(CampaignStore.set_encounter_victory(draft, encounter_id, "Bad Flag", "", "").get("ok", false)))
	assert_true(bool(CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(3, 3), encounter_id, "beacon_lit", "").get("ok", false)))
	var renamed := CampaignStore.rename_encounter(draft, encounter_id, "chapel_shade")
	assert_true(bool(renamed.get("ok", false)), String(renamed.get("message", "")))
	assert_eq(String(Dictionary(CampaignStore.triggers_of(draft, "area_01")[0]).get("encounter", "")), "chapel_shade", "rename updates the trigger reference")
	assert_false(bool(CampaignStore.delete_encounter(draft, "chapel_shade").get("ok", false)), "a referenced encounter is not deleted")
	assert_true(bool(CampaignStore.remove_encounter_trigger(draft, "area_01", "trigger_01").get("ok", false)))
	assert_true(bool(CampaignStore.delete_encounter(draft, "chapel_shade").get("ok", false)))


func test_trigger_placement_persists_with_once_only_guard() -> void:
	var draft := _new_draft()
	var added := CampaignStore.add_encounter(draft)
	var encounter_id := String(added.get("id", ""))
	assert_false(bool(CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(0, 0), encounter_id, "", "").get("ok", false)), "a wall cannot host a trigger")
	assert_false(bool(CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(4, 4), encounter_id, "", "").get("ok", false)), "the entry cell cannot host a trigger")
	assert_false(bool(CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(3, 3), "missing", "", "").get("ok", false)), "a missing encounter is refused")
	assert_false(bool(CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(3, 3), encounter_id, "Bad Flag", "").get("ok", false)), "an invalid guard is refused")
	var placed := CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(3, 3), encounter_id, "beacon_lit", "A shape stirs.")
	assert_true(bool(placed.get("ok", false)), String(placed.get("message", "")))
	assert_false(bool(CampaignStore.add_encounter_trigger(draft, "area_01", Vector2i(3, 3), encounter_id, "", "").get("ok", false)), "a second trigger on the same cell is refused")
	var trigger := CampaignStore.find_trigger(draft, "area_01", String(placed.get("id", "")))
	assert_eq(String(trigger.get("requires_flag_not", "")), "beacon_lit")
	assert_eq(int(Array(trigger.get("pos", [0, 0]))[0]), 3)
	var saved := CampaignStore.write_package(draft)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var reopened: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	var reopened_trigger := CampaignStore.find_trigger(reopened, "area_01", String(placed.get("id", "")))
	assert_eq(String(reopened_trigger.get("encounter", "")), encounter_id, "the trigger survives save and reopen")
	assert_eq(String(reopened_trigger.get("requires_flag_not", "")), "beacon_lit", "the once-only guard survives")
	assert_false(bool(CampaignStore.update_encounter_trigger(reopened, "area_01", "missing", encounter_id, "", "").get("ok", false)))


func test_playtest_snapshot_is_independent_of_the_saved_package() -> void:
	var draft := _new_draft()
	var quest_id := CREATOR_ID + "_quest"
	assert_true(bool(CampaignStore.write_package(draft).get("ok", false)))
	var quests_path := CampaignStore.package_dir(CREATOR_ID).path_join("quests.json")
	var saved_text := FileAccess.get_file_as_string(quests_path)
	draft["quests"][quest_id]["title"] = "Unsaved Draft Title"
	var staged := CampaignStore.stage_playtest(draft)
	assert_true(bool(staged.get("ok", false)), String(staged.get("message", "")))
	assert_true(DirAccess.dir_exists_absolute(String(staged.get("root", ""))), "the staged snapshot exists on disk")
	var loaded := Game.load_campaign_snapshot(Dictionary(staged.get("manifest", {})))
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(String(Game.content.get_quest(quest_id).get("title", "")), "Unsaved Draft Title", "playtest uses the in-memory draft")
	assert_eq(FileAccess.get_file_as_string(quests_path), saved_text, "the saved package is untouched by staging")
	CampaignStore.cleanup_playtest(CREATOR_ID)
	assert_false(DirAccess.dir_exists_absolute(CampaignStore.PLAYTEST_ROOT.path_join(CREATOR_ID)), "staging is removed on return")
	assert_eq(FileAccess.get_file_as_string(quests_path), saved_text, "the saved package is still untouched")
	var reopened: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	assert_eq(String(Dictionary(reopened["quests"])[quest_id].get("title", "")), "Test Campaign", "reopening shows the deliberately saved title")


func test_authored_scenario_victory_defeat_no_repeat_and_reload() -> void:
	var story := _story_campaign()
	var quest_id := String(story["quest"])
	var chapel_id := String(story["chapel"])
	assert_true(bool(Game.load_campaign(CREATOR_ID).get("ok", false)))
	Game.playtest_mode = false
	# Defeat first: it must not complete the objective or grant the flag.
	assert_true(bool(Game.new_game([], 301).get("ok", false)))
	assert_true(bool(Game.interact().get("ok", false)))
	assert_true(bool(Game.dialogue_choose(0).get("ok", false)))
	Game.facing = 2
	assert_true(bool(Game.interact().get("ok", false)))
	assert_eq(Game.area_id, chapel_id)
	Game.facing = 0
	Game.move_forward()
	assert_eq(Game.mode, "combat", "the trigger starts the authored encounter")
	var xp_before := int(Game.party[0].xp)
	Game.encounter.finish("defeat")
	assert_false(bool(Game.flags.get("beacon_lit", false)), "defeat does not set the victory flag")
	assert_false(Game.quests.objective_done(quest_id, "light_beacon"), "defeat does not complete the objective")
	assert_false(Game.quests.is_complete(quest_id), "defeat does not complete the quest")
	assert_eq(int(Game.party[0].xp), xp_before, "defeat grants no encounter XP")
	# Victory: the flag, objective and quest complete; the trigger never repeats.
	assert_true(bool(Game.new_game([], 302).get("ok", false)))
	assert_true(bool(Game.interact().get("ok", false)))
	assert_true(bool(Game.dialogue_choose(0).get("ok", false)))
	assert_true(Game.quests.is_active(quest_id), "the dialogue response starts the quest")
	Game.facing = 2
	Game.interact()
	Game.facing = 0
	Game.move_forward()
	assert_eq(Game.mode, "combat")
	Game.encounter.finish("victory")
	assert_true(bool(Game.flags.get("beacon_lit", false)), "victory sets the objective flag")
	assert_true(Game.quests.objective_done(quest_id, "light_beacon"))
	assert_true(Game.quests.is_complete(quest_id), "the configured consequence completes the quest")
	assert_true(Game.victory_pending, "completion is the configured campaign victory")
	var xp_after := int(Game.party[0].xp)
	assert_true(xp_after > xp_before, "victory awards the authored XP")
	Game.move_back()
	Game.move_forward()
	assert_eq(Game.mode, "explore", "a spent trigger does not repeat combat")
	assert_eq(int(Game.party[0].xp), xp_after, "a spent trigger grants no extra XP")
	# Returning to the keeper exposes the changed response.
	Game.move_back()
	Game.facing = 2
	assert_true(bool(Game.interact().get("ok", false)))
	assert_eq(Game.area_id, "area_01")
	Game.facing = 0
	assert_true(bool(Game.interact().get("ok", false)))
	var changed_available := false
	for choice in Game.dialogue_choices():
		if String(choice.get("text", "")).contains("beacon is lit") and bool(choice.get("available", false)):
			changed_available = true
	assert_true(changed_available, "the keeper's response changes after victory")
	Game.dialogue_choose(2)
	assert_true(bool(Game.save_game("slot1").get("ok", false)), "ordinary play saves progress")
	assert_true(bool(Game.new_game([], 303).get("ok", false)))
	assert_false(bool(Game.flags.get("beacon_lit", false)), "a new run starts clean")
	assert_true(bool(Game.load_game("slot1").get("ok", false)))
	assert_true(bool(Game.flags.get("beacon_lit", false)), "the saved flag survives reload")
	assert_true(bool(Game.flags.get("trigger_trigger_01", false)), "the trigger stays spent after reload")
	assert_true(Game.quests.is_complete(quest_id), "the saved quest completion survives reload")
	var xp_loaded := int(Game.party[0].xp)
	Game.facing = 2
	Game.move_back()
	Game.facing = 0
	Game.move_forward()
	assert_eq(Game.mode, "explore", "reloading does not rearm the encounter")
	assert_eq(int(Game.party[0].xp), xp_loaded, "reloading does not repeat the reward")


func _package_snapshot(campaign_id: String) -> Dictionary:
	var result := {}
	var stack: Array[String] = [CampaignStore.package_dir(campaign_id)]
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for raw_file in DirAccess.get_files_at(dir):
			var path := dir.path_join(String(raw_file))
			result[path] = FileAccess.get_file_as_string(path)
		for raw_dir in DirAccess.get_directories_at(dir):
			stack.append(dir.path_join(String(raw_dir)))
	return result


## The creator only exposes a bounded form. Supported content it does not edit
## (doors, objects, effects, conditions, unknown author keys, local instance
## tables) must survive opening, changing an unrelated field, and saving.
func test_saving_unrelated_edits_preserves_unexposed_supported_content() -> void:
	assert_true(bool(_create().get("ok", false)))
	var draft: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	var quest_id := CREATOR_ID + "_quest"
	CampaignStore.update_objective(draft, quest_id, "look_around", "light_beacon", "Light it.", "beacon_lit")
	CampaignStore.add_flag_definition(draft, "beacon_lit", "Lit.")
	var chapel := CampaignStore.add_area(draft, "East Chapel")
	var chapel_id := String(chapel.get("id", ""))
	CampaignStore.add_transition(draft, "area_01", Vector2i(4, 5), chapel_id)
	var encounter := CampaignStore.add_encounter(draft, "room_7x5")
	var encounter_id := String(encounter.get("id", ""))
	CampaignStore.set_encounter_fields(draft, encounter_id, "Chapel Shade", 50, "Intro.")
	CampaignStore.set_encounter_victory(draft, encounter_id, "beacon_lit", "Lit.", "")
	CampaignStore.add_encounter_trigger(draft, chapel_id, Vector2i(4, 3), encounter_id, "beacon_lit", "Stirs.")
	CampaignStore.add_dialogue(draft, "keeper_talk", "The Keeper")
	CampaignStore.set_dialogue_node(draft, "keeper_talk", "start", "Hello.", "The Keeper", "", "", "")
	var choice := CampaignStore.add_dialogue_choice(draft, "keeper_talk", "start")
	CampaignStore.update_dialogue_choice(draft, "keeper_talk", "start", int(choice.get("index", 0)), {"text": "Ask.", "next": ""})
	CampaignStore.place_npc(draft, "area_01", Vector2i(4, 3), "keeper_npc", "The Keeper", "A keeper.", "keeper_talk")
	var written := CampaignStore.write_package(draft)
	assert_true(bool(written.get("ok", false)), String(written.get("message", "")))
	var dir := CampaignStore.package_dir(CREATOR_ID)
	# Add supported content the creator form does not expose, plus author keys.
	var area_path := dir.path_join("areas").path_join("area_01.json")
	var area: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(area_path))
	area["doors"] = [{"id": "north_door", "pos": [2, 2], "open_flag": "north_door_open", "label": "Door"}]
	area["objects"] = [{
		"id": "shrine",
		"name": "Shrine",
		"pos": [6, 6],
		"look": "A shrine.",
		"interactions": [{
			"id": "pray",
			"label": "Pray",
			"once": true,
			"requires_flag": "beacon_lit",
			"success_text": "Warmth.",
			"effects": [
				{"type": "set_flag", "flag": "prayed", "value": true},
				{"type": "narration", "text": "You pray."},
			],
		}],
	}]
	area["custom_area_note"] = "keep area note"
	_write_json(area_path, area)
	var quests_path := dir.path_join("quests.json")
	var quests: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(quests_path))
	var quest_def: Dictionary = Dictionary(quests[quest_id])
	quest_def["custom_quest_note"] = "keep quest note"
	var objectives: Array = Array(quest_def.get("objectives", []))
	if not objectives.is_empty():
		Dictionary(objectives[0])["custom_hint"] = "keep hint"
	_write_json(quests_path, quests)
	var encounters_path := dir.path_join("encounters.json")
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(encounters_path))
	var encounter_def: Dictionary = Dictionary(encounters[encounter_id])
	Array(encounter_def.get("victory_effects", [])).append({"type": "gold", "amount": 10})
	encounter_def["custom_encounter_note"] = "keep encounter note"
	_write_json(encounters_path, encounters)
	var talk_path := dir.path_join("dialogue").path_join("keeper_talk.json")
	var talk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(talk_path))
	var start_node: Dictionary = Dictionary(Dictionary(talk.get("nodes", {}))["start"])
	start_node["effects"] = [
		{"type": "heal_party", "amount": 2},
		{"type": "narration", "text": "Existing narration."},
	]
	start_node["author_note"] = "keep node note"
	var first_choice: Dictionary = Dictionary(Array(start_node.get("choices", []))[0])
	first_choice["effects"] = [{"type": "heal_party", "amount": 1}]
	first_choice["conditions"] = [{"type": "not_flag", "flag": "some_optional_flag"}]
	first_choice["custom_choice_note"] = "keep choice note"
	_write_json(talk_path, talk)
	var manifest_path := dir.path_join("campaign.json")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	manifest["custom_manifest_note"] = "keep manifest note"
	manifest["flag_definitions"] = {"beacon_lit": "The beacon is lit."}
	_write_json(manifest_path, manifest)
	var items_path := dir.path_join("items.json")
	var local_item := {
		"id": "local_charm",
		"name": "Local Charm",
		"kind": "weapon",
		"category": "martial",
		"damage": "1d6",
		"crit_range": 20,
		"crit_mult": 2,
		"damage_type": "slashing",
		"weight_lb": 1,
		"value_gp": 5,
		"description": "A campaign-local practice blade.",
	}
	_write_json(items_path, {"local_charm": local_item})
	var items_before := FileAccess.get_file_as_string(items_path)
	var dungeon_path := dir.path_join("dungeon.json")
	var legacy_area: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(area_path)).duplicate(true)
	legacy_area["id"] = "legacy_room"
	legacy_area.erase("doors")
	legacy_area.erase("objects")
	_write_json(dungeon_path, legacy_area)
	var dungeon_before := FileAccess.get_file_as_string(dungeon_path)
	# Reopen, change unrelated fields, save.
	var reopened := CampaignStore.load_package(CREATOR_ID)
	assert_true(bool(reopened.get("ok", false)), String(reopened.get("message", "")))
	var second: Dictionary = reopened["draft"]
	second["title"] = "Renamed Campaign"
	Dictionary(Array(second["areas"])[0])["name"] = "Renamed Area"
	assert_true(bool(CampaignStore.set_encounter_fields(second, encounter_id, "Renamed Encounter", 50, "Intro.").get("ok", false)))
	assert_true(bool(CampaignStore.set_quest_fields(second, quest_id, "Renamed Quest", "Summary", quest_id, "").get("ok", false)))
	var resaved := CampaignStore.write_package(second)
	assert_true(bool(resaved.get("ok", false)), String(resaved.get("message", "")))
	var final := CampaignStore.load_package(CREATOR_ID)
	assert_true(bool(final.get("ok", false)), String(final.get("message", "")))
	var after: Dictionary = final["draft"]
	var final_area: Dictionary = Dictionary(Array(after["areas"])[0])
	assert_eq(String(final_area.get("name", "")), "Renamed Area", "the unrelated edit applies")
	assert_eq(Array(final_area.get("doors", [])).size(), 1, "doors survive the save")
	assert_eq(String(Dictionary(Array(final_area["doors"])[0]).get("open_flag", "")), "north_door_open")
	assert_eq(Array(final_area.get("objects", [])).size(), 1, "objects survive the save")
	var shrine: Dictionary = Dictionary(Array(final_area["objects"])[0])
	var pray: Dictionary = Dictionary(Array(shrine.get("interactions", []))[0])
	assert_true(bool(pray.get("once", false)), "object interaction flags survive")
	assert_eq(Array(pray.get("effects", [])).size(), 2, "object effects survive")
	assert_eq(String(final_area.get("custom_area_note", "")), "keep area note")
	var final_quest: Dictionary = Dictionary(Dictionary(after["quests"])[quest_id])
	assert_eq(String(final_quest.get("custom_quest_note", "")), "keep quest note")
	assert_eq(String(Dictionary(Array(final_quest["objectives"])[0]).get("custom_hint", "")), "keep hint")
	var final_encounter: Dictionary = Dictionary(Dictionary(after["encounters"])[encounter_id])
	assert_eq(String(final_encounter.get("custom_encounter_note", "")), "keep encounter note")
	var found_gold := false
	for raw_effect in Array(final_encounter.get("victory_effects", [])):
		if String(Dictionary(raw_effect).get("type", "")) == "gold":
			found_gold = true
	assert_true(found_gold, "a hand-authored victory effect is not stripped")
	var final_node: Dictionary = Dictionary(Dictionary(Dictionary(after["dialogues"])["keeper_talk"])["nodes"]["start"])
	assert_eq(String(final_node.get("author_note", "")), "keep node note")
	var found_heal := false
	for raw_effect in Array(final_node.get("effects", [])):
		if String(Dictionary(raw_effect).get("type", "")) == "heal_party":
			found_heal = true
	assert_true(found_heal, "an unexposed node effect survives")
	var final_choice: Dictionary = Dictionary(Array(final_node.get("choices", []))[0])
	assert_eq(String(final_choice.get("custom_choice_note", "")), "keep choice note")
	assert_eq(Array(final_choice.get("conditions", [])).size(), 1, "an unexposed condition survives")
	var final_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("campaign.json")))
	assert_eq(String(final_manifest.get("custom_manifest_note", "")), "keep manifest note")
	assert_true(Dictionary(final_manifest.get("flag_definitions", {})).has("beacon_lit"))
	assert_eq(FileAccess.get_file_as_string(items_path), items_before, "a local instance table is not rewritten")
	assert_eq(FileAccess.get_file_as_string(dungeon_path), dungeon_before, "an unmanaged dungeon variant is not deleted")


## A package the creator cannot read or would narrow must be refused, not
## silently emptied and saved over.
func test_load_refuses_packages_it_cannot_rewrite_losslessly() -> void:
	assert_true(bool(_create().get("ok", false)))
	var dir := CampaignStore.package_dir(CREATOR_ID)
	var manifest_path := dir.path_join("campaign.json")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var original_manifest := manifest.duplicate(true)
	manifest["quests"] = {"inline_quest": {"id": "inline_quest", "title": "Inline", "objectives": []}}
	_write_json(manifest_path, manifest)
	var inline := CampaignStore.load_package(CREATOR_ID)
	assert_false(bool(inline.get("ok", false)), "inline content is not silently dropped")
	assert_true(String(inline.get("message", "")).contains("inline"), String(inline.get("message", "")))
	_write_json(manifest_path, original_manifest)
	assert_true(bool(CampaignStore.load_package(CREATOR_ID).get("ok", false)))
	manifest = original_manifest.duplicate(true)
	manifest["format_version"] = 99
	_write_json(manifest_path, manifest)
	var future := CampaignStore.load_package(CREATOR_ID)
	assert_false(bool(future.get("ok", false)), "a newer package format is not rewritten")
	assert_true(String(future.get("message", "")).contains("format version"))
	_write_json(manifest_path, original_manifest)
	var area_path := dir.path_join("areas").path_join("area_01.json")
	var good_area := FileAccess.get_file_as_string(area_path)
	var broken := FileAccess.open(area_path, FileAccess.WRITE)
	broken.store_string("[]")
	broken.close()
	var malformed := CampaignStore.load_package(CREATOR_ID)
	assert_false(bool(malformed.get("ok", false)), "an area file that is not a JSON object blocks editing")
	assert_true(String(malformed.get("message", "")).contains("not a JSON object"))
	var restored := FileAccess.open(area_path, FileAccess.WRITE)
	restored.store_string(good_area)
	restored.close()
	# Persist a valid dialogue, then duplicate its id in a second file.
	var with_dialogue: Dictionary = Dictionary(CampaignStore.load_package(CREATOR_ID).get("draft", {}))
	CampaignStore.add_dialogue(with_dialogue, "dup_talk", "Speaker")
	CampaignStore.set_dialogue_node(with_dialogue, "dup_talk", "start", "Hello.", "Speaker", "", "", "")
	assert_true(bool(CampaignStore.write_package(with_dialogue).get("ok", false)))
	var talk_text := FileAccess.get_file_as_string(dir.path_join("dialogue").path_join("dup_talk.json"))
	var duplicate_file := FileAccess.open(dir.path_join("dialogue").path_join("dup_copy.json"), FileAccess.WRITE)
	duplicate_file.store_string(talk_text)
	duplicate_file.close()
	var duplicate := CampaignStore.load_package(CREATOR_ID)
	assert_false(bool(duplicate.get("ok", false)), "duplicate dialogue ids block editing")
	assert_true(String(duplicate.get("message", "")).contains("Two dialogue files"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join("dialogue").path_join("dup_copy.json")))
	assert_true(bool(CampaignStore.load_package(CREATOR_ID).get("ok", false)))


## Deliberate Save is the only writer of the authored package; playtest stages a
## temporary snapshot, leaves the draft and the normal save untouched, and its
## cleanup cannot reach outside the designated directory.
func test_authored_writes_and_playtest_cleanup_stay_in_bounds() -> void:
	var draft := _new_draft()
	var quest_id := CREATOR_ID + "_quest"
	assert_true(bool(CampaignStore.write_package(draft).get("ok", false)))
	var before := _package_snapshot(CREATOR_ID)
	var quests_path := CampaignStore.package_dir(CREATOR_ID).path_join("quests.json")
	assert_true(bool(Game.load_campaign(CREATOR_ID).get("ok", false)))
	assert_true(bool(Game.new_game([], 77, CREATOR_ID).get("ok", false)))
	assert_true(bool(Game.save_game("slot1").get("ok", false)))
	var save_before := JSON.stringify(SaveSystem.read_save("slot1", CREATOR_ID))
	draft["quests"][quest_id]["title"] = "Unsaved Title"
	var staged := CampaignStore.stage_playtest(draft)
	assert_true(bool(staged.get("ok", false)), String(staged.get("message", "")))
	Game.playtest_mode = true
	Game.playtest_root = String(staged.get("root", ""))
	assert_true(bool(Game.load_campaign_snapshot(Dictionary(staged.get("manifest", {}))).get("ok", false)))
	assert_true(bool(Game.new_game([], 88, CREATOR_ID).get("ok", false)))
	assert_false(bool(Game.save_game("slot1").get("ok", false)), "playtest refuses a normal save")
	Game.abandon_playtest()
	assert_false(DirAccess.dir_exists_absolute(String(staged.get("root", ""))), "staging is removed")
	assert_eq(_package_snapshot(CREATOR_ID), before, "the saved package is byte-identical after playtest")
	assert_eq(JSON.stringify(SaveSystem.read_save("slot1", CREATOR_ID)), save_before, "the normal save is unchanged by playtest")
	assert_eq(String(draft["quests"][quest_id]["title"]), "Unsaved Title", "the draft keeps the unsaved edit")
	# A deliberate save is the one action that updates the package.
	draft["quests"][quest_id]["title"] = "Saved Title"
	assert_true(bool(CampaignStore.write_package(draft).get("ok", false)))
	var after := _package_snapshot(CREATOR_ID)
	assert_ne(after.get(quests_path), before.get(quests_path), "Save updates the authored quest table")
	for path in before.keys():
		if String(path) == quests_path:
			continue
		assert_eq(after.get(path), before.get(path), "unrelated package file %s is unchanged" % path)
	# Cleanup only touches user://playtest/<valid id>.
	var sentinel := "user://cleanup_sentinel.txt"
	var handle := FileAccess.open(sentinel, FileAccess.WRITE)
	handle.store_string("keep me")
	handle.close()
	var staged_file := CampaignStore.PLAYTEST_ROOT.path_join(CREATOR_ID).path_join("keep.txt")
	DirAccess.make_dir_recursive_absolute(CampaignStore.PLAYTEST_ROOT.path_join(CREATOR_ID))
	var inner := FileAccess.open(staged_file, FileAccess.WRITE)
	inner.store_string("delete me")
	inner.close()
	CampaignStore.cleanup_playtest("..")
	CampaignStore.cleanup_playtest("bad/../id")
	CampaignStore.delete_user_campaign("..")
	assert_true(FileAccess.file_exists(sentinel), "cleanup cannot escape its designated root")
	CampaignStore.cleanup_playtest(CREATOR_ID)
	assert_false(FileAccess.file_exists(staged_file), "cleanup removes files inside the designated directory")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sentinel))


## The creator's Save/Validate/Playtest bar and its feedback must stay visible while
## the long quest/encounter sections are scrolled into view.
func test_creator_action_bar_stays_visible_when_scrolled() -> void:
	var screen := CampaignCreator.new()
	add_child_autofree(screen)
	screen.setup(null, CampaignStore.make_draft("Usability", "usability_test"))
	for i in 3:
		await get_tree().process_frame
	screen.focus_encounter_section()
	for i in 3:
		await get_tree().process_frame
	var view := screen.get_viewport().get_visible_rect()
	assert_true(view.encloses(screen.save_button.get_global_rect()), "Save draft stays on screen")
	assert_true(view.encloses(screen.validate_button.get_global_rect()), "Validate draft stays on screen")
	assert_true(view.encloses(screen.play_button.get_global_rect()), "Playtest draft stays on screen")
	assert_true(view.encloses(screen.status_label.get_global_rect()), "status feedback stays on screen")


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file, "could not write %s" % path)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
