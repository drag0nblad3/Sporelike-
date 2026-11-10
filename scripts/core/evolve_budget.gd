class_name EvolveBudget
extends RefCounted
## How much a stage 3 body may change between generations: one row of
## the customizer (AnimalRecipe) per pick, where picks come from the eggs
## laid that generation (LandGenerations.picks_for). A row already changed
## can keep stepping; a new row needs a pick left. off: no limit (free
## editing in the lab).

var off := true
var picks := 0
var _start := {}


func begin(recipe: AnimalRecipe, count: int) -> void:
	off = false
	picks = count
	_start = recipe.picks.duplicate()


func end() -> void:
	off = true


func changed(recipe: AnimalRecipe) -> int:
	var count := 0
	for key: String in _start:
		if recipe.index(key) != int(_start[key]):
			count += 1
	return count


func allows(recipe: AnimalRecipe, key: String) -> bool:
	if off or recipe.index(key) != int(_start.get(key, 0)):
		return true
	return changed(recipe) < picks


func text(recipe: AnimalRecipe) -> String:
	if off:
		return ""
	return "Evolve: %d of %d changes left" % [maxi(picks - changed(recipe), 0), picks]
