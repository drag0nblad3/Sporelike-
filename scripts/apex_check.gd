class_name ApexCheck
extends RefCounted
## CI only (part of "-- --smoke", after ColonyFightCheck): builds every
## sea's apex colony, bites one until ApexHunt says it is dead, and reports
## an error if a plan is too small or the apex never dies.


static func run(host: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for sea_id in Sea.ids():
		var kind := ApexKind.for_sea(sea_id)
		var plan := kind.make_plan(30, rng)
		print("smoke: apex %s has %d cells (%s)" % [kind.title, plan.parts.size(), plan.style])
		if plan.parts.size() < 20:
			push_error("Apex %s body plan is too small" % kind.title)
	var apex := Colony.new()
	apex.build(ApexKind.for_sea(Sea.DEFAULT).make_plan(30, rng), Vector3(40.0, 0.0, 0.0))
	host.add_child(apex)
	var bites := 0
	for _i in 400:
		if ApexHunt.fatal(apex):
			break
		var outcome := apex.wounds.bite(apex, rng.randi() % apex.plan.parts.size(), rng)
		if outcome == ColonyWounds.BITTEN:
			bites += 1
	print("smoke: apex died after %d bites, fatal %s" % [bites, ApexHunt.fatal(apex)])
	if not ApexHunt.fatal(apex):
		push_error("Apex colony never died from bites")
	apex.queue_free()
