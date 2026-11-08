class_name AnimalArmLook
extends Node3D
## The extra arms of a stage 3 Animal: 1 or 2 pairs held up in front from
## the shoulders (the segment behind the head), never walked on, swaying as
## it moves. Each ends in a hand with fingers, an opening pincer or a long
## folded blade, by the AnimalBody's arm_tip.

var _body: AnimalBody
## Parts of arm k: upper arm, forearm, then its tip parts.
var _arms: Array = []
var _segment := 0


func build(body: AnimalBody) -> void:
	_body = body
	_segment = mini(1, body.segments() - 1)
	var skin := AnimalParts.material(body.color().darkened(0.15))
	var tip := AnimalParts.material(body.color2().darkened(0.25))
	for k in body.arm_pairs * 2:
		var parts: Array[MeshInstance3D] = []
		for j in 2:
			parts.append(AnimalParts.node(AnimalParts.rod(), skin, self))
		match body.arm_tip:
			"blade":
				parts.append(AnimalParts.node(AnimalParts.cone(), tip, self))
			"pincer":
				parts.append(AnimalParts.node(AnimalParts.ball(), skin, self))
				for j in 2:
					parts.append(AnimalParts.node(AnimalParts.cone(), tip, self))
			_:
				parts.append(AnimalParts.node(AnimalParts.ball(), skin, self))
				for j in 3:
					parts.append(AnimalParts.node(AnimalParts.rod(), tip, self))
		_arms.append(parts)


func update(animal: Animal, frames: Array[Transform3D]) -> void:
	if _arms.is_empty():
		return
	var frame := frames[_segment]
	var r := _body.radii[_segment]
	var length := maxf(_body.longest_leg(), r * 2.2) * 0.8
	var fwd := animal.segment_forward(_segment)
	for k in _arms.size():
		var pair := k / 2
		var side := -1.0 if k % 2 == 0 else 1.0
		var out := frame.basis.x.normalized() * side
		var shoulder := frame * Vector3(side * 0.8, 0.35 - 0.3 * pair, 0.6 - 0.7 * pair)
		var sway := sin(animal.time * 2.5 + pair * 1.7 + side) * 0.12
		var elbow := shoulder + out * length * 0.35 + fwd * length * 0.2 - Vector3.UP * length * 0.3
		var hand := elbow + fwd * length * 0.45 - out * length * 0.12 \
			+ Vector3.UP * length * (0.3 + sway)
		var parts: Array[MeshInstance3D] = []
		parts.assign(_arms[k])
		parts[0].transform = AnimalParts.span(shoulder, elbow, r * 0.12)
		parts[1].transform = AnimalParts.span(elbow, hand, r * 0.1)
		_pose_tip(parts, hand, fwd, out, length, r, animal.time + k)


func _pose_tip(parts: Array[MeshInstance3D], hand: Vector3, fwd: Vector3, out: Vector3,
		length: float, r: float, time: float) -> void:
	match _body.arm_tip:
		"blade":
			var tip := hand + (-fwd * 0.5 - Vector3.UP * 0.85).normalized() * length * 0.6
			parts[2].transform = AnimalParts.span(hand, tip, r * 0.12)
		"pincer":
			parts[2].transform = Transform3D(Basis.from_scale(Vector3.ONE * r * 0.2), hand)
			var open := 0.3 + 0.2 * sin(time * 3.0)
			for j in 2:
				var spread := out * open * (1.0 if j == 0 else -1.0)
				parts[3 + j].transform = AnimalParts.span(hand,
					hand + (fwd + spread).normalized() * length * 0.3, r * 0.1)
		_:
			parts[2].transform = Transform3D(Basis.from_scale(Vector3.ONE * r * 0.14), hand)
			for j in 3:
				var spread := out * (j - 1) * 0.5
				var tip := hand + (fwd + spread + Vector3.UP * 0.2).normalized() * length * 0.18
				parts[3 + j].transform = AnimalParts.span(hand, tip, r * 0.04)
