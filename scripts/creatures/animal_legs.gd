class_name AnimalLegs
extends RefCounted
## All the limbs of a stage 3 Animal: one LegStepper per limb, which
## segment and side it hangs from, and where along the segment (a segment
## with two pairs has one near its front and one near its back). Low
## sprawl tucks the legs under the body; high sprawl sets them wide.

var limbs: Array[LegStepper] = []
var segment := PackedInt32Array()
var side := PackedFloat32Array()
## Offset along the segment, as a share of its half length (-1 to 1).
var along := PackedFloat32Array()


func build(animal: Animal) -> void:
	var body := animal.body
	limbs.clear()
	segment.clear()
	side.clear()
	along.clear()
	var seconds := AnimalGait.step_time(body)
	for i in body.segments():
		var count := int(body.leg_pairs[i])
		for p in count:
			var at := 0.0 if count == 1 else (0.5 - p)
			var pair: Array[LegStepper] = []
			for s: float in [-1.0, 1.0]:
				var leg := LegStepper.new(body.leg_lengths[i], body.joints, seconds,
					body.limb == "tentacle")
				limbs.append(leg)
				segment.append(i)
				side.append(s)
				along.append(at)
				leg.plant(home(animal, limbs.size() - 1))
				pair.append(leg)
			pair[0].partner = pair[1]
			pair[1].partner = pair[0]


func update(animal: Animal, delta: float) -> void:
	var body := animal.body
	for k in limbs.size():
		var i := segment[k]
		var lead := animal.segment_forward(i) * animal.speed_now * 0.22
		limbs[k].update(hip(animal, k), home(animal, k), lead, body.leg_lengths[i] * 0.45,
			delta, animal.time)


func hip(animal: Animal, k: int) -> Vector3:
	var i := segment[k]
	var body := animal.body
	# Upright legs hang from under the belly, sprawling ones from the sides.
	var width := body.radii[i] * body.shape_scale(i).x * lerpf(0.3, 0.9, body.sprawl)
	var low := body.radii[i] * body.shape_scale(i).y * (1.0 - body.sprawl) * 0.6
	return animal.spine[i] + animal.segment_right(i) * side[k] * width \
		+ animal.segment_forward(i) * along[k] * body.half_length(i) - Vector3.UP * low


## Where a foot rests on the ground under limb k.
func home(animal: Animal, k: int) -> Vector3:
	var i := segment[k]
	var body := animal.body
	var out := body.radii[i] * body.shape_scale(i).x * lerpf(0.35, 1.0, body.sprawl) \
		+ body.leg_lengths[i] * body.sprawl * 0.7
	var p := animal.spine[i] + animal.segment_right(i) * side[k] * out \
		+ animal.segment_forward(i) * along[k] * body.half_length(i)
	p.y = LandHeight.at(p.x, p.z)
	return p
