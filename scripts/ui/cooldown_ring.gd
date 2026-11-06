class_name CooldownRing
extends Control
## Drawn over a round ability button: while the ability recharges, a dark
## wedge covers the part still to refill and a bright arc runs round the rim,
## like a clock hand sweeping back to ready.

var tint := UiTheme.GOLD
## Share of the recharge still to go: 1 just used, 0 ready.
var left := 0.0:
	set(value):
		if not is_equal_approx(value, left):
			left = value
			queue_redraw()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if left <= 0.0:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 2.0
	var start := -PI * 0.5
	var end := start + TAU * left
	var wedge := PackedVector2Array([center])
	var steps := maxi(int(48 * left), 2)
	for i in steps + 1:
		var a := lerpf(start, end, float(i) / steps)
		wedge.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(wedge, Color(0, 0.02, 0.05, 0.55))
	draw_arc(center, radius - 3.0, end, start + TAU, 64, Color(tint, 0.9), 6.0, true)
