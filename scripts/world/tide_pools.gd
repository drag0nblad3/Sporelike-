class_name TidePools
extends Node3D
## Tide pools along the shore, just above the low-tide line: at high tide a
## colony can swim into one, and at low tide it is cut off from the sea.
## Each holds food that a colony inside eats and that slowly comes back, and
## hunters lose sight of a colony hiding in one. Pools sit at fixed spots
## along the shore, so a few meshes are moved to the ones near the colony.

const GAP := 24.0
const INLAND := 2.0
const RADIUS := 3.2
const SHOWN := 7
const FOOD_MAX := 30.0
const EAT_RATE := 2.5
const REGROW := 0.3
const EMPTY := Color(0.25, 0.35, 0.33, 0.85)
const FULL := Color(0.2, 0.62, 0.55, 0.85)

var _line: ShoreLine
## Pool index along the shore -> food left in it.
var _food := {}
var _meshes: Array[MeshInstance3D] = []
var _first := 0


func _ready() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.08
	disc.radial_segments = 20
	disc.rings = 1
	for i in SHOWN:
		var mesh := MeshInstance3D.new()
		mesh.mesh = disc
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.2
		mesh.material_override = mat
		add_child(mesh)
		_meshes.append(mesh)


func show_line(line: ShoreLine) -> void:
	_line = line
	_food.clear()
	visible = line != null


## Where pool `k` lies on the flat sea.
func center(k: int) -> Vector2:
	var jitter := sin(k * 12.9898) * GAP * 0.25
	return _line.point(k * GAP + jitter, INLAND)


## The pool a point is in, or -1.
func pool_at(p: Vector2) -> int:
	if _line == null:
		return -1
	var k := roundi(_line.along(p) / GAP)
	for near: int in [k - 1, k, k + 1]:
		if center(near).distance_squared_to(p) <= RADIUS * RADIUS:
			return near
	return -1


## A colony centred in pool `k` eats from it; returns the energy taken.
func eat(k: int, delta: float) -> float:
	var left: float = _food.get(k, FOOD_MAX)
	var taken := minf(left, EAT_RATE * delta)
	_food[k] = left - taken
	return taken


func follow(focus: Vector2, delta: float) -> void:
	if _line == null:
		return
	_first = roundi(_line.along(focus) / GAP) - int(SHOWN * 0.5)
	for k: int in _food.keys():
		_food[k] = minf(float(_food[k]) + REGROW * delta, FOOD_MAX)
	for i in SHOWN:
		var k := _first + i
		var at := center(k)
		var y := ShoreLook.FLOOR_Y + ShoreLine.rise(INLAND) + 0.05
		_meshes[i].position = Vector3(at.x, y, at.y)
		var mat := _meshes[i].material_override as StandardMaterial3D
		mat.albedo_color = EMPTY.lerp(FULL, float(_food.get(k, FOOD_MAX)) / FOOD_MAX)
