class_name Cell
extends Node3D
## The player's single-celled organism. Moves on the flat ocean plane (X/Z),
## drifts like it is in water, and wobbles so it feels alive.

const ACCELERATION := 12.0
const WATER_DRAG := 2.5
const MAX_SPEED := 6.0
const MAX_RADIUS := 2.0

## Set every frame by main.gd from the joystick or keyboard. Length 0 to 1.
var move_input := Vector2.ZERO
var radius := 0.6
var arena_radius := 30.0
var velocity := Vector3.ZERO

var _body: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	_body = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	_body.mesh = sphere
	var membrane := StandardMaterial3D.new()
	membrane.albedo_color = Color(0.35, 0.85, 1.0, 0.6)
	membrane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	membrane.emission_enabled = true
	membrane.emission = Color(0.15, 0.55, 0.8)
	_body.material_override = membrane
	add_child(_body)

	var nucleus := MeshInstance3D.new()
	var core := SphereMesh.new()
	core.radius = 0.35
	core.height = 0.7
	nucleus.mesh = core
	var nucleus_mat := StandardMaterial3D.new()
	nucleus_mat.albedo_color = Color(0.55, 0.3, 0.9)
	nucleus_mat.emission_enabled = true
	nucleus_mat.emission = Color(0.35, 0.15, 0.6)
	nucleus.material_override = nucleus_mat
	nucleus.position = Vector3(0.2, 0.1, 0.15)
	_body.add_child(nucleus)
	_apply_size()


func _physics_process(delta: float) -> void:
	var dir := Vector3(move_input.x, 0.0, move_input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity += dir * ACCELERATION * delta
	velocity -= velocity * minf(WATER_DRAG * delta, 1.0)
	velocity = velocity.limit_length(MAX_SPEED)
	position += velocity * delta

	# Stay inside the arena.
	var flat := Vector2(position.x, position.z)
	var limit := arena_radius - radius
	if flat.length() > limit:
		flat = flat.normalized() * limit
		position.x = flat.x
		position.z = flat.y
		velocity *= 0.5

	# Turn to face the direction of travel.
	if velocity.length() > 0.1:
		var target := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target, minf(8.0 * delta, 1.0))


func _process(delta: float) -> void:
	_time += delta
	var pulse := 1.0 + 0.06 * sin(_time * 4.0)
	var stretch := 1.0 + velocity.length() * 0.04
	_body.scale = Vector3(pulse / sqrt(stretch), 0.8 / pulse, stretch)


## Called when the cell eats. Returns the new radius.
func grow(amount: float) -> float:
	radius = minf(radius + amount, MAX_RADIUS)
	_apply_size()
	return radius


func _apply_size() -> void:
	scale = Vector3.ONE * radius
