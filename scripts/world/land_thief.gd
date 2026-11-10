class_name LandThief
extends Node
## The egg thief of stage 3: a rival animal that comes for the nest every
## so often while there are eggs in it. It sits on the nest for GRAB
## seconds, then runs off with an egg. The player drives it away by biting
## it, or just by coming close with frightening parts (LandBody.scare);
## kin near it bite as well. Killing a thief that holds an egg gets the egg
## back. Drawn by the LandCrowd it is added to.

signal notice(text: String)
signal cue(kind: String, at: Vector3)

const EVERY := 70.0
const HEALTH := 5.0
const FROM := 45.0
const GRAB := 4.0
const THINK := 0.3

## Empty, or the one thief now about.
var actors: Array[CrowdActor] = []
var rng := RandomNumberGenerator.new()
var stolen := 0
var driven_off := 0
## Seconds until the next thief sets out.
var comes_in := 50.0
var _grab := 0.0
var _wait := 0.0
var _body: AnimalBody


func step(animal: Animal, kin: Array[CrowdActor], powers: LandBody, nest: LandNest,
		delta: float) -> void:
	if actors.is_empty():
		comes_in -= delta
		if comes_in <= 0.0 and nest.eggs > 0:
			_send(nest.position)
		return
	var thief := actors[0]
	var far := thief.flat_to(animal.head())
	if thief.alive and far < 3.0 + thief.size():
		thief.hurt(powers.bite * delta)
		cue.emit("bite", thief.pos)
	if not thief.alive:
		_end()
		if thief.carrying > 0:
			nest.add_egg()
		cue.emit("kill", thief.pos)
		notice.emit("You killed the egg thief" + (" and saved the egg" if thief.carrying > 0 else ""))
		return
	if not thief.leaving and (far < powers.scare or thief.health < HEALTH * 0.6):
		thief.leaving = true
		driven_off += 1
		notice.emit("The egg thief takes fright and runs")
	_wait -= delta
	if _wait <= 0.0:
		_wait = THINK
		_think(thief, kin, nest)


func _think(thief: CrowdActor, kin: Array[CrowdActor], nest: LandNest) -> void:
	if CrowdFind.nearest(kin, thief.pos, 2.6 + thief.size()) != null:
		thief.hurt(THINK)
	var home := nest.position
	if thief.leaving:
		var away := thief.pos - home
		away.y = 0.0
		thief.hurry = 1.3
		thief.go(thief.pos + away.normalized() * 10.0)
		if thief.flat_to(home) > FROM + 10.0:
			_end()
		return
	thief.go(home)
	if thief.flat_to(home) > 2.5:
		return
	_grab += THINK
	if _grab >= GRAB and nest.steal():
		thief.carrying = 1
		thief.leaving = true
		stolen += 1
		cue.emit("hurt", home)
		notice.emit("The thief stole an egg! Catch it to get the egg back")


func _send(nest: Vector3) -> void:
	if _body == null:
		_body = AnimalRandom.make(rng)
		_body.hue = 0.78
		_body.hue2 = 0.9
	var from := CrowdFind.ring(nest, 0, FROM, rng.randf() * TAU)
	actors.append(CrowdActor.make(CrowdActor.RAIDER, _body, from, HEALTH))
	_grab = 0.0
	cue.emit("alarm", nest)
	notice.emit("An egg thief is heading for your nest!")


func _end() -> void:
	actors.clear()
	comes_in = EVERY
