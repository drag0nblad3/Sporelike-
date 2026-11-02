class_name SoftBody
extends RefCounted
## A cheap soft-body solver for colonies and plants. Points (one per cell)
## move by Verlet integration with water drag, springs keep neighbours at
## their resting distance, and shape matching pulls the whole body back
## toward its resting shape, turned about the vertical axis. Points are 3D
## so layered bodies can come later; for now each is held at its rest
## height, so play stays flat. Everything lives in packed arrays, so 40
## cells cost well under a millisecond a frame.

var pos := PackedVector3Array()
var prev := PackedVector3Array()
## Each point's place in the resting shape, relative to the body's centre.
var rest := PackedVector3Array()
## 1 / mass; 0 pins a point in place (a plant's root).
var inv_mass := PackedFloat32Array()
var accel := PackedVector3Array()
var spring_a := PackedInt32Array()
var spring_b := PackedInt32Array()
var spring_len := PackedFloat32Array()

## Share of each spring's stretch undone per pass, and passes per step.
var spring_stiffness := 0.5
var passes := 3
## Share of the gap to the resting shape closed each step.
var shape_stiffness := 0.2
## Share of speed the water takes away each second.
var drag := 2.5
## Angle about +Y the resting shape is steered toward, and how strongly
## it overrides the angle the body has drifted to on its own (0 to 1).
var heading := 0.0
var steer := 0.0
## Plants: the resting shape stays at `anchor` and never turns.
var anchored := false
var anchor := Vector3.ZERO
## The angle the resting shape was matched at last step.
var angle := 0.0

var _reach := 0.0
var _last_center := Vector3.ZERO
var _velocity := Vector3.ZERO


func add_point(at: Vector3, rest_offset: Vector3, mass: float = 1.0) -> int:
	pos.append(at)
	prev.append(at)
	rest.append(rest_offset)
	inv_mass.append(0.0 if mass <= 0.0 else 1.0 / mass)
	accel.append(Vector3.ZERO)
	_reach = maxf(_reach, rest_offset.length())
	_last_center = center()
	return pos.size() - 1


func add_spring(a: int, b: int) -> void:
	spring_a.append(a)
	spring_b.append(b)
	spring_len.append(rest[a].distance_to(rest[b]))


## Joins every pair of points whose resting distance is at most max_dist.
func connect_near(max_dist: float) -> void:
	for a in pos.size():
		for b in range(a + 1, pos.size()):
			if rest[a].distance_to(rest[b]) <= max_dist:
				add_spring(a, b)


func size() -> int:
	return pos.size()


func center() -> Vector3:
	var sum := Vector3.ZERO
	for p in pos:
		sum += p
	return sum / float(maxi(pos.size(), 1))


## How far the resting shape reaches from its centre.
func reach() -> float:
	return _reach


func velocity() -> Vector3:
	return _velocity


## Where a point of the resting shape is now, e.g. the gut cavity.
func to_world(rest_offset: Vector3) -> Vector3:
	var base := anchor if anchored else center()
	return base + rest_offset.rotated(Vector3.UP, angle)


## Adds an acceleration (units/s²) to every point for the next step.
func push_all(a: Vector3) -> void:
	for i in accel.size():
		accel[i] += a


func push(i: int, a: Vector3) -> void:
	accel[i] += a


func step(delta: float) -> void:
	if pos.is_empty() or delta <= 0.0:
		return
	var keep := maxf(1.0 - drag * delta, 0.0)
	var dt2 := delta * delta
	for i in pos.size():
		if inv_mass[i] > 0.0:
			var p := pos[i]
			pos[i] = p + (p - prev[i]) * keep + accel[i] * dt2
			prev[i] = p
		accel[i] = Vector3.ZERO
	for _pass in passes:
		_solve_springs()
	_match_shape()
	var c := center()
	_velocity = (c - _last_center) / delta
	_last_center = c


func _solve_springs() -> void:
	for s in spring_a.size():
		var a := spring_a[s]
		var b := spring_b[s]
		var wa := inv_mass[a]
		var wb := inv_mass[b]
		if wa + wb <= 0.0:
			continue
		var d := pos[b] - pos[a]
		var dist := d.length()
		if dist < 0.0001:
			continue
		var fix := d * ((dist - spring_len[s]) / dist * spring_stiffness / (wa + wb))
		pos[a] += fix * wa
		pos[b] -= fix * wb


## Finds the turn that best fits the resting shape onto the points, blends
## it toward `heading`, then pulls each point toward its place in that pose.
func _match_shape() -> void:
	var c := anchor if anchored else center()
	angle = heading
	if not anchored:
		var along := 0.0
		var across := 0.0
		for i in pos.size():
			var p := pos[i] - c
			var q := rest[i]
			along += p.x * q.x + p.z * q.z
			across += p.x * q.z - p.z * q.x
		angle = lerp_angle(atan2(across, along), heading, steer)
	for i in pos.size():
		if inv_mass[i] <= 0.0:
			continue
		var goal := c + rest[i].rotated(Vector3.UP, angle)
		var p := pos[i]
		p += (goal - p) * shape_stiffness
		p.y = c.y + rest[i].y if anchored else rest[i].y
		pos[i] = p
