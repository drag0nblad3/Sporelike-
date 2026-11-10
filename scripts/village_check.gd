class_name VillageCheck
extends RefCounted
## CI only (part of "-- --smoke"): runs a stage 4 village for a few game
## minutes without drawing (orders, a building, a raid, the overhead view,
## Rally, a generation's births, the elder dying, the run ending) and the
## stage 3 family (kin, a prowler, founding), reporting an error if any of
## it misbehaves.


static func run(host: Node) -> void:
	_check_family(host)
	var lab := VillageLab.new()
	lab.seed_value = 7
	host.add_child(lab)
	var village := lab.village
	# Full bodies are moved by the engine, which is not running here.
	lab.crowd.avatars.off = true
	# Three gather, one guards, one is free to build.
	village.set_job(VillageJob.HUNT, -1)
	village.set_job(VillageJob.GATHER, 1)
	village.set_job(VillageJob.HUNT, -1)
	village.buildings.queue(VillageBuilding.STORE)
	var most_food := 0
	for i in 900:
		lab.tick(0.1)
		most_food = maxi(most_food, village.stock)
	print("smoke: village of %d stored up to %d food, store level %d, traits: %s" % [
		village.people(), most_food, village.buildings.level(VillageBuilding.STORE),
		village.traits.text().replace("\n", "; ")])
	if most_food == 0 or village.buildings.level(VillageBuilding.STORE) != 1:
		push_error("Villagers did not gather food or raise the store")
	lab.generations.time_left = lab.generations.length * 0.3
	for i in 1200:
		lab.tick(0.1)
	print("smoke: raid done %s, %d lost, %d people, rival %d %s" % [lab.raids.done,
		lab.raids.losses, village.people(), lab.rival.size(), lab.rival.mood()])
	if not lab.raids.done:
		push_error("The raid never finished")
	lab.set_overhead(true)
	lab.hud.panel.refresh(village)
	var spot := lab.overhead.ground_at(Vector2(0.3, 0.5), 16.0 / 9.0)
	lab.set_overhead(false)
	lab.events.rally()
	print("smoke: overhead tap lands %d m from the village; %s" % [
		roundi(village.center.distance_to(spot)), VillageStatus.text(lab).replace("\n", " | ")])
	if village.center.distance_to(spot) > 80.0:
		push_error("The overhead view's map tap is far off the village")
	var before := village.villagers.size()
	village.stock = village.stock_cap()
	lab.generations.end_now()
	lab.hud.editor.closed.emit()
	village.elder.hurt(999.0)
	lab.tick(0.1)
	print("smoke: births %d, new elder alive %s, generation %d" % [
		village.villagers.size() + 1 - before, village.elder.alive, lab.generations.number])
	if village.villagers.size() < before or not village.elder.alive or lab.paused:
		push_error("Births or the elder's succession misbehaved")
	lab.generations.number = VillageRun.GENERATIONS + 1
	lab.tick(0.1)
	print("smoke: village run %s, +%d gene points" % [lab.run.outcome, lab.run.points()])
	if lab.run.outcome == "" or not lab.hud.summary.visible:
		push_error("The village run did not end")
	lab.queue_free()


static func _check_family(host: Node) -> void:
	var family := LandFamily.new()
	host.add_child(family)
	family.crowd.avatars.off = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var animal := Animal.new()
	animal.build(AnimalRandom.make(rng), Vector3(5.0, 0.0, 4.0))
	host.add_child(animal)
	var nest := LandNest.new()
	nest.position = animal.head()
	host.add_child(nest)
	var born := family.hatch(8, animal.body, nest.position)
	family.prowl_in = 0.0
	family.call_kin()
	for i in 600:
		family.step(animal, 0.1)
	print("smoke: %d kin hatched, %d alive, %d prowlers left, can found %s" % [born,
		family.kin.size(), family.prowlers.size(), family.ready_to_found(animal.head(), nest)])
	if born != 4 or family.kin.is_empty():
		push_error("The stage 3 family did not hatch or was wiped out")
	for node: Node in [family, animal, nest]:
		node.queue_free()
