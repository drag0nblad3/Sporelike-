class_name FloorShadow
extends MeshInstance3D
## A soft, round shadow on the sea floor under something that floats above
## it (a comb jelly, an algae raft). It follows its owner each frame,
## slides further from the sun and fades the higher the owner swims.
## ShadowLayer draws many of the same shadow at once.

## The sea floor is at y = -1.4; shadows lie just above it.
const FLOOR := -1.35
## Sideways shift per unit of height, away from the sun (Arena's light).
const SUN_SHIFT := Vector2(-0.29, -0.5)

const CODE := """shader_type spatial;
render_mode blend_mix, depth_draw_never, unshaded, cull_disabled;

uniform float strength = 0.35;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = vec3(0.0);
	ALPHA = strength * (1.0 - smoothstep(0.35, 1.0, d));
}
"""

static var _shader: Shader

var radius := 1.0


static func material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.render_priority = -1
	return mat


static func disc() -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	return plane


func _init(size := 1.0) -> void:
	radius = size
	mesh = disc()
	material_override = material()
	top_level = true


## Lies under `above`, a point in world space.
func follow(above: Vector3) -> void:
	var lift := maxf(above.y - FLOOR, 0.0)
	global_position = Vector3(above.x + SUN_SHIFT.x * lift, FLOOR, above.z + SUN_SHIFT.y * lift)
	# Higher things cast bigger, fainter shadows.
	scale = Vector3.ONE * radius * (1.0 + 0.06 * lift)
	(material_override as ShaderMaterial).set_shader_parameter("strength", 0.4 / (1.0 + 0.12 * lift))
