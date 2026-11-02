class_name CurrentStream
extends RefCounted
## One band of moving water following a winding path: a chain of points,
## `width` across, flowing from the first point to the last at `speed`
## units per second along its middle and fading out at its sides and ends.

## Flow speed tiers in world units per second (1 unit = 10 µm). The player
## starts at about 5.4, so a strong current is hard to swim against.
const WEAK := 0.7
const MEDIUM := 2.0
const STRONG := 4.5
const STEP := 3.0

var points := PackedVector2Array()
## Distance along the path to each point.
var marks := PackedFloat32Array()
var width := 6.0
var speed := WEAK
var _box := Rect2()


## A path that starts at `from` heading along `angle` and bends in slow,
## changing S-curves, like water finding its way around.
static func wind(from: Vector2, angle: float, total: float, band: float, flow: float,
		rng: RandomNumberGenerator) -> CurrentStream:
	var s := CurrentStream.new()
	s.width = band
	s.speed = flow
	var bend := rng.randf_range(0.025, 0.06)
	var wave := rng.randf_range(0.04, 0.09)
	var phase := rng.randf() * TAU
	var p := from
	var steps := ceili(total / STEP)
	for i in steps + 1:
		s.points.append(p)
		var t := i * STEP
		angle += STEP * bend * (sin(t * wave + phase) + 0.5 * sin(t * wave * 2.3 + phase * 1.7))
		p += Vector2.from_angle(angle) * STEP
	s._measure()
	return s


func length() -> float:
	return marks[marks.size() - 1]


## 0 for the weakest tier up to 1 for the strongest, for visuals.
func strength() -> float:
	return clampf((speed - WEAK) / (STRONG - WEAK), 0.0, 1.0)


## The point this far along the path.
func position_at(along: float) -> Vector2:
	var i := _segment(along)
	var t := (along - marks[i]) / maxf(marks[i + 1] - marks[i], 0.001)
	return points[i].lerp(points[i + 1], clampf(t, 0.0, 1.0))


## The flow direction this far along the path.
func tangent_at(along: float) -> Vector2:
	var i := _segment(along)
	return (points[i + 1] - points[i]).normalized()


## The push this stream gives at a point, zero outside the band.
func flow_at(p: Vector2) -> Vector2:
	if not _box.has_point(p):
		return Vector2.ZERO
	var half := width * 0.5
	var best := half
	var best_along := -1.0
	var best_dir := Vector2.ZERO
	for i in points.size() - 1:
		var a := points[i]
		var seg := points[i + 1] - a
		var t := clampf((p - a).dot(seg) / seg.length_squared(), 0.0, 1.0)
		var d := p.distance_to(a + seg * t)
		if d < best:
			best = d
			best_along = marks[i] + seg.length() * t
			best_dir = seg.normalized()
	if best_along < 0.0:
		return Vector2.ZERO
	var side := 1.0 - smoothstep(half * 0.5, half, best)
	var ends := smoothstep(0.0, 5.0, best_along) * smoothstep(0.0, 5.0, length() - best_along)
	return best_dir * speed * side * ends


func _measure() -> void:
	marks.clear()
	var run := 0.0
	_box = Rect2(points[0], Vector2.ZERO)
	for i in points.size():
		if i > 0:
			run += points[i].distance_to(points[i - 1])
		marks.append(run)
		_box = _box.expand(points[i])
	_box = _box.grow(width)


func _segment(along: float) -> int:
	var i := 0
	while i < marks.size() - 2 and marks[i + 1] < along:
		i += 1
	return i
