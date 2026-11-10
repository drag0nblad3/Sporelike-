class_name LandLifeCheck
extends RefCounted
## CI only (part of "-- --smoke"): carries a finished stage 2 body onto
## the land (LandStart, LandRun read back from a save Dictionary), opens
## stage 3 as part of that run, and plays out an egg thief and a grazer
## kill, reporting an error if any of it misbehaves.


static func run(host: Node) -> void:
	var plan := BodyPlan.starter(Symmetry.RADIAL)
	plan.final_body = FinalBody.SWIMMER
	var first := LandStart.recipe_for(plan, Color(0.2, 0.6, 0.9))
	var back := LandRun.from_save({"stage": 3, "land": {"subspecies": "Checkus", "kin": 2,
		"generation": 2, "recipe": first.picks, "unlocked": ["ford"]}})
	back.throwaway = true
	print("smoke: land body from the sea: %s, %s, hue %s" % [back.recipe.value("shape"),
		back.recipe.value("symmetry"), back.recipe.value("hue")])
	if back.recipe.value("shape") != "keel" or back.recipe.value("symmetry") != "radial":
		push_error("The stage 2 body did not carry onto the land")
	var lab := AnimalLab.new()
	lab.run = back
	host.add_child(lab)
	lab.family.crowd.avatars.off = true
	if lab.family.kin.size() != 2 or lab.generations.number != 2 \
			or not "ford" in lab.goals.unlocks.reached:
		push_error("A saved land run did not come back whole")
	var events := lab.events
	lab.goals.nest.deliver(LandNest.FOOD_PER_EGG * 2)
	events.thief.comes_in = 0.0
	for i in 500:
		events.step(0.1)
		lab.family.step(lab.animal, 0.1)
	print("smoke: egg thief stole %d, driven off %d, eggs %d; %s" % [events.thief.stolen,
		events.thief.driven_off, lab.goals.nest.eggs, events.powers.text()])
	if events.thief.stolen + events.thief.driven_off == 0 and events.thief.actors.is_empty():
		push_error("The egg thief never came")
	lab.goals.food.carried = 0
	events.prey.actors[0].hurt(99.0)
	events.step(0.1)
	print("smoke: grazers %d, kills %d, carrying %d" % [events.prey.actors.size(),
		events.prey.kills, lab.goals.food.carried])
	if events.prey.kills != 1 or lab.goals.food.carried != lab.goals.food.capacity:
		push_error("A grazer kill did not fill the mouth")
	lab.queue_free()
