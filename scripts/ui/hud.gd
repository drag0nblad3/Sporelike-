class_name Hud
extends CanvasLayer
## On-screen text, the touch joystick, and the pause button with its menu.
## The population screen is added as a child by Game.

var joystick: VirtualJoystick
var pause_menu: PauseMenu

var _energy: EnergyBar
var _generation: Label
var _species: Label
var _debug: Label
var _hint: Label
var _message: Label
var _message_timer := 0.0


func _ready() -> void:
	joystick = VirtualJoystick.new()
	add_child(joystick)

	_energy = EnergyBar.new()
	add_child(_energy)
	_species = _corner_label(Vector2(24, 36), 20)
	_debug = _corner_label(Vector2(24, 100), 18)
	_debug.modulate = Color(1, 1, 1, 0.5)

	_generation = _corner_label(Vector2(0, 34), 30)
	_generation.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_generation.offset_left = -360.0
	_generation.offset_right = -24.0
	_generation.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_hint = _center_label(-90.0, 28)
	_hint.text = "Drag on the left side to swim. Eat glowing food. Avoid the red hunters."
	_message = _center_label(-200.0, 40)

	var pause := Button.new()
	pause.text = "II  Help"
	pause.add_theme_font_size_override("font_size", 26)
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -180.0
	pause.offset_right = -24.0
	pause.offset_top = 80.0
	pause.offset_bottom = 140.0
	add_child(pause)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause.pressed.connect(pause_menu.open)


func _process(delta: float) -> void:
	_message_timer -= delta
	_message.visible = _message_timer > 0.0
	_debug.text = "FPS %d" % Engine.get_frames_per_second()


func show_status(energy: float, full: float, most: float) -> void:
	_energy.show_energy(energy, full, most)


func show_generation(number: int, seconds_left: float, food: int) -> void:
	_generation.text = "Gen %d  %ds  Food %d" % [number, ceili(maxf(seconds_left, 0.0)), food]


func show_species(population: int, births: int, averages: Dictionary) -> void:
	var parts := PackedStringArray()
	for t in Genome.TRAITS:
		parts.append("%s %.2f" % [t, averages[t]])
	_species.text = "Species %d (births %d)\n%s" % [population, births, "  ".join(parts)]


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
