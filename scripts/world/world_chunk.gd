class_name WorldChunk
extends Node3D
## One loaded square of sea floor: its tinted ground tile and the floor
## blobs under its food patches. The food itself lives in FoodField.

const BASE_COLOR := Color(0.05, 0.2, 0.25)

var coord := Vector2i.ZERO
var patches: Array[FoodPatch] = []


func setup(at: Vector2i, chunk_patches: Array[FoodPatch]) -> void:
	coord = at
	patches = chunk_patches


func _ready() -> void:
	var size := ChunkGenerator.SIZE
	var tile := PlaneMesh.new()
	tile.size = Vector2(size, size)
	var ground := MeshInstance3D.new()
	ground.mesh = tile
	ground.material_override = _material(BASE_COLOR, 0.0)
	ground.position = Vector3((coord.x + 0.5) * size, -1.4, (coord.y + 0.5) * size)
	add_child(ground)
	var y := -1.39
	for patch in patches:
		y += 0.001
		_disc(patch, y)


## A flat blob following the patch's outline, as a triangle fan.
func _disc(patch: FoodPatch, y: float) -> void:
	var edge := patch.outline()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in edge.size():
		var a := edge[i]
		var b := edge[(i + 1) % edge.size()]
		st.add_vertex(Vector3(patch.center.x, y, patch.center.y))
		st.add_vertex(Vector3(b.x, y, b.y))
		st.add_vertex(Vector3(a.x, y, a.y))
	var blob := MeshInstance3D.new()
	blob.mesh = st.commit()
	blob.material_override = _material(patch.kind.floor_color, patch.kind.floor_glow)
	add_child(blob)


static func _material(color: Color, glow: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color * glow
	return mat
