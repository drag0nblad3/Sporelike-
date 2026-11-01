class_name Ecosystem
extends Node3D
## Owns the living world: food, the AI members of the player's species and
## the predators. Resolves eating, predation and reproduction each frame.

signal species_changed

const START_POPULATION := 14
const MAX_POPULATION := 40
const PREDATOR_COUNT := 3
const REPRODUCE_AT := 10.0

var arena_radius := 30.0
var food: FoodField
var player: PlayerCell
var rng := RandomNumberGenerator.new()
var species: Array[SpeciesCell] = []
var predators: Array[Predator] = []
var births := 0

var _founder: Genome


func setup(arena: float, founder: Genome) -> void:
	arena_radius = arena
	_founder = founder


func _ready() -> void:
	rng.randomize()
	food = FoodField.new()
	food.setup(arena_radius, rng)
	add_child(food)
	for _i in START_POPULATION:
		spawn_member(_founder.mutated(rng).mutated(rng), _random_point(4.0, 20.0), 6.0)
	for _i in PREDATOR_COUNT:
		_spawn_predator(_random_point(14.0, arena_radius - 3.0))


func _physics_process(_delta: float) -> void:
	var prey := prey_list()
	var movers: Array[Vector2] = []
	for org in prey:
		_feed(org)
		movers.append(org.flat_pos())
	food.startle_near(movers)
	_hunt(prey)
	_reproduce()


## Closest predator within max_range of pos, or null.
func nearest_predator(pos: Vector2, max_range: float) -> Predator:
	var best: Predator = null
	var best_d := max_range
	for p in predators:
		var d := pos.distance_to(p.flat_pos())
		if d < best_d:
			best_d = d
			best = p
	return best


## Average of each trait across the AI species members.
func trait_averages() -> Dictionary:
	var sums := {}
	for t in Genome.TRAITS:
		sums[t] = 0.0
	if species.is_empty():
		return sums
	for member in species:
		for t in Genome.TRAITS:
			sums[t] += member.genome.values[t]
	for t in Genome.TRAITS:
		sums[t] /= species.size()
	return sums


func spawn_member(g: Genome, at: Vector2, start_energy: float) -> SpeciesCell:
	var cell := SpeciesCell.new()
	cell.setup(g, arena_radius, start_energy)
	cell.ecosystem = self
	cell.position = Vector3(at.x, 0.0, at.y)
	cell.died.connect(_on_member_died)
	add_child(cell)
	species.append(cell)
	species_changed.emit()
	return cell


func _spawn_predator(at: Vector2) -> void:
	var hunter := Predator.new()
	hunter.setup(Predator.make_genome(), arena_radius, 1.0)
	hunter.ecosystem = self
	hunter.position = Vector3(at.x, 0.0, at.y)
	add_child(hunter)
	predators.append(hunter)


func _feed(org: Organism) -> void:
	if not org.alive:
		return
	var gained := food.consume_near(org)
	if gained > 0.0:
		org.eat(gained)


func _hunt(targets: Array[Organism]) -> void:
	for hunter in predators:
		if hunter.cooldown > 0.0:
			continue
		for prey in targets:
			if not prey.alive or not hunter.wants(prey):
				continue
			var reach := hunter.radius() + prey.radius() * 0.5
			if hunter.flat_pos().distance_to(prey.flat_pos()) <= reach:
				hunter.try_bite(prey, rng)
				break


func _reproduce() -> void:
	for item in species.duplicate():
		if species.size() >= MAX_POPULATION:
			return
		var parent := item as SpeciesCell
		if parent.alive and parent.energy >= REPRODUCE_AT:
			parent.energy *= 0.5
			var offset := Vector2.from_angle(rng.randf() * TAU) * parent.radius() * 2.0
			spawn_member(parent.genome.mutated(rng), parent.flat_pos() + offset, parent.energy)
			births += 1


## Every living organism a predator might hunt, the player included.
func prey_list() -> Array[Organism]:
	var list: Array[Organism] = []
	for member in species:
		if member.alive:
			list.append(member)
	if is_instance_valid(player) and player.alive:
		list.append(player)
	return list


func _random_point(min_dist: float, max_dist: float) -> Vector2:
	return Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(min_dist, max_dist)


func _on_member_died(org: Organism, _cause: String) -> void:
	species.erase(org as SpeciesCell)
	species_changed.emit()
