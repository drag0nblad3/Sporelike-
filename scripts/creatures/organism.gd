class_name Organism
extends Node3D
## Base for every living thing: movement through water, energy, death.
## Subclasses override think() to set move_input each physics frame.

signal died(organism: Organism, cause: String)
signal ate(amount: float)

const MAX_ENERGY := 12.0

var genome: Genome
var energy := 6.0
var move_input := Vector2.ZERO
var velocity := Vector3.ZERO
var arena_radius := 30.0
var alive := true
## Multiplier on genome upkeep; predators set it to 0.
var upkeep_scale := 1.0

var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0


func setup(g: Genome, arena: float, start_energy: float) -> void:
	genome = g
	arena_radius = arena
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


## Override in subclasses.
func think(_delta: float) -> void:
	pass


func eat(amount: float) -> void:
	energy = minf(energy + amount, MAX_ENERGY)
	ate.emit(amount)


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
	if flat_pos().length() > arena_radius * 0.85:
		_wander_dir = -flat_pos().normalized() * 0.5
	return _wander_dir


func _move(delta: float) -> void:
	var top_speed := genome.max_speed()
	var dir := Vector3(move_input.x, 0.0, move_input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity += dir * genome.acceleration() * delta
	velocity -= velocity * minf(2.5 * delta, 1.0)
	velocity = velocity.limit_length(top_speed)
	position += velocity * delta

	var flat := flat_pos()
	var limit := arena_radius - radius()
	if flat.length() > limit:
		flat = flat.normalized() * limit
		position.x = flat.x
		position.z = flat.y
		velocity *= 0.5

	if velocity.length() > 0.1:
		var target := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target, minf(genome.turn_rate() * delta, 1.0))
