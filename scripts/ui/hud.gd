class_name Hud
extends CanvasLayer
## On-screen text and the touch joystick.

var joystick: VirtualJoystick

var _status: Label
var _species: Label
var _debug: Label
var _hint: Label
var _message: Label
var _message_timer := 0.0


func _ready() -> void:
	joystick = VirtualJoystick.new()
	add_child(joystick)

	_status = _corner_label(Vector2(24, 18), 30)
	_species = _corner_label(Vector2(24, 60), 22)
	_debug = _corner_label(Vector2(24, 92), 18)
	_debug.modulate = Color(1, 1, 1, 0.5)

	_hint = _center_label(-90.0, 28)
	_hint.text = "Drag on the left side to swim. Eat green food. Avoid the red hunters."
	_message = _center_label(-200.0, 40)


func _process(delta: float) -> void:
	_message_timer -= delta
	_message.visible = _message_timer > 0.0
	_debug.text = "FPS %d" % Engine.get_frames_per_second()


func show_status(energy: float, max_energy: float, eaten: int) -> void:
	_status.text = "Energy %d/%d   Food %d" % [ceili(energy), int(max_energy), eaten]


func show_species(population: int, births: int, averages: Dictionary) -> void:
	_species.text = "Species %d  (births %d)   size %.2f  speed %.2f  sense %.2f  armor %.2f" % [
		population, births, averages["size"], averages["speed"],
		averages["sense"], averages["armor"]]


func set_hint_visible(visible_now: bool) -> void:
	_hint.visible = visible_now


func flash_message(text: String, seconds: float) -> void:
	_message.text = text
	_message_timer = seconds


func _corner_label(at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	_style(label, size)
	add_child(label)
	return label


func _center_label(from_bottom: float, size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = from_bottom
	label.offset_left = -600.0
	label.offset_right = 600.0
	_style(label, size)
	add_child(label)
	return label


func _style(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
