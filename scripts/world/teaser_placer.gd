class_name TeaserPlacer
extends RefCounted
## Decides, from the world seed, which chunks hold a giant teaser of the
## next stage (a ghostly sea plant or cell colony, many times the size of
## a cell) and builds it. Roughly one chunk in six has one; the starting
## chunk never does.

const PLANT_CHANCE := 0.09
const COLONY_CHANCE := 0.08
const COLONY_HEIGHT := 2.5


## The teaser for this chunk, or null.
static func build(world_seed: int, coord: Vector2i) -> Node3D:
	if coord == Vector2i.ZERO:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, coord.x, coord.y, "teaser"])
	var roll := rng.randf()
	var node: Node3D
	if roll < PLANT_CHANCE:
		node = TeaserPlant.new(rng.randi())
	elif roll < PLANT_CHANCE + COLONY_CHANCE:
		var kind := "sphere" if rng.randf() < 0.6 else "chain"
		node = TeaserColony.new(kind, rng.randi())
	else:
		return null
	var size := ChunkGenerator.SIZE
	var at := (Vector2(coord) + Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8))) * size
	node.position = Vector3(at.x, COLONY_HEIGHT if node is TeaserColony else 0.0, at.y)
	return node
