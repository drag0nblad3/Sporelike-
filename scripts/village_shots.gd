class_name VillageShots
extends RefCounted
## CI only (part of "-- --shot"): screenshots of stage 4. The elder on
## foot among the villagers, the overhead view with its command panel and
## a raid closing in, and the end-of-run summary.


static func run(tour: ScreenshotTour) -> void:
	var lab := VillageLab.new()
	lab.process_mode = Node.PROCESS_MODE_ALWAYS
	lab.start_people = 9
	lab.seed_value = 11
	tour.get_parent().add_child(lab)
	var village := lab.village
	village.buildings.set_level(VillageBuilding.STORE, 1)
	village.buildings.set_level(VillageBuilding.WALL, 1)
	village.buildings.queue(VillageBuilding.LOOKOUT)
	village.stock = 6
	lab.autopilot = Vector2(0.2, -1.0)
	await tour.get_tree().create_timer(4.0).timeout
	lab.autopilot = Vector2.ZERO
	lab.events.rally()
	await tour.get_tree().create_timer(2.0).timeout
	await tour.shoot("stage4_elder")
	print("shot: stage 4 on foot at %d FPS" % roundi(Engine.get_frames_per_second()))
	lab.set_overhead(true)
	village.flag = village.center + Vector3(-22.0, 0.0, -14.0)
	lab.generations.time_left = lab.generations.length * (1.0 - VillageRaids.WHEN) + 12.0
	await tour.get_tree().create_timer(26.0).timeout
	await tour.shoot("stage4_overhead")
	print("shot: stage 4 overhead at %d FPS" % roundi(Engine.get_frames_per_second()))
	lab.set_overhead(false)
	lab.generations.number = VillageRun.GENERATIONS + 1
	await tour.get_tree().create_timer(1.0).timeout
	await tour.shoot("stage4_end")
	lab.queue_free()
	LandHeight.use_seed(1)
	await tour.get_tree().process_frame
