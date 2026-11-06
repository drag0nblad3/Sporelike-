class_name Hud
extends CanvasLayer
## On-screen readouts, the touch joystick, and the pause button with its menu.
## The population screen is added as a child by Game.

signal ability_pressed(id: String)
## The multicellular stage's Rise (+1) or Sink (-1) button.
signal depth_pressed(step: int)

var joystick: VirtualJoystick
var pause_menu: PauseMenu

var _energy: EnergyBar
var _abilities: AbilityBar
var _depth: DepthControl
var _generation: GenerationReadout
var _species: SpeciesReadout
var _debug: Label
var _hint: Label
var _message: Label
var _message_timer := 0.0


func _ready() -> void:
	joystick = VirtualJoystick.new()
	add_child(joystick)

	_energy = EnergyBar.new()
	add_child(_energy)
	_species = SpeciesReadout.new()
	add_child(_species)
	_generation = GenerationReadout.new()
	add_child(_generation)

	_debug = Label.new()
	UiTheme.outline(_debug, 16)
	_debug.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_debug.offset_left = 12.0
	_debug.offset_top = -30.0
	_debug.modulate = Color(1, 1, 1, 0.35)
	add_child(_debug)

	# Both sit in the middle third so they clear the joystick on the left and
	# the ability buttons on the right.
	_hint = _center_label(-150.0, 24, UiTheme.INK)
	_hint.text = "Drag on the left side to swim. Eat glowing food. Avoid the red hunters."
	_hint.offset_left = -280.0
	_hint.offset_right = 280.0
	_hint.add_theme_stylebox_override("normal", UiTheme.panel(Color(UiTheme.PANEL, 0.7), 10))
	_message = _center_label(-260.0, 40, UiTheme.GOLD)

	var pause := _corner_button("II  Help", 26, Vector2(170, 76))
	pause.offset_top = 150.0
	pause.offset_bottom = 150.0 + 76.0
	pause.offset_right = -20.0
	pause.offset_left = -20.0 - 170.0
	_abilities = AbilityBar.new()
	add_child(_abilities)
	_abilities.pressed.connect(func(id: String) -> void: ability_pressed.emit(id))
	_depth = DepthControl.new()
	add_child(_depth)
	_depth.pressed.connect(func(step: int) -> void: depth_pressed.emit(step))
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause.pressed.connect(pause_menu.open)


func _process(delta: float) -> void:
	_message_timer -= delta
	_message.visible = _message_timer > 0.0
	_debug.text = "FPS %d" % Engine.get_frames_per_second()


func show_status(energy: float, full: float, most: float) -> void:
	_energy.show_energy(energy, full, most)


## fed: energy gathered this generation over what the body burns in one.
func show_generation(number: int, seconds_left: float, fed: float) -> void:
	_generation.show_generation(number, seconds_left, fed)


func show_species(population: int, births: int, averages: Dictionary) -> void:
	_species.show_species(population, births, averages)


## Shows the ability buttons this body has, dimmed while recharging.
func show_abilities(g: Genome, timers: AbilityTimers) -> void:
	_abilities.show_for(g, timers)


func show_colony_abilities(plan: BodyPlan, timers: AbilityTimers) -> void:
	_abilities.show_colony(plan, timers)


func hide_abilities() -> void:
	_abilities.hide_all()
	_depth.visible = false


func show_depth(layer: int) -> void:
	_depth.show_layer(layer)


func set_hint_visible(visible_now: bool) -> void:
	_hint.visible = visible_now


func flash_message(text: String, seconds: float) -> void:
	_message.text = text
	_message_timer = seconds


func _corner_button(label: String, font_size: int, min_size: Vector2) -> Button:
	var button := Button.new()
	button.theme = UiTheme.shared()
	button.text = label
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", font_size)
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	add_child(button)
	return button


func _center_label(from_bottom: float, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = from_bottom
	label.offset_bottom = from_bottom
	label.grow_vertical = Control.GROW_DIRECTION_END
	label.offset_left = -320.0
	label.offset_right = 320.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTheme.outline(label, font_size)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
	return label
