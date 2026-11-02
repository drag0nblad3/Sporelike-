class_name NicheLedger
extends RefCounted
## Who ate which kind of food this generation: the player's species (you
## and your AI members) against each rival species. Rivals read it to see
## which niches are crowded, and it keeps each rival's eating habits.

const YOURS := "yours"

## Group -> {food kind id: energy eaten}.
var energy := {}
## Rival species name -> its Habits this generation.
var habits := {}


func reset() -> void:
	energy = {}
	habits = {}


## Connected to FoodField.eaten.
func record(org: Organism, item: FoodItem, gained: float) -> void:
	var group := YOURS
	var rival := org as RivalCell
	if rival:
		group = rival.group_name
		habits_for(group).note_meal(org.genome, item, gained)
	var eaten: Dictionary = energy.get(group, {})
	eaten[item.kind.id] = float(eaten.get(item.kind.id, 0.0)) + gained
	energy[group] = eaten


func habits_for(group: String) -> Habits:
	if not habits.has(group):
		habits[group] = Habits.new()
	var h: Habits = habits[group]
	return h


## Food kind id -> 0..1: its share of what every other group ate.
func crowding(group: String) -> Dictionary:
	var sums := {}
	var total := 0.0
	for other in energy:
		if other == group:
			continue
		var eaten: Dictionary = energy[other]
		for id in eaten:
			var amount: float = eaten[id]
			sums[id] = float(sums.get(id, 0.0)) + amount
			total += amount
	if total > 0.0:
		for id in sums:
			sums[id] = float(sums[id]) / total
	return sums
