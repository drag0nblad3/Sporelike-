class_name CombJellies
extends Node3D
## Keeps a few comb jellies drifting at the surface around the colony,
## more over the deep and the upwelling coast, and runs their hunt each
## frame. Jellies left far behind drift in again ahead.

const SPAWN_MIN := 18.0
const SPAWN_MAX := 32.0
const DESPAWN := 60.0
## sea id -> how many jellies drift around the colony there.
const COUNT := {"deep": 3, "upwelling": 2, "shelf": 1, "lagoon": 1, "vents": 1}

var rng := RandomNumberGenerator.new()
var jellies: Array[CombJelly] = []


func clear() -> void:
	for jelly in jellies:
		jelly.queue_free()
	jellies.clear()


## Returns [the outcome of a bite on the colony or "", whether any jelly
## started a dive this frame].
func step(colony: Colony, delta: float) -> Array:
	var c := colony.center()
	var center := Vector2(c.x, c.z)
	for jelly: CombJelly in jellies.duplicate():
		if Vector2(jelly.position.x, jelly.position.z).distance_to(center) > DESPAWN:
			jellies.erase(jelly)
			jelly.queue_free()
	var want := int(COUNT.get(SeaMap.at(center).id, 1))
	if jellies.size() < want:
		_spawn(center)
	var outcome := ""
	var dove := false
	for jelly in jellies:
		var was := jelly.diving
		var hit := jelly.hunt(colony, rng, delta)
		if hit != "":
			outcome = hit
		dove = dove or (jelly.diving and not was)
	return [outcome, dove]


func _spawn(center: Vector2) -> void:
	var at := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(SPAWN_MIN, SPAWN_MAX)
	var jelly := CombJelly.new()
	jelly.position = Vector3(at.x, Depth.height(Depth.SURFACE), at.y)
	add_child(jelly)
	jellies.append(jelly)
