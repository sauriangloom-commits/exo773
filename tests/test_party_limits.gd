extends GutTest

## The declared party contract: the campaign's own party.min and party.max are
## enforced at party selection and at the authoritative new-game entry point.
##
## The point of these tests is that the size rule is the campaign's, not the
## screen's, and that a refused request cannot replace live state. Ashwick now
## declares 3-4; campaigns that still declare 1-4 must behave exactly as before.

const ASHWICK := "ashwick_ferry"
const DEMO := "ravenloft_demo"
const SLOT := "party_limits_qa"
const FIVE := ["kaelen", "sera", "aldric", "ysolde", "mira"]

var main: Control


func before_each() -> void:
	Game.playtest_mode = false
	SaveSystem.delete_save_everywhere(SLOT)
	SaveSystem.delete_save_everywhere("auto")


func after_each() -> void:
	if main != null:
		main.queue_free()
		main = null
	SaveSystem.delete_save_everywhere(SLOT)
	SaveSystem.delete_save_everywhere("auto")
	Game.load_campaign(DEMO)


# ------------------------------------------------------------------ pure limits

func test_limits_come_from_the_campaign_and_keep_the_authored_fallback() -> void:
	assert_eq(Game.party_limits({"party": {"default": ["kaelen"], "min": 1, "max": 4}}), {"min": 1, "max": 4})
	assert_eq(Game.party_limits({"party": {"default": ["kaelen"], "min": 3, "max": 4}}), {"min": 3, "max": 4})
	# A campaign that omits party limits keeps the existing 1-4 fallback.
	assert_eq(Game.party_limits({"party": {"default": ["kaelen"]}}), {"min": 1, "max": 4})
	assert_eq(Game.party_limits({"party": {"default": ["kaelen"], "min": 2}}), {"min": 2, "max": 4})
	assert_eq(Game.party_range_text({"party": {"min": 3, "max": 4}}), "three to four")
	assert_eq(Game.party_range_text({"party": {"min": 3, "max": 3}}), "three")
	assert_eq(Game.party_size_error(1, {"party": {"min": 2, "max": 3}}), "Choose at least two adventurers.")
	assert_eq(Game.party_size_error(4, {"party": {"min": 2, "max": 3}}), "Choose at most three adventurers.")
	assert_eq(Game.party_size_error(3, {"party": {"min": 2, "max": 3}}), "")


func test_loaded_campaigns_report_their_own_declared_range() -> void:
	var ashwick := Game.load_campaign(ASHWICK)
	assert_true(bool(ashwick.get("ok", false)), String(ashwick.get("message", "")))
	assert_eq(Game.party_limits(), {"min": 3, "max": 4})
	var demo := Game.load_campaign(DEMO)
	assert_true(bool(demo.get("ok", false)), String(demo.get("message", "")))
	assert_eq(Game.party_limits(), {"min": 1, "max": 4})


# --------------------------------------------------------------- new_game rule

func test_new_game_enforces_the_ashwick_minimum_and_refuses_before_starting() -> void:
	var loaded := Game.load_campaign(ASHWICK)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	var mode_before := Game.mode
	var party_before := Game.party.size()
	var too_few := Game.new_game(["kaelen", "sera"], 4242)
	assert_false(bool(too_few.get("ok", false)), "two characters are refused")
	assert_eq(String(too_few.get("message", "")), "Choose at least three adventurers.")
	assert_eq(Game.mode, mode_before, "a refused request starts nothing")
	assert_eq(Game.party.size(), party_before, "a refused request fills no party")
	var three := Game.new_game(["kaelen", "sera", "aldric"], 4242)
	assert_true(bool(three.get("ok", false)), String(three.get("message", "")))
	assert_eq(Game.party.size(), 3)
	var four := Game.new_game(["kaelen", "sera", "aldric", "ysolde"], 4243)
	assert_true(bool(four.get("ok", false)), String(four.get("message", "")))
	assert_eq(Game.party.size(), 4)
	var too_many := Game.new_game(FIVE, 4244)
	assert_false(bool(too_many.get("ok", false)), "the campaign maximum still applies")
	assert_eq(String(too_many.get("message", "")), "Choose at most four adventurers.")
	assert_eq(Game.party.size(), 4, "the refused five-character request kept the live party")


