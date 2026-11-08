class_name AnimalRandom
extends RefCounted
## Rolls a varied random AnimalBody for the stage 3 lab (and later for
## rival species): segment count and shapes, posture, limbs and feet, head
## and tail extras, parts on the back and a colour pattern.

const TOPS := ["", "", "", "spikes", "sail", "plates"]
const FEET := ["pad", "claw", "spike", "sucker"]
const TAILS := ["", "", "fork", "club", "spike"]
const PATTERNS := ["plain", "stripes", "spots", "bands"]
const EYE_SETS := ["front", "wide", "top"]
const ARM_TIPS := ["hand", "pincer", "blade"]
const MOUTHS := ["none", "smile", "smile", "beak", "mandibles", "tusks", "trunk", "sucker"]
const HEADS := ["front", "front", "front", "raised", "low", "middle"]
const SYMMETRY := ["two-sided", "two-sided", "two-sided", "radial", "lopsided"]
const KNEES := ["up", "up", "high", "back"]


static func make(rng: RandomNumberGenerator) -> AnimalBody:
	var body := AnimalBody.new()
	var count := rng.randi_range(3, 8)
	var thick := rng.randf_range(0.45, 0.8)
	var taper := rng.randf_range(-0.2, 0.5)
	var shapes: Array = AnimalBody.SHAPES.keys()
	var main: String = shapes[rng.randi() % shapes.size()]
	var legless := rng.randf() < 0.15
	var hopper := not legless and rng.randf() < 0.15
	var leg := rng.randf_range(0.8, 2.0) * thick * 2.0
	var top: String = TOPS[rng.randi() % TOPS.size()]
	for i in count:
		var t := float(i) / float(count - 1)
		body.radii.append(thick * (1.0 - taper * t) * rng.randf_range(0.9, 1.1))
		var shape: String = main if rng.randf() < 0.7 else shapes[rng.randi() % shapes.size()]
		body.shapes.append(shape)
		var pairs := 0
		if not legless and not hopper and i > 0 and i < count - 1 and rng.randf() < 0.7:
			pairs = 2 if rng.randf() < 0.25 else 1
		body.leg_pairs.append(pairs)
		body.leg_lengths.append(leg * rng.randf_range(0.8, 1.2))
		body.tops.append(top if i > 0 and rng.randf() < 0.8 else "")
	if hopper:
		var back := count - 2 if count > 3 else 1
		body.leg_pairs[back] = 1
		body.leg_lengths[back] = maxf(leg, thick * 2.6) * 1.3
	elif not legless and body.pairs() == 0:
		body.leg_pairs[1] = 1
	body.limb = "tentacle" if not hopper and rng.randf() < 0.2 else "leg"
	body.joints = 5 if body.limb == "tentacle" else rng.randi_range(2, 4)
	body.foot = FEET[rng.randi() % FEET.size()]
	body.arch = rng.randf_range(0.0, 0.6) if rng.randf() < 0.5 else 0.0
	body.sprawl = rng.randf_range(0.25, 1.0)
	body.claw_side = [-1, 1][rng.randi() % 2] if rng.randf() < 0.2 else 0
	body.tail = TAILS[rng.randi() % TAILS.size()]
	body.horns = [0, 0, 1, 2][rng.randi() % 4]
	body.feelers = rng.randf() < 0.4
	body.eye_stalks = rng.randf() < 0.25
	body.eyes = [1, 2, 2, 2, 3, 4, 6, 8][rng.randi() % 8]
	body.eye_set = EYE_SETS[rng.randi() % EYE_SETS.size()]
	body.neck = [0.0, 0.0, 0.0, 0.8, 1.6][rng.randi() % 5]
	body.arm_pairs = 1 if not hopper and rng.randf() < 0.25 else 0
	body.arm_tip = ARM_TIPS[rng.randi() % ARM_TIPS.size()]
	body.smooth = rng.randf() < 0.4
	body.mouth = MOUTHS[rng.randi() % MOUTHS.size()]
	body.head_at = HEADS[rng.randi() % HEADS.size()]
	body.symmetry = SYMMETRY[rng.randi() % SYMMETRY.size()]
	body.knee = "up" if body.limb == "tentacle" else KNEES[rng.randi() % KNEES.size()]
	body.leg_build = [1.0, 1.0, 1.6, 2.4][rng.randi() % 4]
	body.pattern = PATTERNS[rng.randi() % PATTERNS.size()]
	body.hue = rng.randf()
	body.hue2 = fposmod(body.hue + rng.randf_range(0.25, 0.6), 1.0)
	return body
