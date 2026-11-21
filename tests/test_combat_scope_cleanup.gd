extends GutTest

## Combat-scope effects must not outlive the encounter that created them.
##
## Fighting defensively (PHB p.140), total defense (p.143) and Combat Expertise
## (p.92) all last until the start of a character's next turn, and that turn is
## measured inside one encounter. `Encounter.finish` is therefore the boundary:
## it must drop the effects and the encounter-only selections before
## `_resolve_encounter` writes the victory autosave, which serializes `effects`.
##
## These tests drive the real path: a real campaign game, real `Game` wrappers,
## the real resolution signal, the real autosave, and `Game.load_game` for the
## reload half. A fallback path (an ally finishes the fight) covers the case
## where the stance user cannot be the one who ends it.
##
## Slots: only the `auto` slot is written and every artifact is removed before
## and after each test. Run with an isolated APPDATA profile so no player save
## directory is touched.

const CAMPAIGN := "ravenloft_demo"
const SLOT := "auto"


func before_each() -> void:
	Game.reset_to_menu()
	Game.load_campaign(CAMPAIGN)
	_clean_slot()


func after_each() -> void:
	_clean_slot()
	Game.reset_to_menu()
	Game.load_campaign(CAMPAIGN)


func _clean_slot() -> void:
	SaveSystem.delete_save_everywhere(SLOT)
	for path in _prefixed_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _prefixed_files() -> Array:
	var found: Array = []
	for directory_path in [SaveSystem.campaign_dir(CAMPAIGN), SaveSystem.save_dir]:
		var directory := DirAccess.open(String(directory_path))
		if directory == null:
			continue
		for name in directory.get_files():
			if String(name).to_lower().begins_with(SLOT + ".json"):
				found.append(String(directory_path).path_join(String(name)))
	return found


func _slot_path() -> String:
	return SaveSystem.path_for(SLOT, CAMPAIGN)


## A real two-character game on `qa_victory`, with the zombie placed next to the
## stance user and the ally far enough away that casting provokes nothing.
func _start_duel(seed_value: int, party_ids: Array = ["kaelen", "ysolde"]) -> Dictionary:
	var started := Game.new_game(party_ids, seed_value)
	assert_true(bool(started.get("ok", false)), "a QA party starts: %s" % String(started.get("message", "")))
	var begun := Game.start_encounter("qa_victory")
	assert_true(bool(begun.get("ok", false)), "the QA encounter starts: %s" % String(begun.get("message", "")))
	var e := Game.encounter
	assert_not_null(e, "the encounter exists")
	var zombie: Character = null
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			zombie = entry["char"]
			entry["cell"] = Vector2i(3, 2)
	# The stance user's attack must commit without ending the fight, so the
	# zombie survives it; the ally's automatic-hit spell lands the killing blow.
	# A stationary zombie cannot close on the caster and make the cast provoke.
	zombie.max_hp = 40
	zombie.hp = 40
	zombie.speed_ft = 0
	var user: Character = Game.party[0]
	e.entry_for(user)["cell"] = Vector2i(2, 2)
	if Game.party.size() > 1:
		e.entry_for(Game.party[1])["cell"] = Vector2i(6, 2)
	# A lasting effect that has nothing to do with the stances: it must survive.
	user.add_effect("bless", "Bless", 3)
	return {"encounter": e, "user": user, "zombie": zombie}


func _advance_to(name: String) -> bool:
	var e := Game.encounter
	for _i in 40:
		if e == null or e.finished:
			return false
		var active := e.active_character()
		if active != null and String(active.id) == name and Game.mode == "combat":
			return true
		Game.combat_end_turn()
	return false


func _zombie_index() -> int:
	var e := Game.encounter
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			return int(entry["index"])
	return -1


## Ends the fight: the stance user attacks (committing the stance), and if the
## zombie survives, the ally's automatic-hit spell finishes it on the next turn.
func _finish_fight(use_attack: bool) -> void:
	var e := Game.encounter
	if use_attack:
		Game.combat_attack(_zombie_index())
	if e.finished:
		return
	assert_true(_advance_to("ysolde"), "the ally's turn arrives")
	for entry in e.combatants:
		if int(entry["team"]) == Encounter.TEAM_ENEMY:
			(entry["char"] as Character).hp = 1
	Game.combat_cast("magic_missile", _zombie_index())


func _saved_effects(character_id: String) -> Array:
	var text := FileAccess.get_file_as_string(_slot_path())
	assert_ne(text, "", "the victory autosave exists")
	var parsed = JSON.parse_string(text)
	assert_true(parsed is Dictionary, "the autosave parses")
	if not parsed is Dictionary:
		return []
	for entry in Array(Dictionary(parsed).get("party", [])):
		if String(Dictionary(entry).get("id", "")) == character_id:
			return Array(Dictionary(entry).get("effects", []))
	return []


func _has_saved_effect(character_id: String, effect_id: String) -> bool:
	for effect in _saved_effects(character_id):
		if String(Dictionary(effect).get("id", "")) == effect_id:
			return true
	return false


func _assert_clean_character(ch: Character, base_ac: int, label: String) -> void:
	assert_false(ch.has_effect("fighting_defensively"), "%s: no fighting-defensively effect" % label)
	assert_false(ch.has_effect("total_defense"), "%s: no total-defense effect" % label)
	assert_false(ch.has_effect("combat_expertise"), "%s: no Combat Expertise effect" % label)
	assert_true(ch.has_effect("bless"), "%s: the unrelated bless effect is preserved" % label)
	assert_eq(Rules.armor_class(ch), base_ac, "%s: AC is back to its base" % label)


