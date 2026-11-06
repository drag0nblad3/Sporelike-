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
var _cues := SenseCues.new()
var _feel := PlayerFeel.new()
## Whether the player has been told it can swallow small cells.
var _told_swallow := false
var _swallow_check := 1.0


func _ready() -> void:
	add_child(_scent)
	add_child(_cues)
	add_child(_feel)
	ecosystem.food.eaten.connect(_on_food_eaten)
	ecosystem.player_swallowed.connect(_on_swallowed)
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
	player.bite_blocked.connect(func(how: String) -> void: _feel.bite_blocked(player, how))
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
		_cues.clear()
		return
	_scent.track(player, ecosystem.food, delta)
	_cues.track(player, ecosystem, camera, delta)
	var input := _read_move_input()
	if input.length() > 0.1:
		_has_moved = true
	player.move_input = input
	camera.follow(player.position, player.radius(), delta)
	hud.show_status(player.energy, Genome.FULL_ENERGY, player.genome.max_energy())
	hud.show_abilities(player.genome, player.abilities)
	_hint_swallowing(delta)
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
	if is_alive() and AbilityCaster.fire(player, id, ecosystem):
		_feel.ability(id)


func _hint_swallowing(delta: float) -> void:
	_swallow_check -= delta
	if _told_swallow or _swallow_check > 0.0:
		return
	_swallow_check = 1.0
	if CellEngulf.any_edible_near(ecosystem):
		_told_swallow = true
		hud.flash_message("That cell is under half your size: swim into it to swallow it", 4.0)


func _smoke_abilities(delta: float) -> void:
	_smoke_timer -= delta
	if _smoke_timer > 0.0:
		return
	_smoke_timer = 1.5
	for id in Ability.ALL:
		AbilityCaster.apply(player, id, ecosystem, 2)


func _on_player_died(_org: Organism, cause: String) -> void:
	_feel.died()
	died.emit(cause)


func _on_player_ate(amount: float) -> void:
	ate.emit(amount)


## Food pieces: the streak bonus, and the prize morsel fanfare.
func _on_food_eaten(org: Organism, item: FoodItem, energy: float) -> void:
	if org != player or not is_alive():
		return
	if item.prize:
		_feel.prize(player, energy)
	var extra := _feel.meal(player, energy)
	if extra > 0.0:
		# Added straight to the bar so it does not count as another meal.
		player.energy = minf(player.energy + extra, player.genome.max_energy())
		ate.emit(extra)


func _on_swallowed(energy: float) -> void:
	_feel.swallowed(player, energy)


func _read_move_input() -> Vector2:
	return TouchSteer.read(hud.joystick)
