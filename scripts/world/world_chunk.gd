class_name WorldChunk
extends Node3D
## One loaded square of sea floor: its tinted ground, the soft floor blobs
## under its food patches, the currents that start here and any giant
## teaser of the next stage. The food itself lives in FoodField.

## Ground squares per chunk side; their corners carry the floor colour.
const GROUND_GRID := 6

var coord := Vector2i.ZERO
var patches: Array[FoodPatch] = []
var streams: Array[CurrentStream] = []
var teaser: Node3D


func setup(at: Vector2i, chunk_patches: Array[FoodPatch],
		chunk_streams: Array[CurrentStream], chunk_teaser: Node3D) -> void:
	coord = at
	patches = chunk_patches
	streams = chunk_streams
	teaser = chunk_teaser


func _ready() -> void:
	add_child(_ground())
	# Blobs overlap, also across chunk edges, so each gets its own clear
	# height step (neighbouring chunks start at different heights) to
	# keep them from flickering through each other.
	var y := -1.39 + 0.004 * posmod(coord.x + 2 * coord.y, 3)
	for patch in patches:
		y += 0.012
		if not patch.hidden:
			add_child(FloorBlob.build(patch, y))
	for stream in streams:
		add_child(CurrentView.new(stream))
	if teaser:
		add_child(teaser)


## The sand under the chunk, a grid whose corners take the blended colour
## of the seas around them (SeaBlend), so region borders fade softly and
## neighbouring chunks meet without a seam.
func _ground() -> MeshInstance3D:
	var size := ChunkGenerator.SIZE
	var step := size / GROUND_GRID
	var origin := Vector2(coord) * size
	var colors := PackedColorArray()
	for gy in GROUND_GRID + 1:
		for gx in GROUND_GRID + 1:
			colors.append(SeaBlend.floor_at(origin + Vector2(gx, gy) * step))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for gy in GROUND_GRID:
		for gx in GROUND_GRID:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
					Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var cx := gx + corner.x
				var cy := gy + corner.y
				st.set_color(colors[cy * (GROUND_GRID + 1) + cx])
				var p := origin + Vector2(cx, cy) * step
				st.add_vertex(Vector3(p.x, -1.4, p.y))
	var ground := MeshInstance3D.new()
	ground.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ground.material_override = mat
	return ground
