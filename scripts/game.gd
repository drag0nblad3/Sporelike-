class_name Game
extends Node3D
## One play session: wires the world together and runs the generation loop
## (play a generation, see the population screen, pick a mutation, be reborn
## as one of your kind). Starts fresh or from a save. Rules live elsewhere.

signal quit_to_title
signal generation_started(number: int)

const ARENA_RADIUS := 55.0
const DEATH_PAUSE := 1.5

var ecosystem: Ecosystem
var director: PlayerDirector
var cycle: GenerationCycle
var camera: CameraRig
var hud: Hud
var screen: PopulationScreen
var saver: GameSaver
var progress := EvolutionProgress.new()
var rng := RandomNumberGenerator.new()
## Set by CI ("-- --smoke"): short generations, mutations picked automatically.
var smoke_test := false

var _save := {}


## Call before adding to the tree. An empty save starts a new game.
func setup(save: Dictionary, smoke: bool) -> void:
	_save = save
	smoke_test = smoke


func _ready() -> void:
	rng.randomize()
	var world_seed := int(_save.get("world_seed", randi()))
	var map := BiomeMap.generate(world_seed, ARENA_RADIUS, FoodKind.all())
	add_child(Arena.new(map))
	camera = CameraRig.new()
	add_child(camera)
	hud = Hud.new()
	add_child(hud)
	screen = PopulationScreen.new()
	hud.add_child(screen)
	screen.chosen.connect(_on_mutation_chosen)
	hud.pause_menu.quit_requested.connect(_on_quit_requested)

	var founder := Genome.new()
	ecosystem = Ecosystem.new()
	ecosystem.setup(map, founder)
	ecosystem.saved_members = GameSaver.members_from(_save)
	ecosystem.births = int(_save.get("births", 0))
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

	saver = GameSaver.new()
	saver.ecosystem = ecosystem
	saver.director = director
	saver.cycle = cycle
	saver.progress = progress
	saver.world_seed = world_seed
	progress.points = float(_save.get("progress", 0.0))
	add_child(saver)

	if _save.is_empty():
		director.spawn(founder, Vector2.ZERO)
		_begin_generation()
	else:
		_resume()
	_refresh_species()


func _process(_delta: float) -> void:
	hud.show_generation(cycle.number, cycle.time_left, cycle.stats.food_eaten)


func _resume() -> void:
	var you := GameSaver.player_from(_save)
	var you_genome: Genome = you[0]
	var you_at: Vector2 = you[1]
	director.spawn(you_genome, you_at)
	director.player.energy = you[2]
	cycle.number = int(_save.get("generation", 1)) - 1
	cycle.begin()
	cycle.time_left = minf(float(_save.get("time_left", cycle.length)), cycle.length)
	saver.save_now()
	_announce()


func _begin_generation() -> void:
	cycle.begin()
	saver.save_now()
	_announce()


func _announce() -> void:
	generation_started.emit(cycle.number)
	if smoke_test:
		print("smoke: generation %d started, species %d, progress %d, physics %.2f ms" % [
			cycle.number, ecosystem.species.size(), progress.points,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])


func _on_player_died(cause: String) -> void:
	hud.flash_message("You were eaten!" if cause == "eaten" else "You starved!", DEATH_PAUSE)
	var generation := cycle.number
	await get_tree().create_timer(DEATH_PAUSE).timeout
	if cycle.number == generation:
		cycle.finish(cause)


func _on_generation_ended(stats: GenerationStats) -> void:
	get_tree().paused = true
	stats.progress_text = progress.summary(progress.add_generation(stats))
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
	_begin_generation()
	_refresh_species()


func _on_quit_requested() -> void:
	saver.save_now()
	get_tree().paused = false
	quit_to_title.emit()


func _refresh_species() -> void:
	hud.show_species(ecosystem.species.size(), ecosystem.births, ecosystem.trait_averages())
