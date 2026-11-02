class_name PlayerDirector
extends Node
## Owns the player's current body: spawning it, steering it from touch or
## keys, following it with the camera, and reporting its meals, habits and
## death.

signal died(cause: String)
signal ate(energy: float)
## Energy the body made without eating (photosynthesis, chemosynthesis).
signal made_energy(energy: float)

var ecosystem: Ecosystem
var camera: CameraRig
var hud: Hud
var player: PlayerCell
var genome := Genome.new()

## Records what the player does each generation (see Habits).
var tracker := HabitTracker.new()

var _has_moved := false
var _scent := ScentArrow.new()


func _ready() -> void:
	add_child(_scent)
	tracker.ecosystem = ecosystem
	add_child(tracker)


func is_alive() -> bool:
	return is_instance_valid(player) and player.alive


func spawn(g: Genome, at: Vector2) -> void:
	genome = g
	player = PlayerCell.new()
	player.setup(g, 8.0)
	player.position = Vector3(at.x, 0.0, at.y)
	player.died.connect(_on_player_died)
	player.ate.connect(_on_player_ate)
	player.absorbed.connect(func(amount: float) -> void: made_energy.emit(amount))
	add_child(player)
	ecosystem.player = player
	tracker.player = player
	camera.snap_to(player.position)


## Removes the current body without counting it as a death.
func retire() -> void:
	if is_instance_valid(player):
		player.queue_free()
	player = null
	ecosystem.player = null


func _process(delta: float) -> void:
	hud.set_hint_visible(not _has_moved)
	if not is_alive():
		_scent.visible = false
		return
	_scent.track(player, ecosystem.food, delta)
	var input := _read_move_input()
	if input.length() > 0.1:
		_has_moved = true
	player.move_input = input
	camera.follow(player.position, player.radius(), delta)
	hud.show_status(player.energy, Genome.FULL_ENERGY, player.genome.max_energy())
	hud.show_jet(player.genome.feature("jet") > 0, player.boost_cooldown <= 0.0)
	if Input.is_physical_key_pressed(KEY_SPACE):
		player.try_boost()


## Stops showing the how-to-swim hint (the player has moved on).
func hide_hint() -> void:
	_has_moved = true


## Called from the HUD's Jet button.
func boost() -> void:
	if is_alive():
		player.try_boost()


func _on_player_died(_org: Organism, cause: String) -> void:
	died.emit(cause)


func _on_player_ate(amount: float) -> void:
	ate.emit(amount)


func _read_move_input() -> Vector2:
	return TouchSteer.read(hud.joystick)
