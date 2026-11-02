class_name HabitDrift
extends RefCounted
## Use shapes the body: after each generation the player's habits (see
## Habits) give the whole species a small push toward what the player did,
## far smaller than a pick. Like picks, it only adds; diet leans toward
## what the player ate.

## Most a trait moves from one generation of habits (a pick at x1 is 0.12).
const MAX_STEP := 0.03
## Weaker hints than this do nothing, so ordinary play is not noise.
const MIN_HINT := 0.2
## At most this many changed numbers are listed on the population screen.
const MAX_LINES := 4


static func apply(habits: Habits, genome: Genome) -> void:
	for t in Genome.TRAITS:
		var hint := habits.trait_hint(t)
		if hint < MIN_HINT:
			continue
		var step := MAX_STEP * hint
		if t == "diet":
			step *= signf(habits.diet_lean())
		genome.values[t] = clampf(genome.values[t] + step, 0.0, 1.0)


static func apply_all(habits: Habits, genomes: Array[Genome]) -> void:
	for g in genomes:
		apply(habits, g)


## Two lines for the population screen: the habits that counted, then what
## they did to a typical member. "" when no habit was strong enough.
static func describe(habits: Habits, before: Genome) -> String:
	var names := habits.shown(MIN_HINT)
	if names.is_empty():
		return ""
	var after := before.copy()
	apply(habits, after)
	var lines := StatSheet.changes(before, after)
	var text := "Your habits shaped your species: " + ", ".join(names)
	if not lines.is_empty():
		text += "\n" + "   ".join(lines.slice(0, MAX_LINES))
	return text
