class_name HunterKind
extends RefCounted
## The kinds of hunter in the sea, each a real single-celled predator with
## its own body, numbers and hunting style. Each kind evolves as its own
## HunterLineage.

const CHASER := "chaser"
const AMBUSHER := "ambusher"
const PACK := "pack"
const FILTER := "filter"

## id -> plural name, how many swim at once, body radius, share of that
## radius prey must be under to be swallowed, body tint, and genome traits.
const KINDS := {
	CHASER: ["Didinia", 4, 1.2, 0.85, Color(1.0, 0.3, 0.25, 0.7),
		{"size": 1.0, "speed": 0.45, "agility": 0.3, "sense": 0.55, "jaw": 1.0}],
	AMBUSHER: ["Heliozoa", 3, 1.0, 0.95, Color(0.62, 0.2, 0.22, 0.55),
		{"size": 0.8, "speed": 0.2, "agility": 0.2, "sense": 0.6, "jaw": 0.6}],
	PACK: ["Swarm dinoflagellates", 3, 0.8, 0.85, Color(1.0, 0.5, 0.55, 0.75),
		{"size": 0.5, "speed": 0.8, "agility": 0.75, "sense": 0.5, "jaw": 0.5}],
	FILTER: ["Stentors", 1, 2.2, 0.45, Color(0.8, 0.25, 0.6, 0.6),
		{"size": 1.0, "speed": 0.1, "agility": 0.1, "sense": 0.3, "jaw": 0.0}],
}


static func ids() -> Array:
	return KINDS.keys()


static func plural(kind: String) -> String:
	return str(KINDS[kind][0])


static func count(kind: String) -> int:
	return int(KINDS[kind][1])


static func radius(kind: String) -> float:
	return float(KINDS[kind][2])


static func swallow(kind: String) -> float:
	return float(KINDS[kind][3])


static func tint(kind: String) -> Color:
	var c: Color = KINDS[kind][4]
	return c


static func genome(kind: String) -> Genome:
	var g := Genome.new()
	var traits: Dictionary = KINDS[kind][5]
	for t in traits:
		g.values[t] = float(traits[t])
	g.values["armor"] = 0.0
	g.values["toxin"] = 0.0
	return g


## The biggest prey radius any hunter can swallow before upgrades.
static func biggest_meal() -> float:
	var best := 0.0
	for kind in KINDS:
		best = maxf(best, radius(kind) * swallow(kind))
	return best
