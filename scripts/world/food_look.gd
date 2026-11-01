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


static func material_for(kind: FoodKind) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = kind.color
	mat.emission_enabled = true
	mat.emission = Color(kind.color.r, kind.color.g, kind.color.b)
	# Faint kinds glow faintly and are see-through.
	mat.emission_energy_multiplier = lerpf(0.3, 1.5, kind.visibility)
	if kind.color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
