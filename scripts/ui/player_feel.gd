class_name PlayerFeel
extends Node
## Makes the player's moments felt: a sound, a buzz of the phone and a
## pop-up line for meals, eating streaks (EatStreak), prize morsels,
## swallowed cells, blocked bites, the Jet and death. PlayerDirector calls it.

const STREAK_COLOUR := Color(0.6, 1.0, 0.7)
const PRIZE_COLOUR := Color(1.0, 0.85, 0.3)
const SWALLOW_COLOUR := Color(1.0, 0.6, 0.5)
const BLOCK_COLOUR := Color(0.7, 0.85, 1.0)

var streak := EatStreak.new()
var _sounds := BlipSounds.new()


func _ready() -> void:
	add_child(_sounds)


## A normal meal. Returns the streak's extra energy for it.
func meal(body: Organism, amount: float) -> float:
	var count := streak.note(Time.get_ticks_msec() / 1000.0)
	_sounds.play("eat", 1.0 + 0.06 * mini(count - 1, 10))
	Haptics.pulse(12, 0.3)
	var share := streak.bonus()
	if share > 0.0:
		_pop(body, "Streak x%d: +%d%% energy" % [count, roundi(share * 100.0)], STREAK_COLOUR)
	return amount * share


func prize(body: Organism, energy: float) -> void:
	_sounds.play("prize")
	Haptics.pulse(60, 0.7)
	_pop(body, "Prize morsel! +%.1f energy" % energy, PRIZE_COLOUR)


func swallowed(body: Organism, energy: float) -> void:
	_sounds.play("swallow")
	Haptics.pulse(80, 0.8)
	_pop(body, "Swallowed a cell! +%.1f energy" % energy, SWALLOW_COLOUR)


func bite_blocked(body: Organism, how: String) -> void:
	_sounds.play("hit")
	Haptics.pulse(120, 1.0)
	_pop(body, how, BLOCK_COLOUR)


func ability(id: String) -> void:
	_sounds.play("jet" if id == "jet" else "hit", 1.6 if id != "jet" else 1.0)
	Haptics.pulse(25, 0.5)


func died() -> void:
	_sounds.play("death")
	Haptics.pulse(300, 1.0)


func _pop(body: Organism, line: String, colour: Color) -> void:
	if is_instance_valid(body) and body.get_parent():
		PopText.show_at(body.get_parent(), body.position, line, colour)
