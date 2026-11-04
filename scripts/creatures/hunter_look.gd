class_name HunterLook
extends RefCounted
## The extra parts that make each hunter kind easy to tell apart (see
## HunterKind). Parts are in body units; the organism is scaled by radius.


## Heliozoan: long, fine axopods radiating all round like a sunburst.
static func axopods(tint: Color) -> Node3D:
	var root := Node3D.new()
	var count := 22
	for i in count:
		var angle := TAU * i / count
		var length := 1.3 if i % 2 == 0 else 0.9
		var ray := VisualParts.cone(0.035, length, tint.lightened(0.45))
		ray.position = Vector3(sin(angle), 0.0, cos(angle)) * (0.95 + length / 2.0)
		ray.rotation = Vector3(PI / 2.0, angle, 0.0)
		root.add_child(ray)
	PartBaker.bake(root)
	return root


## Dinoflagellate: a girdle groove round the middle and a whip flagellum
## trailing behind.
static func girdle(tint: Color) -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.92
	ring.outer_radius = 1.08
	var band := MeshInstance3D.new()
	band.mesh = ring
	band.material_override = VisualParts.material(tint.lightened(0.35), 0.5)
	root.add_child(band)
	var whip := VisualParts.cone(0.04, 1.4, tint.lightened(0.2))
	whip.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	whip.position = Vector3(0.25, 0.0, -1.5)
	root.add_child(whip)
	return root


## Stentor: a trumpet narrowing to a holdfast behind, a crown of cilia at
## the wide front, and a faint swirl showing how far its vortex reaches.
static func trumpet(tint: Color, vortex: float) -> Node3D:
	var root := Node3D.new()
	var stalk := VisualParts.cone(0.8, 1.8, tint.darkened(0.15))
	stalk.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	stalk.position = Vector3(0.0, 0.0, -1.3)
	root.add_child(stalk)
	var crown := VisualParts.cilia(28, tint)
	crown.position = Vector3(0.0, 0.25, 0.1)
	crown.scale = Vector3.ONE * 1.15
	root.add_child(crown)
	PartBaker.bake(root)
	var disc := CylinderMesh.new()
	disc.top_radius = vortex
	disc.bottom_radius = vortex
	disc.height = 0.02
	var swirl := MeshInstance3D.new()
	swirl.mesh = disc
	swirl.material_override = VisualParts.material(Color(tint.r, tint.g, tint.b, 0.07), 0.2, true)
	swirl.position = Vector3(0.0, -0.6, 0.0)
	root.add_child(swirl)
	return root
