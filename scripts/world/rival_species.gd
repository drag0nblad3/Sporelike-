class_name RivalSpecies
extends Node
## Another species sharing the sea: competes for food and feeds the hunters.
## Breeds on its own and evolves a little each generation, more slowly than
## the player's species, toward a niche (see Niche): food its body suits
## that the other species leave alone.

const START_POPULATION := 10
const MAX_POPULATION := 18
## Influence of its one automatic pick per generation (the player's is
## 0.5x to 2x, plus bonus picks).
const EVOLVE_INFLUENCE := 0.6
## How strongly its niche pulls, as a habit strength (see Niche.push).
const NICHE_PULL := 0.7

var ecosystem: Ecosystem
var species_name := ""
var colour := Color.WHITE
var template: Genome
var members: Array[RivalCell] = []
## Food kind id it is specializing in, and whether it just switched.
var niche := ""
var _moved := false


func setup(eco: Ecosystem, title: String, tint: Color, genome: Genome) -> void:
	ecosystem = eco
	species_name = title
	colour = tint
	template = genome


## Releases a founding group around this point.
func found(home: Vector2) -> void:
	var rng := ecosystem.rng
	for _i in START_POPULATION:
		var at := home + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 6.0)
		spawn(template.mutated(rng), at, 6.0)


func spawn(g: Genome, at: Vector2, start_energy: float) -> RivalCell:
	var cell := RivalCell.new()
	cell.setup(g, start_energy)
	cell.colour = colour
	cell.group_name = species_name
	cell.ecosystem = ecosystem
	cell.position = Vector3(at.x, 0.0, at.y)
	cell.died.connect(func(org: Organism, _cause: String) -> void:
		members.erase(org as RivalCell))
	add_child(cell)
	members.append(cell)
	return cell


func _physics_process(_delta: float) -> void:
	for item in members.duplicate():
		var parent := item as RivalCell
		if members.size() >= MAX_POPULATION:
			return
		if parent.alive and not parent.dormant and parent.energy >= Ecosystem.REPRODUCE_AT:
			parent.energy *= 0.5
			var offset := Vector2.from_angle(randf() * TAU) * parent.radius() * 2.0
			spawn(parent.genome.mutated(ecosystem.rng), parent.flat_pos() + offset, parent.energy)


## Evolves like the player's species, steered by its own eating habits
## plus a pull toward its niche: a little habit drift and one automatic
## pick, the offer that best suits those habits.
func evolve(rng: RandomNumberGenerator, habits: Habits, crowding: Dictionary) -> void:
	var before := niche
	niche = Niche.choose(template, crowding, niche)
	_moved = before != "" and before != niche
	Niche.push(habits, niche, NICHE_PULL)
	var genomes: Array[Genome] = [template]
	for cell in members:
		genomes.append(cell.genome)
	HabitDrift.apply_all(habits, genomes)
	var choices := PickRoller.roll(rng, 3, Genome.average(genomes), template, habits)
	var best: MutationChoice = null
	var best_score := -1.0
	for c in choices:
		var hint := habits.feature_hint(c.feature_id) if c.feature_id != "" \
			else habits.trait_hint(c.trait_name)
		var score := hint + rng.randf() * 0.3
		if score > best_score:
			best_score = score
			best = c
	if best:
		for g in genomes:
			best.apply_to(g, EVOLVE_INFLUENCE)


## "living off plankton clouds", or "moving to ..." after a switch.
func niche_words() -> String:
	if niche == "":
		return ""
	return ("moving to " if _moved else "living off ") + str(Niche.WORDS[niche])
