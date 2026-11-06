class_name EnergyBar
extends Control
## The starvation timer: a bar across the top of the screen that empties as
## energy burns. Food stored past full (fat store upgrade) shows as a gold
## bar laid over it, filling its own capacity from the left.

const HEIGHT := 28.0
const TRACK := Color(0.01, 0.05, 0.09, 0.75)
const FULL := Color(0.4, 0.9, 0.5)
const LOW := Color(0.95, 0.3, 0.25)
const STORED := Color(1.0, 0.8, 0.25, 0.9)

var _energy := 0.0
var _full := 12.0
var _store := 0.0
var _label: Label
## One rounded box, recoloured for the track and each fill as it draws.
var _box := StyleBoxFlat.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 16.0
	offset_right = -16.0
	offset_top = 8.0
	offset_bottom = 8.0 + HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.anti_aliasing = true
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
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
	var r := HEIGHT * 0.5
	_pill(Rect2(0, 0, w, HEIGHT), TRACK, Color(UiTheme.EDGE, 0.35))
	var inner := Rect2(3, 3, w - 6, HEIGHT - 6)
	var part := clampf(_energy / _full, 0.0, 1.0)
	_fill(inner, part, LOW.lerp(FULL, part))
	if _store > 0.0:
		_fill(inner, clampf((_energy - _full) / _store, 0.0, 1.0), STORED)
	# A faint sheen along the top edge reads as a glass tube.
	draw_line(Vector2(r, 4), Vector2(w - r, 4), Color(1, 1, 1, 0.12), 2.0)


func _fill(inner: Rect2, part: float, tint: Color) -> void:
	if part <= 0.0:
		return
	var width := maxf(inner.size.x * part, inner.size.y)
	_pill(Rect2(inner.position, Vector2(width, inner.size.y)), tint, Color(0, 0, 0, 0))


func _pill(rect: Rect2, fill: Color, edge: Color) -> void:
	_box.bg_color = fill
	_box.set_corner_radius_all(int(rect.size.y * 0.5))
	_box.border_color = edge
	_box.set_border_width_all(2 if edge.a > 0.0 else 0)
	draw_style_box(_box, rect)
