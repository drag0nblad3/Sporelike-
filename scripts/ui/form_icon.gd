class_name FormIcon
extends RefCounted
## The 2D drawing UpgradeIcon shows for each body form (see BodyForm and
## FormLook): the cell's outline in that shape. Front is up.

const CELL := Color(0.45, 0.8, 1.0)
const SHELL := Color(0.86, 0.76, 0.56)


static func draw_form(ci: CanvasItem, id: String, c: Vector2, r: float) -> void:
	match id:
		"form_rod":
			_oval(ci, c, Vector2(0.6, 1.4) * r)
		"form_spiral":
			_oval(ci, c, Vector2(0.5, 1.4) * r)
			for i in 7:
				var y := lerpf(-1.2, 1.2, i / 6.0) * r
				var x := 0.45 * r * (1.0 if i % 2 == 0 else -1.0)
				ci.draw_line(c + Vector2(-x, y - 6.0), c + Vector2(x, y + 6.0), CELL.darkened(0.3), 3.0)
		"form_amoeboid":
			_oval(ci, c, Vector2(0.85, 0.85) * r)
			for a in [0.3, 1.9, 3.4, 4.9]:
				var p := c + Vector2.from_angle(a) * r * 0.85
				ci.draw_circle(p, r * 0.38, Color(CELL, 0.25))
				ci.draw_arc(p, r * 0.38, a - 1.4, a + 1.4, 16, CELL, 2.0, true)
		"form_shelled":
			_oval(ci, c, Vector2(r, r))
			for i in 4:
				var a := PI * 0.6 + i * 0.95
				ci.draw_circle(c + Vector2.from_angle(a) * r * 0.55, 7.0 + 2.5 * i, Color(SHELL, 0.85))
		"form_disc":
			_oval(ci, c, Vector2(1.3, 1.05) * r)
			ci.draw_arc(c, r * 0.85, 0.0, TAU, 40, CELL.lightened(0.3), 3.0, true)
			for i in 12:
				ci.draw_circle(c + Vector2.from_angle(TAU * i / 12.0) * r * 0.7, 2.0, CELL)


static func _oval(ci: CanvasItem, c: Vector2, radii: Vector2) -> void:
	ci.draw_set_transform(c, 0.0, radii / radii.x)
	ci.draw_circle(Vector2.ZERO, radii.x, Color(CELL, 0.25))
	ci.draw_arc(Vector2.ZERO, radii.x, 0.0, TAU, 40, CELL, 2.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
