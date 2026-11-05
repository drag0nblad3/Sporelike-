class_name DepthControl
extends Control
## Two buttons on the right edge to swim up or down one Depth, and a label
## with the depth the colony is at. Like AbilityBar, it reads screen touches
## directly so it works while another finger steers.

## step is +1 to rise, -1 to sink.
signal pressed(step: int)

## [left, top, right, bottom] offsets from the right edge's middle.
const UP_RECT := [-150, -260, -30, -160]
const DOWN_RECT := [-150, -140, -30, -40]

var _up: Button
var _down: Button
var _label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_up = _make("Rise", UP_RECT)
	_down = _make("Sink", DOWN_RECT)
	_label = Label.new()
	UiTheme.outline(_label, 22)
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_label.offset_left = -320
	_label.offset_right = -160
	_label.offset_top = -170
	_label.offset_bottom = -130
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_label)
	visible = false


func show_layer(layer: int) -> void:
	visible = true
	_label.text = Depth.title(layer)
	_up.disabled = layer >= Depth.SURFACE
	_down.disabled = layer <= Depth.FLOOR


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


func _make(text: String, rect: Array) -> Button:
	var button := Button.new()
	button.theme = UiTheme.shared()
	button.text = text
	button.add_theme_font_size_override("font_size", 24)
	button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	button.offset_left = rect[0]
	button.offset_top = rect[1]
	button.offset_right = rect[2]
	button.offset_bottom = rect[3]
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button
