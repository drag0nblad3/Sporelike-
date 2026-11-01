class_name Genome
extends RefCounted
## Heritable traits of one organism. Each trait is stored as 0..1 so mutation
## stays simple; the getters turn them into gameplay numbers.

const TRAITS := ["size", "speed", "agility", "sense", "armor", "toxin", "diet", "jaw"]
const MUTATION_CHANCE := 0.4
const MUTATION_STEP := 0.08

## diet: 0 = eats plants well, 1 = eats animals well. jaw cracks shells.
var values := {
	"size": 0.3, "speed": 0.5, "agility": 0.3, "sense": 0.4,
	"armor": 0.1, "toxin": 0.0, "diet": 0.3, "jaw": 0.1,
}


## Average of each trait across several genomes (all zeros when empty).
static func average(genomes: Array[Genome]) -> Dictionary:
	var sums := {}
	for t in TRAITS:
		sums[t] = 0.0
	for g in genomes:
		for t in TRAITS:
			sums[t] += g.value_of(t)
	if not genomes.is_empty():
		for t in TRAITS:
			sums[t] /= genomes.size()
	return sums


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


func value_of(trait_name: String) -> float:
	return values.get(trait_name, 0.0)


func radius() -> float:
	return lerpf(0.35, 1.2, value_of("size"))


## Armor plates and a twitchy, agile body both cost top speed.
func max_speed() -> float:
	return lerpf(2.5, 8.0, value_of("speed")) * lerpf(1.0, 0.7, value_of("armor")) \
		* lerpf(1.0, 0.85, value_of("agility"))


## How hard the cell can push: high agility means quick starts and turns.
func acceleration() -> float:
	return max_speed() * lerpf(1.2, 4.5, value_of("agility"))


func turn_rate() -> float:
	return lerpf(4.0, 14.0, value_of("agility"))


func sense_range() -> float:
	return lerpf(3.0, 12.0, value_of("sense"))


## Chance (0..1) to survive a predator's bite.
func armor() -> float:
	return value_of("armor") * 0.6


## Chance (0..1) a biting predator is stung and lets go.
func toxin() -> float:
	return value_of("toxin") * 0.8


## Energy burned per second. Every advantage has a running cost.
func upkeep() -> float:
	return 0.25 + 0.35 * value_of("size") + 0.3 * value_of("speed") + 0.2 * value_of("agility") \
		+ 0.2 * value_of("sense") + 0.15 * value_of("armor") + 0.35 * value_of("toxin") \
		+ 0.2 * value_of("jaw")


## Whether the jaw is strong enough for food of this hardness.
func can_crack(hardness: float) -> bool:
	return value_of("jaw") >= hardness


## Energy gained from food worth `energy`, after digestive efficiency.
func digest(energy: float, is_plant: bool) -> float:
	var efficiency := lerpf(1.0, 0.3, value_of("diet")) if is_plant \
		else lerpf(0.3, 1.0, value_of("diet"))
	return energy * efficiency


## How far away food this visible (0..1) can be noticed.
func notice_range(visibility: float) -> float:
	return sense_range() * visibility


func color() -> Color:
	var hue: float = 0.5 + 0.12 * (value_of("speed") - value_of("armor"))
	var base := Color.from_hsv(hue, 0.55 + 0.3 * value_of("sense"), 1.0, 0.6)
	# Toxic cells shift toward a warning orange.
	return base.lerp(Color(1.0, 0.55, 0.1, 0.7), value_of("toxin"))
