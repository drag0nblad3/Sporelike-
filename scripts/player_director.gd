class_name PlayerDirector
extends Node
## Owns the player's current body: spawning it, steering it from touch or
## keys, following it with the camera, and reporting its meals and death.

signal died(cause: String)
signal ate

var ecosystem: Ecosystem
var camera: CameraRig
var hud: Hud
var arena_radius := 30.0
var player: PlayerCell
var genome := Genome.new()

var _has_moved := false


func is_alive() -> bool:
	return is_instance_valid(player) and player.alive


func spawn(g: Genome, at: Vector2) -> void:
	genome = g
	player = PlayerCell.new()
	player.setup(g, arena_radius, 8.0)
	player.position = Vector3(at.x, 0.0, at.y)
	player.died.connect(_on_player_died)
	player.ate.connect(_on_player_ate)
	add_child(player)
	ecosystem.player = player
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
		return
	var input := _read_move_input()
	if input.length() > 0.1:
		_has_moved = true
	player.move_input = input
	camera.follow(player.position, player.radius(), delta)
	hud.show_status(player.energy, Organism.MAX_ENERGY)


func _on_player_died(_org: Organism, cause: String) -> void:
	died.emit(cause)


func _on_player_ate(_amount: float) -> void:
	ate.emit()


func _read_move_input() -> Vector2:
	if hud.joystick.is_active():
		return hud.joystick.output
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		keys.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		keys.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		keys.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		keys.y += 1.0
	return keys.limit_length(1.0)
