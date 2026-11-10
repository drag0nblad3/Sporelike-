class_name ColonyAbility
extends RefCounted
## The multicellular body's active abilities, one HUD button each: Surge
## (every flagellated cell beats at once), Sting (every stinging cell fires
## its thread outward) and Curl (the body pulls in behind its plates). Holds
## each one's numbers for ColonyCaster and the help text. Distances are
## world units (10 µm).

const ALL := ["surge", "sting", "curl"]
const BUTTON := {"surge": "Surge", "sting": "Sting", "curl": "Curl"}
## The cell kind each needs, and how many of them.
const NEEDS := {"surge": ["flagellum", 0], "sting": ["gland", 1], "curl": ["plate", 2]}
const COST := {"surge": 0.0, "sting": 1.0, "curl": 0.5}
const COOLDOWN := {"surge": 5.0, "sting": 10.0, "curl": 12.0}
const COLORS := {"surge": Color(0.5, 0.62, 1.0), "sting": Color(0.78, 0.45, 0.95),
	"curl": Color(0.72, 0.7, 0.6)}
## Seconds a surge lasts; push multiplier for the body and per whip.
const SURGE_TIME := 0.6
const SURGE_PUSH := 2.0
const SURGE_PER_WHIP := 0.25
## Sting reach from the body's edge, plus more per stinging cell.
const STING_REACH := 3.0
const STING_PER_GLAND := 0.5
const STING_STUN := 3.0
const CURL_TIME := 3.0


static func has(plan: BodyPlan, id: String) -> bool:
	var need: Array = NEEDS[id]
	return plan.count(str(need[0])) >= int(need[1])


static func owned(plan: BodyPlan) -> Array[String]:
	var list: Array[String] = []
	for id in ALL:
		if has(plan, id):
			list.append(id)
	return list


static func surge_push(plan: BodyPlan) -> float:
	return SURGE_PUSH + SURGE_PER_WHIP * plan.count("flagellum")


static func sting_reach(plan: BodyPlan) -> float:
	return STING_REACH + STING_PER_GLAND * plan.count("gland")


## Energy an ability costs; Potent venom makes Sting dearer.
static func cost(plan: BodyPlan, id: String) -> float:
	var extra := TissueTrait.VENOM_COST * TissueTrait.level(plan, "venom") if id == "sting" else 0.0
	return float(COST[id]) + extra


static func sting_stun(plan: BodyPlan) -> float:
	return STING_STUN + TissueTrait.VENOM_STUN * TissueTrait.level(plan, "venom")


static func curl_time(plan: BodyPlan) -> float:
	return CURL_TIME + TissueTrait.CURL_TIME * TissueTrait.level(plan, "plates")


## A line for the cell pick card when this pick unlocks or improves an ability.
static func card_line(role: String, after: BodyPlan) -> String:
	var um := StatSheet.MICRONS
	match role:
		"flagellum":
			return "Surge: %.1fx push for %.1f s" % [surge_push(after), SURGE_TIME]
		"gland":
			return "Sting: stuns everything within %d µm for %.1f s" % [
				sting_reach(after) * um, sting_stun(after)]
		"plate":
			if has(after, "curl"):
				return "Curl: blocks every bite for %.1f s, but you stop swimming" % curl_time(after)
			return "2 plates unlock Curl"
	return ""
