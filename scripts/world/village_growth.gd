class_name VillageGrowth
extends RefCounted
## How a stage 4 village renews itself: stored food becomes newborns at
## the end of a generation (as many as the nursery allows), and when the
## elder dies the oldest villager takes over.


## Newborns the food in store and the nursery allow right now.
static func births_due(village: Village) -> int:
	var allowed: int = VillageBuilding.BIRTHS[village.buildings.level(VillageBuilding.NURSERY)]
	var fed := village.stock / Village.FOOD_PER_BIRTH
	return maxi(mini(mini(allowed, fed), Village.MOST - village.villagers.size()), 0)


## Turns stored food into newborns with `body`; returns how many.
static func births(village: Village, body: AnimalBody) -> int:
	village.tribe_body = body
	village.refresh_traits()
	var count := births_due(village)
	for v in village.villagers:
		v.age += 1
	for k in count:
		village.add_villager(body)
	village.stock -= count * Village.FOOD_PER_BIRTH
	return count


## The oldest villager steps up as elder; null when nobody is left.
static func next_elder(village: Village) -> CrowdActor:
	if village.villagers.is_empty():
		return null
	var oldest := village.villagers[0]
	for v in village.villagers:
		if v.age > oldest.age:
			oldest = v
	village.villagers.erase(oldest)
	oldest.max_health = Village.ELDER_HEALTH
	oldest.health = Village.ELDER_HEALTH
	oldest.job = VillageJob.IDLE
	oldest.carrying = 0
	village.elder = oldest
	village.jobs.assign(village.villagers)
	return oldest
