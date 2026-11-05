class_name ShadowLayer
extends MultiMeshInstance3D
## Soft shadows on the sea floor under every swimming cell and hunter, so
## they read as floating above it. All shadows are one MultiMesh (one draw
## call) of FloorShadow's disc, placed each frame from the ecosystem's lists.

const MAX_SHADOWS := 256

var _ecosystem: Ecosystem


func _init(ecosystem: Ecosystem) -> void:
	_ecosystem = ecosystem
	var disc := FloorShadow.disc()
	disc.material = FloorShadow.material()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = disc
	multimesh.instance_count = MAX_SHADOWS
	multimesh.visible_instance_count = 0
	# The shadows roam the whole endless sea, so never cull them as a block.
	custom_aabb = AABB(Vector3(-1e5, -10.0, -1e5), Vector3(2e5, 20.0, 2e5))
	# Placed in world space, whoever each organism's parent is.
	top_level = true


func _process(_delta: float) -> void:
	var count := 0
	# The prey list is cached per physics frame, so it can still hold cells
	# freed since; check each one before treating it as an Organism.
	for item: Variant in _ecosystem.prey_list():
		count = _place(count, item)
	for item: Variant in _ecosystem.predators:
		count = _place(count, item)
	multimesh.visible_instance_count = count


func _place(count: int, item: Variant) -> int:
	if count >= MAX_SHADOWS or not is_instance_valid(item):
		return count
	var org := item as Organism
	if org == null or not org.alive or not org.visible or not org.is_inside_tree():
		return count
	var size := org.radius() * 1.15
	var p := org.global_position
	var lift := maxf(p.y - FloorShadow.FLOOR, 0.0)
	var shift := FloorShadow.SUN_SHIFT * lift
	var at := Vector3(p.x + shift.x, FloorShadow.FLOOR, p.z + shift.y)
	multimesh.set_instance_transform(count, Transform3D(Basis.from_scale(Vector3.ONE * size), at))
	return count + 1
