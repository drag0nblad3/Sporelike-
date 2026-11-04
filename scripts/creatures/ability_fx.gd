class_name AbilityFx
extends RefCounted
## Short-lived visuals for the active abilities: an expanding ring
## (Trichocysts), a dart line to each target (Toxicysts) and a glowing
## bubble (Scintillons flash). Each one fades and frees itself.

const TIME := 0.4


## A flat ring that grows from the cell out to `reach`.
static func ring(from: Node3D, reach: float, color: Color) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.92
	torus.outer_radius = 1.0
	var mesh := _place(from, torus, color)
	if mesh:
		mesh.scale = Vector3.ONE * 0.5
		_fade(mesh, Vector3(reach, 1.0, reach))


## A bright bubble that swells to `reach` and fades.
static func glow(from: Node3D, reach: float, color: Color) -> void:
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	var mesh := _place(from, ball, Color(color, 0.5))
	if mesh:
		mesh.scale = Vector3.ONE
		_fade(mesh, Vector3.ONE * reach)


## A thin line from the cell to the target, fading out.
static func dart(from: Node3D, to: Node3D, color: Color) -> void:
	var a := from.global_position
	var b := to.global_position
	a.y = 0.3
	b.y = 0.3
	if a.distance_to(b) < 0.05:
		return
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, a.distance_to(b))
	var mesh := _place(from, box, color)
	if mesh:
		mesh.global_position = (a + b) * 0.5
		mesh.look_at(b)
		_fade(mesh, mesh.scale)


static func _place(from: Node3D, shape: Mesh, color: Color) -> MeshInstance3D:
	var world := from.get_parent()
	if world == null or not from.is_inside_tree():
		return null
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mesh)
	mesh.global_position = Vector3(from.global_position.x, 0.3, from.global_position.z)
	return mesh


static func _fade(mesh: MeshInstance3D, to_scale: Vector3) -> void:
	var mat := mesh.material_override as StandardMaterial3D
	var tween := mesh.create_tween().set_parallel()
	tween.tween_property(mesh, "scale", to_scale, TIME)
	tween.tween_property(mat, "albedo_color:a", 0.0, TIME)
	tween.chain().tween_callback(mesh.queue_free)
