class_name AnimalEyeLook
extends Node3D
## The eyes of a stage 3 Animal: 1 to 8 of them, facing ahead ("front"),
## set wide on the sides of the head ("wide") or up on the crown ("top"),
## either on the head or raised on stalks. An odd count puts one in the
## middle. A radial body has its eyes in a ring all round the head; a
## lopsided one has big eyes on the left and small ones on the right. Each
## pupil looks the way its eye faces.

var _body: AnimalBody
var _whites: Array[MeshInstance3D] = []
var _pupils: Array[MeshInstance3D] = []
var _stalks: Array[MeshInstance3D] = []
## Which way each eye faces in the head's own space (x right, y up, z ahead).
var _dirs: Array[Vector3] = []
var _sizes := PackedFloat32Array()


func build(body: AnimalBody) -> void:
	_body = body
	var white := AnimalParts.material(Color(0.95, 0.95, 0.9))
	var black := AnimalParts.material(Color(0.05, 0.05, 0.05))
	var stalk := AnimalParts.material(body.color().darkened(0.2))
	for e in body.eyes:
		_whites.append(AnimalParts.node(AnimalParts.ball(), white, self))
		_pupils.append(AnimalParts.node(AnimalParts.ball(), black, self))
		if body.eye_stalks:
			_stalks.append(AnimalParts.node(AnimalParts.rod(), stalk, self))
		_dirs.append(_facing(e))
		var big := 1.0
		if body.symmetry == "lopsided" and not (body.eyes % 2 == 1 and e == body.eyes - 1):
			big = 1.45 if e % 2 == 0 else 0.65
		_sizes.append(big)


func update(head: Transform3D) -> void:
	var r := _body.radii[0]
	var size := r * (0.24 if _body.eyes <= 2 else 0.19)
	for e in _whites.size():
		var dir := _dirs[e]
		var base := head * (dir * 0.88)
		var out := (head.basis * dir).normalized()
		var s := size * _sizes[e]
		if _body.eye_stalks:
			var tip := base + (out * 0.5 + Vector3.UP).normalized() * r * 0.9
			_stalks[e].transform = AnimalParts.span(base, tip, r * 0.06)
			base = tip
			s *= 1.15
		_whites[e].transform = Transform3D(Basis.from_scale(Vector3.ONE * s), base)
		_pupils[e].transform = Transform3D(Basis.from_scale(Vector3.ONE * s * 0.55),
			base + out * s * 0.6)


## The direction eye e faces: a yaw (away from straight ahead) and a pitch
## (up) on the head, by the body's eye layout.
func _facing(e: int) -> Vector3:
	if _body.symmetry == "radial" and _body.eyes > 1:
		var around := TAU * (e + 0.5) / _body.eyes
		return Vector3(sin(around) * cos(0.45), sin(0.45), cos(around) * cos(0.45))
	var odd := _body.eyes % 2 == 1
	var yaw := 0.0
	var pitch := 0.0
	if odd and e == _body.eyes - 1:
		pitch = {"front": 0.55, "wide": 0.8, "top": 1.35}.get(_body.eye_set, 0.55)
	else:
		var pair := e / 2
		var side := -1.0 if e % 2 == 0 else 1.0
		match _body.eye_set:
			"wide":
				yaw = side * (1.05 + 0.32 * pair)
				pitch = 0.35 - 0.06 * pair
			"top":
				yaw = side * (0.35 + 0.3 * (pair % 2))
				pitch = 1.0 - 0.28 * (pair / 2)
			_:
				yaw = side * (0.28 + 0.2 * (pair % 2))
				pitch = 0.32 - 0.34 * (pair / 2) + 0.08 * (pair % 2)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
