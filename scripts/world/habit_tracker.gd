class_name HabitTracker
extends Node
## Watches the player's cell during a generation and records its habits
## (see Habits): sprinting, sharp turns, time near hunters, time in sunlit
## meadows or by vents, and what kinds of food it ate.

## Share of top speed that counts as sprinting.
const SPRINT_AT := 0.75
## Angle between where you steer and where you are going that counts as a
## sharp turn.
const SHARP_TURN := PI / 3.0
## A hunter this close that wants you counts as danger.
const DANGER_RANGE := 7.0
const GROUND_CHECK := 0.25

var ecosystem: Ecosystem
var player: PlayerCell
var habits := Habits.new()

var _ground_timer := 0.0


func _ready() -> void:
	ecosystem.food.eaten.connect(_on_eaten)


## Starts a fresh record for a generation of this many seconds.
func reset(seconds: float) -> void:
	habits = Habits.new()
	habits.length = seconds


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not player.alive:
		return
	var v := Vector2(player.velocity.x, player.velocity.z)
	var top := player.genome.max_speed() * player.speed_scale
	if v.length() >= SPRINT_AT * top:
		habits.add("sprint", delta)
	if player.move_input.length() > 0.5 and v.length() > 0.5 \
			and absf(v.angle_to(player.move_input)) > SHARP_TURN:
		habits.add("turn", delta)
	var me := player.flat_pos()
	var hunter := ecosystem.nearest_predator(me, DANGER_RANGE)
	if hunter and hunter.wants(player):
		habits.add("danger", delta)
	_ground_timer -= delta
	if _ground_timer <= 0.0:
		_ground_timer = GROUND_CHECK
		var kind := EnergySources.kind_at(me, ecosystem.food.patches)
		if kind == EnergySources.SUN_KIND:
			habits.add("sun", GROUND_CHECK)
		elif kind == EnergySources.VENT_KIND:
			habits.add("vent", GROUND_CHECK)


func _on_eaten(org: Organism, item: FoodItem, energy: float) -> void:
	if org == player:
		habits.note_meal(org.genome, item, energy)
