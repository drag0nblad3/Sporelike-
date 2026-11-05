class_name Game
extends Node3D
## One play session: wires the world together and runs the generation loop
## (play a generation, see the population screen, pick a mutation, be reborn
## as one of your kind). Each game is one subspecies run, founded with genes
## from the GeneBank; RunEnd pays out when it dies out or establishes.
## Starts fresh or from a save. Rules live elsewhere.

signal quit_to_title
signal generation_started(number: int)

const DEATH_PAUSE := 1.5

var arena: Arena
var ecosystem: Ecosystem
var director: PlayerDirector
var cycle: GenerationCycle
var camera: CameraRig
var hud: Hud
var screen: PopulationScreen
var saver: GameSaver
var streamer: ChunkStreamer
var progress := EvolutionProgress.new()
var round_end: EvolutionRound
var stage_two: StageTwo
var rng := RandomNumberGenerator.new()
## Set by CI ("-- --smoke"): short generations, mutations picked automatically.
var smoke_test := false
## Set from the title screen's "Test stage 2": skip straight to the switch.
var jump_to_stage_two := false
## The subspecies this run founds and the genes it starts with (set by
## setup for a new run, read from the save otherwise).
var subspecies_name := ""
var loadout: Array[String] = []
## The Sea this run starts in (see Sea.ids); the rest of the world is a
## patchwork of every sea (SeaMap).
var sea_id := Sea.DEFAULT
var run_end: RunEnd

var _save := {}
var _sea_map: SeaMap
## Where the subspecies established itself, for the switch to stage 2.
var _switch_at := Vector2.ZERO


## Call before adding to the tree. An empty save starts a new game.
func setup(save: Dictionary, smoke: bool, new_name: String = "",
		genes: Array[String] = [], new_sea: String = Sea.DEFAULT) -> void:
	_save = save
	smoke_test = smoke
	subspecies_name = str(save.get("subspecies", new_name))
	sea_id = str(save.get("sea", new_sea))
	# The world reads the sea as it is built, so pick it before _ready.
	Sea.use(sea_id)
	loadout = genes
	for raw in save.get("loadout", []):
		loadout.append(str(raw))


func _ready() -> void:
	rng.randomize()
	var world_seed := int(_save.get("world_seed", randi()))
	_sea_map = SeaMap.new(world_seed, sea_id)
	SeaMap.active = _sea_map
	arena = Arena.new()
	add_child(arena)
	camera = CameraRig.new()
	add_child(camera)
	hud = Hud.new()
	add_child(hud)
	screen = PopulationScreen.new()
	hud.add_child(screen)
	hud.pause_menu.quit_requested.connect(_on_quit_requested)
	hud.pause_menu.save_cell_requested.connect(_on_save_cell)

	var founder := EvolvedSpecies.random(rng) if jump_to_stage_two else Genome.new()
	if not jump_to_stage_two:
		GeneCatalog.apply(founder, loadout)
	ecosystem = Ecosystem.new()
	ecosystem.setup(founder)
	if not _save.is_empty():
		var you_at: Vector2 = GameSaver.player_from(_save)[1]
		ecosystem.focus = you_at
	ecosystem.saved_members = GameSaver.members_from(_save)
	ecosystem.births = int(_save.get("births", 0))
	ecosystem.saved_rivals = _save.get("rivals", [])
	ecosystem.hunters.load_save(_save.get("hunters", {}))
	ecosystem.species_changed.connect(_refresh_species)
	add_child(ecosystem)
	_add_world(world_seed)

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
	director.smoke_test = smoke_test
	director.died.connect(_on_player_died)
	director.ate.connect(cycle.record_food)
	director.made_energy.connect(cycle.record_energy)
	hud.ability_pressed.connect(director.use)
	add_child(director)

	_add_stage_two()
	saver = GameSaver.new()
	saver.stage_two = stage_two
	saver.ecosystem = ecosystem
	saver.director = director
	saver.cycle = cycle
	saver.progress = progress
	saver.world_seed = world_seed
	saver.run_info = {"subspecies": subspecies_name, "loadout": loadout, "sea": sea_id}
	# A stage 2 test run must not overwrite the player's real save.
	saver.enabled = not jump_to_stage_two
	progress.points = float(_save.get("progress", 0.0))
	if smoke_test and _save.is_empty():
		# CI: reach the multicellular switch after the first generation.
		progress.points = EvolutionProgress.GOAL - 1.0
	add_child(saver)
	_add_round()
	_add_run_end()

	if _save.is_empty():
		director.spawn(founder, Vector2.ZERO)
		if jump_to_stage_two:
			progress.points = EvolutionProgress.GOAL
			stage_two.offer_switch(Vector2.ZERO)
		else:
			_begin_generation()
			hud.flash_message("%s arrives in the %s" % [subspecies_name, Sea.current().title], 3.0)
	else:
		_resume()
	_refresh_species()


func _process(delta: float) -> void:
	if director.is_alive():
		ecosystem.focus = director.player.flat_pos()
	elif stage_two.pilot.is_alive():
		ecosystem.focus = stage_two.center()
	streamer.update(ecosystem.focus)
	arena.follow(ecosystem.focus, delta)
	hud.show_generation(cycle.number, cycle.time_left, cycle.stats.fed_ratio())


func _exit_tree() -> void:
	if SeaMap.active == _sea_map:
		SeaMap.active = null


## The endless sea floor: chunks load around the player and bring their
## food patches with them; far-off members sleep until the player returns.
func _add_world(world_seed: int) -> void:
	streamer = ChunkStreamer.new(world_seed)
	streamer.chunk_loaded.connect(func(c: WorldChunk) -> void:
		ecosystem.food.add_patches(c.patches))
	streamer.chunk_unloaded.connect(func(c: WorldChunk) -> void:
		ecosystem.food.remove_patches(c.patches))
	add_child(streamer)
	streamer.update(ecosystem.focus)
	var zone := ActivityZone.new()
	zone.ecosystem = ecosystem
	zone.streamer = streamer
	add_child(zone)


