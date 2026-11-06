class_name DepthControl
extends Control
## The multicellular stage's depth panel on the right edge, between the
## pause button and the ability buttons: Rise and Sink buttons either side
## of a small gauge that lights the colony's Depth (surface on top, sea
## floor at the bottom) and names it. Like AbilityBar, it reads screen
## touches directly so it works while another finger steers.

## step is +1 to rise, -1 to sink.
signal pressed(step: int)

## The panel as offsets from the top-right corner: [left, top, right, bottom].
## It sits below the pause button (ends at 226) and above the ability
## buttons (start 370 up from the bottom of a 720 high screen).
const PANEL := [-440.0, 240.0, -20.0, 350.0]
const BUTTON_W := 116.0

var _layer := -1
var _up: Button
var _down: Button
var _gauge: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := Panel.new()
	back.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PANEL, 0))
	_place(back, PANEL[0], PANEL[2])
	_up = _make("Rise", PANEL[0], PANEL[0] + BUTTON_W)
	_down = _make("Sink", PANEL[2] - BUTTON_W, PANEL[2])
	_gauge = Control.new()
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_gauge, PANEL[0], PANEL[2])
	_gauge.draw.connect(_draw_gauge)
	visible = false


func show_layer(layer: int) -> void:
	visible = true
	if layer == _layer:
		return
	_layer = layer
	_up.disabled = layer >= Depth.SURFACE
	_down.disabled = layer <= Depth.FLOOR
	_gauge.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	if not touch.pressed:
		return
	for pair in [[_up, 1], [_down, -1]]:
		var button: Button = pair[0]
		if not button.disabled and button.get_global_rect().has_point(touch.position):
			get_viewport().set_input_as_handled()
			pressed.emit(int(pair[1]))
			return


## Three stacked marks (surface on top) with the current one lit, the depth's
## name beside them, and an arrow on each button.
func _draw_gauge() -> void:
	var h := _gauge.size.y
	var mid := _gauge.size.x * 0.5
	var font := _gauge.get_theme_default_font()
	for layer: int in [Depth.SURFACE, Depth.OPEN, Depth.FLOOR]:
		var y := h * 0.5 + (Depth.OPEN - layer) * 26.0
		var lit := layer == _layer
		var dot := Rect2(mid - 88.0, y - 7.0, 30.0, 14.0)
		_gauge.draw_rect(dot, UiTheme.ACCENT if lit else Color(UiTheme.DIM, 0.3))
	var name_at := Vector2(mid - 48.0, h * 0.5 + 8.0)
	_gauge.draw_string(font, name_at, Depth.title(_layer), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 20,
		UiTheme.INK)
	_arrow(Vector2(BUTTON_W * 0.5, 26.0), -1.0, _up.disabled)
	_arrow(Vector2(_gauge.size.x - BUTTON_W * 0.5, h - 26.0), 1.0, _down.disabled)


func _arrow(at: Vector2, dir: float, off: bool) -> void:
	var tip := at + Vector2(0, 9.0 * dir)
	var points := PackedVector2Array([tip, at + Vector2(-12, -7 * dir), at + Vector2(12, -7 * dir)])
	_gauge.draw_colored_polygon(points, Color(UiTheme.ACCENT, 0.25 if off else 0.9))


func _make(text: String, left: float, right: float) -> Button:
	var button := Button.new()
	button.theme = UiTheme.shared()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	_place(button, left, right)
	button.offset_left += 6.0
	button.offset_right -= 6.0
	button.offset_top += 6.0
	button.offset_bottom -= 6.0
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	return button


func _place(node: Control, left: float, right: float) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	node.offset_left = left
	node.offset_right = right
	node.offset_top = PANEL[1]
	node.offset_bottom = PANEL[3]
	add_child(node)
