extends GutTest

## Story-file diagnostics and recovery for a user campaign package.
##
## The package reader must name the damaged file and the parser line for syntax
## errors, distinguish that from valid JSON of the wrong shape and from a missing
## referenced file, and never rewrite or partially load the package. Repairing the
## file in place clears the diagnostic on the next validation.

const ID := "qa_story_diag"
const BROKEN_AREA := "{\n\t\"id\": \"area_01\",\n\tthis is not json\n}\n"

var area_path: String
var dialogue_path: String


func before_each() -> void:
	CampaignStore.delete_user_campaign(ID)
	Game.refresh_campaigns()
	var created := CampaignStore.create("Story diagnostics", ID)
	assert_true(bool(created.get("ok", false)), String(created.get("message", "")))
	Game.refresh_campaigns()
	area_path = CampaignStore.package_dir(ID).path_join("areas").path_join("area_01.json")
	dialogue_path = CampaignStore.package_dir(ID).path_join("dialogue").path_join("intro.json")


func after_each() -> void:
	CampaignStore.delete_user_campaign(ID)
	Game.refresh_campaigns()


func _write(path: String, text: String) -> void:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file, "could not write %s" % path)
	if file != null:
		file.store_string(text)
		file.close()


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _find(diagnostics: Array, code: String) -> Dictionary:
	for raw in diagnostics:
		if raw is Dictionary and String(Dictionary(raw).get("code", "")) == code:
			return Dictionary(raw)
	return {}


func _messages(errors: Array) -> String:
	return "\n".join(PackedStringArray(errors))


func test_malformed_area_json_names_the_file_and_parser_line() -> void:
	_write(area_path, BROKEN_AREA)
	var result := Game.validate_campaign(ID)
	assert_false(bool(result.get("ok", false)), "a malformed area makes the package invalid")
	var text := _messages(Array(result.get("errors", [])))
	assert_string_contains(text, "areas/area_01.json")
	assert_string_contains(text, "line 3")
	var diag := _find(Array(result.get("diagnostics", [])), "content.area.syntax")
	assert_false(diag.is_empty(), "structured syntax diagnostic is recorded")
	assert_eq(String(diag.get("campaign", "")), ID)
	assert_eq(String(diag.get("source", "")), "areas/area_01.json")
	assert_eq(String(diag.get("entity_type", "")), "area")
	assert_eq(int(diag.get("line", 0)), 3)
	assert_eq(_read(area_path), BROKEN_AREA, "validation never rewrites the damaged file")


func test_malformed_dialogue_json_names_the_file_and_parser_line() -> void:
	_write(dialogue_path, "{\n\t\"id\": \"intro\",\n\tbroken\n}\n")
	var result := Game.validate_campaign(ID)
	assert_false(bool(result.get("ok", false)))
	var text := _messages(Array(result.get("errors", [])))
	assert_string_contains(text, "dialogue/intro.json")
	assert_string_contains(text, "line 3")
	var diag := _find(Array(result.get("diagnostics", [])), "content.dialogue.syntax")
	assert_false(diag.is_empty())
	assert_eq(String(diag.get("source", "")), "dialogue/intro.json")
	assert_eq(String(diag.get("entity_type", "")), "dialogue")
	assert_eq(int(diag.get("line", 0)), 3)


func test_valid_json_with_the_wrong_shape_is_not_reported_as_syntax() -> void:
	_write(area_path, "[]\n")
	var result := Game.validate_campaign(ID)
	assert_false(bool(result.get("ok", false)))
	var diag := _find(Array(result.get("diagnostics", [])), "content.area.shape")
	assert_false(diag.is_empty(), "shape has its own diagnostic code")
	assert_eq(int(diag.get("line", 0)), 0, "no line is invented for a semantic shape problem")
	var text := _messages(Array(result.get("errors", [])))
	assert_false(text.contains("not valid JSON"), "valid JSON is not called a syntax error")
	assert_string_contains(text, "areas/area_01.json")


