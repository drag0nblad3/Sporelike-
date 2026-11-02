class_name PickRoller
extends RefCounted
## Deals the upgrade choices between generations. Each offer is random, but
## upgrades that match how the player played (see Habits) come up more
## often and say so on their card.

## A full-strength hint makes an upgrade this many times likelier.
const HINT_WEIGHT := 4.0
## Hints at least this strong are named on the card.
const SHOW_REASON := 0.3
## Chance one choice is an organelle, when any is available; strong
## organelle hints raise it by up to FEATURE_BOOST.
const FEATURE_CHANCE := 0.6
const FEATURE_BOOST := 0.3
## The plain energy-saving pick: how often it is one of the choices.
const EFFICIENCY_CHANCE := 0.5


## A few different choices: trait increases (diet either way), sometimes an
## organelle the species has unlocked, sometimes Leaner metabolism. Traits
## already at the top of their scale are not offered.
static func roll(rng: RandomNumberGenerator, count: int, averages: Dictionary,
		template: Genome, habits: Habits) -> Array[MutationChoice]:
	var picks: Array[MutationChoice] = []
	var unlocked := Feature.available(habits.with_habits(averages), template)
	var best := 0.0
	for id in unlocked:
		best = maxf(best, habits.feature_hint(id))
	if not unlocked.is_empty() and rng.randf() < FEATURE_CHANCE + FEATURE_BOOST * best:
		var f := MutationChoice.new()
		f.feature_id = _ordered(rng, unlocked, habits.feature_hint)[0]
		if habits.feature_hint(f.feature_id) >= SHOW_REASON:
			f.reason = habits.feature_reason(f.feature_id)
		picks.append(f)
	if template.efficiency < 1.0 and rng.randf() < EFFICIENCY_CHANCE:
		var e := MutationChoice.new()
		e.trait_name = "efficiency"
		picks.append(e)
	for t in _ordered(rng, Genome.TRAITS, habits.trait_hint):
		if picks.size() >= count:
			break
		var c := _trait_choice(rng, t, template, habits)
		if c:
			picks.append(c)
	return picks


static func _trait_choice(rng: RandomNumberGenerator, trait_name: String,
		template: Genome, habits: Habits) -> MutationChoice:
	var c := MutationChoice.new()
	c.trait_name = trait_name
	var value: float = template.values[trait_name]
	if trait_name == "diet":
		var lean := habits.diet_lean()
		if absf(lean) >= HabitDrift.MIN_HINT:
			c.direction = signf(lean)
		else:
			c.direction = 1.0 if rng.randf() < 0.5 else -1.0
		if (c.direction > 0.0 and value >= 1.0) or (c.direction < 0.0 and value <= 0.0):
			c.direction = -c.direction
	elif value >= 1.0:
		return null
	# Only name the habit when the pick goes the way the habit points.
	var lean_agrees := trait_name != "diet" or signf(habits.diet_lean()) == c.direction
	if lean_agrees and habits.trait_hint(trait_name) >= SHOW_REASON:
		c.reason = habits.trait_reason(trait_name)
	return c


## The ids in a random order where higher-hint ids tend to come first
## (weighted shuffle: each draws key = u^(1/weight), largest first).
static func _ordered(rng: RandomNumberGenerator, ids: Array, hint: Callable) -> Array:
	var keyed := []
	for id in ids:
		var weight := 1.0 + HINT_WEIGHT * float(hint.call(id))
		keyed.append([pow(rng.randf(), 1.0 / weight), id])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var out := []
	for pair in keyed:
		out.append(pair[1])
	return out
