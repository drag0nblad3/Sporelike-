class_name Arena
extends Node3D
## The patch of ocean: background, lighting, sea floor and glowing rim.

var radius := 30.0


func _init(arena_radius: float = 30.0) -> void:
	radius = arena_radius


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.07, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.55, 0.65)
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60.0, 30.0, 0.0)
	sun.light_color = Color(0.75, 0.9, 1.0)
	add_child(sun)

	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = radius
	floor_mesh.bottom_radius = radius
	floor_mesh.height = 0.2
	floor_mesh.radial_segments = 64
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.05, 0.2, 0.25)
	var ocean_floor := MeshInstance3D.new()
	ocean_floor.mesh = floor_mesh
	ocean_floor.material_override = floor_mat
	ocean_floor.position.y = -1.5
	add_child(ocean_floor)

	# Zones on the floor: sunlit shallows outside, deep water inside,
	# warm vents in the middle. FoodKind zones match these radii.
	_floor_disc(radius - 0.5, Color(0.12, 0.38, 0.4), 0.0, -1.38)
	_floor_disc(13.0, Color(0.03, 0.1, 0.16), 0.0, -1.37)
	_floor_disc(6.0, Color(0.45, 0.18, 0.08), 0.6, -1.36)

	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = radius - 0.25
	rim_mesh.outer_radius = radius + 0.25
	rim_mesh.rings = 64
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.2, 0.6, 0.7)
	rim_mat.emission_enabled = true
	rim_mat.emission = Color(0.1, 0.4, 0.5)
	var rim := MeshInstance3D.new()
	rim.mesh = rim_mesh
	rim.material_override = rim_mat
	rim.position.y = -1.3
	add_child(rim)


func _floor_disc(r: float, color: Color, glow: float, y: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = 0.02
	mesh.radial_segments = 64
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color * glow
	var disc := MeshInstance3D.new()
	disc.mesh = mesh
	disc.material_override = mat
	disc.position.y = y
	add_child(disc)
