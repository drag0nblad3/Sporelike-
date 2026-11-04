class_name Predator
extends Organism
## A hunter. This base kind (Didinium, the barrel ciliate) chases prey it
## can sense and swallows it; AmbushHunter, PackHunter and FilterHunter hunt
## in their own ways. Armor can deflect a bite; toxin stings it, stuns it,
## and teaches it to avoid prey at least that toxic from then on. Never
## starves; instead its kind's HunterLineage evolves when it goes hungry.

const BITE_COOLDOWN := 2.0
const STUNG_COOLDOWN := 6.0
const SCAN_INTERVAL := 0.2

var ecosystem: Ecosystem
var kind := HunterKind.CHASER
var lineage := HunterLineage.new()
var cooldown := 0.0
## Prey with toxin at or above this is left alone. Lowered by bad experiences.
var avoid_toxin := 1.0
## nearest_prey() rescans everyone only every SCAN_INTERVAL seconds and
## keeps chasing the last pick in between.
var _target: Organism
var _chasing := false
var _scan_timer := randf() * SCAN_INTERVAL


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


## The closest prey in sight, rechecked a few times a second.
func nearest_prey() -> Organism:
	_scan_timer -= get_physics_process_delta_time()
	if _chasing and not (is_instance_valid(_target) and _still_hunting(_target)):
		_scan_timer = 0.0
	if _scan_timer > 0.0:
		return _target if _chasing else null
	_scan_timer = SCAN_INTERVAL
	_target = _scan()
	_chasing = _target != null
	return _target


func _still_hunting(prey: Organism) -> bool:
	return prey.alive and not prey.dormant and wants(prey) \
		and flat_pos().distance_squared_to(prey.flat_pos()) < pow(sight_range() * 1.2, 2.0)


func _scan() -> Organism:
	var best: Organism = null
	var best_d := sight_range()
	var me := flat_pos()
	for prey in ecosystem.prey_list():
		var d := me.distance_to(prey.flat_pos())
		if d >= best_d or not prey.alive or not wants(prey):
			continue
		best_d = d
		best = prey
	return best
