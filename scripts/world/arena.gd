class_name Arena
extends Node3D
## The ocean around everything: background colour, ambient light and the
## sun. They start in the colours of the run's starting Sea and blend
## toward the seas around the player (follow, SeaBlend), fading softly
## across region borders. The sea floor itself is
## drawn chunk by chunk by WorldChunk.

## How fast the colours blend into a new sea, per second.
const BLEND_RATE := 0.6
## The sea underfoot is looked up this often, not every frame.
const CHECK_INTERVAL := 0.5

var _env: Environment
var _sun: DirectionalLight3D
var _target: Sea
var _check := 0.0


func _ready() -> void:
	var sea := Sea.current()
	_target = sea
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = sea.water
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = sea.ambient
	_env.ambient_light_energy = 0.7
	_env.glow_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	add_child(world_env)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-60.0, 30.0, 0.0)
	_sun.light_color = sea.sun
	_sun.light_energy = sea.sun_energy
	add_child(_sun)


## Blends the water and light toward the sea at this point.
func follow(p: Vector2, delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_INTERVAL
		_target = SeaBlend.at(p)
	var t := clampf(BLEND_RATE * delta, 0.0, 1.0)
	_env.background_color = _env.background_color.lerp(_target.water, t)
	_env.ambient_light_color = _env.ambient_light_color.lerp(_target.ambient, t)
	_sun.light_color = _sun.light_color.lerp(_target.sun, t)
	_sun.light_energy = lerpf(_sun.light_energy, _target.sun_energy, t)
