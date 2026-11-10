class_name ElderActions
extends RefCounted
## What the stage 4 elder does by simply being somewhere: bites the
## nearest attacker or prey in reach, works on the building site it stands
## at (as two villagers), drops carried food at the village store, and
## heals at home. Keeps the elder's CrowdActor where the Animal walks.

const REACH := 3.2
const DAMAGE := 2.4
const WORK := 2.0
const HEAL := 0.5


static func step(village: Village, animal: Animal, delta: float) -> void:
	var elder := village.elder
	var head := animal.head()
	elder.pos = Vector3(head.x, LandHeight.at(head.x, head.z), head.z)
	elder.heading = animal.heading
	var foe := village.enemy_near(elder.pos, REACH + 1.0)
	if foe == null:
		foe = CrowdFind.nearest(village.prey, elder.pos, REACH + 1.5)
	if foe != null and elder.flat_to(foe.pos) < REACH + foe.size():
		foe.hurt(DAMAGE * village.traits.attack * delta)
		foe.foe = elder
		if not foe.alive and foe.team == CrowdActor.PREY:
			if foe.giant:
				village.big_kill()
				village.deliver(VillagerBrain.GIANT_MEAT)
			else:
				village.food.carried = LandFood.CARRY
	var site := village.buildings.site()
	if site != Vector3.INF and elder.flat_to(site) < 4.5:
		village.buildings.add_work(WORK * delta)
	if elder.flat_to(village.center) < 4.0:
		if village.food.carried > 0:
			village.deliver(village.food.drop_all())
		elder.health = minf(elder.health + HEAL * delta, elder.max_health)


## Calls every villager within `reach` to follow the elder for `seconds`.
static func rally(village: Village, reach: float, seconds: float) -> int:
	var called := 0
	for v in village.villagers:
		if v.flat_to(village.elder.pos) < reach:
			v.rallied = seconds
			called += 1
	return called
