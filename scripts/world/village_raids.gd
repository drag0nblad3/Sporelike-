class_name VillageRaids
extends Node
## The raid of each stage 4 generation. Two thirds of the way through, a
## pack of land predators (bigger each generation) comes from one side, or
## the rival tribe's own members when it is aggressive. A warning comes
## first (longer with a Lookout and sharp eyes); the Lookout also tells
## the side and, upgraded, the size. The raid breaks off after a while or
## when the raiders are dead; it was clean if no villager died.

signal notice(text: String)
signal ended(clean: bool)

const WHEN := 0.62
const LASTS := 50.0
const FROM := 62.0
const HEALTH := 6.0
const THINK := 0.3
const SIDES := ["south", "south-east", "east", "north-east", "north", "north-west", "west",
	"south-west"]

var actors: Array[CrowdActor] = []
var active := false
var warned := false
var done := false
var losses := 0
var count := 0
var from := 0.0
var rival_party := false
var rng := RandomNumberGenerator.new()
var _home := Vector3.ZERO
var _left := 0.0
var _wait := 0.0
var _pack: AnimalBody


## A new generation: plans its raid. Raiders still about give up.
func plan(generation: int) -> void:
	warned = false
	done = false
	active = false
	losses = 0
	for r in actors:
		r.leaving = true
	count = mini(1 + generation, 6)
	from = rng.randf() * TAU
	if _pack == null:
		_pack = AnimalRandom.make(rng)
		_pack.hue = 0.0
		_pack.hue2 = 0.08


## `share` of the generation gone (0 to 1).
func step(delta: float, share: float, length: float, village: Village, rival: RivalTribe) -> void:
	if not done:
		_schedule(share, length, village, rival)
	if actors.is_empty():
		return
	_left -= delta
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = THINK
	for i in range(actors.size() - 1, -1, -1):
		var r := actors[i]
		r.leaving = r.leaving or _left <= 0.0
		if r.alive and not (r.leaving and r.flat_to(_home) < 6.0):
			RaiderBrain.think(r, village, _home, THINK)
			continue
		actors.remove_at(i)
		if r.team == CrowdActor.RIVAL:
			rival.returned(r)
	if actors.is_empty() and active:
		_finish(village)


func _schedule(share: float, length: float, village: Village, rival: RivalTribe) -> void:
	var level := village.buildings.level(VillageBuilding.LOOKOUT)
	var lead: float = (VillageBuilding.WARNING[level] + village.traits.warning) / length
	if not warned and share >= WHEN - lead:
		warned = true
		rival_party = rival.aggressive and rival.actors.size() > 2
		if rival_party:
			var to_camp := rival.camp - village.center
			from = atan2(to_camp.x, to_camp.z)
		_warn(level, village)
	if warned and not active and share >= WHEN and actors.is_empty():
		_start(village, rival)


func _warn(level: int, village: Village) -> void:
	var text := "A raid is coming!"
	if level >= 1:
		village.raid_from = from
		text = "A raid is coming from the %s!" % side(from)
	if level >= 2:
		text += " %d %s" % [count, "rival warriors" if rival_party else "predators"]
	notice.emit(text)


func _start(village: Village, rival: RivalTribe) -> void:
	active = true
	_left = LASTS
	_home = CrowdFind.ring(village.center, 0, FROM, from)
	if rival_party:
		_home = rival.camp
		for r in rival.send(count):
			actors.append(r)
	else:
		for k in count:
			var r := CrowdActor.make(CrowdActor.RAIDER, _pack, CrowdFind.ring(_home, k, 3.0), HEALTH)
			r.slot = k
			actors.append(r)
	notice.emit("The raid is here! Rally your villagers")


func _finish(village: Village) -> void:
	active = false
	done = true
	village.raid_from = INF
	notice.emit("The raid is over. %s" % ("Nobody was lost!" if losses == 0
		else "%d villagers were lost" % losses))
	ended.emit(losses == 0)


## The compass side an angle (as CrowdFind.ring uses) points to.
static func side(angle: float) -> String:
	var text: String = SIDES[posmod(roundi(angle / (TAU / 8.0)), 8)]
	return text
