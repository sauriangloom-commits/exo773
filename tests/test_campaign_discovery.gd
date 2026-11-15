extends GutTest

## User campaign discovery (user://campaigns).
##
## A package the author can no longer read must not vanish silently: the campaign
## list skips it, but the reason (invalid JSON with a line number, id/folder
## mismatch, missing manifest, illegal folder name) has to survive into the
## registry errors that the validator, the creator and the player log show.

const BROKEN := "qa_discovery_broken"
const MISMATCH := "qa_discovery_mismatch"
const NOMANIFEST := "qa_discovery_nomanifest"
const GOOD := "qa_discovery_good"
const BAD_NAME := "QA Discovery Bad Name"


func after_each() -> void:
	_cleanup(BROKEN)
	_cleanup(MISMATCH)
	_cleanup(NOMANIFEST)
	_cleanup(GOOD)
	_cleanup(BAD_NAME)
	CampaignStore.delete_user_campaign(BROKEN)
	CampaignStore.delete_user_campaign(MISMATCH)
	CampaignStore.delete_user_campaign(NOMANIFEST)
	CampaignStore.delete_user_campaign(GOOD)
	CampaignStore.scan_errors.clear()
	Game.refresh_campaigns()


func _make_dir(campaign_id: String) -> String:
	var path := CampaignStore.USER_ROOT.path_join(campaign_id)
	DirAccess.make_dir_recursive_absolute(path)
	return path


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file, "could not write %s" % path)
	if file != null:
		file.store_string(text)
		file.close()


func _cleanup(dir_name: String) -> void:
	var path := CampaignStore.USER_ROOT.path_join(dir_name)
	if not DirAccess.dir_exists_absolute(path):
		return
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(String(file_name))))
	for sub in DirAccess.get_directories_at(path):
		var sub_path := path.path_join(String(sub))
		for inner in DirAccess.get_files_at(sub_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(sub_path.path_join(String(inner))))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sub_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _listed(campaign_id: String) -> bool:
	for manifest in CampaignStore.list_user_campaigns():
		if String(Dictionary(manifest).get("id", "")) == campaign_id:
			return true
	return false


func _errors_text() -> String:
	return "\n".join(PackedStringArray(CampaignStore.scan_errors))


func test_a_package_with_invalid_json_is_skipped_with_a_line_number() -> void:
	var path := _make_dir(BROKEN)
	_write(path.path_join("campaign.json"), "{\n\t\"id\": \"%s\",\n\tthis is not json\n}\n" % BROKEN)
	assert_false(_listed(BROKEN), "a package that cannot be parsed is not listed")
	var text := _errors_text()
	assert_string_contains(text, "campaign.json is not valid JSON")
	assert_string_contains(text, "line", "the diagnostic names the offending line")
	assert_string_contains(text, BROKEN)


func test_the_registry_carries_the_scan_error_so_it_reaches_the_validator() -> void:
	var path := _make_dir(BROKEN)
	_write(path.path_join("campaign.json"), "{ not json ")
	CampaignStore.list_user_campaigns()
	var db := CampaignDB.new()
	db.load_registry()
	var found := false
	for message in db.errors:
		if String(message).contains(BROKEN) and String(message).contains("not valid JSON"):
			found = true
	assert_true(found, "the campaign registry reports why the package is missing")


func test_an_id_that_does_not_match_its_folder_is_reported() -> void:
	var path := _make_dir(MISMATCH)
	_write(
		path.path_join("campaign.json"),
		JSON.stringify({"format_version": 1, "id": "some_other_id", "title": "Mismatch"}),
	)
	assert_false(_listed(MISMATCH), "a mismatched package is not listed under either id")
	var text := _errors_text()
	assert_string_contains(text, "does not match its folder")
	assert_string_contains(text, "some_other_id")


func test_a_folder_without_a_manifest_is_reported() -> void:
	_make_dir(NOMANIFEST)
	assert_false(_listed(NOMANIFEST))
	assert_string_contains(_errors_text(), "has no campaign.json")


func test_an_illegal_folder_name_is_reported() -> void:
	_make_dir(BAD_NAME)
	assert_false(_listed(BAD_NAME))
	assert_string_contains(_errors_text(), "not a valid campaign id")


func test_fixing_the_manifest_restores_the_package_without_a_restart() -> void:
	var path := _make_dir(BROKEN)
	_write(path.path_join("campaign.json"), "{ broken ")
	assert_false(_listed(BROKEN))
	assert_ne(CampaignStore.scan_errors, [], "the first scan reports the problem")
	# The author repairs the file; the next scan lists the package again and the
	# stale diagnostic must not survive.
	_write(
		path.path_join("campaign.json"),
		JSON.stringify({"format_version": 1, "id": BROKEN, "title": "Repaired"}),
	)
	assert_true(_listed(BROKEN), "the repaired package is discovered again")
	assert_eq(CampaignStore.scan_errors, [], "the earlier diagnostic is cleared")


func test_a_valid_package_lists_cleanly_and_reports_nothing() -> void:
	var created := CampaignStore.create("Discovery QA", GOOD)
	assert_true(bool(created.get("ok", false)), String(created.get("message", "")))
	assert_true(_listed(GOOD), "the readable package is listed")
	assert_eq(CampaignStore.scan_errors, [], "a healthy scan reports nothing")
