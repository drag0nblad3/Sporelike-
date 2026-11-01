class_name CameraRig
extends Camera3D
## Top-down camera that follows a point and pulls back as the target grows.

const OFFSET := Vector3(0.0, 16.0, 8.0)

## Multiplies the follow distance; the CI screenshot tour zooms out with it.
var zoom := 1.0


func _ready() -> void:
	fov = 55.0
	make_current()


func snap_to(target: Vector3) -> void:
	position = target + OFFSET
	look_at(target)


func follow(target: Vector3, target_radius: float, delta: float) -> void:
	var goal := target + OFFSET * (0.8 + target_radius * 0.35) * zoom
	position = position.lerp(goal, minf(4.0 * delta, 1.0))
	look_at(position - OFFSET)
