class_name RivalColonies
extends Node3D
## Other species that went multicellular too. Keeps a few rival colonies
## around the player's: one smaller, one about the same, one bigger, each
## with its own symmetry, cells and FeedingStyle. They feed, flee and hunt
## (RivalBrain), and bigger colonies bite smaller ones (ColonyBites), the
## player's included. Rivals that die or drift far away are replaced.

const COUNT := 3
const SPAWN_MIN := 22.0
const SPAWN_MAX := 34.0
const DESPAWN := 70.0
## Cells each rival has compared to the player's colony.
const SIZE_STEPS := [-6, 0, 8]
const THINK_EVERY := 0.25
const TINTS := [Color(0.95, 0.6, 0.35, 0.6), Color(0.6, 0.55, 1.0, 0.6),
	Color(0.9, 0.85, 0.4, 0.6)]

var ecosystem: Ecosystem
var world: ColonyWorld
var rng := RandomNumberGenerator.new()
var rivals: Array[Colony] = []
var _think_timer := 0.0


func clear() -> void:
	for rival in rivals:
		if is_instance_valid(rival):
			rival.queue_free()
	rivals.clear()


## Called every physics frame by ColonyPilot. Returns [energy the player
## ate from rivals, outcome of a rival's bite on the player or ""].
func step(player: Colony, delta: float) -> Array:
	_refill(player)
	_think_timer -= delta
	var thinking := _think_timer <= 0.0
	if thinking:
		_think_timer = THINK_EVERY
	var eaten := 0.0
	var hit := ""
	for rival: Colony in rivals.duplicate():
		if thinking:
			RivalBrain.think(rival, player, ecosystem, world.bed)
		_feed(rival)
		var mine := ColonyBites.attempt(player, rival, rng)
		eaten += float(mine[1])
		var theirs := ColonyBites.attempt(rival, player, rng)
		if str(theirs[0]) != "":
			hit = str(theirs[0])
			rival.feed(float(theirs[1]))
		if rival.wounds.is_fatal(rival):
			world.drop_carrion(rival.center(), rival.wounds.full_size(rival))
			_remove(rival)
		elif rival.energy <= 0.0:
			_remove(rival)
	return [eaten, hit]


func _feed(rival: Colony) -> void:
	world.rocks.push_out(rival)
	var gained := world.bed.touch(rival) * FeedingStyle.seaweed_factor(rival.plan.style)
	var reach := FeedingStyle.mouth_reach(rival.plan.style)
	for point in rival.eat_points():
		gained += ecosystem.food.take_near(Vector2(point.x, point.z), reach) \
			* FeedingStyle.food_factor(rival.plan.style)
	if gained > 0.0:
		rival.feed(gained)


func _refill(player: Colony) -> void:
	var c := player.center()
	var center := Vector2(c.x, c.z)
	for rival: Colony in rivals.duplicate():
		var rc := rival.center()
		if Vector2(rc.x, rc.z).distance_to(center) > DESPAWN:
			_remove(rival)
	if rivals.size() >= COUNT:
		return
	var step_size: int = SIZE_STEPS[rivals.size() % SIZE_STEPS.size()]
	var target := clampi(player.plan.parts.size() + step_size, 8, BodyPlan.MAX_CELLS)
	var at := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(SPAWN_MIN, SPAWN_MAX)
	_spawn(make_plan(target, rng), at)


func _spawn(plan: BodyPlan, at: Vector2) -> void:
	var rival := Colony.new()
	rival.tint = TINTS[rng.randi() % TINTS.size()]
	rival.nucleus = rival.tint.darkened(0.3)
	rival.facing = rng.randf() * TAU
	rival.build(plan, Vector3(at.x, 0.0, at.y))
	rival.energy = rival.max_energy() * 0.7
	add_child(rival)
	rivals.append(rival)


func _remove(rival: Colony) -> void:
	rivals.erase(rival)
	rival.queue_free()


## A random colony of about `cells` cells, with a random feeding style.
static func make_plan(cells: int, random: RandomNumberGenerator) -> BodyPlan:
	var plan := BodyPlan.starter(Symmetry.ALL[random.randi() % Symmetry.ALL.size()])
	plan.style = FeedingStyle.ALL[random.randi() % FeedingStyle.ALL.size()]
	var roles: Array = LabHud.GROWABLE
	var tries := 0
	while plan.parts.size() < cells and tries < 30:
		tries += 1
		plan.grow(str(roles[random.randi() % roles.size()]))
	return plan
