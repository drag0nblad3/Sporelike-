class_name SpeciesCell
extends Organism
## An AI cell, of the player's species or a rival's. Its body sets its
## habits (ForageStyle): it flees hunters inside its flee range, otherwise
## swims to the most worthwhile food it can see and likes, otherwise basks
## over light or vents if it can make energy there, otherwise heads for a
## nearby patch of food that suits it (or, with Chemoreceptors, straight
## for the nearest one).

const FORAGE_GIVE_UP := 12.0
## Seconds between food searches; steering toward the chosen food happens
## every frame. Keeps a big population cheap on phones.
const SEARCH_INTERVAL := 0.25
## Seconds between rereading the body into a ForageStyle (picks change it).
const STYLE_INTERVAL := 5.0

var ecosystem: Ecosystem
var style: ForageStyle

var _forage_target := Vector2.ZERO
var _forage_timer := 0.0
var _food: FoodItem
var _search_timer := randf() * SEARCH_INTERVAL
var _style_timer := 0.0


func think(delta: float) -> void:
	_style_timer -= delta
	if _style_timer <= 0.0 or style == null:
		_style_timer = STYLE_INTERVAL
		style = ForageStyle.of(genome)
	var me := flat_pos()

	var threat := ecosystem.nearest_predator(me, style.flee_range)
	if threat and threat.wants(self):
		_steer((me - threat.flat_pos()).normalized(), delta * 2.0)
		if me.distance_to(threat.flat_pos()) < threat.radius() + radius() + 2.0:
			try_boost()
		return

	_search_timer -= delta
	if _search_timer <= 0.0 or not _food_still_there():
		_search_timer = SEARCH_INTERVAL
		_food = ecosystem.food.best_for(self, style.appeal)
	if _food_still_there():
		_steer((_food.flat_pos() - me).normalized(), delta)
		return

	if style.basks and ambient_rate > 0.0 and energy < genome.max_energy():
		_steer(wander_input(delta), delta)
		return

	_forage_timer -= delta
	if _forage_timer <= 0.0 or me.distance_to(_forage_target) < 2.0:
		_pick_forage_target(me)
	_steer((_forage_target - me).normalized() * style.cruise, delta)


## Turns the swimming direction toward want at this body's steering pace:
## agile cells dart, big sluggish ones swing round slowly.
func _steer(want: Vector2, delta: float) -> void:
	move_input = move_input.lerp(want, minf(style.steer * delta, 1.0))


func _pick_forage_target(me: Vector2) -> void:
	_forage_timer = FORAGE_GIVE_UP
	var patch: FoodPatch = null
	if genome.feature("food_scent") > 0:
		patch = FoodScent.nearest(ecosystem.food.patches, genome, me)
	if patch == null:
		patch = style.pick_patch(ecosystem.food.patches, me, ecosystem.rng)
	_forage_target = patch.random_point(ecosystem.rng) if patch else Vector2.ZERO


func _food_still_there() -> bool:
	return is_instance_valid(_food) and not _food.is_queued_for_deletion()
