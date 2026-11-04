class_name PlayerDirector
extends Node
## Owns the player's current body: spawning it, steering it from touch or
## keys, following it with the camera, and reporting its meals, habits and
## death.

signal died(cause: String)
signal ate(energy: float)
## Energy the body made without eating (photosynthesis, chemosynthesis).
signal made_energy(energy: float)

## Keyboard keys for the abilities, for the Windows build.
const KEYS := {KEY_SPACE: "jet", KEY_Q: "trichocysts", KEY_E: "toxicysts", KEY_R: "flash"}

var ecosystem: Ecosystem
var camera: CameraRig
var hud: Hud
var player: PlayerCell
var genome := Genome.new()

## Records what the player does each generation (see Habits).
var tracker := HabitTracker.new()

## CI ("-- --smoke"): fire every ability's effect now and then, owned or not.
var smoke_test := false

var _has_moved := false
var _smoke_timer := 0.5
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
	hud.show_abilities(player.genome, player.abilities)
	if smoke_test:
		_smoke_abilities(delta)
	for key in KEYS:
		if Input.is_physical_key_pressed(key):
			use(KEYS[key])


## Stops showing the how-to-swim hint (the player has moved on).
func hide_hint() -> void:
	_has_moved = true


## Called from the HUD's ability buttons (and the keys in KEYS).
func use(id: String) -> void:
	if is_alive():
		AbilityCaster.fire(player, id, ecosystem)


func _smoke_abilities(delta: float) -> void:
	_smoke_timer -= delta
	if _smoke_timer > 0.0:
		return
	_smoke_timer = 1.5
	for id in Ability.ALL:
		AbilityCaster.apply(player, id, ecosystem, 2)


func _on_player_died(_org: Organism, cause: String) -> void:
	died.emit(cause)


func _on_player_ate(amount: float) -> void:
	ate.emit(amount)


func _read_move_input() -> Vector2:
	return TouchSteer.read(hud.joystick)
