class_name LandCrowd
extends Node3D
## Everyone on the land besides the player's own animal: moves each
## CrowdActor (CrowdMotion), lends full bodies to the nearest few
## (CrowdAvatars) and draws the rest as simple shapes (CrowdProxies).
## Groups (a village, raiders, a rival tribe, prey) register their own
## lists; the dead are dropped from drawing by their owners.

var proxies := CrowdProxies.new()
var avatars := CrowdAvatars.new()
var _groups: Array[Array] = []
var _all: Array[CrowdActor] = []


func _ready() -> void:
	add_child(proxies)
	add_child(avatars)


## Registers a list of actors that the owner keeps adding to and removing from.
func add_group(actors: Array[CrowdActor]) -> void:
	_groups.append(actors)


## Overhead: no full bodies, bigger shapes.
func set_overhead(on: bool) -> void:
	avatars.off = on
	proxies.grow = 2.6 if on else 1.0


func step(focus: Vector3, delta: float) -> void:
	_all.clear()
	for group in _groups:
		for actor: CrowdActor in group:
			_all.append(actor)
			if actor.alive:
				CrowdMotion.step(actor, delta)
			elif actor.avatar != null:
				avatars.drop(actor)
	avatars.update(_all, focus, delta)
	proxies.draw(_all, delta)
