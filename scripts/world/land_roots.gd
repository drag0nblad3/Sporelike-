class_name LandRoots
extends MultiMeshInstance3D
## Roots around a stage 4 village: low mounds that only gatherers with
## digging sticks can dig up (Discovery.STICKS), worth FOOD each. Dug
## spots grow back after a while. Hidden until the village learns to dig.
## One MultiMesh; the same lookups as LandFood (nearest, has, spot, take).

const COUNT := 36
const SPREAD := 60.0
const FOOD := 2
const REGROW := 55.0

var _spots := PackedVector3Array()
var _gone := PackedFloat32Array()
var _wait := 0.0


func setup(center: Vector3, rng: RandomNumberGenerator) -> void:
	var mound := SphereMesh.new()
	mound.radius = 0.7
	mound.height = 0.7
	mound.radial_segments = 8
	mound.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.33, 0.2)
	mound.material = mat
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mound
	multimesh.instance_count = COUNT
	for i in COUNT:
		var at := center + Vector3(rng.randf_range(-SPREAD, SPREAD), 0.0,
			rng.randf_range(-SPREAD, SPREAD))
		at.y = LandHeight.at(at.x, at.z) + 0.1
		_spots.append(at)
		_gone.append(0.0)
		multimesh.set_instance_transform(i, Transform3D(Basis(), at))
	visible = false


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0 or not visible:
		return
	_wait = 1.0
	for i in COUNT:
		if _gone[i] > 0.0:
			_gone[i] -= 1.0
			if _gone[i] <= 0.0:
				multimesh.set_instance_transform(i, Transform3D(Basis(), _spots[i]))


func nearest(at: Vector3, reach: float) -> int:
	var best := -1
	var best_d := reach * reach
	for i in COUNT:
		if _gone[i] > 0.0:
			continue
		var p := _spots[i]
		var d := (p.x - at.x) * (p.x - at.x) + (p.z - at.z) * (p.z - at.z)
		if d < best_d:
			best_d = d
			best = i
	return best


func has(i: int) -> bool:
	return i >= 0 and i < COUNT and _gone[i] <= 0.0


func spot(i: int) -> Vector3:
	return _spots[i]


func take(i: int) -> bool:
	if not has(i):
		return false
	_gone[i] = REGROW
	multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.01), _spots[i]))
	return true
