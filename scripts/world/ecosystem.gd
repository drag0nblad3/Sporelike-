class_name Ecosystem
extends Node3D
## Owns the living world: food, the AI members of the player's species and
## the predators. Resolves eating, predation and reproduction each frame.

signal species_changed
signal member_died(cause: String)

const START_POPULATION := 30
const MAX_POPULATION := 100
const REPRODUCE_AT := 10.0

## Where the player is; new members and hunters appear around it.
var focus := Vector2.ZERO
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
## Saved rival templates (Genome dicts) and hunter upgrade levels.
var saved_rivals: Array = []
var rivals: Rivals
var hunters := HunterLineages.new()
## Speed multiplier for hunters and food; see Pace.
var others_pace := 1.0

var _founder: Genome
## prey_list() is built once per physics frame and shared: every hunter
## asks for it, and a fresh list each time was a lot of work.
var _prey: Array[Organism] = []
var _prey_frame := -1


func setup(founder: Genome) -> void:
	_founder = founder


func _ready() -> void:
	rng.randomize()
	food = FoodField.new()
	food.setup(rng)
	add_child(food)
	for entry in saved_members:
		var saved_genome: Genome = entry[0]
		var saved_at: Vector2 = entry[1]
		var saved_energy: float = entry[2]
		spawn_member(saved_genome, saved_at, saved_energy)
	if saved_members.is_empty():
		for _i in START_POPULATION:
			spawn_member(_founder.mutated(rng).mutated(rng), _random_point(3.0, 24.0), 6.0)
	rivals = Rivals.new()
	rivals.ecosystem = self
	add_child(rivals)
	rivals.start(_founder, saved_rivals)
	HunterSpawner.spawn_all(self)


func _physics_process(delta: float) -> void:
	food.refresh()
	var prey := prey_list()
	for org in prey:
		_feed(org, delta)
	food.startle_near(prey)
	_hunt(prey)
	_reproduce()


## Closest predator within max_range of pos, or null. Hunters lying in
## wait count as further away (Predator.notice_scale).
func nearest_predator(pos: Vector2, max_range: float) -> Predator:
	var best: Predator = null
	var best_d := max_range
	for p in predators:
		var d := pos.distance_to(p.flat_pos()) / p.notice_scale()
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
	others_pace = Pace.others(float(roster.averages().get("speed", 0.0)))
	FoodItem.pace = others_pace
	for hunter in predators:
		hunter.speed_scale = others_pace * hunter.lineage.speed_factor()


## The player's next body: a random awake member near the player if any,
## else any living member, or null if extinct.
func pick_parent() -> SpeciesCell:
	var awake: Array[SpeciesCell] = []
	for member in species:
		if not member.dormant:
			awake.append(member)
	var pool := awake if not awake.is_empty() else species
	if pool.is_empty():
		return null
	return pool[rng.randi() % pool.size()]


## Restart the species from one genome after an extinction.
func reseed(founder: Genome) -> void:
	for _i in START_POPULATION:
		spawn_member(founder.mutated(rng), _random_point(2.0, 12.0), 6.0)


func spawn_member(g: Genome, at: Vector2, start_energy: float) -> SpeciesCell:
	var cell := SpeciesCell.new()
	cell.setup(g, start_energy)
	cell.ecosystem = self
	cell.position = Vector3(at.x, 0.0, at.y)
	cell.died.connect(_on_member_died)
	add_child(cell)
	species.append(cell)
	roster.add(g)
	species_changed.emit()
	return cell


func _feed(org: Organism, delta: float) -> void:
	if not org.alive:
		return
	var gained := food.consume_near(org, delta)
	if gained > 0.0:
		org.eat(gained)
	EnergySources.feed(org, food.patches, delta)


func _hunt(targets: Array[Organism]) -> void:
	for hunter in predators:
		if hunter.cooldown > 0.0 or hunter.stun_time > 0.0:
			continue
		var at := hunter.flat_pos()
		var size := hunter.radius()
		for prey in targets:
			# Distance first: it is cheap and rules out almost everyone.
			var reach := size + prey.radius() * 0.5
			if at.distance_squared_to(prey.flat_pos()) > reach * reach:
				continue
			if prey.alive and hunter.wants(prey):
				hunter.try_bite(prey, rng)
				break


func _reproduce() -> void:
	for item in species.duplicate():
		if species.size() >= MAX_POPULATION:
			return
		var parent := item as SpeciesCell
		if parent.alive and not parent.dormant and parent.energy >= REPRODUCE_AT:
			parent.energy *= 0.5
			var offset := Vector2.from_angle(rng.randf() * TAU) * parent.radius() * 2.0
			spawn_member(parent.genome.mutated(rng), parent.flat_pos() + offset, parent.energy)
			births += 1


## Every living organism a predator might hunt: the player's species, the
## rival species and the player. Built once per physics frame; callers
## should still skip any that died since (alive is false).
func prey_list() -> Array[Organism]:
	var frame := Engine.get_physics_frames()
	if frame == _prey_frame:
		return _prey
	_prey_frame = frame
	var list: Array[Organism] = []
	for member in species:
		if member.alive and not member.dormant:
			list.append(member)
	if rivals:
		for member in rivals.members():
			if member.alive and not member.dormant:
				list.append(member)
	if is_instance_valid(player) and player.alive:
		list.append(player)
	_prey = list
	return list


func _random_point(min_dist: float, max_dist: float) -> Vector2:
	return focus + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(min_dist, max_dist)


func _on_member_died(org: Organism, cause: String) -> void:
	species.erase(org as SpeciesCell)
	member_died.emit(cause)
	species_changed.emit()
