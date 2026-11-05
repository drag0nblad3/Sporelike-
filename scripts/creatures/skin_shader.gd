class_name SkinShader
extends RefCounted
## The shader for a colony's shared skin and its shadow. The mesh is a
## flat web of rings; the vertex shader lifts it into a low dome over the
## outline ring (ColonyOutline) and gives it dome-shaped normals, so the
## sun lights one side and leaves a glossy highlight. The skin is nearly
## clear where you look straight through it and thick, glowing membrane at
## its edge, like a stage 1 cell. The shadow is the same outline lying
## flat on the sea floor, soft at its edge.

const CODE := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform vec3 ring[48];
uniform float height = 1.0;
uniform float base = -0.25;
uniform vec4 skin : source_color = vec4(0.5, 0.9, 0.8, 1.0);
uniform vec4 glow : source_color = vec4(0.3, 0.6, 0.55, 1.0);
uniform bool shadow = false;
varying float edge_t;
varying float sunlit;

void vertex() {
	int i = int(UV.x + 0.5);
	float t = UV.y;
	vec3 edge = vec3(ring[i].x, 0.0, ring[i].z);
	float r = max(length(edge), 0.001);
	float h = shadow ? 0.0 : height;
	float up = sqrt(max(1.0 - t * t, 0.0));
	VERTEX = vec3(edge.x * t, base + h * up, edge.z * t);
	// The normal of an ellipsoid r wide and h tall.
	vec3 n = vec3(edge.x / r * t / r, up / max(h, 0.001), edge.z / r * t / r);
	NORMAL = shadow ? vec3(0.0, 1.0, 0.0) : normalize(n);
	edge_t = t;
	// How squarely this bit of skin faces the sun (see Arena's light).
	sunlit = max(dot(NORMAL, normalize(vec3(0.25, 0.87, 0.43))), 0.0);
}

void fragment() {
	if (shadow) {
		ALBEDO = vec3(0.0);
		ALPHA = 0.4 * (1.0 - smoothstep(0.6, 1.0, edge_t));
	} else {
		float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0);
		float edge = smoothstep(0.82, 1.0, edge_t);
		// A glossy sheen where the dome faces the sun, shade on its far side.
		float sheen = pow(sunlit, 24.0);
		ALBEDO = skin.rgb * (0.55 + 0.45 * sunlit);
		ALPHA = clamp(0.2 + 0.5 * rim + 0.35 * edge + 0.4 * sheen, 0.0, 0.92);
		EMISSION = glow.rgb * (0.12 + 0.9 * rim + 0.6 * edge) + vec3(0.55) * sheen;
		ROUGHNESS = 0.22;
		SPECULAR = 0.8;
	}
}
"""

static var _shader: Shader


## A fresh material for one colony: its skin (or, with `as_shadow`, its
## shadow), drawn after (or before) everything else in the body.
static func material(tint: Color, as_shadow := false) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("skin", Color(tint, 1.0))
	mat.set_shader_parameter("glow", Color(tint.lightened(0.2), 1.0) * 0.6)
	mat.set_shader_parameter("shadow", as_shadow)
	mat.render_priority = -1 if as_shadow else 1
	return mat
