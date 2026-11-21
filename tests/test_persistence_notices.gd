extends GutTest

## The two persistence notices players can see: a read-only settings file is named
## at the top of the Settings panel, and a recovered load names its source both in
## the Load list and in the status line after it runs.

const SLOT := "slot1"
const CAMPAIGN := "ravenloft_demo"

var main: Control = null


func before_each() -> void:
	SaveSystem.delete_save(SLOT)
	Game.load_campaign(CAMPAIGN)
	Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4242)
	main = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main)
	await wait_frames(2)


func after_each() -> void:
	Game.settings_newer = false
	main = null
	SaveSystem.delete_save(SLOT)
	Game.reset_to_menu()
	Game.load_campaign(CAMPAIGN)


func _labels(node: Node) -> Array:
	var texts: Array = []
	for child in node.find_children("*", "Label", true, false):
		texts.append(String((child as Label).text))
	return texts


func _buttons(node: Node) -> Array:
	var found: Array = []
	for child in node.find_children("*", "Button", true, false):
		found.append(child as Button)
	return found


func _notice() -> Label:
	if main.modal == null:
		return null
	return main.modal.find_child("ModalNotice", true, false) as Label


## Leaves the slot with a valid backup and no primary, like a crash between the
## two renames of a save.
func _crashed_slot() -> void:
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var path := SaveSystem.path_for(SLOT, CAMPAIGN)
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var file := FileAccess.open(path + ".bak", FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Game.gold = 0


func test_the_settings_notice_shows_only_for_a_newer_file() -> void:
	main.call("_open_settings")
	await wait_frames(2)
	assert_null(_notice(), "a current settings file needs no notice")
	main.call("close_modal")
	await wait_frames(1)
	Game.settings_newer = true
	main.call("_open_settings")
	await wait_frames(2)
	var notice := _notice()
	assert_not_null(notice, "a read-only settings file is announced")
	if notice == null:
		return
	assert_string_contains(notice.text, "Read-only")
	assert_string_contains(notice.text, "not written")
	var panel: Rect2 = main.modal.get_global_rect()
	var rect := notice.get_global_rect()
	assert_true(rect.position.y >= panel.position.y, "the notice starts inside the panel")
	assert_true(rect.end.y <= panel.end.y, "the notice ends inside the panel")
	var scroll := main.get("modal_scroll") as ScrollContainer
	assert_not_null(scroll)
	assert_false(scroll.is_ancestor_of(notice), "the notice sits outside the scrolling body, so it cannot scroll away")
	assert_true(rect.end.y <= scroll.get_global_rect().position.y + 1.0, "the notice is above the scrolling body")


func test_the_settings_notice_does_not_prevent_editing() -> void:
	Game.settings_newer = true
	main.call("_open_settings")
	await wait_frames(2)
	var sliders: Array = main.modal.find_children("*", "HSlider", true, false)
	assert_gt(sliders.size(), 0, "the panel still offers its controls")
	var slider := sliders[0] as HSlider
	var before := slider.value
	slider.value = before + 1.0 if before < slider.max_value else before - 1.0
	assert_ne(slider.value, before, "a read-only file does not freeze this session's controls")


func test_the_load_panel_names_the_recovery_source() -> void:
	_crashed_slot()
	main.call("_open_load_modal")
	await wait_frames(2)
	var texts := _labels(main.modal)
	assert_true(texts.any(func(text: String) -> bool: return text.contains("(from backup)")), "the row says the backup will be used: %s" % [texts])


func test_the_save_panel_does_not_call_a_crashed_slot_empty() -> void:
	_crashed_slot()
	main.call("_open_save_modal")
	await wait_frames(2)
	var texts := _labels(main.modal)
	assert_true(texts.any(func(text: String) -> bool: return text.contains("interrupted")), "a crashed slot reads as interrupted: %s" % [texts])
	assert_false(texts.any(func(text: String) -> bool: return text == "slot1 — empty"), "the crashed slot is not reported as empty: %s" % [texts])


func test_a_recovered_load_says_which_file_it_used() -> void:
	_crashed_slot()
	main.call("_open_load_modal")
	await wait_frames(2)
	var target: Button = null
	for button in _buttons(main.modal):
		if String(button.text).contains("Load") and not String(button.text).contains("Load Game"):
			target = button
			break
	assert_not_null(target, "the load row has its button")
	if target == null:
		return
	target.pressed.emit()
	await wait_frames(3)
	var texts := _labels(main.modal) if main.modal != null else []
	assert_true(texts.any(func(text: String) -> bool: return text.contains("from its backup")), "the status line names the backup: %s" % [texts])
	assert_eq(Game.gold, int(JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.path_for(SLOT, CAMPAIGN) + ".bak")).get("gold", -1)), "the recovered state is live")
