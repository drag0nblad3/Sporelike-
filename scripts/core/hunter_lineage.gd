class_name HunterLineage
extends RefCounted
## The hunters as one slowly evolving species. Counts the prey they catch;
## after a generation where they went hungry they may gain a level of one
## of their own upgrades, which every hunter shares.

## Fewer catches than this per hunter in a generation counts as hungry.
const HUNGRY_BELOW := 1.0
## Chance a hungry generation brings an upgrade, so they evolve slowly.
const EVOLVE_CHANCE := 0.5
## id -> [label, effect per level, max level]
const UPGRADES := {
	"lunge": ["Lunge flagella", "+10% top speed", 3],
	"keen_nose": ["Chemosensors", "+20% sight", 3],
	"thick_hide": ["Thick membrane", "toxin stings 30% less often", 3],
	"wide_maw": ["Wide gullet", "swallows prey 8% bigger", 3],
}
const BASE_SWALLOW := 0.85

var levels := {}
## Prey caught this generation.
var meals := 0


func level(id: String) -> int:
	return int(levels.get(id, 0))


func speed_factor() -> float:
	return 1.0 + 0.1 * level("lunge")


func sight_factor() -> float:
	return 1.0 + 0.2 * level("keen_nose")


## Multiplies the chance a toxic prey stings.
func sting_factor() -> float:
	return 1.0 - 0.3 * level("thick_hide")


## Prey must be smaller than this share of the hunter's radius.
func swallow_ratio() -> float:
	return BASE_SWALLOW + 0.07 * level("wide_maw")


## Ends the generation for the hunters: maybe evolves, resets the meal
## count, and returns a line for the population screen.
func end_generation(hunters: int, rng: RandomNumberGenerator) -> String:
	var caught := meals
	meals = 0
	if caught >= hunters * HUNGRY_BELOW:
		return "Hunters ate well: %d prey caught" % caught
	var open: Array[String] = []
	for id in UPGRADES:
		var row: Array = UPGRADES[id]
		if level(id) < int(row[2]):
			open.append(id)
	if open.is_empty() or rng.randf() > EVOLVE_CHANCE:
		return "Hunters went hungry (%d prey caught)" % caught
	var pick := open[rng.randi() % open.size()]
	levels[pick] = level(pick) + 1
	var info: Array = UPGRADES[pick]
	return "Hungry hunters evolved %s (level %d): %s" % [info[0], level(pick), info[1]]
