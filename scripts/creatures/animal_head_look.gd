class_name AnimalHeadLook
extends Node3D
## The head of a stage 3 Animal: 2 to 6 eyes (on the head or up on stalks),
## horns, a pair of swaying feelers and one big pincer claw on one side,
## each only if the AnimalBody has it. Posed from the head segment's
## transform every frame.

var _body: AnimalBody
var _whites: Array[MeshInstance3D] = []
var _pupils: Array[MeshInstance3D] = []
var _stalks: Array[MeshInstance3D] = []
var _horns: Array[MeshInstance3D] = []
var _feelers: Array[MeshInstance3D] = []
var _claw: Array[MeshInstance3D] = []


func build(body: AnimalBody) -> void:
	_body = body
	var white := AnimalParts.material(Color(0.95, 0.95, 0.9))
	var black := AnimalParts.material(Color(0.05, 0.05, 0.05))
	var limb := AnimalParts.material(body.color().darkened(0.2))
	var horn := AnimalParts.material(Color(0.88, 0.84, 0.72))
	for e in body.eyes:
		_whites.append(AnimalParts.node(AnimalParts.ball(), white, self))
		_pupils.append(AnimalParts.node(AnimalParts.ball(), black, self))
		if body.eye_stalks:
			_stalks.append(AnimalParts.node(AnimalParts.rod(), limb, self))
	for k in body.horns:
		_horns.append(AnimalParts.node(AnimalParts.cone(), horn, self))
	if body.feelers:
		for k in 4:
			_feelers.append(AnimalParts.node(AnimalParts.rod(), limb, self))
	if body.claw_side != 0:
		for k in 2:
			_claw.append(AnimalParts.node(AnimalParts.rod(), limb, self))
		_claw.append(AnimalParts.node(AnimalParts.ball(), limb, self))
		for k in 2:
			_claw.append(AnimalParts.node(AnimalParts.cone(), horn, self))


func update(animal: Animal, head: Transform3D) -> void:
	var r := _body.radii[0]
	var fwd := animal.forward()
	var right := fwd.cross(Vector3.UP)
	for e in _whites.size():
		var pair := e / 2
		var side := -1.0 if e % 2 == 0 else 1.0
		var base := head * Vector3(side * (0.42 - pair * 0.08), 0.55 - pair * 0.28, 0.72 - pair * 0.18)
		var size := r * 0.22
		if _body.eye_stalks:
			var tip := base + Vector3.UP * r * 0.9 + fwd * r * 0.2 + right * side * r * 0.2 * pair
			_stalks[e].transform = AnimalParts.span(base, tip, r * 0.06)
			base = tip
			size = r * 0.26
		_whites[e].transform = Transform3D(Basis.from_scale(Vector3.ONE * size), base)
		_pupils[e].transform = Transform3D(Basis.from_scale(Vector3.ONE * size * 0.55),
			base + fwd * size * 0.6)
	for k in _horns.size():
		var side := 0.0 if _horns.size() == 1 else (-1.0 if k == 0 else 1.0)
		var base := head * Vector3(side * 0.35, 0.7, 0.55)
		var tip := base + (Vector3.UP * 0.8 + fwd * 0.6 + right * side * 0.3).normalized() * r * 1.2
		_horns[k].transform = AnimalParts.span(base, tip, r * 0.18)
	for k in range(0, _feelers.size(), 2):
		var side := -1.0 if k == 0 else 1.0
		var sway := sin(animal.time * 4.0 + side) * 0.3
		var base := head * Vector3(side * 0.25, 0.6, 0.85)
		var mid := base + (fwd * 0.8 + Vector3.UP * 0.6 + right * side * 0.3).normalized() * r * 1.2
		var tip := mid + (fwd + Vector3.UP * 0.1 + right * (side * 0.4 + sway)).normalized() * r * 1.3
		_feelers[k].transform = AnimalParts.span(base, mid, r * 0.04)
		_feelers[k + 1].transform = AnimalParts.span(mid, tip, r * 0.03)
	if not _claw.is_empty():
		_pose_claw(head, fwd, right, r, animal.time)


## Upper arm, forearm, palm and two pincer blades that open and close.
func _pose_claw(head: Transform3D, fwd: Vector3, right: Vector3, r: float, time: float) -> void:
	var side := float(_body.claw_side)
	var shoulder := head * Vector3(side * -0.8, -0.2, 0.3)
	var elbow := shoulder + right * side * r * 1.0 + fwd * r * 0.4 - Vector3.UP * r * 0.2
	var wrist := elbow + fwd * r * 1.3 + Vector3.UP * r * 0.2
	_claw[0].transform = AnimalParts.span(shoulder, elbow, r * 0.16)
	_claw[1].transform = AnimalParts.span(elbow, wrist, r * 0.2)
	_claw[2].transform = Transform3D(Basis.from_scale(Vector3(0.4, 0.3, 0.5) * r), wrist)
	var open := 0.25 + 0.2 * sin(time * 3.0)
	for k in 2:
		var spread := right * open * (1.0 if k == 0 else -1.0)
		var tip := wrist + (fwd + spread).normalized() * r * 1.1
		_claw[3 + k].transform = AnimalParts.span(wrist, tip, r * 0.22)
