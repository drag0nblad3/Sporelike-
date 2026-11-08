class_name LandTerrain
extends MeshInstance3D
## A square of stage 3 land shaped by LandHeight: sand in the hollows and
## river beds, moss and low green growth on the slopes, dark leaf litter
## under forests and banded bare rock on cliffs, crags and peaks. One lit
## mesh with vertex colours; LandWater adds the rivers on top.

const SIZE := 240.0
const STEP := 1.5
const SAND := Color(0.8, 0.73, 0.53)
const MOSS := Color(0.33, 0.5, 0.24)
const GRASS := Color(0.5, 0.6, 0.3)
const ROCK := Color(0.47, 0.45, 0.41)
const LITTER := Color(0.24, 0.3, 0.16)
const MUD := Color(0.42, 0.36, 0.26)


func _ready() -> void:
	mesh = _build()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat
	add_child(LandWater.new())


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
	c = c.lerp(LITTER, LandZone.forest(x, z) * 0.85)
	c = c.lerp(MUD, smoothstep(0.3, 0.7, LandRiver.wet(x, z)))
	var bare := maxf(smoothstep(9.0, 14.0, y), smoothstep(0.82, 0.62, flat))
	# Layered bands across cliff faces.
	var rock := ROCK.darkened(0.12 * (0.5 + 0.5 * sin(y * 2.4 + sin(x * 0.2) * 0.8)))
	c = c.lerp(rock, bare)
	return c.lightened(speckle) if speckle > 0.0 else c.darkened(-speckle)
