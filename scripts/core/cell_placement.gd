class_name CellPlacement
extends RefCounted
## Decides where a new cell grows, the way an embryo would rather than by
## stacking. Every new cell touches at least two others, and the body stays
## a rounded lump. Each job has its zone: on a bilateral body, movers sit at
## the back, eyespots at the front corners, stinging cells beside the mouth
## and plates on the flanks. Inner jobs (digestive and storage cells) take
## over a skin cell inside the body and push a fresh skin cell out, so the
## gut grows around the cavity. Outer jobs may also take over a skin cell on
## the surface, which keeps the outline smooth. New skin never covers an
## outer cell, since eyes and whips must touch the water.

## Cells that must face open water.
const SURFACE := ["flagellum", "eye", "plate", "gland"]
## Angle from straight ahead (radians) each outer job prefers on a
## bilateral body, and on a biradial body measured from the nearer end.
const BILATERAL_ZONES := {"flagellum": PI, "eye": 0.85, "plate": 1.8, "gland": 1.15}
const BIRADIAL_ZONES := {"flagellum": PI / 2.0, "eye": 0.6, "plate": PI / 2.0, "gland": 0.6}


## [spot, takes_over_skin] for the best place to grow `role`, or [] when
## there is no room.
static func choose(plan: BodyPlan, role: String) -> Array:
	var center := _centroid(plan)
	var best: Array = []
	var best_score := -INF
	for spot in plan.open_spots():
		if _in_mouth_path(plan, spot) or _neighbours(plan, spot) < 2:
			continue
		var score := _open_score(plan, spot, center) + _job_score(plan, role, spot, center, false)
		if score > best_score + 0.0001:
			best_score = score
			best = [spot, false]
	if role == "skin":
		return best
	for part in plan.parts:
		if part.role != "skin" or (role in SURFACE and not _on_surface(plan, part.offset)):
			continue
		var score := 0.5 + _job_score(plan, role, part.offset, center, true)
		if score > best_score + 0.0001:
			best_score = score
			best = [part.offset, true]
	return best


## Compact growth: touching more cells, nearer the middle, and not covering
## a cell that needs open water.
static func _open_score(plan: BodyPlan, spot: Vector2, center: Vector2) -> float:
	var covered := 0
	for part in plan.parts:
		if part.role in SURFACE and part.offset.distance_to(spot) < BodyPlan.SPACING * 1.1:
			covered += 1
	return 1.2 * _neighbours(plan, spot) - 0.6 * spot.distance_to(center) - 0.7 * covered


static func _job_score(plan: BodyPlan, role: String, spot: Vector2, center: Vector2,
		takes_over: bool) -> float:
	# A small nudge toward the midline lets a bilateral body add 1 cell
	# there instead of 2 when spots are otherwise equal.
	var score := -0.01 * absf(spot.x)
	match role:
		"gut":
			score -= 2.0 * _nearest(spot, plan.hollow)
		"storage":
			score -= spot.distance_to(center) - (1.0 if takes_over else 0.0)
		"mouth":
			var openings := _spots_of(plan, "mouth")
			openings.append_array(plan.hollow.slice(1))
			score -= 2.0 * _nearest(spot, openings)
		_:
			score += _zone(plan, role, spot)
	return score


## How well a spot's direction from the middle suits an outer job.
static func _zone(plan: BodyPlan, role: String, spot: Vector2) -> float:
	var angle := absf(atan2(spot.x, spot.y))
	var zones := BILATERAL_ZONES
	match plan.symmetry:
		Symmetry.RADIAL:
			return 0.0
		Symmetry.BIRADIAL:
			angle = minf(angle, PI - angle)
			zones = BIRADIAL_ZONES
	if not zones.has(role):
		return 0.0
	return 2.0 * cos(angle - float(zones[role]))


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


static func _on_surface(plan: BodyPlan, spot: Vector2) -> bool:
	for item in BodyPlan.DIRS:
		var dir: Vector2 = item
		if not plan.is_taken(spot + dir * BodyPlan.SPACING):
			return true
	return false


static func _centroid(plan: BodyPlan) -> Vector2:
	var sum := Vector2.ZERO
	for part in plan.parts:
		sum += part.offset
	return sum / float(maxi(plan.parts.size(), 1))


static func _neighbours(plan: BodyPlan, spot: Vector2) -> int:
	var n := 0
	for part in plan.parts:
		if part.offset.distance_to(spot) < BodyPlan.SPACING * 1.1:
			n += 1
	return n


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
