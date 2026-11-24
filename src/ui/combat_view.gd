class_name CombatView
extends Control

## Square-grid tactical battle view (placeholder art). Draws terrain, reachable
## squares, tokens, HP and conditions, and reports clicked cells.

signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

var cell_size := 56.0
var origin := Vector2(20, 20)
var hover_cell := Vector2i(-1, -1)
var mode := "move"
## Keyboard targeting cursor. Inactive (-1,-1) means the grid does not own the
## keyboard: the ring stays on the sidebar and its arrows keep the ordinary
## focus navigation. `CombatScreen` decides when the grid may take the ring.
var keyboard_cursor := Vector2i(-1, -1)
var keyboard_cursor_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	Game.state_changed.connect(queue_redraw)
	resized.connect(_layout_and_redraw)
	# Tab, a modal, a turn change or a refresh can all take the ring away. A
	# cursor that kept listening after that would confirm a cell nobody aimed at.
	focus_exited.connect(_on_focus_exited)


func _layout_and_redraw() -> void:
	_layout()
	queue_redraw()


func _layout() -> void:
	if Game.encounter == null:
		return
	var cols := Game.encounter.map.width
	var rows := Game.encounter.map.height
	if cols <= 0 or rows <= 0:
		return
	cell_size = clampf(minf((size.x - 40.0) / float(cols), (size.y - 70.0) / float(rows)), 26.0, 78.0)
	origin = Vector2(
		(size.x - cell_size * float(cols)) * 0.5,
		26.0
	)


