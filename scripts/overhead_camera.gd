class_name OverheadCamera
extends Camera3D
## Stage 4's overhead view: looks down on the village from high up and a
## little to the south, so north is up the screen. ground_at turns a
## screen point into the spot on the land under it (for the focus flag).

const HEIGHT := 78.0
const BACK := 34.0

var _center := Vector3.ZERO


func _ready() -> void:
	fov = 55.0
	far = 260.0


func frame(center: Vector3) -> void:
	_center = center
	position = center + Vector3(0.0, HEIGHT, BACK)
	look_at(center)


## Where the land is under a screen point, given as shares of the screen
## (0 to 1 across and down) so the UI's scaling does not matter. `aspect`
## is the screen's width over its height.
func ground_at(share: Vector2, aspect: float) -> Vector3:
	var half := tan(deg_to_rad(fov) * 0.5)
	var local := Vector3((share.x * 2.0 - 1.0) * half * aspect, (1.0 - share.y * 2.0) * half, -1.0)
	var dir := (global_transform.basis * local).normalized()
	var from := global_position
	var hit := _center
	if dir.y > -0.01:
		return hit
	var level := _center.y
	for _pass in 3:
		hit = from + dir * ((level - from.y) / dir.y)
		level = LandHeight.at(hit.x, hit.z)
	return Vector3(hit.x, level, hit.z)
