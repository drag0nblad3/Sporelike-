class_name FoodScent
extends RefCounted
## The Scent trail upgrade's sense: finds the nearest loaded patch with a
## good amount of food this body can crack and digest well, hidden or not.

## Fewer pieces left than this and the patch is not worth heading for.
const MIN_PIECES := 3
## Food digested at less than this share of its value is not "appropriate".
const MIN_DIGEST := 0.55


static func nearest(patches: Array[FoodPatch], genome: Genome, from: Vector2) -> FoodPatch:
	var best: FoodPatch = null
	var best_d := INF
	for patch in patches:
		if patch.count < MIN_PIECES or not suits(patch.kind, genome):
			continue
		var d := from.distance_to(patch.center) - patch.radius
		if d < best_d:
			best_d = d
			best = patch
	return best


## Whether this body can break into the easier pieces of this kind and
## gets most of their energy out.
static func suits(kind: FoodKind, genome: Genome) -> bool:
	if genome.crack_time(kind.hardness_min * 0.3) == INF:
		return false
	return genome.digest(1.0, kind.is_plant) >= MIN_DIGEST
