class_name AnimalNeckLook
extends Node3D
## Where a stage 3 Animal's head sits and the thick neck holding it. A
## "front" head is the first segment, pushed out ahead by a neck; a
## "raised" head sits up on top of the front, a "low" one hangs under it
## near the ground and a "middle" one rises from the middle of the back.
## Away from the front the head is its own ball and the first segment is
## body. pose() gives the head's transform for the eyes, mouth and horns.

var _body: AnimalBody
var _ball: MeshInstance3D
var _parts: Array[MeshInstance3D] = []


func build(body: AnimalBody) -> void:
	_body = body
	if body.head_at != "front":
		_ball = AnimalParts.node(AnimalParts.ball(), AnimalSkinMaterial.make(body, body.color()),
			self)
	if body.neck > 0.0 or body.head_at != "front":
		var mat := AnimalSkinMaterial.make(body, body.color().darkened(0.08))
		for k in 3:
			var part: Mesh = AnimalParts.ball() if k == 1 else AnimalParts.rod()
			_parts.append(AnimalParts.node(part, mat, self))


func pose(animal: Animal, frames: Array[Transform3D]) -> Transform3D:
	var head := frames[0]
	var r := _body.radii[0]
	var n := _body.neck
	var fwd := animal.forward()
	var base := Vector3.ZERO
	match _body.head_at:
		"raised":
			head.origin = frames[0] * Vector3(0.0, 0.9, 0.3) + Vector3.UP * r * (0.6 + n * 1.8)
			base = frames[0] * Vector3(0.0, 0.6, 0.3)
		"low":
			var p := frames[0] * Vector3(0.0, -0.4, 0.9) + fwd * r * (0.7 + n * 1.6)
			p.y = maxf(p.y - r * n * 0.6, LandHeight.at(p.x, p.z) + r * 0.75)
			head.origin = p
			base = frames[0] * Vector3(0.0, -0.3, 0.7)
		"middle":
			var mid := frames[frames.size() / 2]
			head.origin = mid * Vector3(0.0, 0.9, 0.0) + Vector3.UP * r * (0.9 + n * 1.8) \
				+ fwd * r * 0.4
			base = mid * Vector3(0.0, 0.6, 0.0)
		_:
			if _parts.is_empty():
				return head
			base = frames[1] * Vector3(0.0, 0.3, 0.7)
	if _ball:
		_ball.transform = head
	if not _parts.is_empty():
		var top := head * Vector3(0.0, -0.2, -0.4)
		var bend := Vector3.UP if _body.head_at != "low" else -Vector3.UP
		var middle := (base + top) * 0.5 + bend * base.distance_to(top) * 0.12
		var width := r * 0.55
		_parts[0].transform = AnimalParts.span(base, middle, width)
		_parts[1].transform = Transform3D(Basis.from_scale(Vector3.ONE * width), middle)
		_parts[2].transform = AnimalParts.span(middle, top, width * 0.85)
	return head
