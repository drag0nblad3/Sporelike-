class_name AbilityBar
extends Control
## The round ability buttons in the bottom-right corner: a big Jet button
## every cell has, and a smaller one around it for each ability organelle
## the body has grown. Buttons dim while recharging.

signal pressed(id: String)

## Button rectangle per ability, as offsets from the bottom-right corner:
## [left, top, right, bottom].
const SLOTS := {
	"jet": [-200, -200, -40, -40],
	"trichocysts": [-350, -160, -230, -40],
	"toxicysts": [-160, -350, -40, -230],
	"flash": [-330, -330, -220, -220],
}

var _buttons := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in Ability.ALL:
		_buttons[id] = _make(id)


## Shows the buttons this body can use, dimmed while recharging.
func show_for(g: Genome, timers: AbilityTimers) -> void:
	for id in Ability.ALL:
		var button: Button = _buttons[id]
		button.visible = Ability.has(g, id)
		if button.visible:
			button.modulate.a = 1.0 if timers.ready(id) else 0.35 + 0.3 * (1.0 - timers.fraction(id))


func hide_all() -> void:
	for id in Ability.ALL:
		var button: Button = _buttons[id]
		button.visible = false


func _make(id: String) -> Button:
	var rect: Array = SLOTS[id]
	var big := id == "jet"
	var button := Button.new()
	button.theme = UiTheme.shared()
	button.text = Ability.BUTTON[id]
	button.add_theme_font_size_override("font_size", 34 if big else 24)
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = rect[0]
	button.offset_top = rect[1]
	button.offset_right = rect[2]
	button.offset_bottom = rect[3]
	var tint: Color = UiTheme.GOLD
	if not big:
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
	button.pressed.connect(func() -> void: pressed.emit(id))
	add_child(button)
	return button
