class_name FoodItem
extends MeshInstance3D
## One piece of food. Some kinds drift around and dart away from anything
## that comes close.

var kind: FoodKind
var velocity := Vector2.ZERO
var arena_radius := 30.0

var _phase := 0.0
var _drift_dir := Vector2.ZERO
var _drift_timer := 0.0


func _ready() -> void:
	_phase = randf() * TAU


func flat_pos() -> Vector2:
	return Vector2(position.x, position.z)


## Dart away from a nearby threat, if this kind can.
func startle(from: Vector2) -> void:
	if kind.flee_speed > 0.0:
		velocity = (flat_pos() - from).normalized() * kind.flee_speed


func _process(delta: float) -> void:
	_phase += delta
	position.y = 0.15 * sin(_phase * 2.0)
	if kind.drift_speed <= 0.0 and velocity == Vector2.ZERO:
		return

	_drift_timer -= delta
	if _drift_timer <= 0.0:
		_drift_timer = randf_range(1.5, 4.0)
		_drift_dir = Vector2.from_angle(randf() * TAU)
	velocity = velocity.move_toward(_drift_dir * kind.drift_speed, delta * 4.0)

	var p := flat_pos() + velocity * delta
	var outer := minf(kind.zone_max, arena_radius - 1.0)
	if p.length() > outer:
		p = p.normalized() * outer
		_drift_dir = -p.normalized()
	elif p.length() < kind.zone_min and p.length() > 0.01:
		p = p.normalized() * kind.zone_min
		_drift_dir = p.normalized()
	position.x = p.x
	position.z = p.y
