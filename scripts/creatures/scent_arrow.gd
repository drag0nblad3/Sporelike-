class_name ScentArrow
extends MeshInstance3D
## A glowing arrow beside the player that points toward the nearest food
## their body suits, for species with the Scent trail upgrade. Hides while
## the player is already inside such a patch.

const RECHECK := 0.5
const GAP := 1.6

var target: FoodPatch
var _timer := 0.0


func _ready() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(0.0, 0.0, -0.9))
	st.add_vertex(Vector3(0.45, 0.0, 0.3))
	st.add_vertex(Vector3(-0.45, 0.0, 0.3))
	mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.85, 0.5, 0.75)
	material_override = mat
	visible = false


## Called every frame by PlayerDirector with the player's body.
func track(player: Organism, food: FoodField, delta: float) -> void:
	if player.genome.feature("food_scent") <= 0:
		visible = false
		return
	var me := player.flat_pos()
	_timer -= delta
	if _timer <= 0.0 or target == null or target.count <= 0:
		_timer = RECHECK
		target = FoodScent.nearest(food.patches, player.genome, me)
	if target == null or target.contains(me):
		visible = false
		return
	var dir := (target.center - me).normalized()
	var at := me + dir * (player.radius() + GAP)
	position = Vector3(at.x, 0.4, at.y)
	look_at(position + Vector3(dir.x, 0.0, dir.y), Vector3.UP)
	visible = true
