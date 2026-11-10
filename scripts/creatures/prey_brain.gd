class_name PreyBrain
extends RefCounted
## A prey animal on the stage 4 land: grazes around its herd's home, runs
## from whoever bit it, and forgets once they fall behind. The giant one
## stands and fights back instead.

const FORGET := 16.0
const GIANT_DAMAGE := 1.4


static func think(p: CrowdActor, home: Vector3, dt: float) -> void:
	var hunter := p.foe
	if hunter != null and (not hunter.alive or p.flat_to(hunter.pos) > FORGET):
		p.foe = null
		hunter = null
	if hunter == null:
		p.hurry = 0.6
		if not p.moving and randf() < 0.2:
			p.go(CrowdFind.ring(home, randi() % 40, 6.0))
		return
	p.hurry = 1.0
	if p.giant:
		p.go(hunter.pos)
		if p.flat_to(hunter.pos) < 2.5 + p.size():
			hunter.hurt(GIANT_DAMAGE * dt)
		return
	var away := p.pos - hunter.pos
	away.y = 0.0
	p.go(p.pos + away.normalized() * 10.0)
