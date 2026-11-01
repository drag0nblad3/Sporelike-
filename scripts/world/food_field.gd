class_name FoodField
extends Node3D
## All food in the loaded part of the world. Each FoodPatch regrows its own
## pieces at its kind's pace, so a big population runs short and has to
## compete. Patches arrive and leave with their chunks. A FoodGrid keeps
## lookups local.

const STARTLE_RANGE := 2.5
## Organisms are never bigger than this, so it bounds the eating reach.
const MAX_REACH := 3.5

var rng: RandomNumberGenerator
var patches: Array[FoodPatch] = []

var _meshes := {}
var _materials := {}
var _grid := FoodGrid.new()


func setup(random: RandomNumberGenerator) -> void:
	rng = random


func _ready() -> void:
	for kind in FoodKind.all():
		_meshes[kind.id] = FoodLook.mesh_for(kind)
		for tier in FoodItem.TIERS:
			_materials["%s%d" % [kind.id, tier]] = FoodLook.material_for(kind, tier, false)
			_materials["%s%dh" % [kind.id, tier]] = FoodLook.material_for(kind, tier, true)


func _process(delta: float) -> void:
	for patch in patches:
		if patch.count >= patch.target:
			continue
		patch.regrow_timer -= delta
		if patch.regrow_timer <= 0.0:
			patch.regrow_timer = patch.kind.regrow_interval
			_spawn(patch)


## Starts growing food in these patches, fully stocked.
func add_patches(new_patches: Array[FoodPatch]) -> void:
	for patch in new_patches:
		patches.append(patch)
		for _i in patch.target - patch.count:
			_spawn(patch)
	refresh()


## Removes these patches and every piece of food in them.
func remove_patches(old_patches: Array[FoodPatch]) -> void:
	for patch in old_patches:
		patches.erase(patch)
	for child in get_children():
		var item := child as FoodItem
		if item.home in old_patches:
			item.queue_free()
	refresh()


## Re-buckets all food. The ecosystem calls this once per physics frame.
func refresh() -> void:
	_grid.rebuild(get_children())


## Darting food flees from any of these organisms that come close, unless
## one has a sticky coat and the food is within its sticky reach: then the
## food is stuck where it is.
func startle_near(movers: Array[Organism]) -> void:
	for org in movers:
		var t := org.flat_pos()
		var sticky := org.genome.feature("sticky_coat")
		var stick_reach := org.radius() + 0.8 * sticky
		for item in _grid.near(t, STARTLE_RANGE):
			if item.flee_speed <= 0.0:
				continue
			var d := item.flat_pos().distance_to(t)
			if sticky > 0 and d < stick_reach:
				item.velocity = Vector2.ZERO
			elif d < STARTLE_RANGE:
				item.startle(t)


## The most worthwhile food this organism can notice and digest, or null.
func best_for(org: Organism) -> FoodItem:
	var best: FoodItem = null
	var best_score := 0.0
	var me := org.flat_pos()
	for item in _grid.near(me, org.genome.sense_range()):
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
	for item in _grid.near(me, MAX_REACH):
		if item.is_queued_for_deletion():
			continue
		var reach := org.radius() + item.kind.size + org.genome.grab_reach()
		if me.distance_squared_to(item.flat_pos()) > reach * reach:
			continue
		var crack := org.genome.crack_time(item.hardness)
		if crack == INF or (crack > 0.0 and not item.chew_for(delta, crack)):
			continue
		gained += org.genome.digest(item.energy, item.kind.is_plant)
		item.home.count -= 1
		item.queue_free()
	return gained


func _spawn(patch: FoodPatch) -> void:
	var kind := patch.kind
	var item := FoodItem.new()
	item.roll(kind, rng)
	item.home = patch
	item.mesh = _meshes[kind.id]
	if patch.hidden:
		item.visibility *= FoodPatch.HIDDEN_VISIBILITY
		item.energy *= FoodPatch.HIDDEN_RICHNESS
	var key := "%s%d%s" % [kind.id, item.tier(), "h" if patch.hidden else ""]
	item.material_override = _materials[key]
	var p := patch.random_point(rng)
	item.position = Vector3(p.x, 0.0, p.y)
	add_child(item)
	patch.count += 1
