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
