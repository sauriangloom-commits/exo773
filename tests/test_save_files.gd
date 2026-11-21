extends GutTest

## Slot-file identity, unusable-copy messages and tie-breaking.
##
## One parser decides what belongs to a slot: the canonical names, the numbered
## working copies (2..100) the writer creates, and the previous release's `.w`
## names. A hand-made archive or editor backup is not a slot file, so it neither
## loads as recovery nor disappears when the slot is deleted. A slot that still
## holds files is never reported as empty: incompatible, foreign, stale, invalid
## and damaged copies each name their own reason.

const SLOT := "slot2"
const CAMPAIGN := "ravenloft_demo"


func before_each() -> void:
	Game.load_campaign(CAMPAIGN)
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)
	_clean()


func after_each() -> void:
	_clean()
	Game.reset_to_menu()
	Game.load_campaign(CAMPAIGN)


func _clean() -> void:
	SaveSystem.delete_save(SLOT)
	for path in _prefixed_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Every file whose name merely looks like the slot, accepted pattern or not.
func _prefixed_files() -> Array:
	var found: Array = []
	for directory_path in [SaveSystem.campaign_dir(CAMPAIGN), SaveSystem.save_dir]:
		var directory := DirAccess.open(String(directory_path))
		if directory == null:
			continue
		for name in directory.get_files():
			if String(name).to_lower().begins_with(SLOT + ".json"):
				found.append(String(directory_path).path_join(String(name)))
	return found


