class_name Hardship
extends RefCounted
## Keeps a struggling game going: after a bad generation (the species
## shrank a lot, or the player starved) every member becomes a little more
## efficient, burning less energy, up to Genome.MAX_SAVING less in all.

const SHRINK_LIMIT := 0.25


## Applies the adaptation if this generation went badly and returns the
## line for the population screen, or "" if it went fine.
static func adapt(stats: GenerationStats, genomes: Array[Genome]) -> String:
	var lost := 0.0
	if stats.start_population > 0:
		lost = clampf(1.0 - float(stats.end_population) / stats.start_population, 0.0, 1.0)
	if lost < SHRINK_LIMIT and stats.ended_by != "starved":
		return ""
	var gain := 0.08 + 0.12 * lost
	var total := 0.0
	for g in genomes:
		g.efficiency = minf(g.efficiency + gain, 1.0)
		total += g.efficiency
	if genomes.is_empty():
		return ""
	var saved := roundi(total / genomes.size() * Genome.MAX_SAVING * 100.0)
	return "Hard times: your species adapted and now burns %d%% less energy" % saved
