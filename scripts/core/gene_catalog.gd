class_name GeneCatalog
extends RefCounted
## Every gene a subspecies can be founded with, in four trees. A gene is
## either a starting stat nudge (1 slot) or an organelle the founders are
## born with (2 slots). Each gene costs gene points to unlock in the
## GeneBank and may need another gene in its tree first.

const TREES := ["body", "defense", "feeding", "motion"]
const TREE_NAMES := {"body": "Body", "defense": "Defense", "feeding": "Feeding",
	"motion": "Motion"}

## id -> {tree, label, cost, needs, and one of trait/amount, feature, efficiency}
const ALL := {
	"big_1": {"tree": "body", "label": "Larger founders", "cost": 2, "needs": "",
		"trait": "size", "amount": 0.06},
	"big_2": {"tree": "body", "label": "Larger founders II", "cost": 4, "needs": "big_1",
		"trait": "size", "amount": 0.06},
	"swift_1": {"tree": "body", "label": "Swift founders", "cost": 2, "needs": "",
		"trait": "speed", "amount": 0.06},
	"swift_2": {"tree": "body", "label": "Swift founders II", "cost": 4, "needs": "swift_1",
		"trait": "speed", "amount": 0.06},
	"nimble_1": {"tree": "body", "label": "Nimble founders", "cost": 2, "needs": "",
		"trait": "agility", "amount": 0.06},
	"keen_1": {"tree": "body", "label": "Keen founders", "cost": 2, "needs": "",
		"trait": "sense", "amount": 0.06},
	"spines_1": {"tree": "defense", "label": "Early spines", "cost": 2, "needs": "",
		"trait": "armor", "amount": 0.08},
	"venom_1": {"tree": "defense", "label": "Early toxin", "cost": 2, "needs": "",
		"trait": "toxin", "amount": 0.08},
	"trichocysts": {"tree": "defense", "label": "Trichocysts", "cost": 5, "needs": "spines_1",
		"feature": "trichocysts"},
	"sticky_coat": {"tree": "defense", "label": "Mucus coat", "cost": 4, "needs": "spines_1",
		"feature": "sticky_coat"},
	"toxicysts": {"tree": "defense", "label": "Toxicysts", "cost": 5, "needs": "venom_1",
		"feature": "toxicysts"},
	"flash": {"tree": "defense", "label": "Scintillons", "cost": 5, "needs": "",
		"feature": "flash"},
	"grazer": {"tree": "feeding", "label": "Grazer gut", "cost": 2, "needs": "",
		"trait": "diet", "amount": -0.1},
	"hunter_gut": {"tree": "feeding", "label": "Hunter gut", "cost": 2, "needs": "",
		"trait": "diet", "amount": 0.1},
	"jaw_1": {"tree": "feeding", "label": "Firm mouth", "cost": 2, "needs": "",
		"trait": "jaw", "amount": 0.08},
	"lean_1": {"tree": "feeding", "label": "Lean metabolism", "cost": 3, "needs": "",
		"efficiency": 0.25},
	"gut_lining": {"tree": "feeding", "label": "Digestive vacuoles", "cost": 3, "needs": "",
		"feature": "gut_lining"},
	"fat_store": {"tree": "feeding", "label": "Lipid droplets", "cost": 3, "needs": "",
		"feature": "fat_store"},
	"chloroplasts": {"tree": "feeding", "label": "Chloroplasts", "cost": 6, "needs": "grazer",
		"feature": "chloroplasts"},
	"vent_symbionts": {"tree": "feeding", "label": "Vent symbionts", "cost": 6,
		"needs": "gut_lining", "feature": "vent_symbionts"},
	"food_scent": {"tree": "feeding", "label": "Chemoreceptors", "cost": 5,
		"needs": "gut_lining", "feature": "food_scent"},
	"jet": {"tree": "motion", "label": "Contractile jet", "cost": 3, "needs": "",
		"feature": "jet"},
	"tail_bud": {"tree": "motion", "label": "Second flagellum", "cost": 5, "needs": "jet",
		"feature": "tail_bud"},
	"grabbing_cilia": {"tree": "motion", "label": "Grabbing cilia", "cost": 4, "needs": "",
		"feature": "grabbing_cilia"},
	"eye_cluster": {"tree": "motion", "label": "Eyespot cluster", "cost": 4,
		"needs": "grabbing_cilia", "feature": "eye_cluster"},
}


static func info(id: String) -> Dictionary:
	return ALL.get(id, {})


static func in_tree(tree: String) -> Array[String]:
	var list: Array[String] = []
	for id in ALL:
		if str(ALL[id]["tree"]) == tree:
			list.append(id)
	return list


## Slots this gene takes in a subspecies: organelles take two.
static func slots(id: String) -> int:
	return 2 if info(id).has("feature") else 1


## The gene that unlocks for free when a subspecies evolves this organelle
## during its run, or "" if none.
static func for_feature(feature_id: String) -> String:
	for id in ALL:
		if str(ALL[id].get("feature", "")) == feature_id:
			return id
	return ""


## Applies the chosen genes to a founder genome.
static func apply(genome: Genome, ids: Array) -> void:
	for raw in ids:
		var row := info(str(raw))
		if row.has("trait"):
			var t: String = row["trait"]
			genome.values[t] = clampf(float(genome.values[t]) + float(row["amount"]), 0.0, 1.0)
		elif row.has("feature"):
			var f: String = row["feature"]
			genome.features[f] = maxi(genome.feature(f), 1)
		elif row.has("efficiency"):
			genome.efficiency = minf(genome.efficiency + float(row["efficiency"]), 1.0)
