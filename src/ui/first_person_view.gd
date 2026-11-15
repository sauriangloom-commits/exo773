class_name FirstPersonView
extends Control

## Stylised first-person dungeon renderer (placeholder art).
##
## A column raycaster over the authored exploration grid, painted with flat
## 2D shapes. The rendering is presentation-only: movement, facing and
## interaction live in Dungeon/GameSession. Replace this view later with
## sprite/tile art without touching gameplay code.

const FOV := 1.30  # ~74 degrees
const MAX_DEPTH := 14.0

var depth_buffer := PackedFloat32Array()
var _hover_hint := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Close walls project above the view rect; without clipping they paint over
	# the screen header.
	clip_contents = true
	Game.state_changed.connect(_on_state_changed)
	resized.connect(queue_redraw)


func _on_state_changed() -> void:
	queue_redraw()


func _draw() -> void:
	if Game.dungeon == null or Game.party.is_empty():
		return
	var w := int(maxf(size.x, 16.0))
	var h := int(maxf(size.y, 16.0))
	draw_rect(Rect2(0, 0, w, h), Color("#0a0d11"))
	var horizon := int(h * 0.5)
	# Ceiling and floor bands with a little perspective shading.
	for i in 8:
		var band_h := float(h) * 0.5 / 8.0
		var top_col := Color("#0c1218").lerp(Color("#1a232c"), float(i) / 8.0)
		draw_rect(Rect2(0, i * band_h, w, band_h + 1), top_col)
		var floor_col := Color("#14181b").lerp(Color("#2a241d"), float(i) / 8.0)
		draw_rect(Rect2(0, horizon + i * band_h, w, band_h + 1), floor_col)
	var focal := (float(w) * 0.5) / tan(FOV * 0.5)
	draw_rect(Rect2(0, horizon - 1, w, 2), Color(0, 0, 0, 0.35))
	# Perspective floor / ceiling depth lines (occluded by wall slices later).
	for d in range(1, 9):
		var y_floor := horizon + focal * 0.5 / float(d)
		var y_ceil := horizon - focal * 0.5 / float(d)
		var alpha := 0.14 * (1.0 - float(d) / 10.0)
		draw_line(Vector2(0, y_floor), Vector2(w, y_floor), Color(0.75, 0.8, 0.85, alpha), 1.0)
		draw_line(Vector2(0, y_ceil), Vector2(w, y_ceil), Color(0.6, 0.68, 0.75, alpha * 0.6), 1.0)
	var cam := Vector2(Game.position.x + 0.5, Game.position.y + 0.5)
	var angle := -PI / 2.0 + float(Game.facing) * PI / 2.0
	var dir := Vector2(cos(angle), sin(angle))
	var right := Vector2(-dir.y, dir.x)
	var plane_scale := tan(FOV * 0.5)
	depth_buffer.resize(w)
	for x in w:
		var camera_x := 2.0 * float(x) / float(w) - 1.0
		var ray := dir + right * (plane_scale * camera_x)
		var hit := _cast_ray(cam, ray)
		var perp := clampf(float(hit["distance"]), 0.05, MAX_DEPTH)
		depth_buffer[x] = perp
		var line_h := focal / perp
		var top := float(horizon) - line_h * 0.5
		var color := _wall_color(hit, perp)
		# Four vertical bands give each slice a torch-lit gradient instead of a
		# flat silhouette, which is what made the placeholder view unreadable.
		for band in 4:
			var band_h := line_h / 4.0
			var shade := color.lightened(0.035 * (3 - band))
			draw_rect(Rect2(float(x), top + band * band_h, 1.0, band_h + 1.0), shade)
		# Floor and ceiling junctions.
		draw_line(
			Vector2(float(x), top),
			Vector2(float(x), top + 2.0),
			color.lightened(0.18),
			1.0
		)
		draw_line(
			Vector2(float(x), top + line_h - 2.0),
			Vector2(float(x), top + line_h),
			color.darkened(0.35),
			1.0
		)
		if perp < 8.0 and x % 2 == 0:
			var mortar := color.darkened(0.18)
			draw_line(
				Vector2(float(x), top + line_h * 0.33),
				Vector2(float(x), top + line_h * 0.36),
				mortar,
				1.0
			)
			draw_line(
				Vector2(float(x), top + line_h * 0.7),
				Vector2(float(x), top + line_h * 0.71),
				mortar,
				1.0
			)
	_draw_sprites(w, h, focal, horizon, cam, dir, right, plane_scale)
	_draw_hud(w, h, focal, horizon)


