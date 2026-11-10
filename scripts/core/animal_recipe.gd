class_name AnimalRecipe
extends RefCounted
## The choices behind a customized stage 3 animal: one pick per row of
## the body customizer (AnimalEditor), each an index into that row's
## options. AnimalBuilder turns a recipe into an AnimalBody.

const HUES := ["red", "orange", "yellow", "lime", "green", "teal", "blue", "violet", "pink"]

## Each row: [key, label, options].
const ROWS := [
	["skin", "Body", ["segments", "smooth"]],
	["posture", "Posture", ["crawl", "leaning biped", "upright biped"]],
	["symmetry", "Symmetry", ["two-sided", "radial"]],
	["segments", "Segments", ["2", "3", "4", "5", "6", "7", "8"]],
	["shape", "Shape", ["round", "flat", "keel", "tube", "bulb"]],
	["size", "Build", ["slim", "medium", "bulky"]],
	["taper", "Taper", ["even", "narrow tail", "big rear"]],
	["head_at", "Head on", ["front", "raised", "low", "mid-back"]],
	["neck", "Neck", ["none", "short", "long"]],
	["mouth", "Mouth", ["none", "smile", "beak", "mandibles", "tusks", "trunk", "sucker"]],
	["legs", "Leg pairs", ["0", "1", "2", "3", "4", "5", "6"]],
	["leg_length", "Leg length", ["short", "medium", "long"]],
	["leg_build", "Leg build", ["thin", "sturdy", "mighty"]],
	["stance", "Stance", ["under body", "upright", "wide", "crouched", "back knees"]],
	["limb", "Limbs", ["legs", "tentacles"]],
	["joints", "Joints", ["2", "3", "4"]],
	["foot", "Feet", ["pad", "claw", "spike", "sucker"]],
	["arms", "Arms", ["none", "1 pair", "2 pairs"]],
	["arm_tip", "Arm ends", ["hand", "pincer", "blade"]],
	["claw", "Big claw", ["none", "left", "right"]],
	["eyes", "Eyes", ["1", "2", "3", "4", "5", "6", "7", "8"]],
	["eye_set", "Eye place", ["front", "wide", "top"]],
	["stalks", "Eye stalks", ["no", "yes"]],
	["horns", "Horns", ["none", "one", "two"]],
	["feelers", "Feelers", ["no", "yes"]],
	["back", "Back", ["none", "spikes", "sail", "plates"]],
	["arch", "Back arch", ["flat", "low", "high"]],
	["tail", "Tail", ["none", "fork", "club", "spike"]],
	["pattern", "Pattern", ["plain", "stripes", "spots", "bands"]],
	["shading", "Shading", ["even", "dark back", "light belly", "both"]],
	["texture", "Texture", ["smooth", "scales", "warts", "fuzz"]],
	["covering", "Covering", ["none", "a few feathers", "full feathers", "quills"]],
	["oversize", "Oversize", ["none", "head", "eyes", "legs", "arms", "tail", "horns"]],
	["hue", "Colour", HUES],
	["hue2", "Colour 2", HUES],
]

var picks := {}


func _init() -> void:
	for row: Array in ROWS:
		picks[row[0]] = 0
	picks["segments"] = 3
	picks["size"] = 1
	picks["legs"] = 2
	picks["leg_length"] = 1
	picks["stance"] = 1
	picks["eyes"] = 1
	picks["mouth"] = 1
	picks["leg_build"] = 1
	picks["hue"] = 4
	picks["hue2"] = 6


## The chosen option of a row, as its text.
func value(key: String) -> String:
	var options := options_of(key)
	return options[clampi(index(key), 0, options.size() - 1)]


func index(key: String) -> int:
	var at: int = picks.get(key, 0)
	return at


## Moves a row's pick by `step`, wrapping around its options.
func shift(key: String, step: int) -> void:
	picks[key] = posmod(index(key) + step, options_of(key).size())


func options_of(key: String) -> Array:
	for row: Array in ROWS:
		if row[0] == key:
			var options: Array = row[2]
			return options
	return [""]


func roll(rng: RandomNumberGenerator) -> void:
	for row: Array in ROWS:
		var options: Array = row[2]
		picks[row[0]] = rng.randi() % options.size()
