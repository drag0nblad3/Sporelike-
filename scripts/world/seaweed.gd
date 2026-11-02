class_name Seaweed
extends Node3D
## A multicellular seaweed rooted to the sea floor: a stalk with a few side
## branches, built as an anchored SoftBody so swimmers push the fronds aside
## and they spring back, swaying in the current. Buds at the branch tips
## are food that grows back after it is eaten.

const BUD_ENERGY := 3.0
const REGROW := 10.0
const CELL_GAP := 0.8
const STALK := Color(0.25, 0.6, 0.3)
const BUD := Color(1.0, 0.85, 0.35)

var body := SoftBody.new()
## Which body points carry a bud, and seconds until each is ripe again.
var buds := PackedInt32Array()
var bud_wait := PackedFloat32Array()
var _cells: BeadStrip
var _bud_look: BeadStrip
var _time := 0.0


func grow_at(root: Vector3, rng: RandomNumberGenerator) -> void:
	body = SoftBody.new()
	body.anchored = true
	body.anchor = root
	body.shape_stiffness = 0.06
	body.drag = 3.0
	body.add_point(root, Vector3.ZERO, 0.0)
	_time = rng.randf() * 10.0
	var dir := Vector2.from_angle(rng.randf() * TAU)
	var stalk := _branch(0, dir, rng.randi_range(5, 7), rng)
	for k in rng.randi_range(2, 3):
		var from := stalk[rng.randi_range(1, stalk.size() - 2)]
		var turn := PI / 3.0 * (1.0 if k % 2 == 0 else -1.0) * rng.randf_range(0.7, 1.2)
		_branch(from, dir.rotated(turn), rng.randi_range(2, 4), rng)
	_build_look()


## The nearest ripe bud within `reach` of `from`, or -1.
func nearest_bud(from: Vector3, reach: float) -> int:
	var best := -1
	var best_d := reach * reach
	for k in buds.size():
		if bud_wait[k] > 0.0:
			continue
		var d := body.pos[buds[k]].distance_squared_to(from)
		if d <= best_d:
			best_d = d
			best = k
	return best


func bud_position(k: int) -> Vector3:
	return body.pos[buds[k]]


## Eats bud `k`; returns the energy it held.
func take_bud(k: int) -> float:
	bud_wait[k] = REGROW
	return BUD_ENERGY


func _physics_process(delta: float) -> void:
	_time += delta
	body.push_all(Vector3(sin(_time * 0.7), 0.0, cos(_time * 0.53)) * 0.6)
	body.step(delta)
	for k in bud_wait.size():
		bud_wait[k] = maxf(bud_wait[k] - delta, 0.0)


func _process(_delta: float) -> void:
	if _cells == null:
		return
	for i in body.size():
		_cells.place(i, body.pos[i], lerpf(1.0, 0.6, i / float(body.size())), 0.6)
	for k in buds.size():
		var ripe := 1.0 - bud_wait[k] / REGROW
		_bud_look.place(k, body.pos[buds[k]] + Vector3(0.0, 0.3, 0.0), maxf(ripe, 0.15))


func _branch(from: int, dir: Vector2, count: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var made := PackedInt32Array()
	var last := from
	for i in count:
		dir = dir.rotated(rng.randf_range(-0.35, 0.35))
		var local := body.rest[last] + Vector3(dir.x, 0.0, dir.y) * CELL_GAP
		var point := body.add_point(body.anchor + local, local)
		body.add_spring(last, point)
		made.append(point)
		last = point
	buds.append(last)
	bud_wait.append(0.0)
	return made


func _build_look() -> void:
	_cells = BeadStrip.make(body.size(), 0.42, 8)
	for i in body.size():
		_cells.set_color(i, STALK.lightened(0.25 * i / float(body.size())))
	add_child(_cells)
	_bud_look = BeadStrip.make(buds.size(), 0.32, 8)
	for k in buds.size():
		_bud_look.set_color(k, BUD)
	add_child(_bud_look)
