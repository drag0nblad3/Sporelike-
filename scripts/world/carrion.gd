class_name Carrion
extends Node3D
## The remains of a colony that was bitten to death: a heap of dead cells
## that sinks to the floor and can be eaten bit by bit. It shrinks as it is
## eaten and rots away after a while if nobody finishes it.

## Energy left per dead cell, and how much one mouthful takes.
const ENERGY_PER_CELL := 1.5
const MOUTHFUL := 2.0
const ROT_TIME := 40.0
const BITE_REACH := 1.0

var energy := 0.0
var center := Vector3.ZERO
var _full := 1.0
var _age := 0.0
var _wait := 0.0
var _spots := PackedVector3Array()
var _look: BeadStrip


func lay(at: Vector3, cells: int, rng: RandomNumberGenerator) -> void:
	center = Vector3(at.x, 0.0, at.z)
	energy = ENERGY_PER_CELL * cells
	_full = energy
	var count := clampi(roundi(cells * 0.5), 3, 14)
	_spots.append(center)
	for i in count - 1:
		_spots.append(center + Vector3(rng.randf_range(-1.2, 1.2), 0.0, rng.randf_range(-1.2, 1.2)))
	_look = BeadStrip.make(count, 0.45, 8)
	for i in count:
		_look.set_color(i, Color(0.75, 0.65, 0.55).lightened(rng.randf_range(-0.1, 0.1)))
	add_child(_look)
	_show()


func is_gone() -> bool:
	return energy <= 0.0 or _age >= ROT_TIME


## Takes a mouthful for each of the points touching the heap.
func bite(points: PackedVector3Array) -> float:
	if _wait > 0.0:
		return 0.0
	var gained := 0.0
	for point in points:
		if energy <= 0.0:
			break
		for spot in _spots:
			if Vector2(point.x - spot.x, point.z - spot.z).length() <= BITE_REACH:
				var take := minf(MOUTHFUL, energy)
				energy -= take
				gained += take
				break
	if gained > 0.0:
		_wait = 0.4
		_show()
	return gained


func _process(delta: float) -> void:
	_age += delta
	_wait = maxf(_wait - delta, 0.0)


func _show() -> void:
	var left := energy / _full
	for i in _spots.size():
		var size := 1.0 if float(i) / _spots.size() < left else 0.0
		_look.place(i, _spots[i], size, 0.6)
