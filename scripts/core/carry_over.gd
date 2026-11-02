class_name CarryOver
extends RefCounted
## What a single-celled species brings into the multicellular stage: its
## strongest traits become its first specialised cells (a fast species
## starts with a flagellum, a sharp-eyed one with eyespots, and so on).

## Trait -> the cell it turns into, and how strong it must be to count.
const CELLS := {
	"speed": "flagellum", "sense": "eye", "armor": "plate", "toxin": "gland",
	"jaw": "mouth", "agility": "skin",
}
const THRESHOLD := 0.6
const MOST_CELLS := 2


## Grows up to MOST_CELLS kinds of cell on `plan` for `genome`'s strongest
## traits. Returns the labels of the cells grown, for a message.
static func grow_from(plan: BodyPlan, genome: Genome) -> PackedStringArray:
	var ranked: Array = CELLS.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool:
		return genome.value_of(a) > genome.value_of(b))
	var grown := PackedStringArray()
	for t in ranked:
		var trait_name: String = t
		if grown.size() >= MOST_CELLS or genome.value_of(trait_name) < THRESHOLD:
			break
		var role: String = CELLS[trait_name]
		if plan.grow(role) > 0:
			grown.append(BodyPart.label(role).to_lower())
	return grown
