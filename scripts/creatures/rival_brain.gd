class_name RivalBrain
extends RefCounted
## How a rival colony decides where to swim: away from a colony that can
## bite it, after one it can bite, toward seaweed buds or food fields, and
## otherwise drifting. Uses its Sting or Curl when something is biting it.

const SIGHT := 14.0
const FLEE_RANGE := 10.0
const FOOD_SIGHT := 18.0


static func think(rival: Colony, player: Colony, eco: Ecosystem, bed: SeaweedBed) -> void:
	var c := rival.center()
	var me := Vector2(c.x, c.z)
	rival.move_input = _choose(rival, me, player, eco, bed)
	if player and rival.stun_time <= 0.0:
		var pc := player.center()
		var gap := me.distance_to(Vector2(pc.x, pc.z)) - rival.reach() - player.reach()
		if gap < 1.0 and ColonyBites.can_bite(player, rival):
			if not ColonyCaster.fire(rival, "sting", eco, [player]):
				ColonyCaster.fire(rival, "curl", eco, [])


static func _choose(rival: Colony, me: Vector2, player: Colony, eco: Ecosystem,
		bed: SeaweedBed) -> Vector2:
	if player:
		var pc := player.center()
		var them := Vector2(pc.x, pc.z)
		var d := me.distance_to(them)
		if d < FLEE_RANGE + player.reach() and ColonyBites.can_bite(player, rival):
			return (me - them).normalized()
		if d < SIGHT + player.reach() and ColonyBites.can_bite(rival, player):
			return (player.cell_flat(player.nearest_cell(me)) - me).normalized()
	if bed and FeedingStyle.seaweed_factor(rival.plan.style) >= 1.0:
		var bud := bed.nearest_food(rival.center(), FOOD_SIGHT)
		if bud != Vector3.INF:
			return (Vector2(bud.x, bud.z) - me).normalized()
	var patch := eco.food.nearest_patch(me, FOOD_SIGHT)
	if patch != Vector2.INF and me.distance_to(patch) > 1.5:
		return (patch - me).normalized() * 0.8
	var t := Time.get_ticks_msec() * 0.0003 + float(rival.get_instance_id() % 97)
	return Vector2(cos(t), sin(t * 0.7)) * 0.5
