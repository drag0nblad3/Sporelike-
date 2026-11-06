class_name SeaBlend
extends RefCounted
## Soft borders between sea regions. SeaMap gives one sea per point with a
## sharp edge; this averages it over a disc around the point so colours,
## light and vent strength fade from one sea into the next across about
## two RADIUS. For things that are spawned (food kinds, plants, rocks)
## `mixed` instead jitters the lookup, so near a border both seas' kinds
## mingle and thin out gradually.

## Half the width of the fade between two seas, in world units.
const RADIUS := 30.0
## Sample spots per ring; two rings (half and full RADIUS) plus the centre.
const RING := 8

static var _offsets: PackedVector2Array


## A Sea holding the averaged look and strengths around this point. Its
## id and title are those of the sea right at the point.
static func at(p: Vector2) -> Sea:
	var here := SeaMap.at(p)
	var s := Sea.of(here.id)
	var water := Color(0, 0, 0)
	var ambient := Color(0, 0, 0)
	var sun := Color(0, 0, 0)
	var floor_color := Color(0, 0, 0)
	var energy := 0.0
	var light := 0.0
	var vents := 0.0
	var food := 0.0
	var offsets := _ring_offsets()
	for offset in offsets:
		var near := SeaMap.at(p + offset)
		water += near.water
		ambient += near.ambient
		sun += near.sun
		floor_color += near.floor_color
		energy += near.sun_energy
		light += near.light
		vents += near.vents
		food += near.food
	var n := float(offsets.size())
	s.water = water / n
	s.ambient = ambient / n
	s.sun = sun / n
	s.floor_color = floor_color / n
	s.sun_energy = energy / n
	s.light = light / n
	s.vents = vents / n
	s.food = food / n
	return s


## Only the averaged sea floor colour, for the many floor vertices.
static func floor_at(p: Vector2) -> Color:
	var sum := Color(0, 0, 0)
	var offsets := _ring_offsets()
	for offset in offsets:
		sum += SeaMap.at(p + offset).floor_color
	return sum / float(offsets.size())


## The sea at a spot near this point, picked the same way every time for
## the same point, so spawns near a border mix both seas.
static func mixed(p: Vector2) -> Sea:
	var h := hash(Vector2i(roundi(p.x * 8.0), roundi(p.y * 8.0)))
	var angle := float(h & 0xffff) / 65536.0 * TAU
	var reach := RADIUS * sqrt(float((h >> 16) & 0xffff) / 65536.0)
	return SeaMap.at(p + Vector2.from_angle(angle) * reach)


static func _ring_offsets() -> PackedVector2Array:
	if _offsets.is_empty():
		_offsets.append(Vector2.ZERO)
		for i in RING:
			var angle := TAU * i / RING
			_offsets.append(Vector2.from_angle(angle) * RADIUS * 0.5)
			_offsets.append(Vector2.from_angle(angle + PI / RING) * RADIUS)
	return _offsets
