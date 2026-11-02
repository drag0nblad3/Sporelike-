class_name ForageStyle
extends RefCounted
## How a cell's body shapes the way it lives, so species with different
## traits behave differently: which food it goes for (see Niche.fit), how
## close a hunter gets before it flees (spiny or toxic cells stand firm),
## how fast it cruises between patches, how sharply it steers, and whether
## it basks over sunlit meadows or vents instead of roaming.

## Patches considered when roaming: the closest few.
const CHOICES := 6
## Distance at which a patch's pull halves.
const NEAR := 15.0

## Food kind id -> 0..1: its fit compared to the body's best kind.
var appeal := {}
var flee_range := 5.0
## Share of top speed used to travel between patches.
var cruise := 0.7
## How quickly the swimming direction follows a new goal, per second.
var steer := 6.0
var basks := false


static func of(g: Genome) -> ForageStyle:
	var s := ForageStyle.new()
	var fits := {}
	var best := 0.01
	for kind in Niche.kinds():
		var f := Niche.fit(g, kind)
		fits[kind.id] = f
		best = maxf(best, f)
	for id in fits:
		s.appeal[id] = float(fits[id]) / best
	var bold := maxf(g.value_of("armor"), g.value_of("toxin"))
	s.flee_range = g.sense_range() * lerpf(1.0, 0.35, bold)
	s.cruise = lerpf(0.5, 1.0, g.value_of("speed"))
	s.steer = g.turn_rate() * 0.5
	s.basks = EnergySources.makes_energy(g)
	return s


## One of the closest patches, likelier the better its food suits this
## body, the fuller it is and the nearer it is. Null if none are loaded.
func pick_patch(patches: Array[FoodPatch], me: Vector2, rng: RandomNumberGenerator) -> FoodPatch:
	var near: Array = patches.filter(func(p: FoodPatch) -> bool: return not p.hidden)
	near.sort_custom(func(a: FoodPatch, b: FoodPatch) -> bool:
		return me.distance_squared_to(a.center) < me.distance_squared_to(b.center))
	near = near.slice(0, CHOICES)
	if near.is_empty():
		return null
	var weights: Array[float] = []
	var total := 0.0
	for item in near:
		var patch: FoodPatch = item
		var a: float = appeal.get(patch.kind.id, 0.0)
		var fullness := 0.2 + float(patch.count) / maxf(patch.target, 1.0)
		var w := a * a * fullness / (1.0 + me.distance_to(patch.center) / NEAR)
		weights.append(w)
		total += w
	if total <= 0.0:
		return near[rng.randi() % near.size()]
	var roll := rng.randf() * total
	for i in near.size():
		roll -= weights[i]
		if roll <= 0.0:
			return near[i]
	return near[near.size() - 1]
