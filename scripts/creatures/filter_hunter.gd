class_name FilterHunter
extends Predator
## A Stentor, the giant trumpet ciliate: drifts slowly while its crown of
## cilia beats a vortex that drags small cells toward its mouth. It feels
## the water rather than looking, so a Scintillons flash does not hide you
## from it; swim hard out of the swirl instead.

const VORTEX := 6.0
## Drag at the mouth, in units per second, fading to 0 at the vortex edge.
const PULL := 2.6

var _prey_cache: Array[Organism] = []
var _cache_timer := 0.0


func _ready() -> void:
	super._ready()
	add_child(HunterLook.trumpet(tint(), vortex_range() / radius()))


func vortex_range() -> float:
	return (VORTEX + radius()) * lineage.sight_factor()


func sight_range() -> float:
	return vortex_range()


func wants(prey: Organism) -> bool:
	return can_swallow(prey)


func think(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	move_input = wander_input(delta) * 0.6
	if cooldown <= 0.0:
		_draw_in(delta)


func _draw_in(delta: float) -> void:
	_cache_timer -= delta
	if _cache_timer <= 0.0:
		_cache_timer = 0.25
		_prey_cache = ecosystem.prey_list()
	var me := flat_pos()
	var reach := vortex_range()
	for prey in _prey_cache:
		if not is_instance_valid(prey) or not prey.alive or not wants(prey):
			continue
		var off := me - prey.flat_pos()
		var d := off.length()
		if d > reach or d < 0.05:
			continue
		var pull := off / d * PULL * (1.0 - d / reach) * delta
		prey.position += Vector3(pull.x, 0.0, pull.y)
