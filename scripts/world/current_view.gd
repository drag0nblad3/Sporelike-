class_name CurrentView
extends Node3D
## Makes one CurrentStream visible: a faint band on the sea floor plus pale
## streaks that slide along it at the water's speed. Stronger currents get
## more, longer and brighter streaks.

const STREAK_Y := -0.55
const BAND_Y := -1.3

var stream: CurrentStream
var _multimesh: MultiMesh
var _offsets := PackedFloat32Array()
var _lanes := PackedFloat32Array()


func _init(s: CurrentStream) -> void:
	stream = s


func _ready() -> void:
	var strength := stream.strength()
	var dir := stream.direction()
	rotation.y = atan2(dir.x, dir.y)
	var mid := (stream.start + stream.finish) * 0.5
	position = Vector3(mid.x, 0.0, mid.y)
	_add_band(strength)
	_add_streaks(strength)


func _add_band(strength: float) -> void:
	var band := PlaneMesh.new()
	band.size = Vector2(stream.width, stream.length())
	var mesh := MeshInstance3D.new()
	mesh.mesh = band
	mesh.position.y = BAND_Y
	mesh.material_override = _material(Color(0.55, 0.85, 1.0, 0.05 + 0.07 * strength))
	add_child(mesh)


func _add_streaks(strength: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12 + 0.06 * strength, 0.8 + 2.2 * strength)
	quad.orientation = PlaneMesh.FACE_Y
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = quad
	var area := stream.width * stream.length()
	var count := clampi(roundi(area / (14.0 - 8.0 * strength)), 8, 90)
	_multimesh.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([stream.start, stream.finish])
	for i in count:
		_offsets.append(rng.randf() * stream.length())
		_lanes.append(rng.randf_range(-0.42, 0.42) * stream.width)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _multimesh
	var mat := _material(Color(0.8, 0.95, 1.0, 0.3 + 0.4 * strength))
	mat.vertex_color_use_as_albedo = true
	instance.material_override = mat
	add_child(instance)
	_place(0.0)


func _process(delta: float) -> void:
	_place(delta)


## Slides every streak downstream and wraps it back to the start, fading
## it in and out near the ends so it never pops.
func _place(delta: float) -> void:
	var total := stream.length()
	var half := total * 0.5
	for i in _offsets.size():
		var along := fmod(_offsets[i] + stream.speed * delta, total)
		_offsets[i] = along
		var at := Vector3(_lanes[i], STREAK_Y, along - half)
		_multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
		var fade := smoothstep(0.0, 3.0, along) * smoothstep(0.0, 3.0, total - along)
		fade *= 1.0 - absf(_lanes[i]) / (stream.width * 0.5)
		_multimesh.set_instance_color(i, Color(1, 1, 1, fade))


static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
