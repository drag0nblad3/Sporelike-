class_name ChunkGenerator
extends RefCounted
## Decides which food patches each square chunk of the endless sea floor
## holds, from the world seed alone, so a chunk always comes back the same.
## A slow noise field groups chunks into regions that grade into each
## other: algae meadows give way to open plankton water, then dark mote
## trenches, with shell beds on vents deep inside the trenches. Some
## patches also bring companions: vents beside trenches, plankton clouds
## fringing meadows.

const SIZE := 40.0
const MIN_PATCHES := 1
const MAX_PATCHES := 3
## Chance a patch is the region's own kind rather than any kind.
const REGION_BIAS := 0.7
## Kind -> [companion kind, chance]. Companions sit against the patch's edge.
const COMPANIONS := {
	"motes": ["shells", 0.5],
	"algae": ["plankton", 0.4],
}

var world_seed := 0
var kinds: Array[FoodKind] = []
var _by_id := {}
var _regions := FastNoiseLite.new()


func _init(seed_value: int) -> void:
	world_seed = seed_value
	kinds = FoodKind.all()
	for kind in kinds:
		_by_id[kind.id] = kind
	_regions.seed = seed_value
	_regions.frequency = 0.006


static func chunk_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / SIZE), floori(p.y / SIZE))


func patches_for(coord: Vector2i) -> Array[FoodPatch]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, coord.x, coord.y])
	var origin := Vector2(coord) * SIZE
	var list: Array[FoodPatch] = []
	if coord == Vector2i.ZERO:
		# The species always starts on an algae meadow at the center.
		list.append(FoodPatch.make(_by_id["algae"], Vector2.ZERO, 10.0, coord, rng))
	var n := rng.randi_range(MIN_PATCHES, MAX_PATCHES)
	for _i in n:
		var kind := _pick_kind(origin + Vector2(SIZE, SIZE) * 0.5, rng)
		var r := rng.randf_range(kind.patch_min, kind.patch_max)
		var at := origin + Vector2(rng.randf_range(r, SIZE - r), rng.randf_range(r, SIZE - r))
		if _overlaps(list, at, r):
			continue
		var patch := FoodPatch.make(kind, at, r, coord, rng)
		list.append(patch)
		_add_companion(list, patch, rng)
	return list


## The region's food kind at this point, most of the time.
func region_kind(p: Vector2) -> FoodKind:
	var n := _regions.get_noise_2d(p.x, p.y)
	if n < -0.2:
		return _by_id["algae"]
	if n < 0.15:
		return _by_id["plankton"]
	if n < 0.4:
		return _by_id["motes"]
	return _by_id["shells"]


func _add_companion(list: Array[FoodPatch], patch: FoodPatch,
		rng: RandomNumberGenerator) -> void:
	if not COMPANIONS.has(patch.kind.id):
		return
	var rule: Array = COMPANIONS[patch.kind.id]
	var chance: float = rule[1]
	if rng.randf() > chance:
		return
	var kind: FoodKind = _by_id[rule[0]]
	var r := rng.randf_range(kind.patch_min, kind.patch_max)
	var angle := rng.randf() * TAU
	var at := patch.center + Vector2.from_angle(angle) * (patch.radius_at(angle) + r * 0.7)
	var others := list.duplicate()
	others.erase(patch)
	if not _overlaps(others, at, r):
		list.append(FoodPatch.make(kind, at, r, patch.chunk, rng))


func _pick_kind(p: Vector2, rng: RandomNumberGenerator) -> FoodKind:
	if rng.randf() < REGION_BIAS:
		return region_kind(p)
	return kinds[rng.randi() % kinds.size()]


func _overlaps(list: Array[FoodPatch], at: Vector2, r: float) -> bool:
	for other in list:
		if at.distance_to(other.center) < r + other.radius + 1.0:
			return true
	return false
