class_name TraitNames
extends RefCounted
## On-screen names for the Genome traits, in single-cell terms. The ids in
## Genome.TRAITS stay the same so old saves still load.

const NAMES := {
	"size": "Size", "speed": "Speed", "agility": "Agility", "sense": "Sense",
	"armor": "Spines", "toxin": "Toxin", "diet": "Diet", "jaw": "Mouth",
}


static func of(trait_name: String) -> String:
	return NAMES.get(trait_name, trait_name.capitalize())
