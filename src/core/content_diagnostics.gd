class_name ContentDiagnostics
extends RefCounted

## One content problem, with explicit location metadata. Producers attach these
## fields directly; consumers never parse the human-readable message.
const ERROR := "error"
const WARNING := "warning"


static func make(code: String, severity: String, message: String, context := {}) -> Dictionary:
	return {
		"code": code,
		"severity": severity,
		"message": message,
		"campaign": String(context.get("campaign", "")),
		"source": String(context.get("source", "")),
		"entity_type": String(context.get("entity_type", "")),
		"entity_id": String(context.get("entity_id", "")),
		"field": String(context.get("field", "")),
		"area_id": String(context.get("area_id", "")),
		"node_id": String(context.get("node_id", "")),
		"choice_index": int(context.get("choice_index", -1)),
		"line": int(context.get("line", 0)),
		"section": String(context.get("section", "advanced")),
		"refs": Array(context.get("refs", [])).duplicate(),
		"advanced": bool(context.get("advanced", false)),
	}


## Legacy validators stay authoritative until each rule is migrated. Their
## errors are wrapped as advanced diagnostics because no location was recorded.
static func wrap_legacy(message: String, campaign: String, source := "") -> Dictionary:
	return make("content.rule", ERROR, message, {
		"campaign": campaign,
		"source": source,
		"section": "advanced",
		"advanced": true,
	})


static func has_errors(diagnostics: Array) -> bool:
	for raw in diagnostics:
		if raw is Dictionary and String(Dictionary(raw).get("severity", "")) == ERROR:
			return true
	return false


static func count(diagnostics: Array, severity: String) -> int:
	var total := 0
	for raw in diagnostics:
		if raw is Dictionary and String(Dictionary(raw).get("severity", "")) == severity:
			total += 1
	return total


static func messages(diagnostics: Array) -> Array[String]:
	var result: Array[String] = []
	for raw in diagnostics:
		if raw is Dictionary:
			result.append(String(Dictionary(raw).get("message", "")))
	return result


## The informational award inventory of one campaign, as one line.
##
## Informational only: the caller prints it beside the diagnostics and never turns
## it into a diagnostic, so a campaign whose authored awards cannot reach the
## threshold still passes. The words are load-bearing - a sum is not a route and
## says nothing about reachability, and exclusive awards are all in the sum.
static func advancement_line(campaign: String, inventory: Dictionary) -> String:
	return (
		"ADVANCEMENT AWARDS %s authored=%d ordinary=%d qa=%d encounters=%d effects=%d start=%d threshold=%d"
		% [
			campaign,
			int(inventory.get("authored", 0)),
			int(inventory.get("ordinary", 0)),
			int(inventory.get("qa", 0)),
			int(inventory.get("encounters", 0)),
			int(inventory.get("effects", 0)),
			int(inventory.get("start", 0)),
			LevelUp.XP_THRESHOLD,
		]
		+ " (static inventory of authored awards; not a route, not reachability;"
		+ " mutually exclusive awards are both counted)"
	)


static func summary(diagnostics: Array) -> String:
	var errors := count(diagnostics, ERROR)
	var warnings := count(diagnostics, WARNING)
	if errors == 0 and warnings == 0:
		return "No content problems."
	if errors == 0:
		return "%d warning(s). The draft can be saved." % warnings
	return "%d error(s), %d warning(s)." % [errors, warnings]
