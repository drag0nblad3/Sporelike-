class_name ColonyCheck
extends RefCounted
## CI only (part of "-- --smoke"): grows every kind of cell on every body
## plan, then swims a colony through the lab for a moment and reports an
## error if its soft body blew up or did not move.


static func run(host: Node) -> void:
	for kind in Symmetry.ALL:
		var plan := BodyPlan.starter(kind)
		var start := plan.parts.size()
		for role in LabHud.GROWABLE:
			plan.grow(role)
		var again := BodyPlan.from_dict(plan.to_dict())
		print("smoke: colony %s %d -> %d cells, reloads as %d" % [
			kind, start, plan.parts.size(), again.parts.size()])
		if again.parts.size() != plan.parts.size():
			push_error("Body plan did not survive saving and loading")
	var lab := ColonyLab.new()
	lab.process_mode = Node.PROCESS_MODE_ALWAYS
	lab.with_sea = false
	host.add_child(lab)
	lab.start(Symmetry.BILATERAL)
	lab.colony.grow("flagellum")
	lab.colony.grow("eye")
	var from := lab.colony.center()
	lab.autopilot = Vector2(0.4, -1.0)
	await host.get_tree().create_timer(1.0).timeout
	if not is_instance_valid(lab):
		return
	var moved := lab.colony.center().distance_to(from)
	print("smoke: colony swam %.2f units, energy %.1f" % [moved, lab.colony.energy])
	if is_nan(moved) or moved < 0.2 or moved > 50.0:
		push_error("Colony soft body did not swim properly (moved %.2f)" % moved)
	ColonyFightCheck.run(lab.colony)
	ApexCheck.run(lab)
	lab.queue_free()
