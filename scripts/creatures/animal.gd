class_name Animal
extends Node3D
## A stage 3 land animal (AnimalBody): its head goes where move_input
## points, turning at a steady rate, and every other segment trails the
## one in front over the ground (LandHeight), arched by its posture. Limbs
## step on their own (AnimalLegs); a hopper bounds along in leaps
## (AnimalGait). A neck holds the head up and out in front. Drawn by
## AnimalLook.

## Radians per second it can turn.
const TURN := 2.6
## How fast it gets up to speed or stops, in units per second per second.
const ACCEL := 8.0
const HOP_RATE := 7.0

var body: AnimalBody
## Where to go, in world x and z, length 0 to 1.
var move_input := Vector2.ZERO
var heading := 0.0
var spine := PackedVector3Array()
var legs := AnimalLegs.new()
var speed_now := 0.0
var time := 0.0
## Height of the current leap for a hopper.
var bounce := 0.0
var _look := AnimalLook.new()


func _ready() -> void:
	add_child(_look)
	if body:
		_look.build(body)


func build(new_body: AnimalBody, at: Vector3) -> void:
	body = new_body
	spine.clear()
	var p := at
	for i in body.segments():
		spine.append(p)
		if i < body.segments() - 1:
			p -= forward() * spacing(i)
	_rest_on_ground()
	legs.build(self)
	if is_inside_tree():
		_look.build(body)


func forward() -> Vector3:
	return Vector3(sin(heading), 0.0, cos(heading))


## Gap between segment i and the one behind it.
func spacing(i: int) -> float:
	var gap := (body.half_length(i) + body.half_length(mini(i + 1, body.segments() - 1))) * 0.7
	return gap + (body.neck * body.radii[0] if i == 0 else 0.0)


## The direction segment i faces (toward the one in front of it).
func segment_forward(i: int) -> Vector3:
	if i == 0:
		return forward()
	var d := spine[i - 1] - spine[i]
	d.y = 0.0
	return d.normalized() if d.length_squared() > 0.0001 else forward()


func segment_right(i: int) -> Vector3:
	return segment_forward(i).cross(Vector3.UP)


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
	var pace := speed_now
	bounce = 0.0
	if body.gait() == AnimalGait.HOP and speed_now > 0.2:
		var leap := maxf(sin(time * HOP_RATE), 0.0)
		pace = speed_now * (0.3 + 1.6 * leap)
		bounce = leap * body.longest_leg() * 0.35
	spine[0] += forward() * pace * delta
	for i in range(1, spine.size()):
		var back := spine[i] - spine[i - 1]
		back.y = 0.0
		if back.length_squared() < 0.0001:
			back = -forward()
		spine[i] = spine[i - 1] + back.normalized() * spacing(i - 1)
	_rest_on_ground()
	legs.update(self, delta)


func _process(_delta: float) -> void:
	if body:
		_look.update(self)


func _rest_on_ground() -> void:
	var last := maxf(spine.size() - 1, 1)
	for i in spine.size():
		var p := spine[i]
		var arch := sin(PI * i / last) * body.arch * (body.ride_height() + body.radii[i])
		var half_height := body.radii[i] * body.shape_scale(i).y
		p.y = LandHeight.at(p.x, p.z) + body.ride_height() + half_height * 0.8 + arch + bounce
		if i == 0:
			p.y += body.neck * body.radii[0] * 0.8
		spine[i] = p
