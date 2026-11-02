class_name VisualParts
extends RefCounted
## Builders for the body parts that show an organism's traits: spikes for
## armor, a tail for speed, cilia for agility, an eye for sense, mandibles
## for the cell mouth. Each returns a node to add to the organism's visual.


static func spikes(count: int, tint: Color) -> Node3D:
	var root := Node3D.new()
	for i in count:
		var angle := TAU * i / count
		var spike := cone(0.12, 0.45, tint.darkened(0.3))
		spike.position = Vector3(sin(angle), 0.0, cos(angle)) * 1.05
		spike.rotation = Vector3(PI / 2.0, angle, 0.0)
		root.add_child(spike)
	return root


## Returns the tail's pivot so the caller can wiggle it.
static func tail(length: float, tint: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(0.0, 0.0, -0.9)
	var rod := CylinderMesh.new()
	rod.top_radius = 0.04
	rod.bottom_radius = 0.08
	rod.height = length
	var mesh := MeshInstance3D.new()
	mesh.mesh = rod
	mesh.material_override = material(tint, 0.6)
	mesh.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	mesh.position = Vector3(0.0, 0.0, -length / 2.0)
	pivot.add_child(mesh)
	return pivot


## Short hairs around the rim; more hairs for more agility.
static func cilia(count: int, tint: Color) -> Node3D:
	var root := Node3D.new()
	for i in count:
		var angle := TAU * (i + 0.5) / count
		var hair := cone(0.03, 0.3, tint.lightened(0.3))
		hair.position = Vector3(sin(angle), -0.2, cos(angle)) * 1.0
		hair.rotation = Vector3(PI / 2.0, angle, 0.0)
		root.add_child(hair)
	return root


static func eye(size: float) -> MeshInstance3D:
	var e := sphere(size, Color(0.05, 0.05, 0.1), 0.0)
	e.position = Vector3(0.0, 0.35, 0.8)
	return e


## The cytostome (cell mouth) at the front: a dark opening ringed by stiff
## rods that crush food. A stronger mouth has a wider opening and more,
## longer rods.
static func mouth(strength: float) -> Node3D:
	var root := Node3D.new()
	var hole := sphere(lerpf(0.14, 0.26, strength), Color(0.08, 0.04, 0.06), 0.0)
	hole.scale = Vector3(1.0, 0.45, 0.6)
	hole.position = Vector3(0.0, 0.1, 0.95)
	root.add_child(hole)
	var rods := 4 + roundi(strength * 6.0)
	var length := lerpf(0.18, 0.4, strength)
	for i in rods:
		var angle := lerpf(-0.9, 0.9, float(i) / maxf(rods - 1, 1))
		var rod := cone(0.035, length, Color(0.95, 0.9, 0.75))
		rod.position = Vector3(sin(angle) * 0.35, 0.1, 0.9 + cos(angle) * 0.05)
		# Rods point inward toward the opening, like a funnel.
		rod.rotation = Vector3(-PI / 2.0, angle * 0.6, 0.0)
		root.add_child(rod)
	return root


static func cone(base_radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = base_radius
	mesh.height = height
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material(color, 0.3)
	return inst


static func sphere(r: float, color: Color, glow: float, see_through := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material(color, glow, see_through)
	return inst


static func material(color: Color, glow: float, see_through := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if see_through:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b) * glow
	return mat
