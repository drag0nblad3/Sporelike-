class_name HunterLineages
extends RefCounted
## Every hunter kind's HunterLineage: each kind goes hungry and evolves on
## its own. Saves as {kind: upgrade levels}.

var by_kind := {}


func _init() -> void:
	for kind in HunterKind.ids():
		var lineage := HunterLineage.new()
		lineage.kind = kind
		by_kind[kind] = lineage


func of(kind: String) -> HunterLineage:
	return by_kind[kind]


func to_save() -> Dictionary:
	var data := {}
	for kind in by_kind:
		data[kind] = of(kind).levels
	return data


## Older saves held one set of levels for the single kind of hunter.
func load_save(data: Dictionary) -> void:
	for key in data:
		if HunterLineage.UPGRADES.has(key):
			of(HunterKind.CHASER).levels = data
			return
	for kind in data:
		if by_kind.has(kind):
			var levels: Dictionary = data[kind]
			of(kind).levels = levels


## Ends the generation for every kind; one line per kind.
func end_generation(hunters: Array[Predator], rng: RandomNumberGenerator) -> String:
	var lines: Array[String] = []
	for kind in by_kind:
		var count := 0
		for h in hunters:
			if h.kind == kind:
				count += 1
		lines.append(of(kind).end_generation(count, rng))
	return "\n".join(lines)
