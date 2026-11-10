class_name Discovery
extends RefCounted
## The things stage 4 villagers can figure out by doing their jobs. Each
## job has a line of discoveries; every one adds something new to do and
## takes nothing away. LINES lists them per VillageJob (resting villagers
## learn by building). TOOLS says which one puts a tool in the hand.

const STICKS := "digging_sticks"
const BASKETS := "baskets"
const STONES := "thrown_stones"
const SPEARS := "spears"
const CALLS := "watch_calls"
const FIRE := "fire"
const WORKSHOP := "workshop"
const RACKS := "drying_racks"
const ALL: Array[String] = [STICKS, BASKETS, STONES, SPEARS, CALLS, FIRE, WORKSHOP, RACKS]
const LINES := {
	VillageJob.GATHER: [STICKS, BASKETS],
	VillageJob.HUNT: [STONES, SPEARS],
	VillageJob.GUARD: [CALLS, FIRE],
	VillageJob.IDLE: [WORKSHOP, RACKS],
}
const LINE_TITLES := {VillageJob.GATHER: "gatherer", VillageJob.HUNT: "hunter",
	VillageJob.GUARD: "guard", VillageJob.IDLE: "builder"}
const TITLES := {STICKS: "Digging sticks", BASKETS: "Baskets", STONES: "Thrown stones",
	SPEARS: "Spears", CALLS: "Watch calls", FIRE: "Fire", WORKSHOP: "Workshop",
	RACKS: "Drying racks"}
const TEXTS := {
	STICKS: "Gatherers dig up roots: a new food worth 2 that only stick users can reach.",
	BASKETS: "Gatherers carry 3 loads a trip, and you can set a drop-off basket from the"
		+ " village view.",
	STONES: "Hunters hit prey from 9 m away, so it no longer gets away.",
	SPEARS: "Hunters take on the giant without a Rally, and hit prey 50% harder.",
	CALLS: "Guards call out raiders: the Alarm goes up by itself and ends with the raid.",
	FIRE: "A campfire at the centre. Predators will not come near it, so sheltering is safe.",
	WORKSHOP: "A workshop by the village: every job learns 50% faster.",
	RACKS: "Drying racks: the village keeps 15 more food.",
}
## Tool kinds drawn in a villager's hand: 1 stick, 2 basket, 3 stone, 4 spear, 5 horn.
const TOOLS := {STICKS: 1, BASKETS: 2, STONES: 3, SPEARS: 4, CALLS: 5}


static func title(id: String) -> String:
	var text: String = TITLES.get(id, id)
	return text


static func text(id: String) -> String:
	var words: String = TEXTS.get(id, "")
	return words


static func line(job: int) -> Array:
	var ids: Array = LINES.get(job, [])
	return ids


static func learner(job: int) -> String:
	var who: String = LINE_TITLES.get(job, "villager")
	return who
