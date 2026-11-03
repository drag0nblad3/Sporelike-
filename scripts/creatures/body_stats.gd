class_name BodyStats
extends RefCounted
## The movement and upkeep numbers an organism reads every physics frame,
## worked out from its genome a few times a second instead of every frame.
## Each one walks many genome lookups, which adds up across a big crowd.

const REFRESH := 0.5

var top_speed := 0.0
var push := 0.0
var turn := 0.0
var upkeep := 0.0
var drift := 1.0

var _timer := 0.0


## Re-reads the genome when due (or right away with force), so a pick
## shows up within half a second.
func tick(genome: Genome, delta: float, force := false) -> void:
	_timer -= delta
	if _timer > 0.0 and not force:
		return
	_timer = REFRESH
	top_speed = genome.max_speed()
	push = genome.acceleration()
	turn = genome.turn_rate()
	upkeep = genome.upkeep()
	drift = BodyForm.drift(genome)
