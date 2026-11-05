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
var rng := RandomNumberGenerator.new()
## When not zero, steers instead of the player (the screenshot tour).
var autopilot := Vector2.ZERO
## The species' colour, carried over from its single-celled days.
var tint := Color(0.55, 0.9, 0.8, 0.6)
var nucleus := Color(0.3, 0.85, 0.35)
var _dead := false
var _cues := SenseCues.new()
var _sea_id := ""
var _sea_timer := 0.0


func _ready() -> void:
	add_child(world)
	rivals.ecosystem = ecosystem
	rivals.world = world
	add_child(rivals)
	hud.add_child(_cues)
	hud.ability_pressed.connect(use)


## Brings `plan` to life. The colony plays with its own copy, so cells
## bitten off in play never touch the species' saved body plan.
func spawn(plan: BodyPlan, at: Vector2, energy: float) -> void:
	retire()
	colony = Colony.new()
	colony.tint = tint
	colony.nucleus = nucleus
	colony.build(plan.copy(), Vector3(at.x, 0.0, at.y))
	colony.energy = minf(energy, colony.max_energy())
	colony.limbs.food_finder = world.bed.nearest_food
	add_child(colony)
	_dead = false
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


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	colony.move_input = autopilot if autopilot != Vector2.ZERO else TouchSteer.read(hud.joystick)
	world.follow(colony.center())
	var fight := rivals.step(colony, delta)
	var meal := world.feed(colony, delta) + ColonyFeeding.eat(colony, ecosystem) + float(fight[0])
	if meal > 0.0:
		colony.feed(meal)
		ate.emit(meal * colony.digest_share())
	var sight := RockField.SHELTER_SIGHT if world.rocks.sheltered(colony) else 1.0
	_report(ColonyThreat.hunt(ecosystem, colony, rng, sight))
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
		_note_region(delta)
		hud.show_colony_abilities(colony.plan, colony.abilities)
		_cues.track_reach(eyes, false, ecosystem, camera, delta)


## Names the sea region and what grows there whenever the colony enters a new one.
func _note_region(delta: float) -> void:
	_sea_timer -= delta
	if _sea_timer > 0.0:
		return
	_sea_timer = 1.0
	var sea := SeaMap.at(flat_center())
	if sea.id == _sea_id:
		return
	var first := _sea_id == ""
	_sea_id = sea.id
	if not first:
		hud.flash_message("%s: %s" % [sea.title, PlantKind.for_sea(sea.id).title.to_lower()], 3.0)


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
