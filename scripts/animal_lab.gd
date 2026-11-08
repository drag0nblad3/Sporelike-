class_name AnimalLab
extends Node3D
## The stage 3 feel test: one land animal on hilly ground (LandTerrain,
## LandScatter) under an open sky with haze, the ChaseCamera, the joystick
## and look pad, New body for a random AnimalBody, the body customizer
## (AnimalEditor, built by AnimalBuilder) and the land goals (LandGoals:
## food, nest and eggs, landmarks that unlock parts). Used from the title
## screen's Test stage 3 and by the screenshot tour.

signal back_requested

const SKY := Color(0.62, 0.77, 0.88)

var animal: Animal
var camera := ChaseCamera.new()
var hud := AnimalLabHud.new()
var goals := LandGoals.new()
var rng := RandomNumberGenerator.new()
## When not zero, steers instead of the player, in screen terms like the
## joystick (the screenshot tour).
var autopilot := Vector2.ZERO


func _ready() -> void:
	rng.randomize()
	add_child(_environment())
	add_child(_sun())
	add_child(LandTerrain.new())
	add_child(LandScatter.new())
	add_child(goals)
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
	new_body()


## Swaps in a fresh random body where the animal stands.
func new_body() -> void:
	set_body(AnimalRandom.make(rng))


func set_body(body: AnimalBody) -> void:
	var at := Vector3.ZERO
	var heading := 0.0
	if is_instance_valid(animal):
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


func _process(delta: float) -> void:
	if not is_instance_valid(animal):
		return
	camera.showcase = hud.editor.visible
	camera.follow(animal.focus(), animal.heading, animal.body.radii[0], delta)
	hud.show_status(animal.body, goals.status_text(animal.focus()))


func _environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.78, 0.85)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = SKY
	env.fog_density = 0.012
	var node := WorldEnvironment.new()
	node.environment = env
	return node


func _sun() -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.1
	return sun
