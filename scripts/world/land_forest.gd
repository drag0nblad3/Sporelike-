class_name LandForest
extends Node3D
## Stage 3 forests: tall trees where LandZone says forest, on ground gentle
## enough to root in and out of rivers, with a few lone trees out on the
## hills. Two kinds of crown (pointed spires and round tufts) on bare
## trunks, plus low thickets between them. Four LandMulti batches.

## Spacing of the jittered grid trees are tried on.
const GAP := 3.6
const LONE := 0.015

var rng := RandomNumberGenerator.new()
var _trunks: Array[Transform3D] = []
var _trunk_tints := PackedColorArray()
var _spires: Array[Transform3D] = []
var _spire_tints := PackedColorArray()
var _tufts: Array[Transform3D] = []
var _tuft_tints := PackedColorArray()
var _bushes: Array[Transform3D] = []
var _bush_tints := PackedColorArray()


func _ready() -> void:
	rng.seed = 23
	var reach := LandScatter.SPREAD
	var steps := int(reach * 2.0 / GAP)
	for gz in steps:
		for gx in steps:
			var x := -reach + (gx + rng.randf()) * GAP
			var z := -reach + (gz + rng.randf()) * GAP
			_try(x, z)
	add_child(LandMulti.build_patches(LandMulti.post(0.12, 0.2, 5), _trunks, _trunk_tints))
	add_child(LandMulti.build_patches(LandMulti.post(0.0, 1.0, 7), _spires, _spire_tints))
	add_child(LandMulti.build_patches(LandMulti.blob(1.0, 1.0, 8, 4), _tufts, _tuft_tints))
	add_child(LandMulti.build_patches(LandMulti.blob(1.0, 0.7, 7, 3), _bushes, _bush_tints))


func _try(x: float, z: float) -> void:
	if Vector2(x, z).length() < 7.0 or LandRiver.wet(x, z) > 0.1:
		return
	var f := LandZone.forest(x, z)
	var roll := rng.randf()
	if roll > f * 0.8 + LONE:
		if roll < f * 0.8 + LONE + f * 0.25:
			_bush(x, z)
		return
	if LandHeight.normal(x, z).y < 0.8:
		return
	var y := LandHeight.at(x, z)
	var tall := rng.randf_range(6.0, 12.0)
	var trunk := tall * rng.randf_range(0.45, 0.6)
	var lean := Basis(Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.0, 0.08))
	var base := Vector3(x, y - 0.3, z)
	_trunks.append(Transform3D(lean.scaled(Vector3(tall * 0.12, trunk + 0.5, tall * 0.12)), base))
	_trunk_tints.append(Color(0.36, 0.27, 0.19).lightened(rng.randf_range(-0.1, 0.1)))
	var top := base + lean * Vector3(0, trunk, 0)
	var turn := Basis(Vector3.UP, rng.randf() * TAU)
	if rng.randf() < 0.55:
		var wide := tall * rng.randf_range(0.22, 0.3)
		var high := tall - trunk * 0.6
		_spires.append(Transform3D(turn.scaled(Vector3(wide, high, wide)), top - Vector3(0, trunk * 0.4, 0)))
		_spire_tints.append(Color(0.16, 0.36, 0.2).lightened(rng.randf_range(-0.08, 0.12)))
	else:
		var r := tall * rng.randf_range(0.25, 0.35)
		_tufts.append(Transform3D(turn.scaled(Vector3(r, r * 0.8, r)), top + Vector3(0, r * 0.4, 0)))
		_tuft_tints.append(Color(0.3, 0.48, 0.2).lightened(rng.randf_range(-0.1, 0.12)))


func _bush(x: float, z: float) -> void:
	var r := rng.randf_range(0.6, 1.5)
	var turn := Basis(Vector3.UP, rng.randf() * TAU)
	_bushes.append(Transform3D(turn.scaled(Vector3(r * 1.3, r, r)), Vector3(x, LandHeight.at(x, z), z)))
	_bush_tints.append(Color(0.26, 0.42, 0.2).lightened(rng.randf_range(-0.1, 0.12)))
