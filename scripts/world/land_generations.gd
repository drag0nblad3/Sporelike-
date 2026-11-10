class_name LandGenerations
extends Node
## Stage 3's generations: a 180 s clock that stops while the body is
## evolving. When it runs out, ended says which generation finished, and
## the eggs in the nest become that many picks (picks_for) for the next
## body, which hatches at the nest.

signal ended(number: int)

const LENGTH := 180.0
## Picks even with no eggs, and the most a generation can give.
const BASE_PICKS := 1
const MAX_PICKS := 6

## Seconds per generation (the village of stage 4 runs longer ones).
var length := LENGTH
var number := 1
var time_left := LENGTH
var running := true


static func picks_for(eggs: int) -> int:
	return mini(BASE_PICKS + eggs, MAX_PICKS)


func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	if time_left <= 0.0:
		end_now()


## Ends this generation at once (the clock running out, or a test).
func end_now() -> void:
	running = false
	time_left = 0.0
	ended.emit(number)


## The next generation's clock starts.
func begin_next() -> void:
	number += 1
	time_left = length
	running = true


func text() -> String:
	var left := ceili(maxf(time_left, 0.0))
	return "Generation %d  ·  %d:%02d left" % [number, left / 60, left % 60]
