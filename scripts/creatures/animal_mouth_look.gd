class_name AnimalMouthLook
extends Node3D
## The mouth of a stage 3 Animal, on the front of its head: a dark smile,
## a two-part beak that opens, mandibles that snap side to side, a pair of
## tusks, a swaying trunk or a round sucker mouth ringed with teeth.

const TRUNK := 4

var _body: AnimalBody
var _parts: Array[MeshInstance3D] = []


func build(body: AnimalBody) -> void:
	_body = body
	var dark := AnimalParts.material(Color(0.12, 0.04, 0.05))
	var horn := AnimalParts.material(Color(0.9, 0.82, 0.55))
	var skin := AnimalParts.material(body.color().darkened(0.1))
	var lip := AnimalParts.material(body.color2().lightened(0.25))
	match body.mouth:
		"smile":
			_add(AnimalParts.ball(), dark)
		"beak", "mandibles", "tusks":
			for k in 2:
				_add(AnimalParts.cone(), horn)
		"trunk":
			for k in TRUNK:
				_add(AnimalParts.rod(), skin)
		"sucker":
			_add(AnimalParts.ball(), lip)
			_add(AnimalParts.ball(), dark)
			for k in 6:
				_add(AnimalParts.cone(), horn)


func update(animal: Animal, head: Transform3D) -> void:
	if _parts.is_empty():
		return
	var r := _body.radii[0]
	var fwd := animal.forward()
	var right := fwd.cross(Vector3.UP)
	var t := animal.time
	match _body.mouth:
		"smile":
			_parts[0].transform = head * Transform3D(
				Basis.from_scale(Vector3(0.42, 0.07, 0.12)), Vector3(0.0, -0.3, 0.9))
		"beak":
			var base := head * Vector3(0.0, -0.1, 0.75)
			var gape := 0.15 + 0.1 * maxf(sin(t * 2.0), 0.0)
			var upper := base + (fwd - Vector3.UP * 0.25).normalized() * r * 1.1
			_parts[0].transform = AnimalParts.span(base, upper, r * 0.38)
			_parts[1].transform = AnimalParts.span(base - Vector3.UP * r * 0.12,
				base + (fwd - Vector3.UP * (0.4 + gape)).normalized() * r * 0.8, r * 0.3)
		"mandibles":
			var snap := 0.35 + 0.3 * sin(t * 5.0)
			for k in 2:
				var side := -1.0 if k == 0 else 1.0
				var base := head * Vector3(side * 0.35, -0.35, 0.75)
				var tip := base + (fwd - right * side * (0.6 - snap)).normalized() * r * 0.9
				_parts[k].transform = AnimalParts.span(base, tip, r * 0.16)
		"tusks":
			for k in 2:
				var side := -1.0 if k == 0 else 1.0
				var base := head * Vector3(side * 0.3, -0.4, 0.7)
				var tip := base + (fwd * 0.8 - Vector3.UP * 0.7 + right * side * 0.25).normalized() * r * 1.3
				_parts[k].transform = AnimalParts.span(base, tip, r * 0.14)
		"trunk":
			var at := head * Vector3(0.0, -0.1, 0.95)
			var dir := fwd
			for k in TRUNK:
				var droop := 0.35 + 0.15 * sin(t * 2.0 + k * 0.8)
				dir = (dir - Vector3.UP * droop + right * sin(t * 1.3 + k) * 0.2).normalized()
				var next := at + dir * r * 0.5
				_parts[k].transform = AnimalParts.span(at, next, r * (0.22 - 0.035 * k))
				at = next
		"sucker":
			var centre := head * Vector3(0.0, -0.05, 0.95)
			_parts[0].transform = Transform3D(Basis(right * r * 0.45, Vector3.UP * r * 0.45,
				fwd * r * 0.15), centre)
			_parts[1].transform = Transform3D(Basis(right * r * 0.3, Vector3.UP * r * 0.3,
				fwd * r * 0.1), centre + fwd * r * 0.05)
			for k in 6:
				var a := TAU * k / 6.0
				var rim := centre + (right * cos(a) + Vector3.UP * sin(a)) * r * 0.32 + fwd * r * 0.08
				_parts[2 + k].transform = AnimalParts.span(rim, rim - (right * cos(a)
					+ Vector3.UP * sin(a)) * r * 0.14, r * 0.05)


func _add(mesh: Mesh, mat: Material) -> void:
	_parts.append(AnimalParts.node(mesh, mat, self))
