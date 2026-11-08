class_name LandWater
extends MeshInstance3D
## The rivers of stage 3 as one see-through moving surface: a grid of
## quads laid only where LandRiver is wet, at its water height. The banks
## rise through it, so the water's edge follows the land. Drawn with
## WaterShader.

const STEP := 3.0
## Cells with no corner wetter than this are left out.
const DRY := 0.15


func _ready() -> void:
	mesh = _build()
	material_override = WaterShader.material()


func _build() -> ArrayMesh:
	var cells := int(LandTerrain.SIZE / STEP)
	var half := LandTerrain.SIZE * 0.5
	var row := cells + 1
	var wet := PackedFloat32Array()
	for gz in row:
		for gx in row:
			wet.append(LandRiver.wet(-half + gx * STEP, -half + gz * STEP))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var index := {}
	for gz in cells:
		for gx in cells:
			var a := gz * row + gx
			var quad: Array[int] = [a, a + 1, a + row + 1, a + row]
			var most := 0.0
			for k in quad:
				most = maxf(most, wet[k])
			if most < DRY:
				continue
			var ids: Array[int] = []
			for k in quad:
				if not index.has(k):
					index[k] = index.size()
					var x := -half + (k % row) * STEP
					var z := -half + (k / row) * STEP
					st.set_color(Color(1, 1, 1, wet[k]))
					st.set_normal(Vector3.UP)
					st.add_vertex(Vector3(x, LandRiver.surface(x, z), z))
				ids.append(index[k])
			for i: int in [0, 1, 2, 0, 2, 3]:
				st.add_index(ids[i])
	return st.commit()
