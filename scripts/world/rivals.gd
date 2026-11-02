class_name Rivals
extends Node
## The few rival species around the player. Founds them with random traits
## a little weaker overall than the player's species, evolves them between
## generations, and replaces any that die out with a new arrival.

const COUNT := 3
const NAMES := ["Amber", "Violet", "Lime"]
const HUES := [0.08, 0.78, 0.24]
## A new rival's total trait strength compared to the player's species.
const STRENGTH := 0.85

var ecosystem: Ecosystem
var groups: Array[RivalSpecies] = []


## Founds every rival, from saved templates where there are any.
func start(player: Genome, saved: Array) -> void:
	for i in COUNT:
		var genome := _random_template(player)
		if i < saved.size():
			var data: Dictionary = saved[i]
			genome = Genome.from_dict(data)
		_add(i, genome)


func members() -> Array[RivalCell]:
	var all: Array[RivalCell] = []
	for group in groups:
		all.append_array(group.members)
	return all


## Evolves each rival a little and replaces extinct ones. Returns a line for
## the population screen.
func end_generation(player: Genome) -> String:
	var parts := PackedStringArray()
	for i in groups.size():
		var group := groups[i]
		if group.members.is_empty():
			group.queue_free()
			groups[i] = _make(i, _random_template(player))
			parts.append("%s died out, a new %s arrived" % [NAMES[i], NAMES[i]])
		else:
			group.evolve(ecosystem.rng)
			parts.append("%s %d" % [NAMES[i], group.members.size()])
	return "Rival species: " + ", ".join(parts)


func to_save() -> Array:
	var out: Array = []
	for group in groups:
		out.append(group.template.to_dict())
	return out


func _add(index: int, genome: Genome) -> void:
	groups.append(_make(index, genome))


func _make(index: int, genome: Genome) -> RivalSpecies:
	var group := RivalSpecies.new()
	var colour := Color.from_hsv(HUES[index], 0.75, 1.0, 0.7)
	group.setup(ecosystem, NAMES[index], colour, genome)
	add_child(group)
	var rng := ecosystem.rng
	group.found(ecosystem.focus + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20.0, 40.0))
	return group


## Random traits, scaled so their total is a little below the player's.
func _random_template(player: Genome) -> Genome:
	var rng := ecosystem.rng
	var g := Genome.new()
	var total := 0.0
	var target := 0.0
	for t in Genome.TRAITS:
		g.values[t] = rng.randf()
		if t != "diet":
			total += g.values[t]
			target += player.value_of(t)
	target *= STRENGTH
	for t in Genome.TRAITS:
		if t != "diet":
			g.values[t] = clampf(g.value_of(t) * target / maxf(total, 0.01), 0.0, 1.0)
	return g
