extends GutTest

## Batch 4a of docs/LEVEL_UP_PLAN.md section 14.7: the level-up screen may call
## exactly three things on the level-up engine - `LevelChoices.choices` (what may
## be chosen), `LevelChoices.validate` (may this draft be applied) and
## `LevelUp.apply` (the only mutation). Staging belongs to the choice module, so a
## screen that staged would be a second authority on what a legal draft is.
##
## Both tests are source-text guards. Their limit is stated here because it is a
## real one: a call built from a string, or reached through an alias, is invisible
## to them. The behavioural side of the same coin is
## `tests/test_level_up_screen.gd:test_confirm_applies_through_validate_and_apply`
## and `:test_apply_is_not_called_when_validate_refuses`, so a screen that went
## around the surface fails on behaviour even if it passes these.

const SCREEN := "res://src/ui/level_up_screen.gd"
const STAGING_OWNER := "res://src/core/level_choices.gd"


func _text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


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
func test_the_screen_calls_only_choices_validate_and_apply() -> void:
	var text := _text(SCREEN)
	assert_ne(text, "", "the screen file exists")
	assert_true(text.contains("LevelChoices.choices"), "the screen calls LevelChoices.choices")
	assert_true(text.contains("LevelChoices.validate"), "the screen calls LevelChoices.validate")
	assert_true(text.contains("LevelUp.apply"), "the screen calls LevelUp.apply")
	assert_false(text.contains("LevelUp.stage"), "the screen never stages")
	assert_false(
		text.contains("LevelUp.required_choices"),
		"the screen never lists the required choices itself",
	)


# 2
func test_no_shipped_file_stages_a_level_outside_the_choice_module() -> void:
	var staging: Array[String] = []
	_staging_files("res://src", staging)
	_staging_files("res://tools", staging)
	staging.sort()
	assert_eq(staging, [STAGING_OWNER], "only the choice module stages")
	assert_false(staging.has(SCREEN), "src/ui/level_up_screen.gd does not stage")
