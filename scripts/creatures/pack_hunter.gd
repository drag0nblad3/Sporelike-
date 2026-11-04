class_name PackHunter
extends Predator
## A swarm dinoflagellate: small and fast, with a girdle groove and a
## trailing flagellum. Too small to swallow grown cells, but the swarm
## (HunterPack) chases one target together and spreads out to flank it.

## How far to the side each member aims while closing in.
const FLANK := 1.6
const REGROUP := 3.0

var pack: HunterPack


func _ready() -> void:
	super._ready()
	add_child(HunterLook.girdle(tint()))


func think(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	var me := flat_pos()
	var home := pack.center()
	if cooldown > 0.0:
		move_input = (home - me).normalized() * 0.5 if me.distance_to(home) > REGROUP \
			else wander_input(delta) * 0.5
		return
	var prey := pack.refresh(self)
	if prey == null:
		move_input = (home - me).normalized() * 0.7 if me.distance_to(home) > REGROUP \
			else wander_input(delta)
		return
	var aim := prey.flat_pos()
	var gap := me.distance_to(aim)
	if gap > 3.0:
		# Spread out left and right of the prey so it is hard to dodge.
		var side := Vector2(-(aim - me).y, (aim - me).x).normalized()
		var slot := pack.index_of(self) - (pack.members.size() - 1) / 2.0
		aim += side * slot * FLANK * minf(gap / 8.0, 1.0)
	move_input = (aim - me).normalized()
