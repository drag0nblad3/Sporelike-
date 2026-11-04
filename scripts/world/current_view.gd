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
## Per streak: 12 transform floats then 4 colour floats, sent in one call.
var _buffer := PackedFloat32Array()
var _screen: VisibleOnScreenNotifier3D
## Streaks move every other frame, half the views on even frames and half on
## odd ones, so a screen full of currents costs half as much. They move
## slowly enough that the steps don't show.
var _odd := false
var _held := 0.0


func _init(s: CurrentStream) -> void:
	stream = s


func _ready() -> void:
	var strength := stream.strength()
	_add_ribbon(0.09 + 0.1 * strength)
	_add_streaks(strength)
	# Only animate streaks while some of the stream is on screen.
	var box := stream.bounds()
	_screen = VisibleOnScreenNotifier3D.new()
	_screen.aabb = AABB(Vector3(box.position.x, RIBBON_Y, box.position.y),
		Vector3(box.size.x, STREAK_Y - RIBBON_Y + 0.5, box.size.y))
	add_child(_screen)


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
	quad.size = Vector2(0.18 + 0.1 * strength, 1.0 + 2.4 * strength)
	quad.orientation = PlaneMesh.FACE_Y
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = quad
	var area := stream.width * stream.length()
	var count := clampi(roundi(area / (10.0 - 6.0 * strength)), 10, 120)
	_multimesh.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([stream.points[0], stream.length()])
	_odd = rng.randf() < 0.5
	for i in count:
		_offsets.append(rng.randf() * stream.length())
		_lanes.append(rng.randf_range(-0.42, 0.42) * stream.width)
	_buffer.resize(count * 16)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _multimesh
	var mat := _material(Color(0.85, 0.97, 1.0, 0.5 + 0.4 * strength))
	mat.vertex_color_use_as_albedo = true
	instance.material_override = mat
	add_child(instance)
	_place(0.0)


func _process(delta: float) -> void:
	_held += delta
	if (Engine.get_process_frames() % 2 == 1) != _odd:
		return
	if _screen.is_on_screen():
		_place(_held)
	_held = 0.0


## Slides every streak downstream along the curve and wraps it back to the
## start, fading it in and out near the ends so it never pops. Off screen
## the streaks wait where they are; nobody can see them pause.
func _place(delta: float) -> void:
	var total := stream.length()
	var half := stream.width * 0.5
	var step := stream.speed * delta
	for i in _offsets.size():
		var along := fmod(_offsets[i] + step, total)
		_offsets[i] = along
		var dir := stream.tangent_at(along)
		var lane := _lanes[i]
		var p := stream.position_at(along) + Vector2(-dir.y, dir.x) * lane
		var fade := smoothstep(0.0, 4.0, along) * smoothstep(0.0, 4.0, total - along)
		fade *= 1.0 - absf(lane) / half
		# A turn about Y that points the streak along dir, as matrix rows.
		var k := i * 16
		_buffer[k] = dir.y
		_buffer[k + 1] = 0.0
		_buffer[k + 2] = dir.x
		_buffer[k + 3] = p.x
		_buffer[k + 4] = 0.0
		_buffer[k + 5] = 1.0
		_buffer[k + 6] = 0.0
		_buffer[k + 7] = STREAK_Y
		_buffer[k + 8] = -dir.x
		_buffer[k + 9] = 0.0
		_buffer[k + 10] = dir.y
		_buffer[k + 11] = p.y
		_buffer[k + 12] = 1.0
		_buffer[k + 13] = 1.0
		_buffer[k + 14] = 1.0
		_buffer[k + 15] = fade
	_multimesh.buffer = _buffer


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
