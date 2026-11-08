class_name AnimalBuilder
extends RefCounted
## Turns the picks of an AnimalRecipe (the body customizer) into an
## AnimalBody: segment sizes from the build and taper, leg pairs spread
## evenly along the body (a single long pair goes at the back, so it hops),
## and every head, back and tail part as picked.

const THICK := [0.45, 0.6, 0.8]
const TAPER := [0.0, 0.4, -0.3]
const LEG := [1.1, 1.7, 2.5]
const STANCE := [0.1, 0.5, 1.0]
const NECK := [0.0, 0.8, 1.7]
const ARCH := [0.0, 0.3, 0.6]


static func build(recipe: AnimalRecipe) -> AnimalBody:
	var body := AnimalBody.new()
	var count := recipe.index("segments") + 2
	var thick: float = THICK[recipe.index("size")]
	var taper: float = TAPER[recipe.index("taper")]
	var leg: float = LEG[recipe.index("leg_length")] * thick
	var top := recipe.value("back")
	for i in count:
		var t := float(i) / float(count - 1)
		body.radii.append(thick * (1.0 - taper * t))
		body.shapes.append(recipe.value("shape"))
		body.leg_pairs.append(0)
		body.leg_lengths.append(leg)
		body.tops.append("" if top == "none" or i == 0 else top)
	_place_legs(body, recipe.index("legs"), recipe.index("leg_length") == 2)
	body.smooth = recipe.value("skin") == "smooth"
	body.neck = NECK[recipe.index("neck")]
	body.sprawl = STANCE[recipe.index("stance")]
	body.limb = "tentacle" if recipe.value("limb") == "tentacles" else "leg"
	body.joints = 5 if body.limb == "tentacle" else recipe.index("joints") + 2
	body.foot = recipe.value("foot")
	body.arm_pairs = recipe.index("arms")
	body.arm_tip = recipe.value("arm_tip")
	body.claw_side = [0, -1, 1][recipe.index("claw")]
	body.eyes = recipe.index("eyes") + 1
	body.eye_set = recipe.value("eye_set")
	body.eye_stalks = recipe.value("stalks") == "yes"
	body.horns = recipe.index("horns")
	body.feelers = recipe.value("feelers") == "yes"
	body.arch = ARCH[recipe.index("arch")]
	var tail := recipe.value("tail")
	body.tail = "" if tail == "none" else tail
	body.pattern = recipe.value("pattern")
	body.hue = recipe.index("hue") / float(AnimalRecipe.HUES.size())
	body.hue2 = recipe.index("hue2") / float(AnimalRecipe.HUES.size())
	return body


## Spreads `pairs` leg pairs over the body behind the head (a second pair
## per segment only once every segment has one).
static func _place_legs(body: AnimalBody, pairs: int, long: bool) -> void:
	var count := body.segments()
	var first := 1 if count > 2 else 0
	var last := count - 2 if count > 3 else count - 1
	var slots := last - first + 1
	pairs = mini(pairs, slots * 2)
	if pairs == 1 and long:
		body.leg_pairs[last] = 1
		return
	for k in pairs:
		var round_k := k % slots
		var per_round := mini(pairs - (k / slots) * slots, slots)
		var at := first + int((round_k + 0.5) * slots / float(per_round)) if per_round < slots \
			else first + round_k
		body.leg_pairs[mini(at, last)] += 1
