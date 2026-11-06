class_name TitleBackdrop
extends Control
## The title screen's backdrop: deep water lit from above, with a few faint
## cells drifting slowly upward so the first screen feels alive.

const TOP := Color(0.05, 0.2, 0.26)
const BOTTOM := Color(0.01, 0.04, 0.08)
const CELLS := 14

var _cells: Array[Vector4] = []
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in CELLS:
		# x share, start y share, radius, speed
		_cells.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(10.0, 46.0),
			rng.randf_range(6.0, 18.0)))


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var bands := 48
	for i in bands:
		var y0 := h * i / bands
		draw_rect(Rect2(0, y0, w, h / bands + 1.0), TOP.lerp(BOTTOM, float(i) / (bands - 1)))
	# Light from the surface: a soft glow behind the title.
	for i in 30:
		draw_circle(Vector2(w * 0.5, h * 0.22), 450.0 - i * 14.0, Color(UiTheme.ACCENT, 0.005))
	for c: Vector4 in _cells:
		var y := fposmod(c.y * (h + 120.0) - _time * c.w, h + 120.0) - 60.0
		var x := c.x * w + sin(_time * 0.3 + c.x * 9.0) * 12.0
		var at := Vector2(x, y)
		draw_circle(at, c.z, Color(UiTheme.ACCENT, 0.05))
		draw_arc(at, c.z, 0.0, TAU, 32, Color(UiTheme.ACCENT, 0.16), 2.0, true)
		draw_circle(at + Vector2(c.z * 0.2, -c.z * 0.15), c.z * 0.3, Color(UiTheme.ACCENT, 0.1))
