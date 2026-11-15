class_name DialogueRunner
extends RefCounted

## Data-driven dialogue with conditional choices, skill checks and effects.
##
## The runner never touches presentation. It returns structured choices and
## messages; GameSession executes effect dictionaries so authored content and
## runtime rules stay separate.

var data: Dictionary = {}
var session  # GameSession (untyped to avoid a cyclic class dependency)
var rng: RandomNumberGenerator
var node_id := ""
var finished := true
var last_skill_result: Dictionary = {}
var actor_used: Character = null
var errors: Array[String] = []
var visited_nodes: Array[String] = []
var start_time := 0


func setup(dialogue_data: Dictionary, session_ref, rng_ref: RandomNumberGenerator) -> void:
	data = dialogue_data
	session = session_ref
	rng = rng_ref


func start() -> bool:
	errors.clear()
	visited_nodes.clear()
	last_skill_result = {}
	actor_used = null
	if data.is_empty():
		errors.append("Dialogue data is empty.")
		return false
	node_id = String(data.get("start", ""))
	if node_id == "" or not Dictionary(data.get("nodes", {})).has(node_id):
		errors.append("Dialogue '%s' has no valid start node." % data.get("id", "?"))
		return false
	finished = false
	_enter_node(node_id)
	return true


func current_node() -> Dictionary:
	return Dictionary(data.get("nodes", {})).get(node_id, {})


func speaker_name() -> String:
	var node := current_node()
	return String(node.get("speaker_name", data.get("speaker", "Someone")))


func speaker_kind() -> String:
	return String(current_node().get("speaker", "npc"))


func text() -> String:
	return String(current_node().get("text", ""))


## Applies an optional on_enter effect list. Choice/next handling lives in
## choose(); node entry only needs presentation-safe effects.
func _enter_node(id: String) -> void:
	node_id = id
	if not visited_nodes.has(id):
		visited_nodes.append(id)
	var node := current_node()
	var effects := Array(node.get("effects", []))
	if not effects.is_empty() and session != null:
		session.apply_effects(effects, "dialogue:%s" % id)
	if not Array(node.get("choices", [])).is_empty():
		return
	var next := String(node.get("next", ""))
	if next == "":
		finished = true
	else:
		if Dictionary(data.get("nodes", {})).has(next):
			_enter_node(next)
		else:
			errors.append("Node '%s' links to missing node '%s'." % [id, next])
			finished = true


## Returns [{text, index, check, actor_name, available, reason}].
func available_choices() -> Array:
	var result: Array = []
	var node := current_node()
	var choices := Array(node.get("choices", []))
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var conditions := Array(choice.get("conditions", []))
		var gate := _check_conditions(conditions)
		var entry := {
			"index": i,
			"text": String(choice.get("text", "...")),
			"available": bool(gate["ok"]),
			"reason": String(gate.get("reason", "")),
			"has_check": not Dictionary(choice.get("check", {})).is_empty(),
		}
		if bool(entry["has_check"]):
			var check: Dictionary = choice.get("check", {})
			entry["check_text"] = "%s DC %d" % [
				Skills.name(String(check.get("skill", ""))),
				int(check.get("dc", 10)),
			]
			entry["actor_name"] = _pick_actor(choice).display_name if _pick_actor(choice) != null else "—"
		result.append(entry)
	return result


func _check_conditions(conditions: Array) -> Dictionary:
	if session == null:
		return {"ok": true}
	return session.check_conditions(conditions)


func _pick_actor(choice: Dictionary) -> Character:
	var check: Dictionary = choice.get("check", {})
	if check.is_empty():
		return null
	var requested := String(check.get("actor", "best"))
	var party: Array = session.party
	if requested == "best":
		var best: Character = null
		var best_total := -999
		for ch in party:
			if not ch.can_act():
				continue
			var total := Rules.skill_total(ch, String(check.get("skill", "")))
			if total > best_total:
				best_total = total
				best = ch
		return best
	for ch in party:
		if ch.id == requested and ch.can_act():
			return ch
	return null


