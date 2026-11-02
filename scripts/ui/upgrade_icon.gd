class_name UpgradeIcon
extends Control
## A small drawing of a cell on an upgrade pick card, showing the part the
## pick grows in the same colour it has in the game (OrganelleParts). Cards
## for organelles get a gold ring and an "ORGANELLE" tag. Front faces up.

const CELL := Color(0.45, 0.8, 1.0)
const GOLD := Color(1.0, 0.82, 0.35)
const R := 26.0

## Feature id, or trait name for a plain trait pick.
var kind := ""
var direction := 1.0
var organelle := false


static func make(choice: MutationChoice) -> UpgradeIcon:
	var icon := UpgradeIcon.new()
	icon.organelle = choice.feature_id != ""
	icon.kind = choice.feature_id if icon.organelle else choice.trait_name
	icon.direction = choice.direction
	icon.custom_minimum_size = Vector2(0, 96)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _draw() -> void:
	var c := Vector2(size.x / 2.0, 52.0)
	if organelle:
		draw_arc(c, R + 20.0, 0.0, TAU, 40, Color(GOLD, 0.6), 2.0, true)
		draw_string(get_theme_default_font(), Vector2(0, 12), "ORGANELLE",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, GOLD)
	var r := R * (1.3 if kind == "size" else 1.0)
	draw_circle(c, r, Color(CELL, 0.25))
	draw_arc(c, r, 0.0, TAU, 36, CELL, 2.0, true)
	IconParts.draw_part(self, kind, direction, c, r)
