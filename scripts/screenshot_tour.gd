class_name ScreenshotTour
extends Node
## CI only ("-- --shot", run with a real renderer): saves screenshots of
## gameplay and the pause menu to build/shots/ so layout bugs that headless
## runs cannot see show up as images, then quits.

const OUT_DIR := "res://build/shots"

var game: Game


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_run.call_deferred()


func _run() -> void:
	await get_tree().create_timer(1.5).timeout
	await _shoot("play")
	game.hud.pause_menu.open()
	await _shoot("pause")
	game.hud.pause_menu.close()
	print("shot: done")
	get_tree().quit()


func _shoot(shot_name: String) -> void:
	for _i in 3:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, shot_name])
	var err := image.save_png(path)
	print("shot: %s %dx%d -> %s (%s)" % [shot_name, image.get_width(), image.get_height(),
		path, error_string(err)])
