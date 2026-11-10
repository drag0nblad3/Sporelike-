class_name ElderAura
extends MeshInstance3D
## A faint ring on the ground showing how far the stage 4 elder's aura
## reaches, and a tall marker for the focus flag (flag). One thin torus
## and one post; both unshaded so they cost next to nothing.

var flag := MeshInstance3D.new()
var _ring := TorusMesh.new()


func _ready() -> void:
	_ring.rings = 40
	_ring.ring_segments = 4
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(1.0, 0.9, 0.5, 0.4)
	_ring.material = glow
	mesh = _ring
	scale = Vector3(1.0, 0.3, 1.0)
	set_reach(VillageTraits.AURA)
	var post := CylinderMesh.new()
	post.top_radius = 0.9
	post.bottom_radius = 0.15
	post.height = 9.0
	post.radial_segments = 6
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = Color(1.0, 0.45, 0.2)
	post.material = paint
	flag.mesh = post
	flag.top_level = true
	flag.visible = false
	add_child(flag)


func set_reach(radius: float) -> void:
	_ring.inner_radius = radius - 0.25
	_ring.outer_radius = radius + 0.25


func follow(at: Vector3, alive: bool) -> void:
	visible = alive
	position = at + Vector3.UP * 0.25


func show_flag(at: Vector3) -> void:
	flag.visible = at != Vector3.INF
	if flag.visible:
		flag.global_position = at + Vector3.UP * 4.5
