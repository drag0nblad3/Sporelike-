class_name AnimalLabHud
extends CanvasLayer
## Controls for the stage 3 feel-test lab: the joystick on the left, the
## look pad on the right, a status line (the body and the frame rate), a
## New body button and Back.

signal new_body_pressed
signal back_pressed

var joystick := VirtualJoystick.new()
var look := LookPad.new()
var _status: Label
var _hint: Label


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.shared()
	add_child(root)
	root.add_child(joystick)
	root.add_child(look)
	_status = Label.new()
	_status.position = Vector2(24, 18)
	_status.size = Vector2(900, 80)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTheme.outline(_status, 26)
	root.add_child(_status)
	_hint = Label.new()
	_hint.text = "Left thumb: walk   ·   Right thumb: look around"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -70.0
	_hint.offset_left = -420.0
	_hint.offset_right = 420.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.outline(_hint, 24)
	root.add_child(_hint)
	root.add_child(_corner("Back", 20.0, func() -> void: back_pressed.emit()))
	root.add_child(_corner("New body", 110.0, func() -> void: new_body_pressed.emit()))


func steering() -> Vector2:
	return TouchSteer.read(joystick)


func show_status(body: AnimalBody) -> void:
	_status.text = "Stage 3 test  ·  %d FPS\n%s" % [roundi(Engine.get_frames_per_second()),
		body.describe()]


func _corner(label: String, top: float, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -230.0
	button.offset_right = -20.0
	button.offset_top = top
	button.offset_bottom = top + 72.0
	button.pressed.connect(action)
	return button
