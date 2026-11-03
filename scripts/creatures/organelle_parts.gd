class_name OrganelleParts
extends RefCounted
## Builders for the organelles (see Feature) and the inner trait parts that
## show on a cell: each one has its own shape and colour so upgrades can be
## told apart at a glance. The cell's front is +z and its top is +y.

## Colours shared with the upgrade card icons (UpgradeIcon).
const COLORS := {
	"grabbing_cilia": Color(0.55, 1.0, 0.85),
	"tail_bud": Color(0.7, 0.9, 1.0),
	"fat_store": Color(1.0, 0.8, 0.3),
	"gut_lining": Color(1.0, 0.5, 0.65),
	"eye_cluster": Color(0.15, 0.1, 0.3),
	"jet": Color(1.0, 0.55, 0.15),
	"sticky_coat": Color(0.85, 0.95, 0.3),
	"food_scent": Color(0.4, 0.95, 1.0),
	"toxin": Color(0.75, 0.3, 1.0),
	"efficiency": Color(1.0, 0.6, 0.35),
	"chloroplasts": EnergyOrganelles.CHLOROPLAST,
	"vent_symbionts": EnergyOrganelles.SYMBIONT,
	"trichocysts": Color(0.95, 0.95, 1.0),
	"toxicysts": Color(0.85, 0.35, 1.0),
	"flash": Color(0.4, 1.0, 0.95),
}


## Adds every organelle and inner part the genome has to the cell. Inner
## parts go on `body` so they wobble with it; outer parts go on `root`.
static func add_all(root: Node3D, body: Node3D, genome: Genome) -> void:
	_add(root, grabbers(genome.feature("grabbing_cilia")))
	_add(root, eye_cluster(genome.feature("eye_cluster")))
	_add(root, jet_nozzle(genome.feature("jet")))
	_add(root, sticky_coat(genome.feature("sticky_coat")))
	_add(root, antennae(genome.feature("food_scent")))
	_add(body, gut_lining(genome.feature("gut_lining")))
	_add(body, fat_drops(genome.feature("fat_store")))
	_add(body, vesicles(roundi(genome.value_of("toxin") * 8.0)))
	_add(body, mitochondria(roundi(genome.efficiency * 6.0)))
	EnergyOrganelles.add_all(body, genome)
	AbilityParts.add_all(root, body, genome)


static func _add(parent: Node3D, part: Node3D) -> void:
	if part.get_child_count() > 0:
		parent.add_child(part)
	else:
		part.free()


## Grabbing cilia: long arms reaching forward with sticky knobs on the tips.
static func grabbers(level: int) -> Node3D:
	var root := Node3D.new()
	for i in level * 2:
		var side := -1.0 if i % 2 == 0 else 1.0
		var spread := 0.5 + 0.35 * floorf(i / 2.0)
		var arm := Node3D.new()
		arm.position = Vector3(sin(spread) * side, 0.0, cos(spread)) * 0.95
		arm.rotation.y = spread * side
		var rod := VisualParts.cone(0.05, 0.7, COLORS["grabbing_cilia"])
		rod.rotation.x = PI / 2.0
		rod.position.z = 0.35
		arm.add_child(rod)
		var knob := VisualParts.sphere(0.09, COLORS["grabbing_cilia"], 0.8)
		knob.position.z = 0.72
		arm.add_child(knob)
		root.add_child(arm)
	return root


## Eye cluster: a ring of small extra eyes around the main eye.
static func eye_cluster(level: int) -> Node3D:
	var root := Node3D.new()
	var spots := [Vector3(-0.32, 0.5, 0.62), Vector3(0.32, 0.5, 0.62),
		Vector3(-0.5, 0.45, 0.4), Vector3(0.5, 0.45, 0.4)]
	for i in level * 2:
		var e := VisualParts.sphere(0.13, COLORS["eye_cluster"], 0.0)
		e.position = spots[i]
		root.add_child(e)
		var shine := VisualParts.sphere(0.04, Color.WHITE, 1.0)
		shine.position = spots[i] + Vector3(0.03, 0.11, 0.03)
		root.add_child(shine)
	return root


