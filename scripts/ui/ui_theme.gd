class_name UiTheme
extends RefCounted
## The shared look of every menu and HUD control: deep-sea colours, rounded
## panels, and big touch-friendly buttons. Top-level controls set
## `theme = UiTheme.shared()` and their children inherit it.

const INK := Color(0.92, 0.97, 1.0)
const DIM := Color(0.7, 0.8, 0.86)
const ACCENT := Color(0.5, 0.95, 0.85)
const GOLD := Color(1.0, 0.82, 0.4)
const COST := Color(1.0, 0.68, 0.5)
const GAIN := Color(0.55, 1.0, 0.6)
const LOSS := Color(1.0, 0.55, 0.45)
const PANEL := Color(0.03, 0.1, 0.16, 0.82)
const SHADE := Color(0.0, 0.03, 0.06, 0.94)
const BUTTON := Color(0.07, 0.2, 0.27, 0.95)
const BUTTON_HOVER := Color(0.1, 0.28, 0.36, 0.97)
const BUTTON_DOWN := Color(0.16, 0.42, 0.48, 1.0)
const EDGE := Color(0.45, 0.85, 0.85, 0.45)
const RADIUS := 18

static var _theme: Theme


static func shared() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## A rounded, translucent card for grouping HUD text or menu content.
static func panel(fill: Color = PANEL, pad: int = 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(RADIUS)
	box.set_content_margin_all(pad)
	box.border_color = Color(EDGE, 0.25)
	box.set_border_width_all(2)
	return box


## Text with a dark outline so it reads over the busy sea behind it.
static func outline(label: Control, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 24
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_stylebox("panel", "PanelContainer", panel())

	t.set_stylebox("normal", "Button", _button_box(BUTTON, EDGE))
	t.set_stylebox("hover", "Button", _button_box(BUTTON_HOVER, Color(EDGE, 0.8)))
	t.set_stylebox("pressed", "Button", _button_box(BUTTON_DOWN, ACCENT))
	t.set_stylebox("hover_pressed", "Button", _button_box(BUTTON_DOWN, ACCENT))
	t.set_stylebox("disabled", "Button", _button_box(Color(BUTTON, 0.5), Color(EDGE, 0.2)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", INK)
	t.set_font_size("font_size", "Button", 28)

	# A wide, rounded scroll grabber that a thumb can catch.
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(ACCENT, 0.55)
	grabber.set_corner_radius_all(14)
	grabber.content_margin_left = 14.0
	grabber.content_margin_right = 14.0
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.06)
	track.set_corner_radius_all(14)
	track.content_margin_left = 14.0
	track.content_margin_right = 14.0
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	t.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	t.set_stylebox("scroll", "VScrollBar", track)
	return t


static func _button_box(fill: Color, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(2)
	box.set_corner_radius_all(RADIUS)
	box.content_margin_left = 20.0
	box.content_margin_right = 20.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box
