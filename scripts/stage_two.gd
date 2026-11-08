class_name StageTwo
extends Node
## The multicellular stage inside Game. It runs the switch from a single
## cell, a symmetry choice once stage 1's goal is reached. It owns the
## player's colony (through ColonyPilot), the choices between generations
## (ColonyChoices), and the colony's part of the save.

## A generation can begin: the switch or this round's pick is done.
signal ready_to_play
signal died(cause: String)
## The colony picked its final body: the multicellular stage is complete.
signal stage_finished

## Share of a full belly a colony starts each generation with.
const START_ENERGY := 0.6
## Seconds per multicellular generation: bigger bodies live longer than cells.
const GENERATION_SECONDS := 120.0
## Seconds the colony spends hauling itself onto the beach at the end.
const HAUL_TIME := 3.0

var ecosystem: Ecosystem
var camera: CameraRig
var hud: Hud
var director: PlayerDirector
var rng: RandomNumberGenerator
var smoke_test := false
var active := false
var plan: BodyPlan
var pilot := ColonyPilot.new()
## Multicellular generations ended so far.
var generations := 0

var _picker: SymmetryPicker
var _choices := ColonyChoices.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pilot.ecosystem = ecosystem
	pilot.camera = camera
	pilot.hud = hud
	pilot.process_mode = Node.PROCESS_MODE_PAUSABLE
	pilot.starved.connect(func() -> void: died.emit("starved"))
	pilot.eaten.connect(func() -> void: died.emit("eaten"))
	pilot.rng.seed = rng.randi()
	pilot.smoke_test = smoke_test
	pilot.rivals.rng.seed = rng.randi()
	pilot.apex.rng.seed = rng.randi()
	add_child(pilot)
	_choices.hud = hud
	_choices.rng = rng
	_choices.smoke_test = smoke_test
	_choices.done.connect(_on_choices_done)
	_choices.stage_finished.connect(_haul_out)
	add_child(_choices)


## Stage 1 is done: ask which symmetry the colony evolves.
func offer_switch(at: Vector2) -> void:
	get_tree().paused = true
	if smoke_test:
		switch_to.call_deferred(Symmetry.BILATERAL, at)
		return
	_picker = SymmetryPicker.new()
	_picker.process_mode = Node.PROCESS_MODE_ALWAYS
	_picker.theme = UiTheme.shared()
	_picker.chosen.connect(func(kind: String) -> void: switch_to(kind, at))
	hud.add_child(_picker)


func switch_to(kind: String, at: Vector2) -> void:
	if is_instance_valid(_picker):
		_picker.queue_free()
	active = true
	plan = BodyPlan.starter(kind)
	var grown := CarryOver.grow_from(plan, director.genome)
	director.retire()
	director.hide_hint()
	_spawn(at)
	var note := "Your cells stay stuck together!"
	if not grown.is_empty():
		note += " Your old strengths gave you: " + ", ".join(grown)
	hud.flash_message(note, 4.0)
	ready_to_play.emit()


## Picks up a saved multicellular game.
func resume(data: Dictionary, at: Vector2) -> void:
	active = true
	var saved: Dictionary = data.get("colony", {})
	plan = BodyPlan.from_dict(saved)
	generations = int(data.get("colony_generations", 0))
	pilot.shallows.load_data(data.get("shore", {}))
	pilot.apex.load_data(data.get("apex", {}))
	pilot.tint = director.genome.color()
	pilot.nucleus = VisualParts.diet_color(director.genome)
	director.retire()
	director.hide_hint()
	pilot.spawn(plan, at, float(data.get("colony_energy", 0.0)))
	if pilot.colony.energy <= 0.0:
		pilot.colony.energy = pilot.colony.max_energy() * START_ENERGY


func save_data() -> Dictionary:
	if not active:
		return {}
	var energy := pilot.colony.energy if pilot.is_alive() else 0.0
	return {"stage": 2, "colony": plan.to_dict(), "colony_energy": energy,
		"colony_generations": generations, "shore": pilot.shallows.to_dict(),
		"apex": pilot.apex.to_dict()}


## What the colony burns per second, for the generation's Fed score.
func upkeep() -> float:
	return Colony.UPKEEP_PER_CELL * plan.parts.size() * FinalBody.upkeep_factor(plan.final_body)


func center() -> Vector2:
	return pilot.flat_center()


## Between generations: a new cell, and now and then a bigger choice.
func end_generation(stats: GenerationStats) -> void:
	generations += 1
	_choices.at_shore = is_instance_valid(pilot.colony) and pilot.shallows.reached(pilot.colony)
	_choices.open(stats, plan, generations)


## After the stage is complete and its summary shown: play on.
func play_on() -> void:
	pilot.autopilot = Vector2.ZERO
	_on_choices_done()


func _on_choices_done() -> void:
	_spawn(pilot.shallows.water_spot(center()))
	ready_to_play.emit()


## The final body is picked: the colony crawls out of the sea, then the
## stage is complete.
func _haul_out() -> void:
	get_tree().paused = false
	pilot.haul_out()
	hud.flash_message("Your colony hauls itself out onto the sand", HAUL_TIME)
	await get_tree().create_timer(HAUL_TIME).timeout
	stage_finished.emit()


func _spawn(at: Vector2) -> void:
	pilot.tint = director.genome.color()
	pilot.nucleus = VisualParts.diet_color(director.genome)
	pilot.spawn(plan, at, CellEffects.max_energy(plan) * START_ENERGY)
	if not pilot.shallows.active and plan.parts.size() >= Shallows.APPEAR_AT:
		pilot.shallows.place(at)
		hud.flash_message("The sea grows shallow to the north. A shore lies ahead", 4.0)
