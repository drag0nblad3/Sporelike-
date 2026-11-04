class_name AmbushHunter
extends Predator
## A heliozoan ("sun animalcule"): settles in a food field with its long
## axopods spread and waits. Sitting still, prey only notice it up close;
## when prey comes within its axopods' reach it lunges. Moves to another
## field after a long wait with no catch.

const STRIKE_RANGE := 4.0
const STRIKE_RECHARGE := 4.0
const RELOCATE_AFTER := 25.0
## Food fields further than this are ignored when picking a spot.
const SEARCH := 30.0

var _spot := Vector2.INF
var _waited := 0.0
var _strike_timer := 0.0


func _ready() -> void:
	super._ready()
	add_child(HunterLook.axopods(tint()))


func notice_scale() -> float:
	return 0.35 if velocity.length() < 1.0 and boost_time <= 0.0 else 1.0


func sight_range() -> float:
	return (STRIKE_RANGE + radius()) * lineage.sight_factor()


func try_bite(prey: Organism, rng: RandomNumberGenerator) -> void:
	_waited = 0.0
	super.try_bite(prey, rng)


func think(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	_strike_timer = maxf(_strike_timer - delta, 0.0)
	var prey: Organism = null
	if cooldown <= 0.0:
		prey = nearest_prey()
	if prey:
		move_input = (prey.flat_pos() - flat_pos()).normalized()
		if _strike_timer <= 0.0:
			start_jet()
			_strike_timer = STRIKE_RECHARGE
		return
	_waited += delta
	var me := flat_pos()
	if _spot == Vector2.INF or _waited > RELOCATE_AFTER or me.distance_to(_spot) > SEARCH * 1.5:
		_spot = _pick_spot(me)
		_waited = 0.0
	var to_spot := _spot - me
	move_input = to_spot.normalized() * 0.6 if to_spot.length() > 1.0 else Vector2.ZERO


## A random point in a random nearby food field, or somewhere close by.
func _pick_spot(me: Vector2) -> Vector2:
	var rng := ecosystem.rng
	var near: Array[FoodPatch] = []
	for patch in ecosystem.food.patches:
		if patch.center.distance_to(me) < SEARCH:
			near.append(patch)
	if near.is_empty():
		return me + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(5.0, 12.0)
	return near[rng.randi() % near.size()].random_point(rng)
