class_name StageTwo
extends Node
## The multicellular stage inside Game. It runs the switch from a single
## cell, a symmetry choice once stage 1's goal is reached. It owns the
## player's colony (through ColonyPilot), the cell picks between
## generations, and the colony's part of the save.

## A generation can begin: the switch or this round's pick is done.
signal ready_to_play
signal died(cause: String)

## Share of a full belly a colony starts each generation with.
const START_ENERGY := 0.6

var ecosystem: Ecosystem
var camera: CameraRig
var hud: Hud
var director: PlayerDirector
var rng: RandomNumberGenerator
var smoke_test := false
var active := false
var plan: BodyPlan
var pilot := ColonyPilot.new()

var _picker: SymmetryPicker
var _picks: CellPickScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pilot.ecosystem = ecosystem
	pilot.camera = camera
	pilot.hud = hud
	pilot.process_mode = Node.PROCESS_MODE_PAUSABLE
	pilot.starved.connect(func() -> void: died.emit("starved"))
	add_child(pilot)
	_picks = CellPickScreen.new()
	_picks.chosen.connect(_on_cell_chosen)
	hud.add_child(_picks)


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
	return {"stage": 2, "colony": plan.to_dict(), "colony_energy": energy}


## What the colony burns per second, for the generation's Fed score.
func upkeep() -> float:
	return Colony.UPKEEP_PER_CELL * plan.parts.size()


func center() -> Vector2:
	return pilot.flat_center()


## Between generations: offer three kinds of cell to grow.
func end_generation(stats: GenerationStats) -> void:
	var roles: Array[String] = []
	for role in LabHud.GROWABLE:
		roles.append(role)
	for i in range(roles.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := roles[i]
		roles[i] = roles[j]
		roles[j] = swap
	roles.resize(3)
	if smoke_test:
		_on_cell_chosen.call_deferred(roles[0])
		return
	_picks.open(stats, plan, roles)


func _on_cell_chosen(role: String) -> void:
	_picks.visible = false
	if role != "":
		plan.grow(role)
	_spawn(center())
	ready_to_play.emit()


func _spawn(at: Vector2) -> void:
	pilot.tint = director.genome.color()
	pilot.nucleus = VisualParts.diet_color(director.genome)
	var full := Colony.MAX_ENERGY_PER_CELL * plan.parts.size()
	pilot.spawn(plan, at, full * START_ENERGY)
