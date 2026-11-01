extends Node3D
## Wires the game together: arena, ecosystem, the player's cell, camera, HUD.
## Game rules live in the classes under scripts/; keep this file thin.

const ARENA_RADIUS := 30.0
const RESPAWN_DELAY := 2.0

var ecosystem: Ecosystem
var player: PlayerCell
var player_genome := Genome.new()
var camera: CameraRig
var hud: Hud
var food_eaten := 0

var _respawn_timer := 0.0
var _has_moved := false


func _ready() -> void:
	add_child(Arena.new(ARENA_RADIUS))
	camera = CameraRig.new()
	add_child(camera)
	hud = Hud.new()
	add_child(hud)

	ecosystem = Ecosystem.new()
	ecosystem.setup(ARENA_RADIUS, player_genome)
	ecosystem.species_changed.connect(_refresh_species)
	add_child(ecosystem)

	_spawn_player()
	camera.snap_to(player.position)
	_refresh_species()


func _process(delta: float) -> void:
	if is_instance_valid(player) and player.alive:
		var input := _read_move_input()
		if input.length() > 0.1:
			_has_moved = true
		player.move_input = input
		camera.follow(player.position, player.radius(), delta)
		hud.show_status(player.energy, Organism.MAX_ENERGY, food_eaten)
	else:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_spawn_player()
	hud.set_hint_visible(not _has_moved)


func _spawn_player() -> void:
	player = PlayerCell.new()
	player.setup(player_genome, ARENA_RADIUS, 8.0)
	player.died.connect(_on_player_died)
	add_child(player)
	player.ate.connect(_on_player_ate)
	ecosystem.player = player


func _on_player_ate(_amount: float) -> void:
	food_eaten += 1


func _on_player_died(_org: Organism, cause: String) -> void:
	_respawn_timer = RESPAWN_DELAY
	if cause == "eaten":
		hud.flash_message("You were eaten! Respawning...", RESPAWN_DELAY)
	else:
		hud.flash_message("You starved! Respawning...", RESPAWN_DELAY)


func _refresh_species() -> void:
	hud.show_species(ecosystem.species.size(), ecosystem.births, ecosystem.trait_averages())


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
