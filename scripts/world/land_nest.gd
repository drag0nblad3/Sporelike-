class_name LandNest
extends Node3D
## The stage 3 animal's nest: a ring of twigs where it brings food home
## (LandFood). Every FOOD_PER_EGG pieces delivered lays an egg in it, and
## each egg is meant to become a pick in the body editor once stage 3 has
## generations. The player can move the nest (move_to); eggs move with it.

signal egg_laid(total: int)

const FOOD_PER_EGG := 3
## Drops food this close to the middle (flat distance).
const REACH := 3.5
const SHOWN_EGGS := 8

var food := 0
var eggs := 0
var _eggs: Array[MeshInstance3D] = []


func _ready() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.6
	torus.outer_radius = 2.4
	torus.rings = 16
	torus.ring_segments = 6
	var twigs := StandardMaterial3D.new()
	twigs.albedo_color = Color(0.45, 0.32, 0.2)
	torus.material = twigs
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.6, 1.0)
	add_child(ring)
	var egg_mesh := SphereMesh.new()
	egg_mesh.radius = 0.38
	egg_mesh.height = 0.95
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.95, 0.92, 0.8)
	egg_mesh.material = shell
	for k in SHOWN_EGGS:
		var egg := MeshInstance3D.new()
		egg.mesh = egg_mesh
		var angle := TAU * k / SHOWN_EGGS
		egg.position = Vector3(cos(angle), 0.35, sin(angle)) * Vector3(0.8 if k % 2 else 0.35, 1.0,
			0.8 if k % 2 else 0.35)
		egg.visible = false
		add_child(egg)
		_eggs.append(egg)
	move_to(position)


func move_to(at: Vector3) -> void:
	position = Vector3(at.x, LandHeight.at(at.x, at.z) + 0.1, at.z)


func is_near(at: Vector3) -> bool:
	return Vector2(at.x - position.x, at.z - position.z).length() < REACH


## Takes `count` pieces of food; lays eggs as the store fills.
func deliver(count: int) -> void:
	food += count
	while food >= FOOD_PER_EGG:
		food -= FOOD_PER_EGG
		eggs += 1
		egg_laid.emit(eggs)
	for k in _eggs.size():
		_eggs[k].visible = k < eggs
