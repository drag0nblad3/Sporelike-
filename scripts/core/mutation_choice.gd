class_name MutationChoice
extends RefCounted
## A nudge to one trait that the player can encourage across the whole
## species between generations.

const STEP := 0.05
const LABELS := {
	"size": ["Bigger body", "Smaller body"],
	"speed": ["Longer tail", "Shorter tail"],
	"agility": ["More cilia", "Fewer cilia"],
	"sense": ["Sharper eye", "Duller eye"],
	"armor": ["Thicker armor", "Lighter armor"],
	"toxin": ["More toxic", "Less toxic"],
	"diet": ["Eat more meat", "Eat more plants"],
	"jaw": ["Stronger jaw", "Weaker jaw"],
}

var trait_name := ""
var direction := 1.0


func label() -> String:
	var pair: Array = LABELS[trait_name]
	return pair[0] if direction > 0.0 else pair[1]


func apply_to(genome: Genome, influence: float) -> void:
	var value: float = genome.values[trait_name]
	genome.values[trait_name] = clampf(value + STEP * influence * direction, 0.0, 1.0)


## A few different traits, each nudged up (usually) or down.
static func roll(rng: RandomNumberGenerator, count: int) -> Array[MutationChoice]:
	var names: Array = Genome.TRAITS.duplicate()
	names.shuffle()
	var picks: Array[MutationChoice] = []
	for i in mini(count, names.size()):
		var c := MutationChoice.new()
		c.trait_name = names[i]
		c.direction = 1.0 if rng.randf() < 0.7 else -1.0
		picks.append(c)
	return picks
