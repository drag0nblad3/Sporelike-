class_name ColonyFightCheck
extends RefCounted
## CI only (part of "-- --smoke", after ColonyCheck): bites a colony until
## a cell comes off and grows back, fires every colony ability, and builds
## a rival colony of each feeding style and final body, reporting an error
## if any of it misbehaves.


static func run(colony: Colony) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var before := colony.plan.parts.size()
	var outcome := ""
	for _i in 40:
		outcome = colony.wounds.bite(colony, colony.plan.parts.size() - 1, rng)
		if outcome == ColonyWounds.BITTEN:
			break
	if outcome != ColonyWounds.BITTEN or colony.plan.parts.size() != before - 1:
		push_error("Colony bite did not take a cell off (%s)" % outcome)
	colony.energy = colony.max_energy()
	colony.wounds.tick(colony, ColonyWounds.REGROW_TIME + 0.1)
	print("smoke: colony bitten %d -> %d cells, regrew to %d" % [
		before, before - 1, colony.plan.parts.size()])
	if colony.plan.parts.size() != before:
		push_error("Colony did not regrow its bitten cell")
	colony.grow("gland")
	colony.grow("plate")
	colony.grow("plate")
	for id in ColonyAbility.ALL:
		colony.energy = colony.max_energy()
		if not ColonyCaster.fire(colony, id, null, []):
			push_error("Colony ability %s did not fire" % id)
	for style in FeedingStyle.ALL:
		for final in FinalBody.ALL:
			var plan := RivalColonies.make_plan(20, rng)
			plan.style = style
			plan.final_body = final
			var again := BodyPlan.from_dict(plan.to_dict())
			if again.style != style or again.final_body != final:
				push_error("Feeding style or final body was lost on saving")
	print("smoke: colony abilities fired, styles and final bodies saved")
	_check_world(rng)
	_check_depth(colony, rng)


## A comb jelly reaches a colony in open water but not one on the floor.
static func _check_depth(colony: Colony, rng: RandomNumberGenerator) -> void:
	var jelly := CombJelly.new()
	var c := colony.center()
	jelly.position = Vector3(c.x + 4.0, Depth.height(Depth.SURFACE), c.z)
	colony.height = 0.0
	colony.body.height = 0.0
	var floor_hit := ""
	for _i in 30:
		floor_hit += jelly.hunt(colony, rng, 0.1)
	colony.height = Depth.height(Depth.OPEN)
	colony.body.height = colony.height
	for i in colony.body.pos.size():
		colony.body.pos[i].y = colony.height
	var open_hit := ""
	for _i in 60:
		open_hit = jelly.hunt(colony, rng, 0.1)
		if open_hit != "":
			break
	print("smoke: comb jelly vs floor colony '%s', vs open-water colony '%s'" % [floor_hit, open_hit])
	if floor_hit != "" or open_hit == "":
		push_error("Comb jelly depth rules are wrong")
	jelly.free()
	colony.height = 0.0
	colony.body.height = 0.0


## Every sea's plant grows buds, and a heap of remains can be eaten.
static func _check_world(rng: RandomNumberGenerator) -> void:
	var kinds: Array[PlantKind] = [PlantKind.raft("lagoon")]
	for id in Sea.ids():
		kinds.append(PlantKind.for_sea(id))
	for kind in kinds:
		var weed := Seaweed.new()
		weed.kind = kind
		weed.grow_at(Vector3.ZERO, rng)
		if weed.buds.is_empty() or weed.take_bud(0) <= 0.0:
			push_error("%s grew no food" % weed.kind.title)
		weed.free()
	var heap := Carrion.new()
	heap.lay(Vector3.ZERO, 12, rng)
	var bite := heap.bite(PackedVector3Array([Vector3.ZERO]))
	print("smoke: plants in %d seas grew buds, remains gave %.1f per bite" % [Sea.ids().size(), bite])
	if bite <= 0.0:
		push_error("Remains could not be eaten")
	heap.free()
