class_name CrowdProxies
extends Node3D
## Draws every CrowdActor without a full body as simple shapes: a body
## blob and a head in the animal's own colours, plus what it carries, as
## MultiMeshes (four draw calls for the whole crowd), with the tool each
## villager has learned to use held beside it. Moving ones
## bob; hurt ones darken. grow: drawn larger for the overhead view.

const MOST := 64
## Width and length of each tool kind (Discovery.TOOLS; 0 is none), and its colour.
const TOOL_SHAPES: Array[Vector2] = [Vector2.ZERO, Vector2(0.07, 1.5), Vector2(0.35, 0.5),
	Vector2(0.2, 0.25), Vector2(0.06, 2.6), Vector2(0.12, 0.6)]
const TOOL_TINTS: Array[Color] = [Color.WHITE, Color(0.55, 0.38, 0.2), Color(0.85, 0.72, 0.42),
	Color(0.6, 0.6, 0.62), Color(0.8, 0.76, 0.65), Color(0.95, 0.93, 0.85)]

var grow := 1.0
var _bodies := MultiMesh.new()
var _heads := MultiMesh.new()
var _loads := MultiMesh.new()
var _tools := MultiMesh.new()
var _time := 0.0


func _ready() -> void:
	for mm: MultiMesh in [_bodies, _heads, _loads, _tools]:
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = AnimalParts.rod() if mm == _tools else _ball()
		mm.instance_count = MOST
		mm.visible_instance_count = 0
		var node := MultiMeshInstance3D.new()
		node.multimesh = mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.7
		node.material_override = mat
		# The crowd moves, so never cull it by a stale bounding box.
		node.custom_aabb = AABB(Vector3(-400, -100, -400), Vector3(800, 300, 800))
		add_child(node)


func draw(actors: Array[CrowdActor], delta: float) -> void:
	_time += delta
	var n := 0
	var held := 0
	var tools := 0
	for actor in actors:
		if not actor.alive or n >= MOST:
			continue
		var s := actor.size() * grow
		var fwd := Vector3(sin(actor.heading), 0.0, cos(actor.heading))
		var side := fwd.cross(Vector3.UP)
		if actor.tool > 0 and tools < MOST:
			# Tools show on full bodies too, held up beside them.
			var shape: Vector2 = TOOL_SHAPES[actor.tool]
			_tools.set_instance_transform(tools, Transform3D(Basis.from_scale(Vector3(shape.x,
				shape.y, shape.x) * grow), actor.pos + side * (s * 1.2 + 0.3)
				+ Vector3.UP * (s * 1.4 + shape.y * 0.5 * grow)))
			_tools.set_instance_color(tools, TOOL_TINTS[actor.tool])
			tools += 1
		if actor.avatar != null:
			continue
		var bob := absf(sin(_time * 9.0 + actor.slot * 1.7)) * 0.25 * s if actor.moving else 0.0
		var at := actor.pos + Vector3.UP * (s * 1.2 + bob)
		var long := 1.0 + minf(actor.body.segments(), 6) * 0.22
		_bodies.set_instance_transform(n, Transform3D(Basis(-side * s, Vector3.UP * s * 0.85,
			fwd * s * long), at))
		var hurt := clampf(actor.health / actor.max_health, 0.35, 1.0)
		_bodies.set_instance_color(n, actor.body.color() * Color(hurt, hurt, hurt))
		var head_at := at + fwd * s * long + Vector3.UP * s * 0.45
		_heads.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3.ONE * s * 0.62), head_at))
		_heads.set_instance_color(n, actor.body.color2())
		n += 1
		if actor.carrying > 0 and held < MOST:
			_loads.set_instance_transform(held, Transform3D(Basis.from_scale(Vector3.ONE * 0.4 * grow),
				at + Vector3.UP * s * 1.4))
			_loads.set_instance_color(held, Color(0.9, 0.25, 0.3))
			held += 1
	_bodies.visible_instance_count = n
	_heads.visible_instance_count = n
	_loads.visible_instance_count = held
	_tools.visible_instance_count = tools


static func _ball() -> SphereMesh:
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 10
	ball.rings = 5
	return ball
