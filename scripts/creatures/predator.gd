class_name Predator
extends Organism
## A hunter. This base kind (Didinium, the barrel ciliate) chases prey it
## can sense and swallows it; AmbushHunter, PackHunter and FilterHunter hunt
## in their own ways. Armor can deflect a bite; toxin stings it, stuns it,
## and teaches it to avoid prey at least that toxic from then on. Never
## starves; instead its kind's HunterLineage evolves when it goes hungry.

const BITE_COOLDOWN := 2.5
const STUNG_COOLDOWN := 6.0

var ecosystem: Ecosystem
var kind := HunterKind.CHASER
var lineage := HunterLineage.new()
var cooldown := 0.0
## Prey with toxin at or above this is left alone. Lowered by bad experiences.
var avoid_toxin := 1.0


func _init() -> void:
	upkeep_scale = 0.0


func radius() -> float:
	return HunterKind.radius(kind)


func tint() -> Color:
	return HunterKind.tint(kind)


## How far off prey notice this hunter, as a share of their flee range.
func notice_scale() -> float:
	return 1.0


func sight_range() -> float:
	return genome.sense_range() * lineage.sight_factor()


func wants(prey: Organism) -> bool:
	return can_swallow(prey) and prey.hidden_time <= 0.0


func can_swallow(prey: Organism) -> bool:
	return prey.radius() < radius() * lineage.swallow_ratio() \
		and prey.genome.value_of("toxin") < avoid_toxin


func try_bite(prey: Organism, rng: RandomNumberGenerator) -> void:
	cooldown = BITE_COOLDOWN
	if rng.randf() < prey.genome.armor():
		return
	if rng.randf() < prey.genome.toxin() * lineage.sting_factor():
		cooldown = STUNG_COOLDOWN
		avoid_toxin = minf(avoid_toxin, prey.genome.value_of("toxin") - 0.05)
		return
	lineage.meals += 1
	prey.die("eaten")


func think(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if cooldown > 0.0:
		move_input = wander_input(delta) * 0.5
		return
	var prey := nearest_prey()
	if prey:
		move_input = (prey.flat_pos() - flat_pos()).normalized()
	else:
		move_input = wander_input(delta)


func nearest_prey() -> Organism:
	var best: Organism = null
	var best_d := sight_range()
	for prey in ecosystem.prey_list():
		if not wants(prey):
			continue
		var d := flat_pos().distance_to(prey.flat_pos())
		if d < best_d:
			best_d = d
			best = prey
	return best
