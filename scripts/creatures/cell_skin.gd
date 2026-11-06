class_name CellSkin
extends RefCounted
## The membrane of a single cell (or a giant teaser colony's outer skin),
## drawn to match a stage 2 colony's skin (SkinShader): nearly clear where
## you look straight through it, thick and glowing at its edge, lit on the
## side facing the sun with a glossy sheen, and shaded on the far side.

const CODE := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

uniform vec4 tint : source_color = vec4(0.5, 0.9, 0.8, 0.6);
uniform float glow = 0.5;
varying float sunlit;

void vertex() {
	vec3 n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// The same sun direction as SkinShader (Arena's light).
	sunlit = max(dot(n, normalize(vec3(0.25, 0.87, 0.43))), 0.0);
}

void fragment() {
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
	float sheen = pow(sunlit, 24.0);
	ALBEDO = tint.rgb * (0.55 + 0.45 * sunlit);
	ALPHA = clamp(tint.a * 0.75 + 0.4 * rim + 0.35 * sheen, 0.0, 0.95);
	EMISSION = tint.rgb * glow * (0.35 + 1.1 * rim) + vec3(0.5) * sheen;
	ROUGHNESS = 0.25;
	SPECULAR = 0.7;
}
"""

static var _shader: Shader


static func material(tint: Color, glow := 0.5) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("glow", glow)
	return mat
