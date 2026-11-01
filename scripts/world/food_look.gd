class_name FoodLook
extends RefCounted
## Meshes and materials for each FoodKind, so kinds read apart at a glance.


static func mesh_for(kind: FoodKind) -> Mesh:
	match kind.id:
		"plankton":
			var capsule := CapsuleMesh.new()
			capsule.radius = kind.size * 0.6
			capsule.height = kind.size * 3.0
			return capsule
		"shells":
			var disc := CylinderMesh.new()
			disc.top_radius = kind.size * 0.7
			disc.bottom_radius = kind.size
			disc.height = kind.size * 0.8
			return disc
		_:
			var sphere := SphereMesh.new()
			sphere.radius = kind.size
			sphere.height = kind.size * 2.0
			sphere.radial_segments = 12
			sphere.rings = 6
			return sphere


## Tier 0 is the easy, bright version; higher tiers are deeper and duller,
## so tougher, richer pieces read as different at a glance. Food in hidden
## patches is a dim ghost of itself.
static func material_for(kind: FoodKind, tier: int, faint: bool) -> StandardMaterial3D:
	var tint := kind.color.darkened(0.22 * tier)
	tint.a = kind.color.a * (0.3 if faint else 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = Color(tint.r, tint.g, tint.b)
	# Faint kinds glow faintly and are see-through.
	mat.emission_energy_multiplier = lerpf(0.3, 1.5, kind.visibility) * (0.2 if faint else 1.0)
	if tint.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