func test_refused_new_game_preserves_campaign_session_and_save_state() -> void:
	var demo := Game.load_campaign(DEMO)
	assert_true(bool(demo.get("ok", false)), String(demo.get("message", "")))
	var started := Game.new_game(["kaelen"], 4242)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))
	var saved := Game.save_game(SLOT)
	assert_true(bool(saved.get("ok", false)), String(saved.get("message", "")))
	var path := SaveSystem.path_for(SLOT, DEMO)
	var bytes_before := FileAccess.get_file_as_string(path)
	assert_ne(bytes_before, "", "the demo save exists before the refused request")
	var area_before := Game.area_id
	var position_before := Game.position
	var seed_before := Game.seed_value
	var quests_before := Game.quests.status("drowned_bell")
	var hp_before: int = Game.party[0].hp

	# A refused request that also asks to switch campaign must not switch it.
	var refused := Game.new_game(["kaelen", "sera"], 999, ASHWICK)
	assert_false(bool(refused.get("ok", false)))
	assert_eq(String(refused.get("message", "")), "Choose at least three adventurers.")
	assert_eq(Game.campaign_id, DEMO, "the live campaign is unchanged")
	assert_eq(Game.content_version, 1, "the live content is unchanged")
	assert_eq(Game.party.size(), 1, "the live party is unchanged")
	assert_eq(Game.area_id, area_before)
	assert_eq(Game.position, position_before)
	assert_eq(Game.seed_value, seed_before)
	assert_eq(Game.quests.status("drowned_bell"), quests_before)
	assert_eq(Game.party[0].hp, hp_before)
	assert_eq(FileAccess.get_file_as_string(path), bytes_before, "the existing save is untouched")

	# The same request with an allowed party still switches and starts.
	var accepted := Game.new_game(["kaelen", "sera", "aldric"], 999, ASHWICK)
	assert_true(bool(accepted.get("ok", false)), String(accepted.get("message", "")))
	assert_eq(Game.campaign_id, ASHWICK)
	assert_eq(Game.party.size(), 3)


func test_campaigns_that_keep_one_to_four_are_unchanged() -> void:
	var loaded := Game.load_campaign(DEMO)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	var single := Game.new_game(["kaelen"], 4242)
	assert_true(bool(single.get("ok", false)), "a one-character party still starts the demo")
	assert_eq(Game.party.size(), 1)
	var defaults := Game.new_game([], 4243)
	assert_true(bool(defaults.get("ok", false)), "an empty selection still uses the authored default")
	assert_eq(Game.party.size(), 4)
	var too_many := Game.new_game(FIVE, 4244)
	assert_false(bool(too_many.get("ok", false)))
	assert_eq(String(too_many.get("message", "")), "Choose at most four adventurers.")


# ------------------------------------------------------------------ save policy

func test_existing_v2_save_below_the_new_minimum_still_loads() -> void:
	var loaded := Game.load_campaign(ASHWICK)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_eq(Game.content_version, 2, "only the new-game restriction changed; the content version did not")
	var started := Game.new_game(["kaelen", "sera", "aldric"], 4242)
	assert_true(bool(started.get("ok", false)), String(started.get("message", "")))
	# A save written before the restriction could hold fewer characters. Write the
	# same version-2 payload with the party trimmed, which is what such a save is.
	var payload := Game.serialize()
	payload["party"] = Array(payload["party"]).slice(0, 2)
	var written := SaveSystem.write_save(SLOT, payload, ASHWICK)
	assert_true(bool(written.get("ok", false)), String(written.get("message", "")))
	var restored := Game.load_game(SLOT)
	assert_true(bool(restored.get("ok", false)), "a two-character v2 save still loads: " + String(restored.get("message", "")))
	assert_eq(Game.party.size(), 2, "load compatibility is separate from new-game eligibility")
	assert_eq(Game.campaign_id, ASHWICK)
	assert_eq(Game.area_id, "ashwick_landing")


# ------------------------------------------------------------------- party UI

func _open_party_select() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main.call("_show_party_select")
	await get_tree().process_frame
	await get_tree().process_frame


