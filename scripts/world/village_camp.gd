class_name VillageCamp
extends Node3D
## What discoveries add to a stage 4 village on the ground: the campfire
## (predators keep FIRE_REACH away), the workshop hut, the drop-off
## basket gatherers may unload at, and the guards' watch calls, which put
## the Alarm up while raiders are close and take it down afterwards.

const FIRE_REACH := 6.5
const CALL_REACH := 42.0

var fire_lit := false
## Where the drop-off basket stands, or INF.
var basket := Vector3.INF
var _fire := MeshInstance3D.new()
var _hut := MeshInstance3D.new()
var _basket := MeshInstance3D.new()
var _called := false
var _wait := 0.0


func _ready() -> void:
	var flame := CylinderMesh.new()
	flame.top_radius = 0.0
	flame.bottom_radius = 0.8
	flame.height = 2.2
	flame.radial_segments = 6
	_shape(_fire, flame, Color(1.0, 0.55, 0.15), true)
	var hut := BoxMesh.new()
	hut.size = Vector3(3.2, 2.6, 2.6)
	_shape(_hut, hut, Color(0.55, 0.42, 0.28), false)
	var tub := CylinderMesh.new()
	tub.top_radius = 1.1
	tub.bottom_radius = 0.8
	tub.height = 1.2
	tub.radial_segments = 8
	_shape(_basket, tub, Color(0.8, 0.68, 0.4), false)


func place(center: Vector3) -> void:
	_fire.position = center + Vector3.UP * 1.2
	var at := CrowdFind.ring(center, 0, VillageBuildings.RING, TAU * 0.5 + 2.7)
	_hut.position = Vector3(at.x, LandHeight.at(at.x, at.z) + 1.0, at.z)


## Shows what a newly learned discovery builds.
func learned(id: String) -> void:
	if id == Discovery.FIRE:
		fire_lit = true
		_fire.visible = true
	elif id == Discovery.WORKSHOP:
		_hut.visible = true


func set_basket(at: Vector3) -> void:
	basket = at
	_basket.visible = at != Vector3.INF
	if _basket.visible:
		_basket.position = at + Vector3.UP * 0.6


## Watch calls: guards raise and drop the Alarm by themselves.
func step(village: Village, delta: float) -> void:
	_wait -= delta
	if _wait > 0.0 or not village.learning.has(Discovery.CALLS):
		return
	_wait = 0.5
	var near := village.enemy_near(village.center, CALL_REACH) != null
	if near and not village.alarm and village.jobs.count(VillageJob.GUARD) > 0:
		village.alarm = true
		_called = true
		village.notice.emit("The guards call out: raiders! Everyone shelters")
	elif _called and not near:
		village.alarm = false
		_called = false


func _shape(node: MeshInstance3D, mesh: Mesh, tint: Color, glow: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	if glow:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	node.mesh = mesh
	node.material_override = mat
	node.visible = false
	add_child(node)
