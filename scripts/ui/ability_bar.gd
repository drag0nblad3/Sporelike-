class_name AbilityBar
extends Control
## The round ability buttons in the bottom-right corner: a big Jet button
## every cell has, and a smaller one around it for each ability organelle
## the body has grown. Buttons dim while recharging. Buttons read screen
## touches directly, so they work while another finger steers: Godot's
## emulated mouse only follows the first finger on the screen. A colony's
## abilities (ColonyAbility) use the same spots.

signal pressed(id: String)

## Button rectangle per ability, as offsets from the bottom-right corner:
## [left, top, right, bottom].
const SLOTS := {
	"jet": [-200, -200, -40, -40],
	"trichocysts": [-350, -160, -230, -40],
	"toxicysts": [-160, -350, -40, -230],
	"flash": [-330, -330, -220, -220],
	"surge": [-200, -200, -40, -40],
	"curl": [-350, -160, -230, -40],
	"sting": [-160, -350, -40, -230],
}

var _buttons := {}
## Ability id held down by each touch index.
var _held := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in Ability.ALL + ColonyAbility.ALL:
		_buttons[id] = _make(id)


## Shows the buttons this body can use, dimmed while recharging.
func show_for(g: Genome, timers: AbilityTimers) -> void:
	for id in Ability.ALL:
		_show(id, Ability.has(g, id), timers)


## The same for a colony's abilities.
func show_colony(plan: BodyPlan, timers: AbilityTimers) -> void:
	for id in ColonyAbility.ALL:
		_show(id, ColonyAbility.has(plan, id), timers)


func _show(id: String, owned: bool, timers: AbilityTimers) -> void:
	var button: Button = _buttons[id]
	button.visible = owned
	if owned:
		button.modulate.a = 1.0 if timers.ready(id) else 0.35 + 0.3 * (1.0 - timers.fraction(id))


func hide_all() -> void:
	for id in _buttons:
		var button: Button = _buttons[id]
		button.visible = false


func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	if touch.pressed:
		var id := _button_at(touch.position)
		if id != "":
			_held[touch.index] = id
			(_buttons[id] as Button).button_pressed = true
			get_viewport().set_input_as_handled()
			pressed.emit(id)
	elif _held.has(touch.index):
		var id: String = _held[touch.index]
		_held.erase(touch.index)
		if not _held.values().has(id):
			(_buttons[id] as Button).button_pressed = false
		get_viewport().set_input_as_handled()


func _button_at(pos: Vector2) -> String:
	for id in _buttons:
		var button: Button = _buttons[id]
		if button.is_visible_in_tree() and button.get_global_rect().has_point(pos):
			return id
	return ""


func _make(id: String) -> Button:
	var rect: Array = SLOTS[id]
	var big := id == "jet" or id == "surge"
	var button := Button.new()
	button.theme = UiTheme.shared()
	button.text = Ability.BUTTON[id] if Ability.is_ability(id) else ColonyAbility.BUTTON[id]
	button.add_theme_font_size_override("font_size", 34 if big else 24)
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = rect[0]
	button.offset_top = rect[1]
	button.offset_right = rect[2]
	button.offset_bottom = rect[3]
	var tint: Color = UiTheme.GOLD
	if id in ColonyAbility.ALL and not big:
		tint = ColonyAbility.COLORS[id]
	elif not big:
		tint = OrganelleParts.COLORS[id]
	var ring := UiTheme.panel(UiTheme.BUTTON, 0)
	ring.set_corner_radius_all(80)
	ring.border_color = tint
	ring.set_border_width_all(4)
	var lit: StyleBoxFlat = ring.duplicate()
	lit.bg_color = UiTheme.BUTTON_DOWN
	button.add_theme_stylebox_override("normal", ring)
	button.add_theme_stylebox_override("hover", ring)
	button.add_theme_stylebox_override("pressed", lit)
	button.add_theme_stylebox_override("hover_pressed", lit)
	button.add_theme_color_override("font_color", tint)
	button.visible = false
	# Touches are read in _input; the button itself only draws.
	button.toggle_mode = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button
