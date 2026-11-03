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
## Spacing of the lookup table that finds the segment at a distance along.
const BUCKET := 2.0

var points := PackedVector2Array()
## Distance along the path to each point.
var marks := PackedFloat32Array()
var width := 6.0
var speed := WEAK
var _box := Rect2()
## Per segment: unit direction and length, so flow_at does less work.
var _dirs := PackedVector2Array()
var _lens := PackedFloat32Array()
## First segment for each BUCKET of distance along the path.
var _buckets := PackedInt32Array()


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
	return _dirs[_segment(along)]


## The push this stream gives at a point, zero outside the band.
func flow_at(p: Vector2) -> Vector2:
	if not _box.has_point(p):
		return Vector2.ZERO
	var half := width * 0.5
	var best_sq := half * half
	var best_along := -1.0
	var best_dir := Vector2.ZERO
	for i in _dirs.size():
		var a := points[i]
		var dir := _dirs[i]
		var t := clampf((p - a).dot(dir), 0.0, _lens[i])
		var d_sq := p.distance_squared_to(a + dir * t)
		if d_sq < best_sq:
			best_sq = d_sq
			best_along = marks[i] + t
			best_dir = dir
	if best_along < 0.0:
		return Vector2.ZERO
	var side := 1.0 - smoothstep(half * 0.5, half, sqrt(best_sq))
	var ends := smoothstep(0.0, 5.0, best_along) * smoothstep(0.0, 5.0, length() - best_along)
	return best_dir * speed * side * ends


## The area this stream can push in.
func bounds() -> Rect2:
	return _box


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
	_dirs.clear()
	_lens.clear()
	for i in points.size() - 1:
		_dirs.append((points[i + 1] - points[i]).normalized())
		_lens.append(marks[i + 1] - marks[i])
	_buckets.clear()
	var seg := 0
	for b in ceili(run / BUCKET) + 1:
		while seg < marks.size() - 2 and marks[seg + 1] < b * BUCKET:
			seg += 1
		_buckets.append(seg)


func _segment(along: float) -> int:
	var i := _buckets[clampi(floori(along / BUCKET), 0, _buckets.size() - 1)]
	while i < marks.size() - 2 and marks[i + 1] < along:
		i += 1
	return i
