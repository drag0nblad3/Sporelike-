class_name GeneBank
extends RefCounted
## The main species' gene reservoir, kept across every subspecies run in
## its own file: unspent gene points, points earned in all, which genes
## are unlocked, and the genes the last subspecies was founded with.

const PATH := "user://genes.json"
const START_SLOTS := 3
## One more slot for every this many points earned across all runs.
const POINTS_PER_SLOT := 10

var points := 0
var lifetime := 0
var unlocked: Array[String] = []
var last_loadout: Array[String] = []


static func load_bank() -> GeneBank:
	var bank := GeneBank.new()
	if not FileAccess.file_exists(PATH):
		return bank
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		return bank
	var data: Dictionary = parsed
	bank.points = int(data.get("points", 0))
	bank.lifetime = int(data.get("lifetime", 0))
	for raw in data.get("unlocked", []):
		if GeneCatalog.exists(str(raw)):
			bank.unlocked.append(str(raw))
	for raw in data.get("last_loadout", []):
		if bank.has(str(raw)):
			bank.last_loadout.append(str(raw))
	return bank


func save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save genes: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({"points": points, "lifetime": lifetime,
		"unlocked": unlocked, "last_loadout": last_loadout}))


func has(id: String) -> bool:
	return id in unlocked


func slots() -> int:
	return START_SLOTS + lifetime / POINTS_PER_SLOT


## Whether this gene can be bought now: not owned, its parent owned, and
## enough points.
func can_unlock(id: String) -> bool:
	if not GeneCatalog.exists(id) or has(id):
		return false
	var needs := GeneCatalog.needs(id)
	return (needs == "" or has(needs)) and points >= GeneCatalog.cost(id)


func unlock(id: String) -> bool:
	if not can_unlock(id):
		return false
	points -= GeneCatalog.cost(id)
	unlocked.append(id)
	return true


## Gene flow at the end of a run: adds the points, and unlocks for free the
## gene of each organelle the subspecies evolved. Returns the genes newly
## unlocked that way.
func receive(earned: int, evolved: Genome) -> Array[String]:
	points += earned
	lifetime += earned
	var fresh: Array[String] = []
	for f in evolved.features:
		for id in GeneCatalog.for_feature(str(f), evolved.feature(str(f))):
			if not has(id):
				unlocked.append(id)
				fresh.append(id)
	return fresh
