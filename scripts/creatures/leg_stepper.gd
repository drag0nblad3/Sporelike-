class_name LegStepper
extends RefCounted
## One limb of a stage 3 walker: its foot stays planted on the ground until
## the body has moved too far from it, then swings in an arc to a new spot
## a little ahead. A partner limb (the other side) never steps at the same
## time, which gives an alternating gait. The joints are bent by IkChain;
## a bendy limb (a tentacle) curls in a travelling wave. Knees arch up,
## ride high above the hip (crouched) or bend backward, by the body's knee.

const LIFT := 0.45

var chain: IkChain
var foot := Vector3.ZERO
var partner: LegStepper
var stepping := false
var step_time := 0.18
var bendy := false
## "up", "high" or "back".
var knee := "up"
## The way the body faces, so backward knees know which way is back.
var facing := Vector3.FORWARD
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _phase := 0.0


func _init(length: float, bones: int, seconds: float, curls: bool, knees: String) -> void:
	chain = IkChain.make(bones + 1, length * 1.1 / bones)
	step_time = seconds
	bendy = curls
	knee = knees
	_phase = randf() * TAU


## home: where the foot would rest under the body right now; lead: how far
## ahead to put it when it steps (along the way the body moves).
func update(hip: Vector3, home: Vector3, lead: Vector3, reach: float, delta: float,
		time: float) -> void:
	if stepping:
		_t = minf(_t + delta / step_time, 1.0)
		foot = _from.lerp(_to, _t) + Vector3.UP * sin(_t * PI) * LIFT
		if _t >= 1.0:
			stepping = false
	elif _should_step(home, reach):
		stepping = true
		_t = 0.0
		_from = foot
		_to = home + lead
		_to.y = LandHeight.at(_to.x, _to.z)
	_bend(hip, time)
	chain.solve(hip, foot, 4)


func plant(at: Vector3) -> void:
	foot = Vector3(at.x, LandHeight.at(at.x, at.z), at.z)
	stepping = false


## Steps when the foot has fallen behind, waiting for its partner unless
## it is so far behind that the limb would stretch out of shape.
func _should_step(home: Vector3, reach: float) -> bool:
	var gap := foot.distance_to(home)
	if gap > reach * 2.0:
		return true
	return gap > reach and not (partner and partner.stepping)


## Starts the joints in a bent guess (an upward arch, or a wave for a
## tentacle) so the solver keeps knees up and curls going.
func _bend(hip: Vector3, time: float) -> void:
	var n := chain.joints.size()
	var height := chain.total_length() * (0.9 if knee == "high" else 0.5)
	var side := (foot - hip).cross(Vector3.UP).normalized()
	var bow := Vector3.UP
	if knee == "back" and not bendy:
		bow = (Vector3.UP * 0.3 - facing * 0.9).normalized()
	for j in n:
		var t := float(j) / float(n - 1)
		var p := hip.lerp(foot, t) + bow * sin(t * PI) * height
		if bendy:
			p += side * sin(time * 3.0 + _phase + t * 5.0) * height * 0.5 * sin(t * PI)
		chain.joints[j] = p
