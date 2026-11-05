class_name ColonySkin
extends MeshInstance3D
## One shared skin stretched over all of a colony's cells, so it reads as a
## single animal: a translucent dome (SkinShader) over the outline ring
## from ColonyOutline, with a soft shadow on the sea floor beneath it. The
## mesh never changes; each frame only the ring is handed to the shader.

## How far the web's rings sit from the centre (0) to the outline (1);
## closer together near the edge, where the dome curves most.
const RINGS := [0.0, 0.35, 0.6, 0.78, 0.9, 0.97, 1.0]

var outline := ColonyOutline.new()
var _skin_mat: ShaderMaterial
var _shadow_mat: ShaderMaterial
var _shadow := MeshInstance3D.new()


func _init() -> void:
	# A child from the start, so it is freed with the skin even if the skin
	# is thrown away before it is ever built.
	add_child(_shadow)


func build(rest: PackedVector3Array, tint: Color) -> void:
	outline.build(rest)
	if mesh == null:
		mesh = _web()
		_shadow.mesh = mesh
	_skin_mat = SkinShader.material(tint)
	_shadow_mat = SkinShader.material(tint, true)
	_shadow_mat.set_shader_parameter("base", 0.0)
	# Bigger bodies stand a little taller.
	_skin_mat.set_shader_parameter("height", clampf(0.5 + 0.1 * sqrt(rest.size()), 0.75, 1.2))
	material_override = _skin_mat
	_shadow.material_override = _shadow_mat
	var reach := 0.0
	for p in rest:
		reach = maxf(reach, Vector2(p.x, p.z).length())
	var box := AABB(Vector3(-reach - 3.0, -2.0, -reach - 3.0),
			Vector3(2.0 * reach + 6.0, 4.0, 2.0 * reach + 6.0))
	custom_aabb = box
	_shadow.custom_aabb = box


func update(body: SoftBody, time: float) -> void:
	if _skin_mat == null:
		return
	outline.update(body, time)
	# The skin rides at the body's depth; its shadow stays on the floor,
	# further from the sun and fainter the higher the body swims.
	position = body.center()
	var lift := maxf(position.y - FloorShadow.FLOOR, 0.0)
	var shift := FloorShadow.SUN_SHIFT * lift
	_shadow.position = Vector3(shift.x, FloorShadow.FLOOR - position.y, shift.y)
	_shadow_mat.set_shader_parameter("shade", 0.4 / (1.0 + 0.12 * lift))
	_skin_mat.set_shader_parameter("ring", outline.ring)
	_shadow_mat.set_shader_parameter("ring", outline.ring)


## A flat web of rings; UV.x is the point on the outline, UV.y how far out.
static func _web() -> ArrayMesh:
	var n := ColonyOutline.POINTS
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var index := PackedInt32Array()
	for r in RINGS.size():
		for k in n:
			verts.append(Vector3.ZERO)
			normals.append(Vector3.UP)
			uvs.append(Vector2(k, float(RINGS[r])))
	for r in RINGS.size() - 1:
		for k in n:
			var a := r * n + k
			var b := r * n + (k + 1) % n
			for v in [a, a + n, b, b, a + n, b + n]:
				index.append(v)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = index
	var web := ArrayMesh.new()
	web.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return web
