class_name FoodItem
extends MeshInstance3D
## One piece of food. Each piece rolls its own grade within its kind: higher
## grades are worth more but are tougher, faster to flee, or harder to see.
## Some kinds drift around and dart away from anything that comes close.

const TIERS := 3

var kind: FoodKind
## 0 = easiest piece of its kind, 1 = hardest and most valuable.
var grade := 0.0
var energy := 0.0
var hardness := 0.0
var visibility := 1.0
var flee_speed := 0.0
var velocity := Vector2.ZERO
var arena_radius := 30.0

var _phase := 0.0
var _drift_dir := Vector2.ZERO
var _drift_timer := 0.0


func _ready() -> void:
	_phase = randf() * TAU


func roll(food_kind: FoodKind, rng: RandomNumberGenerator) -> void:
	kind = food_kind
	grade = rng.randf()
	energy = kind.energy * lerpf(0.35, 1.5, grade)
	hardness = lerpf(kind.hardness_min, kind.hardness_max, grade)
	visibility = minf(kind.visibility * lerpf(1.3, 0.7, grade), 1.0)
	flee_speed = kind.flee_speed * lerpf(0.6, 1.4, grade)
	scale = Vector3.ONE * lerpf(0.65, 1.35, grade)


## 0, 1 or 2: which colour tier to draw this piece with.
func tier() -> int:
	return mini(int(grade * TIERS), TIERS - 1)


func flat_pos() -> Vector2:
	return Vector2(position.x, position.z)


## Dart away from a nearby threat, if this kind can.
func startle(from: Vector2) -> void:
	if flee_speed > 0.0:
		velocity = (flat_pos() - from).normalized() * flee_speed


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
