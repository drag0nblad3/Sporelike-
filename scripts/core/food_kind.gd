class_name FoodKind
extends RefCounted
## One type of food: where it grows, what it is worth, and what it takes to
## find, catch and digest it. Each kind rewards different traits, which is
## what splits a population into niches.

var id := ""
var color := Color.WHITE
var energy := 2.0
var is_plant := true
## Jaw trait needed to crack it.
var hardness := 0.0
## Fraction of the eater's sense range at which it can be noticed.
var visibility := 1.0
var drift_speed := 0.0
## Speed it darts away at when something comes close (0 = never).
var flee_speed := 0.0
var zone_min := 0.0
var zone_max := 30.0
var target_count := 10
var regrow_interval := 1.0
var size := 0.22


static func all() -> Array[FoodKind]:
	# Algae: plentiful in the sunlit outer shallows. Easy, low value.
	var algae := _make("algae", Color(0.45, 1.0, 0.4), 2.5, true, 14.0, 29.0, 45, 0.3)

	# Plankton: drifts and darts away. Rich, but needs speed or agility.
	var plankton := _make("plankton", Color(1.0, 0.9, 0.3), 3.5, false, 6.0, 24.0, 18, 0.9)
	plankton.drift_speed = 1.2
	plankton.flee_speed = 5.5

	# Shells: around the warm central vents. Very rich, needs a strong jaw.
	var shells := _make("shells", Color(0.75, 0.45, 1.0), 5.0, false, 0.0, 10.0, 14, 1.2)
	shells.hardness = 0.45
	shells.size = 0.3

	# Motes: faint glowing spores in the deep center. Only keen senses find them.
	var motes := _make("motes", Color(0.4, 0.75, 1.0, 0.6), 3.0, true, 0.0, 12.0, 16, 0.8)
	motes.visibility = 0.35

	var list: Array[FoodKind] = [algae, plankton, shells, motes]
	return list


static func _make(name: String, tint: Color, value: float, plant: bool,
		inner: float, outer: float, count: int, regrow: float) -> FoodKind:
	var k := FoodKind.new()
	k.id = name
	k.color = tint
	k.energy = value
	k.is_plant = plant
	k.zone_min = inner
	k.zone_max = outer
	k.target_count = count
	k.regrow_interval = regrow
	return k
