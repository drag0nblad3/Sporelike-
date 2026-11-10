class_name LandStages
extends Node
## Opens the land stages for Main: stage 3 (AnimalLab) and stage 4
## (VillageLab), either as part of a run (a LandRun that came ashore from
## stage 2 or was loaded from the save) or as the title screen's tests
## (no run). Founding a village in stage 3 leads into stage 4; closed says
## the player is done and wants the title screen.

signal closed

var _lab: AnimalLab
var _village: VillageLab


## Stage 3. With a run, its body and progress are used and saved.
func open_lab(run: LandRun = null) -> void:
	close()
	_lab = AnimalLab.new()
	_lab.run = run
	_lab.back_requested.connect(_leave)
	_lab.village_founded.connect(func(body: AnimalBody, recipe: AnimalRecipe, at: Vector3,
			kin: int) -> void:
		if run != null:
			run.stage = 4
			run.recipe = recipe
			run.kin = kin
			run.home = at
			run.save()
		open_village.call_deferred(body, recipe, at, kin, run))
	add_child(_lab)


## Stage 4: a village of `body` at `at`, or a random animal in a new
## valley when body is null (the title's test button).
func open_village(body: AnimalBody, recipe: AnimalRecipe, at: Vector3, people: int,
		run: LandRun = null) -> void:
	close()
	_village = VillageLab.new()
	_village.run_info = run
	_village.throwaway = run == null or run.throwaway
	_village.start_body = body
	_village.start_recipe = recipe
	_village.start_at = at
	_village.start_people = people
	_village.valley_seed = 0 if body != null else randi_range(2, 99999)
	_village.back_requested.connect(_leave)
	_village.new_valley_requested.connect(func() -> void:
		open_village.call_deferred(null, null, Vector3.INF, 5))
	add_child(_village)


## Continue from a save made on land.
func resume(run: LandRun) -> void:
	if run.stage >= 4:
		open_village(AnimalBuilder.build(run.recipe), run.recipe, run.home, maxi(run.kin, 4), run)
	else:
		open_lab(run)


func close() -> void:
	if is_instance_valid(_lab):
		_lab.queue_free()
	if is_instance_valid(_village):
		_village.queue_free()
		LandHeight.use_seed(1)
	_lab = null
	_village = null


func _leave() -> void:
	close()
	closed.emit()
