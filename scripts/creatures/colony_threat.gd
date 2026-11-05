class_name ColonyThreat
extends RefCounted
## Hunters going after a colony. The nearest few hunters that can see it
## swim at its closest cell (Heliozoa only from close by, Stentors never
## leave their spot) and bite a cell off when they touch it. See
## ColonyWounds for what a bite does.

## At most this many hunters chase the colony at once.
const MAX_ATTACKERS := 2
## Heliozoa wait in ambush; they only lunge at colonies this close.
const AMBUSH_RANGE := 5.0
## A cell's radius, for touching.
const CELL_RADIUS := 0.5
## Seconds a hunter rests after tearing off a cell.
const FULL_COOLDOWN := 6.0


## Steers hunters and resolves their bites. Returns the outcome of a bite
## on the colony this frame, or "" when there was none.
## sight: share of each hunter's range it can see the colony from (less
## while it shelters against a rock).
static func hunt(eco: Ecosystem, colony: Colony, rng: RandomNumberGenerator,
		sight: float = 1.0) -> String:
	var center := Vector2(colony.center().x, colony.center().z)
	var reach := colony.reach()
	var near: Array = []
	for hunter in eco.predators:
		if not is_instance_valid(hunter) or not hunter.alive or hunter.dormant:
			continue
		if hunter.cooldown > 0.0 or hunter.stun_time > 0.0:
			continue
		var d := hunter.flat_pos().distance_to(center) - reach
		if d < hunter.sight_range() * sight:
			near.append([d, hunter])
	near.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var outcome := ""
	for k in mini(near.size(), MAX_ATTACKERS):
		var hunter: Predator = near[k][1]
		var at := hunter.flat_pos()
		var index := colony.nearest_cell(at)
		var cell := colony.cell_flat(index)
		var gap := at.distance_to(cell)
		if _chases(hunter, gap):
			hunter.lure = cell
		if gap <= hunter.radius() + CELL_RADIUS:
			outcome = _bite(hunter, colony, index, rng)
	return outcome


static func _chases(hunter: Predator, gap: float) -> bool:
	match hunter.kind:
		HunterKind.FILTER:
			return false
		HunterKind.AMBUSHER:
			return gap < AMBUSH_RANGE
	return true


static func _bite(hunter: Predator, colony: Colony, index: int,
		rng: RandomNumberGenerator) -> String:
	hunter.cooldown = Predator.BITE_COOLDOWN
	var outcome := colony.wounds.bite(colony, index, rng)
	match outcome:
		ColonyWounds.STUNG:
			hunter.stun_time = CellEffects.STING_STUN
			hunter.cooldown = Predator.STUNG_COOLDOWN
		ColonyWounds.BITTEN:
			hunter.cooldown = FULL_COOLDOWN
			hunter.lineage.meals += 1
	return outcome
