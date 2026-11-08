class_name BoneMesh
extends RefCounted
## Stretches a unit cylinder between two points, for legs and other limbs
## drawn as simple rods.


static func make(radius: float, material: Material) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 1.0
	cylinder.radial_segments = 6
	cylinder.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = cylinder
	node.material_override = material
	return node


static func place(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var along := b - a
	var length := along.length()
	if length < 0.001:
		node.visible = false
		return
	node.visible = true
	var y := along / length
	var side := Vector3.FORWARD if absf(y.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var x := y.cross(side).normalized()
	var z := x.cross(y)
	node.global_transform = Transform3D(Basis(x, y * length, z), (a + b) * 0.5)
