class_name EvolvedSpecies
extends RefCounted
## Makes up a single-celled species as it might look at the end of stage 1,
## for testing stage 2 without playing stage 1 through: a few traits pushed
## high (a specialisation), the rest middling, a diet, some efficiency and
## a handful of organelles.


static func random(rng: RandomNumberGenerator) -> Genome:
	var g := Genome.new()
	for t in Genome.TRAITS:
		g.values[t] = rng.randf_range(0.2, 0.55)
	g.values["armor"] = rng.randf_range(0.0, 0.4)
	g.values["toxin"] = rng.randf_range(0.0, 0.4)
	g.values["diet"] = rng.randf()
	# Two or three traits the species specialised in.
	var picks: Array = Genome.TRAITS.duplicate()
	picks.erase("diet")
	for i in rng.randi_range(2, 3):
		var t: String = picks.pop_at(rng.randi_range(0, picks.size() - 1))
		g.values[t] = rng.randf_range(0.65, 0.95)
	g.efficiency = rng.randf_range(0.1, 0.5)
	var ids: Array = Feature.ALL.keys()
	for i in rng.randi_range(2, 4):
		var id: String = ids[rng.randi_range(0, ids.size() - 1)]
		g.features[id] = rng.randi_range(1, Feature.max_level(id))
	return g
