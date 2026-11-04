class_name GeneIcon
extends BaseButton
## One round node in the gene trees: a drawing of the part or trait the
## gene gives (IconParts, FormIcon), a ring coloured by its state, and a
## small badge (cost or slots). The screen showing it sets the look fields
## and calls queue_redraw(); this class only draws and reports taps.

## Icon drawings are made for a cell of radius 30 in a box this wide.
const NATIVE := 115.0

var gene := ""
var ring := UiTheme.DIM
## Owned (gene trees) or taken (creator): lights the line up to the next tier.
var lit := false
var dim := false
var check := false
var badge := ""
var badge_color := UiTheme.GOLD
var selected := false


static func make(id: String) -> GeneIcon:
	var icon := GeneIcon.new()
	icon.gene = id
	icon.focus_mode = Control.FOCUS_NONE
	return icon


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	if selected:
		draw_circle(c, r, Color(UiTheme.GOLD, 0.25))
		draw_arc(c, r - 2.0, 0.0, TAU, 40, UiTheme.GOLD, 4.0, true)
	var inner := r * 0.86
	draw_circle(c, inner, Color(0.02, 0.07, 0.11, 0.95))
	draw_arc(c, inner, 0.0, TAU, 40, ring, 4.0 if lit else 2.5, true)
	if GeneCatalog.tier(gene) >= 3:
		draw_arc(c, inner - 5.0, 0.0, TAU, 40, Color(UiTheme.GOLD, 0.45), 1.5, true)
	var k := inner * 2.0 / NATIVE
	draw_set_transform(c, 0.0, Vector2(k, k))
	_draw_part()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if dim:
		draw_circle(c, inner - 1.0, Color(0.0, 0.03, 0.06, 0.6))
	_draw_badge(c + Vector2(r, r) * 0.62, r * 0.3)


func _draw_part() -> void:
	var row: Array = GeneCatalog.GENES[gene]
	var what := str(row[2])
	match str(row[1]):
		"efficiency":
			_cell()
			IconParts.draw_part(self, "efficiency", 1.0, Vector2.ZERO, 30.0)
		"trait":
			_cell(1.15 if what == "size" else 1.0)
			IconParts.draw_part(self, what, signf(float(row[3])), Vector2.ZERO, 30.0)
		_:
			if GeneCatalog.is_form(gene):
				FormIcon.draw_form(self, what, Vector2.ZERO, 26.0)
			else:
				_cell()
				IconParts.draw_part(self, what, 1.0, Vector2.ZERO, 30.0)


func _cell(scale_by: float = 1.0) -> void:
	draw_circle(Vector2.ZERO, 30.0 * scale_by, Color(UpgradeIcon.CELL, 0.25))
	draw_arc(Vector2.ZERO, 30.0 * scale_by, 0.0, TAU, 36, UpgradeIcon.CELL, 2.0, true)


func _draw_badge(at: Vector2, br: float) -> void:
	if check:
		draw_circle(at, br, UiTheme.GAIN)
		var tick := PackedVector2Array([at + Vector2(-0.5, 0.0) * br,
			at + Vector2(-0.1, 0.4) * br, at + Vector2(0.5, -0.4) * br])
		draw_polyline(tick, Color(0.02, 0.1, 0.05), maxf(2.0, br * 0.25), true)
	elif badge != "":
		draw_circle(at, br, Color(0.02, 0.07, 0.11))
		draw_arc(at, br, 0.0, TAU, 20, badge_color, 2.0, true)
		var font_size := int(br * 1.3)
		draw_string(get_theme_default_font(), at + Vector2(-br, font_size * 0.36), badge,
			HORIZONTAL_ALIGNMENT_CENTER, br * 2.0, font_size, badge_color)
