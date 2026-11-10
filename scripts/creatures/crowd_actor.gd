class_name CrowdActor
extends RefCounted
## One member of a land crowd (LandCrowd): a villager, the elder, a raider,
## a rival tribe member or a prey animal. Plain data so many can be stepped
## cheaply: where it is, where it walks to, its health, its job and what it
## carries. Its body is drawn as a simple shape (CrowdProxies) unless it is
## one of the few close to the camera, which borrow a full Animal (avatar).

const VILLAGE := 0
const RAIDER := 1
const RIVAL := 2
const PREY := 3

var team := VILLAGE
var body: AnimalBody
var pos := Vector3.ZERO
var heading := 0.0
## Where it is walking to, and whether it still has to get there.
var target := Vector3.ZERO
var moving := false
## Units per second at a walk, and how hard it is hurrying (1 = normal).
var speed := 3.5
var hurry := 1.0
var health := 10.0
var max_health := 10.0
var alive := true
## A VillageJob for villagers.
var job := 0
## Pieces of food or meat held.
var carrying := 0
## Who it is fighting or hunting, if anyone.
var foe: CrowdActor
## Seconds until its brain next thinks, and since it last did.
var think_in := 0.0
## Generations lived (the oldest villager becomes the next elder).
var age := 0
## Seconds left following the elder's Rally.
var rallied := 0.0
## True for the big prey animal that fights back.
var giant := false
## The piece of LandFood it is walking to, or -1.
var aim := -1
## True once a raider has given up and is heading home.
var leaving := false
## Its place in a ring or herd, so members spread out.
var slot := 0
var avatar: Animal


static func make(kind: int, shape: AnimalBody, at: Vector3, hp: float) -> CrowdActor:
	var actor := CrowdActor.new()
	actor.team = kind
	actor.body = shape
	actor.pos = Vector3(at.x, LandHeight.at(at.x, at.z), at.z)
	actor.target = actor.pos
	actor.speed = clampf(shape.speed() * 0.8, 2.6, 5.5)
	actor.health = hp
	actor.max_health = hp
	actor.think_in = randf() * 0.3
	actor.heading = randf() * TAU
	return actor


## Heads for `to`; already there if it is within arm's reach.
func go(to: Vector3) -> void:
	target = to
	moving = flat_to(to) > CrowdMotion.ARRIVE


func flat_to(to: Vector3) -> float:
	return Vector2(to.x - pos.x, to.z - pos.z).length()


func hurt(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		alive = false


## How big its simple shape is drawn.
func size() -> float:
	var most := 0.0
	for r in body.radii:
		most = maxf(most, r)
	return most * (2.2 if giant else 1.0)
