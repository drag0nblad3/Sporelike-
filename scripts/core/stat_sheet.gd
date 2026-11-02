class_name StatSheet
extends RefCounted
## Turns a Genome into concrete numbers with units, for upgrade buttons, the
## HUD and the population screen. One world unit is 10 micrometres (µm).

const MICRONS := 10.0
## Row id -> [label, format]. Values come from measure().
const ROWS := {
	"body": ["Body", "%d µm"],
	"speed": ["Top speed", "%d µm/s"],
	"turn": ["Turning", "%d°/s"],
	"accel": ["Pickup", "%d µm/s²"],
	"sight": ["Sight", "%d µm"],
	"grab": ["Grab reach", "%d µm"],
	"sticky": ["Sticky reach", "%d µm"],
	"chew": ["Chewing speed", "%d%%"],
	"armor": ["Blocks bites", "%d%%"],
	"toxin": ["Stings hunters", "%d%%"],
	"plants": ["From plants", "%d%%"],
	"meat": ["From meat", "%d%%"],
	"jaw": ["Bite force", "%d µN"],
	"store": ["Stomach", "%d energy"],
	"others": ["Hunters & food speed", "%d%%"],
	"upkeep": ["Energy use", "%.1f/min"],
}
## Which row best describes each trait on its own.
const TRAIT_ROW := {
	"size": "body", "speed": "speed", "agility": "turn", "sense": "sight",
	"armor": "armor", "toxin": "toxin", "diet": "meat", "jaw": "jaw",
}


## A genome with these average trait values, to describe a whole species.
static func typical(averages: Dictionary) -> Genome:
	var g := Genome.new()
	for t in Genome.TRAITS:
		g.values[t] = float(averages.get(t, g.values[t]))
	return g


static func measure(g: Genome) -> Dictionary:
	return {
		"body": g.radius() * MICRONS,
		"speed": g.max_speed() * MICRONS,
		"turn": rad_to_deg(g.turn_rate()),
		"accel": g.acceleration() * MICRONS,
		"sight": g.sense_range() * MICRONS,
		"grab": g.grab_reach() * MICRONS,
		"sticky": Feature.STICKY_REACH * g.feature("sticky_coat") * MICRONS,
		"chew": (0.7 + g.value_of("size")) * 100.0,
		"armor": g.armor() * 100.0,
		"toxin": g.toxin() * 100.0,
		"plants": g.digest(1.0, true) * 100.0,
		"meat": g.digest(1.0, false) * 100.0,
		"jaw": g.value_of("jaw") * 100.0,
		"store": g.max_energy(),
		"others": Pace.others(g.value_of("speed")) * 100.0,
		"upkeep": g.upkeep() * 60.0,
	}


static func text(row: String, value: float) -> String:
	var spec: Array = ROWS[row]
	var fmt: String = spec[1]
	return fmt % value


## "Top speed 59 µm/s" for the row that stands for this trait.
static func trait_text(trait_name: String, g: Genome) -> String:
	var row: String = TRAIT_ROW[trait_name]
	var spec: Array = ROWS[row]
	var label: String = spec[0]
	return "%s %s" % [label, text(row, measure(g)[row])]


## One line per number that changes from before to after, such as
## "Top speed 59 → 62 µm/s", ending with the energy cost.
static func changes(before: Genome, after: Genome) -> PackedStringArray:
	var a := measure(before)
	var b := measure(after)
	var lines := PackedStringArray()
	for row in ROWS:
		var old_text := text(row, a[row])
		var new_text := text(row, b[row])
		if old_text == new_text:
			continue
		var spec: Array = ROWS[row]
		var label: String = spec[0]
		var unit := new_text.substr(new_text.find(" ")) if " " in new_text else ""
		var old_num := old_text.trim_suffix(unit)
		var new_num := new_text.trim_suffix(unit)
		lines.append("%s %s → %s%s" % [label, old_num, new_num, unit])
	var limit := hunter_limit()
	if before.radius() < limit and after.radius() >= limit:
		lines.append("Too big for hunters to swallow")
	elif before.radius() >= limit and after.radius() < limit:
		lines.append("Small enough for hunters to swallow")
	return lines


## Bodies at least this big are too large for hunters (see Predator.wants).
static func hunter_limit() -> float:
	return Predator.make_genome().radius() * Predator.SWALLOW_RATIO
