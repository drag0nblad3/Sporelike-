class_name Genome
extends RefCounted
## Heritable traits of one organism. Each trait is stored as 0..1 so mutation
## stays simple; the getters turn them into gameplay numbers.

const TRAITS := ["size", "speed", "sense", "armor"]
const MUTATION_CHANCE := 0.5
const MUTATION_STEP := 0.08

var values := {"size": 0.3, "speed": 0.5, "sense": 0.4, "armor": 0.1}


func copy() -> Genome:
	var g := Genome.new()
	g.values = values.duplicate()
	return g


## A child genome: each trait has a chance to drift a little up or down.
func mutated(rng: RandomNumberGenerator) -> Genome:
	var child := copy()
	for t in TRAITS:
		if rng.randf() < MUTATION_CHANCE:
			child.values[t] = clampf(child.values[t] + rng.randfn(0.0, MUTATION_STEP), 0.0, 1.0)
	return child


func radius() -> float:
	return lerpf(0.35, 1.2, values["size"])


## Armor plates slow the cell down.
func max_speed() -> float:
	return lerpf(2.5, 8.0, values["speed"]) * lerpf(1.0, 0.7, values["armor"])


func sense_range() -> float:
	return lerpf(3.0, 12.0, values["sense"])


## Chance (0..1) to survive a predator's bite.
func armor() -> float:
	return values["armor"] * 0.6


## Energy burned per second. Every advantage has a running cost.
func upkeep() -> float:
	return 0.25 + 0.35 * values["size"] + 0.35 * values["speed"] \
		+ 0.2 * values["sense"] + 0.2 * values["armor"]


func color() -> Color:
	var hue: float = 0.5 + 0.12 * (values["speed"] - values["armor"])
	return Color.from_hsv(hue, 0.55 + 0.3 * values["sense"], 1.0, 0.6)
