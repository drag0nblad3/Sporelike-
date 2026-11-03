class_name EvolutionRound
extends Node
## The pause between generations: tallies progress, hard times, the
## player's habits, the hunters and the rival species, then offers the
## player one set of three picks, plus a bonus set for each doubling of the
## energy their body needed.

signal finished(preview: Genome)

var ecosystem: Ecosystem
var director: PlayerDirector
var cycle: GenerationCycle
var screen: PopulationScreen
var progress: EvolutionProgress
var rng: RandomNumberGenerator
var smoke_test := false
## Offer the body form choice on the first pick, not only at Fed 200%
## (the screenshot tour uses this).
var forms_early := false

var _stats: GenerationStats
var _total := 1
var _offered := 0
## A typical member of the species with this round's picks applied, for
## the numbers on the pick cards.
var _preview: Genome
var _habits: Habits


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
	_habits = director.tracker.habits
	_habits.add("fed", stats.fed_ratio())
	stats.habit_text = HabitDrift.describe(_habits, StatSheet.typical(stats.end_averages))
	HabitDrift.apply_all(_habits, genomes)
	stats.end_averages = ecosystem.trait_averages()
	stats.hunter_text = ecosystem.hunters.end_generation(ecosystem.predators.size(), rng)
	stats.rival_text = ecosystem.rivals.end_generation(director.genome)
	# Preview picks on the same typical member the screen describes, not on
	# the player's own body, whose traits differ from the species average.
	StatSheet.shared = director.genome
	_preview = StatSheet.typical(stats.end_averages)
	_total = 1 + stats.bonus_sets()
	_offered = 0
	_offer()


func _offer() -> void:
	_offered += 1
	var heading := "Encourage a mutation in your species:"
	if _total > 1:
		heading = "Encourage a mutation: pick %d of %d (bonus picks for eating well)" % [
			_offered, _total]
	var choices: Array[MutationChoice]
	if _form_time():
		heading = "Your cells are thriving. Choose a body form (it grows with later picks):"
		choices = BodyForm.roll(rng, 3, _habits)
	else:
		choices = PickRoller.roll(rng, 3, ecosystem.trait_averages(), _preview, _habits)
	screen.open(_stats, choices, _preview, heading)
	if smoke_test:
		screen.call_deferred("_pick", choices[0])


## The first bonus pick (Fed 200%) is the body form choice, once per species.
## Smoke tests offer it straight away so CI exercises it.
func _form_time() -> bool:
	if BodyForm.of(_preview) != "":
		return false
	return _offered == 2 or ((smoke_test or forms_early) and _offered == 1)


func _on_chosen(choice: MutationChoice) -> void:
	cycle.apply(choice)
	choice.apply_to(_preview, _stats.influence())
	if _offered < _total:
		_offer()
	else:
		finished.emit(_preview)
