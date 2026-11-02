class_name IkLimb
extends Node3D
## One jointed limb, a flagellum's whip or a tentacle, drawn as a row of
## shrinking beads. Each frame its tip is aimed at a target that is eased
## toward, so the limb trails as if dragged through water, and IkChain
## bends the joints to reach it.

var chain: IkChain
var _beads: BeadStrip
var _goal := Vector3.ZERO
var _started := false


func setup(joints: int, segment: float, thickness: float, color: Color) -> void:
	chain = IkChain.make(joints, segment)
	_beads = BeadStrip.make(joints, thickness, 6)
	for i in joints:
		_beads.set_color(i, color.lerp(Color.WHITE, 0.4 * i / float(joints)))
	add_child(_beads)


func length() -> float:
	return chain.total_length()


func tip() -> Vector3:
	return chain.tip()


## Moves the limb's base to `root` and bends it toward `target`.
func pose(root: Vector3, target: Vector3, delta: float, ease_rate: float = 10.0) -> void:
	if not _started:
		_started = true
		_goal = target
	_goal = _goal.lerp(target, minf(ease_rate * delta, 1.0))
	chain.solve(root, _goal)
	var n := chain.joints.size()
	for i in n:
		_beads.place(i, chain.joints[i], lerpf(1.0, 0.45, i / float(maxi(n - 1, 1))))
