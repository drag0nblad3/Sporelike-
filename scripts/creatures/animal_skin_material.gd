class_name AnimalSkinMaterial
extends RefCounted
## The lit skin of a stage 3 animal's body, head and neck: its colour,
## optionally a darker back and a lighter belly (read from which way each
## spot faces), and a texture drawn over the mesh's UVs: scales, warts or
## fuzz. One shader shared by all; a ShaderMaterial per colour.

const TEXTURES := ["smooth", "scales", "warts", "fuzz"]

const CODE := """shader_type spatial;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 belly : source_color = vec4(1.0);
uniform float dark_back = 0.0;
uniform float light_belly = 0.0;
uniform int kind = 0;
uniform vec2 tile = vec2(10.0, 5.0);
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec3 to_linear(vec3 c) {
	return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
}
void fragment() {
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 c = tint.rgb * to_linear(COLOR.rgb);
	c = mix(c, belly.rgb, light_belly * smoothstep(0.05, -0.6, n.y));
	c *= 1.0 - dark_back * 0.45 * smoothstep(0.1, 0.9, n.y);
	vec2 p = UV * tile;
	if (kind == 1) {
		p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
		vec2 f = fract(p) - vec2(0.5, 0.0);
		float d = length(f * vec2(1.0, 1.3));
		c *= 0.7 + 0.3 * smoothstep(0.62, 0.38, d);
	} else if (kind == 2) {
		vec2 cell = floor(p * 1.4);
		vec2 f = fract(p * 1.4) - 0.5 + (vec2(hash(cell), hash(cell + 7.0)) - 0.5) * 0.4;
		float wart = step(0.45, hash(cell + 3.0)) * smoothstep(0.32, 0.18, length(f));
		c = mix(c, c * 0.62 + vec3(0.04), wart);
	} else if (kind == 3) {
		float strand = hash(floor(p * vec2(9.0, 3.0)));
		c *= 0.78 + 0.32 * strand;
	}
	ALBEDO = c;
	ROUGHNESS = kind == 3 ? 0.9 : 0.55;
}
"""

static var _shader: Shader


static func make(body: AnimalBody, color: Color) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("belly", body.color().lightened(0.5))
	mat.set_shader_parameter("dark_back", 1.0 if body.shading in ["dark back", "both"] else 0.0)
	mat.set_shader_parameter("light_belly", 0.85 if body.shading in ["light belly", "both"] else 0.0)
	mat.set_shader_parameter("kind", maxi(TEXTURES.find(body.texture), 0))
	return mat
