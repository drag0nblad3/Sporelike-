class_name AbilityTimers
extends RefCounted
## One cell's ability recharge timers: seconds left per ability id.

var _left := {}
var _total := {}


func ready(id: String) -> bool:
	return float(_left.get(id, 0.0)) <= 0.0


func start(id: String, seconds: float) -> void:
	_left[id] = seconds
	_total[id] = maxf(seconds, 0.01)


## 0 when ready, up to 1 just after use.
func fraction(id: String) -> float:
	return clampf(float(_left.get(id, 0.0)) / float(_total.get(id, 1.0)), 0.0, 1.0)


func tick(delta: float) -> void:
	for id in _left:
		_left[id] = maxf(float(_left[id]) - delta, 0.0)
