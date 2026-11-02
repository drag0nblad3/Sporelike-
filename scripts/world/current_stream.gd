class_name CurrentStream
extends RefCounted
## One band of moving water: a straight stretch from `start` to `finish`,
## `width` across, flowing from start to finish at `speed` units per second
## along its middle and fading to nothing at its sides and ends.

## Flow speed tiers in world units per second (1 unit = 10 µm). The player
## starts at about 5.4, so a strong current is hard to swim against.
const WEAK := 0.7
const MEDIUM := 2.0
const STRONG := 4.5

var start := Vector2.ZERO
var finish := Vector2.ZERO
var width := 6.0
var speed := WEAK


static func make(from: Vector2, to: Vector2, band: float, flow: float) -> CurrentStream:
	var s := CurrentStream.new()
	s.start = from
	s.finish = to
	s.width = band
	s.speed = flow
	return s


func direction() -> Vector2:
	return (finish - start).normalized()


func length() -> float:
	return start.distance_to(finish)


## 0 for the weakest tier up to 1 for the strongest, for visuals.
func strength() -> float:
	return clampf((speed - WEAK) / (STRONG - WEAK), 0.0, 1.0)


## The push this stream gives at a point, zero outside the band.
func flow_at(p: Vector2) -> Vector2:
	var dir := direction()
	var along := (p - start).dot(dir)
	var total := length()
	if along < 0.0 or along > total:
		return Vector2.ZERO
	var across := absf((p - start).cross(dir))
	var half := width * 0.5
	if across > half:
		return Vector2.ZERO
	# Smooth falloff toward the sides and the last few units of each end.
	var side := 1.0 - smoothstep(half * 0.5, half, across)
	var ends := smoothstep(0.0, 4.0, along) * smoothstep(0.0, 4.0, total - along)
	return dir * speed * side * ends
