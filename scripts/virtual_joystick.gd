class_name VirtualJoystick
extends Control
## Floating touch joystick. Touch anywhere on the left 60% of the screen and
## drag to steer. Mouse works too, because the project emulates touch from the
## mouse (Project Settings > Input Devices > Pointing).

const BASE_RADIUS := 110.0
const KNOB_RADIUS := 45.0
const ACTIVE_AREA := 0.6

## Steering value, length 0 to 1. Up on screen is negative Y.
var output := Vector2.ZERO

var _touch_index := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_active() -> bool:
	return _touch_index != -1


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			if touch.position.x < get_viewport_rect().size.x * ACTIVE_AREA:
				_touch_index = touch.index
				_center = touch.position
				_knob = touch.position
				_update_output()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			output = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_knob = drag.position
			_update_output()


func _update_output() -> void:
	var offset := _knob - _center
	if offset.length() > BASE_RADIUS:
		offset = offset.normalized() * BASE_RADIUS
		_knob = _center + offset
	output = offset / BASE_RADIUS
	queue_redraw()


func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_center, BASE_RADIUS, Color(1, 1, 1, 0.1))
	draw_arc(_center, BASE_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(_knob, KNOB_RADIUS, Color(0.6, 0.95, 1.0, 0.55))
