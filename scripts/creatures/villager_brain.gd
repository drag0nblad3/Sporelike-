class_name VillagerBrain
extends RefCounted
## Decides what a stage 4 villager does, a few times a second: follow the
## elder's Rally, shelter on an Alarm, or do its job. Gatherers fetch food
## (near the focus flag if one is set), hunters chase small prey and carry the
## meat home, guards meet attackers and otherwise hold a post, and the
## rest raise the queued building or heal at the village. The elder's
## aura makes anyone inside it faster and stronger (Village.boost).

const REACH := 2.4
const DAMAGE := 1.0
## Guards are the fighters; anyone else only snaps back at what bites it.
const GUARD_SKILL := 1.5
const DEFEND := 0.5
const MEAT := 3
const GIANT_MEAT := 8
const FLAG_RANGE := 20.0
const HEAL := 0.4


static func think(v: CrowdActor, village: Village, dt: float) -> void:
	var boost := village.boost(v)
	v.hurry = boost
	if v.job != VillageJob.GUARD and v.rallied <= 0.0:
		var biter := village.enemy_near(v.pos, REACH + 1.0)
		if biter != null:
			biter.hurt(DAMAGE * DEFEND * village.damage(v) * dt)
	if v.rallied > 0.0:
		v.rallied -= dt
		_follow(v, village, dt)
	elif v.carrying > 0:
		v.go(village.center)
		if v.flat_to(village.center) < 3.5:
			village.deliver(v.carrying)
			v.carrying = 0
	elif village.alarm and v.job != VillageJob.GUARD:
		v.go(CrowdFind.ring(village.center, v.slot, 3.0))
	elif v.job == VillageJob.GATHER:
		_gather(v, village)
	elif v.job == VillageJob.HUNT:
		_hunt(v, village, dt)
	elif v.job == VillageJob.GUARD:
		_guard(v, village, dt)
	else:
		_rest(v, village, dt, boost)


## Walks to `foe` and bites it when in reach. True if that killed it.
static func fight(v: CrowdActor, foe: CrowdActor, village: Village, dt: float) -> bool:
	v.go(foe.pos)
	if v.flat_to(foe.pos) > REACH + foe.size():
		return false
	var skill := GUARD_SKILL if v.job == VillageJob.GUARD else 1.0
	foe.hurt(DAMAGE * skill * village.damage(v) * dt)
	if foe.foe == null or not foe.foe.alive:
		foe.foe = v
	return not foe.alive


static func _follow(v: CrowdActor, village: Village, dt: float) -> void:
	var elder := village.elder.pos
	var foe := village.enemy_near(elder, 12.0)
	if foe == null:
		foe = CrowdFind.nearest(village.prey, elder, 10.0)
	if foe == null:
		v.go(CrowdFind.ring(elder, v.slot, 3.0))
	elif fight(v, foe, village, dt) and foe.team == CrowdActor.PREY:
		_take_meat(v, foe, village)


static func _gather(v: CrowdActor, village: Village) -> void:
	var food := village.food
	if v.aim >= 0 and food.has(v.aim):
		var at := food.spot(v.aim)
		v.go(at)
		if v.flat_to(at) < 1.6 and food.take(v.aim):
			v.carrying = village.traits.haul
			v.aim = -1
		return
	if village.flag != Vector3.INF and v.flat_to(village.flag) > FLAG_RANGE:
		v.go(village.flag)
		return
	v.aim = food.nearest(v.pos, 30.0 if village.flag != Vector3.INF else 70.0)
	if v.aim < 0 and not v.moving:
		v.go(CrowdFind.ring(village.focus(), v.slot + randi() % 7, 12.0))


static func _hunt(v: CrowdActor, village: Village, dt: float) -> void:
	if v.foe == null or not v.foe.alive or v.foe.team != CrowdActor.PREY:
		var from := village.flag if village.flag != Vector3.INF else v.pos
		v.foe = _small_prey(village.prey, from)
	if v.foe == null:
		v.go(CrowdFind.ring(village.center, v.slot, 6.0))
	elif fight(v, v.foe, village, dt):
		_take_meat(v, v.foe, village)
		v.foe = null


## The nearest prey that is not the giant (that hunt needs the elder's Rally).
static func _small_prey(prey: Array[CrowdActor], from: Vector3) -> CrowdActor:
	var best: CrowdActor = null
	for p in prey:
		if p.alive and not p.giant and (best == null or p.flat_to(from) < best.flat_to(from)):
			best = p
	return best


static func _take_meat(v: CrowdActor, prey: CrowdActor, village: Village) -> void:
	v.carrying = GIANT_MEAT if prey.giant else MEAT
	if prey.giant:
		village.big_kill()


static func _guard(v: CrowdActor, village: Village, dt: float) -> void:
	var foe := village.enemy_near(village.center, 34.0)
	if foe != null:
		fight(v, foe, village, dt)
	elif village.raid_from != INF:
		v.go(CrowdFind.ring(village.center, v.slot, 9.0, village.raid_from, 1.6))
	else:
		v.go(CrowdFind.ring(village.center, v.slot, 9.0))


static func _rest(v: CrowdActor, village: Village, dt: float, boost: float) -> void:
	var site := village.buildings.site()
	if site != Vector3.INF:
		v.go(site)
		if v.flat_to(site) < 4.0:
			village.buildings.add_work(dt * boost)
		return
	v.go(CrowdFind.ring(village.center, v.slot, 4.5))
	if not v.moving:
		v.health = minf(v.health + HEAL * dt, v.max_health)
