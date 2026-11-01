class_name SpeciesRoster
extends RefCounted
## Everyone who belonged to the species this generation: the living at the
## start, the player, and every newborn. Deaths do not remove anyone, so
## trait averages describe the population instead of scoring who survived.

var _genomes: Array[Genome] = []
var _last := {}


## Starts a new generation's roster from these genomes.
func reset(genomes: Array[Genome]) -> void:
	if not _genomes.is_empty():
		_last = Genome.average(_genomes)
	_genomes = genomes.duplicate()


func add(genome: Genome) -> void:
	_genomes.append(genome)


## Average of each trait. With nobody on the roster yet, the previous
## generation's averages (or all zeros at the very start).
func averages() -> Dictionary:
	if _genomes.is_empty() and not _last.is_empty():
		return _last
	return Genome.average(_genomes)
