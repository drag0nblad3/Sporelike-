class_name GenerationStats
extends RefCounted
## What happened to the species during one generation: trait averages at the
## start and end, births, deaths by cause, and how well the player's avatar
## did (which sets how strongly the player's chosen mutation takes hold).

var number := 1
var ended_by := "time"
var start_averages := {}
var end_averages := {}
var start_population := 0
var end_population := 0
var births := 0
var deaths := {"eaten": 0, "starved": 0}
var food_eaten := 0


## 0.5x to 2x, growing with how much the player's avatar ate.
func influence() -> float:
	return clampf(0.5 + 0.1 * food_eaten, 0.5, 2.0)


func change(trait_name: String) -> float:
	var before: float = start_averages.get(trait_name, 0.0)
	var after: float = end_averages.get(trait_name, 0.0)
	return after - before
