class_name SandShader
extends RefCounted
## The shore's sand (ShoreLook): its own vertex colours, unlit, with ripple
## marks, sunlight caustics where the water covers it and a darker wet band
## just above the waterline that the tide has just left.

const CODE := """shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec2 origin = vec2(0.0);
uniform vec2 inland = vec2(0.0, -1.0);
uniform float water = 0.0;
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
%s
vec3 to_linear(vec3 c) {
	return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
}
void fragment() {
	vec2 rel = world.xz - origin;
	float d = dot(rel, inland);
	float s = dot(rel, vec2(-inland.y, inland.x));
	float under = 1.0 - smoothstep(water - 0.4, water + 0.4, d);
	float ripple = 0.5 + 0.5 * sin(d * 2.4 + sin(s * 0.3) * 1.8);
	float damp = smoothstep(water + 2.5, water, d) * (1.0 - under);
	vec3 c = to_linear(COLOR.rgb);
	c *= 0.9 + 0.12 * ripple;
	c *= 1.0 - 0.22 * damp;
	c += vec3(0.75, 1.0, 0.9) * caustic(world.xz, TIME * 0.5) * 0.35 * under;
	ALBEDO = c;
}
"""

static var _shader: Shader


static func material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE % CausticShader.FUNCTION
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	return mat
