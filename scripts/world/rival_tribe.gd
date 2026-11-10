class_name RivalTribe
extends Node3D
## The other tribe in a stage 4 valley: its own species (one random body)
## camped some way off. Its members gather the same food the village
## wants. Each generation it grows if it ate well and decides its mood:
## peaceful (keeps to itself) or aggressive (its members make up the
## raids). Walking the elder into a peaceful camp gives offence. It never
## helps the village. Gone once every member is dead.

signal notice(text: String)

const START := 4
const MOST := 8
const HEALTH := 9.0
const THINK := 0.5
const CAMP_REACH := 9.0
const FOOD_TO_GROW := 4

var camp := Vector3.ZERO
var actors: Array[CrowdActor] = []
## Members away raiding (VillageRaids holds them meanwhile).
var away := 0
var aggressive := false
var gone := false
var eaten := 0
var body: AnimalBody
var rng := RandomNumberGenerator.new()
var _wait := 0.0


func setup(center: Vector3, seed_value: int) -> void:
	rng.seed = seed_value
	body = AnimalRandom.make(rng)
	var turn := rng.randf() * TAU
	camp = CrowdFind.ring(center, 0, 85.0, turn)
	camp.y = LandHeight.at(camp.x, camp.z)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 2.2
	torus.outer_radius = 3.0
	torus.rings = 16
	torus.ring_segments = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.25, 0.45)
	torus.material = mat
	ring.mesh = torus
	ring.position = camp + Vector3.UP * 0.2
	add_child(ring)
	for k in START:
		_add()
	aggressive = rng.randf() < 0.35


func size() -> int:
	return actors.size() + away


func mood() -> String:
	if gone:
		return "driven out"
	return "aggressive" if aggressive else "peaceful"


func step(delta: float, village: Village) -> void:
	if gone:
		return
	if size() == 0:
		gone = true
		notice.emit("The rival tribe is driven out of the valley!")
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = THINK
	if not aggressive and village.elder.alive and village.elder.flat_to(camp) < CAMP_REACH:
		aggressive = true
		notice.emit("The rival tribe takes offence at your trespass. They are aggressive now")
	village.at_war = aggressive
	for i in range(actors.size() - 1, -1, -1):
		var r := actors[i]
		if not r.alive:
			actors.remove_at(i)
			continue
		var foe: CrowdActor = village.nearest_member(r.pos, 9.0) if aggressive else null
		if foe != null:
			r.go(foe.pos)
			if r.flat_to(foe.pos) < RaiderBrain.REACH + r.size():
				foe.hurt(RaiderBrain.DAMAGE * village.hurt_share(foe) * THINK)
		else:
			_forage(r, village.food)


## A new generation: grow if fed, and settle this generation's mood.
func new_generation(village_size: int) -> void:
	if gone:
		return
	var grow := mini(eaten / FOOD_TO_GROW, 2)
	eaten = 0
	for k in grow:
		if size() < MOST:
			_add()
	# A grudge mostly lasts; a bigger tribe picks fights more readily.
	var stays := aggressive and rng.randf() < 0.7
	aggressive = stays or rng.randf() < (0.5 if size() > village_size else 0.3)
	notice.emit("The rival tribe (%d) is %s this generation" % [size(), mood()])


## Hands over up to `count` members for a raid.
func send(count: int) -> Array[CrowdActor]:
	var party: Array[CrowdActor] = []
	while party.size() < count and actors.size() > 1:
		var r: CrowdActor = actors.pop_back()
		r.aim = -1
		r.carrying = 0
		r.leaving = false
		party.append(r)
	away += party.size()
	return party


## A raider is back at camp (alive) or dead.
func returned(r: CrowdActor) -> void:
	away -= 1
	if r.alive:
		r.leaving = false
		r.foe = null
		actors.append(r)


func _add() -> void:
	var r := CrowdActor.make(CrowdActor.RIVAL, body, CrowdFind.ring(camp, actors.size(), 3.5), HEALTH)
	r.slot = actors.size() + away
	actors.append(r)


func _forage(r: CrowdActor, food: LandFood) -> void:
	if r.carrying > 0:
		r.go(camp)
		if r.flat_to(camp) < 3.5:
			eaten += r.carrying
			r.carrying = 0
	elif r.aim >= 0 and food.has(r.aim):
		r.go(food.spot(r.aim))
		if r.flat_to(food.spot(r.aim)) < 1.8 and food.take(r.aim):
			r.carrying = 1
			r.aim = -1
	else:
		r.aim = food.nearest(r.pos, 60.0)
