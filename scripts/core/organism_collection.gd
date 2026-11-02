class_name OrganismCollection
extends RefCounted
## Cells the player chose to keep. Stored in their own file, apart from the
## game save, so they last across games; some later rival species are
## founded from them.

const PATH := "user://collection.json"
const MAX_ENTRIES := 24


## Each entry: {"label": String, "genome": Dictionary}.
static func entries() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Array else []


## Adds a copy of this genome; the oldest entry goes once the list is full.
## Returns how many cells the collection now holds.
static func add(genome: Genome, label: String) -> int:
	var list := entries()
	list.append({"label": label, "genome": genome.to_dict()})
	while list.size() > MAX_ENTRIES:
		list.pop_front()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save cell: %s" % error_string(FileAccess.get_open_error()))
		return list.size() - 1
	file.store_string(JSON.stringify(list))
	return list.size()


## A random saved entry, or an empty Dictionary when none are saved.
static func pick(rng: RandomNumberGenerator) -> Dictionary:
	var list := entries()
	if list.is_empty():
		return {}
	var entry: Dictionary = list[rng.randi() % list.size()]
	return entry
