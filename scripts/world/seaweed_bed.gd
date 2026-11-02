class_name SeaweedBed
extends Node3D
## A scatter of Seaweed around a colony. In the open sea it replants
## seaweed left far behind somewhere ahead, so there is always some
## nearby. Pushes plants and colony apart where they touch and lets the
## colony's mouths and tentacles graze ripe buds.

const COUNT := 16
const NEAR := 6.0
const FAR := 30.0
## Plants farther than this from the colony are replanted closer.
const DROP := 44.0
## How close a mouth or tentacle tip must get to a bud to eat it.
const BITE_REACH := 0.9
## How far apart colony cells and seaweed cells are kept.
const CONTACT_GAP := 1.0

var plants: Array[Seaweed] = []
## False keeps the plants where they first grew (the colony lab).
var follows := true
var rng := RandomNumberGenerator.new()


func plant_around(center: Vector3, count: int = COUNT) -> void:
	for weed in plants:
		weed.queue_free()
	plants.clear()
	for i in count:
		plants.append(_plant(center, NEAR, FAR))


## Replants seaweed the colony has left far behind.
func follow(center: Vector3) -> void:
	if not follows:
		return
	for k in plants.size():
		if plants[k].body.anchor.distance_to(center) > DROP:
			plants[k].queue_free()
			plants[k] = _plant(center, FAR * 0.6, FAR)


## Shoves seaweed and colony apart and grazes buds. Returns the energy of
## the buds eaten (before the colony digests it).
func touch(colony: Colony) -> float:
	var gained := 0.0
	for weed in plants:
		SoftContact.separate(colony.body, weed.body, CONTACT_GAP)
	for point in colony.eat_points():
		for weed in plants:
			var k := weed.nearest_bud(point, BITE_REACH)
			if k >= 0:
				gained += weed.take_bud(k)
	return gained


## The nearest ripe bud within `reach` of `from`, or Vector3.INF.
func nearest_food(from: Vector3, reach: float) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for weed in plants:
		var k := weed.nearest_bud(from, reach)
		if k >= 0:
			var at := weed.bud_position(k)
			var d := at.distance_squared_to(from)
			if d < best_d:
				best_d = d
				best = at
	return best


func _plant(center: Vector3, low: float, high: float) -> Seaweed:
	var at := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(low, high)
	var weed := Seaweed.new()
	weed.grow_at(center + Vector3(at.x, 0.0, at.y), rng)
	add_child(weed)
	return weed
