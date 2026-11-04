class_name FlowGrid
extends RefCounted
## A cached copy of the CurrentField's flow, sampled every STEP units and
## blended between samples. Working out the exact flow means checking every
## segment of every nearby stream, which got slow with a big crowd in
## winding currents; now each sample is worked out once, the first time
## something swims near it, and every later lookup is four array reads.

const STEP := 1.0
## Samples along one side of a block: one chunk (ChunkGenerator.SIZE) / STEP.
const SIDE := 40
## Forget blocks past this many; the loaded area is only nine chunks.
const BLOCK_LIMIT := 64

## Chunk -> Array of SIDE * SIDE samples, null until worked out. A plain
## Array, not a packed one, so filling in a sample does not copy the block.
var _blocks := {}


## The flow at this point, blended from the four samples around it. The
## field is passed in, not kept, so the two do not hold each other alive.
func flow_at(p: Vector2, field: CurrentField) -> Vector2:
	var gx := p.x / STEP
	var gy := p.y / STEP
	var ix := floori(gx)
	var iy := floori(gy)
	var fx := gx - ix
	var fy := gy - iy
	var top := _sample(ix, iy, field).lerp(_sample(ix + 1, iy, field), fx)
	var bottom := _sample(ix, iy + 1, field).lerp(_sample(ix + 1, iy + 1, field), fx)
	return top.lerp(bottom, fy)


func _sample(ix: int, iy: int, field: CurrentField) -> Vector2:
	var block := Vector2i(floori(float(ix) / SIDE), floori(float(iy) / SIDE))
	if not _blocks.has(block):
		if _blocks.size() >= BLOCK_LIMIT:
			_blocks.clear()
		var fresh := []
		fresh.resize(SIDE * SIDE)
		_blocks[block] = fresh
	var samples: Array = _blocks[block]
	var k := posmod(iy, SIDE) * SIDE + posmod(ix, SIDE)
	var value: Variant = samples[k]
	if value == null:
		value = field.exact_flow(Vector2(ix, iy) * STEP)
		samples[k] = value
	return value
