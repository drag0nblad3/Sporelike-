class_name AnimalLook
extends Node3D
## How a stage 3 Animal looks: a rounded body per segment (striped bodies
## alternate a darker shade), eyes on the head, and legs as two rods each
## with a foot, all simple meshes posed every frame. A legless body wriggles
## from side to side as it slithers.

const WIGGLE := 0.3

var _segments: Array[MeshInstance3D] = []
var _eyes: Array[MeshInstance3D] = []
var _bones: Array[MeshInstance3D] = []
var _feet: Array[MeshInstance3D] = []


func build(body: AnimalBody) -> void:
	for child in get_children():
		child.queue_free()
	_segments.clear()
	_eyes.clear()
	_bones.clear()
	_feet.clear()
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 14
	ball.rings = 8
	var skin := _material(body.color())
	var dark := _material(body.color().darkened(0.35))
	for i in body.segments():
		var seg := MeshInstance3D.new()
		seg.mesh = ball
		seg.material_override = dark if body.striped and i % 2 == 1 else skin
		add_child(seg)
		_segments.append(seg)
	var white := _material(Color(0.95, 0.95, 0.9))
	var black := _material(Color(0.05, 0.05, 0.05))
	for e in body.eyes * 2:
		var eye := MeshInstance3D.new()
		eye.mesh = ball
		eye.material_override = white if e % 2 == 0 else black
		add_child(eye)
		_eyes.append(eye)
	var limb := _material(body.color().darkened(0.2))
	var thick := body.radii[0] * 0.16
	for k in body.pairs() * 2:
		for b in 2:
			var bone := BoneMesh.make(thick, limb)
			add_child(bone)
			_bones.append(bone)
		var foot := MeshInstance3D.new()
		foot.mesh = ball
		foot.material_override = limb
		add_child(foot)
		_feet.append(foot)


func update(animal: Animal) -> void:
	var body := animal.body
	if _segments.size() != body.segments():
		return
	var slither := body.pairs() == 0
	for i in body.segments():
		var r := body.radii[i]
		var fwd := animal.segment_forward(i)
		var side := fwd.cross(Vector3.UP)
		var at := animal.spine[i]
		if slither:
			var moving := clampf(animal.speed_now / 2.0, 0.0, 1.0)
			at += side * sin(animal.time * 9.0 - i * 1.1) * WIGGLE * moving * (0.3 + i * 0.15)
		var up := fwd.cross(side).normalized() * -1.0
		_segments[i].transform = Transform3D(Basis(-side * r, up * r * 0.85, fwd * r * 1.25), at)
	_pose_eyes(_segments[0].transform)
	for k in animal.legs.size():
		var joints := animal.legs[k].chain.joints
		BoneMesh.place(_bones[k * 2], joints[0], joints[1])
		BoneMesh.place(_bones[k * 2 + 1], joints[1], joints[2])
		var size := body.radii[0] * 0.2
		_feet[k].transform = Transform3D(Basis.from_scale(Vector3(size, size * 0.6, size * 1.3)),
			joints[2])


## Pairs of eyes across the front of the head, each a white ball with a pupil.
func _pose_eyes(head: Transform3D) -> void:
	for e in range(0, _eyes.size(), 2):
		var pair := e / 4
		var side := -1.0 if (e / 2) % 2 == 0 else 1.0
		var local := Vector3(side * (0.42 - pair * 0.08), 0.55 - pair * 0.28, 0.72 - pair * 0.18)
		var center := head * local
		var size := head.basis.get_scale().x * 0.22
		_eyes[e].transform = Transform3D(Basis.from_scale(Vector3.ONE * size), center)
		var look := (head.basis * Vector3(0.0, 0.0, 1.0)).normalized()
		_eyes[e + 1].transform = Transform3D(Basis.from_scale(Vector3.ONE * size * 0.55),
			center + look * size * 0.6)


func _material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.55
	return mat
