class_name LandPrey
extends Node
## Grazers of stage 3: small herds that feed around their home ground and
## bolt when the player comes close. They outrun the player for SPRINT
## seconds, then tire, so a chase that keeps going catches one (kin close
## by bite too). A kill fills the player's mouth with meat and every kin
## close by carries a piece home to the nest. Killed grazers are replaced
## far away after a while. Drawn by the LandCrowd they are added to.

signal notice(text: String)
signal cue(kind: String, at: Vector3)

const COUNT := 8
const HERD := 4
const HEALTH := 5.0
const SEE := 13.0
const SPRINT := 4.0
const TIRED := 5.0
const RESPAWN := 35.0
const THINK := 0.3
const FEAST_REACH := 12.0

var actors: Array[CrowdActor] = []
var rng := RandomNumberGenerator.new()
var kills := 0
var _homes: Array[Vector3] = []
var _due: Array[float] = []
var _wait := 0.0
var _body: AnimalBody


func _ready() -> void:
	_body = AnimalRandom.make(rng)
	_body.hue = 0.12
	_body.hue2 = 0.16
	for h in COUNT / HERD:
		_homes.append(_far_spot(Vector3.ZERO, 30.0, 60.0))
	for i in COUNT:
		_add(i)


## How far the nearest grazer is from `at` (INF when none are left).
func nearest_distance(at: Vector3) -> float:
	var near := CrowdFind.nearest(actors, at, 9999.0)
	return INF if near == null else near.flat_to(at)


func step(animal: Animal, kin: Array[CrowdActor], powers: LandBody, goals: LandGoals,
		delta: float) -> void:
	var at := animal.head()
	for i in range(_due.size() - 1, -1, -1):
		_due[i] -= delta
		if _due[i] <= 0.0:
			_due.remove_at(i)
			_homes[0] = _far_spot(at, 45.0, 70.0)
			_add(0)
	for i in range(actors.size() - 1, -1, -1):
		var p := actors[i]
		if p.alive and p.flat_to(at) < 3.0 + p.size():
			p.hurt(powers.bite * delta)
			cue.emit("bite", p.pos)
		if not p.alive:
			actors.remove_at(i)
			_due.append(RESPAWN)
			_feast(p, kin, goals)
	_wait -= delta
	if _wait <= 0.0:
		_wait = THINK
		for p in actors:
			_think(p, at, animal.body.speed(), kin)


func _think(p: CrowdActor, at: Vector3, chaser_speed: float, kin: Array[CrowdActor]) -> void:
	var biter := CrowdFind.nearest(kin, p.pos, 2.6 + p.size())
	if biter != null:
		p.hurt(THINK)
	if p.flat_to(at) > SEE:
		p.wind = maxf(p.wind - THINK, 0.0)
		p.hurry = 0.6
		if not p.moving and rng.randf() < 0.2:
			p.go(CrowdFind.ring(_homes[p.slot % _homes.size()], rng.randi() % 30, 5.0))
		return
	p.wind += THINK
	if p.wind > SPRINT + TIRED:
		p.wind = 0.0
	# Fresh, it outruns the player; winded, it cannot.
	p.hurry = chaser_speed * (1.15 if p.wind < SPRINT else 0.55) / p.speed
	var away := p.pos - at
	away.y = 0.0
	p.go(p.pos + away.normalized() * 10.0)


func _feast(p: CrowdActor, kin: Array[CrowdActor], goals: LandGoals) -> void:
	kills += 1
	var helpers := 0
	for k in kin:
		if k.alive and k.flat_to(p.pos) < FEAST_REACH:
			helpers += 1
	goals.food.carried = goals.food.capacity
	goals.nest.deliver(helpers)
	cue.emit("kill", p.pos)
	var line := "You caught a grazer! Your mouth is full of meat"
	if helpers > 0:
		line += ", and %d kin carry a piece home" % helpers
	notice.emit(line)


func _add(index: int) -> void:
	var home := _homes[(index / HERD) % _homes.size()]
	var actor := CrowdActor.make(CrowdActor.PREY, _body, CrowdFind.ring(home, index, 4.0), HEALTH)
	actor.slot = index / HERD
	actor.speed = 4.0
	actors.append(actor)


## Dry ground between `near` and `far` units from `from`.
func _far_spot(from: Vector3, near: float, far: float) -> Vector3:
	var spot := from
	for _try in 8:
		spot = CrowdFind.ring(from, 0, rng.randf_range(near, far), rng.randf() * TAU)
		if LandRiver.wet(spot.x, spot.z) < 0.1:
			break
	return spot
