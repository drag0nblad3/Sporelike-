class_name TouchButton
extends Button
## A button that reads screen touches itself, so it works while another
## finger holds the joystick (Godot's own buttons only follow the first
## finger). Emits tapped. Looks like any other button.

signal tapped


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE


func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch or disabled or not is_visible_in_tree():
		return
	var touch := event as InputEventScreenTouch
	if touch.pressed and get_global_rect().has_point(touch.position):
		get_viewport().set_input_as_handled()
		tapped.emit()


## Makes one in the top-right corner stack, `top` pixels down.
static func corner(parent: Control, label: String, top: float, action: Callable) -> TouchButton:
	var button := TouchButton.new()
	button.text = label
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -230.0
	button.offset_right = -20.0
	button.offset_top = top
	button.offset_bottom = top + 72.0
	button.tapped.connect(action)
	parent.add_child(button)
	return button
