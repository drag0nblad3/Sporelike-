class_name CombJelly
extends Node3D
## A comb jelly (ctenophore), one of the first animal hunters: a see-through
## bell rowed along by glittering comb rows. It drifts at the surface and
## dives on colonies it spots below it in open water, but will not go down
## to the sea floor, so sinking is the way to escape it. After a bite it
## rises back to the surface to digest.

const RADIUS := 1.6
const SIGHT := 16.0
const DIVE_SPEED := 5.0
const DRIFT_SPEED := 1.5
const RISE_SPEED := 2.0
## Never sinks below this height.
const LOWEST := Depth.STEP - 0.4
const REST_AFTER_BITE := 7.0
const REST_AFTER_BLOCK := 2.5
const COMBS := 8

var stun_time := 0.0
var rest_time := 0.0
var diving := false
var _wander := Vector2.ZERO
var _wander_timer := 0.0
var _time := 0.0
var _combs: BeadStrip
var _shadow: FloorShadow


func _ready() -> void:
	add_to_group("comb_jelly")
	var bell := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = RADIUS
	ball.height = RADIUS * 1.6
	bell.mesh = ball
	# A clear jelly bell, lit and rimmed like every other skin (CellSkin).
	bell.material_override = CellSkin.material(Color(0.75, 0.85, 1.0, 0.2), 0.35)
	add_child(bell)
	# Made here, not at declaration, so a jelly never added to the tree
	# leaves nothing behind.
	_shadow = FloorShadow.new(RADIUS * 1.1)
	add_child(_shadow)
	_combs = BeadStrip.make(COMBS, 0.18, 6, Color(0.4, 0.8, 1.0))
	add_child(_combs)


## One physics step against the player's colony. Returns a bite outcome or "".
func hunt(colony: Colony, rng: RandomNumberGenerator, delta: float) -> String:
	_time += delta
	stun_time = maxf(stun_time - delta, 0.0)
	rest_time = maxf(rest_time - delta, 0.0)
	diving = false
	if stun_time > 0.0:
		_rise(delta * 0.3)
		return ""
	var index := colony.nearest_cell(Vector2(position.x, position.z))
	var cell := colony.body.pos[index]
	var flat := Vector2(cell.x - position.x, cell.z - position.z)
	var below := colony.height > LOWEST - 0.5
	if rest_time <= 0.0 and below and flat.length() < SIGHT:
		diving = true
		var goal := Vector3(cell.x, maxf(cell.y, LOWEST), cell.z)
		position = position.move_toward(goal, DIVE_SPEED * delta)
		if position.distance_to(cell) <= RADIUS + 0.5:
			return _bite(colony, index, rng)
		return ""
	_drift(delta)
	_rise(delta)
	return ""


func _bite(colony: Colony, index: int, rng: RandomNumberGenerator) -> String:
	var outcome := colony.wounds.bite(colony, index, rng)
	match outcome:
		ColonyWounds.STUNG:
			stun_time = CellEffects.STING_STUN
		ColonyWounds.BITTEN:
			rest_time = REST_AFTER_BITE
		_:
			rest_time = REST_AFTER_BLOCK
	return outcome


func _drift(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 4.0)
		_wander = Vector2.from_angle(randf() * TAU)
	position += Vector3(_wander.x, 0.0, _wander.y) * DRIFT_SPEED * delta


func _rise(delta: float) -> void:
	position.y = move_toward(position.y, Depth.height(Depth.SURFACE), RISE_SPEED * delta)


func _process(_delta: float) -> void:
	if _combs == null:
		return
	_shadow.follow(global_position)
	for k in COMBS:
		var a := TAU * k / COMBS
		var shimmer := 0.6 + 0.4 * sin(_time * 8.0 + k)
		var hue := 0.5 + 0.5 * sin(_time * 3.0 + k)
		_combs.set_color(k, Color(0.4, 0.8, 1.0).lerp(Color(1.0, 0.5, 0.9), hue))
		# The strip is a child of the bell, so places are relative to it.
		_combs.place(k, Vector3(cos(a), 0.0, sin(a)) * RADIUS * 0.95, shimmer)
