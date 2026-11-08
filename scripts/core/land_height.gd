class_name LandHeight
extends RefCounted
## The shape of the land in stage 3, the same for everything that stands
## on it (the terrain mesh, walkers, rocks and plants): rolling hills,
## jagged crags and stepped mesa cliffs where LandZone says so, and river
## channels from LandRiver cut through all of it. Heights are in world
## units above sea level.

const HILLS := 7.0
const BUMPS := 0.9
## Crag peaks reach about this high above the hills.
const CRAGS := 18.0
## Height of each mesa tier's cliff.
const TIER := 6.5


static func at(x: float, z: float) -> float:
	LandNoise.ensure()
	var h := LandNoise.hills.get_noise_2d(x, z) * HILLS
	h += LandNoise.bumps.get_noise_2d(x, z) * BUMPS
	# A gentle, flatter spot where a walker starts.
	h *= clampf(Vector2(x, z).length() / 18.0, 0.25, 1.0)
	var c := LandZone.crag(x, z)
	if c > 0.0:
		h += c * _crag(x, z)
	var m := LandZone.mesa(x, z)
	if m > 0.0:
		h += m * _mesa(x, z)
	return LandRiver.carve(x, z, h)


## Points up out of the ground at (x, z).
static func normal(x: float, z: float) -> Vector3:
	var e := 0.5
	var dx := at(x + e, z) - at(x - e, z)
	var dz := at(x, z + e) - at(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


static func use_seed(value: int) -> void:
	LandNoise.make(value)


## Sharp ridge lines with spiky tops.
static func _crag(x: float, z: float) -> float:
	var ridge := 1.0 - absf(LandNoise.ridges.get_noise_2d(x, z))
	var spikes := absf(LandNoise.bumps.get_noise_2d(x * 2.3, z * 2.3))
	return pow(ridge, 3.0) * CRAGS * (0.75 + spikes * 0.6)


## Two flat-topped tiers, each rising in a sharp cliff.
static func _mesa(x: float, z: float) -> float:
	var n := LandNoise.tiers.get_noise_2d(x, z)
	return (smoothstep(-0.02, 0.03, n) + smoothstep(0.28, 0.33, n)) * TIER
