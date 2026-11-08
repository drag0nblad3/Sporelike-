class_name AnimalCoverings
extends RefCounted
## Feathers and quills on a stage 3 animal's body, worked out in each
## segment's unit-ball space so AnimalLook can carry them on the segment
## like its other extras. "a few feathers" is a crest on the head and a fan
## at the tail; "full feathers" also covers the back of every segment in
## overlapping rows; "quills" bristle backward over the back.

const FEATHER_ROWS := 2
const AROUND := 5


## Each entry: [segment, "ball" or "cone", colour, transform in the ball's space].
static func parts(body: AnimalBody) -> Array:
	var out := []
	var last := body.segments() - 1
	var light := body.color2()
	var deep := body.color2().darkened(0.25)
	match body.covering:
		"a few feathers", "full feathers":
			for k in 3:
				var at := Vector3(0.0, 0.85, 0.2 - 0.3 * k)
				out.append([0, "ball", light, _feather(at, Vector3(0.0, 0.8, -0.6), 0.75)])
			for k in 5:
				var spread := (k - 2) * 0.35
				var dir := Vector3(sin(spread), 0.35, -cos(spread))
				out.append([last, "ball", light if k % 2 == 0 else deep,
					_feather(Vector3(0.0, 0.3, -0.85), dir, 1.3)])
			if body.covering == "full feathers":
				for i in range(1, body.segments()):
					_rows(out, i, light, deep)
		"quills":
			for i in range(1, body.segments()):
				for k in AROUND:
					var a := (k - 2) * 0.55
					var at := Vector3(sin(a) * 0.85, cos(a) * 0.85, 0.0)
					var dir := (at.normalized() * 0.6 + Vector3(0.0, 0.2, -0.8)).normalized()
					out.append([i, "cone", Color(0.92, 0.88, 0.78), _quill(at, dir)])
	return out


static func _rows(out: Array, i: int, light: Color, deep: Color) -> void:
	for row in FEATHER_ROWS:
		for k in AROUND:
			var a := (k - 2) * 0.6 + row * 0.3
			var at := Vector3(sin(a) * 0.9, cos(a) * 0.9, 0.45 - row * 0.6)
			var dir := (at.normalized() * 0.35 + Vector3(0.0, 0.0, -1.0)).normalized()
			out.append([i, "ball", light if (k + row) % 2 == 0 else deep, _feather(at, dir, 0.7)])


## A long flat oval from `at` along `dir`, lying flat against the body.
static func _feather(at: Vector3, dir: Vector3, length: float) -> Transform3D:
	var long := dir.normalized()
	var flat := at.normalized() if at.length() > 0.01 else Vector3.UP
	var across := flat.cross(long).normalized()
	flat = long.cross(across)
	var basis := Basis(across * 0.2, flat * 0.05, long * length * 0.5)
	return Transform3D(basis, at + long * length * 0.45)


## A thin cone from `at` along `dir` (the cone mesh runs along y).
static func _quill(at: Vector3, dir: Vector3) -> Transform3D:
	var y := dir.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.UP).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x * 0.07, y * 1.1, z * 0.07), at + y * 0.5)
