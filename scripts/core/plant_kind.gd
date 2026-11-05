class_name PlantKind
extends RefCounted
## The rooted food of the multicellular stage, one kind per kind of Sea, so
## each region looks and feeds differently: sea lettuce on the shelf,
## stromatolite mounds in the lagoon, sulfur bacteria mats at the vents,
## kelp on the upwelling coast and sparse red algae in the deep.

var id := ""
var title := ""
var stalk := Color(0.25, 0.6, 0.3)
var bud := Color(1.0, 0.85, 0.35)
var bud_energy := 3.0
## Seconds an eaten bud takes to grow back.
var regrow := 10.0
## Stalk length range, side branches range, and cell radius.
var stalk_cells := Vector2i(5, 7)
var branches := Vector2i(2, 3)
var cell_size := 0.42
## How hard the water sways it.
var sway := 0.6
## Multiplies how many grow around the colony.
var density := 1.0


static func for_sea(sea_id: String) -> PlantKind:
	var k := PlantKind.new()
	k.id = sea_id
	match sea_id:
		"lagoon":
			_fill(k, "Stromatolite mound", Color(0.55, 0.5, 0.3), Color(0.3, 0.85, 0.75), 2.0, 6.0)
			k.stalk_cells = Vector2i(2, 3)
			k.branches = Vector2i(4, 6)
			k.cell_size = 0.55
			k.sway = 0.1
			k.density = 1.5
		"vents":
			_fill(k, "Sulfur bacteria mat", Color(0.85, 0.85, 0.75), Color(1.0, 0.95, 0.4), 4.0, 14.0)
			k.stalk_cells = Vector2i(1, 2)
			k.branches = Vector2i(5, 7)
			k.cell_size = 0.5
			k.sway = 0.2
			k.density = 0.7
		"upwelling":
			_fill(k, "Kelp", Color(0.45, 0.35, 0.15), Color(0.75, 0.6, 0.2), 5.0, 16.0)
			k.stalk_cells = Vector2i(8, 11)
			k.branches = Vector2i(3, 4)
			k.sway = 1.0
		"deep":
			_fill(k, "Red algae", Color(0.55, 0.15, 0.2), Color(1.0, 0.45, 0.5), 3.0, 18.0)
			k.stalk_cells = Vector2i(3, 5)
			k.branches = Vector2i(1, 2)
			k.density = 0.4
		_:
			k.id = "shelf"
			_fill(k, "Sea lettuce", Color(0.25, 0.6, 0.3), Color(1.0, 0.85, 0.35), 3.0, 10.0)
	return k


static func _fill(k: PlantKind, label: String, stem: Color, tip: Color, energy: float,
		wait: float) -> void:
	k.title = label
	k.stalk = stem
	k.bud = tip
	k.bud_energy = energy
	k.regrow = wait