func _cell_at(point: Vector2) -> Vector2i:
	if Game.encounter == null:
		return Vector2i(-1, -1)
	var local := point - origin
	var x := int(floor(local.x / cell_size))
	var y := int(floor(local.y / cell_size))
	var cell := Vector2i(x, y)
	if Game.encounter.map.in_bounds(cell):
		return cell
	return Vector2i(-1, -1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := _cell_at(event.position)
		if cell != hover_cell:
			hover_cell = cell
			cell_hovered.emit(cell)
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var cell := _cell_at(event.position)
			if cell.x >= 0:
				# Mouse handoff: the click takes the cursor with it, so a later
				# Enter confirms the cell the player last aimed at, never an older
				# keyboard position on the other side of the map.
				if keyboard_cursor_active:
					keyboard_cursor = cell
					queue_redraw()
				cell_clicked.emit(cell)
				queue_redraw()
	elif event is InputEventKey and keyboard_cursor_active:
		_handle_key_event(event)


## Keyboard ownership is explicit: this only runs while the grid holds the focus
## ring. Repeats are accepted for movement on purpose, so a held arrow slides the
## cursor cell by cell; an echoed confirm is ignored, so a held Enter/Space can
## never resolve the same cell twice.
func _handle_key_event(event: InputEventKey) -> void:
	if not event.pressed:
		return
	if event.is_action_pressed("ui_accept"):
		accept_event()
		if event.echo:
			return
		# The same signal a left click emits: CombatScreen resolves it exactly as
		# it resolves a pointer target, including every refusal.
		cell_clicked.emit(keyboard_cursor)
		return
	var step := Vector2i.ZERO
	if event.is_action_pressed("ui_left", true):
		step = Vector2i.LEFT
	elif event.is_action_pressed("ui_right", true):
		step = Vector2i.RIGHT
	elif event.is_action_pressed("ui_up", true):
		step = Vector2i.UP
	elif event.is_action_pressed("ui_down", true):
		step = Vector2i.DOWN
	if step == Vector2i.ZERO:
		return
	accept_event()
	move_keyboard_cursor(step)


## Takes the keyboard for the grid and seats the cursor on `cell`. The cursor is
## clamped here, so no caller can place it outside the encounter's map.
func begin_keyboard_cursor(cell: Vector2i) -> void:
	if Game.encounter == null:
		return
	keyboard_cursor = _clamp_cell(cell)
	keyboard_cursor_active = true
	focus_mode = Control.FOCUS_ALL
	if not has_focus():
		grab_focus()
	queue_redraw()


func end_keyboard_cursor() -> void:
	keyboard_cursor_active = false
	keyboard_cursor = Vector2i(-1, -1)
	if has_focus():
		release_focus()
	focus_mode = Control.FOCUS_NONE
	queue_redraw()


## One cell, stopped at the map edges. Blocked and occupied cells stay reachable:
## the ordinary click path owns range, line-of-sight and occupancy refusals, and
## duplicating them here would let the two drift apart.
func move_keyboard_cursor(step: Vector2i) -> void:
	if not keyboard_cursor_active or Game.encounter == null:
		return
	keyboard_cursor = _clamp_cell(keyboard_cursor + step)
	queue_redraw()


func _clamp_cell(cell: Vector2i) -> Vector2i:
	var map := Game.encounter.map
	return Vector2i(
		clampi(cell.x, 0, maxi(0, map.width - 1)),
		clampi(cell.y, 0, maxi(0, map.height - 1))
	)


func _on_focus_exited() -> void:
	keyboard_cursor_active = false
	keyboard_cursor = Vector2i(-1, -1)
	# Leaving the Tab ring while inactive keeps a later Tab from landing on a
	# grid that has no cursor to show or keys to take.
	focus_mode = Control.FOCUS_NONE
	queue_redraw()


func _draw() -> void:
	if Game.encounter == null:
		return
	_layout()
	var e := Game.encounter
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#0b1015"))
	draw_rect(
		Rect2(origin - Vector2(6, 6), Vector2(e.map.width * cell_size + 12, e.map.height * cell_size + 12)),
		Color("#0d141a")
	)
	# Terrain.
	for y in e.map.height:
		for x in e.map.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(x, y) * cell_size, Vector2(cell_size, cell_size))
			if e.map.is_blocked(cell):
				draw_rect(rect, Color("#171d23"))
				draw_line(rect.position + Vector2(4, 4), rect.end - Vector2(4, 4), Color("#222c35"), 1.0)
				draw_line(Vector2(rect.end.x - 4, rect.position.y + 4), Vector2(rect.position.x + 4, rect.end.y - 4), Color("#222c35"), 1.0)
			else:
				draw_rect(rect, Color("#242a2c") if (x + y) % 2 == 0 else Color("#202628"))
			draw_rect(rect, Color(0.35, 0.42, 0.48, 0.25), false, 1.0)
	# Reachable squares for the active player.
	var active := e.active_entry()
	var active_index := -1 if e.order.is_empty() else int(e.order[e.turn_ptr])
	if not active.is_empty() and not e.finished and int(active["team"]) == Encounter.TEAM_PARTY:
		var ch: Character = active["char"]
		if ch.can_act() and not ch.has_condition("paralyzed"):
			var occupied := e.occupied_except(int(active["index"]))
			var budget := maxi(0, ch.speed_ft - int(e.turn_state.get("moved_ft", 0)))
			if not bool(e.turn_state.get("move_used", false)):
				var reachable := e.map.reachable(active["cell"], budget, occupied)
				for cell in reachable.keys():
					var rect := Rect2(
						origin + Vector2(cell.x, cell.y) * cell_size,
						Vector2(cell_size, cell_size)
					)
					draw_rect(rect, Color(0.36, 0.55, 0.7, 0.18))
					draw_rect(rect, Color(0.5, 0.7, 0.85, 0.35), false, 1.0)
	# Tokens.
	for entry in e.combatants:
		var ch: Character = entry["char"]
		var cell: Vector2i = entry["cell"]
		var center := origin + Vector2(cell.x + 0.5, cell.y + 0.5) * cell_size
		var radius := cell_size * 0.33
		var color := ThemeBuilder.BLUE if int(entry["team"]) == Encounter.TEAM_PARTY else ThemeBuilder.DANGER
		if ch.has_condition("dead"):
			color = Color("#4b4b4b")
		if int(entry["index"]) == active_index:
			draw_circle(center, radius + 5.0, Color(0.85, 0.72, 0.35, 0.55))
		draw_circle(center, radius, color.darkened(0.25))
		draw_circle(center, radius - 2.0, color)
		var font := ThemeDB.fallback_font
		var initial := ch.display_name.left(1).to_upper()
		var fs := int(clampf(cell_size * 0.34, 12.0, 24.0))
		var text_size := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(
			font,
			center - Vector2(text_size.x * 0.5, -text_size.y * 0.32),
			initial,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			fs,
			Color("#0d1116")
		)
		if ch.has_condition("dead"):
			draw_line(center - Vector2(radius, radius) * 0.7, center + Vector2(radius, radius) * 0.7, Color("#e0d8c8"), 2.0)
			draw_line(center + Vector2(radius, -radius) * 0.7, center + Vector2(-radius, radius) * 0.7, Color("#e0d8c0"), 2.0)
		if cell_size >= 52.0:
			var hp_text := "%d" % ch.hp
			var hp_size := font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
			draw_rect(
				Rect2(center.x - hp_size.x * 0.5 - 3, center.y + radius - 2, hp_size.x + 6, 14),
				Color(0, 0, 0, 0.55)
			)
			draw_string(
				font,
				center + Vector2(-hp_size.x * 0.5, radius + 10),
				hp_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				ThemeBuilder.TEXT
			)
		var conditions: Array[String] = []
		if ch.has_condition("paralyzed"):
			conditions.append("PAR")
		if ch.has_condition("dying"):
			conditions.append("DYE")
		if ch.has_condition("stable"):
			conditions.append("STA")
		if ch.has_condition("bless"):
			conditions.append("BL")
		if ch.has_condition("mage_armor"):
			conditions.append("MA")
		if not conditions.is_empty() and cell_size >= 46.0:
			draw_string(
				font,
				center + Vector2(-radius, -radius - 4),
				" ".join(conditions),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				10,
				ThemeBuilder.GOLD
			)
	# Keyboard cursor. Same gold as the active-turn ring so it reads as "a
	# confirm lands here"; the fill is faint enough to keep the token legible.
	if keyboard_cursor_active and keyboard_cursor.x >= 0:
		var cursor_rect := Rect2(
			origin + Vector2(keyboard_cursor.x, keyboard_cursor.y) * cell_size,
			Vector2(cell_size, cell_size)
		)
		draw_rect(cursor_rect, Color(0.85, 0.72, 0.35, 0.14))
		draw_rect(cursor_rect, Color(0.85, 0.72, 0.35, 0.95), false, 2.0)
	# Hover details and legend. Two short lines stay inside the view at the
	# largest text setting instead of running under the sidebar.
	var font2 := ThemeDB.fallback_font
	draw_string(font2, Vector2(14, size.y - 56), "Blue = party • Red = enemy • gold ring = active turn", HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBuilder.fs(12), ThemeBuilder.MUTED)
	# The instruction line describes whichever input owns the grid right now, so
	# a keyboard player is not told to click and a mouse player is not told to
	# use arrows that only work once a mode has taken the ring.
	var controls_hint := (
		"Arrows move the cursor • Enter/Space confirms • Esc cancels targeting."
		if keyboard_cursor_active
		else "Click an enemy to attack; click an empty square to move."
	)
	draw_string(font2, Vector2(14, size.y - 38), controls_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBuilder.fs(12), ThemeBuilder.MUTED)
	var hover := "Hover a square for distance."
	if hover_cell.x >= 0:
		var distance := 0
		if not active.is_empty():
			distance = e.map.distance_ft(active["cell"], hover_cell)
		hover = "Square %d,%d — %d ft. from active combatant" % [hover_cell.x, hover_cell.y, distance]
	draw_string(font2, Vector2(14, size.y - 14), hover, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBuilder.fs(12), ThemeBuilder.TEXT)
	draw_string(
		font2,
		Vector2(size.x - 190, 16),
		"PLACEHOLDER ART",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeBuilder.fs(11),
		Color(0.7, 0.75, 0.8, 0.5)
	)
