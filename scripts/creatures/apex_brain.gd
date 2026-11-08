class_name ApexBrain
extends RefCounted
## How the apex colony behaves: it prowls slowly around its home ground and
## hunts the player's colony on sight, following it between depths, but
## swims a little slower than full speed so a hurt player can get away.

## How far it notices the player, beyond both bodies' reach.
const SIGHT := 16.0
## Gives up the chase this far from home.
const LEASH := 45.0
const PROWL_SPEED := 0.35
const HUNT_SPEED := 0.75


static func think(apex: Colony, home: Vector2, player: Colony, eco: Ecosystem) -> void:
	var c := apex.center()
	var me := Vector2(c.x, c.z)
	var pc := player.center()
	var them := Vector2(pc.x, pc.z)
	var gap := me.distance_to(them) - apex.reach() - player.reach()
	if gap < SIGHT and them.distance_to(home) < LEASH:
		apex.layer = player.layer
		var aim := player.cell_flat(player.nearest_cell(me)) - me
		apex.move_input = aim.normalized() * HUNT_SPEED
		if gap < 1.0 and apex.stun_time <= 0.0 and Depth.level(apex.height, player.height):
			ColonyCaster.fire(apex, "sting", eco, [player])
		return
	apex.layer = Depth.FLOOR
	var to_home := home - me
	if to_home.length() > 10.0:
		apex.move_input = to_home.normalized() * PROWL_SPEED
	else:
		var t := Time.get_ticks_msec() * 0.0004
		apex.move_input = Vector2.from_angle(t + home.x).normalized() * PROWL_SPEED
