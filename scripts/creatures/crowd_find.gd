class_name CrowdFind
extends RefCounted
## Small lookups over lists of CrowdActors: the nearest living one to a
## spot, and a member's place in a ring around a centre.


static func nearest(actors: Array[CrowdActor], at: Vector3, reach: float) -> CrowdActor:
	var best: CrowdActor = null
	var best_d := reach
	for actor in actors:
		if not actor.alive:
			continue
		var d := actor.flat_to(at)
		if d < best_d:
			best_d = d
			best = actor
	return best


## Spot `slot` of a ring of `radius` around `center`, facing `toward`
## (radians) when the ring is only an arc on one side (spread < TAU).
static func ring(center: Vector3, slot: int, radius: float, toward := 0.0,
		spread := TAU) -> Vector3:
	var step := 2.399963 if spread >= TAU else spread / 5.0
	var a := toward + (slot * step if spread >= TAU else (slot % 5 - 2) * step)
	return center + Vector3(sin(a), 0.0, cos(a)) * (radius + (slot / 5) * 1.6)
