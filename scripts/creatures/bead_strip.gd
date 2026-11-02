class_name BeadStrip
extends MultiMeshInstance3D
## Draws many coloured balls in one draw call (a MultiMesh): the cells of a
## colony, the joints of a limb, the cells of a seaweed. Callers place each
## ball every frame with place().


## `count` balls of `radius`, each tinted with set_color().
static func make(count: int, radius: float, segments: int = 10) -> BeadStrip:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = segments
	sphere.rings = maxi(int(segments / 2.0), 3)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sphere
	mm.instance_count = count
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.45
	var strip := BeadStrip.new()
	strip.multimesh = mm
	strip.material_override = mat
	return strip


func count() -> int:
	return multimesh.instance_count


func set_color(i: int, color: Color) -> void:
	multimesh.set_instance_color(i, color)


func place(i: int, at: Vector3, size: float = 1.0, squash: float = 1.0) -> void:
	var basis := Basis.from_scale(Vector3(size, size * squash, size))
	multimesh.set_instance_transform(i, Transform3D(basis, at))
