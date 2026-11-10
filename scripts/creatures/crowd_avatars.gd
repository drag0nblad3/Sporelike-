class_name CrowdAvatars
extends Node3D
## A small pool of full Animals lent to the CrowdActors nearest the camera,
## so the ones the player sees up close walk on real legs while the cost
## stays fixed however big the crowd is. Chosen again a few times a
## second; an Animal that already wears the right body is reused without
## rebuilding its look. off: lend none (the overhead view).

const POOL := 5
const NEAR := 24.0
const EVERY := 0.4

var off := false
var _pool: Array[Animal] = []
var _users: Array[CrowdActor] = []
var _wait := 0.0


func _ready() -> void:
	for k in POOL:
		_pool.append(null)
		_users.append(null)


func update(actors: Array[CrowdActor], focus: Vector3, delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = EVERY
	var wanted: Array[CrowdActor] = []
	if not off:
		for actor in actors:
			if actor.alive and actor.flat_to(focus) < NEAR:
				wanted.append(actor)
		if wanted.size() > POOL:
			wanted.sort_custom(func(a: CrowdActor, b: CrowdActor) -> bool:
				return a.flat_to(focus) < b.flat_to(focus))
			wanted.resize(POOL)
	for k in POOL:
		var user := _users[k]
		if user != null and not wanted.has(user):
			_release(k)
	for actor in wanted:
		if actor.avatar == null:
			_lend(actor)


## Takes the body back from an actor at once (it died or changed role).
func drop(actor: CrowdActor) -> void:
	var k := _users.find(actor)
	if k >= 0:
		_release(k)


## Stops every lent body where it stands (the game is paused on a screen).
func halt() -> void:
	for animal in _pool:
		if animal != null:
			animal.move_input = Vector2.ZERO


func _lend(actor: CrowdActor) -> void:
	var pick := -1
	for k in POOL:
		if _users[k] != null:
			continue
		if _pool[k] != null and _pool[k].body == actor.body:
			pick = k
			break
		if pick == -1 or _pool[pick] != null and _pool[k] == null:
			pick = k
	if pick == -1:
		return
	var animal := _pool[pick]
	if animal == null:
		animal = Animal.new()
		animal.heading = actor.heading
		animal.build(actor.body, actor.pos)
		add_child(animal)
		_pool[pick] = animal
	elif animal.body == actor.body:
		animal.place(actor.pos, actor.heading)
	else:
		animal.heading = actor.heading
		animal.build(actor.body, actor.pos)
	animal.visible = true
	animal.set_physics_process(true)
	animal.set_process(true)
	_users[pick] = actor
	actor.avatar = animal


func _release(k: int) -> void:
	var animal := _pool[k]
	animal.visible = false
	animal.move_input = Vector2.ZERO
	animal.set_physics_process(false)
	animal.set_process(false)
	_users[k].avatar = null
	_users[k] = null
