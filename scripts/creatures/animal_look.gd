class_name AnimalLook
extends Node3D
## How a stage 3 Animal's body looks: a shaped body per segment, a colour
## pattern (stripes, spots or bands in its second colour) and parts on the
## back (spikes, a sail, plates). A legless body wriggles as it slithers.
## A smooth body is one AnimalSkinLook instead of a ball per segment. The
## neck and where the head sits (AnimalNeckLook), the head
## (AnimalHeadLook), limbs and tail (AnimalLimbLook) and arms
## (AnimalArmLook) are drawn by their own children from the segment
## transforms worked out here.

const WIGGLE := 0.3
const SPOTS := 3
const SPIKES := 3

## Each segment's transform this frame (scaled to its size and shape).
var frames: Array[Transform3D] = []
var _body: AnimalBody
var _segments: Array[MeshInstance3D] = []
## Pattern and back parts, each with the segment it rides on and where.
var _extras: Array[MeshInstance3D] = []
var _extra_segment := PackedInt32Array()
var _extra_local: Array[Transform3D] = []
var _head := AnimalHeadLook.new()
var _limbs := AnimalLimbLook.new()
var _arms := AnimalArmLook.new()
var _skin: AnimalSkinLook
var _neck := AnimalNeckLook.new()


func build(body: AnimalBody) -> void:
	for child in get_children():
		child.queue_free()
	_body = body
	_segments.clear()
	_extras.clear()
	_extra_segment.clear()
	_extra_local.clear()
	_skin = null
	frames.clear()
	var skin := AnimalParts.material(body.color())
	var second := AnimalParts.material(body.color2())
	var dark := AnimalParts.material(body.color().darkened(0.35))
	for i in body.segments():
		var striped := body.pattern == "stripes" and i % 2 == 1
		_segments.append(AnimalParts.node(AnimalParts.ball(), second if striped else skin, self))
		frames.append(Transform3D())
		_add_pattern(i, second)
		_add_top(i, second, dark)
	var first := 1 if body.neck > 0.0 and body.head_at == "front" else 0
	if body.smooth and body.segments() - first >= 1:
		for i in range(first, body.segments()):
			_segments[i].visible = false
		_skin = AnimalSkinLook.new()
		add_child(_skin)
		_skin.build(body, first)
	_neck = AnimalNeckLook.new()
	add_child(_neck)
	_neck.build(body)
	_head = AnimalHeadLook.new()
	add_child(_head)
	_head.build(body)
	_limbs = AnimalLimbLook.new()
	add_child(_limbs)
	_limbs.build(body)
	_arms = AnimalArmLook.new()
	add_child(_arms)
	_arms.build(body)


func update(animal: Animal) -> void:
	if _body == null or _segments.size() != _body.segments():
		return
	var slither := _body.pairs() == 0
	for i in _body.segments():
		var r := _body.radii[i]
		var s := _body.shape_scale(i) * r
		var fwd := animal.segment_forward(i)
		var side := fwd.cross(Vector3.UP)
		var at := animal.spine[i]
		if slither:
			var moving := clampf(animal.speed_now / 2.0, 0.0, 1.0)
			at += side * sin(animal.time * 9.0 - i * 1.1) * WIGGLE * moving * (0.3 + i * 0.15)
		frames[i] = Transform3D(Basis(-side * s.x, Vector3.UP * s.y, fwd * s.z), at)
		_segments[i].transform = frames[i]
	for k in _extras.size():
		_extras[k].transform = frames[_extra_segment[k]] * _extra_local[k]
	_head.update(animal, _neck.pose(animal, frames))
	_limbs.update(animal, frames)
	_arms.update(animal, frames)
	if _skin:
		_skin.update(frames)


## Spots or a band on segment i, in the unit space of its ball.
func _add_pattern(i: int, mat: Material) -> void:
	if _body.pattern == "spots":
		for k in SPOTS:
			var a := (k - 1) * 0.6
			var at := Vector3(sin(a) * 0.75, cos(a) * 0.62, 0.15 * (k - 1))
			_extra(i, AnimalParts.ball(), mat, Transform3D(Basis.from_scale(Vector3.ONE * 0.22), at))
	elif _body.pattern == "bands" and i > 0:
		_extra(i, AnimalParts.ball(), mat,
			Transform3D(Basis.from_scale(Vector3(1.04, 1.04, 0.22)), Vector3.ZERO))


func _add_top(i: int, light: Material, dark: Material) -> void:
	match _body.tops[i]:
		"spikes":
			for k in SPIKES:
				var z := (k - 1) * 0.5
				_extra(i, AnimalParts.cone(), dark,
					Transform3D(Basis.from_scale(Vector3(0.18, 0.7, 0.18)), Vector3(0.0, 1.15, z)))
		"sail":
			_extra(i, AnimalParts.ball(), light,
				Transform3D(Basis.from_scale(Vector3(0.06, 0.9, 0.95)), Vector3(0.0, 1.35, 0.0)))
		"plates":
			_extra(i, AnimalParts.ball(), dark,
				Transform3D(Basis.from_scale(Vector3(0.85, 0.35, 0.9)), Vector3(0.0, 0.78, 0.0)))


func _extra(i: int, mesh: Mesh, mat: Material, local: Transform3D) -> void:
	_extras.append(AnimalParts.node(mesh, mat, self))
	_extra_segment.append(i)
	_extra_local.append(local)
