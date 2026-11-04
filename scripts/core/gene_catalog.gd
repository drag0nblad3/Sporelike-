class_name GeneCatalog
extends RefCounted
## Every gene a subspecies can be founded with. Five trees, each with two
## branches of four tiers, so every tree offers the same choices and value:
## tiers 1 and 2 are starting stat nudges (1 slot), tiers 3 and 4 are
## organelles or a body form the founders are born with (2 slots). Each
## tier costs the same gene points in every tree and needs the tier below.

const TREES := ["body", "defense", "feeding", "senses", "metabolism"]
const TREE_NAMES := {"body": "Body", "defense": "Defense", "feeding": "Feeding",
	"senses": "Senses", "metabolism": "Metabolism"}
## tree -> two branches of [name, four gene ids from tier 1 to 4].
const BRANCHES := {
	"body": [["Size", ["big_1", "big_2", "fat_store", "form_amoeboid"]],
		["Speed", ["swift_1", "swift_2", "tail_bud", "form_rod"]]],
	"defense": [["Spines", ["spines_1", "spines_2", "trichocysts", "form_shelled"]],
		["Toxin", ["venom_1", "venom_2", "toxicysts", "toxicysts_2"]]],
	"feeding": [["Plants", ["grazer_1", "grazer_2", "chloroplasts", "form_disc"]],
		["Prey", ["hunter_1", "hunter_2", "sticky_coat", "food_scent"]]],
	"senses": [["Sight", ["keen_1", "keen_2", "eye_cluster", "flash"]],
		["Reflexes", ["nimble_1", "nimble_2", "jet", "form_spiral"]]],
	"metabolism": [["Digestion", ["lean_1", "lean_2", "gut_lining", "vent_symbionts"]],
		["Chewing", ["jaw_1", "jaw_2", "grabbing_cilia", "gut_lining_2"]]],
}
## Gene points and slots by tier (1 to 4).
const COST := [2, 4, 6, 8]
const SLOTS := [1, 1, 2, 2]
## id -> [label, kind ("trait", "feature" or "efficiency"), what, amount].
## Feature amounts are the level the founders are born with.
const GENES := {
	"big_1": ["Larger founders", "trait", "size", 0.06],
	"big_2": ["Larger founders II", "trait", "size", 0.06],
	"swift_1": ["Swift founders", "trait", "speed", 0.06],
	"swift_2": ["Swift founders II", "trait", "speed", 0.06],
	"spines_1": ["Early spines", "trait", "armor", 0.08],
	"spines_2": ["Early spines II", "trait", "armor", 0.08],
	"venom_1": ["Early toxin", "trait", "toxin", 0.08],
	"venom_2": ["Early toxin II", "trait", "toxin", 0.08],
	"grazer_1": ["Grazer gut", "trait", "diet", -0.08],
	"grazer_2": ["Grazer gut II", "trait", "diet", -0.08],
	"hunter_1": ["Hunter gut", "trait", "diet", 0.08],
	"hunter_2": ["Hunter gut II", "trait", "diet", 0.08],
	"keen_1": ["Keen founders", "trait", "sense", 0.06],
	"keen_2": ["Keen founders II", "trait", "sense", 0.06],
	"nimble_1": ["Nimble founders", "trait", "agility", 0.06],
	"nimble_2": ["Nimble founders II", "trait", "agility", 0.06],
	"jaw_1": ["Firm mouth", "trait", "jaw", 0.08],
	"jaw_2": ["Firm mouth II", "trait", "jaw", 0.08],
	"lean_1": ["Lean metabolism", "efficiency", "", 0.15],
	"lean_2": ["Lean metabolism II", "efficiency", "", 0.15],
	"fat_store": ["Lipid droplets", "feature", "fat_store", 1],
	"tail_bud": ["Second flagellum", "feature", "tail_bud", 1],
	"trichocysts": ["Trichocysts", "feature", "trichocysts", 1],
	"toxicysts": ["Toxicysts", "feature", "toxicysts", 1],
	"toxicysts_2": ["Toxicysts II", "feature", "toxicysts", 2],
	"chloroplasts": ["Chloroplasts", "feature", "chloroplasts", 1],
	"sticky_coat": ["Mucus coat", "feature", "sticky_coat", 1],
	"food_scent": ["Chemoreceptors", "feature", "food_scent", 1],
	"eye_cluster": ["Eyespot cluster", "feature", "eye_cluster", 1],
	"flash": ["Scintillons", "feature", "flash", 1],
	"jet": ["Contractile jet", "feature", "jet", 1],
	"gut_lining": ["Digestive vacuoles", "feature", "gut_lining", 1],
	"gut_lining_2": ["Digestive vacuoles II", "feature", "gut_lining", 2],
	"vent_symbionts": ["Vent symbionts", "feature", "vent_symbionts", 1],
	"grabbing_cilia": ["Grabbing cilia", "feature", "grabbing_cilia", 1],
	"form_amoeboid": ["Amoeboid form", "feature", "form_amoeboid", 1],
	"form_rod": ["Rod form", "feature", "form_rod", 1],
	"form_shelled": ["Shelled form", "feature", "form_shelled", 1],
	"form_disc": ["Disc form", "feature", "form_disc", 1],
	"form_spiral": ["Spiral form", "feature", "form_spiral", 1],
}


static func exists(id: String) -> bool:
	return GENES.has(id)


static func count() -> int:
	return GENES.size()


static func label(id: String) -> String:
	return str(GENES[id][0]) if exists(id) else id


## Tier 1 to 4, from the gene's place in its branch.
static func tier(id: String) -> int:
	for tree in BRANCHES:
		for branch in BRANCHES[tree]:
			var ids: Array = branch[1]
			if id in ids:
				return ids.find(id) + 1
	return 1


static func cost(id: String) -> int:
	return int(COST[tier(id) - 1])


static func slots(id: String) -> int:
	return int(SLOTS[tier(id) - 1])


## The gene below this one in its branch, or "" for tier 1.
static func needs(id: String) -> String:
	for tree in BRANCHES:
		for branch in BRANCHES[tree]:
			var ids: Array = branch[1]
			var at := ids.find(id)
			if at > 0:
				return str(ids[at - 1])
	return ""


static func feature_of(id: String) -> String:
	return str(GENES[id][2]) if exists(id) and str(GENES[id][1]) == "feature" else ""


## Body forms exclude each other: a subspecies takes at most one.
static func is_form(id: String) -> bool:
	return feature_of(id).begins_with("form_")


## Genes unlocked for free when a subspecies evolves this organelle to
## this level during its run.
static func for_feature(feature_id: String, level: int) -> Array[String]:
	var list: Array[String] = []
	for id in GENES:
		var row: Array = GENES[id]
		if str(row[1]) == "feature" and str(row[2]) == feature_id and int(row[3]) <= level:
			list.append(id)
	return list


## Applies the chosen genes to a founder genome.
static func apply(genome: Genome, ids: Array) -> void:
	for raw in ids:
		var id := str(raw)
		if not exists(id):
			continue
		var row: Array = GENES[id]
		var what: String = row[2]
		match str(row[1]):
			"trait":
				genome.values[what] = clampf(float(genome.values[what]) + float(row[3]), 0.0, 1.0)
			"feature":
				genome.features[what] = maxi(genome.feature(what), int(row[3]))
			"efficiency":
				genome.efficiency = minf(genome.efficiency + float(row[3]), 1.0)
