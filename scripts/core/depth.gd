class_name Depth
extends RefCounted
## The three depths a colony can swim at in the multicellular stage. The
## sea floor has rooted plants, rocks, single cells and their hunters. Open
## water has drifting marine snow and is quickest to cross. The sunlit
## surface has floating algae rafts, but comb jellies hunt there and dive
## on anything below them in open water. Things only touch, eat or bite
## things at their own depth.

const FLOOR := 0
const OPEN := 1
const SURFACE := 2
const NAMES := ["Sea floor", "Open water", "Surface"]
## Height above the floor of each depth, in world units.
const STEP := 3.0
## Height units per second a colony rises or sinks.
const SPEED := 3.5


static func height(layer: int) -> float:
	return STEP * clampi(layer, FLOOR, SURFACE)


static func layer_at(y: float) -> int:
	return clampi(roundi(y / STEP), FLOOR, SURFACE)


static func title(layer: int) -> String:
	return NAMES[clampi(layer, FLOOR, SURFACE)]


## Whether two heights are close enough to touch.
static func level(a: float, b: float) -> bool:
	return absf(a - b) < STEP * 0.5


## Multiplies a colony's swimming push at this depth.
static func swim_factor(layer: int) -> float:
	return 1.25 if layer == OPEN else 1.0
