class_name VillageRun
extends RefCounted
## One stage 4 run: a tribe settling a valley over GENERATIONS
## generations. Tracks the three optional goals (a raid with no losses,
## bringing down the giant, all four buildings) and how the run ended:
## "won" (12 people and every building, or the rival driven out),
## "settled" (the generations ran out) or "lost" (nobody left). points()
## is the gene flow the run pays back to the species.

const GENERATIONS := 5
const WIN_PEOPLE := 12
const PER_GOAL := 3
const WIN_BONUS := 6
const SETTLED_BONUS := 2

var clean_raid := false
var giant := false
var all_built := false
var outcome := ""
var people := 0


## Looks at the village; returns the outcome once the run is decided.
func check(village: Village, rival: RivalTribe, generation: int) -> String:
	if outcome != "":
		return outcome
	people = village.people()
	giant = village.killed_giant
	all_built = village.buildings.built() == VillageBuilding.ALL.size()
	if people == 0:
		outcome = "lost"
	elif (people >= WIN_PEOPLE and all_built) or (rival != null and rival.gone):
		outcome = "won"
	elif generation > GENERATIONS:
		outcome = "settled"
	return outcome


func goals_met() -> int:
	return (1 if clean_raid else 0) + (1 if giant else 0) + (1 if all_built else 0)


func points() -> int:
	var bonus := WIN_BONUS if outcome == "won" else (SETTLED_BONUS if outcome == "settled" else 0)
	return people + goals_met() * PER_GOAL + bonus


func goals_text() -> String:
	return "Goals: %s raid with no losses  ·  %s giant hunted  ·  %s 4 buildings" % [
		_tick(clean_raid), _tick(giant), _tick(all_built)]


func summary() -> String:
	var head: String = {"won": "Your tribe rules the valley!",
		"settled": "Your tribe has settled the valley.",
		"lost": "Your tribe has died out."}.get(outcome, "")
	return "%s\n%d people at the end\n%s\nGene flow: +%d gene points" % [head, people,
		goals_text(), points()]


static func _tick(done: bool) -> String:
	return "[x]" if done else "[ ]"
