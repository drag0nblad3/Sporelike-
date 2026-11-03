class_name Habits
extends RefCounted
## What the player's cell did during one generation (filled by HabitTracker),
## turned into 0..1 hints per trait and organelle. Hints nudge the species
## a little (HabitDrift) and make matching upgrades show up more often
## (PickRoller).

## habit -> [name on screen, amount that counts as a full habit]. Timed
## habits count a share of the generation; the rest count meals, and "fed"
## is the Fed ratio.
const KINDS := {
	"sprint": ["sprinting", 0.35],
	"turn": ["sharp turns", 0.12],
	"danger": ["dodging hunters", 0.08],
	"sun": ["basking in sunlit meadows", 0.4],
	"vent": ["lingering by vents", 0.25],
	"tough": ["chewing tough food", 8.0],
	"faint": ["finding faint food", 6.0],
	"darting": ["catching darting food", 6.0],
	"fed": ["eating well", 3.0],
}
const TIMED := ["sprint", "turn", "danger", "sun", "vent"]
## Which habits point toward each trait and organelle.
const TRAIT_HABITS := {
	"size": ["fed"], "speed": ["sprint"], "agility": ["turn", "darting"],
	"sense": ["faint"], "armor": ["danger"], "toxin": ["danger"], "jaw": ["tough"],
}
const FEATURE_HABITS := {
	"chloroplasts": "sun", "vent_symbionts": "vent", "jet": "danger",
	"sticky_coat": "darting", "grabbing_cilia": "darting", "tail_bud": "sprint",
	"eye_cluster": "faint", "food_scent": "faint", "fat_store": "fed", "gut_lining": "fed",
}
## Energy eaten before the diet hint counts.
const DIET_MIN_ENERGY := 3.0

## Seconds in the generation, for the timed habits.
var length := 90.0
var amounts := {}
var plant_energy := 0.0
var prey_energy := 0.0


func add(habit: String, amount: float) -> void:
	amounts[habit] = float(amounts.get(habit, 0.0)) + amount


## Records one meal by a body with this genome: tough, faint or darting
## food, and whether its energy came from plant food or prey.
func note_meal(g: Genome, item: FoodItem, energy: float) -> void:
	if item.hardness > g.value_of("jaw"):
		add("tough", 1.0)
	if item.visibility < 0.5:
		add("faint", 1.0)
	if item.flee_speed > 0.0:
		add("darting", 1.0)
	if item.kind.is_plant:
		plant_energy += energy
	else:
		prey_energy += energy


## 0..1: how strongly the player showed this habit.
func strength(habit: String) -> float:
	if not KINDS.has(habit):
		return 0.0
	var row: Array = KINDS[habit]
	var full: float = row[1]
	var amount: float = amounts.get(habit, 0.0)
	if habit in TIMED:
		amount /= maxf(length, 0.01)
	return clampf(amount / full, 0.0, 1.0)


## -1 = ate only plant food, +1 = only prey, 0 = mixed or barely ate.
func diet_lean() -> float:
	var total := plant_energy + prey_energy
	if total < DIET_MIN_ENERGY:
		return 0.0
	return (prey_energy - plant_energy) / total


func trait_hint(trait_name: String) -> float:
	if trait_name == "diet":
		return absf(diet_lean())
	return strength(_strongest(TRAIT_HABITS.get(trait_name, [])))


func feature_hint(id: String) -> float:
	return strength(_feature_habit(id))


## Plain words for the habit behind a trait's hint, such as "sprinting".
func trait_reason(trait_name: String) -> String:
	if trait_name == "diet":
		return "eating prey" if diet_lean() > 0.0 else "eating plant food"
	return _words(_strongest(TRAIT_HABITS.get(trait_name, [])))


func feature_reason(id: String) -> String:
	return _words(_feature_habit(id))


## The habit behind an organelle or a body form (see BodyForm).
func _feature_habit(id: String) -> String:
	if BodyForm.ALL.has(id):
		var row: Array = BodyForm.ALL[id]
		return row[2]
	return FEATURE_HABITS.get(id, "")


## Trait averages plus the "sun" and "vent" habits, which unlock the
## energy-making organelles (see Feature).
func with_habits(averages: Dictionary) -> Dictionary:
	var out := averages.duplicate()
	out["sun"] = strength("sun")
	out["vent"] = strength("vent")
	return out


## Names of the habits shown at least this strongly, strongest first.
func shown(threshold: float) -> PackedStringArray:
	var ids: Array = KINDS.keys().filter(func(h: String) -> bool:
		return strength(h) >= threshold)
	ids.sort_custom(func(a: String, b: String) -> bool: return strength(a) > strength(b))
	var out := PackedStringArray()
	for h in ids:
		out.append(_words(h))
	return out


func _strongest(habits: Array) -> String:
	var best := ""
	for h in habits:
		if best == "" or strength(h) > strength(best):
			best = h
	return best


func _words(habit: String) -> String:
	if not KINDS.has(habit):
		return ""
	var row: Array = KINDS[habit]
	return row[0]
