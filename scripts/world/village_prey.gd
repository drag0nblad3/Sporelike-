class_name VillagePrey
extends Node
## Prey animals around a stage 4 village: two small herds that graze and
## run when bitten, and one giant that fights back (bringing it down is a
## run goal). All share one random body (the giant a second, drawn big).
## Killed prey come back at their herd's home after a while. Thinks a few
## times a second (PreyBrain).

const HERD := 4
const HERD_HEALTH := 4.0
const GIANT_HEALTH := 34.0
const RESPAWN := 40.0
const THINK := 0.5

var actors: Array[CrowdActor] = []
var _homes: Array[Vector3] = []
var _dead_for := PackedFloat32Array()
var _wait := 0.0


func setup(center: Vector3, rng: RandomNumberGenerator) -> void:
	var body := AnimalRandom.make(rng)
	var big := AnimalRandom.make(rng)
	var turn := rng.randf() * TAU
	for h in 3:
		var home := CrowdFind.ring(center, 0, 38.0 + h * 9.0, turn + h * 2.1)
		for k in (1 if h == 2 else HERD):
			var p := CrowdActor.make(CrowdActor.PREY, big if h == 2 else body,
				CrowdFind.ring(home, k, 4.0), GIANT_HEALTH if h == 2 else HERD_HEALTH)
			p.giant = h == 2
			p.speed = 2.4
			p.slot = actors.size()
			actors.append(p)
			_homes.append(home)
			_dead_for.append(0.0)


func step(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = THINK
	for i in actors.size():
		var p := actors[i]
		if p.alive:
			PreyBrain.think(p, _homes[i], THINK)
			continue
		_dead_for[i] += THINK
		if _dead_for[i] >= RESPAWN and not p.giant:
			_dead_for[i] = 0.0
			var at := _homes[i]
			p.pos = Vector3(at.x, LandHeight.at(at.x, at.z), at.z)
			p.health = p.max_health
			p.foe = null
			p.moving = false
			p.alive = true
