class_name Animal
extends Node3D
## A stage 3 land animal (AnimalBody): its head goes where move_input
## points, turning at a steady rate, every other segment trails the one in
## front at a fixed spacing over the ground (LandHeight), and each leg
## steps on its own (LegStepper). Drawn by AnimalLook.

## Radians per second it can turn.
const TURN := 2.6
## How fast it gets up to speed or stops, in units per second per second.
const ACCEL := 8.0

var body: AnimalBody
## Where to go, in world x and z, length 0 to 1.
var move_input := Vector2.ZERO
var heading := 0.0
var spine := PackedVector3Array()
var legs: Array[LegStepper] = []
## Which segment each leg hangs from, and which side (-1 or 1).
var leg_segment := PackedInt32Array()
var leg_side := PackedFloat32Array()
var speed_now := 0.0
var time := 0.0
var _look := AnimalLook.new()


func _ready() -> void:
	add_child(_look)
	if body:
		_look.build(body)


func build(new_body: AnimalBody, at: Vector3) -> void:
	body = new_body
	spine.clear()
	legs.clear()
	leg_segment.clear()
	leg_side.clear()
	var p := at
	for i in body.segments():
		spine.append(p)
		if i < body.segments() - 1:
			p -= forward() * spacing(i)
	_rest_on_ground()
	for i in body.segments():
		if body.legs[i] == 0:
			continue
		var pair: Array[LegStepper] = []
		for side: float in [-1.0, 1.0]:
			var leg := LegStepper.new(body.leg_length)
			leg.plant(_home(i, side))
			legs.append(leg)
			leg_segment.append(i)
			leg_side.append(side)
			pair.append(leg)
		pair[0].partner = pair[1]
		pair[1].partner = pair[0]
	if is_inside_tree():
		_look.build(body)


func forward() -> Vector3:
	return Vector3(sin(heading), 0.0, cos(heading))


## Gap between segment i and the one behind it.
func spacing(i: int) -> float:
	return (body.radii[i] + body.radii[mini(i + 1, body.segments() - 1)]) * 0.85


## The direction segment i faces (toward the one in front of it).
func segment_forward(i: int) -> Vector3:
	if i == 0:
		return forward()
	var d := spine[i - 1] - spine[i]
	d.y = 0.0
	return d.normalized() if d.length_squared() > 0.0001 else forward()


func head() -> Vector3:
	return spine[0]


func _physics_process(delta: float) -> void:
	if body == null:
		return
	time += delta
	var dir := Vector3(move_input.x, 0.0, move_input.y)
	var amount := minf(dir.length(), 1.0)
	if amount > 0.05:
		heading = rotate_toward(heading, atan2(dir.x, dir.z), TURN * delta)
	speed_now = move_toward(speed_now, body.speed() * amount, ACCEL * delta)
	spine[0] += forward() * speed_now * delta
	for i in range(1, spine.size()):
		var back := spine[i] - spine[i - 1]
		back.y = 0.0
		if back.length_squared() < 0.0001:
			back = -forward()
		spine[i] = spine[i - 1] + back.normalized() * spacing(i - 1)
	_rest_on_ground()
	for k in legs.size():
		var i := leg_segment[k]
		var side := leg_side[k]
		var hip := spine[i] + _right(i) * side * body.radii[i] * 0.8
		var lead := segment_forward(i) * speed_now * 0.22
		legs[k].update(hip, _home(i, side), lead, body.leg_length * 0.45, delta)


func _process(_delta: float) -> void:
	if body:
		_look.update(self)


func _rest_on_ground() -> void:
	for i in spine.size():
		var p := spine[i]
		p.y = LandHeight.at(p.x, p.z) + body.ride_height() + body.radii[i] * 0.7
		spine[i] = p


func _right(i: int) -> Vector3:
	return segment_forward(i).cross(Vector3.UP)


## Where a foot rests under segment i on this side, on the ground.
func _home(i: int, side: float) -> Vector3:
	var p := spine[i] + _right(i) * side * (body.radii[i] + body.leg_length * 0.5)
	p.y = LandHeight.at(p.x, p.z)
	return p
