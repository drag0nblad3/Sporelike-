class_name ShoreLine
extends RefCounted
## Where the coast lies late in the multicellular stage, as a straight line
## on the flat sea: a point on the mean waterline and the way inland. The
## sea floor rises toward it as a sandy slope (rise), reaching the surface
## depth at the waterline, and the tide moves the waterline in and out.

## How far out from the waterline the floor starts to rise.
const SLOPE := 30.0
## How far the tide moves the waterline either way, and how long a cycle lasts.
const TIDE_RANGE := 5.0
const TIDE_PERIOD := 60.0
## The beach keeps rising this much per unit inland, past the waterline.
const BEACH_RISE := 0.08
const BEACH_TOP := 30.0

var origin := Vector2.ZERO
var inland := Vector2(0.0, -1.0)


func _init(at := Vector2.ZERO, toward := Vector2(0.0, -1.0)) -> void:
	origin = at
	inland = toward.normalized()


## Along the shore, perpendicular to inland.
func tangent() -> Vector2:
	return Vector2(-inland.y, inland.x)


func inland3() -> Vector3:
	return Vector3(inland.x, 0.0, inland.y)


## How far inland of the mean waterline a point is (negative out at sea).
func inland_of(p: Vector2) -> float:
	return (p - origin).dot(inland)


func along(p: Vector2) -> float:
	return (p - origin).dot(tangent())


## The point `s` along the shore and `d` inland of the mean waterline.
func point(s: float, d: float) -> Vector2:
	return origin + tangent() * s + inland * d


## Height of the sand above the open sea floor, `d` inland of the waterline.
static func rise(d: float) -> float:
	var surface := Depth.height(Depth.SURFACE)
	if d <= -SLOPE:
		return 0.0
	if d <= 0.0:
		return surface * (d + SLOPE) / SLOPE
	return surface + minf(d, BEACH_TOP) * BEACH_RISE


## How far inland the water reaches at `time` seconds into the tide.
static func waterline(time: float) -> float:
	return TIDE_RANGE * sin(TAU * time / TIDE_PERIOD)


func to_dict() -> Dictionary:
	return {"x": origin.x, "y": origin.y, "ix": inland.x, "iy": inland.y}


static func from_dict(data: Dictionary) -> ShoreLine:
	var at := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	var toward := Vector2(float(data.get("ix", 0.0)), float(data.get("iy", -1.0)))
	return ShoreLine.new(at, toward)
