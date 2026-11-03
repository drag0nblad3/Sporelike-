class_name MutationChoice
extends RefCounted
## One upgrade the player can encourage across the whole species between
## generations: a nudge to a trait, or a new level of an organelle (Feature).

## Base trait change per pick at x1 influence.
const STEP := 0.12
## Pushing a trait further the way it already leans adds up to this much
## more again, so picks drive the species toward a specialty.
const SPECIALIZE := 1.0
## Traits that grow faster per pick than the rest.
const FAST := {"armor": 1.6, "toxin": 1.6}
## Picks only ever add. Diet is the one two-way trait: its second label is
## the pick that moves it toward plants.
const LABELS := {
	"size": ["Bigger cell"],
	"speed": ["Longer flagellum"],
	"agility": ["More cilia"],
	"sense": ["Bigger eyespot"],
	"armor": ["More silica spines"],
	"toxin": ["More toxicysts"],
	"diet": ["Digest more prey", "Digest more plant food"],
	"jaw": ["Stronger cell mouth"],
	"efficiency": ["Leaner metabolism"],
}
## The plain energy-saving pick: how much efficiency it adds at x1
## influence. PickRoller decides which choices are offered.
const EFFICIENCY_STEP := 0.25

## Starts the card line naming the habit a pick suits (PickCard tints it).
const REASON_PREFIX := "Suits your "

var trait_name := ""
var direction := 1.0
## Set instead of trait_name for a branching upgrade.
var feature_id := ""
## The player's habit this pick suits (see Habits), or "".
var reason := ""


func label() -> String:
	if BodyForm.ALL.has(feature_id):
		return "Body form: " + Feature.label(feature_id)
	if feature_id != "":
		return "New organelle: " + Feature.label(feature_id)
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
	if BodyForm.ALL.has(feature_id):
		lines.insert(1, "Level %d of %d" % [after.feature(feature_id), BodyForm.MAX_LEVEL])
	if lines.is_empty():
		lines.append("No noticeable change")
	if reason != "":
		lines.insert(0, REASON_PREFIX + reason)
	return "\n".join(lines)


func apply_to(genome: Genome, influence: float) -> void:
	if feature_id != "":
		var level := mini(genome.feature(feature_id) + 1, Feature.max_level(feature_id))
		genome.features[feature_id] = level
		return
	if trait_name == "efficiency":
		genome.efficiency = minf(genome.efficiency + EFFICIENCY_STEP * influence, 1.0)
		return
	var value: float = genome.values[trait_name]
	var lean := value if direction > 0.0 else 1.0 - value
	var step := STEP * influence * (1.0 + SPECIALIZE * lean) * float(FAST.get(trait_name, 1.0))
	genome.values[trait_name] = clampf(value + step * direction, 0.0, 1.0)
