class_name LandFood
extends Node3D
## Things a stage 3 animal can pick up and carry home: berries on open
## ground and fallen fruit, thicker in forest (LandZone.forest). Walking
## over one picks it up if the mouth has room (CARRY); carried food bobs
## over the animal's back until the LandNest takes it. Picked spots grow
## back after a while.

const COUNT := 160
const SPREAD := 170.0
const CARRY := 3
const REGROW := 30.0
const RADIUS := 0.45

var rng := RandomNumberGenerator.new()
## Food in the animal's mouth now.
var carried := 0
var _items: Array[MeshInstance3D] = []
var _gone := PackedFloat32Array()
var _held: Array[MeshInstance3D] = []
var _mesh := SphereMesh.new()


func _ready() -> void:
	_mesh.radius = RADIUS
	_mesh.height = RADIUS * 2.0
	_mesh.radial_segments = 8
	_mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.2, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.05, 0.1)
	_mesh.material = mat
	for i in COUNT:
		var item := MeshInstance3D.new()
		item.mesh = _mesh
		add_child(item)
		_items.append(item)
		_gone.append(0.0)
		_place(item)
	for i in CARRY:
		var held := MeshInstance3D.new()
		held.mesh = _mesh
		held.visible = false
		add_child(held)
		_held.append(held)


## Picks up food under the animal and moves the carried food with it.
func step(animal: Animal, delta: float) -> void:
	var at := animal.head()
	var reach := animal.body.radii[0] + 1.2
	for i in _items.size():
		var item := _items[i]
		if not item.visible:
			_gone[i] -= delta
			if _gone[i] <= 0.0:
				_place(item)
			continue
		if carried < CARRY and Vector2(item.position.x - at.x, item.position.z - at.z).length() < reach:
			item.visible = false
			_gone[i] = REGROW
			carried += 1
	var top := animal.focus() + Vector3.UP * (animal.body.radii[0] * 1.6 + 0.6)
	for k in _held.size():
		_held[k].visible = k < carried
		_held[k].position = top + animal.forward().cross(Vector3.UP) * (k - 1) * 0.7 \
			+ Vector3.UP * sin(animal.time * 4.0 + k) * 0.12


## The nearest piece of food within `reach` of `at`, or -1 (for villagers).
func nearest(at: Vector3, reach: float) -> int:
	var best := -1
	var best_d := reach * reach
	for i in _items.size():
		if not _items[i].visible:
			continue
		var p := _items[i].position
		var d := (p.x - at.x) * (p.x - at.x) + (p.z - at.z) * (p.z - at.z)
		if d < best_d:
			best_d = d
			best = i
	return best


## True while piece i is still there to pick.
func has(i: int) -> bool:
	return i >= 0 and i < _items.size() and _items[i].visible


func spot(i: int) -> Vector3:
	return _items[i].position


## Somebody other than the player picks piece i; false if it was gone.
func take(i: int) -> bool:
	if i < 0 or not _items[i].visible:
		return false
	_items[i].visible = false
	_gone[i] = REGROW
	return true


## Hands over everything carried, returning how much.
func drop_all() -> int:
	var count := carried
	carried = 0
	return count


func _place(item: MeshInstance3D) -> void:
	var spot := Vector2.ZERO
	for _try in 6:
		spot = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * SPREAD
		if LandRiver.wet(spot.x, spot.y) > 0.1:
			continue
		if LandZone.forest(spot.x, spot.y) > 0.3 or rng.randf() < 0.5:
			break
	item.position = Vector3(spot.x, LandHeight.at(spot.x, spot.y) + RADIUS, spot.y)
	item.visible = true
