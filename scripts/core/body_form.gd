class_name BodyForm
extends RefCounted
## Body forms: the overall shape of a species' cell, chosen once (on the
## first bonus pick, at Fed 200%) and then grown through MAX_LEVEL levels
## offered like organelles. Each is modelled on real microbes. Stored in
## Genome.features under its id, so it saves and inherits like an organelle.
## This file owns the numbers; FormLook draws the shapes.

const MAX_LEVEL := 3
## id -> [label, description, habit that makes it more likely]
const ALL := {
	"form_rod": ["Rod", "Long and narrow like Paramecium: slips through water fast, turns wide",
		"sprint"],
	"form_amoeboid": ["Amoeboid",
		"Shapeless like Amoeba: slow, but pseudopods reach out and wrap hard food", "tough"],
	"form_spiral": ["Spiral",
		"A corkscrew like Spirillum: drills through water, so currents barely move it", "turn"],
	"form_shelled": ["Shelled",
		"A chambered shell (test) like foraminifera: shrugs off bites, swims slower", "danger"],
	"form_disc": ["Disc",
		"Flat and wide like diatoms: lots of surface for chloroplasts and vent bacteria", "sun"],
}
## id -> stat -> value at levels 1, 2, 3. Multipliers unless noted.
## block (bite chance), store (energy) and reach (world units) are added.
const EFFECTS := {
	"form_rod": {"speed": [1.15, 1.32, 1.52], "turn": [0.8, 0.7, 0.62],
		"upkeep": [1.04, 1.08, 1.12]},
	"form_amoeboid": {"speed": [0.75, 0.72, 0.7], "chew": [1.4, 1.8, 2.3],
		"reach": [0.4, 0.8, 1.3], "upkeep": [1.03, 1.06, 1.09]},
	"form_spiral": {"drift": [0.5, 0.35, 0.2], "speed": [1.05, 1.1, 1.16],
		"turn": [0.92, 0.88, 0.85], "upkeep": [1.03, 1.06, 1.09]},
	"form_shelled": {"block": [0.25, 0.37, 0.5], "speed": [0.8, 0.76, 0.72],
		"store": [3.0, 6.0, 9.0], "upkeep": [1.06, 1.1, 1.14]},
	"form_disc": {"symbiont": [1.4, 1.8, 2.3], "drift": [1.3, 1.3, 1.3],
		"turn": [1.1, 1.18, 1.25], "upkeep": [1.02, 1.04, 1.06]},
}
## The form a rival species tends to take in each niche (see Niche).
const NICHE_FORMS := {
	"algae": ["form_disc", "form_rod"], "plankton": ["form_rod", "form_spiral"],
	"shells": ["form_shelled", "form_amoeboid"], "motes": ["form_amoeboid", "form_spiral"],
}
## Chance per generation that a rival species without a form takes one.
const RIVAL_CHANCE := 0.3


## The genome's form id, or "" while it is still round.
static func of(g: Genome) -> String:
	for id in ALL:
		if g.feature(id) > 0:
			return id
	return ""


static func label(id: String) -> String:
	var row: Array = ALL[id]
	return row[0]


## The same shape Feature.ALL rows have, so pick cards can treat a form
## level like an organelle level.
static func as_feature(id: String) -> Array:
	var row: Array = ALL[id]
	return [row[0], row[1], "", 0.0, MAX_LEVEL]


static func speed(g: Genome) -> float:
	return _value(g, "speed", 1.0)


static func turn(g: Genome) -> float:
	return _value(g, "turn", 1.0)


static func upkeep(g: Genome) -> float:
	return _value(g, "upkeep", 1.0)


static func chew(g: Genome) -> float:
	return _value(g, "chew", 1.0)


## Share of a water current's flow that carries this cell along.
static func drift(g: Genome) -> float:
	return _value(g, "drift", 1.0)


static func symbiont(g: Genome) -> float:
	return _value(g, "symbiont", 1.0)


static func block(g: Genome) -> float:
	return _value(g, "block", 0.0)


static func store(g: Genome) -> float:
	return _value(g, "store", 0.0)


static func reach(g: Genome) -> float:
	return _value(g, "reach", 0.0)


## Three different form choices for the bonus pick, likelier ones first
## when they suit the player's habits.
static func roll(rng: RandomNumberGenerator, count: int, habits: Habits) -> Array[MutationChoice]:
	var picks: Array[MutationChoice] = []
	for id in PickRoller._ordered(rng, ALL.keys(), habits.feature_hint):
		if picks.size() >= count:
			break
		var c := MutationChoice.new()
		c.feature_id = id
		if habits.feature_hint(id) >= PickRoller.SHOW_REASON:
			c.reason = habits.feature_reason(id)
		picks.append(c)
	return picks


## A form that suits this niche, for a rival species.
static func for_niche(niche: String, rng: RandomNumberGenerator) -> String:
	var options: Array = NICHE_FORMS.get(niche, ALL.keys())
	return options[rng.randi() % options.size()]


static func _value(g: Genome, stat: String, plain: float) -> float:
	var id := of(g)
	if id == "":
		return plain
	var row: Dictionary = EFFECTS[id]
	if not row.has(stat):
		return plain
	var levels: Array = row[stat]
	return float(levels[clampi(g.feature(id), 1, MAX_LEVEL) - 1])
