class_name Organism
extends Node3D
## Base for every living thing: movement through water, energy, death.
## Subclasses override think() to set move_input each physics frame.

signal died(organism: Organism, cause: String)
signal ate(amount: float)
## Energy made without eating (photosynthesis, chemosynthesis).
signal absorbed(amount: float)


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

## Seconds left on a jet boost, and until the next one is ready.
var boost_time := 0.0
var boost_cooldown := 0.0
## Energy per second this cell is making from light or vents, rechecked by
## EnergySources every ambient_timer seconds.
var ambient_rate := 0.0
var ambient_timer := 0.0

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


## Fires the jet boost if this body has one and it is ready.
func try_boost() -> bool:
	var level := genome.feature("jet")
	if level <= 0 or boost_cooldown > 0.0:
		return false
	boost_time = 0.35
	boost_cooldown = 4.5 - 1.5 * level
	return true


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
	think(delta)
	_move(delta)
	energy -= genome.upkeep() * upkeep_scale * delta
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
	var top_speed := genome.max_speed() * speed_scale
	var push := genome.acceleration() * speed_scale
	boost_cooldown = maxf(boost_cooldown - delta, 0.0)
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

	if velocity.length() > 0.1:
		var target := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target, minf(genome.turn_rate() * delta, 1.0))
