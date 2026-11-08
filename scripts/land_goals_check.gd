class_name LandGoalsCheck
extends RefCounted
## CI only (part of "-- --smoke"): sets up the stage 3 goals with a random
## animal, delivers food to the nest, visits every landmark, checks a
## locked part is skipped, ends a generation and spends its evolve
## budget, reporting an error if any of it misbehaves.


static func run(host: Node) -> void:
	var goals := LandGoals.new()
	host.add_child(goals)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var animal := Animal.new()
	animal.build(AnimalRandom.make(rng), goals.nest.position)
	host.add_child(animal)
	goals.nest.move_to(animal.focus())
	goals.food.carried = LandFood.CARRY * 2
	goals.step(animal, 0.1)
	print("smoke: nest has %d eggs, landmarks %s" % [goals.nest.eggs, goals.landmarks.spots.keys()])
	if goals.nest.eggs != 2:
		push_error("Food carried to the nest did not lay eggs (%d)" % goals.nest.eggs)
	var recipe := AnimalRecipe.new()
	recipe.picks["limb"] = 1
	goals.unlocks.fix(recipe)
	if recipe.value("limb") != "legs":
		push_error("A locked part was not skipped (%s)" % recipe.value("limb"))
	for id: String in goals.landmarks.spots:
		var spot: Vector3 = goals.landmarks.spots[id]
		goals.landmarks.check(spot, goals.unlocks)
	print("smoke: landmarks reached %s; %s" % [goals.unlocks.reached, goals.unlocks.locked_text()])
	if goals.unlocks.reached.size() != goals.landmarks.spots.size():
		push_error("Not every landmark could be reached")
	_check_generation(host, goals)
	animal.queue_free()
	goals.queue_free()


static func _check_generation(host: Node, goals: LandGoals) -> void:
	var generations := LandGenerations.new()
	host.add_child(generations)
	var ends := [0]
	generations.ended.connect(func(_number: int) -> void: ends[0] += 1)
	generations.end_now()
	var picks := LandGenerations.picks_for(goals.nest.eggs)
	var recipe := AnimalRecipe.new()
	var budget := EvolveBudget.new()
	budget.begin(recipe, 1)
	for key: String in ["tail", "horns", "tail"]:
		if budget.allows(recipe, key):
			recipe.shift(key, 1)
	var changed := budget.changed(recipe)
	goals.new_generation()
	generations.begin_next()
	print("smoke: stage 3 generation ended %d time(s), %d picks; 1-pick evolve changed %d row(s)" % [
		ends[0], picks, changed])
	if ends[0] != 1 or picks != 3 or changed != 1 or goals.nest.eggs != 0 or generations.number != 2:
		push_error("Stage 3 generation or evolve budget misbehaved")
	generations.queue_free()
