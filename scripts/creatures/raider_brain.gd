class_name RaiderBrain
extends RefCounted
## A raider (a land predator or an aggressive rival) in stage 4: goes for
## the nearest villager or the elder and bites it; once the raid is called
## off (leaving) it walks back the way it came. Predators keep away from a
## lit campfire (VillageCamp). Guards near a wall take
## less of its damage (Village.hurt_share).

const REACH := 2.4
const DAMAGE := 0.6


static func think(r: CrowdActor, village: Village, home: Vector3, dt: float) -> void:
	if r.leaving:
		r.foe = null
		r.go(home)
		return
	if r.foe == null or not r.foe.alive:
		r.foe = village.nearest_member(r.pos, 200.0)
	var foe := r.foe
	if foe == null:
		r.go(village.center)
		return
	var center := village.center
	if village.camp.fire_lit and r.team == CrowdActor.RAIDER \
			and foe.flat_to(center) < VillageCamp.FIRE_REACH:
		# A predator will not come near the fire: it prowls round the edge.
		var out := r.pos - center
		out.y = 0.0
		r.go(center + out.normalized() * (VillageCamp.FIRE_REACH + 2.5))
		r.foe = null
		return
	r.go(foe.pos)
	if r.flat_to(foe.pos) < REACH + r.size():
		foe.hurt(DAMAGE * village.hurt_share(foe) * dt)
	# Switch to whoever is closer now and then, so guards can draw them off.
	if randf() < 0.15:
		r.foe = village.nearest_member(r.pos, 200.0)
