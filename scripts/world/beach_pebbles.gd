class_name BeachPebbles
extends MultiMeshInstance3D
## Pebbles and shells strewn over the shore's sand, from just under the
## low-tide line up the beach. ShoreLook scatters them again whenever it
## rebuilds its sand around the colony.

const COUNT := 160
const LOW := -6.0
const HIGH := 26.0
const COLORS := [Color(0.95, 0.92, 0.85), Color(0.92, 0.72, 0.66), Color(0.58, 0.57, 0.55),
	Color(0.36, 0.34, 0.31), Color(0.8, 0.78, 0.7)]


func _ready() -> void:
	var stone := SphereMesh.new()
	stone.radius = 0.2
	stone.height = 0.16
	stone.radial_segments = 8
	stone.rings = 4
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = stone
	multimesh.instance_count = COUNT
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Scatters them along `length` of `line` centred `center` along it.
func scatter(line: ShoreLine, center: float, length: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(roundi(center))
	for i in COUNT:
		var d := rng.randf_range(LOW, HIGH)
		var p := line.point(center + rng.randf_range(-0.5, 0.5) * length, d)
		var y := ShoreLook.FLOOR_Y + ShoreLine.rise(d) + 0.04
		var size := rng.randf_range(0.6, 1.7)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size, size * 1.4))
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(p.x, y, p.y)))
		var tint: Color = COLORS[rng.randi() % COLORS.size()]
		multimesh.set_instance_color(i, tint.darkened(rng.randf() * 0.15))
