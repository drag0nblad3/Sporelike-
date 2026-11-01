class_name FoodPatch
extends RefCounted
## One circle of sea floor where a single FoodKind grows.

var kind_id := ""
var center := Vector2.ZERO
var radius := 5.0


static func make(id: String, at: Vector2, r: float) -> FoodPatch:
	var patch := FoodPatch.new()
	patch.kind_id = id
	patch.center = at
	patch.radius = r
	return patch


## A uniformly random point inside the patch.
func random_point(rng: RandomNumberGenerator) -> Vector2:
	return center + Vector2.from_angle(rng.randf() * TAU) * radius * sqrt(rng.randf())


## Pulls a point that drifted out of the patch back to its edge.
func keep_inside(p: Vector2) -> Vector2:
	var offset := p - center
	if offset.length() <= radius:
		return p
	return center + offset.normalized() * radius
