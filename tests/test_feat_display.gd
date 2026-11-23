extends GutTest

## Display-only batch: parameterised feat text shows a human-readable weapon name
## while everything that is stored, matched or selected keeps the raw parameter.
##
## `Feats.display_label` is the one place a displayed parameter is resolved, from
## the shipped item content - there is no lookup table. A parameter with no content
## entry falls back to the raw text: a bare authored id ("longsword", which is not
## an item id in this content) and an unknown id both keep what they were given
## rather than inventing a name.
##
## What stays raw, and is pinned here: `LevelChoices` rows keep `text` as the stored
## value the draft captures, `Feats.parse` still reports the item id, and a staged
## level-up still writes "Name (item_id)".

const RAW_SPECIALIZATION := "Weapon Specialization (masterwork_longsword)"
const LABEL_SPECIALIZATION := "Weapon Specialization (Masterwork Longsword)"

var content: ContentDB


func before_each() -> void:
	Game.load_campaign("ravenloft_demo")
	content = Game.content


func _fighter() -> Character:
	var ch := Character.from_content(
		Dictionary(content.characters["kaelen"]).duplicate(true), content.items
	)
	ch.hp = ch.max_hp
	return ch


func _row_by_key_param(rows: Array, key: String, parameter: String) -> Dictionary:
	for raw in rows:
		var row := Dictionary(raw)
		if String(row.get("key", "")) == key and String(row.get("param", "")) == parameter:
			return row
	return {}


# ----------------------------------------------------------------- labelling


func test_a_known_weapon_parameter_is_shown_by_name() -> void:
	assert_eq(
		Feats.display_label(RAW_SPECIALIZATION),
		LABEL_SPECIALIZATION,
		"the item id is shown as the item's authored name",
	)
	assert_eq(
		Feats.display_label("Weapon Specialization (dagger)"),
		"Weapon Specialization (Dagger)",
		"a simple weapon resolves too",
	)


## The authored Weapon Focus names the base weapon, which is not an item id here.
func test_a_bare_authored_parameter_falls_back_to_itself() -> void:
	assert_eq(
		Feats.display_label("Weapon Focus (longsword)"),
		"Weapon Focus (longsword)",
		"no content entry means the raw parameter is shown, not an invented name",
	)
	var parsed := Feats.parse("Weapon Focus (longsword)")
	assert_eq(String(parsed["param"]), "longsword", "and the parse still reports the raw parameter")


func test_an_unknown_item_id_falls_back_to_itself() -> void:
	assert_eq(
		Feats.display_label("Weapon Specialization (no_such_weapon)"),
		"Weapon Specialization (no_such_weapon)",
		"an unknown id is displayed as given",
	)


func test_an_unimplemented_feat_keeps_its_raw_text() -> void:
	assert_eq(
		Feats.display_label("Some Unimplemented Feat"),
		"Some Unimplemented Feat",
		"a feat outside the catalog is not rewritten",
	)


func test_a_feat_without_a_parameter_keeps_its_name() -> void:
	assert_eq(Feats.display_label("Iron Will"), "Iron Will", "no parameter, no parentheses")


## Scope: this batch resolves weapon parameters only; a skill parameter keeps the
## content id it already showed.
func test_a_skill_parameter_is_left_as_it_is() -> void:
	assert_eq(
		Feats.display_label("Skill Focus (search)"),
		"Skill Focus (search)",
		"skill parameters are out of this batch's scope",
	)


# ------------------------------------------------------------------ surfaces


func test_the_level_up_row_shows_the_name_and_keeps_the_raw_value() -> void:
	var ch := _fighter()
	ch.xp = 6000
	var rows := LevelChoices.feat_options(ch, {"ability": "str"})
	var row := _row_by_key_param(rows, "weapon_specialization", "masterwork_longsword")
	assert_false(row.is_empty(), "the specialization row exists")
	assert_eq(String(row.get("label", "")), LABEL_SPECIALIZATION, "the row's label is human-readable")
	assert_eq(String(row.get("text", "")), RAW_SPECIALIZATION, "the row's stored text is unchanged")
	assert_eq(
		String(Feats.parse(String(row.get("text", "")))["param"]),
		"masterwork_longsword",
		"and the stored parameter is still the item id",
	)


func test_the_character_sheet_names_the_weapon() -> void:
	var ch := _fighter()
	ch.feats.append(RAW_SPECIALIZATION)
	var found := ""
	for raw in Feats.describe(ch):
		var entry := Dictionary(raw)
		if String(entry.get("name", "")).begins_with("Weapon Specialization"):
			found = String(entry.get("name", ""))
	assert_eq(found, LABEL_SPECIALIZATION, "the sheet's feat row shows the item's name")


func test_an_unimplemented_sheet_feat_keeps_its_raw_text() -> void:
	var ch := _fighter()
	ch.feats.append("Some Unimplemented Feat")
	var found := ""
	for raw in Feats.describe(ch):
		var entry := Dictionary(raw)
		if String(entry.get("name", "")).contains("Unimplemented"):
			found = String(entry.get("name", ""))
	assert_eq(found, "Some Unimplemented Feat", "the sheet does not rewrite what it cannot resolve")
