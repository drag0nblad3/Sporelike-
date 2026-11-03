class_name Predator
extends Organism
## A large hunter. Chases prey it can sense and swallow. Armor can deflect a
## bite; toxin stings it, stuns it, and teaches it to avoid prey at least
## that toxic from then on. Never starves; instead the whole HunterLineage
## evolves when hunters go hungry.

const BITE_COOLDOWN := 2.5
const STUNG_COOLDOWN := 6.0
## Prey must be smaller than this share of the hunter's radius to swallow,
## before any Wide maw upgrades.
const SWALLOW_RATIO := HunterLineage.BASE_SWALLOW
## Hunters keep this body radius whatever their size trait; cells can now
## grow to twice it.
const RADIUS := 1.2

var ecosystem: Ecosystem
var lineage := HunterLineage.new()
var cooldown := 0.0
## Prey with toxin at or above this is left alone. Lowered by bad experiences.
var avoid_toxin := 1.0


static func make_genome() -> Genome:
	var g := Genome.new()
	g.values["size"] = 1.0
	g.values["speed"] = 0.45
	g.values["agility"] = 0.3
	g.values["sense"] = 0.55
	g.values["armor"] = 0.0
	g.values["jaw"] = 1.0
	return g


func _init() -> void:
	upkeep_scale = 0.0


func radius() -> float:
	return RADIUS


func tint() -> Color:
	return Color(1.0, 0.3, 0.25, 0.7)


func wants(prey: Organism) -> bool:
	return prey.radius() < radius() * lineage.swallow_ratio() \
		and prey.genome.value_of("toxin") < avoid_toxin and prey.hidden_time <= 0.0


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
	var prey := _nearest_prey()
	if prey:
		move_input = (prey.flat_pos() - flat_pos()).normalized()
	else:
		move_input = wander_input(delta)


func _nearest_prey() -> Organism:
	var best: Organism = null
	var best_d := genome.sense_range() * lineage.sight_factor()
	for prey in ecosystem.prey_list():
		if not wants(prey):
			continue
		var d := flat_pos().distance_to(prey.flat_pos())
		if d < best_d:
			best_d = d
			best = prey
	return best
