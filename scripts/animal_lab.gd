class_name AnimalLab
extends Node3D
## Stage 3: one land animal on hilly ground (LandTerrain,
## LandScatter) under an open sky with haze, the ChaseCamera, the joystick
## and look pad, New body for a random AnimalBody, the body customizer
## (AnimalEditor, built by AnimalBuilder) and the land goals (LandGoals:
## food, nest and eggs, landmarks that unlock parts) and LandGenerations:
## when a generation's clock runs out, the eggs become changes in the
## customizer and the new body hatches at the nest, with kin (LandFamily)
## who follow the player; with enough kin a village can be founded, which
## starts stage 4. AnimalLabEvents handles what happens between the parts
## (generations, grazers, the egg thief, sounds, tips). Part of a run when
## `run` is set (the body and progress come from it and are saved);
## otherwise the title's Test stage 3, with New body and Free edit.

signal back_requested
## The player founded a village at the nest: stage 4 starts (VillageLab).
signal village_founded(body: AnimalBody, recipe: AnimalRecipe, at: Vector3, kin: int)

const SKY := Color(0.62, 0.77, 0.88)

var animal: Animal
var camera := ChaseCamera.new()
var hud := AnimalLabHud.new()
var goals := LandGoals.new()
var generations := LandGenerations.new()
var family := LandFamily.new()
var events := AnimalLabEvents.new()
## The run this stage is part of, or null for the test lab.
var run: LandRun
var rng := RandomNumberGenerator.new()
## When not zero, steers instead of the player, in screen terms like the
## joystick (the screenshot tour).
var autopilot := Vector2.ZERO


func _ready() -> void:
	rng.randomize()
	var world := WorldEnvironment.new()
	world.environment = environment()
	add_child(world)
	add_child(sun())
	add_child(LandTerrain.new())
	add_child(LandScatter.new())
	add_child(goals)
	add_child(generations)
	add_child(family)
	family.notice.connect(func(text: String) -> void: hud.flash(text))
	hud.call_pressed.connect(family.call_kin)
	hud.found_pressed.connect(func() -> void:
		village_founded.emit(animal.body, hud.editor.recipe, goals.nest.position, family.kin.size()))
	goals.notice.connect(func(text: String) -> void: hud.flash(text))
	hud.editor.unlocks = goals.unlocks
	hud.nest_pressed.connect(func() -> void:
		if is_instance_valid(animal):
			goals.nest_here(animal))
	add_child(camera)
	add_child(hud)
	hud.look.dragged.connect(camera.drag)
	hud.new_body_pressed.connect(new_body)
	hud.recipe_changed.connect(func(recipe: AnimalRecipe) -> void:
		set_body(AnimalBuilder.build(recipe)))
	hud.back_pressed.connect(func() -> void: back_requested.emit())
	if run != null:
		_start_run()
	else:
		new_body()
	add_child(events)
	events.wire(self)


## Picks the run up where it stands: its body, unlocked parts and kin.
func _start_run() -> void:
	hud.set_run(run.subspecies)
	hud.editor.recipe = run.recipe
	for id in run.unlocked:
		goals.unlocks.unlock(id)
	generations.number = run.generation
	set_body(AnimalBuilder.build(run.recipe), goals.nest.position)
	family.hatch(run.kin * 2, animal.body, goals.nest.position)


## Swaps in a fresh random body where the animal stands.
func new_body() -> void:
	set_body(AnimalRandom.make(rng))


## Puts `body` on where the animal stands, or at `spot` when given.
func set_body(body: AnimalBody, spot := Vector3.INF) -> void:
	var at := Vector3.ZERO if spot == Vector3.INF else spot
	var heading := 0.0
	if is_instance_valid(animal):
		if spot == Vector3.INF:
			at = animal.head()
		heading = animal.heading
		animal.queue_free()
	animal = Animal.new()
	animal.heading = heading
	animal.build(body, at)
	add_child(animal)
	camera.snap(animal.focus(), heading)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(animal):
		return
	var stick := autopilot if autopilot != Vector2.ZERO else hud.steering()
	# Up on the stick walks the way the camera looks.
	var ahead := camera.flat_forward()
	var right := ahead.cross(Vector3.UP)
	var dir := right * stick.x - ahead * stick.y
	animal.move_input = Vector2(dir.x, dir.z)
	goals.step(animal, delta)
	family.step(animal, delta)
	events.step(delta)


func _process(delta: float) -> void:
	if not is_instance_valid(animal):
		return
	camera.showcase = hud.editor.visible
	camera.follow(animal.focus(), animal.heading, animal.body.radii[0], delta)
	hud.show_status(animal.body, "%s\n%s  ·  Kin %d/%d\n%s" % [events.powers.text(),
		generations.text(), family.kin.size(), LandFamily.FOUND,
		goals.status_text(animal.focus())])
	hud.show_found(family.ready_to_found(animal.focus(), goals.nest))


## The open sky and haze of the land stages.
static func environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.78, 0.85)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = SKY
	env.fog_density = 0.012
	return env


static func sun() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	light.light_color = Color(1.0, 0.95, 0.85)
	light.light_energy = 1.1
	return light
