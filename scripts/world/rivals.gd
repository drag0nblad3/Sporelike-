class_name Rivals
extends Node
## The few rival species around the player. Founds them with random traits
## a little weaker overall than the player's species, evolves them between
## generations, and replaces any that die out with a new arrival. Some new
## rivals descend from cells the player saved (OrganismCollection), toned
## down to the same strength limit.

const COUNT := 3
const NAMES := ["Amber", "Violet", "Lime"]
const HUES := [0.08, 0.78, 0.24]
## A new rival's total trait strength compared to the player's species.
const STRENGTH := 0.85
## Chance a new rival is founded from a saved cell, when any are saved.
const FROM_SAVED := 0.5

var ecosystem: Ecosystem
var groups: Array[RivalSpecies] = []
## How the last new template came about, for the population screen.
var _last_origin := ""


## Founds every rival, from saved templates where there are any.
func start(player: Genome, saved: Array) -> void:
	for i in COUNT:
		var genome := _new_template(player)
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
			var genome := _new_template(player)
			groups[i] = _make(i, genome)
			parts.append("%s died out, a new %s arrived%s" % [NAMES[i], NAMES[i], _last_origin])
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


## A founding genome: a saved cell (sometimes) or random traits, scaled so
## its total is a little below the player's species.
func _new_template(player: Genome) -> Genome:
	var rng := ecosystem.rng
	var g := Genome.new()
	_last_origin = ""
	var saved: Dictionary = {}
	if rng.randf() < FROM_SAVED:
		saved = OrganismCollection.pick(rng)
	if saved.is_empty():
		for t in Genome.TRAITS:
			g.values[t] = rng.randf()
	else:
		var data: Dictionary = saved.get("genome", {})
		g = Genome.from_dict(data).mutated(rng)
		g.efficiency = 0.0
		_last_origin = " from your saved %s" % str(saved.get("label", "cell"))
	_cap_strength(g, player, saved.is_empty())
	return g


## Scales the non-diet traits to STRENGTH times the player's total; a saved
## cell is only ever scaled down, never up.
func _cap_strength(g: Genome, player: Genome, allow_up: bool) -> void:
	var total := 0.0
	var target := 0.0
	for t in Genome.TRAITS:
		if t != "diet":
			total += g.value_of(t)
			target += player.value_of(t)
	target *= STRENGTH
	if total <= target and not allow_up:
		return
	for t in Genome.TRAITS:
		if t != "diet":
			g.values[t] = clampf(g.value_of(t) * target / maxf(total, 0.01), 0.0, 1.0)
