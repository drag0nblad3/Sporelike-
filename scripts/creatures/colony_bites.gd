class_name ColonyBites
extends RefCounted
## One colony biting another: a mouth cell or tentacle tip that touches a
## cell of a smaller colony tears it off and eats it (see ColonyWounds for
## plates and stingers). A colony can bite one that has at most its
## FeedingStyle's bite ratio of its own cells.

## Energy in one bitten-off cell, before digestion.
const CELL_MEAL := 4.0
## Seconds between one colony's bites.
const BITE_COOLDOWN := 1.5
## How close a mouth must come to a cell's centre.
const BITE_REACH := 0.8


static func can_bite(eater: Colony, target: Colony) -> bool:
	return target.plan.parts.size() \
		<= eater.plan.parts.size() * FeedingStyle.bite_ratio(eater.plan.style)


## Tries one bite of `eater` on `target`. Returns [outcome, energy eaten];
## the outcome is "" when no mouth touched.
static func attempt(eater: Colony, target: Colony, rng: RandomNumberGenerator) -> Array:
	if not eater.abilities.ready("bite") or eater.stun_time > 0.0 or not can_bite(eater, target) \
			or not Depth.level(eater.height, target.height):
		return ["", 0.0]
	for point in eater.eat_points():
		var at := Vector2(point.x, point.z)
		var index := target.nearest_cell(at)
		if at.distance_to(target.cell_flat(index)) > BITE_REACH:
			continue
		eater.abilities.start("bite", BITE_COOLDOWN)
		var outcome := target.wounds.bite(target, index, rng)
		if outcome == ColonyWounds.STUNG:
			eater.stun_time = CellEffects.sting_stun(target.plan)
		elif outcome == ColonyWounds.BITTEN:
			return [outcome, CELL_MEAL]
		return [outcome, 0.0]
	return ["", 0.0]
