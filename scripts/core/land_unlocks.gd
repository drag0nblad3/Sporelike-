class_name LandUnlocks
extends RefCounted
## Which body parts stage 3 still holds back. Each LandLandmark unlocks a
## family of customizer options (AnimalRecipe rows) when the animal
## reaches it; until then the AnimalEditor skips those options.

const FORD := "ford"
const SUMMIT := "summit"
const FOREST := "forest"
const ALL := [FORD, SUMMIT, FOREST]
## Landmark -> [family name, {row key: locked option texts}].
const FAMILIES := {
	FORD: ["Wader parts", {"limb": ["tentacles"], "foot": ["sucker"], "tail": ["fork"]}],
	SUMMIT: ["Climber parts", {"foot": ["claw", "spike"], "horns": ["one", "two"],
		"back": ["spikes"]}],
	FOREST: ["Forest parts", {"arms": ["1 pair", "2 pairs"], "stalks": ["yes"],
		"feelers": ["yes"], "covering": ["a few feathers", "full feathers"]}],
}

var reached: Array[String] = []


static func family(id: String) -> String:
	var entry: Array = FAMILIES[id]
	return str(entry[0])


func unlock(id: String) -> void:
	if not id in reached:
		reached.append(id)


func unlock_all() -> void:
	for id: String in ALL:
		unlock(id)


func is_locked(key: String, text: String) -> bool:
	for id: String in ALL:
		if id in reached:
			continue
		var entry: Array = FAMILIES[id]
		var rows: Dictionary = entry[1]
		var options: Array = rows.get(key, [])
		if text in options:
			return true
	return false


## Keeps every row of `recipe` off locked options, moving forward to the
## next free one (each row's first option is never locked).
func fix(recipe: AnimalRecipe) -> void:
	for row: Array in AnimalRecipe.ROWS:
		var key: String = row[0]
		var tries := 0
		while is_locked(key, recipe.value(key)) and tries < 12:
			recipe.shift(key, 1)
			tries += 1


## One line for the customizer: which families are still locked, and where.
func locked_text() -> String:
	var parts: Array[String] = []
	for id: String in ALL:
		if not id in reached:
			parts.append("%s (%s)" % [family(id), LandLandmarks.title(id)])
	if parts.is_empty():
		return "Every part family is unlocked"
	return "Locked: " + ", ".join(parts)