func _cast_ray(origin: Vector2, ray: Vector2) -> Dictionary:
	var map_x := int(floor(origin.x))
	var map_y := int(floor(origin.y))
	var delta_x := absf(1.0 / ray.x) if absf(ray.x) > 0.00001 else 1e30
	var delta_y := absf(1.0 / ray.y) if absf(ray.y) > 0.00001 else 1e30
	var step_x := 1 if ray.x > 0.0 else -1
	var step_y := 1 if ray.y > 0.0 else -1
	var side_x := (
		(float(map_x + 1) - origin.x) * delta_x
		if ray.x > 0.0
		else (origin.x - float(map_x)) * delta_x
	)
	var side_y := (
		(float(map_y + 1) - origin.y) * delta_y
		if ray.y > 0.0
		else (origin.y - float(map_y)) * delta_y
	)
	var side := 0
	for _i in 96:
		if side_x < side_y:
			side_x += delta_x
			map_x += step_x
			side = 0
		else:
			side_y += delta_y
			map_y += step_y
			side = 1
		var cell := Vector2i(map_x, map_y)
		if Game.dungeon.is_blocking_cell(cell):
			var distance := 0.0
			if side == 0:
				distance = (float(map_x) - origin.x + (1.0 - float(step_x)) * 0.5) / ray.x
			else:
				distance = (float(map_y) - origin.y + (1.0 - float(step_y)) * 0.5) / ray.y
			return {
				"distance": maxf(distance, 0.05),
				"cell": cell,
				"side": side,
				"door": not Game.dungeon.door_at(cell).is_empty(),
			}
	return {"distance": MAX_DEPTH, "cell": Vector2i(-1, -1), "side": 0, "door": false}


func _wall_color(hit: Dictionary, distance: float) -> Color:
	var base := Color("#4a5058")
	if bool(hit.get("door", false)):
		base = Color("#5a4029")
	else:
		var cell: Vector2i = hit["cell"]
		if cell.y <= 3:
			base = Color("#3f4650")
		elif cell.y >= 8:
			base = Color("#4c4a43")
		var variation := float(absi(cell.x * 31 + cell.y * 17) % 7) / 100.0
		base = base.lightened(variation)
	if int(hit.get("side", 0)) == 1:
		base = base.darkened(0.16)
	var fog := clampf(distance / (MAX_DEPTH * 0.9), 0.0, 0.85)
	return base.lerp(Color("#070a0d"), fog)


