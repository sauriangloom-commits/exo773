class_name ContentSpec
extends RefCounted

## One registry for the authored effect and condition vocabulary.
##
## Every effect or condition type a writer may put in JSON is declared here with
## the fields it requires and the content table each id must exist in. ContentDB
## validates against this table, and GameSession's runtime handlers reject the
## same vocabulary, so a new type is added in exactly one declaration plus its
## handler. Validation errors are complete sentences that the caller prefixes
## with its own location label ("dialogue 'miruna' node 'root' ...").
##
## Adding a type:
## 1. Add its row below (fields + lookups).
## 2. Add the runtime branch in GameSession.apply_effects / check_conditions.
## 3. Add a focused test in tests/test_extensibility.gd.
## 4. Document it in docs/AUTHORING_GUIDE.md.

const EFFECTS := {
	"set_flag": {
		"fields": [{"name": "flag", "kind": "string", "required": true}],
		"lookups": [],
	},
	"clear_flag": {
		"fields": [{"name": "flag", "kind": "string", "required": true}],
		"lookups": [],
	},
	"quest_start": {
		"fields": [{"name": "quest", "kind": "string", "required": true}],
		"lookups": [{"field": "quest", "table": "quests", "label": "quest"}],
	},
	"give_item": {
		"fields": [
			{"name": "item", "kind": "string", "required": true},
			{"name": "qty", "kind": "int", "required": false},
			{"name": "only_if_missing", "kind": "bool", "required": false},
		],
		"lookups": [{"field": "item", "table": "items", "label": "item"}],
	},
	"remove_item": {
		"fields": [
			{"name": "item", "kind": "string", "required": true},
			{"name": "qty", "kind": "int", "required": false},
		],
		"lookups": [{"field": "item", "table": "items", "label": "item"}],
	},
	"xp": {
		"fields": [{"name": "amount", "kind": "int", "required": true}],
		"lookups": [],
	},
	"gold": {
		"fields": [{"name": "amount", "kind": "int", "required": true}],
		"lookups": [],
	},
	"narration": {
		"fields": [{"name": "text", "kind": "string", "required": true}],
		"lookups": [],
	},
	"heal_party": {
		"fields": [{"name": "amount", "kind": "int", "required": false}],
		"lookups": [],
	},
	"start_combat": {
		"fields": [{"name": "encounter", "kind": "string", "required": true}],
		"lookups": [{"field": "encounter", "table": "encounters", "label": "encounter"}],
	},
	"open_door": {
		"fields": [{"name": "door", "kind": "string", "required": true}],
		"lookups": [],
	},
	"remove_object": {
		"fields": [{"name": "object", "kind": "string", "required": true}],
		"lookups": [],
	},
	"rest": {"fields": [], "lookups": []},
	"travel": {
		"fields": [
			{"name": "area", "kind": "string", "required": true},
			{"name": "pos", "kind": "array", "required": true},
			{"name": "facing", "kind": "int", "required": false},
		],
		"lookups": [{"field": "area", "table": "areas", "label": "area"}],
	},
}

const CONDITIONS := {
	"flag": {
		"fields": [
			{"name": "flag", "kind": "string", "required": true},
			{"name": "value", "kind": "bool", "required": false},
		],
		"lookups": [],
	},
	"not_flag": {
		"fields": [{"name": "flag", "kind": "string", "required": true}],
		"lookups": [],
	},
	"quest_active": {
		"fields": [{"name": "quest", "kind": "string", "required": true}],
		"lookups": [{"field": "quest", "table": "quests", "label": "quest"}],
	},
	"quest_complete": {
		"fields": [{"name": "quest", "kind": "string", "required": true}],
		"lookups": [{"field": "quest", "table": "quests", "label": "quest"}],
	},
	"has_item": {
		"fields": [{"name": "item", "kind": "string", "required": true}],
		"lookups": [{"field": "item", "table": "items", "label": "item"}],
	},
	"skill_at_least": {
		"fields": [
			{"name": "skill", "kind": "skill", "required": true},
			{"name": "value", "kind": "int", "required": true},
		],
		"lookups": [],
	},
}


static func has_effect_type(type: String) -> bool:
	return EFFECTS.has(type)


static func has_condition_type(type: String) -> bool:
	return CONDITIONS.has(type)


static func effect_types() -> Array[String]:
	var result: Array[String] = []
	for key in EFFECTS.keys():
		result.append(String(key))
	result.sort()
	return result


static func condition_types() -> Array[String]:
	var result: Array[String] = []
	for key in CONDITIONS.keys():
		result.append(String(key))
	result.sort()
	return result


## Validates one authored effect. `content` may be null, in which case only the
## shape is checked and identifier references are skipped (used by tests and by
## tools that have no content loaded).
static func validate_effect(effect: Dictionary, content = null) -> Array[String]:
	return _validate(effect, EFFECTS, "effect", content)


static func validate_condition(condition: Dictionary, content = null) -> Array[String]:
	return _validate(condition, CONDITIONS, "condition", content)


static func validate_effect_list(effects: Array, content = null) -> Array[String]:
	var errors: Array[String] = []
	for i in effects.size():
		var effect: Variant = effects[i]
		if not effect is Dictionary:
			errors.append("effect %d is malformed." % (i + 1))
			continue
		errors.append_array(validate_effect(effect, content))
	return errors


static func validate_condition_list(conditions: Array, content = null) -> Array[String]:
	var errors: Array[String] = []
	for i in conditions.size():
		var condition: Variant = conditions[i]
		if not condition is Dictionary:
			errors.append("condition %d is malformed." % (i + 1))
			continue
		errors.append_array(validate_condition(condition, content))
	return errors


static func _validate(entry: Dictionary, table: Dictionary, kind: String, content) -> Array[String]:
	var errors: Array[String] = []
	var type := String(entry.get("type", ""))
	if not table.has(type):
		errors.append("has unknown %s type '%s'." % [kind, type])
		return errors
	var spec: Dictionary = table[type]
	for raw_field in Array(spec.get("fields", [])):
		var field: Dictionary = raw_field
		var field_name := String(field.get("name", ""))
		var field_kind := String(field.get("kind", "string"))
		if not entry.has(field_name):
			if bool(field.get("required", false)):
				errors.append("%s '%s' is missing '%s'." % [kind, type, field_name])
			continue
		var value: Variant = entry[field_name]
		if field_kind == "int" and not (value is int or value is float):
			errors.append("%s '%s' field '%s' must be a number." % [kind, type, field_name])
		elif field_kind == "bool" and not value is bool:
			errors.append("%s '%s' field '%s' must be true or false." % [kind, type, field_name])
		elif field_kind == "array" and not value is Array:
			errors.append("%s '%s' field '%s' must be an array." % [kind, type, field_name])
		elif field_kind == "skill" and not Skills.exists(String(value)):
			errors.append("%s '%s' uses unknown skill '%s'." % [kind, type, value])
		elif field_kind == "string" and String(value).strip_edges() == "":
			if bool(field.get("required", false)):
				errors.append("%s '%s' field '%s' is empty." % [kind, type, field_name])
	for raw_lookup in Array(spec.get("lookups", [])):
		var lookup: Dictionary = raw_lookup
		var id := String(entry.get(String(lookup.get("field", "")), ""))
		if id == "" or content == null:
			continue
		var referenced: Variant = content.get(String(lookup.get("table", "")))
		if not referenced is Dictionary:
			continue
		if not Dictionary(referenced).has(id):
			errors.append(
				"%s '%s' references missing %s '%s'."
				% [kind, type, String(lookup.get("label", "entry")), id]
			)
	return errors
