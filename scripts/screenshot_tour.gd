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
		"food_scent": 1, "eye_cluster": 1, "sticky_coat": 1, "gut_lining": 1,
		"chloroplasts": 2, "vent_symbionts": 1}
	g.values["toxin"] = 0.5
	g.values["jaw"] = 0.6
	g.efficiency = 0.5
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
	# Visit the nearest strong current, then the nearest giant teaser.
	game.camera.zoom = 2.5
	await _visit("current", _find(func(c: Vector2i) -> Variant:
		for st in game.streamer.currents.streams_for(c):
			if st.speed >= CurrentStream.MEDIUM:
				return st.position_at(st.length() * 0.5)
		return null))
	game.camera.zoom = 4.0
	await _visit("teaser", _find(_teaser.bind(TeaserPlant)))
	await _visit("colony", _find(_teaser.bind(TeaserColony)))
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


## Where the teaser of this chunk is, if it has one of this class.
func _teaser(c: Vector2i, kind: Variant) -> Variant:
	var t := TeaserPlacer.build(game.streamer.generator.world_seed, c)
	if t == null:
		return null
	var at := Vector2(t.position.x, t.position.z)
	var same := is_instance_of(t, kind)
	t.free()
	return at if same else null


## The first spot `test` returns for chunks in growing rings around the
## start, or the start itself.
func _find(test: Callable) -> Vector2:
	for ring in range(1, 10):
		for x in range(-ring, ring + 1):
			for y in range(-ring, ring + 1):
				if maxi(absi(x), absi(y)) != ring:
					continue
				var found: Variant = test.call(Vector2i(x, y))
				if found != null:
					return found
	return Vector2.ZERO


func _visit(shot_name: String, at: Vector2) -> void:
	game.director.player.position = Vector3(at.x, 0.0, at.y)
	await get_tree().create_timer(1.5).timeout
	await _shoot(shot_name)


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
