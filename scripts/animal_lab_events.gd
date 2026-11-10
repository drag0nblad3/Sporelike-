class_name AnimalLabEvents
extends Node
## What happens between the parts of an AnimalLab (stage 3): generations
## ending and hatching, the grazers (LandPrey) and the egg thief
## (LandThief), what the body's parts are good for (LandBody), sounds and
## pop-ups (LandFeel), one-time tips, and saving the run as it goes.

var lab: AnimalLab
var feel := LandFeel.new()
var prey := LandPrey.new()
var thief := LandThief.new()
var powers := LandBody.new()
var _body: AnimalBody
var _carried := 0


func wire(owner_lab: AnimalLab) -> void:
	lab = owner_lab
	prey.rng.seed = lab.rng.randi()
	thief.rng.seed = lab.rng.randi()
	for part: Node in [feel, prey, thief]:
		lab.add_child(part)
	lab.family.crowd.add_group(prey.actors)
	lab.family.crowd.add_group(thief.actors)
	for part: Node in [prey, thief]:
		part.connect("notice", lab.hud.flash)
	for part: Node in [prey, thief, lab.family]:
		part.connect("cue", func(kind: String, at: Vector3) -> void: feel.cue(kind, at))
	lab.generations.ended.connect(_on_generation_ended)
	lab.hud.evolve_finished.connect(_hatch)
	lab.goals.nest.egg_laid.connect(func(total: int) -> void:
		feel.cue("egg", lab.goals.nest.position, "Egg %d" % total, LandFeel.GOLD)
		lab.hud.tips.offer("s3_eggs", "When the generation ends, each egg is one change to "
			+ "your body, and half the eggs hatch as kin who follow you."))
	lab.goals.landmarks.reached.connect(func(_id: String) -> void:
		feel.cue("landmark", lab.animal.focus(), "New parts unlocked", LandFeel.GOLD)
		_save())
	lab.hud.tips.offer("s3_food", "Walk over red berries to pick them up, then carry them "
		+ "home to the nest ring. Every %d pieces lays an egg." % LandNest.FOOD_PER_EGG)
	lab.hud.tips.offer("s3_marks", "Beams of light mark three landmarks. Reaching one "
		+ "unlocks a new family of body parts.")


func step(delta: float) -> void:
	var animal := lab.animal
	if animal.body != _body:
		_body = animal.body
		powers = LandBody.of(_body)
		lab.goals.food.capacity = powers.carry
		lab.family.bite = powers.bite
	var carried := lab.goals.food.carried
	if carried > _carried:
		feel.cue("pick")
	elif carried < _carried:
		feel.cue("deliver")
	_carried = carried
	prey.step(animal, lab.family.kin, powers, lab.goals, delta)
	thief.step(animal, lab.family.kin, powers, lab.goals.nest, delta)
	_tips(animal.head())


func _tips(at: Vector3) -> void:
	var tips := lab.hud.tips
	if prey.nearest_distance(at) < 22.0:
		tips.offer("s3_prey", "Grazers bolt when you come close, but they tire after a few "
			+ "seconds. Keep chasing to catch one for a mouth full of meat.")
	if not thief.actors.is_empty():
		tips.offer("s3_thief", "An egg thief is after your nest. Bite it, or evolve horns, "
			+ "spikes or a sail to frighten it off.")
	if not lab.family.prowlers.is_empty():
		tips.offer("s3_prowler", "A prowler hunts your kin. Press Call so they gather on "
			+ "you, then walk into it to bite.")
	if lab.family.kin.size() >= LandFamily.FOUND:
		tips.offer("s3_found", "With %d kin you can found a village: stand on the nest and "
			% LandFamily.FOUND + "press Found a village. That begins stage 4.")


func _on_generation_ended(number: int) -> void:
	var eggs := lab.goals.nest.eggs
	var picks := LandGenerations.picks_for(eggs)
	lab.hud.open_evolve(picks)
	lab.hud.flash("Generation %d is over. %d eggs: make up to %d changes, then Done" % [
		number, eggs, picks])


## The evolved body hatches at the nest and the next generation starts.
func _hatch() -> void:
	var nest := lab.goals.nest
	lab.set_body(AnimalBuilder.build(lab.hud.editor.recipe), nest.position)
	var kin := lab.family.hatch(nest.eggs, lab.animal.body, nest.position)
	lab.goals.new_generation()
	lab.generations.begin_next()
	feel.cue("hatch", nest.position, "+%d kin" % kin if kin > 0 else "")
	lab.hud.flash("Generation %d hatches from the nest, with %d new kin" % [
		lab.generations.number, kin])
	_save()


## Keeps the run's save up to date (nothing to do in the test lab).
func _save() -> void:
	var run := lab.run
	if run == null:
		return
	run.recipe = lab.hud.editor.recipe
	run.generation = lab.generations.number
	run.kin = lab.family.kin.size()
	run.unlocked = lab.goals.unlocks.reached.duplicate()
	run.save()
