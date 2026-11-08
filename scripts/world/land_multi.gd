class_name LandMulti
extends RefCounted
## Turns a list of placed copies of one mesh into a single lit
## MultiMeshInstance3D, so hundreds of stage 3 rocks or trees cost one
## draw call. Each copy carries its own transform and tint.


static func build(mesh: Mesh, places: Array[Transform3D], tints: PackedColorArray) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = places.size()
	for i in places.size():
		mm.set_instance_transform(i, places[i])
		mm.set_instance_color(i, tints[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.9
	node.material_override = mat
	return node


## A low-poly upright cylinder or cone (top 0) one unit tall, base at 0.
static func post(top: float, bottom: float, sides: int) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = 1.0
	m.radial_segments = sides
	m.rings = 1
	return _lifted(m, 0.5)


## A low-poly ball or squashed blob, centred.
static func blob(radius: float, height: float, sides: int, rings: int) -> Mesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = sides
	m.rings = rings
	return m


static func _lifted(mesh: PrimitiveMesh, by: float) -> Mesh:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i].y += by
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out
