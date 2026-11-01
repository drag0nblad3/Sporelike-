class_name BiomeMap
extends RefCounted
## Where each FoodKind grows: patches scattered across the world from a
## seed, so a saved game can rebuild the same map. The first algae meadow
## sits near the center, where a new species starts.

const TRIES := 40
const EDGE_GAP := 2.0

var radius := 55.0
var patches: Array[FoodPatch] = []


static func generate(world_seed: int, world_radius: float, kinds: Array[FoodKind]) -> BiomeMap:
	var map := BiomeMap.new()
	map.radius = world_radius
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	for kind in kinds:
		for i in kind.patch_count:
			var r := rng.randf_range(kind.patch_min, kind.patch_max)
			var start_here := kind.id == "algae" and i == 0
			map.patches.append(FoodPatch.make(kind.id, map._place(r, rng, start_here), r))
	return map


func patches_for(kind_id: String) -> Array[FoodPatch]:
	var list: Array[FoodPatch] = []
	for patch in patches:
		if patch.kind_id == kind_id:
			list.append(patch)
	return list


## A spot for a patch of radius r, kept apart from other patches when
## possible. The starting meadow goes at the center.
func _place(r: float, rng: RandomNumberGenerator, at_center: bool) -> Vector2:
	if at_center:
		return Vector2.ZERO
	var best := Vector2.ZERO
	var best_gap := -INF
	var reach := radius - r - EDGE_GAP
	for _i in TRIES:
		var p := Vector2.from_angle(rng.randf() * TAU) * reach * sqrt(rng.randf())
		var gap := INF
		for other in patches:
			gap = minf(gap, p.distance_to(other.center) - other.radius - r)
		if gap > 1.0:
			return p
		if gap > best_gap:
			best_gap = gap
			best = p
	return best
