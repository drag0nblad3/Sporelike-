class_name TissueCheck
extends RefCounted
## CI only (part of "-- --smoke"): takes every TissueTrait upgrade to its
## top level on a grown body, writes every card, and reports an error if an
## upgrade changed nothing it promised or did not survive saving.


static func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var plan := BodyPlan.starter(Symmetry.BILATERAL)
	for role in LabHud.GROWABLE:
		plan.grow(role)
	var base := plan.copy()
	for id in TissueTrait.INFO:
		for _i in TissueTrait.MAX_LEVEL:
			var card := TissueText.card(id, plan)
			if str(card[2]).count("\n") < 1:
				push_error("Tissue card %s shows no numbers" % id)
			TissueTrait.take(plan, id)
	var again := BodyPlan.from_dict(plan.to_dict())
	if TissueText.summary(again) != TissueText.summary(plan):
		push_error("Tissue upgrades did not survive saving and loading")
	if TissueTrait.offer(plan, rng, 3).size() != 0:
		push_error("Maxed tissue upgrades are still offered")
	_expect(CellEffects.sense_reach(plan) > CellEffects.sense_reach(base), "lens")
	_expect(CellEffects.digest_share(plan) > CellEffects.digest_share(base), "folds")
	_expect(CellEffects.sting_stun(plan) > CellEffects.sting_stun(base), "venom")
	_expect(ColonyWounds.regrow_time(plan) < ColonyWounds.regrow_time(base), "healing")
	_expect(ColonySwim.cell_push(plan, "flagellum") > ColonySwim.cell_push(base, "flagellum"), "whips")
	print("smoke: tissues %s; upkeep %.2f -> %.2f/s, store %d -> %d" % [
		TissueText.summary(plan), CellEffects.upkeep(base), CellEffects.upkeep(plan),
		CellEffects.max_energy(base), CellEffects.max_energy(plan)])


static func _expect(ok: bool, id: String) -> void:
	if not ok:
		push_error("Tissue upgrade %s had no effect" % id)
