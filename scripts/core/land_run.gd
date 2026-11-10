class_name LandRun
extends RefCounted
## A subspecies run once it has left the sea: what carries from stage 2
## through the land stage 3 into the village of stage 4, and its place in
## the save file (stage 3 or 4, the body recipe, unlocked part families,
## kin, where the village stands). A throwaway run (Test stage 2) is never
## saved and banks no gene points.

var subspecies := ""
var sea_title := ""
var throwaway := false
var stage := 3
var recipe := AnimalRecipe.new()
var unlocked: Array[String] = []
var generation := 1
var kin := 0
## Where the village was founded (stage 4).
var home := Vector3.ZERO


static func from_save(data: Dictionary) -> LandRun:
	var run := LandRun.new()
	var land: Dictionary = data.get("land", {})
	run.stage = int(data.get("stage", 3))
	run.subspecies = str(land.get("subspecies", ""))
	run.sea_title = str(land.get("sea", ""))
	run.generation = int(land.get("generation", 1))
	run.kin = int(land.get("kin", 0))
	run.home = Vector3(float(land.get("home_x", 0.0)), 0.0, float(land.get("home_z", 0.0)))
	var picks: Dictionary = land.get("recipe", {})
	for key: String in picks:
		if run.recipe.picks.has(key):
			run.recipe.picks[key] = int(picks[key])
	for id: Variant in land.get("unlocked", []):
		run.unlocked.append(str(id))
	return run


## Writes the run as the save file, so Continue comes back to this stage.
func save() -> void:
	if throwaway:
		return
	SaveGame.write({"stage": stage, "land": {"subspecies": subspecies, "sea": sea_title,
		"generation": generation, "kin": kin, "home_x": home.x, "home_z": home.z,
		"recipe": recipe.picks, "unlocked": unlocked}})


## The run is over: nothing left to continue.
func finish() -> void:
	if not throwaway:
		SaveGame.delete()
