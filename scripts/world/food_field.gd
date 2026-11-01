class_name FoodField
extends Node3D
## All food in the arena, of every FoodKind. Each kind regrows in its own
## zone at its own pace, so a big population runs short and has to compete.

const STARTLE_RANGE := 2.5

var arena_radius := 30.0
var rng: RandomNumberGenerator
var kinds: Array[FoodKind] = []

var _meshes := {}
var _materials := {}
var _counts := {}
var _timers := {}


func setup(arena: float, random: RandomNumberGenerator) -> void:
	arena_radius = arena
	rng = random


func _ready() -> void:
	kinds = FoodKind.all()
	for kind in kinds:
		_meshes[kind.id] = FoodLook.mesh_for(kind)
		for tier in FoodItem.TIERS:
			_materials["%s%d" % [kind.id, tier]] = FoodLook.material_for(kind, tier)
		_counts[kind.id] = 0
		_timers[kind.id] = 0.0
		for _i in kind.target_count:
			_spawn(kind)


func _process(delta: float) -> void:
	for kind in kinds:
		_timers[kind.id] -= delta
		if _timers[kind.id] <= 0.0 and _counts[kind.id] < kind.target_count:
			_timers[kind.id] = kind.regrow_interval
			_spawn(kind)


## Darting food flees from any of these positions that come close.
func startle_near(threats: Array[Vector2]) -> void:
	for child in get_children():
		var item := child as FoodItem
		if item.flee_speed <= 0.0:
			continue
		for t in threats:
			if item.flat_pos().distance_squared_to(t) < STARTLE_RANGE * STARTLE_RANGE:
				item.startle(t)
				break


## The most worthwhile food this organism can notice and digest, or null.
func best_for(org: Organism) -> FoodItem:
	var best: FoodItem = null
	var best_score := 0.0
	var me := org.flat_pos()
	for child in get_children():
		if child.is_queued_for_deletion():
			continue
		var item := child as FoodItem
		var crack := org.genome.crack_time(item.hardness)
		if crack == INF:
			continue
		var d := me.distance_to(item.flat_pos())
		if d > org.genome.notice_range(item.visibility):
			continue
		var score := org.genome.digest(item.energy, item.kind.is_plant) / (d + 1.0 + crack)
		if score > best_score:
			best_score = score
			best = item
	return best


## Eats everything within reach that the jaw cracks, or that it has chewed
## on for long enough. Returns the energy gained.
func consume_near(org: Organism, delta: float) -> float:
	var gained := 0.0
	var me := org.flat_pos()
	for child in get_children():
		if child.is_queued_for_deletion():
			continue
		var item := child as FoodItem
		var reach := org.radius() + item.kind.size
		if me.distance_squared_to(item.flat_pos()) > reach * reach:
			continue
		var crack := org.genome.crack_time(item.hardness)
		if crack == INF or (crack > 0.0 and not item.chew_for(delta, crack)):
			continue
		gained += org.genome.digest(item.energy, item.kind.is_plant)
		_counts[item.kind.id] -= 1
		item.queue_free()
	return gained


func _spawn(kind: FoodKind) -> void:
	var item := FoodItem.new()
	item.roll(kind, rng)
	item.arena_radius = arena_radius
	item.mesh = _meshes[kind.id]
	item.material_override = _materials["%s%d" % [kind.id, item.tier()]]
	var outer := minf(kind.zone_max, arena_radius - 1.0)
	var dist := sqrt(rng.randf_range(kind.zone_min * kind.zone_min, outer * outer))
	var p := Vector2.from_angle(rng.randf() * TAU) * dist
	item.position = Vector3(p.x, 0.0, p.y)
	add_child(item)
	_counts[kind.id] += 1
