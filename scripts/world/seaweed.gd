class_name Seaweed
extends Node3D
## A multicellular seaweed rooted to the sea floor: a stalk with a few side
## branches, built as an anchored SoftBody so swimmers push the fronds aside
## and they spring back, swaying in the current. Buds at the branch tips
## are food that grows back after it is eaten. Its PlantKind (from the sea
## it grows in) sets its shape, colours and food.

const CELL_GAP := 0.8

var kind := PlantKind.for_sea("shelf")
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
	var stalk := _branch(0, dir, rng.randi_range(kind.stalk_cells.x, kind.stalk_cells.y), rng)
	for k in rng.randi_range(kind.branches.x, kind.branches.y):
		var from := stalk[rng.randi_range(0, maxi(stalk.size() - 2, 0))]
		var turn := PI / 3.0 * (1.0 if k % 2 == 0 else -1.0) * rng.randf_range(0.7, 1.2)
		if kind.branches.y > 3:
			# Mats and mounds spread out all around their root.
			turn = TAU * (k + 1) / float(kind.branches.y + 1) + rng.randf_range(-0.3, 0.3)
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
	bud_wait[k] = kind.regrow
	return kind.bud_energy


func _physics_process(delta: float) -> void:
	_time += delta
	body.push_all(Vector3(sin(_time * 0.7), 0.0, cos(_time * 0.53)) * kind.sway)
	body.step(delta)
	for k in bud_wait.size():
		bud_wait[k] = maxf(bud_wait[k] - delta, 0.0)


func _process(_delta: float) -> void:
	if _cells == null:
		return
	for i in body.size():
		_cells.place(i, body.pos[i], lerpf(1.0, 0.6, i / float(body.size())), 0.6)
	for k in buds.size():
		var ripe := 1.0 - bud_wait[k] / kind.regrow
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
	_cells = BeadStrip.make(body.size(), kind.cell_size, 8)
	for i in body.size():
		_cells.set_color(i, kind.stalk.lightened(0.25 * i / float(body.size())))
	add_child(_cells)
	_bud_look = BeadStrip.make(buds.size(), 0.32, 8)
	for k in buds.size():
		_bud_look.set_color(k, kind.bud)
	add_child(_bud_look)