func _draw_sprites(
	w: int,
	h: int,
	focal: float,
	horizon: int,
	cam: Vector2,
	dir: Vector2,
	right: Vector2,
	plane_scale: float
) -> void:
	var sprites: Array = []
	for npc in Game.dungeon.npcs.values():
		if Game.dungeon.is_removed(String(npc.get("id", ""))):
			continue
		sprites.append(
			{
				"pos": Vector2(npc["pos"].x + 0.5, npc["pos"].y + 0.5),
				"kind": String(npc.get("sprite", "npc")),
				"name": String(npc.get("name", "Someone")),
				"id": String(npc.get("id", "")),
			}
		)
	for obj in Game.dungeon.objects.values():
		if Game.dungeon.is_removed(String(obj.get("id", ""))):
			continue
		sprites.append(
			{
				"pos": Vector2(obj["pos"].x + 0.5, obj["pos"].y + 0.5),
				"kind": String(obj.get("id", "object")),
				"name": String(obj.get("name", "Something")),
				"id": String(obj.get("id", "")),
			}
		)
	var projected: Array = []
	for sprite in sprites:
		var rel: Vector2 = sprite["pos"] - cam
		var depth := rel.dot(dir)
		if depth <= 0.15 or depth > MAX_DEPTH:
			continue
		var lateral := rel.dot(right)
		var camera_x := lateral / (depth * plane_scale)
		if absf(camera_x) > 1.35:
			continue
		var screen_x := float(w) * 0.5 * (1.0 + camera_x)
		var col := clampi(int(screen_x), 0, w - 1)
		if depth_buffer.size() > col and depth_buffer[col] < depth - 0.12:
			continue
		sprite["depth"] = depth
		sprite["screen_x"] = screen_x
		projected.append(sprite)
	projected.sort_custom(func(a, b): return float(a["depth"]) > float(b["depth"]))
	for sprite in projected:
		_draw_sprite(sprite, focal, horizon, w, h)
	# Facing-target prompt.
	var target := Game.dungeon.front_target(Game.position, Game.facing)
	if ["npc", "object", "door"].has(String(target.get("kind", ""))):
		var data: Dictionary = target.get("data", {})
		var prompt := "[F] %s" % String(data.get("name", "Interact"))
		var font := ThemeDB.fallback_font
		var font_size := ThemeBuilder.fs(18)
		var text_size := font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_rect(
			Rect2(float(w) * 0.5 - text_size.x * 0.5 - 12, float(h) - 84, text_size.x + 24, 34),
			Color(0, 0, 0, 0.62)
		)
		draw_string(
			font,
			Vector2(float(w) * 0.5 - text_size.x * 0.5, float(h) - 60),
			prompt,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			ThemeBuilder.GOLD
		)


