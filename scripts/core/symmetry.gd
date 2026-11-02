class_name Symmetry
extends RefCounted
## The three body symmetries a colony can evolve at the start of the
## multicellular stage, and how each one copies a new cell around the body.
## Cells sit on BodyPlan's hex grid, which is unchanged by left-right and
## front-back mirroring and by a third of a turn, so every copy lands on a
## grid spot too. In plan coordinates x is left-right and y is back-front.

const RADIAL := "radial"
const BILATERAL := "bilateral"
const BIRADIAL := "biradial"
const ALL := [RADIAL, BILATERAL, BIRADIAL]

## id -> [label, what it means for play]
const INFO := {
	RADIAL: ["Radial",
		"A mouth in the middle and the same all the way round. Grows 3 cells at a time, "
		+ "never has a blind side, and tentacles reach for food."],
	BILATERAL: ["Bilateral",
		"A front and a back, a left and a right. Eyes go to the front and movers to the "
		+ "back, so it swims forward fastest."],
	BIRADIAL: ["Biradial",
		"Mirrored left-right and front-back, with a mouth at each end. Swims either way "
		+ "and grows up to 4 cells at a time."],
}


static func label(kind: String) -> String:
	var row: Array = INFO.get(kind, INFO[BILATERAL])
	return row[0]


static func blurb(kind: String) -> String:
	var row: Array = INFO.get(kind, INFO[BILATERAL])
	return row[1]


## Every spot a cell placed at `spot` is copied to, `spot` itself included.
static func copies(kind: String, spot: Vector2) -> Array[Vector2]:
	var raw: Array[Vector2] = [spot]
	match kind:
		RADIAL:
			raw.append(spot.rotated(TAU / 3.0))
			raw.append(spot.rotated(-TAU / 3.0))
		BILATERAL:
			raw.append(Vector2(-spot.x, spot.y))
		BIRADIAL:
			raw.append(Vector2(-spot.x, spot.y))
			raw.append(Vector2(spot.x, -spot.y))
			raw.append(-spot)
	var out: Array[Vector2] = []
	for p in raw:
		var snapped_spot := BodyPlan.snap(p)
		if not snapped_spot in out:
			out.append(snapped_spot)
	return out
