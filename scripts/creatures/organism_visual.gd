class_name OrganismVisual
extends Node3D
## An organism's body, built from its genome (see VisualParts), plus the
## idle wobble and tail wiggle.

var _body: MeshInstance3D
var _tail_pivot: Node3D
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
	add_child(VisualParts.eye(lerpf(0.12, 0.3, genome.value_of("sense"))))
	if genome.value_of("jaw") > 0.25:
		add_child(VisualParts.jaws(genome.value_of("jaw")))
	_tail_pivot = VisualParts.tail(lerpf(0.6, 1.8, genome.value_of("speed")), tint)
	add_child(_tail_pivot)


func _process(delta: float) -> void:
	_time += delta
	var org := get_parent() as Organism
	var speed := org.velocity.length() if org else 0.0
	var pulse := 1.0 + 0.06 * sin(_time * 4.0)
	var stretch := 1.0 + speed * 0.04
	_body.scale = Vector3(pulse / sqrt(stretch), 0.8 / pulse, stretch)
	_tail_pivot.rotation.y = sin(_time * (6.0 + speed * 2.0)) * 0.45
