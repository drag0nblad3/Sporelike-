class_name Arena
extends Node3D
## The ocean around everything: background colour, ambient light and the
## sun, in the colours of the run's Sea. The sea floor itself is drawn
## chunk by chunk by WorldChunk.


func _ready() -> void:
	var sea := Sea.current()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = sea.water
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = sea.ambient
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60.0, 30.0, 0.0)
	sun.light_color = sea.sun
	sun.light_energy = sea.sun_energy
	add_child(sun)
