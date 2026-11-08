class_name LandMulti
extends RefCounted
## Turns a list of placed copies of one mesh into a single lit
## MultiMeshInstance3D, so hundreds of stage 3 rocks or trees cost one
## draw call. Each copy carries its own transform and tint.

const CHUNK := 80.0
## Patches further than this from the camera are not drawn (the haze has
## hidden them by then).
const FAR := 170.0


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


## Like build(), but split into square patches of CHUNK units so patches
## behind the camera or past FAR are skipped. Returns their parent.
static func build_patches(mesh: Mesh, places: Array[Transform3D], tints: PackedColorArray) -> Node3D:
	var groups := {}
	for i in places.size():
		var o := places[i].origin
		var key := Vector2i(floori(o.x / CHUNK), floori(o.z / CHUNK))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(i)
	var root := Node3D.new()
	for key: Vector2i in groups:
		# Each patch sits at its own centre, which is what its range is
		# measured from.
		var center := Vector3((key.x + 0.5) * CHUNK, 0.0, (key.y + 0.5) * CHUNK)
		var picked: Array[Transform3D] = []
		var colors := PackedColorArray()
		for i: int in groups[key]:
			picked.append(places[i].translated(-center))
			colors.append(tints[i])
		var node := build(mesh, picked, colors)
		node.position = center
		node.visibility_range_end = FAR
		node.visibility_range_end_margin = 10.0
		root.add_child(node)
	return root


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
