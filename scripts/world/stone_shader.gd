class_name StoneShader
extends RefCounted
## Solid rock built the same way as a colony's skin: SkinShader's dome over
## an outline ring (ColonyOutline), but opaque, rough and unlit by any glow,
## so a rock outcrop reads as one lumpy stone rising from the sea floor
## instead of a pile of balls.

const FRAGMENT := """void fragment() {
	// Darker toward the floor, where the stone meets it.
	ALBEDO = skin.rgb * (0.55 + 0.45 * sunlit) * (0.65 + 0.35 * (1.0 - edge_t));
	EMISSION = glow.rgb * 0.3;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
"""

static var _shader: Shader


static func material(tint: Color, glow := Color.BLACK) -> ShaderMaterial:
	if _shader == null:
		var head := SkinShader.CODE.get_slice("void fragment", 0)
		head = head.replace("render_mode blend_mix, depth_draw_never, cull_disabled;",
				"render_mode cull_disabled;")
		_shader = Shader.new()
		_shader.code = head + FRAGMENT
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("skin", Color(tint, 1.0))
	mat.set_shader_parameter("glow", glow)
	return mat
