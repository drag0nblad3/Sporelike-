class_name CellPlacement
extends RefCounted
## Decides where a new cell of each kind grows on a body plan: movers at the
## back (or the rim, for bodies without a back), eyes at the front, plates
## on the flanks, digesting cells against the gut cavity, mouth cells by the
## mouth, and everything else wherever keeps the body a compact lump.


## The best open spot for `role`, or Vector2.INF when there is none.
static func best_spot(plan: BodyPlan, role: String) -> Vector2:
	var best := Vector2.INF
	var best_score := -INF
	for spot in plan.open_spots():
		if _in_mouth_path(plan, spot):
			continue
		var score := _score(plan, role, spot)
		if score > best_score + 0.0001:
			best_score = score
			best = spot
	return best


static func _score(plan: BodyPlan, role: String, spot: Vector2) -> float:
	var r := spot.length()
	var fronted := plan.symmetry == Symmetry.BILATERAL
	# Spots touching more cells keep the body a compact lump, and a small
	# nudge toward the midline lets a bilateral body add 1 cell there
	# instead of 2 when the spots are otherwise equal.
	var base := 0.8 * _neighbours(plan, spot) - 0.01 * absf(spot.x)
	match role:
		"flagellum":
			return base + (-2.0 * spot.y if fronted else -0.5 * r)
		"eye":
			return base + (2.0 * spot.y if fronted else -0.5 * r)
		"plate":
			return base + 1.5 * absf(spot.x) - 0.5 * r
		"gut":
			return base - 3.0 * _nearest(spot, plan.hollow) - 0.2 * r
		"mouth":
			return base - _nearest(spot, _spots_of(plan, "mouth")) - 0.3 * r
	return base - r


static func _neighbours(plan: BodyPlan, spot: Vector2) -> int:
	var n := 0
	for part in plan.parts:
		if part.offset.distance_to(spot) < BodyPlan.SPACING * 1.1:
			n += 1
	return n


## Keeps the way into the mouth clear: nothing grows on the midline in front
## of a bilateral mouth, or in front of or behind a biradial one.
static func _in_mouth_path(plan: BodyPlan, spot: Vector2) -> bool:
	if absf(spot.x) > 0.1:
		return false
	match plan.symmetry:
		Symmetry.BILATERAL:
			return spot.y > 0.0
		Symmetry.BIRADIAL:
			return true
	return false


static func _spots_of(plan: BodyPlan, role: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for part in plan.parts:
		if part.role == role:
			out.append(part.offset)
	return out


static func _nearest(spot: Vector2, others: Array[Vector2]) -> float:
	var best := INF
	for other in others:
		best = minf(best, spot.distance_to(other))
	return best if best < INF else 0.0