func _add_stage_two() -> void:
	stage_two = StageTwo.new()
	stage_two.ecosystem = ecosystem
	stage_two.camera = camera
	stage_two.hud = hud
	stage_two.director = director
	stage_two.rng = rng
	stage_two.smoke_test = smoke_test
	stage_two.died.connect(_on_player_died)
	stage_two.ready_to_play.connect(_on_stage_two_ready)
	stage_two.stage_finished.connect(func() -> void:
		run_end.screen.final_body = FinalBody.title(stage_two.plan.final_body)
		run_end.conclude(true, cycle.number, progress.points, director.genome))
	stage_two.pilot.ate.connect(cycle.record_food)
	add_child(stage_two)


func _add_round() -> void:
	round_end = EvolutionRound.new()
	round_end.ecosystem = ecosystem
	round_end.director = director
	round_end.cycle = cycle
	round_end.screen = screen
	round_end.progress = progress
	round_end.rng = rng
	round_end.smoke_test = smoke_test
	round_end.finished.connect(_on_round_finished)
	add_child(round_end)


func _add_run_end() -> void:
	run_end = RunEnd.new()
	run_end.subspecies_name = subspecies_name
	run_end.sea_title = Sea.current().title
	run_end.throwaway = jump_to_stage_two
	run_end.smoke_test = smoke_test
	run_end.screen = RunSummary.new()
	run_end.screen.visible = false
	hud.add_child(run_end.screen)
	run_end.keep_playing.connect(func() -> void:
		if stage_two.active:
			stage_two.play_on()
		else:
			stage_two.offer_switch(_switch_at))
	run_end.finished.connect(func() -> void:
		get_tree().paused = false
		quit_to_title.emit())
	add_child(run_end)


func _resume() -> void:
	var you := GameSaver.player_from(_save)
	var you_genome: Genome = you[0]
	var you_at: Vector2 = you[1]
	if int(_save.get("stage", 1)) == 2:
		director.genome = you_genome
		stage_two.resume(_save, you_at)
	else:
		director.spawn(you_genome, you_at)
		director.player.energy = you[2]
	cycle.number = int(_save.get("generation", 1)) - 1
	_start_cycle()
	cycle.time_left = minf(float(_save.get("time_left", cycle.length)), cycle.length)
	saver.save_now()
	_announce()


func _begin_generation() -> void:
	_start_cycle()
	saver.save_now()
	_announce()


## Starts the generation's stats against the current body's running cost,
## and pulls the camera back and makes food scarcer as the species progresses.
func _start_cycle() -> void:
	cycle.begin()
	director.tracker.reset(cycle.length)
	StatSheet.shared = director.genome
	var upkeep := stage_two.upkeep() if stage_two.active else director.genome.upkeep()
	cycle.stats.energy_needed = upkeep * cycle.length
	camera.progress_zoom = 1.0 + CameraRig.PROGRESS_ZOOM * progress.fraction()
	ecosystem.food.abundance = progress.food_abundance()


func _announce() -> void:
	generation_started.emit(cycle.number)
	if smoke_test:
		print("smoke: generation %d started, species %d, rivals %d, progress %d, physics %.2f ms" % [
			cycle.number, ecosystem.species.size(), ecosystem.rivals.members().size(), progress.points,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])


func _on_player_died(cause: String) -> void:
	hud.flash_message("You were eaten!" if cause == "eaten" else "You starved!", DEATH_PAUSE)
	var generation := cycle.number
	await get_tree().create_timer(DEATH_PAUSE).timeout
	if cycle.number == generation:
		cycle.finish(cause)


func _on_generation_ended(stats: GenerationStats) -> void:
	get_tree().paused = true
	if stage_two.active:
		stage_two.end_generation(stats)
	else:
		round_end.start(stats)


## After the picks: take over a random survivor's offspring. If none
## survived and you are dead too, the subspecies died out and the run ends;
## if you alone survived, the species restarts from your (picked) genome.
func _on_round_finished(preview: Genome) -> void:
	var next_genome: Genome
	var at := Vector2.ZERO
	var parent := ecosystem.pick_parent()
	if parent == null and not director.is_alive() and not jump_to_stage_two:
		director.retire()
		run_end.conclude(false, cycle.number, progress.points, preview)
		return
	if parent:
		next_genome = parent.genome.mutated(rng)
		at = parent.flat_pos() + Vector2.from_angle(rng.randf() * TAU) * 2.0
	else:
		next_genome = preview
		ecosystem.reseed(next_genome)
	if progress.is_ready() and not stage_two.active:
		_switch_at = director.player.flat_pos() if director.is_alive() else at
		director.retire()
		run_end.conclude(true, cycle.number, progress.points, preview)
		return
	director.retire()
	get_tree().paused = false
	director.spawn(next_genome, at)
	_begin_generation()
	_refresh_species()


## The switch to the multicellular stage, or a stage 2 pick, is done.
func _on_stage_two_ready() -> void:
	get_tree().paused = false
	_begin_generation()
	_refresh_species()


func _on_save_cell() -> void:
	var count := OrganismCollection.add(director.genome, "Gen %d cell" % cycle.number)
	hud.pause_menu.show_note(
		"Cell saved (%d in your collection). It may return as a rival species." % count)


func _on_quit_requested() -> void:
	saver.save_now()
	get_tree().paused = false
	quit_to_title.emit()


func _refresh_species() -> void:
	hud.show_species(ecosystem.species.size(), ecosystem.births, ecosystem.trait_averages())
