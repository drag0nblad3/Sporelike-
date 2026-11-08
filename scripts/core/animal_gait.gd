class_name AnimalGait
extends RefCounted
## How a stage 3 animal gets around, read from its body rather than picked:
## no limbs means it slithers, tentacles creep, a single pair of long legs
## hops, many legs scuttle, and bipeds and anything else walk.

const SLITHER := "slither"
const CREEP := "creep"
const HOP := "hop"
const SCUTTLE := "scuttle"
const WALK := "walk"


static func of(body: AnimalBody) -> String:
	var pairs := body.pairs()
	if pairs == 0:
		return SLITHER
	if body.posture != "crawl":
		return WALK
	if body.limb == "tentacle":
		return CREEP
	if pairs == 1 and body.longest_leg() >= body.radii[0] * 2.4:
		return HOP
	if pairs >= 4:
		return SCUTTLE
	return WALK


## World units per second at full stick: mighty legs push a little harder.
static func speed(body: AnimalBody) -> float:
	return _base_speed(body) * (0.85 + 0.15 * body.leg_build)


static func _base_speed(body: AnimalBody) -> float:
	var legs := body.longest_leg()
	match of(body):
		SLITHER:
			return 3.0
		CREEP:
			return 2.2 + legs * 0.4
		HOP:
			return 3.2 + legs * 1.1
		SCUTTLE:
			return 4.2 + legs * 0.5
	return 2.5 + minf(body.pairs(), 3) * 0.5 + legs * 0.8


## Seconds a foot spends in the air on each step.
static func step_time(body: AnimalBody) -> float:
	match of(body):
		SCUTTLE:
			return 0.11
		HOP:
			return 0.24
		CREEP:
			return 0.32
	return 0.18


static func verb(body: AnimalBody) -> String:
	var limbs := body.limb_count()
	if body.posture != "crawl" and body.pairs() > 0:
		return ("walks upright on %d legs" if body.posture == "upright"
			else "strides on %d legs") % limbs
	match of(body):
		SLITHER:
			return "slithers"
		CREEP:
			return "creeps on %d tentacles" % limbs
		HOP:
			return "hops on %d legs" % limbs
		SCUTTLE:
			return "scuttles on %d legs" % limbs
	return "walks on %d legs" % limbs
