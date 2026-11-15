class_name ThemeBuilder
extends RefCounted

## Central visual theme for the placeholder UI.
## All colors are paired with text, borders or labels so meaning never depends
## on color alone.

const BG := Color("#0b1015")
const PANEL := Color("#141b22")
const PANEL_ALT := Color("#1b2530")
const PANEL_DEEP := Color("#0f151b")
const BORDER := Color("#3b4c5c")
const TEXT := Color("#e9e3d3")
const MUTED := Color("#a7b4c0")
const GOLD := Color("#d6b45f")
const GOOD := Color("#7fb37a")
const DANGER := Color("#d07a6f")
const BLUE := Color("#6f9fc4")


static func fs(base: int) -> int:
	return maxi(10, int(round(float(base) * float(Game.settings.get("text_scale", 1.0)))))


static func _box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


static func build(base_size := 16) -> Theme:
	var t := Theme.new()
	t.default_font_size = fs(base_size)
	t.set_stylebox("normal", "Button", _box(PANEL_ALT, BORDER, 1, 6))
	t.set_stylebox("hover", "Button", _box(Color("#263645"), GOLD, 1, 6))
	t.set_stylebox("pressed", "Button", _box(Color("#33465a"), GOLD, 2, 6))
	t.set_stylebox("disabled", "Button", _box(Color("#111821"), Color("#2a3540"), 1, 6))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD, 2, 6))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("#72808c"))
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, BORDER, 1, 8))
	t.set_stylebox("panel", "Panel", _box(PANEL, BORDER, 1, 8))
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_stylebox("background", "ProgressBar", _box(PANEL_DEEP, BORDER, 1, 4))
	t.set_stylebox("fill", "ProgressBar", _box(GOLD, GOLD, 0, 4))
	t.set_color("font_color", "ProgressBar", TEXT)
	t.set_stylebox("scroll", "VScrollBar", _box(PANEL_DEEP, BORDER, 1, 4))
	t.set_stylebox("grabber", "VScrollBar", _box(BORDER, GOLD, 1, 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", _box(Color("#5b7185"), GOLD, 1, 4))
	t.set_stylebox("normal", "LineEdit", _box(PANEL_DEEP, BORDER, 1, 4))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("slider", "HSlider", _box(PANEL_DEEP, BORDER, 1, 4))
	t.set_stylebox("grabber_area", "HSlider", _box(GOLD, GOLD, 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(Color("#e8cd86"), GOLD, 0, 4))
	t.set_stylebox("tab_selected", "TabContainer", _box(PANEL_ALT, GOLD, 1, 6))
	t.set_stylebox("tab_unselected", "TabContainer", _box(PANEL_DEEP, BORDER, 1, 6))
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_color", "CheckButton", TEXT)
	return t


static func heading(text: String, size := 28) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", fs(size))
	label.add_theme_color_override("font_color", GOLD)
	return label


static func body(text: String, muted := false, size := 16) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", fs(size))
	label.add_theme_color_override("font_color", MUTED if muted else TEXT)
	return label


## Short, non-wrapping label for header/status bars. Using autowrap labels in
## a horizontal header lets them collapse to a few pixels, which broke layout.
static func short(text_value: String, muted := false, size := 16) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", fs(size))
	label.add_theme_color_override("font_color", MUTED if muted else TEXT)
	return label


static func separator() -> HSeparator:
	var sep := HSeparator.new()
	var box := StyleBoxFlat.new()
	box.bg_color = BORDER
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", box)
	return sep
