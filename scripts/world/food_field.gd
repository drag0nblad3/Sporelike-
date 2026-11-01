class_name FoodField
extends Node3D
## Glowing food particles scattered over the arena. Eaten food regrows
## slowly, so a big population runs short and has to compete.

const TARGET_COUNT := 60
const REGROW_INTERVAL := 0.3
const FOOD_RADIUS := 0.22
const ENERGY_PER_FOOD := 2.5

var arena_radius := 30.0
var rng: RandomNumberGenerator

var _mesh: SphereMesh
var _material: StandardMaterial3D
var _regrow_timer := 0.0
var _time := 0.0


func setup(arena: float, random: RandomNumberGenerator) -> void:
	arena_radius = arena
	rng = random


func _ready() -> void:
	_mesh = SphereMesh.new()
	_mesh.radius = FOOD_RADIUS
	_mesh.height = FOOD_RADIUS * 2.0
	_mesh.radial_segments = 12
	_mesh.rings = 6
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.5, 1.0, 0.45)
	_material.emission_enabled = true
	_material.emission = Color(0.3, 0.9, 0.3)
	_material.emission_energy_multiplier = 1.5
	for _i in TARGET_COUNT:
		_spawn()


func _process(delta: float) -> void:
	_time += delta
	for child in get_children():
		var f := child as Node3D
		f.position.y = 0.15 * sin(_time * 2.0 + f.position.x)
	_regrow_timer -= delta
	if _regrow_timer <= 0.0 and get_child_count() < TARGET_COUNT:
		_regrow_timer = REGROW_INTERVAL
		_spawn()


## Closest uneaten food within max_range, or null.
func nearest(pos: Vector2, max_range: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_range * max_range
	for child in get_children():
		if child.is_queued_for_deletion():
			continue
		var f := child as Node3D
		var d := pos.distance_squared_to(Vector2(f.position.x, f.position.z))
		if d < best_d:
			best_d = d
			best = f
	return best


## Removes all food within reach of pos and returns how many were eaten.
func consume_near(pos: Vector2, reach: float) -> int:
	var eaten := 0
	for child in get_children():
		if child.is_queued_for_deletion():
			continue
		var f := child as Node3D
		if pos.distance_squared_to(Vector2(f.position.x, f.position.z)) < reach * reach:
			f.queue_free()
			eaten += 1
	return eaten


func _spawn() -> void:
	var food := MeshInstance3D.new()
	food.mesh = _mesh
	food.material_override = _material
	var angle := rng.randf_range(0.0, TAU)
	var dist := sqrt(rng.randf()) * (arena_radius - 1.0)
	food.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	add_child(food)