func _draw_sprite(sprite: Dictionary, focal: float, horizon: int, w: int, h: int) -> void:
	var depth := float(sprite["depth"])
	var screen_x := float(sprite["screen_x"])
	var scale := focal / depth
	var body_w := scale * 0.52
	var floor_y := float(horizon) + scale * 0.5
	var height := scale * 0.95
	var top := floor_y - height
	var kind := String(sprite["kind"])
	var name := String(sprite["name"])
	var color := Color("#5f8f8a")
	match kind:
		"ghoul":
			color = Color("#a9b79a")
		"npc":
			color = Color("#7c9d8f")
		"bell":
			color = Color("#a8843c")
		"shrine":
			color = Color("#c9a227")
		"supply_crate":
			color = Color("#7a5b37")
		"bier":
			color = Color("#6f6a5f")
		_:
			color = Color("#6f8a9c")
	if body_w < 6.0:
		draw_rect(Rect2(screen_x - 2, top, 4, height), color)
		return
	var outline := Color(0, 0, 0, 0.55)
	if kind == "bell":
		draw_line(Vector2(screen_x - body_w, top), Vector2(screen_x + body_w, top), Color("#4a3a24"), 6.0)
		var bell := PackedVector2Array(
			[
				Vector2(screen_x - body_w * 0.7, floor_y),
				Vector2(screen_x - body_w * 0.35, top + height * 0.25),
				Vector2(screen_x, top + height * 0.18),
				Vector2(screen_x + body_w * 0.35, top + height * 0.25),
				Vector2(screen_x + body_w * 0.7, floor_y),
			]
		)
		draw_colored_polygon(bell, color)
		draw_polyline(bell + PackedVector2Array([bell[0]]), outline, 2.0)
	elif kind == "supply_crate":
		draw_rect(Rect2(screen_x - body_w * 0.7, floor_y - height * 0.55, body_w * 1.4, height * 0.55), color)
		draw_rect(
			Rect2(screen_x - body_w * 0.7, floor_y - height * 0.55, body_w * 1.4, height * 0.55),
			outline,
			false,
			2.0
		)
		draw_line(
			Vector2(screen_x - body_w * 0.7, floor_y - height * 0.28),
			Vector2(screen_x + body_w * 0.7, floor_y - height * 0.28),
			outline,
			2.0
		)
	elif kind == "shrine":
		draw_rect(Rect2(screen_x - body_w * 0.6, top + height * 0.2, body_w * 1.2, height * 0.8), Color("#3d444b"))
		draw_circle(Vector2(screen_x, top + height * 0.32), body_w * 0.32, color)
		draw_arc(Vector2(screen_x, top + height * 0.32), body_w * 0.45, 0, TAU, 20, outline, 2.0)
	elif kind == "bier":
		draw_rect(Rect2(screen_x - body_w * 0.8, floor_y - height * 0.3, body_w * 1.6, height * 0.3), color)
		draw_rect(
			Rect2(screen_x - body_w * 0.8, floor_y - height * 0.3, body_w * 1.6, height * 0.3),
			outline,
			false,
			2.0
		)
	else:
		var is_ghoul := kind == "ghoul"
		var shoulder := body_w * (0.42 if is_ghoul else 0.55)
		var body_top := top + height * 0.28
		var body := PackedVector2Array(
			[
				Vector2(screen_x - shoulder, floor_y),
				Vector2(screen_x - shoulder * 0.8, body_top),
				Vector2(screen_x + shoulder * 0.8, body_top),
				Vector2(screen_x + shoulder, floor_y),
			]
		)
		draw_colored_polygon(body, color)
		draw_polyline(body + PackedVector2Array([body[0]]), outline, 2.0)
		draw_circle(Vector2(screen_x, top + height * 0.17), body_w * (0.26 if is_ghoul else 0.22), color.lightened(0.12))
		if is_ghoul:
			draw_line(
				Vector2(screen_x - shoulder * 0.8, body_top + height * 0.1),
				Vector2(screen_x - shoulder * 1.5, body_top + height * 0.22),
				color.lightened(0.2),
				2.0
			)
			draw_line(
				Vector2(screen_x + shoulder * 0.8, body_top + height * 0.1),
				Vector2(screen_x + shoulder * 1.5, body_top + height * 0.22),
				color.lightened(0.2),
				2.0
			)
		else:
			draw_circle(Vector2(screen_x + body_w * 0.35, body_top + height * 0.12), body_w * 0.09, ThemeBuilder.GOLD)
	if depth < 6.0:
		var font := ThemeDB.fallback_font
		var fs := clampi(int(22.0 / maxf(depth, 0.8)), 10, 18)
		var text_size := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_rect(
			Rect2(screen_x - text_size.x * 0.5 - 4, top - fs - 10, text_size.x + 8, fs + 4),
			Color(0, 0, 0, 0.55)
		)
		draw_string(
			font,
			Vector2(screen_x - text_size.x * 0.5, top - 8),
			name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			fs,
			ThemeBuilder.TEXT
		)


func _draw_hud(w: int, h: int, _focal: float, _horizon: int) -> void:
	var font := ThemeDB.fallback_font
	var fs := ThemeBuilder.fs(14)
	# Compass and location.
	var facing_names := ["N", "E", "S", "W"]
	draw_rect(Rect2(12, 12, 190, 30), Color(0, 0, 0, 0.55))
	draw_string(
		font,
		Vector2(22, 33),
		"%s   %s" % [String(Game.dungeon.display_name), facing_names[Game.facing]],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		ThemeBuilder.TEXT
	)
	# Crosshair.
	var cx := float(w) * 0.5
	var cy := float(h) * 0.5
	draw_circle(Vector2(cx, cy), 2.0, Color(0.9, 0.9, 0.85, 0.7))
	for offset in [Vector2(-9, 0), Vector2(9, 0), Vector2(0, -9), Vector2(0, 9)]:
		draw_line(Vector2(cx, cy) + offset * 0.4, Vector2(cx, cy) + offset, Color(0.9, 0.9, 0.85, 0.45), 1.0)
	# Placeholder watermark.
	draw_string(
		font,
		Vector2(14, float(h) - 14),
		"PLACEHOLDER ART — first-person grid view",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ThemeBuilder.fs(12),
		Color(0.75, 0.8, 0.85, 0.5)
	)
