class_name LandSpires
extends Node3D
## Stage 3 crag pinnacles: tall, leaning, pointed rock spikes clustered on
## the crags (LandZone), with fallen blocks around their feet. Two
## LandMulti batches.

const TRIES := 900

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 37
	var spikes: Array[Transform3D] = []
	var spike_tints := PackedColorArray()
	var blocks: Array[Transform3D] = []
	var block_tints := PackedColorArray()
	var reach := LandScatter.SPREAD
	for _i in TRIES:
		var x := rng.randf_range(-reach, reach)
		var z := rng.randf_range(-reach, reach)
		if rng.randf() > LandZone.crag(x, z) * 0.6 or LandRiver.wet(x, z) > 0.1:
			continue
		var y := LandHeight.at(x, z)
		var grey := Color(0.5, 0.48, 0.45).lightened(rng.randf_range(-0.12, 0.1))
		var tilt := Basis(Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.0, 0.25))
		var turn := tilt * Basis(Vector3.UP, rng.randf() * TAU)
		var high := rng.randf_range(3.0, 10.0)
		var wide := high * rng.randf_range(0.18, 0.3)
		spikes.append(Transform3D(turn.scaled(Vector3(wide, high, wide * rng.randf_range(0.6, 1.0))), Vector3(x, y - 0.8, z)))
		spike_tints.append(grey)
		var bx := x + rng.randf_range(-3.0, 3.0)
		var bz := z + rng.randf_range(-3.0, 3.0)
		var b := rng.randf_range(0.6, 1.6)
		blocks.append(Transform3D(turn.scaled(Vector3(b * 1.2, b * 0.8, b)), Vector3(bx, LandHeight.at(bx, bz) - 0.2, bz)))
		block_tints.append(grey.darkened(0.08))
	add_child(LandMulti.build(LandMulti.post(0.08, 1.0, 5), spikes, spike_tints))
	var block := BoxMesh.new()
	add_child(LandMulti.build(block, blocks, block_tints))
