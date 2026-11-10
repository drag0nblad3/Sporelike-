class_name VillageEvents
extends Node
## What happens between the parts of a VillageLab: the HUD's orders reach
## the village, the elder's Rally and succession, a generation ending
## (births, then the newborns' body in the customizer), a job's learning
## bar filling (the discovery pick), raids counting
## their losses, and the run ending with its VillageSummary.

const RALLY_REACH := 16.0
const RALLY_TIME := 20.0
const RALLY_WAIT := 45.0

var lab: VillageLab
var rally_wait := 0.0


func wire(owner_lab: VillageLab) -> void:
	lab = owner_lab
	var hud := lab.hud
	var village := lab.village
	hud.look.dragged.connect(lab.camera.drag)
	# Deferred, so the tap that switched views cannot also press what appears.
	hud.view_pressed.connect(func() -> void: lab.set_overhead.call_deferred(not hud.overhead))
	hud.rally_pressed.connect(rally)
	hud.back_pressed.connect(func() -> void: lab.back_requested.emit())
	hud.map_tapped.connect(func(share: Vector2, aspect: float) -> void:
		village.flag = lab.overhead.ground_at(share, aspect))
	hud.panel.job_changed.connect(village.set_job)
	hud.panel.build_pressed.connect(func(id: String) -> void: village.buildings.queue(id))
	hud.panel.alarm_pressed.connect(func() -> void: village.alarm = not village.alarm)
	hud.panel.flag_cleared.connect(func() -> void: village.flag = Vector3.INF)
	hud.recipe_changed.connect(func(recipe: AnimalRecipe) -> void:
		if lab.paused:
			lab.set_body(AnimalBuilder.build(recipe), village.elder.pos))
	hud.evolve_finished.connect(evolved)
	hud.discovery.picked.connect(learn)
	hud.basket_tapped.connect(func(share: Vector2, aspect: float) -> void:
		village.camp.set_basket(lab.overhead.ground_at(share, aspect)))
	hud.summary.new_valley.connect(func() -> void: lab.new_valley_requested.emit())
	hud.summary.back_pressed.connect(func() -> void: lab.back_requested.emit())
	for part: Node in [village, lab.raids, lab.rival]:
		part.connect("notice", hud.flash)
	village.died.connect(func(_who: CrowdActor) -> void:
		if lab.raids.active:
			lab.raids.losses += 1
		hud.flash("A villager was lost. %d left" % village.villagers.size()))
	lab.raids.ended.connect(func(clean: bool) -> void:
		lab.run.clean_raid = lab.run.clean_raid or clean)
	lab.generations.ended.connect(generation_ended)


func step(delta: float) -> void:
	rally_wait -= delta
	var village := lab.village
	if not village.elder.alive:
		var heir := VillageGrowth.next_elder(village)
		if heir != null:
			lab.crowd.avatars.drop(heir)
			lab.set_body(heir.body, heir.pos)
			lab.hud.flash("The elder has fallen. The eldest villager takes over")
	if lab.run.check(village, lab.rival, lab.generations.number) != "":
		end_run()
		return
	var job := village.learning.ready_job()
	if job == -1:
		return
	var offers := village.learning.offers(job)
	if offers.size() == 1:
		village.learn(offers[0])
		return
	lab.paused = true
	lab.crowd.avatars.halt()
	lab.animal.move_input = Vector2.ZERO
	lab.hud.open_discovery(job, offers, village.learning.known_text())


## The player picked a discovery (or a check teaches one outright).
func learn(id: String) -> void:
	lab.village.learn(id)
	if lab.hud.discovery.visible:
		lab.hud.close_discovery()
		lab.paused = false


func rally() -> void:
	if rally_wait > 0.0 or lab.paused:
		return
	rally_wait = RALLY_WAIT
	var called := ElderActions.rally(lab.village, RALLY_REACH, RALLY_TIME)
	lab.hud.flash("Rally! %d villagers follow you for %d s" % [called, roundi(RALLY_TIME)])


func generation_ended(number: int) -> void:
	lab.paused = true
	lab.crowd.avatars.halt()
	lab.animal.move_input = Vector2.ZERO
	lab.set_overhead(false)
	var due := VillageGrowth.births_due(lab.village)
	lab.hud.open_evolve(LandGenerations.picks_for(due))
	lab.hud.flash("Generation %d is over. %d will be born: shape the newborns, then Done" % [
		number, due])


## The customizer closed: the newborns arrive and the next generation starts.
func evolved() -> void:
	var village := lab.village
	var born := VillageGrowth.births(village, AnimalBuilder.build(lab.hud.editor.recipe))
	lab.set_body(village.elder.body, village.elder.pos)
	lab.generations.begin_next()
	lab.rival.new_generation(village.people())
	lab.raids.plan(lab.generations.number)
	lab.paused = false
	lab.hud.flash("%d newborns join the village" % born)
	if lab.run.check(village, lab.rival, lab.generations.number) != "":
		end_run()


func end_run() -> void:
	if lab.paused and lab.hud.summary.visible:
		return
	lab.paused = true
	lab.generations.running = false
	lab.crowd.avatars.halt()
	lab.animal.move_input = Vector2.ZERO
	lab.set_overhead(false)
	var text := lab.run.summary()
	if lab.throwaway:
		text += "\n(Test run: gene points are not banked yet)"
	else:
		var bank := GeneBank.load_bank()
		bank.points += lab.run.points()
		bank.lifetime += lab.run.points()
		bank.save()
	lab.hud.show_summary(text)
