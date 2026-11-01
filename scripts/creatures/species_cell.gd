class_name SpeciesCell
extends Organism
## An AI member of the player's species. Flees predators it can sense,
## otherwise swims to the most worthwhile food it can find and digest,
## otherwise heads for one of the nearby food patches it knows about (or,
## with the Scent trail upgrade, straight for the nearest food that suits it).

const FORAGE_CHOICES := 3
const FORAGE_GIVE_UP := 12.0
## Seconds between food searches; steering toward the chosen food happens
## every frame. Keeps a big population cheap on phones.
const SEARCH_INTERVAL := 0.25

var ecosystem: Ecosystem

var _forage_target := Vector2.ZERO
var _forage_timer := 0.0
var _food: FoodItem
var _search_timer := randf() * SEARCH_INTERVAL


func think(delta: float) -> void:
	var me := flat_pos()

	var threat := ecosystem.nearest_predator(me, genome.sense_range())
	if threat and threat.wants(self):
		move_input = (me - threat.flat_pos()).normalized()
		if me.distance_to(threat.flat_pos()) < threat.radius() + radius() + 2.0:
			try_boost()
		return

	_search_timer -= delta
	if _search_timer <= 0.0 or not _food_still_there():
		_search_timer = SEARCH_INTERVAL
		_food = ecosystem.food.best_for(self)
	if _food_still_there():
		move_input = (_food.flat_pos() - me).normalized()
		return

	_forage_timer -= delta
	if _forage_timer <= 0.0 or me.distance_to(_forage_target) < 2.0:
		_pick_forage_target(me)
	move_input = (_forage_target - me).normalized() * 0.7


## Picks one of the few patches closest to here, so the species spreads
## between neighbouring patches instead of crossing the whole world.
func _pick_forage_target(me: Vector2) -> void:
	_forage_timer = FORAGE_GIVE_UP
	if genome.feature("food_scent") > 0:
		var scented := FoodScent.nearest(ecosystem.food.patches, genome, me)
		if scented:
			_forage_target = scented.random_point(ecosystem.rng)
			return
	var patches := ecosystem.food.patches.filter(func(p: FoodPatch) -> bool:
		return not p.hidden)
	patches.sort_custom(func(a: FoodPatch, b: FoodPatch) -> bool:
		return me.distance_to(a.center) < me.distance_to(b.center))
	var count := mini(FORAGE_CHOICES, patches.size())
	if count == 0:
		_forage_target = Vector2.ZERO
		return
	var patch: FoodPatch = patches[randi() % count]
	_forage_target = patch.random_point(ecosystem.rng)


func _food_still_there() -> bool:
	return is_instance_valid(_food) and not _food.is_queued_for_deletion()
