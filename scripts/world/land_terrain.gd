class_name LandTerrain
extends Node3D
## A square of stage 3 land shaped by LandHeight: sand in the hollows and
## river beds, moss and low green growth on the slopes, dark leaf litter
## under forests and banded bare rock on cliffs, crags and peaks. Lit
## meshes with vertex colours; LandWater adds the rivers on top.

const SIZE := 240.0
const STEP := 1.5
const SAND := Color(0.8, 0.73, 0.53)
const MOSS := Color(0.33, 0.5, 0.24)
const GRASS := Color(0.5, 0.6, 0.3)
const ROCK := Color(0.47, 0.45, 0.41)
const LITTER := Color(0.24, 0.3, 0.16)
const MUD := Color(0.42, 0.36, 0.26)
## The square is cut into CHUNKS x CHUNKS meshes so the parts behind the
## camera are skipped.
const CHUNKS := 4


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cells := int(SIZE / STEP)
	var row := cells + 1
	var half := SIZE * 0.5
	var heights := PackedFloat32Array()
	for gz in row:
		for gx in row:
			heights.append(LandHeight.at(-half + gx * STEP, -half + gz * STEP))
	var span := cells / CHUNKS
	for cz in CHUNKS:
		for cx in CHUNKS:
			var part := MeshInstance3D.new()
			part.mesh = _chunk(heights, cells, cx * span, cz * span, span)
			part.material_override = mat
			add_child(part)
	add_child(LandWater.new())


## One mesh covering span x span cells from grid corner (x0, z0).
func _chunk(heights: PackedFloat32Array, cells: int, x0: int, z0: int, span: int) -> ArrayMesh:
	var half := SIZE * 0.5
	var row := cells + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for gz in range(z0, z0 + span + 1):
		for gx in range(x0, x0 + span + 1):
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
	var w := span + 1
	for gz in span:
		for gx in span:
			var a := gz * w + gx
			for k: int in [a, a + 1, a + w + 1, a, a + w + 1, a + w]:
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
