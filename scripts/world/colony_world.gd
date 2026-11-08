class_name ColonyWorld
extends Node3D
## The multicellular stage's surroundings, which follow the colony and
## change with the sea region it is in and the Depth it swims at: rooted
## plants (SeaweedBed, PlantKind), rock outcrops and vent chimneys
## (RockField) and the remains of dead colonies (Carrion) on the floor,
## marine snow in open water, and floating rafts and diving comb jellies
## at the surface. Sunlight ripples over the floor (CausticLight).

const MAX_CARRION := 4
const RAFTS := 7

var bed := SeaweedBed.new()
var rafts := SeaweedBed.new()
var jellies := CombJellies.new()
var snow := MarineSnow.new()
var rocks := RockField.new()
var light := CausticLight.new()
var rng := RandomNumberGenerator.new()
var carrion: Array[Carrion] = []


func _ready() -> void:
	add_child(bed)
	rafts.raft = true
	add_child(rafts)
	add_child(jellies)
	add_child(snow)
	add_child(rocks)
	add_child(light)


func spread_around(center: Vector3) -> void:
	bed.plant_around(center)
	rafts.plant_around(center, RAFTS)
	jellies.clear()
	snow.scatter(center)
	rocks.scatter(center)
	light.follow(center, 1.0)
	for heap in carrion:
		heap.queue_free()
	carrion.clear()


func follow(center: Vector3) -> void:
	bed.follow(center)
	rafts.follow(center)
	snow.follow(center)
	rocks.follow(center)
	light.follow(center, get_physics_process_delta_time())
	for heap in carrion.duplicate():
		if heap.is_gone() or heap.center.distance_to(center) > SeaweedBed.DROP:
			carrion.erase(heap)
			heap.queue_free()


## Everything the colony's mouths reach this frame, weighed by its
## FeedingStyle, plus vent heat over `delta`. Also keeps it out of rocks.
## Plants touch by true distance, so they only feed a colony at their depth.
func feed(colony: Colony, delta: float) -> float:
	rocks.push_out(colony)
	var style := colony.plan.style
	var points := colony.eat_points()
	var plants := bed.touch(colony) + rafts.touch(colony)
	var gained := plants * FeedingStyle.seaweed_factor(style)
	if ColonySwim.at_layer(colony, Depth.OPEN):
		gained += snow.eat(points, CellEffects.mouth_reach(colony.plan))
	if ColonySwim.at_layer(colony, Depth.FLOOR):
		for heap in carrion:
			gained += heap.bite(points) * FeedingStyle.carrion_factor(style)
	return gained + rocks.heat(colony) * delta


## The nearest ripe bud on any plant or raft, for tentacles to reach for.
func nearest_food(from: Vector3, reach: float) -> Vector3:
	var a := bed.nearest_food(from, reach)
	var b := rafts.nearest_food(from, reach)
	if a == Vector3.INF or (b != Vector3.INF and from.distance_to(b) < from.distance_to(a)):
		return b
	return a


func drop_carrion(at: Vector3, cells: int) -> void:
	if carrion.size() >= MAX_CARRION:
		var oldest: Carrion = carrion.pop_front()
		oldest.queue_free()
	var heap := Carrion.new()
	add_child(heap)
	heap.lay(at, cells, rng)
	carrion.append(heap)
