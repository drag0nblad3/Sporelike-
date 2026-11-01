class_name FoodPatch
extends RefCounted
## One blob-shaped stretch of sea floor where a single FoodKind grows,
## belonging to one world chunk. Its edge is a circle bent by a few random
## lobes. Tracks how many pieces it holds and when it regrows.
## A rare hidden patch draws no floor and its food is faint and hard to
## sense, but richer: it looks like empty sand until something finds it.

const LOBES := 3
const HIDDEN_VISIBILITY := 0.3
const HIDDEN_RICHNESS := 1.3
const OUTLINE_POINTS := 40

var kind: FoodKind
var center := Vector2.ZERO
## Average radius; the edge bulges in and out around it.
var radius := 5.0
var chunk := Vector2i.ZERO
## Pieces it holds when fully grown, and how many it holds now.
var target := 1
var count := 0
var regrow_timer := 0.0
var hidden := false

var _amplitudes := PackedFloat32Array()
var _phases := PackedFloat32Array()


static func make(food_kind: FoodKind, at: Vector2, r: float, in_chunk: Vector2i,
		rng: RandomNumberGenerator) -> FoodPatch:
	var patch := FoodPatch.new()
	patch.kind = food_kind
	patch.center = at
	patch.radius = r
	patch.chunk = in_chunk
	for _i in LOBES:
		patch._amplitudes.append(rng.randf_range(0.06, 0.22))
		patch._phases.append(rng.randf() * TAU)
	patch.target = maxi(roundi(PI * r * r * food_kind.density), 3)
	return patch


## Distance from the center to the edge in this direction.
func radius_at(angle: float) -> float:
	var bend := 1.0
	for i in _amplitudes.size():
		bend += _amplitudes[i] * sin((i + 2) * angle + _phases[i])
	return radius * maxf(bend, 0.4)


func contains(p: Vector2) -> bool:
	var offset := p - center
	return offset.length() <= radius_at(offset.angle())


## The edge as a closed loop of points, for drawing.
func outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in OUTLINE_POINTS:
		var angle := TAU * i / OUTLINE_POINTS
		points.append(center + Vector2.from_angle(angle) * radius_at(angle))
	return points


## A uniformly random point inside the blob.
func random_point(rng: RandomNumberGenerator) -> Vector2:
	var reach := radius * 1.7
	for _i in 12:
		var p := center + Vector2(rng.randf_range(-reach, reach), rng.randf_range(-reach, reach))
		if contains(p):
			return p
	return center


## Pulls a point that drifted out of the blob back to its edge.
func keep_inside(p: Vector2) -> Vector2:
	var offset := p - center
	var edge := radius_at(offset.angle())
	if offset.length() <= edge:
		return p
	return center + offset.normalized() * edge
