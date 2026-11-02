class_name EnergyOrganelles
extends RefCounted
## Parts for the organelles that make energy without eating: green
## chloroplast discs for photosynthesis and clusters of small yellow rod
## bacteria for vent chemosynthesis. Both sit inside the body.

const CHLOROPLAST := Color(0.25, 0.9, 0.3)
const SYMBIONT := Color(0.95, 0.85, 0.3)


static func add_all(body: Node3D, genome: Genome) -> void:
	var leaves := chloroplasts(genome.feature("chloroplasts"))
	var bugs := symbionts(genome.feature("vent_symbionts"))
	for part in [leaves, bugs]:
		if part.get_child_count() > 0:
			body.add_child(part)
		else:
			part.free()


## Flat green discs in a loose ring under the top of the cell, three more
## per level.
static func chloroplasts(level: int) -> Node3D:
	var root := Node3D.new()
	var count := level * 3
	for i in count:
		var angle := TAU * (i + 0.25) / maxf(count, 1.0)
		var disc := VisualParts.sphere(0.13, CHLOROPLAST, 0.7)
		disc.scale = Vector3(1.0, 0.35, 0.7)
		disc.position = Vector3(sin(angle) * 0.55, 0.4, cos(angle) * 0.55)
		disc.rotation.y = angle
		root.add_child(disc)
	return root


## Tight clumps of short glowing rods, one clump per level.
static func symbionts(level: int) -> Node3D:
	var root := Node3D.new()
	for clump in level:
		var at := Vector3(0.3 - 0.6 * clump, -0.05, -0.2 + 0.35 * clump)
		for i in 5:
			var rod := CapsuleMesh.new()
			rod.radius = 0.04
			rod.height = 0.18
			var mesh := MeshInstance3D.new()
			mesh.mesh = rod
			mesh.material_override = VisualParts.material(SYMBIONT, 0.9)
			mesh.position = at + Vector3(0.09 * cos(i * 1.3), 0.05 * (i % 2), 0.09 * sin(i * 1.3))
			mesh.rotation = Vector3(PI / 2.0, i * 0.7, 0.0)
			root.add_child(mesh)
	return root
