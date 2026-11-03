class_name AbilityCaster
extends RefCounted
## Fires active abilities (see Ability) for the player and AI cells alike:
## checks the recharge and energy, applies the effect to nearby hunters and
## food, and shows it with AbilityFx.

## How hard Trichocysts throw a hunter, in units per second.
const SHOVE_SPEED := 14.0
## Seconds a Scintillons flash dazzles nearby hunters.
const DAZZLE := 1.0


## Uses the ability if this body has it, it is recharged and the cell can
## pay for it. Returns whether it fired.
static func fire(user: Organism, id: String, eco: Ecosystem) -> bool:
	if not Ability.has(user.genome, id) or not user.abilities.ready(id):
		return false
	var cost := Ability.cost(id)
	if cost > 0.0 and user.energy <= cost * 2.0:
		return false
	var level := user.genome.feature(id)
	if not apply(user, id, eco, level):
		return false
	user.energy -= cost
	user.abilities.start(id, Ability.cooldown(id, level))
	return true


## The effect alone, at a given level (CI's smoke test calls it directly).
## Returns false if there was nothing to hit, so no charge is spent.
static func apply(user: Organism, id: String, eco: Ecosystem, level: int) -> bool:
	match id:
		"jet":
			user.start_jet()
		"trichocysts":
			_shove(user, eco, level)
		"toxicysts":
			return _harpoon(user, eco, level)
		"flash":
			_flash(user, eco, level)
	return true


## AI cells: the best ability against a hunter this far away, if any.
static func defend(user: Organism, eco: Ecosystem, threat: Predator) -> void:
	var gap := user.flat_pos().distance_to(threat.flat_pos()) - threat.radius() - user.radius()
	for id in ["trichocysts", "toxicysts", "flash"]:
		var level := user.genome.feature(id)
		if level > 0 and gap < Ability.reach(id, level) * 0.6 and fire(user, id, eco):
			return
	if gap < 2.0:
		fire(user, "jet", eco)


static func _shove(user: Organism, eco: Ecosystem, level: int) -> void:
	var me := user.flat_pos()
	var reach := Ability.reach("trichocysts", level) + user.radius()
	for p in eco.predators:
		var away := p.flat_pos() - me
		if away.length() > reach + p.radius():
			continue
		var push := away.normalized() * SHOVE_SPEED
		p.velocity += Vector3(push.x, 0.0, push.y)
		p.stun_time = maxf(p.stun_time, Ability.hold("trichocysts", level))
	AbilityFx.ring(user, reach, OrganelleParts.COLORS["trichocysts"])


static func _harpoon(user: Organism, eco: Ecosystem, level: int) -> bool:
	var me := user.flat_pos()
	var reach := Ability.reach("toxicysts", level) + user.radius()
	var hits: Array = []
	for p in eco.predators:
		if p.alive and not p.dormant and me.distance_to(p.flat_pos()) <= reach + p.radius():
			hits.append(p)
	hits.append_array(eco.food.darting_near(me, reach))
	if hits.is_empty():
		return false
	hits.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return user.global_position.distance_squared_to(a.global_position) \
			< user.global_position.distance_squared_to(b.global_position))
	var hold := Ability.hold("toxicysts", level)
	for i in mini(hits.size(), Ability.targets(level)):
		var target: Node3D = hits[i]
		if target is Organism:
			var org := target as Organism
			org.stun_time = maxf(org.stun_time, hold)
		elif target is FoodItem:
			(target as FoodItem).paralyze(hold)
		AbilityFx.dart(user, target, OrganelleParts.COLORS["toxicysts"])
	return true


static func _flash(user: Organism, eco: Ecosystem, level: int) -> void:
	var me := user.flat_pos()
	var reach := Ability.reach("flash", level) + user.radius()
	for p in eco.predators:
		if me.distance_to(p.flat_pos()) <= reach + p.radius():
			p.stun_time = maxf(p.stun_time, DAZZLE)
	user.hidden_time = Ability.hold("flash", level)
	AbilityFx.glow(user, reach, OrganelleParts.COLORS["flash"])
