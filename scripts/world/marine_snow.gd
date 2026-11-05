class_name MarineSnow
extends Node3D
## Marine snow: flakes of dead plankton and mucus drifting down through the
## water around the colony. Thickest in the twilight deep and the
## upwelling coast, thin in the clear lagoon. Mouths take flakes they touch;
## a filter feeder's wide reach sweeps up the most. Flakes left behind or
## eaten drift in again somewhere nearby.

const SLOTS := 48
const FLAKE_ENERGY := 0.8
const NEAR := 4.0
const FAR := 28.0
const DROP := 36.0
## sea id -> share of slots holding a flake there.
const DENSITY := {"deep": 1.0, "upwelling": 0.75, "vents": 0.5, "shelf": 0.4, "lagoon": 0.2}

var rng := RandomNumberGenerator.new()
var _pos := PackedVector3Array()
var _drift := PackedVector3Array()
var _live := PackedByteArray()
var _look: BeadStrip
var _center := Vector3.ZERO


func _ready() -> void:
	_look = BeadStrip.make(SLOTS, 0.16, 6, Color(0.5, 0.5, 0.45))
	add_child(_look)
	for i in SLOTS:
		_look.set_color(i, Color(0.95, 0.95, 0.85, 0.9))
	_pos.resize(SLOTS)
	_drift.resize(SLOTS)
	_live.resize(SLOTS)


func scatter(center: Vector3) -> void:
	_center = center
	for i in SLOTS:
		_respawn(i, NEAR, FAR)


## Takes every flake within `reach` of the points. Returns their energy.
func eat(points: PackedVector3Array, reach: float) -> float:
	var gained := 0.0
	var r2 := reach * reach
	for i in SLOTS:
		if _live[i] == 0:
			continue
		for point in points:
			var d := Vector2(point.x - _pos[i].x, point.z - _pos[i].z)
			if d.length_squared() <= r2:
				gained += FLAKE_ENERGY
				_respawn(i, FAR * 0.6, FAR)
				break
	return gained


func follow(center: Vector3) -> void:
	_center = center


func _physics_process(delta: float) -> void:
	for i in SLOTS:
		_pos[i] += _drift[i] * delta
		if Vector2(_pos[i].x - _center.x, _pos[i].z - _center.z).length() > DROP:
			_respawn(i, FAR * 0.6, FAR)


func _process(_delta: float) -> void:
	if _look == null:
		return
	for i in SLOTS:
		_look.place(i, _pos[i], 1.0 if _live[i] == 1 else 0.0)


func _respawn(i: int, low: float, high: float) -> void:
	var spot := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(low, high)
	var at := Vector2(_center.x, _center.z) + spot
	var share := float(DENSITY.get(SeaMap.at(at).id, 0.4))
	_live[i] = 1 if rng.randf() < share else 0
	_pos[i] = Vector3(at.x, 0.6, at.y)
	_drift[i] = Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))
