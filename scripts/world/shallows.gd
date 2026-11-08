class_name Shallows
extends Node3D
## The shallows the colony reaches late in the multicellular stage: a coast
## (ShoreLine) whose sea floor rises into a beach, a tide that moves the
## waterline in and out, and TidePools to feed and hide in. Colonies are
## lifted by the rising floor and held back at the waterline, except a
## colony hauling itself out at the end of the stage.

## Cells a colony needs before the shallows appear ahead of it.
const APPEAR_AT := 40
## How far ahead of the colony the waterline is placed.
const DISTANCE := 40.0
## How far out from the waterline counts as reaching the shallows.
const REACHED := 12.0
## How far out to sea a colony is put back when it plays on.
const OFFSHORE := 8.0

var active := false
var line: ShoreLine
var _time := 0.0
var _focus := Vector2.ZERO
var _look := ShoreLook.new()
var _pools := TidePools.new()


func _ready() -> void:
	add_child(_look)
	add_child(_pools)
	_show()


## Puts the coast `DISTANCE` ahead of `at`, toward `toward`.
func place(at: Vector2, toward := Vector2(0.0, -1.0)) -> void:
	line = ShoreLine.new(at + toward.normalized() * DISTANCE, toward)
	active = true
	_show()


func load_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	line = ShoreLine.from_dict(data)
	active = true
	_show()


func to_dict() -> Dictionary:
	return line.to_dict() if active else {}


## How far inland the water reaches right now.
func waterline() -> float:
	return ShoreLine.waterline(_time)


func reached(colony: Colony) -> bool:
	return active and line.inland_of(_flat(colony.center())) > -REACHED


func sheltered(colony: Colony) -> bool:
	return active and _pools.pool_at(_flat(colony.center())) >= 0


## A spot in the water off the shore near `p` (or `p` itself if it is).
func water_spot(p: Vector2) -> Vector2:
	if not active:
		return p
	var d := line.inland_of(p)
	return p if d < -OFFSHORE else p - line.inland * (d + OFFSHORE)


## Called every physics frame: lifts colonies over the rising floor, holds
## them in the water and feeds the player from tide pools. Returns the
## energy the player ate.
func step(player: Colony, others: Array, hauling: bool, delta: float) -> float:
	_time += delta
	_focus = _flat(player.center())
	if not active:
		return 0.0
	_lift(player)
	if not hauling:
		_hold_back(player.body)
	for item in others:
		if is_instance_valid(item):
			var other: Colony = item
			_lift(other)
			_hold_back(other.body)
	var k := _pools.pool_at(_focus)
	return _pools.eat(k, delta) if k >= 0 else 0.0


func _process(delta: float) -> void:
	if active:
		_look.follow(_focus, waterline())
		_pools.follow(_focus, delta)


func _show() -> void:
	if is_inside_tree():
		_look.show_line(line if active else null)
		_pools.show_line(line if active else null)


func _lift(colony: Colony) -> void:
	colony.floor_height = ShoreLine.rise(line.inland_of(_flat(colony.center())))


## Moves any point past the waterline (and not in a tide pool) back to it.
func _hold_back(body: SoftBody) -> void:
	var water := waterline()
	var back := line.inland3()
	for i in body.size():
		var p := _flat(body.pos[i])
		var over := line.inland_of(p) - water
		if over > 0.0 and _pools.pool_at(p) < 0:
			body.pos[i] -= back * over
			body.prev[i] -= back * over


static func _flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)
