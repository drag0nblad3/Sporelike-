class_name ScreenshotTour
extends Node
## CI only ("-- --shot", run with a real renderer): saves screenshots of
## gameplay and the pause menu to build/shots/ so layout bugs that headless
## runs cannot see show up as images, then quits.

const OUT_DIR := "res://build/shots"

var game: Game
var title: TitleScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_run.call_deferred()


func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	# Show off the branching upgrades and the stored-food bar.
	var g := game.director.genome.copy()
	g.features = {"tail_bud": 1, "grabbing_cilia": 1, "fat_store": 2, "jet": 1,
		"food_scent": 1}
	game.director.retire()
	game.director.spawn(g, Vector2.ZERO)
	game.director.player.energy = 17.0
	await get_tree().create_timer(0.5).timeout
	await _shoot("play")
	game.camera.zoom = 6.0
	await get_tree().create_timer(1.5).timeout
	await _shoot("map")
	# Swim far away instantly to check that new chunks load there.
	game.director.player.position = Vector3(130.0, 0.0, -90.0)
	await get_tree().create_timer(1.5).timeout
	await _shoot("far")
	game.camera.zoom = 1.0
	await get_tree().create_timer(1.0).timeout
	game.hud.pause_menu.open()
	await _shoot("pause")
	game.hud.pause_menu.close()
	game.cycle.finish("time")
	await _shoot("generation")
	game.visible = false
	game.hud.visible = false
	title.open(true)
	await _shoot("title")
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
	# Also print a small JPEG into the log, for reviewers who cannot
	# download artifacts.
	image.resize(960, 540)
	var data := Marshalls.raw_to_base64(image.save_jpg_to_buffer(0.8))
	for i in range(0, data.length(), 4000):
		print("shotb64 %s %s" % [shot_name, data.substr(i, 4000)])
