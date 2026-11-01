class_name SpeciesCell
extends Organism
## An AI member of the player's species. Flees predators it can sense,
## otherwise swims to the most worthwhile food it can find and digest,
## otherwise wanders.

var ecosystem: Ecosystem


func think(delta: float) -> void:
	var me := flat_pos()

	var threat := ecosystem.nearest_predator(me, genome.sense_range())
	if threat and threat.wants(self):
		move_input = (me - threat.flat_pos()).normalized()
		return

	var food := ecosystem.food.best_for(self)
	if food:
		move_input = (food.flat_pos() - me).normalized()
		return

	move_input = wander_input(delta)
