class_name LegStepper
extends RefCounted
## One leg of a stage 3 walker: its foot stays planted on the ground until
## the body has moved too far from it, then swings in an arc to a new spot
## a little ahead. A partner leg (the other side) never steps at the same
## time, which gives an alternating gait. The knee is bent by IkChain.

const STEP_TIME := 0.18
const LIFT := 0.45

var chain: IkChain
var foot := Vector3.ZERO
var partner: LegStepper
var stepping := false
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0


func _init(length: float) -> void:
	chain = IkChain.make(3, length * 0.55)


## home: where the foot would rest under the body right now; lead: how far
## ahead to put it when it steps (along the way the body moves).
func update(hip: Vector3, home: Vector3, lead: Vector3, reach: float, delta: float) -> void:
	if stepping:
		_t = minf(_t + delta / STEP_TIME, 1.0)
		foot = _from.lerp(_to, _t) + Vector3.UP * sin(_t * PI) * LIFT
		if _t >= 1.0:
			stepping = false
	elif foot.distance_to(home) > reach and not (partner and partner.stepping):
		stepping = true
		_t = 0.0
		_from = foot
		_to = home + lead
		_to.y = LandHeight.at(_to.x, _to.z)
	var knee_up := (hip + foot) * 0.5 + Vector3.UP * chain.total_length() * 0.5
	chain.joints[0] = hip
	chain.joints[1] = knee_up
	chain.joints[2] = foot
	chain.solve(hip, foot, 4)


func plant(at: Vector3) -> void:
	foot = Vector3(at.x, LandHeight.at(at.x, at.z), at.z)
	stepping = false
