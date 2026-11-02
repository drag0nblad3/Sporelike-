class_name Niche
extends RefCounted
## The four food kinds as niches a species can specialize in: how well a
## body suits each one, and the habits (see Habits) that living off it
## builds. Rival species use it to drift toward food that suits them and
## that the other species leave alone.

## Habits a species living off each food kind would show.
const KIND_HABITS := {
	"algae": ["sun"], "plankton": ["darting", "sprint"],
	"shells": ["tough", "vent"], "motes": ["faint"],
}
const PLANT := ["algae", "motes"]
const WORDS := {
	"algae": "sunlit algae meadows", "plankton": "plankton clouds",
	"shells": "vent shell beds", "motes": "faint trench motes",
}
## Any niche is worth this much on top of the body's fit, so an empty one
## can tempt a species that does not suit it yet.
const OPENNESS := 0.3
## How much a niche loses when the other species eat all of that food.
const CROWD_WEIGHT := 0.8
## A species keeps its niche unless another is this much better.
const LOYALTY := 1.2

static var _kinds: Array[FoodKind] = []


static func kinds() -> Array[FoodKind]:
	if _kinds.is_empty():
		_kinds = FoodKind.all()
	return _kinds


## About 0..1.5: how well this body finds, catches, cracks and digests a
## typical piece of this kind, plus energy organelles that work there.
static func fit(g: Genome, kind: FoodKind) -> float:
	var crack := g.crack_time(lerpf(kind.hardness_min, kind.hardness_max, 0.3))
	if crack == INF:
		return 0.0
	var score := g.digest(1.0, kind.is_plant) / (1.0 + 0.3 * crack)
	if kind.visibility < 1.0:
		score *= lerpf(0.4, 1.2, g.value_of("sense")) \
			+ 0.2 * (g.feature("eye_cluster") + g.feature("food_scent"))
	if kind.flee_speed > 0.0:
		var nimble := (g.value_of("speed") + g.value_of("agility")) * 0.5
		score *= lerpf(0.4, 1.2, nimble) \
			+ 0.25 * (g.feature("sticky_coat") + g.feature("grabbing_cilia"))
	if kind.id == EnergySources.SUN_KIND:
		score += 0.25 * g.feature("chloroplasts")
	elif kind.id == EnergySources.VENT_KIND:
		score += 0.25 * g.feature("vent_symbionts")
	return score


## The niche to move toward: one the body suits that few others eat.
## crowding: kind id -> 0..1 share of the other species' eating.
static func choose(g: Genome, crowding: Dictionary, current: String) -> String:
	var best := ""
	var best_score := -1.0
	for kind in kinds():
		var crowd: float = crowding.get(kind.id, 0.0)
		var score := (OPENNESS + fit(g, kind)) * (1.0 - CROWD_WEIGHT * crowd)
		if kind.id == current:
			score *= LOYALTY
		if score > best_score:
			best_score = score
			best = kind.id
	return best


## Adds the habits of living off this kind at this strength (0..1), as if
## the species had shown them.
static func push(habits: Habits, kind_id: String, amount: float) -> void:
	var list: Array = KIND_HABITS.get(kind_id, [])
	for h in list:
		var row: Array = Habits.KINDS[h]
		var full: float = row[1]
		if h in Habits.TIMED:
			full *= habits.length
		habits.add(h, full * amount)
	var energy := Habits.DIET_MIN_ENERGY * 3.0 * amount
	if kind_id in PLANT:
		habits.plant_energy += energy
	else:
		habits.prey_energy += energy