## player_choice is the index into the node's authored choice array.
func choose(player_choice: int) -> Dictionary:
	var node := current_node()
	var choices := Array(node.get("choices", []))
	if player_choice < 0 or player_choice >= choices.size():
		return {"ok": false, "message": "Invalid dialogue choice.", "finished": finished}
	var choice: Dictionary = choices[player_choice]
	var gate := _check_conditions(Array(choice.get("conditions", [])))
	if not bool(gate["ok"]):
		return {"ok": false, "message": String(gate.get("reason", "That option is unavailable."))}
	var messages: Array[String] = []
	if not Array(choice.get("effects", [])).is_empty() and session != null:
		messages.append_array(session.apply_effects(Array(choice.get("effects", [])), "dialogue"))
	last_skill_result = {}
	var next := String(choice.get("next", ""))
	var check: Dictionary = choice.get("check", {})
	if not check.is_empty():
		var actor := _pick_actor(choice)
		if actor == null:
			return {"ok": false, "message": "No conscious party member can attempt that check."}
		actor_used = actor
		var skill := String(check.get("skill", "search"))
		var dc := int(check.get("dc", 10))
		var take := int(check.get("take", 0))
		var check_opts := {
			"take": take,
			"circumstance": int(check.get("circumstance", 0)),
		}
		var roll: Dictionary
		if String(check.get("ability", "")) != "":
			roll = Rules.ability_check(rng, actor, String(check["ability"]), dc, check_opts)
		else:
			roll = Rules.skill_check(rng, actor, skill, dc, check_opts)
		if not bool(roll.get("available", true)):
			var reason := String(roll.get("reason", "That check is unavailable."))
			if session != null:
				session.log(reason)
			return {"ok": false, "message": reason, "finished": finished}
		roll["label"] = String(check.get("label", Skills.name(skill)))
		last_skill_result = roll
		var roll_text := "d20(%d)" % int(roll["roll"])
		if take != 0:
			roll_text = "take %d → %d" % [take, int(roll["roll"])]
		var success_text := "%s check: %s%+d = %d vs DC %d — %s" % [
			actor.display_name,
			roll_text,
			int(roll["bonus"]),
			int(roll["total"]),
			dc,
			"success" if bool(roll["success"]) else "failure",
		]
		messages.append(success_text)
		if session != null:
			session.log(success_text)
		next = String(check.get("success", "")) if bool(roll["success"]) else String(check.get("failure", ""))
	if next == "":
		finished = true
		messages.append("[Dialogue ends.]")
		if session != null:
			session.on_dialogue_finished(data)
		return {"ok": true, "messages": messages, "finished": true, "check": last_skill_result}
	if not Dictionary(data.get("nodes", {})).has(next):
		errors.append("Choice links to missing node '%s'." % next)
		finished = true
		return {"ok": false, "message": "Broken dialogue link '%s'." % next, "finished": true}
	messages.append_array(_enter_node_and_collect(next))
	return {"ok": true, "messages": messages, "finished": finished, "check": last_skill_result}


func _enter_node_and_collect(id: String) -> Array[String]:
	var messages: Array[String] = []
	node_id = id
	if not visited_nodes.has(id):
		visited_nodes.append(id)
	var node := current_node()
	var effects := Array(node.get("effects", []))
	if not effects.is_empty() and session != null:
		messages.append_array(session.apply_effects(effects, "dialogue:%s" % id))
	if Array(node.get("choices", [])).is_empty():
		var next := String(node.get("next", ""))
		if next == "":
			finished = true
			if session != null:
				session.on_dialogue_finished(data)
		elif Dictionary(data.get("nodes", {})).has(next):
			messages.append_array(_enter_node_and_collect(next))
		else:
			errors.append("Node '%s' links to missing node '%s'." % [id, next])
			finished = true
	return messages


func finish_now() -> void:
	finished = true
	if session != null:
		session.on_dialogue_finished(data)
