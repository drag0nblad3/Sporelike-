class_name CellEffects
extends RefCounted
## What each kind of colony cell does in play, with its numbers: eyespots
## feel farther, plates block bites, stinging cells stun biters, storage
## cells hold more energy. Also writes the numbers line on each cell pick.

## World units past the screen edge each eyespot cell lets the colony feel.
const EYE_REACH := 3.0
## Energy every cell can hold, and the extra a storage cell holds.
const ENERGY_PER_CELL := 2.0
const STORAGE_ENERGY := 6.0
## Chance a bite is blocked when it lands on a plate cell, or right beside one.
const PLATE_BLOCK := 0.8
const NEAR_PLATE_BLOCK := 0.4
## A bite within this many cell widths of a stinging cell stings the biter.
const STING_RANGE := 1.2
const STING_STUN := 4.0
## Share of a meal the gut keeps: a base, plus this per digestive cell.
const DIGEST_BASE := 0.55
const DIGEST_PER_GUT := 0.06


static func sense_reach(plan: BodyPlan) -> float:
	return EYE_REACH * plan.count("eye")


static func max_energy(plan: BodyPlan) -> float:
	return ENERGY_PER_CELL * plan.parts.size() + STORAGE_ENERGY * plan.count("storage")


static func digest_share(plan: BodyPlan) -> float:
	return minf(DIGEST_BASE + DIGEST_PER_GUT * plan.count("gut"), 1.0)


## Chance a bite on cell `index` is turned away by plates.
static func block_chance(plan: BodyPlan, index: int) -> float:
	var hit := plan.parts[index]
	if hit.role == "plate":
		return PLATE_BLOCK
	for part in plan.parts:
		if part.role == "plate" and part.offset.distance_to(hit.offset) <= BodyPlan.SPACING * 1.05:
			return NEAR_PLATE_BLOCK
	return 0.0


## Whether a bite on cell `index` lands within reach of a stinging cell.
static func stings(plan: BodyPlan, index: int) -> bool:
	var hit := plan.parts[index]
	for part in plan.parts:
		if part.role == "gland" and part.offset.distance_to(hit.offset) <= BodyPlan.SPACING * STING_RANGE:
			return true
	return false


## The numbers line on a cell pick card for `added` cells of `role`.
static func card_line(role: String, before: BodyPlan, added: int) -> String:
	var um := StatSheet.MICRONS
	match role:
		"eye":
			return "Feel food and hunters %d µm past the screen edge (now %d µm)" % [
				(sense_reach(before) + EYE_REACH * added) * um, sense_reach(before) * um]
		"plate":
			return "Blocks %d%% of bites on itself and %d%% beside it" % [
				PLATE_BLOCK * 100.0, NEAR_PLATE_BLOCK * 100.0]
		"gland":
			return "Stuns anything biting within %d µm for %d s" % [
				STING_RANGE * BodyPlan.SPACING * um, STING_STUN]
		"storage":
			return "Holds %d more energy" % [(ENERGY_PER_CELL + STORAGE_ENERGY) * added]
		"gut":
			var now := digest_share(before)
			var after := minf(now + DIGEST_PER_GUT * added, 1.0)
			return "Keeps %d%% of every meal (now %d%%)" % [after * 100.0, now * 100.0]
		"flagellum":
			return "Each whip pushes 3x as hard as a skin cell's cilia"
		"mouth":
			return "Each takes in food it touches"
	return "Cilia help the body swim"
