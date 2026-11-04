class_name HunterPack
extends RefCounted
## A swarm of PackHunter dinoflagellates that share one target: whoever
## spots prey first, the whole swarm goes after it.

var members: Array[Predator] = []
var target: Organism


func center() -> Vector2:
	var sum := Vector2.ZERO
	var alive := 0
	for m in members:
		if is_instance_valid(m):
			sum += m.flat_pos()
			alive += 1
	return sum / maxf(alive, 1)


## The swarm's current prey, re-picked by this member if it is gone, out of
## sight or no longer wanted.
func refresh(hunter: Predator) -> Organism:
	if is_instance_valid(target) and target.alive and not target.dormant \
			and hunter.wants(target) \
			and center().distance_to(target.flat_pos()) < hunter.sight_range() * 1.5:
		return target
	target = hunter.nearest_prey()
	return target


func index_of(hunter: Predator) -> int:
	return members.find(hunter)
