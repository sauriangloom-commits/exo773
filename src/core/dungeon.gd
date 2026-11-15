class_name Dungeon
extends RefCounted

## Grid-based exploration map with doors, objects, NPCs and triggers.
##
## Facing is discrete: 0 north, 1 east, 2 south, 3 west. A "cell" is a 5-ft
## square for exploration purposes; the first-person view is a stylised
## placeholder rendering of the same grid used by combat.

const NORTH := 0
const EAST := 1
const SOUTH := 2
const WEST := 3
const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const FACING_NAMES := ["north", "east", "south", "west"]

var id := ""
var display_name := ""
var rows: Array[String] = []
var width := 0
var height := 0
var start_pos := Vector2i(1, 1)
var start_facing := NORTH
var doors: Dictionary = {}  # Vector2i -> door dictionary
var objects: Dictionary = {}  # id -> object dictionary
var npcs: Dictionary = {}  # id -> npc dictionary
var triggers: Array = []
var open_doors: Dictionary = {}  # door id -> bool
var removed: Array[String] = []
var searched: Dictionary = {}  # object id -> bool
var visited: Dictionary = {}
var ambient := ""
var errors: Array[String] = []


func setup(data: Dictionary) -> void:
	errors.clear()
	id = String(data.get("id", ""))
	display_name = String(data.get("name", "Dungeon"))
	ambient = String(data.get("ambient", ""))
	rows.clear()
	for row in Array(data.get("rows", [])):
		rows.append(String(row))
	height = rows.size()
	width = 0
	for row in rows:
		width = maxi(width, row.length())
	for row in rows:
		if row.length() != width:
			errors.append("Map row '%s' is %d wide; expected %d." % [row, row.length(), width])
	var start: Dictionary = data.get("start", {})
	var pos: Array = start.get("pos", [1, 1])
	start_pos = Vector2i(int(pos[0]), int(pos[1]))
	start_facing = int(start.get("facing", NORTH)) % 4
	doors.clear()
	for door_data in Array(data.get("doors", [])):
		var d := Dictionary(door_data)
		var dpos := Vector2i(int(d.get("pos", [0, 0])[0]), int(d.get("pos", [0, 0])[1]))
		doors[dpos] = d
	objects.clear()
	for obj_data in Array(data.get("objects", [])):
		var o := Dictionary(obj_data)
		o["pos"] = Vector2i(int(o.get("pos", [0, 0])[0]), int(o.get("pos", [0, 0])[1]))
		objects[String(o.get("id", ""))] = o
	npcs.clear()
	for npc_data in Array(data.get("npcs", [])):
		var n := Dictionary(npc_data)
		n["pos"] = Vector2i(int(n.get("pos", [0, 0])[0]), int(n.get("pos", [0, 0])[1]))
		npcs[String(n.get("id", ""))] = n
	triggers = Array(data.get("triggers", [])).duplicate(true)
	_validate()


func _validate() -> void:
	if rows.is_empty():
		errors.append("Dungeon '%s' has no map rows." % id)
		return
	if not is_walkable(start_pos):
		errors.append("Start position %s is not walkable." % str(start_pos))
	for dpos in doors.keys():
		if not in_bounds(dpos):
			errors.append("Door at %s is outside the map." % str(dpos))
		var door: Dictionary = doors[dpos]
		if String(door.get("id", "")) == "":
			errors.append("Door at %s has no id." % str(dpos))
		if String(door.get("open_flag", "")) == "":
			errors.append("Door '%s' has no open_flag." % door.get("id", "?"))
	for object_id in objects.keys():
		var obj: Dictionary = objects[object_id]
		if not in_bounds(obj["pos"]):
			errors.append("Object '%s' is outside the map." % object_id)
		if not Array(obj.get("interactions", [])).is_empty():
			pass
	for npc_id in npcs.keys():
		if not in_bounds(npcs[npc_id]["pos"]):
			errors.append("NPC '%s' is outside the map." % npc_id)
	var seen_triggers := {}
	for trigger in triggers:
		var tid := String(trigger.get("id", ""))
		if tid == "":
			errors.append("A trigger has no id.")
		elif seen_triggers.has(tid):
			errors.append("Duplicate trigger id '%s'." % tid)
		seen_triggers[tid] = true
		var tpos: Array = trigger.get("pos", [])
		if tpos.size() == 2 and not in_bounds(Vector2i(int(tpos[0]), int(tpos[1]))):
			errors.append("Trigger '%s' is outside the map." % tid)


func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height


func glyph_at(pos: Vector2i) -> String:
	if not in_bounds(pos):
		return "#"
	var row := rows[pos.y]
	return row[pos.x] if pos.x < row.length() else "#"


func is_wall(pos: Vector2i) -> bool:
	return glyph_at(pos) == "#"


func door_at(pos: Vector2i) -> Dictionary:
	return doors.get(pos, {})


func is_door_open(pos: Vector2i) -> bool:
	var door := door_at(pos)
	if door.is_empty():
		return true
	return bool(open_doors.get(String(door.get("id", "")), false))


