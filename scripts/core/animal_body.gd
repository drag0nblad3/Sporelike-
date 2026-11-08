class_name AnimalBody
extends RefCounted
## The body plan of a stage 3 land animal, as the feel-test lab uses it: a
## chain of segments from the head back, how thick each is, which carry a
## pair of legs and how long the legs are, and its colours. random() makes
## a varied one; the full slot-and-part editor comes later.

## Radius of each segment, head first.
var radii := PackedFloat32Array()
## 1 where a segment carries a pair of legs.
var legs := PackedByteArray()
var leg_length := 1.0
var hue := 0.3
var striped := false
## Eyes on the head: 2, 4 or 6.
var eyes := 2


static func random(rng: RandomNumberGenerator) -> AnimalBody:
	var body := AnimalBody.new()
	var count := rng.randi_range(3, 8)
	var thick := rng.randf_range(0.45, 0.8)
	var taper := rng.randf_range(0.0, 0.5)
	var legless := rng.randf() < 0.2
	for i in count:
		var t := float(i) / float(count - 1)
		body.radii.append(thick * (1.0 - taper * t) * rng.randf_range(0.9, 1.1))
		var has_legs := not legless and i > 0 and i < count - 1 and rng.randf() < 0.7
		body.legs.append(1 if has_legs else 0)
	if not legless and body.pairs() == 0:
		body.legs[1] = 1
	body.leg_length = rng.randf_range(0.8, 2.0) * thick * 2.0
	body.hue = rng.randf()
	body.striped = rng.randf() < 0.5
	body.eyes = [2, 2, 4, 6][rng.randi() % 4]
	return body


func segments() -> int:
	return radii.size()


func pairs() -> int:
	var n := 0
	for flag in legs:
		n += flag
	return n


## How high the body rides above the ground: on its legs, or on its belly.
func ride_height() -> float:
	return leg_length * 0.55 if pairs() > 0 else 0.0


## World units per second at full stick: legs help, long legs more.
func speed() -> float:
	if pairs() == 0:
		return 3.0
	return 2.5 + minf(pairs(), 4) * 0.5 + leg_length * 0.8


func color() -> Color:
	return Color.from_hsv(hue, 0.55, 0.75)


func describe() -> String:
	var how := "slithers" if pairs() == 0 else "walks on %d legs" % (pairs() * 2)
	return "%d segments, %d eyes, %s" % [segments(), eyes, how]
