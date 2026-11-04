class_name FoodGrid
extends RefCounted
## Buckets food by position so eaters only check nearby pieces instead of
## every piece in the world. Most food never moves, so it is bucketed once
## when it grows and taken out when eaten; only food that can drift or dart
## is re-bucketed each physics frame (update_moving).

const CELL := 8.0

## Food that stays put, by bucket. Its x/z never change.
var _still := {}
## Food that can move, re-bucketed by update_moving().
var _moving: Array[FoodItem] = []
var _moving_buckets := {}


## Starts tracking a new piece of food.
func add(item: FoodItem) -> void:
	if _can_move(item):
		_moving.append(item)
		_put(_moving_buckets, item)
	else:
		_put(_still, item)


## Stops tracking a piece that is being eaten or removed.
func remove(item: FoodItem) -> void:
	if _can_move(item):
		_moving.erase(item)
		return
	var key := _key(item.flat_pos())
	var bucket: Array = _still.get(key, [])
	bucket.erase(item)
	if bucket.is_empty():
		_still.erase(key)


## Re-buckets the food that can move. Called once per physics frame.
func update_moving() -> void:
	_moving_buckets.clear()
	for item in _moving:
		_put(_moving_buckets, item)


## Food in every bucket that overlaps the circle at pos with this radius.
func near(pos: Vector2, reach: float) -> Array[FoodItem]:
	var found: Array[FoodItem] = []
	var low := _key(pos - Vector2(reach, reach))
	var high := _key(pos + Vector2(reach, reach))
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var key := Vector2i(x, y)
			_gather(_still.get(key), found)
			_gather(_moving_buckets.get(key), found)
	return found


## True if any piece of this kind lies within reach of pos: food only
## regrows next to food of its own kind (FoodField.SEED_RANGE).
func has_kind_near(kind: FoodKind, pos: Vector2, reach: float) -> bool:
	var reach_sq := reach * reach
	for item in near(pos, reach):
		if item.kind.id == kind.id and item.flat_pos().distance_squared_to(pos) <= reach_sq:
			return true
	return false


func _gather(bucket: Variant, found: Array[FoodItem]) -> void:
	if bucket == null:
		return
	for item in bucket:
		if is_instance_valid(item) and not (item as FoodItem).is_queued_for_deletion():
			found.append(item)


func _put(buckets: Dictionary, item: FoodItem) -> void:
	var key := _key(item.flat_pos())
	if not buckets.has(key):
		buckets[key] = []
	var bucket: Array = buckets[key]
	bucket.append(item)


static func _can_move(item: FoodItem) -> bool:
	return item.drift_speed > 0.0 or item.flee_speed > 0.0


func _key(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))
