extends Node
## Entry point: shows the title screen, the subspecies creator for a new
## run, and starts or continues a Game. Keep this thin; the session itself
## lives in Game.

## Set by CI ("-- --smoke"): skip the title, then reload the save once.
var smoke_test := "--smoke" in OS.get_cmdline_user_args()

var _title: TitleScreen
var _creator: SubspeciesCreator
var _game: Game
var _land := LandStages.new()
var _smoke_reloaded := false


func _ready() -> void:
	_title = TitleScreen.new()
	_title.new_game.connect(_on_new_game)
	_title.continue_game.connect(_on_continue)
	_title.test_stage_two.connect(func() -> void: _start({}, true))
	_title.test_stage_three.connect(func() -> void: _open_land(null, 3))
	_title.test_stage_four.connect(func() -> void: _open_land(null, 4))
	add_child(_title)
	_land.closed.connect(func() -> void: _title.open(SaveGame.exists()))
	add_child(_land)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_creator = SubspeciesCreator.new()
	_creator.visible = false
	_creator.begin.connect(_on_begin_run)
	_creator.back.connect(func() -> void: _title.open(SaveGame.exists()))
	layer.add_child(_creator)
	if smoke_test:
		SaveGame.delete()
		# The vent sea differs most from the default, so CI exercises it.
		_on_begin_run.call_deferred("Smokeus testii", [] as Array[String], "vents")
	elif "--shot" in OS.get_cmdline_user_args():
		_start_screenshot_tour.call_deferred()
	else:
		_title.open(SaveGame.exists())


func _start_screenshot_tour() -> void:
	# Show the one-time tips in the shots, whatever ran before.
	Tips.reset()
	_start({})
	var tour := ScreenshotTour.new()
	tour.game = _game
	tour.title = _title
	tour.creator = _creator
	add_child(tour)


## New run: found a subspecies first (the creator), then start.
func _on_new_game() -> void:
	_title.visible = false
	_creator.open(GeneBank.load_bank())


func _on_begin_run(subspecies_name: String, loadout: Array[String], sea_id: String) -> void:
	SaveGame.delete()
	_start({}, false, subspecies_name, loadout, sea_id)


func _on_continue() -> void:
	var data := SaveGame.load_data()
	if int(data.get("stage", 1)) >= 3:
		_open_land(LandRun.from_save(data), 0)
	else:
		_start(data)


## The land stages: a run that came ashore or was saved there, or (run
## null) the title's test of `stage`.
func _open_land(run: LandRun, stage: int) -> void:
	_close_game()
	_title.visible = false
	if run != null:
		_land.resume(run)
	elif stage == 4:
		_land.open_village(null, null, Vector3.INF, 5)
	else:
		_land.open_lab()


## jump: a throwaway game that goes straight to the stage 2 switch.
func _start(save: Dictionary, jump: bool = false, subspecies_name: String = "",
		loadout: Array[String] = [], sea_id: String = Sea.DEFAULT) -> void:
	_close_game()
	_land.close()
	_title.visible = false
	_game = Game.new()
	_game.setup(save, smoke_test, subspecies_name, loadout, sea_id)
	_game.jump_to_stage_two = jump
	_game.quit_to_title.connect(_on_quit_to_title)
	_game.generation_started.connect(_on_generation_started)
	_game.went_ashore.connect(func(run: LandRun) -> void: _open_land.call_deferred(run, 0))
	add_child(_game)


func _on_quit_to_title() -> void:
	_close_game()
	_title.open(SaveGame.exists())


func _close_game() -> void:
	if is_instance_valid(_game):
		_game.queue_free()
	_game = null


## In CI, exercise saving and loading once by reloading generation 2.
func _on_generation_started(number: int) -> void:
	if smoke_test and number == 2 and not _smoke_reloaded:
		_smoke_reloaded = true
		print("smoke: reloading save")
		_on_continue.call_deferred()
	elif smoke_test and number == 3:
		_check_glossary()
		_check_genes()


## In CI, open the pause menu and fail if the glossary text is blank.
func _check_glossary() -> void:
	var menu := _game.hud.pause_menu
	menu.open()
	await get_tree().process_frame
	await get_tree().process_frame
	var height := menu.text_height()
	print("smoke: glossary height %d" % height)
	if height < 200:
		push_error("Glossary text is blank in the pause menu")
	menu.save_cell_requested.emit()
	print("smoke: saved cells %d" % OrganismCollection.entries().size())
	menu.close()
	ColonyCheck.run(self)
	LandGoalsCheck.run(self)
	VillageCheck.run(self)
	LandLifeCheck.run(self)


## In CI, build the subspecies creator and gene trees with a made-up bank.
func _check_genes() -> void:
	var bank := GeneBank.new()
	bank.points = 40
	bank.unlocked.append("spines_1")
	bank.unlocked.append("jet")
	_creator.open(bank)
	_creator.call("_toggle", "jet")
	print("smoke: creator uses %d of %d slots" % [_creator.used_slots(), bank.slots()])
	var trees := GeneTreeScreen.new()
	add_child(trees)
	trees.open(bank)
	trees.call("_pick", "spines_2")
	print("smoke: gene trees open, %d genes, showing %s" % [GeneCatalog.count(), trees.detail.gene])
	trees.queue_free()
	_creator.visible = false
