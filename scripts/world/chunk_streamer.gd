class_name ChunkStreamer
extends Node3D
## Loads the chunks around a focus point (the player) and unloads ones far
## behind, so the sea floor goes on forever but only a small area exists at
## once. Unloading waits one chunk further out, so wobbling on a border
## does not reload chunks over and over.

signal chunk_loaded(chunk: WorldChunk)
signal chunk_unloaded(chunk: WorldChunk)

const LOAD_RADIUS := 1
const UNLOAD_RADIUS := 2

var generator: ChunkGenerator
var _chunks := {}


func _init(world_seed: int) -> void:
	generator = ChunkGenerator.new(world_seed)


func update(focus: Vector2) -> void:
	var center := ChunkGenerator.chunk_of(focus)
	for x in range(center.x - LOAD_RADIUS, center.x + LOAD_RADIUS + 1):
		for y in range(center.y - LOAD_RADIUS, center.y + LOAD_RADIUS + 1):
			var coord := Vector2i(x, y)
			if not _chunks.has(coord):
				_load(coord)
	for key in _chunks.keys():
		var coord: Vector2i = key
		if maxi(absi(coord.x - center.x), absi(coord.y - center.y)) > UNLOAD_RADIUS:
			_unload(coord)


## Whether the ground at this point is loaded (things there are simulated).
func is_loaded(p: Vector2) -> bool:
	return _chunks.has(ChunkGenerator.chunk_of(p))


func _load(coord: Vector2i) -> void:
	var chunk := WorldChunk.new()
	chunk.setup(coord, generator.patches_for(coord))
	add_child(chunk)
	_chunks[coord] = chunk
	chunk_loaded.emit(chunk)


func _unload(coord: Vector2i) -> void:
	var chunk: WorldChunk = _chunks[coord]
	_chunks.erase(coord)
	chunk_unloaded.emit(chunk)
	chunk.queue_free()
