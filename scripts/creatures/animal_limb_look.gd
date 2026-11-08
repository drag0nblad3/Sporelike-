class_name AnimalLimbLook
extends Node3D
## The limbs and tail of a stage 3 Animal: every limb as a chain of rods
## along its IkChain (legs are thickest at the thigh, with round knees,
## and thicker for a mighty build; tentacles taper to a thin tip), a foot
## of the body's kind (pad, claw, spike or sucker) and a forked, clubbed
## or spiked tail.

var _body: AnimalBody
## Rod j of limb k is _rods[k * bones + j].
var _rods: Array[MeshInstance3D] = []
var _feet: Array[MeshInstance3D] = []
## Round joints between leg bones (index as _rods; slot 0 of each limb unused).
var _knees: Array[MeshInstance3D] = []
var _tail: Array[MeshInstance3D] = []
var _bones := 2


func build(body: AnimalBody) -> void:
	_body = body
	_bones = body.joints
	var limb := AnimalParts.material(body.color().darkened(0.2))
	var foot_mat := AnimalParts.material(body.color2().darkened(0.3))
	if body.foot == "sucker":
		foot_mat = AnimalParts.material(body.color2().lightened(0.3))
	for k in _limb_count(body):
		for j in _bones:
			_rods.append(AnimalParts.node(AnimalParts.rod(), limb, self))
			var joint: MeshInstance3D = null
			if j > 0 and body.limb == "leg":
				joint = AnimalParts.node(AnimalParts.ball(), limb, self)
			_knees.append(joint)
		var mesh: Mesh = AnimalParts.cone() if body.foot in ["claw", "spike"] else AnimalParts.ball()
		_feet.append(AnimalParts.node(mesh, foot_mat, self))
	match body.tail:
		"fork":
			for k in 2:
				_tail.append(AnimalParts.node(AnimalParts.cone(), limb, self))
		"club":
			_tail.append(AnimalParts.node(AnimalParts.rod(), limb, self))
			_tail.append(AnimalParts.node(AnimalParts.ball(), foot_mat, self))
		"spike":
			_tail.append(AnimalParts.node(AnimalParts.cone(), foot_mat, self))


func update(animal: Animal, _frames: Array[Transform3D]) -> void:
	var limbs := animal.legs.limbs
	if limbs.size() * _bones != _rods.size():
		return
	var bendy := _body.limb == "tentacle"
	for k in limbs.size():
		var i := animal.legs.segment[k]
		# Thicker for a mightier build, and for a lopsided body's bigger side.
		var thick := _body.radii[0] * 0.15 * _body.leg_build \
			* animal.legs.length[k] / _body.leg_lengths[i]
		var joints := limbs[k].chain.joints
		for j in _bones:
			var width := thick * (1.0 - 0.6 * j / _bones if bendy else 1.35 - 0.5 * j / _bones)
			_rods[k * _bones + j].transform = AnimalParts.span(joints[j], joints[j + 1], width)
		if not bendy:
			for j in range(1, _bones):
				_knees[k * _bones + j].transform = Transform3D(
					Basis.from_scale(Vector3.ONE * thick * (1.2 - 0.4 * j / _bones)), joints[j])
		var fwd := animal.segment_forward(i)
		_feet[k].transform = _foot(joints[_bones], fwd, thick * (0.6 if bendy else 1.3))
	_pose_tail(animal)


## Limbs the body grows: mirrored pairs, or a ring of 2n+1 per segment
## when radial (as AnimalLegs builds them).
func _limb_count(body: AnimalBody) -> int:
	if body.symmetry != "radial":
		return body.pairs() * 2
	var n := 0
	for count in body.leg_pairs:
		n += count * 2 + 1 if count > 0 else 0
	return n


func _foot(at: Vector3, fwd: Vector3, s: float) -> Transform3D:
	var right := fwd.cross(Vector3.UP)
	match _body.foot:
		"claw":
			return AnimalParts.span(at, at + fwd * s * 2.5, s * 0.5)
		"spike":
			return AnimalParts.span(at + Vector3.UP * s * 2.0, at - Vector3.UP * s * 0.2, s * 0.6)
		"sucker":
			return Transform3D(Basis(right * s * 1.5, Vector3.UP * s * 0.35, fwd * s * 1.5), at)
	return Transform3D(Basis(right * s, Vector3.UP * s * 0.55, fwd * s * 1.4), at)


func _pose_tail(animal: Animal) -> void:
	if _tail.is_empty():
		return
	var last := _body.segments() - 1
	var r := _body.radii[last]
	var dir := -animal.segment_forward(last)
	var right := dir.cross(Vector3.UP)
	var base := animal.spine[last] + dir * _body.half_length(last) * 0.85
	match _body.tail:
		"fork":
			for k in 2:
				var s := 1.0 if k == 0 else -1.0
				var tip := base + (dir + right * s * 0.5).normalized() * r * 1.6 + Vector3.UP * r * 0.3
				_tail[k].transform = AnimalParts.span(base, tip, r * 0.25)
		"club":
			var end := base + dir * r * 1.4
			_tail[0].transform = AnimalParts.span(base, end, r * 0.18)
			_tail[1].transform = Transform3D(Basis.from_scale(Vector3.ONE * r * 0.6), end + dir * r * 0.4)
		"spike":
			_tail[0].transform = AnimalParts.span(base, base + dir * r * 2.0, r * 0.4)
