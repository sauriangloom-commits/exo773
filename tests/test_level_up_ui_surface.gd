extends GutTest

## Batch 4a of docs/LEVEL_UP_PLAN.md section 14.7: the UI's call surface on the
## level-up engine.
##
## The screen and the party sheet may read; only `LevelUp.apply` writes, and it is
## called once, after `LevelChoices.validate` has agreed. The allowed members are
## listed as data, so the guard is a closed list: a new engine call fails the test
## instead of passing unnoticed. It is deliberately not "these three strings must
## appear", which was this section's first wording and would have made the shipped
## screen - which also reads `LevelUp.preview` and lists `LevelUp.ABILITIES` - a
## violation of its own plan.
##
## All three tests are source-text guards, and their limit is stated here because it
## is a real one: they read names on non-comment lines, so a call built from a
## string, reached through an alias, or hidden on a comment's line is invisible to
## them. Strings are counted, which only makes the list stricter. The behavioural
## side of the same coin is in `tests/test_level_up_screen.gd`:
## `test_confirm_applies_through_validate_and_apply`,
## `test_apply_is_not_called_when_validate_refuses` and
## `test_a_confirm_writes_only_the_intended_character_fields`.

const SCREEN := "res://src/ui/level_up_screen.gd"
const SHEET := "res://src/ui/panels.gd"
const STAGING_OWNER := "res://src/core/level_choices.gd"

## What the screen names: four reads and the one writer.
const SCREEN_SURFACE := [
	"LevelChoices.choices",
	"LevelChoices.validate",
	"LevelUp.ABILITIES",
	"LevelUp.apply",
	"LevelUp.preview",
]

## What the sheet names: one read-only question.
const SHEET_SURFACE := ["LevelUp.eligibility"]

## What no shipped UI file may name. Staging belongs to the choice module, and the
## required-choice list is that module's vocabulary; a screen that kept its own
## copy could drift from `validate`.
const FORBIDDEN := ["LevelUp.stage", "LevelUp.required_choices"]


func _text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


## Every `LevelUp.<member>` and `LevelChoices.<member>` on a non-comment line, in
## source order, without duplicates. Comment lines are skipped so a module's own
## documentation can name the surface without satisfying the guard.
func _engine_calls(text: String) -> Array[String]:
	var calls: Array[String] = []
	var regex := RegEx.create_from_string("(LevelUp|LevelChoices)\\.[A-Za-z_]+")
	for line in text.split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		for found in regex.search_all(line):
			var name := found.get_string()
			if not calls.has(name):
				calls.append(name)
	calls.sort()
	return calls


## Every shipped `.gd` under the two directories a level-up caller could live in,
## whose text names the staging entry point.
func _staging_files(directory: String, out: Array[String]) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	for name in dir.get_files():
		if not name.ends_with(".gd"):
			continue
		var path := "%s/%s" % [directory, name]
		if _text(path).contains("LevelUp.stage"):
			out.append(path)
	for name in dir.get_directories():
		_staging_files("%s/%s" % [directory, name], out)


# 1
func test_the_screen_names_only_the_read_only_surface_and_apply() -> void:
	var text := _text(SCREEN)
	assert_ne(text, "", "the screen file exists")
	var calls := _engine_calls(text)
	assert_eq(calls, SCREEN_SURFACE, "the screen names only the read-only surface and apply")
	for forbidden in FORBIDDEN:
		assert_false(calls.has(forbidden), "the screen never names %s" % forbidden)
	assert_true(calls.has("LevelUp.apply"), "the screen applies through LevelUp.apply")
	assert_true(calls.has("LevelUp.preview"), "the screen reads its numbers from LevelUp.preview")


# 2
func test_the_party_sheet_only_asks_for_eligibility() -> void:
	var text := _text(SHEET)
	assert_ne(text, "", "the party sheet file exists")
	assert_eq(_engine_calls(text), SHEET_SURFACE, "the sheet only asks LevelUp.eligibility")


# 3
func test_no_shipped_file_stages_a_level_outside_the_choice_module() -> void:
	var staging: Array[String] = []
	_staging_files("res://src", staging)
	_staging_files("res://tools", staging)
	staging.sort()
	assert_eq(staging, [STAGING_OWNER], "only the choice module stages")
	assert_false(staging.has(SCREEN), "src/ui/level_up_screen.gd does not stage")
