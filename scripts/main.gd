extends Node3D
## Wires the game together and runs the generation loop: play a generation,
## see the population screen, pick a mutation, be reborn as one of your kind.
## Game rules live in the classes under scripts/; keep this file thin.

const ARENA_RADIUS := 30.0
const DEATH_PAUSE := 1.5

var ecosystem: Ecosystem
var director: PlayerDirector
var cycle: GenerationCycle
var camera: CameraRig
var hud: Hud
var screen: PopulationScreen
var rng := RandomNumberGenerator.new()
## Set by CI ("-- --smoke"): short generations, mutations picked automatically.
var smoke_test := "--smoke" in OS.get_cmdline_user_args()


func _ready() -> void:
	rng.randomize()
	add_child(Arena.new(ARENA_RADIUS))
	camera = CameraRig.new()
	add_child(camera)
	hud = Hud.new()
	add_child(hud)
	screen = PopulationScreen.new()
	hud.add_child(screen)
	screen.chosen.connect(_on_mutation_chosen)

	var founder := Genome.new()
	ecosystem = Ecosystem.new()
	ecosystem.setup(ARENA_RADIUS, founder)
	ecosystem.species_changed.connect(_refresh_species)
	add_child(ecosystem)

	cycle = GenerationCycle.new()
	cycle.ecosystem = ecosystem
	if smoke_test:
		cycle.length = 2.0
	cycle.ended.connect(_on_generation_ended)
	add_child(cycle)

	director = PlayerDirector.new()
	director.ecosystem = ecosystem
	director.camera = camera
	director.hud = hud
	director.arena_radius = ARENA_RADIUS
	director.died.connect(_on_player_died)
	director.ate.connect(cycle.record_food)
	add_child(director)

	director.spawn(founder, Vector2.ZERO)
	cycle.begin()
	_refresh_species()


func _process(_delta: float) -> void:
	hud.show_generation(cycle.number, cycle.time_left, cycle.stats.food_eaten)


func _on_player_died(cause: String) -> void:
	hud.flash_message("You were eaten!" if cause == "eaten" else "You starved!", DEATH_PAUSE)
	var generation := cycle.number
	await get_tree().create_timer(DEATH_PAUSE).timeout
	if cycle.number == generation:
		cycle.finish(cause)


func _on_generation_ended(stats: GenerationStats) -> void:
	get_tree().paused = true
	var choices := MutationChoice.roll(rng, 3)
	screen.open(stats, choices)
	if smoke_test:
		screen.call_deferred("_pick", choices[0])


## Apply the choice, then take over a random survivor's offspring.
func _on_mutation_chosen(choice: MutationChoice) -> void:
	cycle.apply(choice)
	var next_genome: Genome
	var at := Vector2.ZERO
	var parent := ecosystem.pick_parent()
	if parent:
		next_genome = parent.genome.mutated(rng)
		at = parent.flat_pos() + Vector2.from_angle(rng.randf() * TAU) * 2.0
	else:
		next_genome = director.genome.copy()
		choice.apply_to(next_genome, 1.0)
		ecosystem.reseed(next_genome)
	director.retire()
	get_tree().paused = false
	director.spawn(next_genome, at)
	cycle.begin()
	_refresh_species()
	if smoke_test:
		print("smoke: generation %d started, species %d" % [cycle.number, ecosystem.species.size()])


func _refresh_species() -> void:
	hud.show_species(ecosystem.species.size(), ecosystem.births, ecosystem.trait_averages())
