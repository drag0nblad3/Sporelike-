class_name VillageLearning
extends RefCounted
## What a stage 4 village has learned and is learning. Each job's bar
## fills with the seconds its villagers spend working; a full bar means
## someone figured something out, and the player picks one Discovery from
## that job's line. More villagers in a job fill its bar faster, which is
## how a tribe specializes. rate: hands and the Workshop speed it up.

## Villager-seconds for a job's first and second discovery.
const NEED := [110.0, 220.0]
## Builders only learn while building, so their bar is shorter.
const BUILDER_NEED := [35.0, 70.0]

var known: Array[String] = []
var progress := {VillageJob.GATHER: 0.0, VillageJob.HUNT: 0.0, VillageJob.GUARD: 0.0,
	VillageJob.IDLE: 0.0}
var rate := 1.0


func has(id: String) -> bool:
	return known.has(id)


## The discoveries of `job`'s line not yet learned.
func offers(job: int) -> Array[String]:
	var open: Array[String] = []
	for id: String in Discovery.line(job):
		if not has(id):
			open.append(id)
	return open


func need(job: int) -> float:
	var steps: Array = BUILDER_NEED if job == VillageJob.IDLE else NEED
	var done := Discovery.line(job).size() - offers(job).size()
	var seconds: float = steps[mini(done, steps.size() - 1)]
	return seconds


func add(job: int, seconds: float) -> void:
	if not offers(job).is_empty():
		progress[job] = float(progress[job]) + seconds * rate


## Share of `job`'s bar filled, 0 to 1 (1 when its line is finished).
func share(job: int) -> float:
	if offers(job).is_empty():
		return 1.0
	return clampf(float(progress[job]) / need(job), 0.0, 1.0)


## A job whose bar is full and has something left to learn, or -1.
func ready_job() -> int:
	for job: int in progress:
		if not offers(job).is_empty() and float(progress[job]) >= need(job):
			return job
	return -1


func learn(id: String) -> void:
	if has(id):
		return
	for job: int in progress:
		if Discovery.line(job).has(id):
			progress[job] = 0.0
	known.append(id)


## The tool a villager in `job` carries (see Discovery.TOOLS), or 0.
func tool(job: int) -> int:
	var best := 0
	for id: String in Discovery.line(job):
		if has(id) and Discovery.TOOLS.has(id):
			best = maxi(best, int(Discovery.TOOLS[id]))
	return best


func known_text() -> String:
	var names := PackedStringArray()
	for id in known:
		names.append(Discovery.title(id))
	return "nothing yet" if names.is_empty() else ", ".join(names)
