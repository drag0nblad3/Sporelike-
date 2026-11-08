class_name LandTerrain
extends MeshInstance3D
## A square of stage 3 land shaped by LandHeight: sand in the hollows, moss
## and low green growth on the slopes and bare rock where it is steep or
## high. One lit mesh with vertex colours.

const SIZE := 160.0
const STEP := 2.0
const SAND := Color(0.8, 0.73, 0.53)
const MOSS := Color(0.33, 0.5, 0.24)
const GRASS := Color(0.5, 0.6, 0.3)
const ROCK := Color(0.47, 0.45, 0.41)


func _ready() -> void:
	mesh = _build()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat


func _build() -> ArrayMesh:
	var cells := int(SIZE / STEP)
	var half := SIZE * 0.5
	var row := cells + 1
	var heights := PackedFloat32Array()
	for gz in row:
		for gx in row:
			heights.append(LandHeight.at(-half + gx * STEP, -half + gz * STEP))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for gz in row:
		for gx in row:
			var x := -half + gx * STEP
			var z := -half + gz * STEP
			var y := heights[gz * row + gx]
			var left := heights[gz * row + maxi(gx - 1, 0)]
			var right := heights[gz * row + mini(gx + 1, cells)]
			var back := heights[maxi(gz - 1, 0) * row + gx]
			var front := heights[mini(gz + 1, cells) * row + gx]
			var up := Vector3(left - right, 2.0 * STEP, back - front).normalized()
			st.set_color(_color(y, up.y, x, z))
			st.set_normal(up)
			st.add_vertex(Vector3(x, y, z))
	for gz in cells:
		for gx in cells:
			var a := gz * row + gx
			for k: int in [a, a + 1, a + row + 1, a, a + row + 1, a + row]:
				st.add_index(k)
	return st.commit()


func _color(y: float, flat: float, x: float, z: float) -> Color:
	var speckle := sin(x * 1.7) * sin(z * 1.3) * 0.04
	var c := SAND.lerp(MOSS, smoothstep(-2.5, 0.5, y))
	c = c.lerp(GRASS, smoothstep(2.0, 4.0, y) * 0.6)
	c = c.lerp(ROCK, maxf(smoothstep(4.5, 7.0, y), smoothstep(0.86, 0.7, flat)))
	return c.lightened(speckle) if speckle > 0.0 else c.darkened(-speckle)
