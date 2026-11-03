class_name EvolutionProgress
extends RefCounted
## Tracks how close the species is to its next stage (single cell to
## multicellular). Thriving generations, a big population and a player who
## gathered plenty of energy for its body's cost earn points; reaching GOAL
## unlocks the next stage.

## Points needed to finish the single-cell stage: about 25 to 30 good
## generations.
const GOAL := 300.0
const MAX_PER_GENERATION := 15.0
## How much scarcer food is by the end of the stage: patches regrow this
## much less food, this much more slowly.
const LATE_SCARCITY := 0.35

var points := 0.0


## Adds this generation's points and returns how many were earned.
func add_generation(stats: GenerationStats) -> float:
	var earned := 4.0 + 0.15 * stats.end_population + 5.0 * stats.fed_ratio()
	if stats.end_population == 0:
		earned = 0.0
	earned = minf(earned, MAX_PER_GENERATION)
	points = minf(points + earned, GOAL)
	return earned


func fraction() -> float:
	return points / GOAL


## 1 at the start of the stage, falling to 1 - LATE_SCARCITY at its end
## (see FoodField.abundance), so competition for food grows.
func food_abundance() -> float:
	return 1.0 - LATE_SCARCITY * fraction()


func is_ready() -> bool:
	return points >= GOAL


func summary(earned: float) -> String:
	if is_ready():
		return "Your species is ready to become multicellular: choose its body plan next"
	return "Multicellular progress %d%% (+%d this generation)" % [
		roundi(fraction() * 100.0), roundi(earned)]
