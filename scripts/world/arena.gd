class_name Arena
extends Node3D
## The patch of ocean: background, lighting, sea floor with each food
## patch from the BiomeMap drawn on it, and a glowing rim.

var radius := 55.0
var map: BiomeMap


func _init(biome_map: BiomeMap) -> void:
	map = biome_map
	radius = biome_map.radius


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
	floor_mesh.radial_segments = 96
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.05, 0.2, 0.25)
	var ocean_floor := MeshInstance3D.new()
	ocean_floor.mesh = floor_mesh
	ocean_floor.material_override = floor_mat
	ocean_floor.position.y = -1.5
	add_child(ocean_floor)

	# Each food patch tints the floor beneath it: meadows, open water,
	# warm vents, dark trenches.
	var looks := {}
	for kind in FoodKind.all():
		looks[kind.id] = kind
	var y := -1.39
	for patch in map.patches:
		var kind: FoodKind = looks[patch.kind_id]
		y += 0.001
		_floor_disc(patch.center, patch.radius, kind.floor_color, kind.floor_glow, y)

	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = radius - 0.25
	rim_mesh.outer_radius = radius + 0.25
	rim_mesh.rings = 96
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.2, 0.6, 0.7)
	rim_mat.emission_enabled = true
	rim_mat.emission = Color(0.1, 0.4, 0.5)
	var rim := MeshInstance3D.new()
	rim.mesh = rim_mesh
	rim.material_override = rim_mat
	rim.position.y = -1.3
	add_child(rim)


func _floor_disc(at: Vector2, r: float, color: Color, glow: float, y: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = 0.02
	mesh.radial_segments = 32
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color * glow
	var disc := MeshInstance3D.new()
	disc.mesh = mesh
	disc.material_override = mat
	disc.position = Vector3(at.x, y, at.y)
	add_child(disc)
