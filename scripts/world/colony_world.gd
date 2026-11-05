class_name ColonyWorld
extends Node3D
## The multicellular stage's surroundings, which follow the colony and
## change with the sea region it is in: rooted plants (SeaweedBed,
## PlantKind), drifting marine snow, rock outcrops and vent chimneys
## (RockField), and the remains of dead colonies (Carrion).

const MAX_CARRION := 4

var bed := SeaweedBed.new()
var snow := MarineSnow.new()
var rocks := RockField.new()
var rng := RandomNumberGenerator.new()
var carrion: Array[Carrion] = []


func _ready() -> void:
	add_child(bed)
	add_child(snow)
	add_child(rocks)


func spread_around(center: Vector3) -> void:
	bed.plant_around(center)
	snow.scatter(center)
	rocks.scatter(center)
	for heap in carrion:
		heap.queue_free()
	carrion.clear()


func follow(center: Vector3) -> void:
	bed.follow(center)
	snow.follow(center)
	rocks.follow(center)
	for heap in carrion.duplicate():
		if heap.is_gone() or heap.center.distance_to(center) > SeaweedBed.DROP:
			carrion.erase(heap)
			heap.queue_free()


## Everything the colony's mouths reach this frame, weighed by its
## FeedingStyle, plus vent heat over `delta`. Also keeps it out of rocks.
func feed(colony: Colony, delta: float) -> float:
	rocks.push_out(colony)
	var style := colony.plan.style
	var points := colony.eat_points()
	var gained := bed.touch(colony) * FeedingStyle.seaweed_factor(style)
	gained += snow.eat(points, FeedingStyle.mouth_reach(style))
	for heap in carrion:
		gained += heap.bite(points) * FeedingStyle.carrion_factor(style)
	return gained + rocks.heat(colony) * delta


func drop_carrion(at: Vector3, cells: int) -> void:
	if carrion.size() >= MAX_CARRION:
		var oldest: Carrion = carrion.pop_front()
		oldest.queue_free()
	var heap := Carrion.new()
	add_child(heap)
	heap.lay(at, cells, rng)
	carrion.append(heap)
