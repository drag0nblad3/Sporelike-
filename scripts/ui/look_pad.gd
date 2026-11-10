class_name LookPad
extends Control
## The right side of the screen in stage 3: drag a finger there to look
## around (ChaseCamera.drag). It follows its own finger, so it works while
## the other thumb steers with the joystick on the left.

signal dragged(yaw: float, pitch: float)

## Share of the screen width, from the left, that belongs to the joystick.
const START := VirtualJoystick.ACTIVE_AREA
const YAW_PER_PIXEL := -0.008
const PITCH_PER_PIXEL := 0.005

## Off while a panel (the body customizer) covers the right side.
var enabled := true
var _finger := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _finger == -1 and enabled \
				and touch.position.x >= get_viewport_rect().size.x * START:
			_finger = touch.index
		elif not touch.pressed and touch.index == _finger:
			_finger = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _finger:
			dragged.emit(drag.relative.x * YAW_PER_PIXEL, drag.relative.y * PITCH_PER_PIXEL)
