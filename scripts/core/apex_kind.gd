class_name ApexKind
extends RefCounted
## The one apex colony each sea holds: a huge rival with a name, a colour
## and the cells it leans on. Killing it is a stage 2 run milestone worth
## extra progress (and so gene points) and a feast of remains.

## Shows up once the player's colony has this many cells.
const APPEAR_AT := 16
## Cells it has beyond the player's, capped at BodyPlan.MAX_CELLS.
const EXTRA_CELLS := 14
## Dies when this share of its full body has been bitten off (other
## colonies need ColonyWounds.FATAL_SHARE).
const FATAL_SHARE := 0.3
## Progress for the kill: 100 points is 5 gene points at the run's end.
const PROGRESS_BONUS := 100.0
## Its remains hold this many times the energy of an ordinary colony's.
const FEAST := 3

var title := ""
var tint := Color.WHITE
## Cells grown first, so the apex has its sea's character.
var leans: Array[String] = []
var style := FeedingStyle.HUNTER


static func for_sea(sea_id: String) -> ApexKind:
	var k := ApexKind.new()
	match sea_id:
		"lagoon":
			_fill(k, "Lagoon glutton", Color(0.55, 0.85, 0.3, 0.65), ["gut", "storage", "mouth"],
				FeedingStyle.GRAZER)
		"vents":
			_fill(k, "Vent maw", Color(0.85, 0.35, 0.2, 0.65), ["plate", "plate", "mouth"],
				FeedingStyle.HUNTER)
		"upwelling":
			_fill(k, "Bloom ravager", Color(0.35, 0.75, 0.75, 0.65), ["flagellum", "mouth", "gland"],
				FeedingStyle.HUNTER)
		"deep":
			_fill(k, "Twilight leviathan", Color(0.45, 0.35, 0.85, 0.65), ["eye", "gland", "mouth"],
				FeedingStyle.HUNTER)
		_:
			_fill(k, "Reef tyrant", Color(0.8, 0.3, 0.45, 0.65), ["plate", "mouth", "flagellum"],
				FeedingStyle.HUNTER)
	return k


static func _fill(k: ApexKind, name: String, color: Color, roles: Array, eats: String) -> void:
	k.title = name
	k.tint = color
	k.leans.assign(roles)
	k.style = eats


## A body plan of about `cells` cells, its sea's leaning cells first.
func make_plan(cells: int, rng: RandomNumberGenerator) -> BodyPlan:
	var plan := BodyPlan.starter(Symmetry.ALL[rng.randi() % Symmetry.ALL.size()])
	plan.style = style
	var roles: Array = LabHud.GROWABLE
	var tries := 0
	while plan.parts.size() < cells and tries < 60:
		var role: String = leans[tries % leans.size()] if tries < leans.size() * 3 \
			else str(roles[rng.randi() % roles.size()])
		tries += 1
		plan.grow(role)
	return plan
