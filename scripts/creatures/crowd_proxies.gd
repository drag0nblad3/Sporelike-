class_name CrowdProxies
extends Node3D
## Draws every CrowdActor without a full body as simple shapes: a body
## blob and a head in the animal's own colours, plus what it carries, as
## three MultiMeshes (three draw calls for the whole crowd). Moving ones
## bob; hurt ones darken. grow: drawn larger for the overhead view.

const MOST := 64

var grow := 1.0
var _bodies := MultiMesh.new()
var _heads := MultiMesh.new()
var _loads := MultiMesh.new()
var _time := 0.0


func _ready() -> void:
	for mm: MultiMesh in [_bodies, _heads, _loads]:
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _ball()
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
	for actor in actors:
		if actor.avatar != null or not actor.alive or n >= MOST:
			continue
		var s := actor.size() * grow
		var fwd := Vector3(sin(actor.heading), 0.0, cos(actor.heading))
		var side := fwd.cross(Vector3.UP)
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


static func _ball() -> SphereMesh:
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 10
	ball.rings = 5
	return ball
