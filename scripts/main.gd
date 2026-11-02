extends Node
## Entry point: shows the title screen and starts or continues a Game.
## Keep this thin; the session itself lives in Game.

## Set by CI ("-- --smoke"): skip the title, then reload the save once.
var smoke_test := "--smoke" in OS.get_cmdline_user_args()

var _title: TitleScreen
var _game: Game
var _smoke_reloaded := false


func _ready() -> void:
	_title = TitleScreen.new()
	_title.new_game.connect(_on_new_game)
	_title.continue_game.connect(_on_continue)
	_title.test_stage_two.connect(func() -> void: _start({}, true))
	add_child(_title)
	if smoke_test:
		SaveGame.delete()
		_on_new_game.call_deferred()
	elif "--shot" in OS.get_cmdline_user_args():
		_start_screenshot_tour.call_deferred()
	else:
		_title.open(SaveGame.exists())


func _start_screenshot_tour() -> void:
	_start({})
	var tour := ScreenshotTour.new()
	tour.game = _game
	tour.title = _title
	add_child(tour)


func _on_new_game() -> void:
	SaveGame.delete()
	_start({})


func _on_continue() -> void:
	_start(SaveGame.load_data())


## jump: a throwaway game that goes straight to the stage 2 switch.
func _start(save: Dictionary, jump: bool = false) -> void:
	_close_game()
	_title.visible = false
	_game = Game.new()
	_game.setup(save, smoke_test)
	_game.jump_to_stage_two = jump
	_game.quit_to_title.connect(_on_quit_to_title)
	_game.generation_started.connect(_on_generation_started)
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
