class_name PartMaterial
extends RefCounted
## The one material every merged cell mesh (PartBaker) shares: colour and
## glow come per vertex, lit like VisualParts.material. Also decides which
## part materials it can stand in for.

const SHADER := """shader_type spatial;
varying vec3 glow;

vec3 to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)),
		c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

void vertex() {
	glow = COLOR.rgb * UV2.x;
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = to_linear(COLOR.rgb);
		glow = to_linear(glow);
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = glow;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
"""

static var _material: ShaderMaterial


## Whether the material is a plain opaque one that the shared shader can
## reproduce from a vertex colour and a glow amount.
static func paintable(mat: StandardMaterial3D) -> bool:
	if mat == null or mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return false
	if mat.albedo_color.a < 1.0 or mat.albedo_texture or mat.vertex_color_use_as_albedo:
		return false
	if mat.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
			or mat.cull_mode != BaseMaterial3D.CULL_BACK:
		return false
	if mat.roughness != 1.0 or mat.metallic != 0.0 or mat.metallic_specular != 0.5:
		return false
	return glow(mat) >= 0.0


## How much the part glows as a multiple of its colour (VisualParts.material
## sets emission = colour * glow), or -1 if its emission is anything else.
static func glow(mat: StandardMaterial3D) -> float:
	if not mat.emission_enabled:
		return 0.0
	if mat.emission_texture or mat.emission_operator != BaseMaterial3D.EMISSION_OP_ADD:
		return -1.0
	var c := mat.albedo_color
	var e := mat.emission
	var top := maxf(c.r, maxf(c.g, c.b))
	if top <= 0.0:
		return 0.0 if maxf(e.r, maxf(e.g, e.b)) <= 0.0 else -1.0
	var g := maxf(e.r, maxf(e.g, e.b)) / top
	if absf(c.r * g - e.r) + absf(c.g * g - e.g) + absf(c.b * g - e.b) > 0.01:
		return -1.0
	return g * mat.emission_energy_multiplier


static func shared() -> ShaderMaterial:
	if _material == null:
		var shader := Shader.new()
		shader.code = SHADER
		_material = ShaderMaterial.new()
		_material.shader = shader
	return _material
