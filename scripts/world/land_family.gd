class_name LandFamily
extends Node3D
## The social end of stage 3: kin. When a generation hatches, half its
## eggs (rounded up) become kin with the player's body, who follow the
## player around. Now and then a prowler (a land predator) comes for
## them; kin fight it when it is close, or wherever it is while the
## player's Call lasts, and the player bites it by walking up to it. With
## FOUND kin alive and the player at the nest, a village can be founded
## (ready_to_found), which opens stage 4. Drawn through a LandCrowd.

signal notice(text: String)
## A moment worth a sound (LandFeel): its kind and where.
signal cue(kind: String, at: Vector3)

const MOST := 6
const FOUND := 4
const KIN_HEALTH := 8.0
const CALL_TIME := 15.0
const THINK := 0.3
const PROWL_EVERY := 80.0
const PROWLER_HEALTH := 12.0
const BITE := 2.4

var crowd := LandCrowd.new()
var kin: Array[CrowdActor] = []
var prowlers: Array[CrowdActor] = []
var called := 0.0
var rng := RandomNumberGenerator.new()
## Seconds until the next prowler comes.
var prowl_in := PROWL_EVERY
## The player's bite, per second (LandBody.bite).
var bite := BITE
var _wait := 0.0
var _prowler_body: AnimalBody


func _ready() -> void:
	add_child(crowd)
	crowd.add_group(kin)
	crowd.add_group(prowlers)


## Eggs hatch: some become kin with `body`. Returns how many.
func hatch(eggs: int, body: AnimalBody, nest: Vector3) -> int:
	var born := mini((eggs + 1) / 2, MOST - kin.size())
	for k in born:
		var child := CrowdActor.make(CrowdActor.VILLAGE, body, CrowdFind.ring(nest, kin.size(), 3.0),
			KIN_HEALTH)
		child.slot = kin.size()
		kin.append(child)
	return born


func call_kin() -> void:
	called = CALL_TIME
	cue.emit("call", Vector3.INF)
	notice.emit("You call your kin to you" if not kin.is_empty() else "No kin to call yet")


func ready_to_found(player: Vector3, nest: LandNest) -> bool:
	return kin.size() >= FOUND and nest.is_near(player)


func step(animal: Animal, delta: float) -> void:
	called -= delta
	prowl_in -= delta
	var at := animal.head()
	if prowl_in <= 0.0 and not kin.is_empty() and prowlers.is_empty():
		prowl_in = PROWL_EVERY
		_send_prowler(at)
	for p in prowlers:
		if p.alive and p.flat_to(at) < 3.2 + p.size():
			p.hurt(bite * delta)
			cue.emit("bite", p.pos)
	_wait -= delta
	if _wait <= 0.0:
		_wait = THINK
		_think(at)
	crowd.step(animal.focus(), delta)


func _think(at: Vector3) -> void:
	for i in range(prowlers.size() - 1, -1, -1):
		var p := prowlers[i]
		if not p.alive:
			prowlers.remove_at(i)
			notice.emit("The prowler is dead. Your family is safe")
			continue
		var prey := CrowdFind.nearest(kin, p.pos, 300.0)
		if prey != null:
			p.go(prey.pos)
			if p.flat_to(prey.pos) < 2.4 + p.size():
				prey.hurt(1.0 * THINK)
	for i in range(kin.size() - 1, -1, -1):
		var k := kin[i]
		if not k.alive:
			kin.remove_at(i)
			notice.emit("A prowler killed one of your kin. %d left" % kin.size())
			continue
		var foe := CrowdFind.nearest(prowlers, k.pos, 40.0 if called > 0.0 else 7.0)
		k.hurry = 1.3 if k.flat_to(at) > 9.0 else 1.0
		if foe != null:
			k.go(foe.pos)
			if k.flat_to(foe.pos) < 2.4 + foe.size():
				foe.hurt(1.0 * THINK)
		elif k.flat_to(at) > (3.0 if called > 0.0 else 6.0):
			k.go(CrowdFind.ring(at, k.slot, 3.0))


func _send_prowler(at: Vector3) -> void:
	if _prowler_body == null:
		_prowler_body = AnimalRandom.make(rng)
		_prowler_body.hue = 0.0
		_prowler_body.hue2 = 0.08
	var from := CrowdFind.ring(at, 0, 55.0, rng.randf() * TAU)
	prowlers.append(CrowdActor.make(CrowdActor.RAIDER, _prowler_body, from, PROWLER_HEALTH))
	cue.emit("alarm", at)
	notice.emit("A prowler is hunting your kin! Call them and fight it together")
