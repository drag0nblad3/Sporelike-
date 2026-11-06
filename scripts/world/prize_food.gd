class_name PrizeFood
extends RefCounted
## Rare glowing prize morsels: CHANCE of new food pieces is worth MULTIPLIER
## times the energy, glows gold so it is easy to spot, and darts away fast
## when anything comes near, so catching one takes a chase (or the Jet).

const CHANCE := 0.012
const MULTIPLIER := 5.0
const FLEE_SPEED := 6.5
const COLOUR := Color(1.0, 0.82, 0.25)

static var _material: StandardMaterial3D


static func roll(item: FoodItem, rng: RandomNumberGenerator) -> void:
	if rng.randf() >= CHANCE:
		return
	item.prize = true
	item.energy *= MULTIPLIER
	item.visibility = 1.0
	item.flee_speed = maxf(item.flee_speed, FLEE_SPEED)
	item.agility = 1.0
	item.enlarge(1.4)


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = COLOUR
		_material.emission_enabled = true
		_material.emission = COLOUR
		_material.emission_energy_multiplier = 2.5
	return _material
