class_name ColonySwim
extends RefCounted
## How a colony swims: every cell adds push (cilia on skin, whips on
## flagellated cells, a little from the rest), scaled by its FeedingStyle,
## FinalBody and any Surge, and it turns at a rate its symmetry allows.

## Swimming push per unit of cell push, shared over the whole body.
const SWIM_FORCE := 17.0
## How much each kind of cell helps swimming.
const PUSH := {"skin": 1.0, "flagellum": 3.0}
const OTHER_PUSH := 0.3


## Average push per cell, before any multipliers.
static func cell_average(plan: BodyPlan) -> float:
	var sum := 0.0
	for part in plan.parts:
		sum += float(PUSH.get(part.role, OTHER_PUSH))
	return sum / float(maxi(plan.parts.size(), 1))


static func push(colony: Colony) -> float:
	var plan := colony.plan
	var surge := ColonyAbility.surge_push(plan) if colony.surge_time > 0.0 else 1.0
	return SWIM_FORCE * cell_average(plan) * FeedingStyle.swim_factor(plan.style) \
		* FinalBody.swim_factor(plan.final_body) * Depth.swim_factor(colony.layer) * surge


## Most of the push is shared by the whole body; the rest comes from the
## cells that do the swimming, so a flagellum tail drives and flexes the
## body, and its whips shove it side to side as they beat.
static func stroke(colony: Colony, dir: Vector3, time: float) -> void:
	var total := push(colony)
	if dir == Vector3.ZERO or total <= 0.0:
		return
	var plan := colony.plan
	var average := cell_average(plan)
	var side := dir.cross(Vector3.UP)
	for i in plan.parts.size():
		var role := plan.parts[i].role
		var share := float(PUSH.get(role, OTHER_PUSH)) / average
		var a := dir * total * (0.6 + 0.4 * share)
		if role == "flagellum":
			a += side * sin(time * 9.0 + i) * total * 0.5
		colony.body.push(i, a)


## Moves the colony's height toward its chosen Depth.
static func rise(colony: Colony, delta: float) -> void:
	colony.height = move_toward(colony.height, Depth.height(colony.layer), Depth.SPEED * delta)
	colony.body.height = colony.height


## Whether the colony is settled at `layer` (not passing through it).
static func at_layer(colony: Colony, layer: int) -> bool:
	return Depth.level(colony.height, Depth.height(layer))


## Radians per second; bigger bodies turn slower, radial ones never need to.
static func turn_rate(plan: BodyPlan) -> float:
	if plan.symmetry == Symmetry.RADIAL:
		return 0.0
	var rate := 3.6 if plan.symmetry == Symmetry.BILATERAL else 2.5
	return rate * sqrt(16.0 / maxf(plan.parts.size(), 16.0))


## The colony's new facing after turning toward `dir` for `delta` seconds.
static func turn(colony: Colony, dir: Vector3, delta: float) -> float:
	var target := atan2(dir.x, dir.z)
	# A biradial body has two fronts, so it turns whichever end is closer.
	if colony.plan.symmetry == Symmetry.BIRADIAL \
			and absf(angle_difference(colony.facing, target)) > PI / 2.0:
		target += PI
	return rotate_toward(colony.facing, target, turn_rate(colony.plan) * delta)
