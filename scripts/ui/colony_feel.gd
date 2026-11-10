class_name ColonyFeel
extends Node
## Makes the colony's moments felt in stage 2: a sound and a buzz of the
## phone for meals, biting a rival, losing a cell, stinging a biter, the
## abilities, changing depth, the boss and hauling out. ColonyPilot calls it.

const MEAL_GAP := 0.18
const BITE_GAP := 0.4

var _sounds := BlipSounds.new()
var _meal_at := 0.0
var _bite_at := 0.0


func _ready() -> void:
	add_child(_sounds)


## Food eaten this frame, and how much of it was torn from other colonies.
func meal(amount: float, bitten_off: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if bitten_off > 0.0 and now - _bite_at > BITE_GAP:
		_bite_at = now
		_sounds.play("swallow", 1.2)
		Haptics.pulse(50, 0.7)
	elif amount > 0.0 and now - _meal_at > MEAL_GAP:
		_meal_at = now
		_sounds.play("eat", 0.85)
		Haptics.pulse(10, 0.3)


## A ColonyWounds outcome for the player's colony.
func wound(outcome: String) -> void:
	if outcome == ColonyWounds.BITTEN:
		_sounds.play("hit")
		Haptics.pulse(120, 1.0)
	elif outcome == ColonyWounds.STUNG or outcome == ColonyWounds.BLOCKED:
		_sounds.play("jet", 1.6)
		Haptics.pulse(30, 0.5)


func ability() -> void:
	_sounds.play("jet")
	Haptics.pulse(25, 0.5)


func depth(step: int) -> void:
	_sounds.play("jet", 1.5 if step > 0 else 0.7)


func boss(slain: bool) -> void:
	_sounds.play("prize" if slain else "horn")
	Haptics.pulse(200, 1.0)


func hauled_out() -> void:
	_sounds.play("chime", 0.8)
	Haptics.pulse(150, 0.8)


func died() -> void:
	_sounds.play("death")
	Haptics.pulse(300, 1.0)
