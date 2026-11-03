class_name ColonyPilot
extends Node
## Steers the player's colony in the main game. It handles steering from
## the joystick, the camera and the energy bar. It feeds the colony on
## world food, on single cells small enough to swallow, and on seaweed
## buds, and it reports each meal and when the colony starves.

signal ate(energy: float)
signal starved

## Single cells up to this radius fit through a colony's mouth.
const PREY_RADIUS := 1.4
## Extra energy for swallowing a whole cell, on top of what it carried.
const PREY_BONUS := 3.0
## How far past a mouth cell's centre it can take in food.
const MOUTH_REACH := 0.7

var ecosystem: Ecosystem
var camera: CameraRig
var hud: Hud
var colony: Colony
var bed := SeaweedBed.new()
## When not zero, steers instead of the player (the screenshot tour).
var autopilot := Vector2.ZERO
## The species' colour, carried over from its single-celled days.
var tint := Color(0.55, 0.9, 0.8)
var _starved := false


func _ready() -> void:
	add_child(bed)


func spawn(plan: BodyPlan, at: Vector2, energy: float) -> void:
	retire()
	colony = Colony.new()
	colony.tint = tint
	colony.build(plan, Vector3(at.x, 0.0, at.y))
	colony.energy = minf(energy, colony.max_energy())
	colony.limbs.food_finder = bed.nearest_food
	add_child(colony)
	_starved = false
	bed.plant_around(colony.center())
	camera.snap_to(colony.center())
	hud.show_jet(false, false)


func retire() -> void:
	if is_instance_valid(colony):
		colony.queue_free()
	colony = null


func is_alive() -> bool:
	return is_instance_valid(colony) and not _starved


func flat_center() -> Vector2:
	if not is_instance_valid(colony):
		return Vector2.ZERO
	var c := colony.center()
	return Vector2(c.x, c.z)


func _physics_process(_delta: float) -> void:
	if not is_alive():
		return
	colony.move_input = autopilot if autopilot != Vector2.ZERO else TouchSteer.read(hud.joystick)
	bed.follow(colony.center())
	var meal := bed.touch(colony) + _eat_world()
	if meal > 0.0:
		colony.feed(meal)
		ate.emit(meal * colony.digest_share())
	if colony.energy <= 0.0:
		_starved = true
		colony.move_input = Vector2.ZERO
		starved.emit()


func _process(delta: float) -> void:
	if not is_instance_valid(colony):
		return
	camera.follow(colony.center(), colony.reach() * 0.6, delta)
	hud.show_status(colony.energy, colony.max_energy(), colony.max_energy())


## Food and small cells touching any mouth cell or tentacle tip.
func _eat_world() -> float:
	var gained := 0.0
	var prey := ecosystem.prey_list()
	for point in colony.eat_points():
		var at := Vector2(point.x, point.z)
		gained += ecosystem.food.take_near(at, MOUTH_REACH)
		for org in prey:
			if not org.alive or org.radius() > PREY_RADIUS:
				continue
			if org.flat_pos().distance_to(at) <= org.radius() + MOUTH_REACH:
				gained += maxf(org.energy, 0.0) + PREY_BONUS
				org.die("eaten")
	return gained
