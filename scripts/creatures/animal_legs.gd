class_name AnimalLegs
extends RefCounted
## All the limbs of a stage 3 Animal: one LegStepper per limb, which
## segment it hangs from, the direction round the body it points (angle 0
## is the right side, PI the left), where along the segment it sits and its
## length. A two-sided body mirrors each pair; a radial one spreads each
## segment's limbs all round it; a lopsided one has longer limbs on the
## left. Low sprawl tucks the legs under the body; high sprawl sets them wide.

var limbs: Array[LegStepper] = []
var segment := PackedInt32Array()
var angle := PackedFloat32Array()
## Offset along the segment, as a share of its half length (-1 to 1).
var along := PackedFloat32Array()
var length := PackedFloat32Array()


func build(animal: Animal) -> void:
	var body := animal.body
	limbs.clear()
	segment.clear()
	angle.clear()
	along.clear()
	length.clear()
	var seconds := AnimalGait.step_time(body)
	for i in body.segments():
		var count := int(body.leg_pairs[i])
		if count == 0:
			continue
		if body.symmetry == "radial":
			var ring := count * 2 + 1
			var first := limbs.size()
			for k in ring:
				_add(animal, i, TAU * (k + 0.25) / ring, 0.0, 1.0, seconds)
			for k in ring:
				limbs[first + k].partner = limbs[first + (k + 1) % ring]
		else:
			for p in count:
				var at := 0.0 if count == 1 else (0.5 - p)
				var lop := body.symmetry == "lopsided"
				_add(animal, i, 0.0, at, 0.75 if lop else 1.0, seconds)
				_add(animal, i, PI, at, 1.3 if lop else 1.0, seconds)
				limbs[-1].partner = limbs[-2]
				limbs[-2].partner = limbs[-1]


func update(animal: Animal, delta: float) -> void:
	for k in limbs.size():
		var lead := animal.segment_forward(segment[k]) * animal.speed_now * 0.22
		limbs[k].facing = animal.segment_forward(segment[k])
		limbs[k].update(hip(animal, k), home(animal, k), lead, length[k] * 0.45, delta,
			animal.time)


## The flat direction limb k points out from its segment.
func out_dir(animal: Animal, k: int) -> Vector3:
	var i := segment[k]
	return animal.segment_right(i) * cos(angle[k]) + animal.segment_forward(i) * sin(angle[k])


func hip(animal: Animal, k: int) -> Vector3:
	var i := segment[k]
	var body := animal.body
	# Upright legs hang from under the belly, sprawling ones from the sides.
	var width := body.radii[i] * body.shape_scale(i).x * lerpf(0.3, 0.9, body.sprawl)
	var low := body.radii[i] * body.shape_scale(i).y * (1.0 - body.sprawl) * 0.6
	return animal.spine[i] + out_dir(animal, k) * width \
		+ animal.segment_forward(i) * along[k] * body.half_length(i) - Vector3.UP * low


## Where a foot rests on the ground under limb k.
func home(animal: Animal, k: int) -> Vector3:
	var i := segment[k]
	var body := animal.body
	var out := body.radii[i] * body.shape_scale(i).x * lerpf(0.35, 1.0, body.sprawl) \
		+ length[k] * body.sprawl * 0.7
	var p := animal.spine[i] + out_dir(animal, k) * out \
		+ animal.segment_forward(i) * along[k] * body.half_length(i)
	p.y = LandHeight.at(p.x, p.z)
	return p


func _add(animal: Animal, i: int, a: float, at: float, scale: float, seconds: float) -> void:
	var body := animal.body
	var leg := LegStepper.new(body.leg_lengths[i] * scale, body.joints, seconds,
		body.limb == "tentacle", body.knee)
	limbs.append(leg)
	segment.append(i)
	angle.append(a)
	along.append(at)
	length.append(body.leg_lengths[i] * scale)
	leg.plant(home(animal, limbs.size() - 1))
