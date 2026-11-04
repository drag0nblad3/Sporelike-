class_name ViewFootprint
extends RefCounted
## The patch of sea floor the camera shows, as a ground polygon, and how far
## outside it a point lies. SenseCues uses it to tell what is off screen.

var corners := PackedVector2Array()


func update(camera: Camera3D) -> void:
	var size := camera.get_viewport().get_visible_rect().size
	var screen: Array[Vector2] = [Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]
	corners.clear()
	for p in screen:
		corners.append(_ground(camera, p))


## 0 inside the view, otherwise the distance to its nearest edge.
func outside_by(point: Vector2) -> float:
	if corners.size() < 3 or Geometry2D.is_point_in_polygon(point, corners):
		return 0.0
	var best := INF
	for i in corners.size():
		var a := corners[i]
		var b := corners[(i + 1) % corners.size()]
		best = minf(best, point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)))
	return best


## Where the camera ray through this screen point meets the sea floor (y = 0).
static func _ground(camera: Camera3D, screen: Vector2) -> Vector2:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	dir.y = minf(dir.y, -0.05)
	var hit := from + dir * (-from.y / dir.y)
	return Vector2(hit.x, hit.z)
