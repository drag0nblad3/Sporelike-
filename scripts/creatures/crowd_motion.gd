class_name CrowdMotion
extends RefCounted
## Walks a CrowdActor toward its target over the land. One with a full
## Animal on (avatar) steers that body and takes its place from it, so the
## legs step for real; the others just slide over the ground.

const ARRIVE := 1.1
const TURN := 4.0


static func step(actor: CrowdActor, delta: float) -> void:
	var to := actor.target - actor.pos
	to.y = 0.0
	var far := to.length()
	if far < ARRIVE:
		actor.moving = false
	var pace := actor.speed * actor.hurry if actor.moving else 0.0
	var animal := actor.avatar
	if animal != null:
		var top := maxf(animal.body.speed(), 0.1)
		var push := to / maxf(far, 0.001) * minf(pace / top, 1.0)
		animal.move_input = Vector2(push.x, push.z)
		var head := animal.head()
		actor.pos = Vector3(head.x, LandHeight.at(head.x, head.z), head.z)
		actor.heading = animal.heading
		return
	if pace <= 0.0:
		return
	var dir := to / far
	actor.heading = rotate_toward(actor.heading, atan2(dir.x, dir.z), TURN * delta)
	var p := actor.pos + dir * minf(pace * delta, far)
	actor.pos = Vector3(p.x, LandHeight.at(p.x, p.z), p.z)
