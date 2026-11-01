class_name EnergyBar
extends Control
## The starvation timer: a bar across the top of the screen that empties as
## energy burns. Food stored past full (fat store upgrade) shows as a gold
## bar laid over it, filling its own capacity from the left.

const HEIGHT := 22.0
const TRACK := Color(1, 1, 1, 0.12)
const FULL := Color(0.4, 0.9, 0.5)
const LOW := Color(0.95, 0.3, 0.25)
const STORED := Color(1.0, 0.8, 0.25, 0.9)

var _energy := 0.0
var _full := 12.0
var _store := 0.0
var _label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 16.0
	offset_right = -16.0
	offset_top = 6.0
	offset_bottom = 6.0 + HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)


## energy: current; full: a full stomach; most: full plus storage capacity.
func show_energy(energy: float, full: float, most: float) -> void:
	_energy = energy
	_full = full
	_store = maxf(most - full, 0.0)
	var stored := maxf(energy - full, 0.0)
	_label.text = "Energy %d/%d" % [ceili(minf(energy, full)), int(full)]
	if _store > 0.0:
		_label.text += "   stored %d/%d" % [ceili(stored), int(_store)]
	queue_redraw()


func _draw() -> void:
	var w := size.x
	draw_rect(Rect2(0, 0, w, HEIGHT), TRACK)
	var part := clampf(_energy / _full, 0.0, 1.0)
	draw_rect(Rect2(0, 0, w * part, HEIGHT), LOW.lerp(FULL, part))
	if _store > 0.0:
		var stored := clampf((_energy - _full) / _store, 0.0, 1.0)
		draw_rect(Rect2(0, 0, w * stored, HEIGHT), STORED)
