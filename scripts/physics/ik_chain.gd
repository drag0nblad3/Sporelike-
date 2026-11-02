class_name IkChain
extends RefCounted
## Inverse kinematics for one limb, using FABRIK: walk the joints from the
## tip to the target and back to the root a few times, keeping each
## segment's length. Cheap and stable, which suits whips and tentacles.

var joints := PackedVector3Array()
var lengths := PackedFloat32Array()


## A straight chain of `count` joints, `segment` apart.
static func make(count: int, segment: float) -> IkChain:
	var chain := IkChain.new()
	for i in count:
		chain.joints.append(Vector3(0.0, 0.0, segment * i))
		if i > 0:
			chain.lengths.append(segment)
	return chain


func total_length() -> float:
	var sum := 0.0
	for l in lengths:
		sum += l
	return sum


func tip() -> Vector3:
	return joints[joints.size() - 1]


## Bends the chain so it starts at `root` and its tip reaches toward `target`.
func solve(root: Vector3, target: Vector3, iterations: int = 3) -> void:
	var n := joints.size()
	if n < 2:
		return
	if root.distance_to(target) >= total_length():
		var dir := _dir(root, target)
		joints[0] = root
		for i in range(1, n):
			joints[i] = joints[i - 1] + dir * lengths[i - 1]
		return
	for _pass in iterations:
		joints[n - 1] = target
		for i in range(n - 2, -1, -1):
			joints[i] = joints[i + 1] + _dir(joints[i + 1], joints[i]) * lengths[i]
		joints[0] = root
		for i in range(1, n):
			joints[i] = joints[i - 1] + _dir(joints[i - 1], joints[i]) * lengths[i - 1]


static func _dir(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	if d.length_squared() < 0.00000001:
		return Vector3.BACK
	return d.normalized()
