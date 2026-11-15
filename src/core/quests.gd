class_name QuestLog
extends RefCounted

## Persistent quest state. Objectives are flag-driven so authored content only
## needs to set world flags; the journal stays in sync automatically.

var definitions: Dictionary = {}
var state: Dictionary = {}  # quest_id -> {status, objectives:{id:bool}}


func setup(defs: Dictionary) -> void:
	definitions = defs.duplicate(true)
	state.clear()
	for quest_id in defs.keys():
		var objectives := {}
		for objective in Array(defs[quest_id].get("objectives", [])):
			objectives[String(objective.get("id", ""))] = false
		state[quest_id] = {"status": "not_started", "objectives": objectives}


func start(quest_id: String) -> bool:
	if not state.has(quest_id):
		return false
	if String(state[quest_id]["status"]) == "not_started":
		state[quest_id]["status"] = "active"
		return true
	return false


func status(quest_id: String) -> String:
	if not state.has(quest_id):
		return "unknown"
	return String(state[quest_id]["status"])


func is_active(quest_id: String) -> bool:
	return status(quest_id) == "active"


func is_complete(quest_id: String) -> bool:
	return status(quest_id) == "complete"


func objective_done(quest_id: String, objective_id: String) -> bool:
	if not state.has(quest_id):
		return false
	return bool(state[quest_id]["objectives"].get(objective_id, false))


## Marks objectives whose flag is true and completes quests with all
## objectives done. Returns human-readable changes.
func sync_flags(flags: Dictionary) -> Array[String]:
	var changes: Array[String] = []
	for quest_id in state.keys():
		var quest: Dictionary = state[quest_id]
		if String(quest["status"]) == "not_started":
			continue
		# Completion is a transition. A completed quest must not emit the
		# "Quest complete" line again on every later flag synchronization.
		if String(quest["status"]) == "complete":
			continue
		var def: Dictionary = definitions.get(quest_id, {})
		var all_done := true
		for objective in Array(def.get("objectives", [])):
			var objective_id := String(objective.get("id", ""))
			var flag := String(objective.get("flag", ""))
			var done := bool(quest["objectives"].get(objective_id, false))
			if not done and flag != "" and bool(flags.get(flag, false)):
				quest["objectives"][objective_id] = true
				changes.append("Objective complete: %s" % String(objective.get("text", objective_id)))
			if not bool(quest["objectives"].get(objective_id, false)):
				all_done = false
		if all_done and Array(def.get("objectives", [])).size() > 0:
			quest["status"] = "complete"
			changes.append("Quest complete: %s" % String(def.get("title", quest_id)))
	return changes


func active_quests() -> Array[String]:
	var result: Array[String] = []
	for quest_id in state.keys():
		if String(state[quest_id]["status"]) == "active":
			result.append(quest_id)
	return result


## Compact tracker for the exploration sidebar: active quest title plus the
## next unfinished objectives only.
func compact_text(preferred_quest := "") -> String:
	var lines: Array[String] = []
	var chosen: Array[String] = []
	# An area can feature its own lead so a developer/demo quest does not crowd
	# out the local, source-grounded objective in the exploration sidebar.
	if preferred_quest != "" and status(preferred_quest) != "not_started":
		chosen.append(preferred_quest)
	else:
		chosen = active_quests()
	for quest_id in chosen:
		var def: Dictionary = definitions.get(quest_id, {})
		lines.append(String(def.get("title", quest_id)))
		if is_complete(quest_id):
			lines.append("• Complete.")
		else:
			for objective in Array(def.get("objectives", [])):
				if not objective_done(quest_id, String(objective.get("id", ""))):
					lines.append("• " + String(objective.get("text", "")))
				if lines.size() >= 5:
					break
		if lines.size() >= 5:
			break
	if lines.is_empty():
		return "No active objectives. Explore, and speak with anyone you meet."
	return "\n".join(lines)


func journal_text() -> String:
	var lines: Array[String] = []
	if active_quests().is_empty():
		var completed: Array[String] = []
		for quest_id in state.keys():
			if is_complete(quest_id):
				completed.append(String(definitions.get(quest_id, {}).get("title", quest_id)))
		if completed.is_empty():
			return "No active objectives. Explore, and speak with anyone you meet."
		return "Completed: " + ", ".join(completed)
	for quest_id in active_quests():
		var def: Dictionary = definitions.get(quest_id, {})
		lines.append(String(def.get("title", quest_id)))
		lines.append(String(def.get("summary", "")))
		for objective in Array(def.get("objectives", [])):
			var done := objective_done(quest_id, String(objective.get("id", "")))
			lines.append(("  [x] " if done else "  [ ] ") + String(objective.get("text", "")))
		lines.append("")
	return "\n".join(lines)


func serialize() -> Dictionary:
	return state.duplicate(true)


func apply_state(saved: Dictionary) -> void:
	for quest_id in state.keys():
		if saved.get(quest_id, null) is Dictionary:
			var saved_quest: Dictionary = saved[quest_id]
			if saved_quest.get("objectives", null) is Dictionary:
				state[quest_id] = saved_quest.duplicate(true)
