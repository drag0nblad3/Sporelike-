class_name EatStreak
extends RefCounted
## Counts meals eaten in quick succession. From the STARTS-th meal in a
## row, each one gives STEP more energy than normal, up to MAX_BONUS.

## Seconds allowed between meals before the streak breaks.
const GAP := 1.5
const STARTS := 3
const STEP := 0.1
const MAX_BONUS := 0.5

var count := 0
var _last := -100.0


## Records a meal at this time (seconds) and returns the streak length.
func note(now: float) -> int:
	count = count + 1 if now - _last <= GAP else 1
	_last = now
	return count


## Extra energy share for the current streak (0 below STARTS meals).
func bonus() -> float:
	if count < STARTS:
		return 0.0
	return minf(STEP * (count - STARTS + 1), MAX_BONUS)