## Jet: a glowing orange nozzle ring at the back. Every cell has a small
## one; Contractile jet levels widen it.
static func jet_nozzle(level: int) -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.14 + 0.07 * level
	ring.outer_radius = ring.inner_radius + 0.1
	var mesh := MeshInstance3D.new()
	mesh.mesh = ring
	mesh.material_override = VisualParts.material(COLORS["jet"], 1.2)
	# Lies flat around the tail's base so it reads as a ring from above.
	mesh.position = Vector3(0.0, 0.1, -0.95)
	root.add_child(mesh)
	return root


## Sticky coat: a see-through slime shell with a few droplets on it.
static func sticky_coat(level: int) -> Node3D:
	var root := Node3D.new()
	if level <= 0:
		return root
	var c: Color = COLORS["sticky_coat"]
	var shell := VisualParts.sphere(1.12 + 0.1 * level, Color(c.r, c.g, c.b, 0.22), 0.3, true)
	shell.scale.y = 0.75
	root.add_child(shell)
	for i in 4 * level:
		var angle := TAU * (i + 0.3) / (4.0 * level)
		var drop := VisualParts.sphere(0.08, c, 0.6)
		drop.position = Vector3(sin(angle), 0.45, cos(angle)) * (1.0 + 0.1 * level)
		root.add_child(drop)
	return root


## Scent trail: two feelers on the front with glowing tips.
static func antennae(level: int) -> Node3D:
	var root := Node3D.new()
	if level <= 0:
		return root
	for side in [-1.0, 1.0]:
		var stalk := VisualParts.cone(0.04, 0.8, COLORS["food_scent"].darkened(0.3))
		stalk.position = Vector3(0.3 * side, 0.55, 0.95)
		stalk.rotation = Vector3(PI / 3.0, 0.0, -0.5 * side)
		root.add_child(stalk)
		var tip := VisualParts.sphere(0.08, COLORS["food_scent"], 1.2)
		tip.position = Vector3(0.5 * side, 0.75, 1.25)
		root.add_child(tip)
	return root


## Gut lining: pink folded rings around the middle, one more per level.
static func gut_lining(level: int) -> Node3D:
	var root := Node3D.new()
	for i in level:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.42 + 0.1 * i
		ring.outer_radius = ring.inner_radius + 0.06
		var mesh := MeshInstance3D.new()
		mesh.mesh = ring
		mesh.material_override = VisualParts.material(COLORS["gut_lining"], 0.5)
		mesh.position.y = -0.1
		root.add_child(mesh)
	return root


## Fat store: golden droplets inside the body, one per level.
static func fat_drops(level: int) -> Node3D:
	var root := Node3D.new()
	for i in level:
		var drop := VisualParts.sphere(0.18, COLORS["fat_store"], 0.5)
		drop.position = Vector3(-0.25 + 0.2 * i, 0.15, 0.25 - 0.1 * i)
		root.add_child(drop)
	return root


## Toxin: small glowing purple sacs spread through the body.
static func vesicles(count: int) -> Node3D:
	var root := Node3D.new()
	for i in count:
		var angle := TAU * i / maxf(count, 1.0) + 0.4
		var sac := VisualParts.sphere(0.1, COLORS["toxin"], 1.0)
		sac.position = Vector3(sin(angle) * 0.65, 0.3, cos(angle) * 0.65)
		root.add_child(sac)
	return root


## Leaner metabolism: orange bean-shaped mitochondria near the back.
static func mitochondria(count: int) -> Node3D:
	var root := Node3D.new()
	for i in count:
		var bean := CapsuleMesh.new()
		bean.radius = 0.07
		bean.height = 0.3
		var mesh := MeshInstance3D.new()
		mesh.mesh = bean
		mesh.material_override = VisualParts.material(COLORS["efficiency"], 0.6)
		mesh.position = Vector3(-0.4 + 0.16 * i, 0.2, -0.45 + 0.08 * (i % 2))
		mesh.rotation = Vector3(PI / 2.0, 0.6 * (1 if i % 2 == 0 else -1), 0.0)
		root.add_child(mesh)
	return root
