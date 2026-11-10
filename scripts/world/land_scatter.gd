class_name LandScatter
extends Node3D
## What grows and lies on the open stage 3 land: boulders (thicker around
## crags and below cliffs) and low plants (moss cushions and stalks with a
## bud on top), kept out of rivers. Adds LandForest and LandSpires for the
## trees and crag pinnacles. Drawn as LandMulti batches.

const ROCKS := 300
const STALKS := 1500
const CUSHIONS := 800
## Half the width of the square things are scattered over.
const SPREAD := 210.0

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 11
	_add(LandMulti.blob(0.5, 0.8, 7, 4), ROCKS, Color(0.5, 0.48, 0.45), 1.0, 6.0, 0.3, true)
	var stalk := LandMulti.post(0.03, 0.08, 5)
	_add(stalk, STALKS, Color(0.38, 0.62, 0.3), 0.6, 1.6, 0.05, false)
	_add(LandMulti.blob(0.5, 0.45, 8, 3), CUSHIONS, Color(0.3, 0.52, 0.28), 0.8, 2.2, 0.1, false)
	add_child(LandForest.new())
	add_child(LandSpires.new())


## A random spot away from the start and out of the water, or the start
## itself if none turns up. Rocky spots favour crags and mesas.
func spot(rocky: bool) -> Vector2:
	for _try in 12:
		var p := Vector2(rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD))
		if p.length() < 4.0 or LandRiver.wet(p.x, p.y) > 0.2:
			continue
		var rough := maxf(LandZone.crag(p.x, p.y), LandZone.mesa(p.x, p.y))
		if rocky and rng.randf() > 0.25 + rough:
			continue
		if not rocky and rng.randf() < rough * 0.7:
			continue
		return p
	return Vector2(6.0, 6.0)


func _add(mesh: Mesh, count: int, tint: Color, low: float, high: float, sink: float, rocky: bool) -> void:
	var places: Array[Transform3D] = []
	var tints := PackedColorArray()
	for i in count:
		var p := spot(rocky)
		var size := rng.randf_range(low, high)
		var squash := Vector3(size, size * rng.randf_range(0.6, 1.1), size * rng.randf_range(0.8, 1.2))
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(squash)
		places.append(Transform3D(basis, Vector3(p.x, LandHeight.at(p.x, p.y) - sink * size, p.y)))
		tints.append(tint.lightened(rng.randf_range(-0.1, 0.15)))
	add_child(LandMulti.build_patches(mesh, places, tints))