func _scroll() -> ScrollContainer:
	var scrolls := main.find_children("*", "ScrollContainer", true, false)
	return scrolls[0] as ScrollContainer if not scrolls.is_empty() else null


func _checks() -> Array[CheckBox]:
	var out: Array[CheckBox] = []
	var scroll := _scroll()
	if scroll == null:
		return out
	for node in scroll.find_children("*", "CheckBox", true, false):
		out.append(node as CheckBox)
	return out


func _button(text: String) -> Button:
	var found := main.call("_probe_buttons", main, text) as Array
	return found[0] as Button if not found.is_empty() else null


func _visible_text() -> String:
	var parts: Array[String] = []
	for node in main.find_children("*", "Label", true, false):
		parts.append((node as Label).text)
	return "\n".join(parts)


## Selects exactly these character ids. Cards are matched by their own id, not
## by grid position, so the check does not depend on content ordering.
func _select_only(ids: Array) -> void:
	var seen := 0
	for check in _checks():
		var id := String(check.get_meta("character_id", ""))
		seen += 1
		check.button_pressed = ids.has(id)
	assert_eq(seen, 5, "all five pregens are offered")
	await get_tree().process_frame
	await get_tree().process_frame


func test_party_selection_shows_the_ashwick_range_and_refuses_two() -> void:
	var loaded := Game.load_campaign(ASHWICK)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	assert_string_contains(String(Game.campaign.get("description", "")), "three or four adventurers")
	await _open_party_select()
	var text := _visible_text()
	assert_true(text.contains("Pick three to four adventurers"), "the screen states the real campaign range:\n" + text)
	var begin := _button("Begin")
	var error := main.get("party_error") as Label
	assert_not_null(begin, "Begin is present")
	assert_not_null(error, "the selection reason is present")
	if begin == null or error == null:
		return
	assert_false(begin.disabled, "four default characters satisfy the minimum")
	assert_eq(error.text, "4 selected.")
	await _select_only(["kaelen", "sera"])
	assert_eq(error.text, "Choose at least three adventurers.", "two characters show the real minimum")
	assert_true(begin.disabled, "Begin is unavailable below the minimum")
	var before := Game.party.size()
	begin.emit_signal("pressed")
	await get_tree().process_frame
	assert_eq(error.text, "Pick three to four adventurers.", "Begin states the campaign range")
	assert_eq(Game.party.size(), before, "two characters cannot begin")
	await _select_only(["kaelen", "sera", "aldric"])
	assert_eq(error.text, "3 selected.")
	assert_false(begin.disabled, "three characters satisfy the minimum")
	begin.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(Game.party.size(), 3, "three characters begin")
	assert_eq(Game.campaign_id, ASHWICK)


func test_party_selection_keeps_one_to_four_behavior_and_wording() -> void:
	var loaded := Game.load_campaign(DEMO)
	assert_true(bool(loaded.get("ok", false)), String(loaded.get("message", "")))
	await _open_party_select()
	var text := _visible_text()
	assert_true(text.contains("Pick one to four adventurers"), "the demo keeps its range:\n" + text)
	var begin := _button("Begin")
	var error := main.get("party_error") as Label
	assert_not_null(begin, "Begin is present")
	assert_not_null(error, "the selection reason is present")
	if begin == null or error == null:
		return
	await _select_only(["kaelen"])
	assert_eq(error.text, "1 selected.", "the demo still accepts one character")
	assert_false(begin.disabled, "one character keeps Begin available")
	await _select_only(["kaelen", "sera", "aldric", "ysolde", "mira"])
	assert_eq(error.text, "Choose at most four adventurers.")
	assert_true(begin.disabled, "a fifth character makes Begin unavailable")
	var before := Game.party.size()
	begin.emit_signal("pressed")
	await get_tree().process_frame
	assert_eq(error.text, "Pick one to four adventurers.")
	assert_eq(Game.party.size(), before, "five characters cannot begin")
	await _select_only(["kaelen", "sera", "aldric", "ysolde"])
	assert_eq(error.text, "4 selected.")
	assert_false(begin.disabled)
	begin.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(Game.party.size(), 4, "four characters still begin")
