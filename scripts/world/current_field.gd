class_name CurrentField
extends RefCounted
## All the water currents of the endless sea, decided per chunk from the
## world seed so a chunk always gets the same ones back. About half the
## chunks hold one stream; most are weak, some medium, a few strong.
## Organisms ask `active` for the flow where they are and drift with it.

const CHANCE := 0.5
const MAX_LENGTH := 70.0

## The field of the game in progress, or null (title screen).
static var active: CurrentField

var world_seed := 0
var _cache := {}


func _init(seed_value: int) -> void:
	world_seed = seed_value


## The streams that start in this chunk. They may reach into neighbours.
func streams_for(coord: Vector2i) -> Array[CurrentStream]:
	if _cache.has(coord):
		return _cache[coord]
	var list: Array[CurrentStream] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, coord.x, coord.y, "current"])
	if rng.randf() < CHANCE:
		var size := ChunkGenerator.SIZE
		var mid := (Vector2(coord) + Vector2(rng.randf(), rng.randf())) * size
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var reach := rng.randf_range(30.0, MAX_LENGTH) * 0.5
		var roll := rng.randf()
		var speed := CurrentStream.WEAK
		if roll > 0.85 and coord != Vector2i.ZERO:
			speed = CurrentStream.STRONG
		elif roll > 0.5:
			speed = CurrentStream.MEDIUM
		# Strong currents run in narrower, faster jets.
		var band := rng.randf_range(5.0, 11.0) * (0.7 if speed == CurrentStream.STRONG else 1.0)
		list.append(CurrentStream.make(mid - dir * reach, mid + dir * reach, band, speed))
	_cache[coord] = list
	return list


## The total push of every current at this point.
func flow_at(p: Vector2) -> Vector2:
	var center := ChunkGenerator.chunk_of(p)
	var total := Vector2.ZERO
	for x in range(center.x - 1, center.x + 2):
		for y in range(center.y - 1, center.y + 2):
			for stream in streams_for(Vector2i(x, y)):
				total += stream.flow_at(p)
	return total


## Lets chunks far behind be forgotten so the cache does not grow forever.
func forget(coord: Vector2i) -> void:
	_cache.erase(coord)
