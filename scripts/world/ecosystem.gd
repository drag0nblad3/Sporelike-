class_name Ecosystem
extends Node3D
## Owns the living world: food, the AI members of the player's species and
## the predators. Resolves eating, predation and reproduction each frame.

signal species_changed
signal member_died(cause: String)

const START_POPULATION := 30
const MAX_POPULATION := 100
const PREDATOR_COUNT := 7
const REPRODUCE_AT := 10.0

var arena_radius := 55.0
var map: BiomeMap
var food: FoodField
var player: PlayerCell
var rng := RandomNumberGenerator.new()
var species: Array[SpeciesCell] = []
var predators: Array[Predator] = []
var births := 0
var roster := SpeciesRoster.new()
## Members to restore from a save as [Genome, Vector2, energy]; set before
## the ecosystem enters the tree. Empty means start fresh from the founder.
var saved_members: Array = []

var _founder: Genome


func setup(biome_map: BiomeMap, founder: Genome) -> void:
	map = biome_map
	arena_radius = biome_map.radius
	_founder = founder


func _ready() -> void:
	rng.randomize()
	food = FoodField.new()
	food.setup(map, rng)
	add_child(food)
	for entry in saved_members:
		var saved_genome: Genome = entry[0]
		var saved_at: Vector2 = entry[1]
		var saved_energy: float = entry[2]
		spawn_member(saved_genome, saved_at, saved_energy)
	if saved_members.is_empty():
		for _i in START_POPULATION:
			spawn_member(_founder.mutated(rng).mutated(rng), _random_point(2.0, 12.0), 6.0)
	for _i in PREDATOR_COUNT:
		_spawn_predator(_random_point(20.0, arena_radius - 3.0))


func _physics_process(delta: float) -> void:
	food.refresh()
	var prey := prey_list()
	var movers: Array[Vector2] = []
	for org in prey:
		_feed(org, delta)
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


## Average of each trait across everyone in the species this generation,
## including members who have since died.
func trait_averages() -> Dictionary:
	return roster.averages()


## Called as each generation begins: the roster restarts from the living.
func start_roster() -> void:
	var genomes: Array[Genome] = []
	for member in species:
		genomes.append(member.genome)
	if is_instance_valid(player):
		genomes.append(player.genome)
	roster.reset(genomes)


## A random living member to be the player's next body, or null if extinct.
func pick_parent() -> SpeciesCell:
	if species.is_empty():
		return null
	return species[rng.randi() % species.size()]


## Restart the species from one genome after an extinction.
func reseed(founder: Genome) -> void:
	for _i in START_POPULATION:
		spawn_member(founder.mutated(rng), _random_point(2.0, 12.0), 6.0)


func spawn_member(g: Genome, at: Vector2, start_energy: float) -> SpeciesCell:
	var cell := SpeciesCell.new()
	cell.setup(g, arena_radius, start_energy)
	cell.ecosystem = self
	cell.position = Vector3(at.x, 0.0, at.y)
	cell.died.connect(_on_member_died)
	add_child(cell)
	species.append(cell)
	roster.add(g)
	species_changed.emit()
	return cell


func _spawn_predator(at: Vector2) -> void:
	var hunter := Predator.new()
	hunter.setup(Predator.make_genome(), arena_radius, 1.0)
	hunter.ecosystem = self
	hunter.position = Vector3(at.x, 0.0, at.y)
	add_child(hunter)
	predators.append(hunter)


func _feed(org: Organism, delta: float) -> void:
	if not org.alive:
		return
	var gained := food.consume_near(org, delta)
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


func _on_member_died(org: Organism, cause: String) -> void:
	species.erase(org as SpeciesCell)
	member_died.emit(cause)
	species_changed.emit()
