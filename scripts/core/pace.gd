class_name Pace
extends RefCounted
## Keeps speed from running away: as the player's species gets faster, the
## rest of the sea (hunters and darting food) slows very slightly. Genome
## also gives each step of speed a little less than the one before.

## How much slower everything else is at species speed 1.0.
const OTHERS_SLOWDOWN := 0.12


## Speed multiplier for hunters and food, given the species' average speed.
static func others(species_speed: float) -> float:
	return 1.0 - OTHERS_SLOWDOWN * clampf(species_speed, 0.0, 1.0)
