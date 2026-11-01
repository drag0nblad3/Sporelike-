class_name FoodKind
extends RefCounted
## One type of food: where it grows, what it is worth, and what it takes to
## find, catch and digest it. Each kind rewards different traits, which is
## what splits a population into niches.

var id := ""
var color := Color.WHITE
var energy := 2.0
var is_plant := true
## Jaw trait needed to crack it, from the easiest piece to the toughest.
var hardness_min := 0.0
var hardness_max := 0.0
## Fraction of the eater's sense range at which it can be noticed.
var visibility := 1.0
var drift_speed := 0.0
## Speed it darts away at when something comes close (0 = never).
var flee_speed := 0.0
## Where it grows: this many patches of the sea floor, each a circle with a
## radius between patch_min and patch_max, scattered around the world.
var patch_count := 4
var patch_min := 4.0
var patch_max := 8.0
var floor_color := Color(0.1, 0.3, 0.3)
var floor_glow := 0.0
var target_count := 10
var regrow_interval := 1.0
var size := 0.22


static func all() -> Array[FoodKind]:
	# Algae: big sunlit meadows. Plentiful, easy, low value.
	var algae := _make("algae", Color(0.45, 1.0, 0.4), 2.5, true, 120, 0.12)
	algae.hardness_max = 0.3
	_patches(algae, 7, 6.0, 11.0, Color(0.12, 0.38, 0.3))

	# Plankton: open-water clouds. Drifts and darts away; rich if caught.
	var plankton := _make("plankton", Color(1.0, 0.9, 0.3), 3.5, false, 55, 0.35)
	plankton.drift_speed = 1.2
	plankton.flee_speed = 5.5
	plankton.hardness_max = 0.1
	_patches(plankton, 5, 6.0, 10.0, Color(0.1, 0.25, 0.35))

	# Shells: beds around warm vents. Very rich, needs a strong jaw.
	var shells := _make("shells", Color(0.75, 0.45, 1.0), 5.0, false, 40, 0.45)
	shells.hardness_min = 0.3
	shells.hardness_max = 0.7
	shells.size = 0.3
	_patches(shells, 4, 3.0, 5.0, Color(0.45, 0.18, 0.08), 0.6)

	# Motes: faint spores in dark trenches. Only keen senses find them.
	var motes := _make("motes", Color(0.4, 0.75, 1.0, 0.6), 3.0, true, 45, 0.3)
	motes.visibility = 0.35
	_patches(motes, 4, 4.0, 7.0, Color(0.02, 0.06, 0.12))

	var list: Array[FoodKind] = [algae, plankton, shells, motes]
	return list


static func _make(name: String, tint: Color, value: float, plant: bool,
		count: int, regrow: float) -> FoodKind:
	var k := FoodKind.new()
	k.id = name
	k.color = tint
	k.energy = value
	k.is_plant = plant
	k.target_count = count
	k.regrow_interval = regrow
	return k


static func _patches(k: FoodKind, count: int, smallest: float, largest: float,
		ground: Color, glow: float = 0.0) -> void:
	k.patch_count = count
	k.patch_min = smallest
	k.patch_max = largest
	k.floor_color = ground
	k.floor_glow = glow
