class_name CellEngulf
extends RefCounted
## Lets the player swallow rival cells much smaller than itself (radius
## under SIZE_RATIO of the player's). The rival dies and its body is
## digested as prey food. Small rivals that see the player flee.

const SIZE_RATIO := 0.55
## Energy every swallowed cell is worth, plus this share of what it stored.
const BASE := 1.5
const KEEP := 0.6
## How far away a small rival notices the player, beyond the player's size.
const FEAR_RANGE := 4.0


## The first time a rival small enough to eat is close, the player is told.
static func any_edible_near(eco: Ecosystem) -> bool:
	if not eco.rivals:
		return false
	for rival in eco.rivals.members():
		if rival.alive and not rival.dormant and fears_player(rival, eco):
			return true
	return false


static func can_swallow(eater: Organism, prey: Organism) -> bool:
	return prey.radius() < eater.radius() * SIZE_RATIO


## Swallows the first small rival the player touches. Returns the energy
## gained (0 if none).
static func check(eco: Ecosystem) -> float:
	var me := eco.player
	if not is_instance_valid(me) or not me.alive or me.stun_time > 0.0 or not eco.rivals:
		return 0.0
	var at := me.flat_pos()
	for rival in eco.rivals.members():
		if not rival.alive or rival.dormant or not can_swallow(me, rival):
			continue
		var reach := me.radius() + rival.radius() * 0.5
		if at.distance_squared_to(rival.flat_pos()) > reach * reach:
			continue
		var gained := me.genome.digest(BASE + KEEP * maxf(rival.energy, 0.0), false)
		rival.die("eaten")
		me.eat(gained)
		return gained
	return 0.0


## True when this rival cell is small enough to be eaten and the player is
## close, so it should swim away.
static func fears_player(cell: Organism, eco: Ecosystem) -> bool:
	if not (cell is RivalCell) or not is_instance_valid(eco.player) or not eco.player.alive:
		return false
	var near := eco.player.radius() + FEAR_RANGE
	if cell.flat_pos().distance_squared_to(eco.player.flat_pos()) > near * near:
		return false
	return can_swallow(eco.player, cell)
