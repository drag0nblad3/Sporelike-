class_name EvolutionRound
extends Node
## The pause between generations: tallies progress, hard times, the hunters
## and the rival species, then offers the player one set of three picks,
## plus a bonus set for each doubling of the energy their body needed.

signal finished(preview: Genome)

var ecosystem: Ecosystem
var director: PlayerDirector
var cycle: GenerationCycle
var screen: PopulationScreen
var progress: EvolutionProgress
var rng: RandomNumberGenerator
var smoke_test := false

var _stats: GenerationStats
var _total := 1
var _offered := 0
## The player's genome with this round's picks applied, for previews.
var _preview: Genome


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen.chosen.connect(_on_chosen)


func start(stats: GenerationStats) -> void:
	_stats = stats
	stats.progress_text = progress.summary(progress.add_generation(stats))
	var genomes: Array[Genome] = [director.genome]
	for member in ecosystem.species:
		genomes.append(member.genome)
	stats.adapt_text = Hardship.adapt(stats, genomes)
	stats.hunter_text = ecosystem.hunters.end_generation(ecosystem.predators.size(), rng)
	stats.rival_text = ecosystem.rivals.end_generation(director.genome)
	_preview = director.genome.copy()
	_total = 1 + stats.bonus_sets()
	_offered = 0
	_offer()


func _offer() -> void:
	_offered += 1
	var heading := "Encourage a mutation in your species:"
	if _total > 1:
		heading = "Encourage a mutation: pick %d of %d (bonus picks for eating well)" % [
			_offered, _total]
	var choices := MutationChoice.roll(rng, 3, ecosystem.trait_averages(), _preview)
	screen.open(_stats, choices, _preview, heading)
	if smoke_test:
		screen.call_deferred("_pick", choices[0])


func _on_chosen(choice: MutationChoice) -> void:
	cycle.apply(choice)
	choice.apply_to(_preview, _stats.influence())
	if _offered < _total:
		_offer()
	else:
		finished.emit(_preview)
