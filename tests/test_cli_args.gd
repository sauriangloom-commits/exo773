extends GutTest

## The application command line is refused before any screen is presented.
##
## These tests pin the classification only: `Main._ready()` prints the returned
## message and quits with `UNKNOWN_ARG_EXIT_CODE`, which is not called here
## because quitting would stop the test runner. The real process exit status is
## verified in the exported candidate and recorded in docs/TEST_REPORT.md.

const MainScript := preload("res://src/main.gd")


func test_no_arguments_is_accepted() -> void:
	assert_eq(MainScript.application_arg_error(PackedStringArray()), "", "a normal launch is not refused")


func test_bare_word_is_ignored_as_before() -> void:
	# The dispatch in _ready() has always ignored text without a leading dash.
	assert_eq(MainScript.application_arg_error(PackedStringArray(["notes.txt"])), "")


func test_unknown_option_is_refused_and_named() -> void:
	var message := MainScript.application_arg_error(PackedStringArray(["--bogus-option"]))
	assert_ne(message, "", "an unknown option is an error")
	assert_true(message.contains("--bogus-option"), "the message names the offender")
	assert_true(message.contains("Unknown application option"), "the message says what is wrong")


func test_reported_validate_content_typo_is_refused_with_alternatives() -> void:
	var message := MainScript.application_arg_error(PackedStringArray(["--validate-content"]))
	assert_ne(message, "", "--validate-content does not exist and must not start the game")
	assert_true(message.contains("--validate-content"), "the message names the typo")
	assert_true(message.contains("--validate-campaigns"), "the message suggests the real validator")
	assert_true(message.contains("--validate-diagnostics"), "the message suggests the real validator")


func test_every_unknown_option_is_listed() -> void:
	var message := MainScript.application_arg_error(
		PackedStringArray(["--demo", "--nope", "--also-nope"])
	)
	assert_true(message.contains("--nope"), "first unknown option named")
	assert_true(message.contains("--also-nope"), "second unknown option named")
	assert_false(message.contains("  --demo\n"), "a supported option is not reported as unknown")


func test_valid_validator_commands_are_accepted() -> void:
	for flag in ["--list-campaigns", "--validate-campaigns", "--validate-diagnostics"]:
		assert_eq(
			MainScript.application_arg_error(PackedStringArray([flag])),
			"",
			"%s is a supported command" % flag
		)


func test_representative_existing_probes_are_accepted() -> void:
	# One demo per family plus the exported probes the QA scripts call.
	var probes := [
		"--demo",
		"--demo-dialogue",
		"--demo-combat",
		"--demo-town-square",
		"--demo-trip",
		"--demo-cleave",
		"--demo-creator",
		"--demo-party",
		"--trip-probe",
		"--cleave-probe",
		"--party-limits-probe",
		"--party-layout-probe",
		"--campaign-list-probe",
		"--intro-layout-probe",
		"--intro-click",
		"--quest-log-probe",
		"--creator-acceptance-probe",
		"--pending-edit-probe",
		"--training-probe",
	]
	for flag in probes:
		assert_eq(
			MainScript.application_arg_error(PackedStringArray([flag])),
			"",
			"%s is a supported probe" % flag
		)


func test_value_options_are_accepted_with_their_value() -> void:
	var options := [
		"--campaign=ashwick_ferry",
		"--campaign-probe=ashwick_ferry",
		"--capture=explore",
		"--capture-dir=C:/tmp/shots",
		"--cleave-scenario=cleave",
		"--creator-focus=dialogue",
		"--probe-size=1280x720",
		"--probe-text-scale=1.6",
		"--text-scale=1.4",
		"--trip-scenario=success",
		"--trip-shots=C:/tmp/shots",
	]
	for option in options:
		assert_eq(
			MainScript.application_arg_error(PackedStringArray([option])),
			"",
			"%s is a supported option form" % option
		)


func test_value_option_without_a_value_is_refused() -> void:
	# The bare form is never read by the dispatch, so accepting it would silently
	# ignore the caller's intent.
	for option in ["--probe-size", "--capture", "--trip-shots"]:
		assert_ne(
			MainScript.application_arg_error(PackedStringArray([option])),
			"",
			"bare %s is not a usable option" % option
		)


func test_combined_realistic_command_line_is_accepted() -> void:
	var args := PackedStringArray(
		["--demo-trip", "--trip-probe", "--trip-scenario=success", "--trip-shots=C:/tmp/shots"]
	)
	assert_eq(MainScript.application_arg_error(args), "", "a real probe command line stays valid")


func test_registry_entries_are_unique() -> void:
	var seen := {}
	for flag in MainScript.APP_FLAGS:
		assert_false(seen.has(flag), "%s appears once" % flag)
		seen[flag] = true
	var value_seen := {}
	for option in MainScript.APP_VALUE_OPTIONS:
		assert_false(value_seen.has(option), "%s appears once" % option)
		assert_false(seen.has(option), "%s is not also a bare flag" % option)
		value_seen[option] = true


func test_every_registered_option_is_accepted() -> void:
	for flag in MainScript.APP_FLAGS:
		assert_eq(
			MainScript.application_arg_error(PackedStringArray([flag])),
			"",
			"registered flag %s is accepted" % flag
		)
	for option in MainScript.APP_VALUE_OPTIONS:
		assert_eq(
			MainScript.application_arg_error(PackedStringArray([option + "=x"])),
			"",
			"registered value option %s is accepted" % option
		)


func test_refusal_exit_status_is_distinct_from_success_and_validation_failure() -> void:
	assert_eq(MainScript.UNKNOWN_ARG_EXIT_CODE, 2, "an unusable invocation exits 2")
	assert_ne(MainScript.UNKNOWN_ARG_EXIT_CODE, 0, "never reported as success")
	assert_ne(MainScript.UNKNOWN_ARG_EXIT_CODE, 1, "distinct from a validation or probe failure")
