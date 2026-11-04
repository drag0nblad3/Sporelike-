class_name AbilityIcons
extends RefCounted
## Pick card drawings for the ability organelles, around a cell at `c`
## with radius `r` (front is up).


static func draw(ci: CanvasItem, kind: String, col: Color, c: Vector2, r: float) -> void:
	match kind:
		"trichocysts":
			for i in 10:
				var d := Vector2.from_angle(TAU * i / 10.0)
				ci.draw_line(c + d * (r - 2.0), c + d * (r + 9.0), col, 3.0, true)
		"toxicysts":
			for s in [-1.0, 0.0, 1.0]:
				var base := c + Vector2(7.0 * s, -r + 2.0)
				var tip := base + Vector2(6.0 * s, -18.0)
				ci.draw_line(base, tip, col, 3.0, true)
				ci.draw_circle(tip, 3.0, col)
		"flash":
			ci.draw_arc(c, r + 10.0, 0.0, TAU, 32, Color(col, 0.5), 4.0, true)
			for p in [Vector2(-8, -5), Vector2(7, -8), Vector2(0, 7), Vector2(10, 5), Vector2(-9, 8)]:
				ci.draw_circle(c + p, 3.0, col)
