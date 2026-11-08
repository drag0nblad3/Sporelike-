class_name ScreenshotTour
extends Node
## CI only ("-- --shot", run with a real renderer): saves screenshots of
## gameplay and the pause menu to build/shots/ so layout bugs that headless
## runs cannot see show up as images, then quits.

const OUT_DIR := "res://build/shots"

var game: Game
var title: TitleScreen
var creator: SubspeciesCreator


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
		"chloroplasts": 2, "vent_symbionts": 1, "trichocysts": 1, "toxicysts": 1, "flash": 1}
	g.values["toxin"] = 0.5
	g.values["jaw"] = 0.6
	g.efficiency = 0.5
	game.director.retire()
	game.director.spawn(g, Vector2.ZERO)
	game.director.player.energy = 17.0
	await get_tree().create_timer(0.5).timeout
	await _shoot("play")
	await _shoot_forms(g)
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
	await _visit("giant_colony", _find(_teaser.bind(TeaserColony)))
	game.camera.zoom = 1.0
	await get_tree().create_timer(1.0).timeout
	game.hud.pause_menu.open()
	await _shoot("pause")
	game.hud.pause_menu.close()
	game.round_end.forms_early = true
	game.cycle.finish("time")
	await _shoot("generation")
	game.screen.open_others()
	await _shoot("other_species")
	game.screen.close_others()
	await _shoot_stage_two()
	game.queue_free()
	await get_tree().process_frame
	await _shoot_colony_lab()
	await _shoot_animal_lab()
	title.open(true)
	await _shoot("title")
	await _shoot_genes()
	await _shoot_seas()
	print("shot: done")
	get_tree().quit()


## One still cell of each body form, at its top level, beside the player.
func _shoot_forms(base: Genome) -> void:
	var shown: Array[Organism] = []
	var i := 0
	for id in BodyForm.ALL:
		var g := base.copy()
		g.features = {id: BodyForm.MAX_LEVEL}
		var cell := Organism.new()
		cell.setup(g, 10.0)
		cell.upkeep_scale = 0.0
		var p := game.director.player.position
		cell.position = p + Vector3(-6.0 + 3.0 * i, 0.0, -3.5)
		game.add_child(cell)
		shown.append(cell)
		i += 1
	await get_tree().create_timer(0.5).timeout
	await _shoot("forms")
	for cell in shown:
		cell.queue_free()


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


## The multicellular stage in the real game: the switch, a colony swimming
## among single cells and seaweed, then the cell picks between generations.
func _shoot_stage_two() -> void:
	game.screen.visible = false
	game.stage_two.offer_switch(game.ecosystem.focus)
	await _shoot("switch")
	game.stage_two.switch_to(Symmetry.BILATERAL, game.ecosystem.focus)
	game.stage_two.pilot.autopilot = Vector2(0.6, -1.0)
	await get_tree().create_timer(3.0).timeout
	await _shoot("stage2")
	# Up to the surface, among algae rafts and comb jellies.
	game.stage_two.pilot.colony.layer = Depth.SURFACE
	await get_tree().create_timer(2.5).timeout
	await _shoot("stage2_surface")
	await _shoot_shallows()
	game.cycle.finish("time")
	await _shoot("cell_picks")


## Late in stage 2: the shallows to the north with their beach and tide
## pools, then the colony hauling itself out at the end of the stage.
func _shoot_shallows() -> void:
	var pilot := game.stage_two.pilot
	pilot.colony.layer = Depth.FLOOR
	pilot.shallows.place(game.stage_two.center() + Vector2(0.0, 26.0))
	pilot.autopilot = Vector2(0.0, -1.0)
	game.camera.zoom = 2.0
	await get_tree().create_timer(4.0).timeout
	await _shoot("shallows")
	pilot.haul_out()
	await get_tree().create_timer(StageTwo.HAUL_TIME).timeout
	await _shoot("haul_out")
	pilot.hauling = false
	pilot.autopilot = Vector2.ZERO
	game.camera.zoom = 1.0


## The stage 3 feel test: a random land animal walking over the hills,
## then a second, different body.
func _shoot_animal_lab() -> void:
	var lab := AnimalLab.new()
	lab.process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().add_child(lab)
	lab.rng.seed = 3
	lab.new_body()
	lab.autopilot = Vector2(0.35, -1.0)
	await get_tree().create_timer(3.0).timeout
	await _shoot("stage3")
	lab.new_body()
	lab.autopilot = Vector2(-0.4, -1.0)
	await get_tree().create_timer(2.5).timeout
	await _shoot("stage3_body2")
	lab.queue_free()
	await get_tree().process_frame


## The colony lab: the symmetry choice, then two kinds of colony
## swimming among seaweed.
func _shoot_colony_lab() -> void:
	var lab := ColonyLab.new()
	lab.process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().add_child(lab)
	await _shoot("symmetry")
	lab.start(Symmetry.BILATERAL)
	for role in ["flagellum", "flagellum", "eye", "plate", "gut"]:
		lab.colony.grow(role)
	lab.autopilot = Vector2(0.5, -1.0)
	await get_tree().create_timer(2.5).timeout
	await _shoot("colony")
	lab.start(Symmetry.RADIAL)
	lab.colony.grow("flagellum")
	lab.autopilot = Vector2(1.0, 0.2)
	await get_tree().create_timer(2.5).timeout
	await _shoot("colony_radial")
	lab.queue_free()


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


## A fresh run in every other kind of sea, zoomed out to show its food mix,
## water colour and light.
func _shoot_seas() -> void:
	title.visible = false
	for id in Sea.ids():
		if id == Sea.DEFAULT:
			continue
		var run := Game.new()
		run.setup({}, false, "Tour", [], id)
		get_parent().add_child(run)
		run.camera.zoom = 3.0
		await get_tree().create_timer(2.0).timeout
		await _shoot("sea_" + id)
		if id == "lagoon":
			await _shoot_border(run)
		run.queue_free()
		await get_tree().process_frame
	Sea.use(Sea.DEFAULT)


## The edge of the starting sea region, east of the start.
func _shoot_border(run: Game) -> void:
	var start := SeaMap.at(Vector2.ZERO).id
	for d in range(0, 600, 4):
		var p := Vector2(d, 0.0)
		if SeaMap.at(p).id != start:
			run.director.player.position = Vector3(p.x, 0.0, p.y)
			run.camera.zoom = 5.0
			await get_tree().create_timer(3.0).timeout
			await _shoot("sea_border")
			return


## The subspecies creator and the gene trees, with a made-up gene bank.
func _shoot_genes() -> void:
	var bank := GeneBank.new()
	bank.points = 12
	bank.lifetime = 24
	for id in ["big_1", "spines_1", "spines_2", "trichocysts", "nimble_1", "nimble_2", "jet"]:
		bank.unlocked.append(id)
	creator.open(bank)
	creator.call("_toggle", "trichocysts")
	await _shoot("creator")
	creator.call("_open_trees")
	await _shoot("gene_trees")
	creator.visible = false
