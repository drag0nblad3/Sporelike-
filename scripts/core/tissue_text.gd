class_name TissueText
extends RefCounted
## Writes the card for a TissueTrait upgrade: its name and next level, what
## it is, and every number it changes on this body (speed, energy use,
## energy held and its own effect), worked out from the real rules by
## comparing the body now with the body after the pick.

const NUMERALS := ["", "I", "II", "III", "IV"]


## [id, name, text, colour] for ChoiceScreen.
static func card(id: String, plan: BodyPlan) -> Array:
	var after := plan.copy()
	TissueTrait.take(after, id)
	var next := TissueTrait.level(after, id)
	var lines: Array[String] = [TissueTrait.about(id)]
	var effect := _effect(id, plan, after)
	if effect != "":
		lines.append(effect)
	var speed := _speed(after) / maxf(_speed(plan), 0.001) - 1.0
	if absf(speed) >= 0.005:
		var way := "faster" if speed > 0.0 else "slower"
		lines.append("Swims %d%% %s" % [roundi(absf(speed) * 100.0), way])
	var store_now := CellEffects.max_energy(plan)
	var store_after := CellEffects.max_energy(after)
	if absf(store_after - store_now) >= 0.5:
		lines.append("Holds %d energy (now %d)" % [roundi(store_after), roundi(store_now)])
	var use := CellEffects.upkeep(after) - CellEffects.upkeep(plan)
	if absf(use) >= 0.005:
		lines.append("Energy use %+.2f/s (now %.2f/s)" % [use, CellEffects.upkeep(plan)])
	var heading := "%s %s" % [TissueTrait.title(id), NUMERALS[next]]
	return [id, heading, "\n".join(PackedStringArray(lines)), color(id)]


static func color(id: String) -> Color:
	var need := TissueTrait.role(id)
	return UiTheme.GOLD if need == "" else BodyPart.color(need)


static func _speed(plan: BodyPlan) -> float:
	return ColonySwim.cell_average(plan) * TissueTrait.swim_factor(plan)


static func _effect(id: String, now: BodyPlan, after: BodyPlan) -> String:
	var um := StatSheet.MICRONS
	match id:
		"lens":
			return "Feel food and hunters %d µm past the screen edge (now %d µm)" % [
				CellEffects.sense_reach(after) * um, CellEffects.sense_reach(now) * um]
		"plates":
			return "Plates block %d%% of bites, %d%% beside them (now %d%%, %d%%). Curl lasts %.1f s" % [
				CellEffects.plate_block(after, false) * 100.0, CellEffects.plate_block(after, true) * 100.0,
				CellEffects.plate_block(now, false) * 100.0, CellEffects.plate_block(now, true) * 100.0,
				ColonyAbility.curl_time(after)]
		"venom":
			return "Stings stun for %.1f s (now %.1f s). Sting costs %.1f energy" % [
				CellEffects.sting_stun(after), CellEffects.sting_stun(now),
				ColonyAbility.cost(after, "sting")]
		"folds":
			return "Keeps %d%% of every meal (now %d%%)" % [
				CellEffects.digest_share(after) * 100.0, CellEffects.digest_share(now) * 100.0]
		"lips":
			return "Mouths pull food in from %d µm (now %d µm)" % [
				CellEffects.mouth_reach(after) * um, CellEffects.mouth_reach(now) * um]
		"healing":
			return "Regrows a bitten-off cell in %.1f s (now %.1f s)" % [
				ColonyWounds.regrow_time(after), ColonyWounds.regrow_time(now)]
	return ""


## "Stronger whips II, Folded gut I", or "" with no upgrades yet.
static func summary(plan: BodyPlan) -> String:
	var names: Array[String] = []
	for id in TissueTrait.INFO:
		var lv := TissueTrait.level(plan, id)
		if lv > 0:
			names.append("%s %s" % [TissueTrait.title(id), NUMERALS[lv]])
	return ", ".join(PackedStringArray(names))
