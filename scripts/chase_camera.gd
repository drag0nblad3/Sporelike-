class_name ChaseCamera
extends Camera3D
## Stage 3's camera: sits behind and above the animal and swings round as
## it turns. The player can drag to look around (look_yaw, look_pitch);
## a second after letting go it eases back behind. It never dips into the
## ground (LandHeight). In showcase (the body customizer is open) it swings
## round to a three-quarter front view and keeps the animal left of centre,
## clear of the panel.

const DISTANCE := 9.0
const HEIGHT := 4.0
const FOLLOW := 3.0
const RETURN_DELAY := 1.0
const RETURN_RATE := 2.0
const MIN_PITCH := -0.35
const MAX_PITCH := 0.9
const SHOWCASE_YAW := 2.3

var showcase := false

## Extra turn and tilt from dragging, in radians.
var look_yaw := 0.0
var look_pitch := 0.0
## Seconds since the player last dragged.
var idle := 10.0
var _yaw := 0.0


func _ready() -> void:
	fov = 65.0
	far = 160.0
	make_current()


func snap(target: Vector3, heading: float) -> void:
	_yaw = heading
	_place(target)


func follow(target: Vector3, heading: float, size: float, delta: float) -> void:
	_yaw = lerp_angle(_yaw, heading, clampf(FOLLOW * delta, 0.0, 1.0))
	idle += delta
	if showcase:
		look_yaw = lerp_angle(look_yaw, SHOWCASE_YAW, clampf(RETURN_RATE * delta, 0.0, 1.0))
	elif idle > RETURN_DELAY:
		var k := clampf(RETURN_RATE * delta, 0.0, 1.0)
		look_yaw = lerpf(look_yaw, 0.0, k)
		look_pitch = lerpf(look_pitch, 0.0, k)
	_place(target, 0.7 + size * 0.5)


## The flat direction the camera looks along, for steering.
func flat_forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD


func drag(yaw: float, pitch: float) -> void:
	look_yaw += yaw
	look_pitch = clampf(look_pitch + pitch, MIN_PITCH, MAX_PITCH)
	idle = 0.0


func _place(target: Vector3, scale_by: float = 1.0) -> void:
	var yaw := _yaw + look_yaw
	var back := -Vector3(sin(yaw), 0.0, cos(yaw))
	var tilt := HEIGHT / DISTANCE + look_pitch
	var offset := (back + Vector3.UP * tilt).normalized() * DISTANCE * scale_by
	var spot := target + offset
	spot.y = maxf(spot.y, LandHeight.at(spot.x, spot.z) + 1.2)
	position = spot
	var aim := target + Vector3.UP * 0.8
	if showcase:
		aim += (-back).cross(Vector3.UP) * DISTANCE * scale_by * 0.22
	look_at(aim)
