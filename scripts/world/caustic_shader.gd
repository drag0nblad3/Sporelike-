class_name CausticShader
extends RefCounted
## Moving rings of sunlight focused by surface ripples onto the sea floor.
## FUNCTION is GLSL shared with SandShader; material() makes the glowing
## overlay that CausticLight lays over the floor.

## caustic(p, t): 0 to 1, bright wavy lines tiling every 20 units.
const FUNCTION := """
float caustic(vec2 world_xz, float t) {
	vec2 p = mod(world_xz * 0.05 * 6.28318, 6.28318) - 250.0;
	vec2 i = p;
	float c = 1.0;
	float inten = 0.005;
	for (int n = 0; n < 4; n++) {
		float tt = t * (1.0 - (3.5 / float(n + 1)));
		i = p + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
		c += 1.0 / length(vec2(p.x / (sin(i.x + tt) / inten), p.y / (cos(i.y + tt) / inten)));
	}
	c /= 4.0;
	c = 1.17 - pow(c, 1.4);
	return clamp(pow(abs(c), 8.0), 0.0, 1.0);
}
"""

const OVERLAY := """shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;
uniform float strength = 0.2;
uniform vec2 center = vec2(0.0);
uniform vec4 tint : source_color = vec4(0.75, 1.0, 0.9, 1.0);
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
%s
void fragment() {
	float fade = 1.0 - smoothstep(28.0, 44.0, distance(world.xz, center));
	ALBEDO = tint.rgb * caustic(world.xz, TIME * 0.5) * strength * fade;
}
"""

static var _shader: Shader


static func overlay() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = OVERLAY % FUNCTION
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	return mat
