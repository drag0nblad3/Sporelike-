class_name TeaserColony
extends Node3D
## A huge, ghostly cell colony drifting above the sea floor: a glimpse of
## the multicellular stage. A "sphere" is a hollow ball of cells (a few
## tinted like the specialised cells to come); a "chain" is a long filament
## that ripples. A ball wears one faint shared skin (CellSkin). Purely
## for looks: nothing can touch or eat it yet.

const CELL := Color(0.45, 0.95, 0.8)
const FLATTEN := 0.3
const SPECIAL := [Color(1.0, 0.8, 0.35), Color(0.75, 0.55, 1.0), Color(1.0, 0.5, 0.45)]

var shape := "sphere"
var _rng := RandomNumberGenerator.new()
var _multimesh: MultiMesh
var _points: Array[Vector3] = []
var _phase := 0.0
var _spin := 0.1


func _init(kind: String, seed_value: int) -> void:
	shape = kind
	_rng.seed = seed_value


func _ready() -> void:
	var count := 90 if shape == "sphere" else _rng.randi_range(18, 28)
	var cell := SphereMesh.new()
	cell.radial_segments = 10
	cell.rings = 5
	cell.radius = 1.4 if shape == "sphere" else 1.8
	cell.height = cell.radius * 2.0
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = cell
	_multimesh.instance_count = count
	var radius := _rng.randf_range(9.0, 13.0)
	for i in count:
		if shape == "sphere":
			# Squashed flat so the huge ball stays below the camera.
			_points.append(_fibonacci(i, count) * radius * Vector3(1.0, FLATTEN, 1.0))
		else:
			_points.append(Vector3((i - count * 0.5) * 3.2, 0.0, 0.0))
		var tint := CELL
		if _rng.randf() < 0.25:
			tint = SPECIAL[_rng.randi() % SPECIAL.size()]
		_multimesh.set_instance_color(i, Color(tint, 0.32))
	var view := MultiMeshInstance3D.new()
	view.multimesh = _multimesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.3, 0.3)
	view.material_override = mat
	add_child(view)
	if shape == "sphere":
		add_child(_skin(radius + cell.radius))
	_spin = _rng.randf_range(0.02, 0.06) * (1.0 if _rng.randf() < 0.5 else -1.0)
	rotation.y = _rng.randf() * TAU
	_phase = _rng.randf() * TAU
	_place()


func _process(delta: float) -> void:
	_phase += delta
	rotation.y += _spin * delta
	if shape == "chain":
		_place()
	else:
		# A ball only breathes in and out, so scale the node rather than
		# moving all 90 cells one by one every frame.
		scale = Vector3.ONE * (1.0 + 0.03 * sin(_phase * 0.5))


func _place() -> void:
	var breathe := 1.0 + 0.03 * sin(_phase * 0.5)
	for i in _points.size():
		var p := _points[i] * breathe
		if shape == "chain":
			p.z = 5.0 * sin(_phase * 0.5 + i * 0.35)
			p.y = 0.6 * sin(_phase * 0.4 + i * 0.3)
		_multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))


## One faint membrane round the whole ball, so it reads as one creature.
static func _skin(radius: float) -> MeshInstance3D:
	var ball := SphereMesh.new()
	ball.radius = radius
	ball.height = radius * 2.0
	ball.radial_segments = 32
	ball.rings = 12
	var skin := MeshInstance3D.new()
	skin.mesh = ball
	skin.scale = Vector3(1.0, FLATTEN, 1.0)
	skin.material_override = CellSkin.material(Color(CELL, 0.1), 0.3)
	return skin


## Evenly spread points on a unit sphere.
static func _fibonacci(i: int, count: int) -> Vector3:
	var y := 1.0 - (i + 0.5) * 2.0 / count
	var r := sqrt(1.0 - y * y)
	var angle := i * PI * (3.0 - sqrt(5.0))
	return Vector3(cos(angle) * r, y, sin(angle) * r)
