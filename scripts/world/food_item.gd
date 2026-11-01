class_name FoodItem
extends MeshInstance3D
## One piece of food. Each piece rolls its own grade within its kind: higher
## grades are worth a bit more but are much tougher, faster, nimbler, and
## harder to see; low grades are slow, sluggish and soft.
## Some kinds drift around and dart away from anything that comes close.

const TIERS := 3

var kind: FoodKind
## 0 = easiest piece of its kind, 1 = hardest and most valuable.
var grade := 0.0
var energy := 0.0
var hardness := 0.0
var visibility := 1.0
var flee_speed := 0.0
var drift_speed := 0.0
## 0..1: how sharply it dodges when startled and how often it turns.
var agility := 1.0
var velocity := Vector2.ZERO
## Seconds something has spent chewing on this piece; wears off when left.
var chew := 0.0
## The patch it grew in; drifting food stays inside it.
var home: FoodPatch

var _phase := 0.0
var _drift_dir := Vector2.ZERO
var _drift_timer := 0.0
var _chewed_this_frame := false
var _base_scale := 1.0


func _ready() -> void:
	_phase = randf() * TAU


func roll(food_kind: FoodKind, rng: RandomNumberGenerator) -> void:
	kind = food_kind
	grade = rng.randf()
	energy = kind.energy * lerpf(0.7, 1.5, grade)
	hardness = lerpf(kind.hardness_min * 0.3, kind.hardness_max, grade)
	visibility = minf(kind.visibility * lerpf(1.4, 0.7, grade), 1.0)
	flee_speed = kind.flee_speed * lerpf(0.15, 1.4, grade)
	drift_speed = kind.drift_speed * lerpf(0.25, 1.3, grade)
	agility = lerpf(0.25, 1.0, grade)
	_base_scale = lerpf(0.75, 1.35, grade)
	scale = Vector3.ONE * _base_scale


## 0, 1 or 2: which colour tier to draw this piece with.
func tier() -> int:
	return mini(int(grade * TIERS), TIERS - 1)


## Called each physics frame by whatever is covering this piece. Returns
## true once it has been chewed for long enough to break through.
func chew_for(delta: float, needed: float) -> bool:
	chew += delta
	_chewed_this_frame = true
	return chew >= needed


func _physics_process(delta: float) -> void:
	if not _chewed_this_frame and chew > 0.0:
		chew = maxf(chew - delta, 0.0)
	_chewed_this_frame = false
	# Shake while being chewed so the player can see it working.
	var shake := 0.08 * sin(_phase * 40.0) if chew > 0.0 else 0.0
	scale = Vector3.ONE * _base_scale * (1.0 + shake)


func flat_pos() -> Vector2:
	return Vector2(position.x, position.z)


## Dart away from a nearby threat, if this kind can. Called every physics
## frame while a threat is close; sluggish pieces take about a second to
## turn and get going, nimble ones react almost at once.
func startle(from: Vector2) -> void:
	if flee_speed > 0.0:
		var away := (flat_pos() - from).normalized() * flee_speed
		velocity = velocity.lerp(away, agility * 0.2)


func _process(delta: float) -> void:
	_phase += delta
	position.y = 0.15 * sin(_phase * 2.0)
	if drift_speed <= 0.0 and velocity == Vector2.ZERO:
		return

	_drift_timer -= delta
	if _drift_timer <= 0.0:
		_drift_timer = randf_range(1.5, 4.0) / agility
		_drift_dir = Vector2.from_angle(randf() * TAU)
	velocity = velocity.move_toward(_drift_dir * drift_speed, delta * 4.0)

	var p := flat_pos() + velocity * delta
	var held := home.keep_inside(p)
	if held != p:
		_drift_dir = (home.center - held).normalized()
	position.x = held.x
	position.z = held.y
