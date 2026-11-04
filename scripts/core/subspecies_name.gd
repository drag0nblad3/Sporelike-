class_name SubspeciesName
extends RefCounted
## Made-up Latin-style names for new subspecies, like "Rhodomonas pelagica".

const GENUS_START := ["Rhodo", "Chloro", "Glauco", "Proto", "Thalasso", "Cilio", "Micro",
	"Pelago", "Cyano", "Halo"]
const GENUS_END := ["monas", "coccus", "phyra", "zoon", "cystis", "nema", "opsis", "della"]
const EPITHET := ["pelagica", "abyssalis", "minuta", "velox", "aurea", "fervida",
	"umbrosa", "lucida", "ferox", "nova"]


static func random(rng: RandomNumberGenerator) -> String:
	return "%s%s %s" % [_pick(GENUS_START, rng), _pick(GENUS_END, rng), _pick(EPITHET, rng)]


static func _pick(list: Array, rng: RandomNumberGenerator) -> String:
	return str(list[rng.randi_range(0, list.size() - 1)])
