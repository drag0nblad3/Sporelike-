class_name AbilityParts
extends RefCounted
## Visible parts for the ability organelles (see Ability): Trichocysts as
## white spindles packed under the rim, Toxicysts as purple darts at the
## front, Scintillons as glowing cyan specks. Front is +z, top is +y.


static func add_all(root: Node3D, body: Node3D, genome: Genome) -> void:
	_add(body, spindles(genome.feature("trichocysts")))
	_add(root, darts(genome.feature("toxicysts")))
	_add(body, specks(genome.feature("flash")))


static func _add(parent: Node3D, part: Node3D) -> void:
	if part.get_child_count() > 0:
		parent.add_child(part)
	else:
		part.free()


## Trichocysts: little white spindles pointing outward all round the rim.
static func spindles(level: int) -> Node3D:
	var root := Node3D.new()
	var count := 8 * level
	for i in count:
		var angle := TAU * (i + 0.5) / maxf(count, 1.0)
		var rod := VisualParts.cone(0.05, 0.3, OrganelleParts.COLORS["trichocysts"])
		rod.position = Vector3(sin(angle), 0.2, cos(angle)) * 0.82
		rod.rotation = Vector3(PI / 2.0, angle, 0.0)
		root.add_child(rod)
	return root


## Toxicysts: purple darts bunched round the front, ready to fire.
static func darts(level: int) -> Node3D:
	var root := Node3D.new()
	for i in 2 * level:
		var side := -1.0 if i % 2 == 0 else 1.0
		var spread := 0.25 + 0.2 * floorf(i / 2.0)
		var dart := VisualParts.cone(0.04, 0.35, OrganelleParts.COLORS["toxicysts"])
		dart.position = Vector3(sin(spread) * side, 0.3, cos(spread)) * 0.95
		dart.rotation = Vector3(PI / 2.0, spread * side, 0.0)
		root.add_child(dart)
	return root


## Scintillons: small bright specks scattered through the body.
static func specks(level: int) -> Node3D:
	var root := Node3D.new()
	for i in 6 * level:
		var angle := i * 2.4
		var r := 0.3 + 0.08 * (i % 4)
		var speck := VisualParts.sphere(0.06, OrganelleParts.COLORS["flash"], 1.6)
		speck.position = Vector3(sin(angle) * r, 0.35, cos(angle) * r)
		root.add_child(speck)
	return root
