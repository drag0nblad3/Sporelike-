class_name FoodGrid
extends RefCounted
## Buckets food by position so eaters only check nearby pieces instead of
## every piece in the world. Rebuilt each physics frame, since food drifts.

const CELL := 8.0

var _buckets := {}


func rebuild(items: Array[Node]) -> void:
	_buckets.clear()
	for child in items:
		var item := child as FoodItem
		if item == null or item.is_queued_for_deletion():
			continue
		var key := _key(item.flat_pos())
		if not _buckets.has(key):
			_buckets[key] = []
		var bucket: Array = _buckets[key]
		bucket.append(item)


## Food in every bucket that overlaps the circle at pos with this radius.
func near(pos: Vector2, reach: float) -> Array[FoodItem]:
	var found: Array[FoodItem] = []
	var low := _key(pos - Vector2(reach, reach))
	var high := _key(pos + Vector2(reach, reach))
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var bucket: Array = _buckets.get(Vector2i(x, y), [])
			for item in bucket:
				var food: FoodItem = item
				if is_instance_valid(food) and not food.is_queued_for_deletion():
					found.append(food)
	return found


func _key(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))
