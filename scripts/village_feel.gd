class_name VillageFeel
extends Node
## Makes stage 4 felt and explains it: watches a VillageLab a few times a
## second and plays a LandFeel cue when something changes (a villager
## lost or born, food stored, a building finished, a discovery, a raid
## starting, the elder biting), and offers the one-time village tips.

var feel := LandFeel.new()
var _people := -1
var _built := 0
var _known := 0
var _stock := 0
var _raid := false
var _warned := false


func _ready() -> void:
	add_child(feel)


func start(lab: VillageLab) -> void:
	feel.pops = lab
	lab.hud.tips.offer("s4_elder", "You walk as the elder. Villagers near you work 30% "
		+ "faster and fight harder. Walk into prey or raiders to bite them.")
	lab.hud.tips.offer("s4_view", "Village view shows the whole valley. Set how many "
		+ "gather, hunt and guard, order buildings, and tap the ground to plant a flag.")


## Called a few times a second by the lab.
func watch(lab: VillageLab) -> void:
	var village := lab.village
	var tips := lab.hud.tips
	var people := village.people()
	if _people >= 0 and people < _people:
		feel.cue("hurt")
	elif _people >= 0 and people > _people:
		feel.cue("born", village.center, "+%d born" % (people - _people))
	_people = people
	if village.stock > _stock:
		feel.cue("deliver", village.center, "+%d food" % (village.stock - _stock))
	_stock = village.stock
	var built := 0
	for id: String in VillageBuilding.ALL:
		built += village.buildings.level(id)
	if built > _built:
		feel.cue("build", village.center, "Built!", LandFeel.GOLD)
	_built = built
	var known := village.learning.known.size()
	if known > _known:
		feel.cue("learn", village.center, "Discovery!", LandFeel.GOLD)
		tips.offer("s4_learn", "Villagers learn by doing their job. Keep more of them on "
			+ "a job to fill its learning bar sooner.")
	_known = known
	if lab.raids.warned and not _warned:
		feel.cue("alarm")
		tips.offer("s4_raid", "Raiders are coming. Alarm in Village view pulls everyone "
			+ "home, and Rally makes those near you follow and fight beside you.")
	_warned = lab.raids.warned
	if lab.raids.active and not _raid:
		feel.cue("alarm")
	_raid = lab.raids.active
	if lab.generations.time_left < 45.0:
		tips.offer("s4_births", "When the generation ends, every %d stored food becomes "
			% Village.FOOD_PER_BIRTH + "a newborn, and you shape the newborns' body.")
	_bites(village)


func _bites(village: Village) -> void:
	var elder := village.elder
	if not elder.alive:
		return
	var foe := village.enemy_near(elder.pos, ElderActions.REACH + 1.0)
	if foe == null:
		foe = CrowdFind.nearest(village.prey, elder.pos, ElderActions.REACH + 1.5)
	if foe != null and elder.flat_to(foe.pos) < ElderActions.REACH + foe.size():
		feel.cue("bite", foe.pos, "Bite", LandFeel.BAD)
