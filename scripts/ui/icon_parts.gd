class_name IconParts
extends RefCounted
## The 2D shapes UpgradeIcon draws for each trait and organelle, around a
## cell at `c` with radius `r`. Front is up (negative y).


static func draw_part(ci: CanvasItem, kind: String, direction: float, c: Vector2, r: float) -> void:
	var col: Color = OrganelleParts.COLORS.get(kind, Color.WHITE)
	match kind:
		"size":
			for a in [0.0, PI / 2.0, PI, PI * 1.5]:
				var d := Vector2.from_angle(a)
				ci.draw_line(c + d * (r + 4.0), c + d * (r + 14.0), Color.WHITE, 2.0)
		"speed", "tail_bud":
			_tail(ci, c + Vector2(0, r), Color.WHITE if kind == "speed" else col)
			if kind == "tail_bud":
				_tail(ci, c + Vector2(-12, r - 3), col)
				_tail(ci, c + Vector2(12, r - 3), col)
		"agility":
			_rays(ci, c, r, 18, 7.0, Color.WHITE, 1.5)
		"grabbing_cilia":
			for s in [-1.0, 1.0]:
				var base := c + Vector2.from_angle(-PI / 2.0 + 0.5 * s) * r
				var tip := base + Vector2(10.0 * s, -18.0)
				ci.draw_line(base, tip, col, 3.0, true)
				ci.draw_circle(tip, 4.0, col)
		"sense":
			_eye(ci, c + Vector2(0, -r * 0.55), 7.0)
		"eye_cluster":
			_eye(ci, c + Vector2(0, -r * 0.55), 6.0)
			for p in [Vector2(-11, -10), Vector2(11, -10), Vector2(-16, 2), Vector2(16, 2)]:
				_eye(ci, c + p, 4.0)
		"armor":
			_rays(ci, c, r, 10, 10.0, Color(0.85, 0.9, 1.0), 4.0)
		"toxin":
			for p in [Vector2(-9, -6), Vector2(8, -9), Vector2(0, 8), Vector2(12, 7), Vector2(-12, 9)]:
				ci.draw_circle(c + p, 4.5, col)
		"diet":
			var meat := direction > 0.0
			ci.draw_circle(c, 10.0, Color(0.9, 0.25, 0.25) if meat else Color(0.3, 0.85, 0.35))
		"jaw":
			for s in [-1.0, 1.0]:
				var base := c + Vector2(8.0 * s, -r + 2.0)
				ci.draw_line(base, base + Vector2(2.0 * s, -14.0), Color(0.95, 0.9, 0.75), 4.0)
				ci.draw_line(base + Vector2(2.0 * s, -14.0), base + Vector2(-5.0 * s, -18.0),
					Color(0.95, 0.9, 0.75), 3.0)
		"efficiency":
			for i in 3:
				var p := c + Vector2(-12.0 + 12.0 * i, 4.0 * (i % 2))
				ci.draw_line(p - Vector2(0, 7), p + Vector2(0, 7), col, 7.0)
		"fat_store":
			for p in [Vector2(-8, -4), Vector2(6, 2), Vector2(-2, 10)]:
				ci.draw_circle(c + p, 6.0, col)
		"gut_lining":
			ci.draw_arc(c, 11.0, 0.0, TAU, 24, col, 3.0, true)
			ci.draw_arc(c, 17.0, 0.0, TAU, 24, Color(col, 0.6), 2.0, true)
		"jet":
			ci.draw_arc(c + Vector2(0, r), 7.0, 0.0, TAU, 16, col, 4.0, true)
			for s in [-1.0, 0.0, 1.0]:
				var p := c + Vector2(0, r + 10.0)
				ci.draw_line(p, p + Vector2(9.0 * s, 14.0), Color(col, 0.7), 2.0)
		"sticky_coat":
			ci.draw_arc(c, r + 8.0, 0.0, TAU, 36, Color(col, 0.7), 5.0, true)
			for a in [0.4, 2.3, 4.1]:
				ci.draw_circle(c + Vector2.from_angle(a) * (r + 10.0), 3.5, col)
		"food_scent":
			for s in [-1.0, 1.0]:
				var base := c + Vector2(6.0 * s, -r + 2.0)
				var tip := base + Vector2(12.0 * s, -16.0)
				ci.draw_line(base, tip, col.darkened(0.2), 2.0, true)
				ci.draw_circle(tip, 3.5, col)
			ci.draw_arc(c + Vector2(0, -r - 20.0), 6.0, PI * 1.15, PI * 1.85, 8, col, 2.0)


static func _tail(ci: CanvasItem, from: Vector2, col: Color) -> void:
	var points := PackedVector2Array()
	for i in 8:
		points.append(from + Vector2(sin(i * 1.1) * 4.0, i * 3.0))
	ci.draw_polyline(points, col, 2.5, true)


static func _rays(ci: CanvasItem, c: Vector2, r: float, count: int, length: float,
		col: Color, width: float) -> void:
	for i in count:
		var d := Vector2.from_angle(TAU * i / count)
		ci.draw_line(c + d * r, c + d * (r + length), col, width)


static func _eye(ci: CanvasItem, at: Vector2, size: float) -> void:
	ci.draw_circle(at, size, Color(0.05, 0.05, 0.12))
	ci.draw_circle(at + Vector2(size * 0.3, -size * 0.3), size * 0.3, Color.WHITE)
