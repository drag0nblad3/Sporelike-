class_name VillageLab
extends Node3D
## Stage 4: a small village of the animal designed in stage 3. The player
## walks the elder (an Animal, with the ChaseCamera) or switches to the
## OverheadCamera to give broad orders (VillageHud). Owns the Village, the
## LandCrowd that moves and draws everyone, prey, the rival tribe, raids
## and the generation clock; VillageEvents handles what happens between
## them. Opened by the title's Test stage 4 or by founding a village at
## the end of stage 3 (start_* say who and where). Runs are throwaway for
## now: gene points are shown, not banked.

signal back_requested
signal new_valley_requested

const GENERATION := 240.0

## Set these before adding the lab to the tree.
var start_body: AnimalBody
var start_recipe: AnimalRecipe
var start_at := Vector3.INF
var start_people := 5
## Not zero: reshape the land with this seed (a new valley).
var valley_seed := 0
var throwaway := true
## Not zero: makes the run repeat exactly (CI).
var seed_value := 0

var animal: Animal
var camera := ChaseCamera.new()
var overhead := OverheadCamera.new()
var hud := VillageHud.new()
var crowd := LandCrowd.new()
var village := Village.new()
var food := LandFood.new()
var prey := VillagePrey.new()
var rival := RivalTribe.new()
var raids := VillageRaids.new()
var generations := LandGenerations.new()
var run := VillageRun.new()
var aura := ElderAura.new()
var events := VillageEvents.new()
var rng := RandomNumberGenerator.new()
## Steers instead of the player when not zero (CI and the screenshot tour).
var autopilot := Vector2.ZERO
## True while a screen is up (evolving, or the run has ended).
var paused := false
var _env: Environment
var _status_wait := 0.0


func _ready() -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	food.rng.seed = rng.randi()
	if valley_seed != 0:
		LandHeight.use_seed(valley_seed)
	_env = AnimalLab.environment()
	var world := WorldEnvironment.new()
	world.environment = _env
	add_child(world)
	add_child(AnimalLab.sun())
	add_child(LandTerrain.new())
	add_child(LandScatter.new())
	add_child(food)
	if start_recipe == null:
		start_recipe = AnimalRecipe.new()
		start_recipe.roll(rng)
		start_body = AnimalBuilder.build(start_recipe)
	add_child(village)
	village.food = food
	village.found(VillageSite.pick() if start_at == Vector3.INF else start_at, start_body,
		start_people)
	var nest := LandNest.new()
	nest.position = village.center
	add_child(nest)
	prey.setup(village.center, rng)
	rival.setup(village.center, rng.randi())
	raids.rng.seed = rng.randi()
	raids.plan(1)
	village.prey = prey.actors
	village.foes = raids.actors
	village.rivals = rival.actors
	generations.length = GENERATION
	generations.time_left = GENERATION
	for part: Node in [prey, rival, raids, generations, crowd, aura, camera, overhead, hud, events]:
		add_child(part)
	crowd.add_group(village.villagers)
	crowd.add_group(prey.actors)
	crowd.add_group(raids.actors)
	crowd.add_group(rival.actors)
	overhead.frame(village.center)
	hud.editor.recipe = start_recipe
	hud.editor.unlocks.unlock_all()
	events.wire(self)
	set_body(start_body, village.center)


## Puts `body` on the elder at `spot`.
func set_body(body: AnimalBody, spot: Vector3) -> void:
	var heading := 0.0
	if is_instance_valid(animal):
		heading = animal.heading
		animal.queue_free()
	animal = Animal.new()
	animal.heading = heading
	animal.build(body, spot)
	add_child(animal)
	camera.snap(animal.focus(), heading)


## Swaps between walking as the elder and the overhead view.
func set_overhead(on: bool) -> void:
	hud.set_overhead(on)
	crowd.set_overhead(on)
	_env.fog_density = 0.003 if on else 0.012
	if on:
		overhead.make_current()
	else:
		camera.make_current()


func _physics_process(delta: float) -> void:
	tick(delta)


## One step of the whole village (also driven by CI).
func tick(delta: float) -> void:
	if paused or not is_instance_valid(animal):
		return
	var stick := autopilot if autopilot != Vector2.ZERO else hud.steering()
	var ahead := camera.flat_forward()
	var dir := ahead.cross(Vector3.UP) * stick.x - ahead * stick.y
	animal.move_input = Vector2(dir.x, dir.z)
	ElderActions.step(village, animal, delta)
	food.step(animal, delta)
	village.step(delta)
	prey.step(delta)
	rival.step(delta, village)
	raids.step(delta, 1.0 - generations.time_left / generations.length, generations.length,
		village, rival)
	crowd.step(animal.focus(), delta)
	events.step(delta)


func _process(delta: float) -> void:
	if not is_instance_valid(animal):
		return
	camera.showcase = hud.editor.visible
	if not hud.overhead:
		camera.follow(animal.focus(), animal.heading, animal.body.radii[0], delta)
	aura.set_reach(village.traits.aura)
	aura.follow(village.elder.pos, village.elder.alive and not paused)
	aura.show_flag(village.flag)
	_status_wait -= delta
	if _status_wait <= 0.0:
		_status_wait = 0.25
		hud.show_status(VillageStatus.text(self))
		hud.show_rally(events.rally_wait)
		if hud.overhead:
			hud.panel.refresh(village)
