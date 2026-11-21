class_name BattleMap
extends RefCounted

## Square battle grid used by encounters.
##
## One square = 5 ft (3.5 standard battle grid). Diagonals cost 5 ft here
## instead of the tabletop 1-2-1-2 alternating rule; this is a documented
## adaptation (docs/ADAPTATION_LOG.md) that keeps distance symmetric and
## auditable in a computer game.

const CELL_FT := 5

var width := 0
var height := 0
var blocked: Array = []  # flat Array[bool], index = y * width + x
var label := ""


func setup(rows: Array, map_label := "") -> void:
	label = map_label
	height = rows.size()
	width = 0
	for row in rows:
		width = maxi(width, String(row).length())
	blocked.clear()
	blocked.resize(width * height)
	for y in height:
		var row := String(rows[y])
		for x in width:
			var glyph := row[x] if x < row.length() else "#"
			blocked[y * width + x] = glyph == "#"


static func from_rows(rows: Array, map_label := "") -> BattleMap:
	var m := BattleMap.new()
	m.setup(rows, map_label)
	return m


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func is_blocked(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return true
	return bool(blocked[cell.y * width + cell.x])


func set_walkable(cell: Vector2i, walkable: bool) -> void:
	if not in_bounds(cell):
		return
	blocked[cell.y * width + cell.x] = not walkable


func distance_ft(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y)) * CELL_FT


func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return a != b and maxi(absi(a.x - b.x), absi(a.y - b.y)) <= 1


func is_within_reach(a: Vector2i, b: Vector2i, reach_ft: int) -> bool:
	return a != b and distance_ft(a, b) <= maxi(reach_ft, CELL_FT)


## Bresenham line of sight; any blocked intermediate cell blocks the view.
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return true
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		if Vector2i(x0, y0) != from and Vector2i(x0, y0) != to:
			if is_blocked(Vector2i(x0, y0)):
				return false
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return true


