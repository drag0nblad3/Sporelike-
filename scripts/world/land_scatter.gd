class_name LandScatter
extends Node3D
## What grows and lies on the stage 3 land: boulders and low plants (moss
## cushions and stalks with a bud on top), placed on LandHeight and drawn
## as a few MultiMeshes so hundreds cost a handful of draw calls.

const ROCKS := 45
const STALKS := 260
const CUSHIONS := 140
const SPREAD := 75.0

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 11
	_add(_rock_mesh(), ROCKS, Color(0.5, 0.48, 0.45), 1.0, 3.2, 0.3)
	_add(_stalk_mesh(), STALKS, Color(0.38, 0.62, 0.3), 0.6, 1.6, -0.45)
	_add(_cushion_mesh(), CUSHIONS, Color(0.3, 0.52, 0.28), 0.8, 2.2, 0.1)


func _add(mesh: Mesh, count: int, tint: Color, low: float, high: float, sink: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	for i in count:
		var x := rng.randf_range(-SPREAD, SPREAD)
		var z := rng.randf_range(-SPREAD, SPREAD)
		if Vector2(x, z).length() < 4.0:
			x += 8.0
		var size := rng.randf_range(low, high)
		var squash := Vector3(size, size * rng.randf_range(0.6, 1.1), size * rng.randf_range(0.8, 1.2))
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(squash)
		var at := Vector3(x, LandHeight.at(x, z) - sink * size, z)
		mm.set_instance_transform(i, Transform3D(basis, at))
		mm.set_instance_color(i, tint.lightened(rng.randf_range(-0.1, 0.15)))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.9
	node.material_override = mat
	add_child(node)


func _rock_mesh() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 0.8
	m.radial_segments = 7
	m.rings = 4
	return m


func _stalk_mesh() -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.03
	m.bottom_radius = 0.08
	m.height = 1.0
	m.radial_segments = 5
	m.rings = 1
	return m


func _cushion_mesh() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.5
	m.height = 0.45
	m.radial_segments = 8
	m.rings = 3
	return m
