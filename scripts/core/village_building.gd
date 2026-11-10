class_name VillageBuilding
extends RefCounted
## The four buildings of a stage 4 village and what each level gives.
## Each has two levels; WORK is the villager-seconds a level takes to raise.

const STORE := "store"
const NURSERY := "nursery"
const LOOKOUT := "lookout"
const WALL := "wall"
const ALL: Array[String] = [STORE, NURSERY, LOOKOUT, WALL]
const MAX_LEVEL := 2
const WORK := [45.0, 90.0]
const TITLES := {STORE: "Food store", NURSERY: "Nursery", LOOKOUT: "Lookout", WALL: "Wall"}
## Food the village can keep, by store level.
const STOCK := [8, 20, 40]
## Births allowed per generation, by nursery level.
const BIRTHS := [1, 2, 4]
## Seconds of raid warning, by lookout level.
const WARNING := [15.0, 30.0, 30.0]
## Share of damage guards near the wall still take, by wall level.
const GUARD_HURT := [1.0, 0.6, 0.6]
## Damage per second the level 2 thorn wall does to attackers near it.
const THORNS := 0.5
const EFFECTS := {
	STORE: ["Keeps 20 food (8 without)", "Keeps 40 food"],
	NURSERY: ["2 births per generation (1 without)", "4 births per generation"],
	LOOKOUT: ["Raid warning 30 s ahead, shows the side", "Also shows the raid's size"],
	WALL: ["Guards near it take 40% less damage", "Thorns hurt attackers 0.5/s"],
}


static func title(id: String) -> String:
	var text: String = TITLES.get(id, id)
	return text


## What the next level of `id` gives, or "" when it is finished.
static func next_effect(id: String, level: int) -> String:
	if level >= MAX_LEVEL:
		return ""
	var lines: Array = EFFECTS[id]
	var text: String = lines[level]
	return text


static func work(level: int) -> float:
	var need: float = WORK[clampi(level, 0, MAX_LEVEL - 1)]
	return need
