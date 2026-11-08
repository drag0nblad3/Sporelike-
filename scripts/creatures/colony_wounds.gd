class_name ColonyWounds
extends RefCounted
## Cells bitten off a colony, and how it heals. A bite can be blocked by
## plates (or by curling up), sting the biter if it lands near a stinging
## cell, or tear the cell off. Lost cells grow back one at a time, paid for
## from the colony's energy. Losing too many at once kills the colony.

## Outcomes of a bite.
const BLOCKED := "blocked"
const STUNG := "stung"
const BITTEN := "bitten"
## Seconds to regrow one cell, and the energy it costs.
const REGROW_TIME := 3.5
const REGROW_COST := 2.0
## Dies when this share of its full body has been bitten off.
const FATAL_SHARE := 0.5

var lost: Array[BodyPart] = []
var _timer := 0.0


## Seconds to regrow one cell, shorter with Stem cells.
static func regrow_time(plan: BodyPlan) -> float:
	return REGROW_TIME * TissueTrait.regrow_factor(plan)


## Resolves a bite on cell `index`. Biters must check STUNG themselves.
func bite(colony: Colony, index: int, rng: RandomNumberGenerator) -> String:
	if index < 0 or index >= colony.plan.parts.size():
		return BLOCKED
	if colony.curl_time > 0.0 or rng.randf() < CellEffects.block_chance(colony.plan, index):
		return BLOCKED
	if CellEffects.stings(colony.plan, index):
		return STUNG
	lost.append(colony.lose_cell(index))
	_timer = regrow_time(colony.plan)
	return BITTEN


func full_size(colony: Colony) -> int:
	return colony.plan.parts.size() + lost.size()


func is_fatal(colony: Colony) -> bool:
	return float(lost.size()) >= FATAL_SHARE * float(full_size(colony))


## Called every physics frame by the colony: regrows a cell when it can.
func tick(colony: Colony, delta: float) -> void:
	if lost.is_empty():
		return
	_timer -= delta
	if _timer > 0.0 or colony.energy < REGROW_COST:
		return
	_timer = regrow_time(colony.plan)
	var part: BodyPart = lost.pop_back()
	if colony.regain(part):
		colony.energy -= REGROW_COST