# ------------------------------------------------------- fighting defensively

func test_fighting_defensively_does_not_survive_victory_or_the_autosave() -> void:
	var parts := _start_duel(7101)
	var user: Character = parts["user"]
	var base_ac := Rules.armor_class(user)
	assert_true(_advance_to("kaelen"), "the fighter's turn arrives")
	assert_true(bool(Game.combat_set_fight_defensively(true).get("ok", false)), "the stance is selected")
	var attack := Game.combat_attack(_zombie_index())
	assert_true(bool(attack.get("ok", false)), String(attack.get("message", "")))
	assert_true(user.has_effect("fighting_defensively"), "the committed attack activated the stance")
	_finish_fight(false)
	assert_eq(Game.encounter.outcome, "victory", "the fight is won")
	assert_eq(Game.mode, "explore", "resolution returned to exploration")
	_assert_clean_character(user, base_ac, "victory")
	assert_true(Game.encounter.fight_defensively_selected.is_empty(), "the encounter-only selection is cleared")
	assert_false(_has_saved_effect(user.id, "fighting_defensively"), "the autosave has no stance effect")
	assert_true(_has_saved_effect(user.id, "bless"), "the autosave keeps bless")
	assert_true(bool(Game.load_game(SLOT).get("ok", false)), "the autosave reloads")
	var reloaded := _party_character(user.id)
	assert_not_null(reloaded, "the reloaded party holds the character")
	if reloaded != null:
		_assert_clean_character(reloaded, base_ac, "reload")


# --------------------------------------------------------------- total defense

func test_total_defense_does_not_survive_victory_or_the_autosave() -> void:
	var parts := _start_duel(7102)
	var user: Character = parts["user"]
	var base_ac := Rules.armor_class(user)
	assert_true(_advance_to("kaelen"), "the fighter's turn arrives")
	assert_true(bool(Game.combat_total_defense().get("ok", false)), "total defense is taken")
	assert_true(user.has_effect("total_defense"), "the defense is active")
	assert_eq(Rules.armor_class(user), base_ac + 4, "and it grants its +4 dodge bonus")
	_finish_fight(false)
	assert_eq(Game.encounter.outcome, "victory", "the ally's spell wins the fight")
	assert_eq(Game.mode, "explore", "resolution returned to exploration")
	_assert_clean_character(user, base_ac, "victory")
	assert_false(_has_saved_effect(user.id, "total_defense"), "the autosave has no defense effect")
	assert_true(_has_saved_effect(user.id, "bless"), "the autosave keeps bless")
	assert_true(bool(Game.load_game(SLOT).get("ok", false)), "the autosave reloads")
	var reloaded := _party_character(user.id)
	assert_not_null(reloaded, "the reloaded party holds the character")
	if reloaded != null:
		_assert_clean_character(reloaded, base_ac, "reload")


# ----------------------------------------------------------- Combat Expertise

func test_combat_expertise_still_does_not_survive_victory_or_the_autosave() -> void:
	var parts := _start_duel(7103)
	var user: Character = parts["user"]
	user.feats.append("Combat Expertise")
	user.abilities["int"] = 13
	var base_ac := Rules.armor_class(user)
	assert_true(_advance_to("kaelen"), "the fighter's turn arrives")
	assert_true(bool(Game.combat_set_combat_expertise(2).get("ok", false)), "the amount is chosen")
	var attack := Game.combat_attack(_zombie_index())
	assert_true(bool(attack.get("ok", false)), String(attack.get("message", "")))
	assert_true(user.has_effect("combat_expertise"), "the committed attack created the effect")
	_finish_fight(false)
	assert_eq(Game.encounter.outcome, "victory", "the fight is won")
	_assert_clean_character(user, base_ac, "victory")
	assert_true(Game.encounter.combat_expertise_pending.is_empty(), "no pending choice survives")
	assert_false(_has_saved_effect(user.id, "combat_expertise"), "the autosave has no feat effect")
	assert_true(bool(Game.load_game(SLOT).get("ok", false)), "the autosave reloads")
	var reloaded := _party_character(user.id)
	if reloaded != null:
		_assert_clean_character(reloaded, base_ac, "reload")


# -------------------------------------------------------------------- defeat

func test_a_stance_is_cleared_on_defeat_and_no_autosave_is_written() -> void:
	var parts := _start_duel(7104, ["kaelen"])
	var user: Character = parts["user"]
	assert_true(_advance_to("kaelen"), "the fighter's turn arrives")
	assert_true(bool(Game.combat_total_defense().get("ok", false)), "total defense is taken")
	assert_true(user.has_effect("total_defense"), "the defense is active")
	user.take_damage(user.hp + 5)
	Game.combat_end_turn()
	assert_eq(Game.encounter.outcome, "defeat", "the party is defeated")
	assert_eq(Game.mode, "defeat", "defeat leaves combat for its own screen, not exploration")
	assert_false(user.has_effect("total_defense"), "the defense effect is cleared")
	assert_false(user.has_effect("fighting_defensively"), "no stance effect remains")
	assert_false(FileAccess.file_exists(_slot_path()), "defeat writes no autosave")


func _party_character(character_id: String) -> Character:
	for ch in Game.party:
		if String(ch.id) == character_id:
			return ch
	return null
