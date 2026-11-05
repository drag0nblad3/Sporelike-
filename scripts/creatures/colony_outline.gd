class_name ColonyOutline
extends RefCounted
## The edge of a colony's shared skin: a ring of points around all its
## cells. Each point rides on the outermost cell in its direction (worked
## out once from the resting shape), so the skin stretches, bends and
## wobbles with the soft body for a few dozen sums a frame.

## Points around the ring; ColonySkin's shader expects exactly this many.
const POINTS := 48
## How far past a cell's centre the skin reaches.
const MARGIN := 0.95

## The ring this frame, relative to the body's centre, flat (y = 0).
var ring := PackedVector3Array()
var _cell := PackedInt32Array()
var _offset := PackedVector3Array()


## Finds, for each direction from the centre, the cell that sticks out
## furthest that way and where the skin passes it.
func build(rest: PackedVector3Array) -> void:
	_cell.resize(POINTS)
	_offset.resize(POINTS)
	ring.resize(POINTS)
	for k in POINTS:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * k / POINTS)
		var best := -INF
		for i in rest.size():
			var p := Vector3(rest[i].x, 0.0, rest[i].z)
			var along := p.dot(dir)
			var gap := MARGIN * MARGIN - (p.length_squared() - along * along)
			# A cell the ray misses still counts, ranked by how near it is.
			var far := along + sqrt(gap) if gap >= 0.0 else along - 3.0 * sqrt(-gap)
			if far > best:
				best = far
				_cell[k] = i
				var edge := dir * far if gap >= 0.0 else p + dir * MARGIN
				_offset[k] = edge - p


## Moves the ring onto the cells where they are now, smooths it into a
## soft curve and lets it ripple gently.
func update(body: SoftBody, time: float) -> void:
	if body.size() == 0 or _cell.is_empty():
		return
	var center := body.center()
	for k in POINTS:
		var p := body.pos[_cell[k]] + _offset[k].rotated(Vector3.UP, body.angle) - center
		p.y = 0.0
		ring[k] = p
	for _pass in 2:
		var before := ring.duplicate()
		for k in POINTS:
			var prev := before[(k + POINTS - 1) % POINTS]
			var next := before[(k + 1) % POINTS]
			ring[k] = before[k] * 0.5 + (prev + next) * 0.25
	for k in POINTS:
		ring[k] *= 1.0 + 0.025 * sin(time * 2.2 + TAU * 3.0 * k / POINTS)