## Cells whose interior a segment passes through, in corner coordinates (cell
## (x, y) spans [x, x+1] x [y, y+1]).
##
## The printed cover rule (PHB p. 151) asks whether a line passes through a
## square, so a segment that only runs along a grid line touches no square's
## interior and returns nothing, and a diagonal that passes exactly through a
## corner enters only the diagonal square. That is a documented grid adaptation:
## without it two allies sharing a row would block every line by border-riding
## and a diagonal neighbour would always grant cover (docs/ADAPTATION_LOG.md).
static func cells_crossed(from_corner: Vector2, to_corner: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var low := Vector2(minf(from_corner.x, to_corner.x), minf(from_corner.y, to_corner.y))
	var high := Vector2(maxf(from_corner.x, to_corner.x), maxf(from_corner.y, to_corner.y))
	for y in range(int(floor(low.y)) - 1, int(ceil(high.y)) + 2):
		for x in range(int(floor(low.x)) - 1, int(ceil(high.x)) + 2):
			if segment_enters_interior(from_corner, to_corner, Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


## True when some part of the segment lies strictly inside the cell. The shrink
## by `eps` is what makes a border-riding segment miss every square, and a
## corner-crossing diagonal miss the two squares it only grazes.
static func segment_enters_interior(
	from_corner: Vector2, to_corner: Vector2, cell: Vector2i, eps := 0.0001
) -> bool:
	var span := to_corner - from_corner
	var t0 := 0.0
	var t1 := 1.0
	for axis in 2:
		var origin := from_corner.x if axis == 0 else from_corner.y
		var delta := span.x if axis == 0 else span.y
		var cell_origin := float(cell.x) if axis == 0 else float(cell.y)
		var inside_low := cell_origin + eps
		var inside_high := cell_origin + 1.0 - eps
		if absf(delta) <= eps:
			if origin <= inside_low or origin >= inside_high:
				return false
			continue
		var enter := (inside_low - origin) / delta
		var leave := (inside_high - origin) / delta
		if enter > leave:
			var swap := enter
			enter = leave
			leave = swap
		t0 = maxf(t0, enter)
		t1 = minf(t1, leave)
		if t1 <= t0 + eps:
			return false
	return true


## The four corners of a square in the same coordinate space as `cells_crossed`.
static func square_corners(cell: Vector2i) -> Array[Vector2]:
	var x := float(cell.x)
	var y := float(cell.y)
	return [
		Vector2(x, y),
		Vector2(x + 1.0, y),
		Vector2(x, y + 1.0),
		Vector2(x + 1.0, y + 1.0),
	]


## Soft cover from creatures (PHB p. 151): "choose a corner of your square. If
## any line from this corner to any corner of the target's square passes through
## ... a square occupied by a creature, the target has cover (+4 to AC)." The
## attacker picks the corner, so the target has cover only if every one of the
## attacker's corners still has a blocked line; one clear corner means no cover.
##
## `occupied` maps a cell to any truthy value for every creature in the fight.
## The attacker's and target's own squares are never cover, and a body that only
## shares an edge or a corner with a line does not count (see `cells_crossed`).
static func creature_cover(
	attacker_cell: Vector2i, target_cell: Vector2i, occupied: Dictionary
) -> int:
	if attacker_cell == target_cell or occupied.is_empty():
		return 0
	var attacker_corners := square_corners(attacker_cell)
	var target_corners := square_corners(target_cell)
	for from_corner in attacker_corners:
		var clear := true
		for to_corner in target_corners:
			if _line_crosses_creature(from_corner, to_corner, attacker_cell, target_cell, occupied):
				clear = false
				break
		if clear:
			return 0
	return 4


static func _line_crosses_creature(
	from_corner: Vector2,
	to_corner: Vector2,
	attacker_cell: Vector2i,
	target_cell: Vector2i,
	occupied: Dictionary
) -> bool:
	for cell in cells_crossed(from_corner, to_corner):
		if cell == attacker_cell or cell == target_cell:
			continue
		if occupied.has(cell):
			return true
	return false


func occupied_lookup(positions: Array) -> Dictionary:
	var lookup := {}
	for pos in positions:
		if pos is Vector2i:
			lookup[pos] = true
	return lookup


## Breadth-first reachable squares within a movement budget.
## Returns {cell: cost_ft}. Excludes occupied squares.
func reachable(from: Vector2i, budget_ft: int, occupied: Dictionary) -> Dictionary:
	var result := {}
	var frontier: Array[Vector2i] = [from]
	var costs := {from: 0}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		var current_cost := int(costs[current])
		for dir in _directions():
			var nxt := current + dir
			if not in_bounds(nxt) or is_blocked(nxt) or occupied.has(nxt):
				continue
			if _blocked_diagonal(current, dir):
				continue
			var cost := current_cost + CELL_FT
			if cost > budget_ft:
				continue
			if costs.has(nxt) and int(costs[nxt]) <= cost:
				continue
			costs[nxt] = cost
			result[nxt] = cost
			frontier.append(nxt)
	return result


## Shortest path excluding the start. Empty if unreachable.
func find_path(from: Vector2i, to: Vector2i, occupied: Dictionary = {}) -> Array[Vector2i]:
	if from == to:
		return []
	var frontier: Array[Vector2i] = [from]
	var came_from := {from: from}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == to:
			break
		for dir in _directions():
			var nxt := current + dir
			if not in_bounds(nxt) or is_blocked(nxt):
				continue
			if _blocked_diagonal(current, dir):
				continue
			if occupied.has(nxt) and nxt != to:
				continue
			if came_from.has(nxt):
				continue
			came_from[nxt] = current
			frontier.append(nxt)
	if not came_from.has(to):
		return []
	var path: Array[Vector2i] = []
	var step := to
	while step != from:
		path.push_front(step)
		step = came_from[step]
	return path


func _directions() -> Array[Vector2i]:
	return [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1),
	]


func _blocked_diagonal(current: Vector2i, dir: Vector2i) -> bool:
	if dir.x == 0 or dir.y == 0:
		return false
	# Cannot cut a corner between two blocked orthogonal squares.
	return is_blocked(current + Vector2i(dir.x, 0)) and is_blocked(current + Vector2i(0, dir.y))


func to_rows() -> Array[String]:
	var rows: Array[String] = []
	for y in height:
		var row := ""
		for x in width:
			row += "#" if is_blocked(Vector2i(x, y)) else "."
		rows.append(row)
	return rows
