class_name TeaserPlant
extends Node3D
## A giant, ghostly sea plant rooted in the floor: a rosette of long fronds
## that sway with the water. A hint of the bigger life to come; purely for
## looks, nothing can touch or eat it yet.

const FROND := Color(0.45, 0.85, 0.35, 0.26)
const FLOOR_Y := -1.4

var _rng := RandomNumberGenerator.new()
var _fronds: Array[Node3D] = []
var _tilts := PackedFloat32Array()
var _phase := 0.0


func _init(seed_value: int) -> void:
	_rng.seed = seed_value


func _ready() -> void:
	position.y = FLOOR_Y
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FROND
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(0.08, 0.2, 0.06)
	var count := _rng.randi_range(5, 8)
	for i in count:
		var pivot := Node3D.new()
		pivot.rotation.y = TAU * i / count + _rng.randf_range(-0.3, 0.3)
		add_child(pivot)
		var leaf := MeshInstance3D.new()
		leaf.mesh = _leaf(_rng.randf_range(10.0, 17.0), _rng.randf_range(2.0, 3.4))
		leaf.material_override = mat
		pivot.add_child(leaf)
		_fronds.append(leaf)
		_tilts.append(_rng.randf_range(0.2, 0.45))
	_phase = _rng.randf() * TAU


func _process(delta: float) -> void:
	_phase += delta
	for i in _fronds.size():
		# Lean up from the floor and sway, each frond a little out of step.
		_fronds[i].rotation.x = -_tilts[i] - 0.08 * sin(_phase * 0.7 + i * 1.3)


## A long tapered blade lying along +Z, wide in the middle.
static func _leaf(length: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var steps := 6
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	for s in range(1, steps + 1):
		var t := float(s) / steps
		var half := width * 0.5 * sin(t * PI) + 0.05
		var z := length * t
		var l := Vector3(-half, 0.0, z)
		var r := Vector3(half, 0.0, z)
		st.add_vertex(prev_l)
		st.add_vertex(r)
		st.add_vertex(l)
		st.add_vertex(prev_l)
		st.add_vertex(prev_r)
		st.add_vertex(r)
		prev_l = l
		prev_r = r
	return st.commit()
