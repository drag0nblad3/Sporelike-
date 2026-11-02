class_name CurrentView
extends Node3D
## Makes one CurrentStream visible: a faint ribbon on the sea floor that
## follows its curves, plus pale streaks that slide along it at the water's
## speed. Stronger currents get more, longer and brighter streaks.

const STREAK_Y := -0.55
const RIBBON_Y := -1.3
const LANE := Color(0.55, 0.85, 1.0)

var stream: CurrentStream
var _multimesh: MultiMesh
var _offsets := PackedFloat32Array()
var _lanes := PackedFloat32Array()


func _init(s: CurrentStream) -> void:
	stream = s


func _ready() -> void:
	var strength := stream.strength()
	_add_ribbon(0.04 + 0.06 * strength)
	_add_streaks(strength)


## A strip along the path, clear at both edges and the ends, tinted in the middle.
func _add_ribbon(alpha: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var half := stream.width * 0.5
	var total := stream.length()
	var cols: Array[float] = [-1.0, 0.0, 1.0]
	for i in stream.points.size() - 1:
		var rows: Array = []
		for j in [i, i + 1]:
			var along: float = stream.marks[j]
			var p := stream.points[j]
			var dir := stream.tangent_at(minf(along, total - 0.01))
			var side := Vector2(-dir.y, dir.x)
			var fade := smoothstep(0.0, 5.0, along) * smoothstep(0.0, 5.0, total - along)
			var row: Array = []
			for c in cols:
				var at := p + side * half * c
				row.append([Vector3(at.x, RIBBON_Y, at.y), (1.0 - absf(c)) * fade])
			rows.append(row)
		for c in 2:
			_quad(st, rows[0][c], rows[0][c + 1], rows[1][c], rows[1][c + 1], alpha)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	var mat := _material(Color(1, 1, 1))
	mat.vertex_color_use_as_albedo = true
	mesh.material_override = mat
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
	var count := clampi(roundi(area / (14.0 - 8.0 * strength)), 8, 110)
	_multimesh.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([stream.points[0], stream.length()])
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


## Slides every streak downstream along the curve and wraps it back to the
## start, fading it in and out near the ends so it never pops.
func _place(delta: float) -> void:
	var total := stream.length()
	for i in _offsets.size():
		var along := fmod(_offsets[i] + stream.speed * delta, total)
		_offsets[i] = along
		var dir := stream.tangent_at(along)
		var p := stream.position_at(along) + Vector2(-dir.y, dir.x) * _lanes[i]
		var turn := Basis(Vector3.UP, atan2(dir.x, dir.y))
		_multimesh.set_instance_transform(i, Transform3D(turn, Vector3(p.x, STREAK_Y, p.y)))
		var fade := smoothstep(0.0, 4.0, along) * smoothstep(0.0, 4.0, total - along)
		fade *= 1.0 - absf(_lanes[i]) / (stream.width * 0.5)
		_multimesh.set_instance_color(i, Color(1, 1, 1, fade))


func _quad(st: SurfaceTool, a: Array, b: Array, c: Array, d: Array, alpha: float) -> void:
	for v in [a, b, c, b, d, c]:
		var weight: float = v[1]
		st.set_color(Color(LANE, alpha * weight))
		st.add_vertex(v[0])


static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
