class_name VillageJob
extends RefCounted
## The jobs a stage 4 villager can hold and how many the player wants in
## each (set from the overhead view). Villagers with no job rest at the
## village, heal, and raise whatever building is queued. assign() hands
## the jobs out, moving as few villagers as it can.

const IDLE := 0
const GATHER := 1
const HUNT := 2
const GUARD := 3
const WORKING: Array[int] = [GATHER, HUNT, GUARD]
const TITLES := {IDLE: "Resting", GATHER: "Gather", HUNT: "Hunt", GUARD: "Guard"}

var wanted := {GATHER: 2, HUNT: 1, GUARD: 1}


static func title(job: int) -> String:
	var text: String = TITLES.get(job, "")
	return text


func count(job: int) -> int:
	var n: int = wanted.get(job, 0)
	return n


func total() -> int:
	return count(GATHER) + count(HUNT) + count(GUARD)


## Changes how many are wanted in `job` by `step`, within the `roster` size.
func change(job: int, step: int, roster: int) -> void:
	var n := clampi(count(job) + step, 0, roster)
	wanted[job] = n
	# Never want more workers than there are villagers: trim the others.
	for other in WORKING:
		while total() > roster and other != job and count(other) > 0:
			wanted[other] = count(other) - 1


func assign(villagers: Array[CrowdActor]) -> void:
	var have := {GATHER: 0, HUNT: 0, GUARD: 0}
	for v in villagers:
		if v.job == IDLE:
			continue
		if int(have[v.job]) >= count(v.job):
			v.job = IDLE
			v.foe = null
		else:
			have[v.job] = int(have[v.job]) + 1
	for job in WORKING:
		for v in villagers:
			if int(have[job]) >= count(job):
				break
			if v.job == IDLE:
				v.job = job
				have[job] = int(have[job]) + 1
