class_name GenerationStats
extends RefCounted
## What happened to the species during one generation: trait averages at the
## start and end, births, deaths by cause, and how well the player's avatar
## did (which sets how strongly the player's chosen mutation takes hold).

const MAX_BONUS_SETS := 3

var number := 1
var ended_by := "time"
var start_averages := {}
var end_averages := {}
var start_population := 0
var end_population := 0
var births := 0
var deaths := {"eaten": 0, "starved": 0}
var food_eaten := 0
## Energy the player's avatar digested this generation, and what its body
## burns in a full generation (its upkeep times the generation length).
var energy_gained := 0.0
var energy_needed := 1.0
## Filled in by Game: how close the species is to its next stage.
var progress_text := ""
## Filled in by Game when hard times made the species more efficient.
var adapt_text := ""
## Filled in by EvolutionRound: how the player's habits nudged the species.
var habit_text := ""
## Filled in by Game: how the hunters and the rival species fared.
var hunter_text := ""
var rival_text := ""


## Energy gathered compared to what the body costs to run: 1.0 = broke even.
## A costlier, more evolved body has to gather more for the same credit.
func fed_ratio() -> float:
	return energy_gained / maxf(energy_needed, 0.01)


## Extra sets of three picks: one for each doubling past break-even
## (2x, 4x, 8x the energy the body needs), at most MAX_BONUS_SETS.
func bonus_sets() -> int:
	var ratio := fed_ratio()
	if ratio < 2.0:
		return 0
	return mini(floori(log(ratio) / log(2.0)), MAX_BONUS_SETS)


## 0.5x to 2x, growing with how well the player's avatar fed itself.
func influence() -> float:
	return clampf(0.5 + 0.75 * fed_ratio(), 0.5, 2.0)


func change(trait_name: String) -> float:
	var before: float = start_averages.get(trait_name, 0.0)
	var after: float = end_averages.get(trait_name, 0.0)
	return after - before
