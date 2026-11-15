extends GutTest

## Foundation contracts rather than feat behaviour.
##
## These pin the shared authored vocabularies and the validation contract that
## every future effect, condition, interaction and narrative consequence uses.
## Adding an authored option should mean: one ContentSpec row, one runtime
## handler, one documentation line, one test here - not an edit in every layer.

var content: ContentDB


func before_all() -> void:
	content = ContentDB.new()
	content.load_all()
	content.validate()


func test_shipped_content_validates_against_the_registry() -> void:
	# Every effect and condition shipped in content/ either resolves through the
	# registry or fails validation here; this is the end-to-end registry proof.
	assert_eq(content.errors, [], "shipped content has no validation errors")


func test_registered_condition_and_effect_validate_cleanly() -> void:
	# Positive control: a data-only addition that only uses registered shapes and
	# existing ids needs no new code anywhere.
	content.errors.clear()
	content._validate_effect_list(
		[
			{"type": "set_flag", "flag": "example_flag", "value": true},
			{"type": "quest_start", "quest": "drowned_bell"},
			{"type": "narration", "text": "(EXAMPLE) foundation contract probe"},
		],
		"example"
	)
	content._validate_dialogue(
		_dialogue_with_condition({"type": "skill_at_least", "skill": "search", "value": 5}),
		"example"
	)
	assert_eq(content.errors, [], "registered shapes with real ids need no new code")


func test_unknown_effect_type_is_a_named_content_error() -> void:
	content.errors.clear()
	content._validate_effect_list([{"type": "teleport_party"}], "example")
	assert_eq(content.errors.size(), 1, "one error for one unknown effect")
	assert_string_contains(
		String(content.errors[0]), "unknown effect type 'teleport_party'", "the type is named"
	)


func test_unknown_condition_type_is_a_named_content_error() -> void:
	content.errors.clear()
	content._validate_dialogue(_dialogue_with_condition({"type": "mood", "mood": "grim"}), "example")
	assert_true(_errors_contain("unknown condition type 'mood'"), "the condition type is named")


func test_effect_requires_its_identifier_fields() -> void:
	content.errors.clear()
	content._validate_effect_list(
		[{"type": "give_item"}, {"type": "travel", "area": "old_gatehouse"}], "example"
	)
	assert_true(_errors_contain("effect 'give_item' is missing 'item'"), "give_item needs its item")
	assert_true(_errors_contain("effect 'travel' is missing 'pos'"), "travel needs its position")


func test_effect_references_must_exist() -> void:
	content.errors.clear()
	content._validate_effect_list(
		[
			{"type": "give_item", "item": "no_such_item"},
			{"type": "quest_start", "quest": "no_such_quest"},
			{"type": "start_combat", "encounter": "no_such_encounter"},
			{"type": "travel", "area": "no_such_area", "pos": [1, 1]},
		],
		"example"
	)
	assert_true(_errors_contain("missing item 'no_such_item'"), "items are checked")
	assert_true(_errors_contain("missing quest 'no_such_quest'"), "quests are checked")
	assert_true(_errors_contain("missing encounter 'no_such_encounter'"), "encounters are checked")
	assert_true(_errors_contain("missing area 'no_such_area'"), "areas are checked")


func test_condition_references_must_exist() -> void:
	content.errors.clear()
	content._validate_dialogue(
		_dialogue_with_condition({"type": "has_item", "item": "no_such_item"}), "example"
	)
	assert_true(_errors_contain("missing item 'no_such_item'"), "items are checked")


func test_condition_skills_must_exist() -> void:
	content.errors.clear()
	content._validate_dialogue(
		_dialogue_with_condition({"type": "skill_at_least", "skill": "basket_weaving", "value": 5}),
		"example"
	)
	assert_true(_errors_contain("unknown skill 'basket_weaving'"), "skills are checked")


func test_every_registry_lookup_is_a_declared_field() -> void:
	# Prevents a registry row from validating an id it never requires, which is
	# how "missing reference" checks silently stop covering a new type.
	for table in [ContentSpec.EFFECTS, ContentSpec.CONDITIONS]:
		for type in table.keys():
			var names: Array = []
			for raw_field in Array(table[type].get("fields", [])):
				names.append(String(raw_field.get("name", "")))
			for raw_lookup in Array(table[type].get("lookups", [])):
				assert_true(
					names.has(String(raw_lookup.get("field", ""))),
					"%s lookup '%s' is also a declared field" % [type, raw_lookup.get("field", "")]
				)


func test_registry_is_a_single_lowercase_snake_case_vocabulary() -> void:
	var expected := [
		"clear_flag",
		"give_item",
		"gold",
		"heal_party",
		"narration",
		"open_door",
		"quest_start",
		"remove_item",
		"remove_object",
		"rest",
		"set_flag",
		"start_combat",
		"travel",
		"xp",
	]
	assert_eq(ContentSpec.effect_types(), expected, "the effect vocabulary is stable")
	assert_eq(
		ContentSpec.condition_types(),
		["flag", "has_item", "not_flag", "quest_active", "quest_complete", "skill_at_least"],
		"the condition vocabulary is stable"
	)


func _dialogue_with_condition(condition: Dictionary) -> Dictionary:
	return {
		"id": "example",
		"start": "root",
		"nodes": {
			"root": {
				"text": "(EXAMPLE DIALOGUE) foundation contract probe",
				"choices": [{"text": "Continue", "next": "", "conditions": [condition]}],
			}
		},
	}


func _errors_contain(needle: String) -> bool:
	return "\n".join(content.errors).contains(needle)
