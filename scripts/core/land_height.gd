class_name LandHeight
extends RefCounted
## The shape of the land in stage 3: rolling hills with bumpy detail, the
## same for everything that stands on it (the terrain mesh, walkers, rocks
## and plants). Heights are in world units above sea level.

const HILLS := 7.0
const BUMPS := 0.9

static var _hills: FastNoiseLite
static var _bumps: FastNoiseLite


static func at(x: float, z: float) -> float:
	if _hills == null:
		_setup(1)
	var h := _hills.get_noise_2d(x, z) * HILLS + _bumps.get_noise_2d(x, z) * BUMPS
	# A gentle, flatter spot where a walker starts.
	var calm := clampf(Vector2(x, z).length() / 18.0, 0.25, 1.0)
	return h * calm


## Points up out of the ground at (x, z).
static func normal(x: float, z: float) -> Vector3:
	var e := 0.5
	var dx := at(x + e, z) - at(x - e, z)
	var dz := at(x, z + e) - at(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


static func use_seed(value: int) -> void:
	_setup(value)


static func _setup(value: int) -> void:
	_hills = FastNoiseLite.new()
	_hills.seed = value
	_hills.frequency = 0.012
	_hills.fractal_octaves = 3
	_bumps = FastNoiseLite.new()
	_bumps.seed = value + 1
	_bumps.frequency = 0.09
