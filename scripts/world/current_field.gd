class_name CurrentField
extends RefCounted
## All the water currents of the endless sea, decided per chunk from the
## world seed so a chunk always gets the same ones back. About half the
## chunks hold one stream; most are weak, some medium, a few strong. The
## run's Sea changes how many chunks hold one and how fast they run.
## Organisms ask `active` for the flow where they are and drift with it.

const MAX_LENGTH := 75.0
## Streams reach at most this many chunks from the one they start in.
const REACH := 2
## Forget remembered chunks past this many, so the cache stays small.
const CACHE_LIMIT := 400

## The field of the game in progress, or null (title screen).
static var active: CurrentField

var world_seed := 0
var sea := Sea.current()
var _cache := {}
## Chunk -> the streams whose band reaches into it, so flow_at checks only
## those instead of every stream within REACH.
var _touching := {}


func _init(seed_value: int) -> void:
	world_seed = seed_value


## The streams that start in this chunk. They may reach into neighbours.
func streams_for(coord: Vector2i) -> Array[CurrentStream]:
	if _cache.has(coord):
		return _cache[coord]
	if _cache.size() > CACHE_LIMIT:
		_cache.clear()
	var list: Array[CurrentStream] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, coord.x, coord.y, "current"])
	if rng.randf() < sea.current_chance:
		var size := ChunkGenerator.SIZE
		var from := (Vector2(coord) + Vector2(rng.randf(), rng.randf())) * size
		var roll := rng.randf()
		var speed := CurrentStream.WEAK
		if roll > 0.85 and coord != Vector2i.ZERO:
			speed = CurrentStream.STRONG
		elif roll > 0.5:
			speed = CurrentStream.MEDIUM
		# Strong currents run in narrower, faster jets.
		var band := rng.randf_range(5.0, 11.0) * (0.7 if speed == CurrentStream.STRONG else 1.0)
		list.append(CurrentStream.wind(from, rng.randf() * TAU,
			rng.randf_range(40.0, MAX_LENGTH), band, speed * sea.current_speed, rng))
	_cache[coord] = list
	return list


## The total push of every current at this point.
func flow_at(p: Vector2) -> Vector2:
	var total := Vector2.ZERO
	for stream in _streams_touching(ChunkGenerator.chunk_of(p)):
		total += stream.flow_at(p)
	return total


func _streams_touching(center: Vector2i) -> Array[CurrentStream]:
	if _touching.has(center):
		return _touching[center]
	if _touching.size() > CACHE_LIMIT:
		_touching.clear()
	var size := ChunkGenerator.SIZE
	var area := Rect2(Vector2(center) * size, Vector2(size, size))
	var list: Array[CurrentStream] = []
	for x in range(center.x - REACH, center.x + REACH + 1):
		for y in range(center.y - REACH, center.y + REACH + 1):
			for stream in streams_for(Vector2i(x, y)):
				if stream.bounds().intersects(area, true):
					list.append(stream)
	_touching[center] = list
	return list