func is_walkable(pos: Vector2i) -> bool:
	if not in_bounds(pos) or is_wall(pos):
		return false
	if not door_at(pos).is_empty():
		return is_door_open(pos)
	return true


## True when a sight or movement ray stops here: wall, closed door, or edge.
func is_blocking_cell(pos: Vector2i) -> bool:
	if not in_bounds(pos) or is_wall(pos):
		return true
	return not door_at(pos).is_empty() and not is_door_open(pos)


func is_removed(object_id: String) -> bool:
	return removed.has(object_id)


func object_at(pos: Vector2i) -> Dictionary:
	for object_id in objects.keys():
		if is_removed(object_id):
			continue
		if objects[object_id]["pos"] == pos:
			return objects[object_id]
	return {}


func npc_at(pos: Vector2i) -> Dictionary:
	for npc_id in npcs.keys():
		if is_removed(npc_id):
			continue
		if npcs[npc_id]["pos"] == pos:
			return npcs[npc_id]
	return {}


func mark_removed(object_id: String) -> void:
	if not removed.has(object_id):
		removed.append(object_id)


func mark_searched(object_id: String) -> void:
	searched[object_id] = true


func is_searched(object_id: String) -> bool:
	return bool(searched.get(object_id, false))


func set_door_open(door_id: String, value := true) -> void:
	open_doors[door_id] = value


func door_by_id(door_id: String) -> Dictionary:
	for door in doors.values():
		if String(door.get("id", "")) == door_id:
			return door
	return {}


func facing_pos(pos: Vector2i, facing: int) -> Vector2i:
	return pos + DIRS[facing % 4]


## What the party is looking at: NPC, object, door, wall or open space.
func front_target(pos: Vector2i, facing: int) -> Dictionary:
	var target_pos := facing_pos(pos, facing)
	if not in_bounds(target_pos):
		return {"kind": "none"}
	var door := door_at(target_pos)
	if not door.is_empty():
		if not is_door_open(target_pos):
			return {"kind": "door", "pos": target_pos, "data": door, "id": String(door.get("id", ""))}
	var npc := npc_at(target_pos)
	if not npc.is_empty():
		return {"kind": "npc", "pos": target_pos, "data": npc, "id": String(npc.get("id", ""))}
	var obj := object_at(target_pos)
	if not obj.is_empty():
		return {"kind": "object", "pos": target_pos, "data": obj, "id": String(obj.get("id", ""))}
	if is_wall(target_pos):
		return {"kind": "wall", "pos": target_pos}
	return {"kind": "floor", "pos": target_pos}


func describe_view(pos: Vector2i, facing: int) -> String:
	var parts: Array[String] = []
	var dir_name: String = FACING_NAMES[facing % 4]
	parts.append("You face %s." % dir_name)
	var target := front_target(pos, facing)
	match String(target.get("kind", "")):
		"wall":
			parts.append("A cold stone wall blocks the way.")
		"door":
			var door: Dictionary = target["data"]
			parts.append(String(door.get("description", "A heavy door.")))
		"npc":
			var npc: Dictionary = target["data"]
			parts.append("%s — %s" % [String(npc.get("name", npc.get("id", "Someone"))), String(npc.get("look", "Someone stands here."))])
		"object":
			var obj: Dictionary = target["data"]
			parts.append(String(obj.get("look", "Something is here.")))
		"floor":
			parts.append("The passage continues.")
	var exits: Array[String] = []
	for facing_index in 4:
		var neighbor := facing_pos(pos, facing_index)
		if is_walkable(neighbor):
			exits.append(FACING_NAMES[facing_index])
		elif not door_at(neighbor).is_empty():
			exits.append("%s (door)" % FACING_NAMES[facing_index])
	if not exits.is_empty():
		parts.append("Exits: %s." % ", ".join(exits))
	return " ".join(parts)


func trigger_at(pos: Vector2i) -> Dictionary:
	for trigger in triggers:
		var tpos: Array = trigger.get("pos", [])
		if tpos.size() == 2 and int(tpos[0]) == pos.x and int(tpos[1]) == pos.y:
			return trigger
	return {}


func serialize() -> Dictionary:
	return {
		"open_doors": open_doors.duplicate(true),
		"removed": removed.duplicate(),
		"searched": searched.duplicate(true),
		"visited": _visited_list(),
	}


func apply_state(state: Dictionary) -> void:
	open_doors = Dictionary(state.get("open_doors", {})).duplicate(true) if state.get("open_doors", {}) is Dictionary else {}
	searched = Dictionary(state.get("searched", {})).duplicate(true) if state.get("searched", {}) is Dictionary else {}
	removed.clear()
	if state.get("removed", []) is Array:
		removed.assign(state.get("removed", []))
	visited.clear()
	if state.get("visited", []) is Array:
		for entry in Array(state.get("visited", [])):
			var parts := String(entry).split(",")
			if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
				visited[Vector2i(int(parts[0]), int(parts[1]))] = true


func _visited_list() -> Array[String]:
	var result: Array[String] = []
	for pos in visited.keys():
		result.append("%d,%d" % [pos.x, pos.y])
	return result


func visit(pos: Vector2i) -> void:
	visited[pos] = true
