class_name WaterShader
extends RefCounted
## The look of stage 3 river water: blue-green, clearer at the shallow
## edges, with slow drifting ripples that catch the sun.

const CODE := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 deep : source_color = vec4(0.16, 0.38, 0.5, 1.0);
uniform vec4 shallow : source_color = vec4(0.4, 0.62, 0.62, 1.0);
varying vec3 world;
varying float wet;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wet = COLOR.a;
}
void fragment() {
	float t = TIME * 0.6;
	vec2 p = world.xz;
	float r = sin(p.x * 0.9 + t) * sin(p.y * 0.7 - t * 0.8);
	r += 0.5 * sin(p.x * 2.1 - p.y * 1.7 + t * 1.6);
	vec3 n = normalize(vec3(r * 0.12, 1.0, cos(p.y * 1.3 + t) * 0.08));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float edge = smoothstep(0.15, 0.6, wet);
	ALBEDO = mix(shallow.rgb, deep.rgb, edge);
	ROUGHNESS = 0.15;
	SPECULAR = 0.7;
	ALPHA = mix(0.45, 0.82, edge);
}
"""

static var _material: ShaderMaterial


static func material() -> ShaderMaterial:
	if _material == null:
		var shader := Shader.new()
		shader.code = CODE
		_material = ShaderMaterial.new()
		_material.shader = shader
	return _material
