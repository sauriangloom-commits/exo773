extends Node

## QA tooling only — excluded from export (tools/*).
## Prints every Button label with its global rect at the project's 1280x720
## canvas size so native acceptance runs can target real controls instead of
## guessing coordinates from screenshots. Changes no gameplay code.

var main: Node


func _dump(label: String, node: Node) -> void:
	print("--- ", label)
	if node == null:
		print("  (null)")
		return
	var found := 0
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		var rect := button.get_global_rect()
		print("BTN|\"%s\"|%d,%d|%dx%d|enabled=%s" % [
			button.text,
			int(rect.position.x),
			int(rect.position.y),
			int(rect.size.x),
			int(rect.size.y),
			str(not button.disabled),
		])
		found += 1
	if found == 0:
		print("  (no buttons)")


func _settle(frames := 3) -> void:
	for i in frames:
		await get_tree().process_frame


func _ready() -> void:
	# Match the shipped window exactly so every printed rect is usable as a
	# native click coordinate. Headless defaults to a square viewport.
	get_window().size = Vector2i(1280, 720)
	await _settle(4)
	print("VIEWPORT=", get_viewport().get_visible_rect().size)
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _settle()
	print("MODE=", Game.mode)
	_dump("menu", main.current_screen)

	main._open_settings()
	await _settle()
	_dump("settings", main.modal)
	main.close_modal()
	await _settle()

	main._open_save_modal()
	await _settle()
	_dump("save-modal", main.modal)
	main.close_modal()
	await _settle()

	# Combat layout for the E3 encounter used by acceptance. Route through Main so
	# the screen gets exactly the layout the shipped game uses.
	Game.new_game(["kaelen", "aldric", "ysolde", "mira"], 424242)
	var started := Game.start_encounter("town_square_zombies")
	print("ENCOUNTER_OK=", str(started.get("ok", false)))
	main._route()
	await _settle(5)
	print("MODE_AFTER=", Game.mode)
	var combat = main.current_screen
	print("SCREEN=", combat.get_class())
	_dump("combat-actions", combat.button_box)
	_dump("combat-targets", combat.target_box)

	# Exact cell centres so native runs can click squares, not guess them.
	var view = combat.view
	print("MAP=", Game.encounter.map.width, "x", Game.encounter.map.height)
	print("VIEW_RECT=", view.get_global_rect(), " CELL=", view.cell_size, " ORIGIN=", view.origin)
	var base: Vector2 = view.get_global_rect().position + view.origin
	for entry in Game.encounter.combatants:
		var ch: Character = entry["char"]
		var cell: Vector2i = entry["pos"]
		var centre := base + Vector2(cell.x + 0.5, cell.y + 0.5) * view.cell_size
		print("CELL|%s|team=%d|%d,%d|%d,%d" % [
			ch.display_name, int(entry["team"]), cell.x, cell.y, int(centre.x), int(centre.y)
		])
	get_tree().quit()
