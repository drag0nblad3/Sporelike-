class_name FloorBlob
extends RefCounted
## Builds the coloured floor under a food patch: a solid core following
## the patch outline, ringed by a see-through rim that fades out past the
## edge, so meadows, plankton water and trenches melt into the sand and
## into each other instead of ending in a hard line. Materials are shared
## per food kind.

## Where the solid core stops and how far past the outline the rim fades,
## as fractions of the outline's distance from the centre.
const CORE := 0.85
const FADE := 1.3

static var _cores := {}
static var _rims := {}


static func build(patch: FoodPatch, y: float) -> MeshInstance3D:
	var mid := Vector3(patch.center.x, y, patch.center.y)
	var core := PackedVector3Array()
	var outer := PackedVector3Array()
	for p in patch.outline():
		var out := Vector3(p.x, y, p.y) - mid
		core.append(mid + out * CORE)
		outer.append(mid + out * FADE)
	var mesh := ArrayMesh.new()
	_add_core(mesh, mid, core)
	_add_rim(mesh, core, outer, patch.kind.floor_color)
	mesh.surface_set_material(0, _core_material(patch.kind))
	mesh.surface_set_material(1, _rim_material(patch.kind))
	var blob := MeshInstance3D.new()
	blob.mesh = mesh
	return blob


static func _add_core(mesh: ArrayMesh, mid: Vector3, edge: PackedVector3Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in edge.size():
		st.add_vertex(mid)
		st.add_vertex(edge[(i + 1) % edge.size()])
		st.add_vertex(edge[i])
	st.commit(mesh)


static func _add_rim(mesh: ArrayMesh, inner: PackedVector3Array,
		outer: PackedVector3Array, color: Color) -> void:
	var solid := Color(color, 1.0)
	var clear := Color(color, 0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in inner.size():
		var j := (i + 1) % inner.size()
		_corner(st, inner[i], solid)
		_corner(st, outer[j], clear)
		_corner(st, outer[i], clear)
		_corner(st, inner[i], solid)
		_corner(st, inner[j], solid)
		_corner(st, outer[j], clear)
	st.commit(mesh)


static func _corner(st: SurfaceTool, at: Vector3, color: Color) -> void:
	st.set_color(color)
	st.add_vertex(at)


static func _core_material(kind: FoodKind) -> StandardMaterial3D:
	if not _cores.has(kind.id):
		var mat := _base(kind)
		mat.albedo_color = kind.floor_color
		_cores[kind.id] = mat
	return _cores[kind.id]


static func _rim_material(kind: FoodKind) -> StandardMaterial3D:
	if not _rims.has(kind.id):
		var mat := _base(kind)
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# Drawn before other see-through things (cell shadows, streaks).
		mat.render_priority = -1
		_rims[kind.id] = mat
	return _rims[kind.id]


static func _base(kind: FoodKind) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if kind.floor_glow > 0.0:
		mat.emission_enabled = true
		mat.emission = kind.floor_color * kind.floor_glow
	return mat
