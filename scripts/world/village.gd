class_name Village
extends Node3D
## A stage 4 village: its villagers and elder (CrowdActors), the food in
## store, the jobs wanted (VillageJob), its buildings (VillageBuildings),
## the focus flag and the alarm. Runs each villager's VillagerBrain a few
## times a second, staggered, and buries the dead (births and the next
## elder are in VillageGrowth). Other parts hang their
## lists here so brains can find them: food (LandFood), prey, foes
## (raiders) and rivals (hostile only while at_war).

signal notice(text: String)
signal died(actor: CrowdActor)

const MOST := 12
const THINK := 0.3
const VILLAGER_HEALTH := 10.0
const ELDER_HEALTH := 24.0
const FOOD_PER_BIRTH := 4

var center := Vector3.ZERO
var villagers: Array[CrowdActor] = []
var elder: CrowdActor
var jobs := VillageJob.new()
var buildings := VillageBuildings.new()
var traits := VillageTraits.new()
## The body newborns get (the tribe's latest design).
var tribe_body: AnimalBody
var stock := 0
var flag := Vector3.INF
var alarm := false
## The direction (radians) a known raid comes from, or INF.
var raid_from := INF
var food: LandFood
var prey: Array[CrowdActor] = []
var foes: Array[CrowdActor] = []
var rivals: Array[CrowdActor] = []
var at_war := false
var killed_giant := false
var _next_slot := 0


func _ready() -> void:
	add_child(buildings)
	buildings.finished.connect(func(id: String, level: int) -> void:
		refresh_traits()
		notice.emit("%s level %d is built" % [VillageBuilding.title(id), level]))


func found(at: Vector3, body: AnimalBody, count: int) -> void:
	center = Vector3(at.x, LandHeight.at(at.x, at.z), at.z)
	buildings.place(center)
	tribe_body = body
	elder = CrowdActor.make(CrowdActor.VILLAGE, body, center, ELDER_HEALTH)
	for k in count:
		add_villager(body)
	refresh_traits()


func add_villager(body: AnimalBody) -> CrowdActor:
	var v := CrowdActor.make(CrowdActor.VILLAGE, body, CrowdFind.ring(center, _next_slot, 3.0),
		VILLAGER_HEALTH)
	v.slot = _next_slot
	_next_slot += 1
	villagers.append(v)
	jobs.assign(villagers)
	return v


func refresh_traits() -> void:
	traits = VillageTraits.of(tribe_body).with_tools(buildings.level(VillageBuilding.STORE),
		buildings.level(VillageBuilding.WALL))


func step(delta: float) -> void:
	for i in range(villagers.size() - 1, -1, -1):
		var v := villagers[i]
		if not v.alive:
			villagers.remove_at(i)
			jobs.assign(villagers)
			died.emit(v)
			continue
		v.think_in -= delta
		if v.think_in <= 0.0:
			v.think_in += THINK
			VillagerBrain.think(v, self, THINK)
	if buildings.level(VillageBuilding.WALL) >= 2:
		for foe in foes:
			if foe.alive and foe.flat_to(center) < VillageBuildings.WALL_RADIUS + 2.0:
				foe.hurt(VillageBuilding.THORNS * delta)


func set_job(job: int, step_by: int) -> void:
	jobs.change(job, step_by, villagers.size())
	jobs.assign(villagers)


func focus() -> Vector3:
	return flag if flag != Vector3.INF else center


func stock_cap() -> int:
	var cap: int = VillageBuilding.STOCK[buildings.level(VillageBuilding.STORE)]
	return cap


func deliver(count: int) -> void:
	stock = mini(stock + count, stock_cap())


func in_aura(actor: CrowdActor) -> bool:
	return elder.alive and actor.flat_to(elder.pos) < traits.aura


## How much faster `actor` works and walks (the elder's aura).
func boost(actor: CrowdActor) -> float:
	return VillageTraits.WORK_BOOST if in_aura(actor) else 1.0


func damage(actor: CrowdActor) -> float:
	return traits.attack * (VillageTraits.DAMAGE_BOOST if in_aura(actor) else 1.0)


## The share of a raider's bite that `actor` really takes.
func hurt_share(actor: CrowdActor) -> float:
	var share := traits.hurt
	if actor.job == VillageJob.GUARD and actor != elder \
			and actor.flat_to(center) < VillageBuildings.WALL_RADIUS + 3.0:
		var by_wall: float = VillageBuilding.GUARD_HURT[buildings.level(VillageBuilding.WALL)]
		share *= by_wall
	return share


## The nearest attacker to `at`: a raider, or a rival while at war.
func enemy_near(at: Vector3, reach: float) -> CrowdActor:
	var foe := CrowdFind.nearest(foes, at, reach)
	if foe == null and at_war:
		foe = CrowdFind.nearest(rivals, at, reach)
	return foe


## The nearest villager or the elder, for attackers.
func nearest_member(at: Vector3, reach: float) -> CrowdActor:
	var best := CrowdFind.nearest(villagers, at, reach)
	if elder.alive and (best == null or elder.flat_to(at) < best.flat_to(at)):
		best = elder
	return best


func big_kill() -> void:
	if not killed_giant:
		killed_giant = true
		notice.emit("Your hunters brought down the giant!")


## Villagers plus the elder.
func people() -> int:
	return villagers.size() + (1 if elder.alive else 0)
