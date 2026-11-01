class_name ActivityZone
extends Node
## Keeps the simulation around the player. Species members standing on
## unloaded chunks go dormant until the player comes back; hunters that fall
## too far behind are moved back into range, as if new ones swam in.

const CHECK_INTERVAL := 0.5
const HUNTER_LEASH := 70.0

var ecosystem: Ecosystem
var streamer: ChunkStreamer

var _timer := 0.0


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = CHECK_INTERVAL
	for member in ecosystem.species:
		member.set_dormant(not streamer.is_loaded(member.flat_pos()))
	for hunter in ecosystem.predators:
		if hunter.flat_pos().distance_to(ecosystem.focus) > HUNTER_LEASH:
			var rng := ecosystem.rng
			var at := ecosystem.focus \
				+ Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(35.0, 50.0)
			hunter.position = Vector3(at.x, 0.0, at.y)
			hunter.velocity = Vector3.ZERO
