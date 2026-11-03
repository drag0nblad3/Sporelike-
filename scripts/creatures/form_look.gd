class_name FormLook
extends Node3D
## The visible body form (see BodyForm): the stretch or flattening of the
## whole cell, plus the parts each form adds and animates: a corkscrew ridge
## that spins, pseudopods that flow in and out, shell chambers, a disc rim.

const SHELL := Color(0.86, 0.76, 0.56, 0.75)

var form := ""
var level := 0
var _parts: Array[Node3D] = []
var _time := 0.0


## Scale for the whole visual: rods and spirals stretch along the swim
## direction (+Z), discs spread wide.
static func shape_scale(g: Genome) -> Vector3:
	var id := BodyForm.of(g)
	var lv := float(g.feature(id))
	match id:
		"form_rod":
			return Vector3(0.72, 1.0, 1.3 + 0.15 * lv)
		"form_spiral":
			return Vector3(0.62, 1.0, 1.35 + 0.15 * lv)
		"form_disc":
			return Vector3(1.2 + 0.05 * lv, 0.6, 1.05)
	return Vector3.ONE


static func make(g: Genome, tint: Color) -> FormLook:
	var look := FormLook.new()
	look.form = BodyForm.of(g)
	look.level = g.feature(look.form) if look.form != "" else 0
	look._build(tint)
	return look


func _build(tint: Color) -> void:
	_time = randf() * 10.0
	match form:
		"form_spiral":
			_spiral(tint.darkened(0.35))
		"form_amoeboid":
			_pseudopods(tint)
		"form_shelled":
			_chambers()
		"form_disc":
			_rim(tint.lightened(0.35))


## Merges the parts that never move, and the beads riding on each moving
## part, so a form costs a few draw calls (see PartBaker).
func bake_still_parts() -> void:
	PartBaker.bake(self, _parts)
	for part in _parts:
		PartBaker.bake(part)


## A ridge of beads winding around the body; spinning it looks like a screw.
func _spiral(col: Color) -> void:
	var screw := Node3D.new()
	add_child(screw)
	_parts.append(screw)
	for i in 16 + 4 * level:
		var t := float(i) / (15.0 + 4.0 * level)
		var a := t * TAU * (2.0 + level * 0.5)
		var bead := VisualParts.sphere(0.13, col, 0.4)
		bead.position = Vector3(cos(a), sin(a), lerpf(-0.95, 0.95, t))
		screw.add_child(bead)


## Lobes around the rim that bulge out and pull back in turn.
func _pseudopods(tint: Color) -> void:
	for i in 3 + level:
		var lobe := VisualParts.sphere(0.42, tint, 0.4, true)
		lobe.set_meta("angle", TAU * i / (3.0 + level) + randf() * 0.5)
		add_child(lobe)
		_parts.append(lobe)


## Chambers coiled over the back of the cell, one more per level.
func _chambers() -> void:
	for i in 2 + level:
		var a := PI * 0.75 + i * 0.95
		var r := 0.32 + 0.09 * i
		var chamber := VisualParts.sphere(r, SHELL, 0.15, true)
		chamber.position = Vector3(cos(a) * (0.75 - 0.08 * i), 0.45, sin(a) * 0.55 - 0.2)
		add_child(chamber)
	var test := VisualParts.sphere(1.08, Color(SHELL, 0.3), 0.0, true)
	add_child(test)


## A glassy rim with pores, like a diatom's shell seen from above.
func _rim(col: Color) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.92
	ring.outer_radius = 1.12
	var rim := MeshInstance3D.new()
	rim.mesh = ring
	rim.material_override = VisualParts.material(Color(col, 0.8), 0.4, true)
	add_child(rim)
	for i in 10 + 2 * level:
		var a := TAU * i / (10.0 + 2.0 * level)
		var pore := VisualParts.sphere(0.06, col.darkened(0.4), 0.0)
		pore.position = Vector3(cos(a) * 0.8, 0.3, sin(a) * 0.8)
		add_child(pore)


func _process(delta: float) -> void:
	_time += delta
	if form == "form_spiral":
		_parts[0].rotation.z += delta * 6.0
	elif form == "form_amoeboid":
		for i in _parts.size():
			var lobe := _parts[i]
			var a: float = lobe.get_meta("angle") + _time * 0.3
			var out := 0.75 + 0.3 * sin(_time * 1.7 + i * 2.1)
			lobe.position = Vector3(sin(a), 0.0, cos(a)) * out
