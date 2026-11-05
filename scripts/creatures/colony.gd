class_name Colony
extends Node3D
## A multicellular body: a BodyPlan brought to life as a SoftBody. It swims
## where move_input points (ColonySwim), feeds
## through its mouth cells and tentacles, digests better with more gut
## cells (CellEffects), loses cells to bites and regrows them (ColonyWounds),
## and is drawn by ColonyLook with limbs from ColonyLimbs. The node itself
## stays put; its cells move in world space.

## Energy each cell burns per second.
const UPKEEP_PER_CELL := 0.04

var plan: BodyPlan
var body := SoftBody.new()
var limbs := ColonyLimbs.new()
var move_input := Vector2.ZERO
var facing := 0.0
var energy := 20.0
## Membrane colour (the species' colour) and nucleus colour (its diet).
var tint := Color(0.55, 0.9, 0.8, 0.6)
var nucleus := Color(0.3, 0.85, 0.35)
var wounds := ColonyWounds.new()
var abilities := AbilityTimers.new()
## Seconds left of a Surge, of being curled up, and of being stunned.
var surge_time := 0.0
var curl_time := 0.0
var stun_time := 0.0
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


## Energy the body burns per second.
func upkeep() -> float:
	return UPKEEP_PER_CELL * plan.parts.size() * FinalBody.upkeep_factor(plan.final_body)


func max_energy() -> float:
	return CellEffects.max_energy(plan)


## Share of a meal's energy the gut keeps: more digestive cells, more kept,
## up to all of it.
func digest_share() -> float:
	return CellEffects.digest_share(plan)


func cell_flat(index: int) -> Vector2:
	return Vector2(body.pos[index].x, body.pos[index].z)


## The cell closest to `at` on the flat sea.
func nearest_cell(at: Vector2) -> int:
	var best := 0
	var best_d := INF
	for i in body.pos.size():
		var d := at.distance_squared_to(cell_flat(i))
		if d < best_d:
			best_d = d
			best = i
	return best


## Removes a bitten-off cell and reshapes the body; returns the lost cell.
func lose_cell(index: int) -> BodyPart:
	var part := plan.parts[index]
	plan.parts.remove_at(index)
	build(plan, body.center())
	energy = minf(energy, max_energy())
	return part


## Grows a lost cell back in its old spot. False when the spot is taken.
func regain(part: BodyPart) -> bool:
	if plan.is_taken(part.offset):
		return false
	plan.parts.append(part)
	build(plan, body.center())
	return true


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
	return ColonySwim.push(self)


func _physics_process(delta: float) -> void:
	if plan == null:
		return
	surge_time = maxf(surge_time - delta, 0.0)
	curl_time = maxf(curl_time - delta, 0.0)
	stun_time = maxf(stun_time - delta, 0.0)
	abilities.tick(delta)
	wounds.tick(self, delta)
	var dir := Vector3(move_input.x, 0.0, move_input.y).limit_length(1.0)
	if curl_time > 0.0 or stun_time > 0.0:
		dir = Vector3.ZERO
	elif surge_time > 0.0 and dir.length() < 0.1:
		dir = Vector3(sin(facing), 0.0, cos(facing))
	if dir.length() > 0.1:
		facing = ColonySwim.turn(self, dir, delta)
	body.heading = facing
	_time += delta
	ColonySwim.stroke(self, dir, _time)
	body.step(delta)
	energy = maxf(energy - upkeep() * delta, 0.0)


func _process(delta: float) -> void:
	if plan == null:
		return
	_look.update(body, hollow_rest, delta)
	limbs.update(delta)
