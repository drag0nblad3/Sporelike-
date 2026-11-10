class_name VillageBuildings
extends Node3D
## The stage 4 village's four buildings (VillageBuilding) on fixed spots
## around the centre: their levels, the one being raised now (queue) and
## its progress from villagers' work, and simple shapes for each: a squat
## food store, a domed nursery, a lookout post and a ring wall. A building
## grows out of the ground as it is built.

signal finished(id: String, level: int)

const RING := 6.5
const WALL_RADIUS := 11.0
const TINTS := {"store": Color(0.72, 0.55, 0.3), "nursery": Color(0.9, 0.8, 0.62),
	"lookout": Color(0.5, 0.36, 0.22), "wall": Color(0.42, 0.34, 0.24)}

var levels := {}
## The building being raised, or "".
var active := ""
var progress := 0.0
var _center := Vector3.ZERO
var _shapes := {}


func _ready() -> void:
	for id in VillageBuilding.ALL:
		levels[id] = 0
		var shape := MeshInstance3D.new()
		shape.mesh = _mesh(id)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = TINTS[id]
		mat.roughness = 0.9
		shape.material_override = mat
		shape.visible = false
		add_child(shape)
		_shapes[id] = shape


func place(center: Vector3) -> void:
	_center = center
	for k in VillageBuilding.ALL.size():
		var id := VillageBuilding.ALL[k]
		var at := center if id == VillageBuilding.WALL \
			else CrowdFind.ring(center, 0, RING, TAU * k / 3.0 + 0.6)
		at.y = LandHeight.at(at.x, at.z)
		(_shapes[id] as MeshInstance3D).position = at


func level(id: String) -> int:
	var n: int = levels.get(id, 0)
	return n


func built() -> int:
	var n := 0
	for id in VillageBuilding.ALL:
		n += 1 if level(id) > 0 else 0
	return n


## Sets a building's level outright (tests and screenshots).
func set_level(id: String, to: int) -> void:
	levels[id] = to
	_show(id)


## Starts raising the next level of `id`. False if busy or finished.
func queue(id: String) -> bool:
	if active != "" or level(id) >= VillageBuilding.MAX_LEVEL:
		return false
	active = id
	progress = 0.0
	_show(id)
	return true


## Where villagers go to work on the queued building, or INF.
func site() -> Vector3:
	if active == "":
		return Vector3.INF
	var at := (_shapes[active] as MeshInstance3D).position
	return at + Vector3(0.0, 0.0, WALL_RADIUS) if active == VillageBuilding.WALL else at


func add_work(seconds: float) -> void:
	if active == "":
		return
	progress += seconds
	if progress >= VillageBuilding.work(level(active)):
		var id := active
		levels[id] = level(id) + 1
		active = ""
		progress = 0.0
		_show(id)
		finished.emit(id, level(id))
	else:
		_show(active)


## Share of the queued building done, 0 to 1.
func share() -> float:
	return 0.0 if active == "" else progress / VillageBuilding.work(level(active))


func _show(id: String) -> void:
	var shape: MeshInstance3D = _shapes[id]
	var grown := 0.6 + 0.4 * level(id)
	var rising := share() if id == active else 0.0
	shape.visible = level(id) > 0 or id == active
	var tall := maxf(grown - 0.4 + 0.4 * rising if level(id) > 0 else 0.15 + 0.85 * rising, 0.1)
	var wide := 1.0 if id == VillageBuilding.WALL else maxf(grown, 1.0)
	# The wall is a flat ring, so stretch it up into a palisade.
	shape.scale = Vector3(wide, tall * (3.0 if id == VillageBuilding.WALL else 1.0), wide)


func _mesh(id: String) -> Mesh:
	match id:
		VillageBuilding.STORE:
			var drum := CylinderMesh.new()
			drum.top_radius = 1.5
			drum.bottom_radius = 1.9
			drum.height = 3.2
			drum.radial_segments = 10
			return drum
		VillageBuilding.NURSERY:
			var dome := SphereMesh.new()
			dome.radius = 2.0
			dome.height = 3.2
			dome.radial_segments = 12
			dome.rings = 6
			return dome
		VillageBuilding.LOOKOUT:
			var post := CylinderMesh.new()
			post.top_radius = 0.9
			post.bottom_radius = 0.45
			post.height = 9.0
			post.radial_segments = 8
			return post
	var wall := TorusMesh.new()
	wall.inner_radius = WALL_RADIUS - 0.5
	wall.outer_radius = WALL_RADIUS + 0.5
	wall.rings = 28
	wall.ring_segments = 6
	return wall
