class_name Arena
extends Node3D
## The ocean around everything: background colour, ambient light and the
## sun. The sea floor itself is drawn chunk by chunk by WorldChunk.


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
