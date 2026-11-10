class_name ApexHunt
extends Node3D
## The stage 2 boss: once the player's colony is big enough, its sea's
## ApexKind turns up nearby and hunts it (ApexBrain). Anyone may bite the
## apex whatever its size, and it dies sooner than other colonies
## (ApexKind.FATAL_SHARE). Its death leaves a feast of remains and pays
## out once per run (slain); it never comes back after that.

## The apex was bitten to death.
signal slain(title: String)
## The apex turned up (the HUD names it).
signal appeared(title: String)

const SPAWN_DISTANCE := 30.0
## Wanders off (and turns up again later) beyond this.
const DESPAWN := 90.0
const THINK_EVERY := 0.25

var world: ColonyWorld
var ecosystem: Ecosystem
var rng := RandomNumberGenerator.new()
var apex: Colony
var kind: ApexKind
var done := false
var _home := Vector2.ZERO
var _think_timer := 0.0


func clear() -> void:
	if is_instance_valid(apex):
		apex.queue_free()
	apex = null


## Called every physics frame by ColonyPilot. Returns [energy the player
## ate from the apex, outcome of the apex's bite on the player or ""].
func step(player: Colony, delta: float) -> Array:
	if done:
		return [0.0, ""]
	if not is_instance_valid(apex):
		if player.plan.parts.size() >= ApexKind.APPEAR_AT:
			_spawn(player)
		return [0.0, ""]
	var pc := player.center()
	if apex.center().distance_to(pc) > DESPAWN:
		clear()
		return [0.0, ""]
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = THINK_EVERY
		ApexBrain.think(apex, _home, player, ecosystem)
	world.rocks.push_out(apex)
	apex.energy = maxf(apex.energy, apex.max_energy() * 0.5)
	var mine := ColonyBites.attempt(player, apex, rng, true)
	var theirs := ColonyBites.attempt(apex, player, rng)
	if fatal(apex):
		_die()
	return [float(mine[1]), str(theirs[0])]


static func fatal(colony: Colony) -> bool:
	return float(colony.wounds.lost.size()) \
		>= ApexKind.FATAL_SHARE * float(colony.wounds.full_size(colony))


func to_dict() -> Dictionary:
	return {"slain": done}


func load_data(data: Dictionary) -> void:
	done = bool(data.get("slain", false))


func _spawn(player: Colony) -> void:
	kind = ApexKind.for_sea(Sea.current().id)
	var c := player.center()
	_home = Vector2(c.x, c.z) + Vector2.from_angle(rng.randf() * TAU) * SPAWN_DISTANCE
	var cells := mini(player.plan.parts.size() + ApexKind.EXTRA_CELLS, BodyPlan.MAX_CELLS)
	apex = Colony.new()
	apex.tint = kind.tint
	apex.nucleus = kind.tint.darkened(0.5)
	apex.facing = rng.randf() * TAU
	apex.build(kind.make_plan(cells, rng), Vector3(_home.x, 0.0, _home.y))
	apex.energy = apex.max_energy()
	add_child(apex)
	appeared.emit(kind.title)


func _die() -> void:
	done = true
	var at := apex.center()
	var cells := apex.wounds.full_size(apex) * ApexKind.FEAST
	world.drop_carrion(at, cells)
	clear()
	slain.emit(kind.title)
