class_name PartBaker
extends RefCounted
## Merges the still, opaque parts under a node (spikes, cilia, mouth rods,
## organelles, shell pores...) into one mesh. Every MeshInstance3D is its
## own draw call, and a cell can have dozens of parts, so this keeps a crowd
## of cells cheap to draw on phones. Each part keeps its colour and glow
## through vertex data and a shared shader that matches
## VisualParts.material (PartMaterial). Moving parts must be passed in
## `skip`.

## Parts with a radius at or above this get the finer sphere.
const FINE_RADIUS := 0.2


## Replaces the mergeable parts below `anchor` with one mesh child. Nodes
## in `skip`, nodes with scripts and everything under them are left alone.
static func bake(anchor: Node3D, skip: Array = []) -> void:
	var found: Array = []
	_collect(anchor, Transform3D.IDENTITY, skip, found)
	if found.size() < 2:
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var glows := PackedVector2Array()
	var idx := PackedInt32Array()
	for entry in found:
		var shape: Array = entry[1]
		var xf: Transform3D = entry[2]
		var mat := (entry[0] as MeshInstance3D).material_override as StandardMaterial3D
		var base := verts.size()
		var part_verts: PackedVector3Array = shape[0]
		var part_normals: PackedVector3Array = shape[1]
		var part_idx: PackedInt32Array = shape[2]
		verts.append_array(xf * part_verts)
		normals.append_array(Transform3D(xf.basis.inverse().transposed(), Vector3.ZERO) * part_normals)
		var tint := PackedColorArray()
		tint.resize(part_verts.size())
		tint.fill(Color(mat.albedo_color, 1.0))
		colors.append_array(tint)
		var glow := PackedVector2Array()
		glow.resize(part_verts.size())
		glow.fill(Vector2(PartMaterial.glow(mat), 0.0))
		glows.append_array(glow)
		for i in part_idx:
			idx.append(i + base)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV2] = glows
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var merged := MeshInstance3D.new()
	merged.mesh = mesh
	merged.material_override = PartMaterial.shared()
	anchor.add_child(merged)
	# Children were found after their parents, so free from the back.
	for i in range(found.size() - 1, -1, -1):
		var part: MeshInstance3D = found[i][0]
		if part.get_child_count() == 0:
			part.free()
		else:
			part.mesh = null


static func _collect(node: Node3D, xf: Transform3D, skip: Array, found: Array) -> void:
	for child in node.get_children():
		var part := child as Node3D
		if part == null or part in skip or part.get_script() != null or not part.visible:
			continue
		var at := xf * part.transform
		var mesh_part := part as MeshInstance3D
		if mesh_part and PartMaterial.paintable(mesh_part.material_override as StandardMaterial3D):
			var shape := _shape(mesh_part.mesh)
			if not shape.is_empty():
				var from_unit: Transform3D = shape[1]
				found.append([mesh_part, shape[0], at * from_unit])
		_collect(part, at, skip, found)


## [geometry, transform from the unit shape] for the primitives cells use,
## or [] for anything else.
static func _shape(mesh: Mesh) -> Array:
	var prim := mesh as PrimitiveMesh
	if prim == null or prim.material != null:
		return []
	if mesh is SphereMesh:
		var s := mesh as SphereMesh
		if s.is_hemisphere:
			return []
		var fine := s.radius >= FINE_RADIUS
		var unit := PartShapes.sphere(16 if fine else 10, 8 if fine else 5)
		var size := Vector3(s.radius, s.height * 0.5, s.radius)
		return [unit, Transform3D(Basis.from_scale(size), Vector3.ZERO)]
	if mesh is CapsuleMesh:
		var c := mesh as CapsuleMesh
		var mid := maxf(c.height * 0.5 - c.radius, 0.0) / maxf(c.radius, 0.0001)
		var unit := PartShapes.sphere(10, 7, mid)
		return [unit, Transform3D(Basis.from_scale(Vector3.ONE * c.radius), Vector3.ZERO)]
	if mesh is CylinderMesh:
		var y := mesh as CylinderMesh
		if not y.cap_top or not y.cap_bottom:
			return []
		var shape := PartShapes.cylinder(y.top_radius, y.bottom_radius, y.height, 10)
		return [shape, Transform3D.IDENTITY]
	if mesh is TorusMesh:
		var t := mesh as TorusMesh
		return [PartShapes.torus(t.inner_radius, t.outer_radius, 20, 8), Transform3D.IDENTITY]
	return []
