class_name Organism
extends Node3D
## Base for every living thing: movement through water, energy, death.
## Subclasses override think() to set move_input each physics frame.

signal died(organism: Organism, cause: String)
signal ate(amount: float)
## Energy made without eating (photosynthesis, chemosynthesis).
signal absorbed(amount: float)
## A hunter's bite failed: how says why (spines or toxin).
signal bite_blocked(how: String)


var genome: Genome
var energy := 6.0
var move_input := Vector2.ZERO
var velocity := Vector3.ZERO
var alive := true
## Far from the player, in an unloaded chunk: frozen in place until it loads.
var dormant := false
## Multiplier on genome upkeep; predators set it to 0.
var upkeep_scale := 1.0
## Multiplies top speed and push; Ecosystem slows hunters with it (Pace).
var speed_scale := 1.0

## Seconds left on a jet burst; AbilityCaster starts it.
var boost_time := 0.0
## Recharge timers for the Jet and the other abilities (see Ability).
var abilities := AbilityTimers.new()
## Seconds left paralyzed (Toxicysts, Trichocysts): no swimming or biting.
var stun_time := 0.0
## Seconds hunters cannot find this cell (Scintillons flash).
var hidden_time := 0.0
## Set each frame by ColonyThreat: a colony cell to swim at instead of
## thinking. Cleared once used.
var lure := Vector2.INF
## Energy per second this cell is making from light or vents, rechecked by
## EnergySources every ambient_timer seconds.
var ambient_rate := 0.0
var ambient_timer := 0.0

var stats := BodyStats.new()

var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0


func setup(g: Genome, start_energy: float) -> void:
	genome = g
	energy = start_energy


func _ready() -> void:
	var visual := OrganismVisual.new()
	add_child(visual)
	visual.build(genome, tint())
	scale = Vector3.ONE * radius()


func radius() -> float:
	return genome.radius()


func tint() -> Color:
	return genome.color()


func flat_pos() -> Vector2:
	return Vector2(position.x, position.z)


func set_dormant(value: bool) -> void:
	if value == dormant:
		return
	dormant = value
	process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	visible = not value


## Override in subclasses.
func think(_delta: float) -> void:
	pass


## Starts a jet burst (AbilityCaster checks the recharge).
func start_jet() -> void:
	boost_time = Ability.JET_TIME


func eat(amount: float) -> void:
	energy = minf(energy + amount, genome.max_energy())
	ate.emit(amount)


func absorb(amount: float) -> void:
	energy = minf(energy + amount, genome.max_energy())
	absorbed.emit(amount)


func die(cause: String) -> void:
	if not alive:
		return
	alive = false
	died.emit(self, cause)
	queue_free()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	stats.tick(genome, delta)
	abilities.tick(delta)
	hidden_time = maxf(hidden_time - delta, 0.0)
	if stun_time > 0.0:
		stun_time -= delta
		move_input = Vector2.ZERO
	elif lure != Vector2.INF:
		move_input = (lure - flat_pos()).normalized()
		lure = Vector2.INF
	else:
		think(delta)
	_move(delta)
	energy -= stats.upkeep * upkeep_scale * delta
	if energy <= 0.0:
		die("starved")


## Slow random drifting, for when there is nothing better to do.
func wander_input(delta: float) -> Vector2:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.0, 3.0)
		_wander_dir = Vector2.from_angle(randf() * TAU) * 0.5
	return _wander_dir


func _move(delta: float) -> void:
	var top_speed := stats.top_speed * speed_scale
	var push := stats.push * speed_scale
	if boost_time > 0.0:
		boost_time -= delta
		top_speed *= 2.2
		push *= 4.0
	var dir := Vector3(move_input.x, 0.0, move_input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	if boost_time > 0.0 and dir.length() < 0.1:
		dir = velocity.normalized() if velocity.length() > 0.1 else -global_basis.z
	velocity += dir * push * delta
	velocity -= velocity * minf(2.5 * delta, 1.0)
	velocity = velocity.limit_length(top_speed)
	position += velocity * delta
	# Water currents carry everything along on top of its own swimming;
	# some body forms are pushed less (or more), see BodyForm.drift.
	if CurrentField.active:
		var flow := CurrentField.active.flow_at(Vector2(position.x, position.z)) * stats.drift
		position += Vector3(flow.x, 0.0, flow.y) * delta

	if velocity.length() > 0.1:
		var target := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target, minf(stats.turn * delta, 1.0))
