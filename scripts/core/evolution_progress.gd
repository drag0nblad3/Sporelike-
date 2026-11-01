class_name EvolutionProgress
extends RefCounted
## Tracks how close the species is to its next stage (single cell to
## multicellular). Thriving generations, a big population and a well-fed
## player earn points; reaching GOAL unlocks the next stage.

const GOAL := 100.0
const MAX_PER_GENERATION := 20.0

var points := 0.0


## Adds this generation's points and returns how many were earned.
func add_generation(stats: GenerationStats) -> float:
	var earned := 4.0 + 0.4 * stats.end_population + 0.5 * stats.food_eaten
	if stats.end_population == 0:
		earned = 0.0
	earned = minf(earned, MAX_PER_GENERATION)
	points = minf(points + earned, GOAL)
	return earned


func fraction() -> float:
	return points / GOAL


func is_ready() -> bool:
	return points >= GOAL


func summary(earned: float) -> String:
	if is_ready():
		return "Your species is ready to become multicellular (coming in a future update)"
	return "Multicellular progress %d%% (+%d this generation)" % [
		roundi(fraction() * 100.0), roundi(earned)]
