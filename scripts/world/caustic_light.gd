class_name CausticLight
extends MeshInstance3D
## Sunlight rippling over the sea floor around the colony in the
## multicellular stage: a glowing CausticShader overlay that follows it,
## bright in sunny seas and faint in the dim deep.

const SIZE := 96.0
const FLOOR_Y := -1.32
## Overlay strength per unit of the sea's sun energy, and its limits.
const PER_SUN := 0.22
const LOWEST := 0.04
const HIGHEST := 0.32

var _mat := CausticShader.overlay()
var _strength := 0.15


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh = plane
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func follow(center: Vector3, delta: float) -> void:
	position = Vector3(center.x, FLOOR_Y, center.z)
	var flat := Vector2(center.x, center.z)
	var goal := clampf(SeaBlend.at(flat).sun_energy * PER_SUN, LOWEST, HIGHEST)
	_strength = lerpf(_strength, goal, clampf(delta, 0.0, 1.0))
	_mat.set_shader_parameter("strength", _strength)
	_mat.set_shader_parameter("center", flat)