func _path(suffix := "") -> String:
	return SaveSystem.path_for(SLOT, CAMPAIGN) + suffix


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _write(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## A complete, valid payload with a chosen gold value and identity.
func _payload(gold: int, unix := 1000, campaign := CAMPAIGN, content := -1, version := 0) -> Dictionary:
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var payload: Dictionary = JSON.parse_string(_text(_path()))
	payload["gold"] = gold
	payload["saved_unix"] = unix
	payload["saved_at"] = "2026-11-20 13:%02d:00" % (gold % 60)
	if campaign != CAMPAIGN:
		payload["campaign_id"] = campaign
	if content >= 0:
		payload["content_version"] = content
	if version > 0:
		payload["save_version"] = version
	SaveSystem.delete_save(SLOT)
	return payload


func _row() -> Dictionary:
	for entry in Game.list_saves():
		if String(entry["slot"]) == SLOT:
			return entry
	return {}


func _load_gold() -> int:
	var loaded := Game.load_game(SLOT)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	return Game.gold


func test_the_parser_accepts_exactly_the_writer_names() -> void:
	var accepted := {
		"slot2.json": "primary",
		"slot2.json.bak": "backup",
		"slot2.json.tmp": "temp",
		"slot2.json.bak.2": "backup",
		"slot2.json.bak.100": "backup",
		"slot2.json.tmp.2": "temp",
		"slot2.json.tmp.100": "temp",
		"slot2.json.bak.w": "backup",
		"slot2.json.tmp.w": "temp",
	}
	for name in accepted.keys():
		var parsed := SaveSystem.parse_slot_file(String(name), SLOT)
		assert_eq(String(parsed.get("role", "")), String(accepted[name]), String(name))
	var rejected := [
		"slot2.json.bak.1", "slot2.json.bak.0", "slot2.json.bak.101",
		"slot2.json.bak.02", "slot2.json.bak.+2", "slot2.json.bak.-2",
		"slot2.json.bak.w.2", "slot2.json.bak.2.old", "slot2.json.bakup",
		"slot2.json.tmpX", "slot2.json.orig", "slot2.json~",
		"slot2.json.2026-11-20", "slot2.jsonx", "slot20.json", "slot2.json.",
	]
	for name in rejected:
		assert_true(SaveSystem.parse_slot_file(String(name), SLOT).is_empty(), "rejects %s" % name)


func test_case_variants_parse_and_stay_distinct() -> void:
	assert_eq(String(SaveSystem.parse_slot_file("SLOT2.JSON", SLOT).get("role", "")), "primary")
	assert_eq(String(SaveSystem.parse_slot_file("Slot2.Json.Bak.2", SLOT).get("role", "")), "backup")
	assert_eq(String(SaveSystem.parse_slot_file("SLOT2.JSON.TMP.W", SLOT).get("role", "")), "temp")
	var ordered := SaveSystem._classify_names(["SLOT2.JSON", "slot2.json"], SLOT)
	assert_eq(ordered.size(), 2, "differently cased names are two files, not one")
	assert_eq(String(ordered[0]["name"]), "slot2.json", "the exact spelling is read first")


func test_stray_files_are_not_slot_files() -> void:
	var payload := _payload(10, 100)
	for suffix in [".notes", ".orig", "x", ".2026-11-20", ".bak.101", ".bak.manual"]:
		_write(_path(String(suffix)), payload)
	assert_eq(SaveSystem.slot_files(SLOT, CAMPAIGN), [], "no stray name is a slot file")
	assert_false(SaveSystem.has_artifacts(SLOT, CAMPAIGN))
	assert_true(_row().is_empty(), "a stray file does not list the slot")
	assert_eq(Panels._save_info(SLOT), "empty")
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_string_contains(String(loaded.get("message", "")), "No save in")


func test_stray_files_do_not_block_the_legacy_fallback() -> void:
	_write(_path(".notes"), _payload(10, 100))
	var legacy := _payload(999, 100)
	legacy.erase("campaign_id")
	_write(SaveSystem.path_for(SLOT), legacy)
	assert_eq(_load_gold(), 999)


func test_deleting_a_slot_keeps_stray_files() -> void:
	# Payloads are built first: _payload() writes and deletes the slot itself.
	var primary := _payload(10, 100)
	var backup := _payload(20, 200)
	var archive := _payload(30, 300)
	_write(_path(), primary)
	_write(_path(".bak.2"), backup)
	var stray := _path(".2026-11-20")
	_write(stray, archive)
	assert_true(SaveSystem.delete_save(SLOT))
	assert_false(FileAccess.file_exists(_path()))
	assert_false(FileAccess.file_exists(_path(".bak.2")))
	assert_true(FileAccess.file_exists(stray), "a hand-made archive is not the slot's to delete")


func test_a_case_variant_primary_is_discovered() -> void:
	var variant := SaveSystem.campaign_dir(CAMPAIGN).path_join("SLOT2.JSON")
	_write(variant, _payload(10, 100))
	assert_eq(_load_gold(), 10)
	assert_true(SaveSystem.delete_save(SLOT))
	assert_false(FileAccess.file_exists(variant), "deletion removes the entry it found")


func test_damaged_only_slot_is_not_reported_as_empty() -> void:
	_write_text(_path(".bak"), "not json")
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_eq(String(loaded.get("reason", "")), "corrupt")
	assert_string_contains(String(loaded.get("message", "")), "corrupt")
	assert_false(String(loaded.get("message", "")).contains("No save in"))
	var row := _row()
	assert_false(bool(row.get("readable", true)), "the row is not offered as loadable")
	assert_eq(String(row.get("source", "")), "backup")
	assert_string_contains(Panels._save_info(SLOT), "damaged")
	assert_false(Panels._save_info(SLOT) == "empty")


func test_incompatible_only_slot_is_unreadable_not_empty() -> void:
	_write(_path(".bak"), _payload(10, 100, CAMPAIGN, -1, 99))
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_eq(String(loaded.get("reason", "")), "unsupported_version")
	assert_string_contains(String(loaded.get("message", "")), "incompatible version")
	assert_false(String(loaded.get("message", "")).contains("No save in"))
	assert_false(bool(_row().get("readable", true)))
	assert_string_contains(Panels._save_info(SLOT), "unreadable")
	assert_false(Panels._save_info(SLOT).contains("damaged"))


func test_foreign_only_slot_names_the_campaign_without_switching() -> void:
	_write(_path(".bak.2"), _payload(10, 100, "some_other_campaign"))
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_eq(String(loaded.get("reason", "")), "campaign_mismatch")
	assert_string_contains(String(loaded.get("message", "")), "belongs to campaign")
	assert_string_contains(String(loaded.get("message", "")), "some_other_campaign")
	assert_eq(Game.campaign_id, CAMPAIGN)


func test_content_mismatch_only_slot_reports_the_content_refusal() -> void:
	var payload := _payload(10, 100, CAMPAIGN, Game.content_version + 1)
	_write(_path(".tmp"), payload)
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_eq(String(loaded.get("reason", "")), "content_mismatch")
	assert_string_contains(String(loaded.get("message", "")), "content version")
	assert_string_contains(String(loaded.get("message", "")), "The save was not modified.")


func test_invalid_only_slot_reports_its_validation_message() -> void:
	var broken := _payload(10, 100)
	broken["party"] = []
	_write(_path(".tmp.2"), broken)
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_eq(String(loaded.get("reason", "")), "invalid")
	assert_string_contains(String(loaded.get("message", "")), "no valid party members")


func test_mixed_failures_prefer_the_incompatible_one() -> void:
	_write_text(_path(".bak"), "not json")
	_write(_path(".bak.2"), _payload(10, 100, CAMPAIGN, -1, 99))
	var loaded := Game.load_game(SLOT)
	assert_false(bool(loaded.get("ok", false)))
	assert_eq(String(loaded.get("reason", "")), "unsupported_version")


func test_equal_timestamps_resolve_by_canonical_then_name() -> void:
	var canonical := _payload(10, 900)
	var numbered := _payload(60, 900)
	_write(_path(".bak"), canonical)
	_write(_path(".bak.2"), numbered)
	assert_eq(_load_gold(), 10, "the canonical name wins a tie")
	_clean()
	var second := _payload(20, 900)
	var tenth := _payload(70, 900)
	_write(_path(".bak.2"), second)
	_write(_path(".bak.10"), tenth)
	assert_eq(_load_gold(), 70, "otherwise the lexicographically first name wins")
	_clean()
	var temp := _payload(30, 900)
	var numbered_temp := _payload(80, 900)
	_write(_path(".tmp"), temp)
	_write(_path(".tmp.2"), numbered_temp)
	assert_eq(_load_gold(), 30, "the canonical temp wins its own tie")


func test_missing_saved_unix_is_the_oldest() -> void:
	var old := _payload(10, 900)
	old.erase("saved_unix")
	var stamped := _payload(60, 500)
	_write(_path(".bak"), old)
	_write(_path(".bak.2"), stamped)
	assert_eq(_load_gold(), 60, "a copy without a timestamp loses to any timestamp")
	_clean()
	var first := _payload(10, 900)
	first.erase("saved_unix")
	var second := _payload(20, 900)
	second.erase("saved_unix")
	_write(_path(".bak"), first)
	_write(_path(".bak.2"), second)
	assert_eq(_load_gold(), 10, "two missing timestamps tie on the canonical name")


func test_primary_refusals_are_unchanged() -> void:
	_write(_path(), _payload(10, 100, CAMPAIGN, -1, 99))
	var incompatible := Game.load_game(SLOT)
	assert_eq(String(incompatible.get("message", "")), "Save slot2 was written by an incompatible version (99.0).")
	_clean()
	_write_text(_path(), "not json")
	var corrupt := Game.load_game(SLOT)
	assert_eq(String(corrupt.get("message", "")), "Save slot2 is corrupt (invalid JSON).")
	_clean()
	_write(_path(), _payload(10, 100, CAMPAIGN, Game.content_version + 1))
	var stored: Dictionary = JSON.parse_string(_text(_path()))
	var parsed_content: Variant = stored["content_version"]
	var content := Game.load_game(SLOT)
	assert_eq(
		String(content.get("message", "")),
		"Save 'slot2' was made for campaign content version %s; the installed campaign is version %d. The save was not modified." % ["%s" % [parsed_content], Game.content_version]
	)


func test_an_unreadable_slot_is_tagged_in_the_load_list() -> void:
	_write(_path(".bak"), _payload(10, 100, CAMPAIGN, -1, 99))
	var panel := Panels.saves("load", func() -> void: pass)
	add_child_autofree(panel)
	await wait_frames(1)
	var texts: Array = []
	for node in panel.find_children("*", "Label", true, false):
		texts.append(String((node as Label).text))
	assert_true(texts.any(func(text: String) -> bool: return text.contains("(unreadable)")), "the row is tagged: %s" % [texts])
