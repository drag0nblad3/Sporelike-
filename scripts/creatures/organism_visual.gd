class_name OrganismVisual
extends Node3D
## Builds an organism's look from its genome: armor shows as spikes, speed as
## a tail (flagellum), sense as an eye spot. Also handles the idle wobble.

var _body: MeshInstance3D
var _tail_pivot: Node3D
var _time := 0.0


func build(genome: Genome, tint: Color) -> void:
	_time = randf() * 10.0
	_body = _sphere(1.0, tint, 0.5, true)
	add_child(_body)

	var nucleus := _sphere(0.35, Color(0.55, 0.3, 0.9), 0.6)
	nucleus.position = Vector3(0.2, 0.1, -0.15)
	_body.add_child(nucleus)

	_add_spikes(int(round(genome.values["armor"] * 10.0)), tint)
	_add_tail(lerpf(0.6, 1.8, genome.values["speed"]), tint)
	_add_eye(lerpf(0.12, 0.3, genome.values["sense"]))


func _process(delta: float) -> void:
	_time += delta
	var org := get_parent() as Organism
	var speed := org.velocity.length() if org else 0.0
	var pulse := 1.0 + 0.06 * sin(_time * 4.0)
	var stretch := 1.0 + speed * 0.04
	_body.scale = Vector3(pulse / sqrt(stretch), 0.8 / pulse, stretch)
	if _tail_pivot:
		_tail_pivot.rotation.y = sin(_time * (6.0 + speed * 2.0)) * 0.45


func _add_spikes(count: int, tint: Color) -> void:
	for i in count:
		var angle := TAU * i / count
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.12
		cone.height = 0.45
		var spike := MeshInstance3D.new()
		spike.mesh = cone
		spike.material_override = _material(tint.darkened(0.3), 0.3)
		spike.position = Vector3(sin(angle), 0.0, cos(angle)) * 1.05
		spike.rotation = Vector3(PI / 2.0, angle, 0.0)
		add_child(spike)


func _add_tail(length: float, tint: Color) -> void:
	_tail_pivot = Node3D.new()
	_tail_pivot.position = Vector3(0.0, 0.0, -0.9)
	add_child(_tail_pivot)
	var rod := CylinderMesh.new()
	rod.top_radius = 0.04
	rod.bottom_radius = 0.08
	rod.height = length
	var tail := MeshInstance3D.new()
	tail.mesh = rod
	tail.material_override = _material(tint, 0.6)
	tail.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	tail.position = Vector3(0.0, 0.0, -length / 2.0)
	_tail_pivot.add_child(tail)


func _add_eye(size: float) -> void:
	var eye := _sphere(size, Color(0.05, 0.05, 0.1), 0.0)
	eye.position = Vector3(0.0, 0.35, 0.8)
	add_child(eye)


func _sphere(r: float, color: Color, glow: float, see_through := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _material(color, glow, see_through)
	return inst


func _material(color: Color, glow: float, see_through := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if see_through:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b) * glow
	return mat
