class_name LandRiver
extends RefCounted
## The rivers of stage 3: winding lines where LandNoise.rivers crosses
## zero. Each cuts a channel down to a bed below its water surface,
## slicing canyons through mesas and crags it meets. The surface follows
## the broad hills, so rivers run gently down valleys.

## Noise distance from a river's middle where its banks top out.
const BANK := 0.06
## Where the channel floor is flat.
const BED := 0.022
const DEPTH := 1.3 * LandHeight.SCALE
## Shifts the river lines so none runs through the start.
const SHIFT := Vector2(30.0, 30.0) * LandHeight.SCALE


## 1 in the river, falling to 0 at the top of its banks.
static func wet(x: float, z: float) -> float:
	LandNoise.ensure()
	var r := absf(LandNoise.rivers.get_noise_2d(x + SHIFT.x, z + SHIFT.y))
	return 1.0 - smoothstep(BED, BANK, r)


## The height of the water surface (meaningful where wet() > 0).
static func surface(x: float, z: float) -> float:
	LandNoise.ensure()
	return LandNoise.hills.get_noise_2d(x, z) * LandHeight.HILLS * 0.35 - 0.6 * LandHeight.SCALE


## Cuts the river channel into ground height h.
static func carve(x: float, z: float, h: float) -> float:
	var w := wet(x, z)
	if w <= 0.0:
		return h
	var bed := surface(x, z) - DEPTH * (0.4 + 0.6 * w)
	return lerpf(h, minf(h, bed), smoothstep(0.0, 0.8, w))
