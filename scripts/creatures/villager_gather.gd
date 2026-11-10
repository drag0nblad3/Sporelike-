class_name VillagerGather
extends RefCounted
## A stage 4 gatherer's rounds: walk to the nearest food (near the focus
## flag if one is set), or a root once the village has digging sticks,
## pick it up, and carry it to the store or the drop-off basket, whichever
## is nearer. With baskets it fills up with three loads before going back.

const FLAG_RANGE := 20.0
const BASKET_LOADS := 3


## Loads a gatherer holds before it heads home.
static func full(village: Village) -> int:
	var loads := BASKET_LOADS if village.learning.has(Discovery.BASKETS) else 1
	return loads * village.traits.haul


## Walks a loaded villager to where it can unload. True once unloaded.
static func bring_home(v: CrowdActor, village: Village) -> bool:
	var to := village.center
	var basket := village.camp.basket
	if v.job == VillageJob.GATHER and basket != Vector3.INF \
			and v.flat_to(basket) < v.flat_to(to):
		to = basket
	v.go(to)
	if v.flat_to(to) > 3.5:
		return false
	village.deliver(v.carrying)
	v.carrying = 0
	return true


static func think(v: CrowdActor, village: Village) -> void:
	if v.carrying >= full(village):
		bring_home(v, village)
		return
	var food := village.food
	var roots := village.roots
	# aim counts roots after the food: COUNT and up is a root.
	if v.aim >= LandFood.COUNT and roots.has(v.aim - LandFood.COUNT):
		var at := roots.spot(v.aim - LandFood.COUNT)
		v.go(at)
		if v.flat_to(at) < 1.8 and roots.take(v.aim - LandFood.COUNT):
			v.carrying += LandRoots.FOOD
			v.aim = -1
		return
	if v.aim >= 0 and v.aim < LandFood.COUNT and food.has(v.aim):
		var at := food.spot(v.aim)
		v.go(at)
		if v.flat_to(at) < 1.6 and food.take(v.aim):
			v.carrying += village.traits.haul
			v.aim = -1
		return
	if village.flag != Vector3.INF and v.flat_to(village.flag) > FLAG_RANGE:
		v.go(village.flag)
		return
	var reach := 30.0 if village.flag != Vector3.INF else 70.0
	v.aim = food.nearest(v.pos, reach)
	if village.learning.has(Discovery.STICKS):
		var root := roots.nearest(v.pos, reach)
		if root >= 0 and (v.aim < 0 or v.flat_to(roots.spot(root)) < v.flat_to(food.spot(v.aim)) + 6.0):
			v.aim = LandFood.COUNT + root
	if v.aim < 0:
		if v.carrying > 0:
			bring_home(v, village)
		elif not v.moving:
			v.go(CrowdFind.ring(village.focus(), v.slot + randi() % 7, 12.0))
