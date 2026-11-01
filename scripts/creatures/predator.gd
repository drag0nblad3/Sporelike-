class_name Predator
extends Organism
## A large hunter. Chases the nearest prey it can sense and can swallow
## anything noticeably smaller than itself. Never starves (for now).

const BITE_COOLDOWN := 2.5

var ecosystem: Ecosystem
var cooldown := 0.0


static func make_genome() -> Genome:
	var g := Genome.new()
	g.values = {"size": 1.0, "speed": 0.45, "sense": 0.55, "armor": 0.0}
	return g


func _init() -> void:
	upkeep_scale = 0.0


func tint() -> Color:
	return Color(1.0, 0.3, 0.25, 0.7)


func can_swallow(prey: Organism) -> bool:
	return prey.radius() < radius() * 0.85


func think(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if cooldown > 0.0:
		move_input = wander_input(delta) * 0.5
		return
	var prey := ecosystem.nearest_prey_for(self)
	if prey:
		move_input = (prey.flat_pos() - flat_pos()).normalized()
	else:
		move_input = wander_input(delta)
