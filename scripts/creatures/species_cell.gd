class_name SpeciesCell
extends Organism
## An AI member of the player's species. Flees predators it can sense,
## otherwise swims to the nearest food it can sense, otherwise wanders.

var ecosystem: Ecosystem


func think(delta: float) -> void:
	var me := flat_pos()
	var sense := genome.sense_range()

	var threat := ecosystem.nearest_predator(me, sense)
	if threat:
		move_input = (me - threat.flat_pos()).normalized()
		return

	var food := ecosystem.food.nearest(me, sense)
	if food:
		move_input = (Vector2(food.position.x, food.position.z) - me).normalized()
		return

	move_input = wander_input(delta)
