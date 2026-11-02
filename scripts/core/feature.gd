class_name Feature
extends RefCounted
## Branching upgrades: special body parts a species can grow once a trait is
## developed enough (or, for storage, at any time). Each has a few levels.
## Genome reads the levels; this file says what exists and when it unlocks.

## Extra reach per Sticky coat level at which darting food sticks.
const STICKY_REACH := 1.2

## id -> [label, effect text, unlocking trait ("" = always), threshold, max level]
const ALL := {
	"grabbing_cilia": ["Grabbing cilia", "Cilia snatch food that is very close", "agility", 0.55, 2],
	"tail_bud": ["Tail bud", "Grow another tail: faster, costs more energy", "speed", 0.6, 2],
	"fat_store": ["Fat store", "Store extra food past full", "", 0.0, 3],
	"gut_lining": ["Gut lining", "Digest more of every food", "", 0.0, 3],
	"eye_cluster": ["Eye cluster", "Spot food from farther away", "sense", 0.6, 2],
	"jet": ["Jet boost", "Tap Jet for a quick burst of speed", "speed", 0.5, 2],
	"sticky_coat": ["Sticky coat", "Darting food that comes close gets stuck", "armor", 0.3, 2],
	"food_scent": ["Scent trail", "An arrow points to the nearest food you can eat, even hidden",
		"sense", 0.65, 1],
}


static func label(id: String) -> String:
	var row: Array = ALL[id]
	return row[0]


static func effect(id: String) -> String:
	var row: Array = ALL[id]
	return row[1]


static func max_level(id: String) -> int:
	var row: Array = ALL[id]
	return row[4]


## Features the species could grow now, given its average traits and the
## levels a typical member (the template genome) already has.
static func available(averages: Dictionary, template: Genome) -> Array[String]:
	var list: Array[String] = []
	for id in ALL:
		var row: Array = ALL[id]
		var needs: String = row[2]
		var threshold: float = row[3]
		if needs != "" and float(averages.get(needs, 0.0)) < threshold:
			continue
		if template.feature(id) >= max_level(id):
			continue
		list.append(id)
	return list
