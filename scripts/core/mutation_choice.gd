class_name MutationChoice
extends RefCounted
## One upgrade the player can encourage across the whole species between
## generations: a nudge to a trait, or a new level of a branching Feature.

const STEP := 0.05
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
## What each nudge does, for the button's second line.
const EFFECTS := {
	"size": ["Longer reach, chews faster, turns slower", "Turns faster, burns less"],
	"speed": ["Swims faster", "Burns less energy"],
	"agility": ["Speeds up and turns faster", "Burns less energy"],
	"sense": ["Notices food and hunters farther away", "Burns less energy"],
	"armor": ["Deflects more bites, a bit slower", "Faster, burns less"],
	"toxin": ["Stings hunters that bite", "Burns less energy"],
	"diet": ["More energy from meat, less from plants", "More from plants, less from meat"],
	"jaw": ["Cracks tougher food", "Burns less energy"],
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


func effect() -> String:
	if feature_id != "":
		return Feature.effect(feature_id)
	var pair: Array = EFFECTS[trait_name]
	return pair[0] if direction > 0.0 else pair[1]


func apply_to(genome: Genome, influence: float) -> void:
	if feature_id != "":
		var level := mini(genome.feature(feature_id) + 1, Feature.max_level(feature_id))
		genome.features[feature_id] = level
		return
	var value: float = genome.values[trait_name]
	genome.values[trait_name] = clampf(value + STEP * influence * direction, 0.0, 1.0)


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
