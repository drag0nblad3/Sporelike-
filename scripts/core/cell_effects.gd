class_name CellEffects
extends RefCounted
## What each kind of colony cell does in play, with its numbers: eyespots
## feel farther, plates block bites, stinging cells stun biters, storage
## cells hold more energy, all raised by TissueTrait upgrades. Also the
## body's energy use and mouth reach, and the numbers line on each cell pick.

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


static func eye_reach(plan: BodyPlan) -> float:
	return EYE_REACH + TissueTrait.LENS_REACH * TissueTrait.level(plan, "lens")


static func sense_reach(plan: BodyPlan) -> float:
	return eye_reach(plan) * plan.count("eye")


static func storage_energy(plan: BodyPlan) -> float:
	return STORAGE_ENERGY + TissueTrait.OIL_ENERGY * TissueTrait.level(plan, "oil")


static func max_energy(plan: BodyPlan) -> float:
	return (ENERGY_PER_CELL * plan.parts.size() + storage_energy(plan) * plan.count("storage")) \
		* TissueTrait.store_factor(plan)


static func per_gut(plan: BodyPlan) -> float:
	return DIGEST_PER_GUT + TissueTrait.FOLD_DIGEST * TissueTrait.level(plan, "folds")


static func digest_share(plan: BodyPlan) -> float:
	return minf(DIGEST_BASE + per_gut(plan) * plan.count("gut"), 1.0)


## Energy the body burns per second.
static func upkeep(plan: BodyPlan) -> float:
	return (Colony.UPKEEP_PER_CELL * plan.parts.size() * TissueTrait.upkeep_factor(plan)
		+ TissueTrait.extra_upkeep(plan)) * FinalBody.upkeep_factor(plan.final_body)


## How far past a mouth cell food is pulled in, in world units.
static func mouth_reach(plan: BodyPlan) -> float:
	return FeedingStyle.mouth_reach(plan.style) \
		+ TissueTrait.LIP_REACH * TissueTrait.level(plan, "lips")


## Seconds a stinging cell stuns whatever bit near it.
static func sting_stun(plan: BodyPlan) -> float:
	return STING_STUN + TissueTrait.VENOM_STUN * TissueTrait.level(plan, "venom")


## Chance of blocking a bite on a plate cell, or beside one.
static func plate_block(plan: BodyPlan, near: bool) -> float:
	var plates := TissueTrait.level(plan, "plates")
	if near:
		return NEAR_PLATE_BLOCK + TissueTrait.NEAR_PLATE_BLOCK * plates
	return PLATE_BLOCK + TissueTrait.PLATE_BLOCK * plates


## Chance a bite on cell `index` is turned away by plates.
static func block_chance(plan: BodyPlan, index: int) -> float:
	var hit := plan.parts[index]
	if hit.role == "plate":
		return plate_block(plan, false)
	for part in plan.parts:
		if part.role == "plate" and part.offset.distance_to(hit.offset) <= BodyPlan.SPACING * 1.05:
			return plate_block(plan, true)
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
				(sense_reach(before) + eye_reach(before) * added) * um, sense_reach(before) * um]
		"plate":
			return "Blocks %d%% of bites on itself and %d%% beside it" % [
				plate_block(before, false) * 100.0, plate_block(before, true) * 100.0]
		"gland":
			return "Stuns anything biting within %d µm for %.1f s" % [
				STING_RANGE * BodyPlan.SPACING * um, sting_stun(before)]
		"storage":
			return "Holds %d more energy" % [
				(ENERGY_PER_CELL + storage_energy(before)) * added * TissueTrait.store_factor(before)]
		"gut":
			var now := digest_share(before)
			var after := minf(now + per_gut(before) * added, 1.0)
			return "Keeps %d%% of every meal (now %d%%)" % [after * 100.0, now * 100.0]
		"flagellum":
			return "Each whip pushes %.1fx as hard as a skin cell's cilia" % [
				ColonySwim.cell_push(before, "flagellum") / ColonySwim.cell_push(before, "skin")]
		"mouth":
			return "Each takes in food it touches"
	return "Cilia help the body swim"