func test_a_dialogue_that_parses_but_is_not_an_object_is_a_shape_error() -> void:
	_write(dialogue_path, "[]\n")
	var result := Game.validate_campaign(ID)
	assert_false(bool(result.get("ok", false)))
	var diag := _find(Array(result.get("diagnostics", [])), "content.dialogue.shape")
	assert_false(diag.is_empty())
	assert_eq(String(diag.get("source", "")), "dialogue/intro.json")
	assert_eq(int(diag.get("line", 0)), 0)


func test_a_referenced_area_file_that_is_missing_is_reported_by_filename() -> void:
	_write(area_path, JSON.stringify({"id": "area_01", "width": 9, "height": 9, "rows": []}))
	_write(
		CampaignStore.package_dir(ID).path_join("areas").path_join("_manifest.json"),
		JSON.stringify({"areas": ["area_01", "missing_area"]}),
	)
	var result := Game.validate_campaign(ID)
	assert_false(bool(result.get("ok", false)))
	var diag := _find(Array(result.get("diagnostics", [])), "content.area.missing")
	assert_false(diag.is_empty(), "missing referenced story file has its own code")
	assert_eq(String(diag.get("source", "")), "areas/missing_area.json")
	assert_eq(String(diag.get("entity_id", "")), "missing_area")


func test_a_broken_package_never_replaces_the_active_campaign() -> void:
	Game.load_campaign("ravenloft_demo")
	var active_id := Game.campaign_id
	var area_count := Game.content.areas.size()
	_write(area_path, BROKEN_AREA)
	var loaded := Game.load_campaign(ID)
	assert_false(bool(loaded.get("ok", false)), "the broken package is refused")
	assert_eq(Game.campaign_id, active_id, "the active campaign is unchanged")
	assert_eq(Game.content.areas.size(), area_count, "no partial live-state replacement")
	assert_true(Game.load_campaign("ravenloft_demo").get("ok", true), "the valid campaign still loads")
	Game.load_campaign("ravenloft_demo")


func test_the_creator_refuses_a_damaged_story_file_with_its_line() -> void:
	_write(dialogue_path, "{\n\t\"id\": \"intro\",\n\tbroken\n}\n")
	var loaded := CampaignStore.load_package(ID)
	assert_false(bool(loaded.get("ok", false)), "creator refuses a package it cannot read")
	var message := String(loaded.get("message", ""))
	assert_string_contains(message, "intro.json")
	assert_string_contains(message, "line")
	assert_eq(_read(dialogue_path), "{\n\t\"id\": \"intro\",\n\tbroken\n}\n", "refusal leaves bytes untouched")


func test_repair_clears_the_error_and_does_not_leak_into_another_package() -> void:
	var original := _read(area_path)
	_write(area_path, BROKEN_AREA)
	assert_false(bool(Game.validate_campaign(ID).get("ok", true)))
	_write(area_path, original)
	var repaired := Game.validate_campaign(ID)
	assert_true(bool(repaired.get("ok", false)), "the repaired package validates")
	assert_eq(Array(repaired.get("diagnostics", [])), [], "no stale diagnostic survives")
	var other := Game.validate_campaign("hollow_lantern")
	assert_true(bool(other.get("ok", false)), "another package is unaffected")
	assert_eq(Array(other.get("diagnostics", [])), [], "no error leaked into another package")


func test_both_diagnostic_surfaces_agree() -> void:
	var original := _read(area_path)
	_write(area_path, BROKEN_AREA)
	var validation := Game.validate_campaign(ID)
	var diagnosis := Game.diagnose_campaign(ID)
	assert_eq(bool(validation.get("ok", false)), bool(diagnosis.get("ok", false)))
	assert_false(bool(validation.get("ok", true)))
	var diag := _find(Array(diagnosis.get("diagnostics", [])), "content.area.syntax")
	assert_false(diag.is_empty(), "the structured surface keeps the code and line")
	assert_eq(String(diag.get("campaign", "")), ID)
	_write(area_path, original)
	var repaired := Game.validate_campaign(ID)
	assert_true(bool(repaired.get("ok", false)))
	assert_true(bool(Game.diagnose_campaign(ID).get("ok", false)))
