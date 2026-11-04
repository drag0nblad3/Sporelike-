class_name ChunkGenerator
extends RefCounted
## Decides which food patches each square chunk of the endless sea floor
## holds, from the world seed alone, so a chunk always comes back the same.
## Each chunk is a grid of cells, and each cell gets one overlapping blob,
## so food forms big connected regions. Slow noise fields decide the
## region's kind (algae meadows grade into open plankton water, then dark
## mote trenches, with shell vents inside the trenches), where narrow
## channels of open sand run, and the rare faint "hidden" fields. The run's
## Sea moves the region cutoffs, so each sea has its own mix of food.

const SIZE := 40.0
const GRID := 3
## Blob radius as a fraction of the cell size; above 0.5 neighbours overlap.
const REACH_MIN := 0.62
const REACH_MAX := 0.8
const JITTER := 0.15
## Chance a cell is any kind rather than its region's (or companion) kind.
const STRAY_CHANCE := 0.1
## Region kind -> [companion kind, chance]: vents in trenches, plankton
## clouds drifting over meadows.
const COMPANIONS := {
	"motes": ["shells", 0.3],
	"algae": ["plankton", 0.2],
}

var world_seed := 0
var sea := Sea.current()
var kinds: Array[FoodKind] = []
var _by_id := {}
var _regions := FastNoiseLite.new()
var _gaps := FastNoiseLite.new()
var _hidden := FastNoiseLite.new()


func _init(seed_value: int) -> void:
	world_seed = seed_value
	kinds = FoodKind.all()
	for kind in kinds:
		_by_id[kind.id] = kind
	_regions.seed = seed_value
	_regions.frequency = 0.006
	_gaps.seed = seed_value + 1
	_gaps.frequency = 0.025
	_hidden.seed = seed_value + 2
	_hidden.frequency = 0.012


static func chunk_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / SIZE), floori(p.y / SIZE))


func patches_for(coord: Vector2i) -> Array[FoodPatch]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, coord.x, coord.y])
	var origin := Vector2(coord) * SIZE
	var cell := SIZE / GRID
	var list: Array[FoodPatch] = []
	if coord == Vector2i.ZERO:
		# The species always starts on a meadow of its sea's start food.
		list.append(FoodPatch.make(_by_id[sea.start_kind], Vector2.ZERO, 10.0, coord, rng))
	for gx in GRID:
		for gy in GRID:
			var at := origin + (Vector2(gx, gy) + Vector2(0.5, 0.5)) * cell
			at += Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * cell * JITTER
			if _gaps.get_noise_2d(at.x, at.y) < sea.gap_below:
				continue
			var kind := _pick_kind(at, rng)
			var r := cell * rng.randf_range(REACH_MIN, REACH_MAX) * kind.patch_scale
			var patch := FoodPatch.make(kind, at, r, coord, rng)
			patch.hidden = coord != Vector2i.ZERO \
				and _hidden.get_noise_2d(at.x, at.y) > sea.hidden_above
			list.append(patch)
	return list


## The region's food kind at this point.
func region_kind(p: Vector2) -> FoodKind:
	var n := _regions.get_noise_2d(p.x, p.y)
	var order := ["algae", "plankton", "motes"]
	for i in order.size():
		if n < sea.cutoffs[i]:
			return _by_id[order[i]]
	return _by_id["shells"]


func _pick_kind(p: Vector2, rng: RandomNumberGenerator) -> FoodKind:
	if rng.randf() < STRAY_CHANCE:
		return kinds[rng.randi() % kinds.size()]
	var kind := region_kind(p)
	if COMPANIONS.has(kind.id):
		var rule: Array = COMPANIONS[kind.id]
		var chance: float = rule[1]
		if rng.randf() < chance:
			return _by_id[rule[0]]
	return kind
