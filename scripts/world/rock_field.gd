class_name RockField
extends Node3D
## Rock outcrops scattered around the colony, replanted ahead as it swims
## like the seaweed. Colonies bump against them; hunters lose sight of a
## colony pressed against a rock; vent chimneys warm the water around them,
## feeding any colony close by on vent chemistry.

const COUNT := 8
const NEAR := 8.0
const FAR := 32.0
const DROP := 46.0
const CONTACT_GAP := 1.0
## Energy per second a colony gets with any cell this close to a chimney.
const CHIMNEY_HEAT := 0.3
const CHIMNEY_RANGE := 3.5
## Hunters see a sheltering colony only from this share of their range.
const SHELTER_SIGHT := 0.4

var rocks: Array[Rock] = []
var rng := RandomNumberGenerator.new()


func scatter(center: Vector3) -> void:
	for rock in rocks:
		rock.queue_free()
	rocks.clear()
	for i in COUNT:
		rocks.append(_place(center, NEAR, FAR))


func follow(center: Vector3) -> void:
	for k in rocks.size():
		if rocks[k].body.anchor.distance_to(center) > DROP:
			rocks[k].queue_free()
			rocks[k] = _place(center, FAR * 0.6, FAR)


## Pushes the colony out of any rock it overlaps.
func push_out(colony: Colony) -> void:
	for rock in rocks:
		SoftContact.separate(colony.body, rock.body, CONTACT_GAP)


func sheltered(colony: Colony) -> bool:
	for rock in rocks:
		if rock.touches(colony.body, CONTACT_GAP * 1.4):
			return true
	return false


## Energy per second the colony is getting from nearby vent chimneys.
func heat(colony: Colony) -> float:
	for rock in rocks:
		if rock.chimney and rock.touches(colony.body, CHIMNEY_RANGE):
			return CHIMNEY_HEAT
	return 0.0


func _place(center: Vector3, low: float, high: float) -> Rock:
	var spot := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(low, high)
	var at := Vector2(center.x, center.z) + spot
	var rock := Rock.new()
	rock.build(Vector3(at.x, 0.0, at.y), SeaBlend.mixed(at).id, rng)
	add_child(rock)
	return rock
