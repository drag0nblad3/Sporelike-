class_name Colony
extends Node3D
## A multicellular body: a BodyPlan brought to life as a SoftBody. It swims
## where move_input points (turning at a rate its symmetry allows), feeds
## through its mouth cells and tentacles, digests better with more gut
## cells, and is drawn by ColonyLook with limbs from ColonyLimbs. The node
## itself stays put; its cells move in world space.

## Energy each cell burns per second.
const UPKEEP_PER_CELL := 0.04
const MAX_ENERGY_PER_CELL := 2.0
## Swimming push per unit of cell push, shared over the whole body.
const SWIM_FORCE := 12.0
## How much each kind of cell helps swimming: cilia on skin, whips on
## flagellated cells, a little from everything else.
const PUSH := {"skin": 1.0, "flagellum": 3.0}
const OTHER_PUSH := 0.3

var plan: BodyPlan
var body := SoftBody.new()
var limbs := ColonyLimbs.new()
var move_input := Vector2.ZERO
var facing := 0.0
var energy := 20.0
## Membrane colour (the species' colour) and nucleus colour (its diet).
var tint := Color(0.55, 0.9, 0.8, 0.6)
var nucleus := Color(0.3, 0.85, 0.35)
## Where the gut cavity and mouth openings sit in the resting shape.
var hollow_rest := PackedVector3Array()
var _look := ColonyLook.new()
var _time := 0.0


func _ready() -> void:
	add_child(_look)
	add_child(limbs)
	if plan:
		_look.build(plan, tint, nucleus)


## Lays the plan's cells out around `at`, facing `facing`.
func build(new_plan: BodyPlan, at: Vector3) -> void:
	plan = new_plan
	var centroid := Vector3.ZERO
	for part in plan.parts:
		centroid += part.local_position()
	centroid /= float(maxi(plan.parts.size(), 1))
	body = SoftBody.new()
	body.heading = facing
	# Loose enough to bend, squash and wobble as it swims and bumps things.
	body.steer = 0.2
	body.shape_stiffness = 0.1
	body.spring_stiffness = 0.35
	body.passes = 2
	for part in plan.parts:
		var local := part.local_position() - centroid
		body.add_point(at + local.rotated(Vector3.UP, facing), local)
	body.connect_near(BodyPlan.SPACING * 1.05)
	hollow_rest.clear()
	for spot in plan.hollow:
		hollow_rest.append(Vector3(spot.x, 0.0, spot.y) - centroid)
	if is_inside_tree():
		_look.build(plan, tint, nucleus)
	limbs.build(self)


## Adds a cell of `role` (and its symmetric copies). Returns how many grew.
func grow(role: String) -> int:
	var at := body.center()
	var added := plan.grow(role)
	if added > 0:
		build(plan, at)
	return added


func center() -> Vector3:
	return body.center()


func reach() -> float:
	return body.reach() + 0.6


func max_energy() -> float:
	return MAX_ENERGY_PER_CELL * plan.parts.size()


## Share of a meal's energy the gut keeps: more digestive cells, more kept,
## up to all of it.
func digest_share() -> float:
	return minf(0.55 + 0.06 * plan.count("gut"), 1.0)


func feed(amount: float) -> void:
	energy = minf(energy + amount * digest_share(), max_energy())


## Points that pick up food: mouth cells and tentacle tips.
func eat_points() -> PackedVector3Array:
	var points := limbs.tentacle_tips()
	for i in plan.parts.size():
		if plan.parts[i].role == "mouth":
			points.append(body.pos[i])
	return points


func swim_push() -> float:
	var sum := 0.0
	for part in plan.parts:
		sum += float(PUSH.get(part.role, OTHER_PUSH))
	return SWIM_FORCE * sum / float(maxi(plan.parts.size(), 1))


## Radians per second; bigger bodies turn slower, radial ones never need to.
func turn_rate() -> float:
	if plan.symmetry == Symmetry.RADIAL:
		return 0.0
	var rate := 2.6 if plan.symmetry == Symmetry.BILATERAL else 1.8
	return rate * sqrt(16.0 / maxf(plan.parts.size(), 16.0))


func _physics_process(delta: float) -> void:
	if plan == null:
		return
	var dir := Vector3(move_input.x, 0.0, move_input.y).limit_length(1.0)
	if dir.length() > 0.1:
		_turn_toward(dir, delta)
	body.heading = facing
	_swim(dir, delta)
	body.step(delta)
	energy = maxf(energy - UPKEEP_PER_CELL * plan.parts.size() * delta, 0.0)


func _process(delta: float) -> void:
	if plan == null:
		return
	_look.update(body, hollow_rest, delta)
	limbs.update(delta)


## Most of the push is shared by the whole body; the rest comes from the
## cells that do the swimming, so a flagellum tail drives and flexes the
## body, and its whips shove it side to side as they beat.
func _swim(dir: Vector3, delta: float) -> void:
	_time += delta
	var push := swim_push()
	if dir == Vector3.ZERO or push <= 0.0:
		return
	var average := push / SWIM_FORCE
	var side := dir.cross(Vector3.UP)
	for i in plan.parts.size():
		var role := plan.parts[i].role
		var share := float(PUSH.get(role, OTHER_PUSH)) / average
		var a := dir * push * (0.6 + 0.4 * share)
		if role == "flagellum":
			a += side * sin(_time * 9.0 + i) * push * 0.5
		body.push(i, a)


func _turn_toward(dir: Vector3, delta: float) -> void:
	var target := atan2(dir.x, dir.z)
	# A biradial body has two fronts, so it turns whichever end is closer.
	if plan.symmetry == Symmetry.BIRADIAL and absf(angle_difference(facing, target)) > PI / 2.0:
		target += PI
	facing = rotate_toward(facing, target, turn_rate() * delta)
