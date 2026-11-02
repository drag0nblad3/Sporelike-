class_name MutationChoice
extends RefCounted
## One upgrade the player can encourage across the whole species between
## generations: a nudge to a trait, or a new level of a branching Feature.

## Base trait change per pick at x1 influence.
const STEP := 0.12
## Pushing a trait further the way it already leans adds up to this much
## more again, so picks drive the species toward a specialty.
const SPECIALIZE := 1.0
const LABELS := {
	"size": ["Bigger body", "Smaller body"],
	"speed": ["Longer tail", "Shorter tail"],
	"agility": ["More cilia", "Fewer cilia"],
	"sense": ["Sharper eye", "Duller eye"],
	"armor": ["Thicker armor", "Lighter armor"],
	"toxin": ["More toxic", "Less toxic"],
	"diet": ["Eat more meat", "Eat more plants"],
	"jaw": ["Stronger jaw", "Weaker jaw"],
}
## Chance one of the choices is a branching feature, when any is available.
const FEATURE_CHANCE := 0.6

var trait_name := ""
var direction := 1.0
## Set instead of trait_name for a branching upgrade.
var feature_id := ""


func label() -> String:
	if feature_id != "":
		return "New: " + Feature.label(feature_id)
	var pair: Array = LABELS[trait_name]
	return pair[0] if direction > 0.0 else pair[1]


## What this choice would do to a typical member, in numbers: every stat
## that changes (gains and costs alike), after a short description for
## branching features.
func effect(template: Genome, influence: float) -> String:
	var after := template.copy()
	apply_to(after, influence)
	var lines := StatSheet.changes(template, after)
	if feature_id != "":
		lines.insert(0, Feature.effect(feature_id))
	if lines.is_empty():
		lines.append("No noticeable change")
	return "\n".join(lines)


func apply_to(genome: Genome, influence: float) -> void:
	if feature_id != "":
		var level := mini(genome.feature(feature_id) + 1, Feature.max_level(feature_id))
		genome.features[feature_id] = level
		return
	var value: float = genome.values[trait_name]
	var lean := value if direction > 0.0 else 1.0 - value
	var step := STEP * influence * (1.0 + SPECIALIZE * lean)
	genome.values[trait_name] = clampf(value + step * direction, 0.0, 1.0)


## A few different choices: trait nudges (usually up), and sometimes one
## branching feature the species has unlocked.
static func roll(rng: RandomNumberGenerator, count: int, averages: Dictionary,
		template: Genome) -> Array[MutationChoice]:
	var names: Array = Genome.TRAITS.duplicate()
	names.shuffle()
	var picks: Array[MutationChoice] = []
	var unlocked := Feature.available(averages, template)
	if not unlocked.is_empty() and rng.randf() < FEATURE_CHANCE:
		var f := MutationChoice.new()
		f.feature_id = unlocked[rng.randi() % unlocked.size()]
		picks.append(f)
	for i in names.size():
		if picks.size() >= count:
			break
		var c := MutationChoice.new()
		c.trait_name = names[i]
		c.direction = 1.0 if rng.randf() < 0.7 else -1.0
		picks.append(c)
	return picks
