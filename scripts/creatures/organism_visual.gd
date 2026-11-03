class_name OrganismVisual
extends Node3D
## An organism's body, built from its genome (see VisualParts), plus the
## idle wobble and tail wiggle.

var _body: MeshInstance3D
var _tails: Array[Node3D] = []
var _time := 0.0


func build(genome: Genome, tint: Color) -> void:
	_time = randf() * 10.0
	_body = VisualParts.sphere(1.0, tint, 0.5, true)
	add_child(_body)

	# Nucleus colour shows diet: green for plant eaters, red for meat eaters.
	var diet_color := Color(0.3, 0.85, 0.35).lerp(Color(0.9, 0.25, 0.25), genome.value_of("diet"))
	var nucleus := VisualParts.sphere(0.35, diet_color, 0.6)
	nucleus.position = Vector3(0.2, 0.1, -0.15)
	_body.add_child(nucleus)

	add_child(VisualParts.spikes(int(round(genome.value_of("armor") * 10.0)), tint))
	add_child(VisualParts.cilia(int(round(genome.value_of("agility") * 16.0)), tint))
	# Organelles and inner parts, each with its own look (see OrganelleParts).
	OrganelleParts.add_all(self, _body, genome)
	# The body form stretches the whole cell and adds its own parts.
	scale = FormLook.shape_scale(genome)
	add_child(FormLook.make(genome, tint))
	add_child(VisualParts.eye(lerpf(0.12, 0.3, genome.value_of("sense"))))
	if genome.value_of("jaw") > 0.25:
		add_child(VisualParts.mouth(genome.value_of("jaw")))
	# The main tail, plus a bud tail on alternating sides per tail_bud level.
	var length := lerpf(0.6, 1.8, genome.value_of("speed"))
	for i in 1 + genome.feature("tail_bud"):
		var tail := VisualParts.tail(length * (1.0 if i == 0 else 0.75), tint)
		tail.position.x = 0.0 if i == 0 else (0.35 if i % 2 == 1 else -0.35)
		add_child(tail)
		_tails.append(tail)


func _process(delta: float) -> void:
	_time += delta
	var org := get_parent() as Organism
	var speed := org.velocity.length() if org else 0.0
	var pulse := 1.0 + 0.06 * sin(_time * 4.0)
	var stretch := 1.0 + speed * 0.04
	_body.scale = Vector3(pulse / sqrt(stretch), 0.8 / pulse, stretch)
	for i in _tails.size():
		_tails[i].rotation.y = sin(_time * (6.0 + speed * 2.0) + i * 1.3) * 0.45
