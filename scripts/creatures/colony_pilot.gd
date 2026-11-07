class_name ColonyPilot
extends Node
## Steers the player's colony in the main game: steering from the joystick,
## the camera, the energy bar, the ability buttons and the edge-of-screen
## senses. It feeds the colony (ColonyFeeding), lets hunters and rival
## colonies bite it (ColonyThreat, RivalColonies), and reports each meal and
## when the colony starves or is eaten.

signal ate(energy: float)
signal starved
signal eaten

var ecosystem: Ecosystem
var camera: CameraRig
var hud: Hud
var colony: Colony
var world := ColonyWorld.new()
var rivals := RivalColonies.new()
var shallows := Shallows.new()
## Crawling out onto the beach at the end of the stage, beyond harm.
var hauling := false
var rng := RandomNumberGenerator.new()
## When not zero, steers instead of the player (the screenshot tour).
var autopilot := Vector2.ZERO
## The species' colour, carried over from its single-celled days.
var tint := Color(0.55, 0.9, 0.8, 0.6)
var nucleus := Color(0.3, 0.85, 0.35)
## CI: swims up and down through every depth on its own.
var smoke_test := false
var _dead := false
var _cues := SenseCues.new()
var _region := RegionNotice.new()
var _smoke_timer := 0.0


func _ready() -> void:
	add_child(world)
	rivals.ecosystem = ecosystem
	rivals.world = world
	add_child(rivals)
	add_child(shallows)
	hud.add_child(_cues)
	hud.ability_pressed.connect(use)
	hud.depth_pressed.connect(change_depth)


## Brings `plan` to life. The colony plays with its own copy, so cells
## bitten off in play never touch the species' saved body plan.
func spawn(plan: BodyPlan, at: Vector2, energy: float) -> void:
	retire()
	colony = Colony.new()
	colony.tint = tint
	colony.nucleus = nucleus
	colony.build(plan.copy(), Vector3(at.x, 0.0, at.y))
	colony.energy = minf(energy, colony.max_energy())
	colony.limbs.food_finder = world.nearest_food
	add_child(colony)
	_dead = false
	hauling = false
	world.spread_around(colony.center())
	camera.snap_to(colony.center())
	hud.hide_abilities()


func retire() -> void:
	if is_instance_valid(colony):
		colony.queue_free()
	colony = null
	rivals.clear()
	_cues.clear()


func is_alive() -> bool:
	return is_instance_valid(colony) and not _dead


func flat_center() -> Vector2:
	if not is_instance_valid(colony):
		return Vector2.ZERO
	var c := colony.center()
	return Vector2(c.x, c.z)


func use(id: String) -> void:
	if is_alive() and id in ColonyAbility.ALL:
		ColonyCaster.fire(colony, id, ecosystem, rivals.rivals)


## The stage is over: crawl inland out of the water.
func haul_out() -> void:
	hauling = true
	autopilot = shallows.line.inland if shallows.active else Vector2(0.0, -1.0)


## Rise (+1) or sink (-1) one Depth.
func change_depth(step: int) -> void:
	if is_alive():
		colony.layer = clampi(colony.layer + step, Depth.FLOOR, Depth.SURFACE)


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	colony.move_input = autopilot if autopilot != Vector2.ZERO else TouchSteer.read(hud.joystick)
	world.follow(colony.center())
	var shore_meal := shallows.step(colony, rivals.rivals, hauling, delta)
	if hauling:
		return
	var fight := rivals.step(colony, delta)
	if smoke_test:
		_smoke_timer += delta
		colony.layer = int(_smoke_timer / 2.0) % 3
	var on_floor := ColonySwim.at_layer(colony, Depth.FLOOR)
	var meal := world.feed(colony, delta) + float(fight[0]) + shore_meal
	if on_floor:
		meal += ColonyFeeding.eat(colony, ecosystem)
	if meal > 0.0:
		colony.feed(meal)
		ate.emit(meal * colony.digest_share())
	if on_floor:
		var hidden := world.rocks.sheltered(colony) or shallows.sheltered(colony)
		var sight := RockField.SHELTER_SIGHT if hidden else 1.0
		_report(ColonyThreat.hunt(ecosystem, colony, rng, sight))
	var dive := world.jellies.step(colony, delta)
	_report(str(dive[0]))
	if bool(dive[1]):
		hud.flash_message("A comb jelly is diving at you! Sink to the floor", 2.0)
	_report(str(fight[1]))
	if colony.wounds.is_fatal(colony):
		_die(eaten)
	elif colony.energy <= 0.0:
		_die(starved)


func _process(delta: float) -> void:
	if not is_instance_valid(colony):
		return
	var eyes := CellEffects.sense_reach(colony.plan)
	camera.follow(colony.center(), colony.reach() * 0.6 + eyes * 0.05, delta)
	hud.show_status(colony.energy, colony.max_energy(), colony.max_energy())
	if is_alive():
		_region.check(flat_center(), hud, delta)
		hud.show_colony_abilities(colony.plan, colony.abilities)
		hud.show_depth(colony.layer)
		_cues.track_reach(eyes, false, ecosystem, camera, delta)


func _report(outcome: String) -> void:
	match outcome:
		ColonyWounds.BITTEN:
			hud.flash_message("A cell was bitten off! It regrows in %d s" % ColonyWounds.REGROW_TIME, 1.5)
		ColonyWounds.STUNG:
			hud.flash_message("Your stinging cells stunned the biter!", 1.5)


func _die(why: Signal) -> void:
	_dead = true
	colony.move_input = Vector2.ZERO
	hud.hide_abilities()
	_cues.clear()
	why.emit()
