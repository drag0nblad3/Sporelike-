class_name ColonyCaster
extends RefCounted
## Fires a colony's active abilities (ColonyAbility) for the player and
## rival colonies: checks the body has the cells, the recharge and the
## energy, then applies the effect and shows it with AbilityFx.


## Returns whether it fired. `others` are the colonies a Sting can hit.
static func fire(colony: Colony, id: String, eco: Ecosystem, others: Array) -> bool:
	if not ColonyAbility.has(colony.plan, id) or not colony.abilities.ready(id):
		return false
	var cost := float(ColonyAbility.COST[id])
	if cost > 0.0 and colony.energy <= cost * 2.0:
		return false
	match id:
		"surge":
			colony.surge_time = ColonyAbility.SURGE_TIME
			_show(colony, colony.reach(), id, false)
		"sting":
			_sting(colony, eco, others)
		"curl":
			colony.curl_time = ColonyAbility.CURL_TIME
			_show(colony, colony.reach() * 0.8, id, true)
	colony.energy -= cost
	colony.abilities.start(id, float(ColonyAbility.COOLDOWN[id]))
	return true


## Stuns every hunter and other colony within reach of the body's edge.
static func _sting(colony: Colony, eco: Ecosystem, others: Array) -> void:
	var c := colony.center()
	var center := Vector2(c.x, c.z)
	var reach := colony.reach() + ColonyAbility.sting_reach(colony.plan)
	if eco:
		for hunter in eco.predators:
			if is_instance_valid(hunter) and hunter.alive \
					and hunter.flat_pos().distance_to(center) <= reach + hunter.radius():
				hunter.stun_time = maxf(hunter.stun_time, ColonyAbility.STING_STUN)
	for item in others:
		var other := item as Colony
		if other == null or other == colony or not is_instance_valid(other):
			continue
		var oc := other.center()
		if Vector2(oc.x, oc.z).distance_to(center) <= reach + other.reach():
			other.stun_time = maxf(other.stun_time, ColonyAbility.STING_STUN)
	_show(colony, reach, "sting", false)


static func _show(colony: Colony, reach: float, id: String, glow: bool) -> void:
	var host := colony.get_parent()
	if host == null:
		return
	var marker := Node3D.new()
	host.add_child(marker)
	marker.global_position = colony.center()
	var color: Color = ColonyAbility.COLORS[id]
	if glow:
		AbilityFx.glow(marker, reach, color)
	else:
		AbilityFx.ring(marker, reach, color)
	marker.queue_free()
