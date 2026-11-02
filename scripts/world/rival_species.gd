class_name RivalSpecies
extends Node
## Another species sharing the sea: competes for food and feeds the hunters.
## Breeds on its own and evolves a little each generation, more slowly than
## the player's species, mostly deepening what it is already good at.

const START_POPULATION := 10
const MAX_POPULATION := 18
## Influence of its one automatic pick per generation (the player's is
## 0.5x to 2x, plus bonus picks).
const EVOLVE_INFLUENCE := 0.6

var ecosystem: Ecosystem
var species_name := ""
var colour := Color.WHITE
var template: Genome
var members: Array[RivalCell] = []


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


## One automatic pick, usually pushing one of its strongest traits.
func evolve(rng: RandomNumberGenerator) -> void:
	var ranked: Array = Genome.TRAITS.duplicate()
	ranked.erase("diet")
	ranked.sort_custom(func(a: String, b: String) -> bool:
		return template.value_of(a) > template.value_of(b))
	var choice := MutationChoice.new()
	choice.trait_name = ranked[rng.randi() % 3]
	if template.value_of(choice.trait_name) >= 1.0:
		choice.trait_name = ranked[ranked.size() - 1]
	choice.apply_to(template, EVOLVE_INFLUENCE)
	for cell in members:
		choice.apply_to(cell.genome, EVOLVE_INFLUENCE)
