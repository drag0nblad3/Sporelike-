class_name FoodBob
extends RefCounted
## Bobs the food that stays put up and down for FoodField, one slice of the
## pieces per frame so each piece moves every SLICES frames. The bob is slow,
## so nobody sees the steps, and it saves a script call per piece per frame.
## Food that can move bobs itself in FoodItem._process.

const SLICES := 3

var _clock := 0.0
var _slice := 0


func tick(field: Node, delta: float) -> void:
	_clock += delta
	_slice = (_slice + 1) % SLICES
	for i in range(_slice, field.get_child_count(), SLICES):
		var item := field.get_child(i) as FoodItem
		if item and not item.can_move():
			item.bob(_clock)
