class_name Ability
extends RefCounted
## Active abilities, each fired from its own HUD button: the Jet every cell
## is born with, and the organelles that add a button (Trichocysts,
## Toxicysts, Scintillons). Holds each one's numbers per level, for
## AbilityCaster and the pick cards. Distances are world units (10 µm).

const ALL := ["jet", "trichocysts", "toxicysts", "flash"]
## Short names for the HUD buttons.
const BUTTON := {"jet": "Jet", "trichocysts": "Shove", "toxicysts": "Harpoon", "flash": "Flash"}
## Energy each use costs.
const COST := {"jet": 0.0, "trichocysts": 0.6, "toxicysts": 0.5, "flash": 0.4}
## Seconds a jet burst lasts.
const JET_TIME := 0.35


static func is_ability(id: String) -> bool:
	return id in ALL


## Whether this body can use the ability: every cell has a Jet.
static func has(g: Genome, id: String) -> bool:
	return id == "jet" or g.feature(id) > 0


static func owned(g: Genome) -> Array[String]:
	var list: Array[String] = []
	for id in ALL:
		if has(g, id):
			list.append(id)
	return list


static func cost(id: String) -> float:
	return float(COST[id])


## Seconds before the ability can be used again.
static func cooldown(id: String, level: int) -> float:
	match id:
		"jet":
			return 4.5 - 1.5 * level
		"trichocysts":
			return 10.0 - 2.0 * maxi(level - 1, 0)
		"toxicysts":
			return 8.0 - 2.0 * maxi(level - 1, 0)
	return 14.0


## How far the ability reaches from the cell's edge.
static func reach(id: String, level: int) -> float:
	match id:
		"trichocysts":
			return 3.5 + 1.0 * level
		"toxicysts":
			return 6.0 + 2.0 * level
		"flash":
			return 9.0
	return 0.0


## Seconds a hit hunter is stunned (for Scintillons: seconds no hunter can
## find you).
static func hold(id: String, level: int) -> float:
	match id:
		"trichocysts":
			return 2.0 + 0.5 * maxi(level - 1, 0)
		"toxicysts":
			return 3.0 + 1.5 * maxi(level - 1, 0)
		"flash":
			return 4.0
	return 0.0


## How many things one Toxicyst volley hits.
static func targets(level: int) -> int:
	return 1 + level


## The pick card's description, with the numbers at the new level and,
## for the Jet, what it was before.
static func card_text(id: String, level: int, before: int) -> String:
	var um := StatSheet.MICRONS
	var tail := "Recharges in %d s, costs %.1f energy" % [cooldown(id, level), cost(id)]
	match id:
		"jet":
			return "Your Jet recharges in %.1f s (was %.1f s)" % [
				cooldown(id, level), cooldown(id, before)]
		"trichocysts":
			return ("Tap Shove: spindles shoot out, pushing hunters within %d µm away "
				+ "and stunning them %.1f s. ") % [reach(id, level) * um, hold(id, level)] + tail
		"toxicysts":
			return ("Tap Harpoon: poison darts paralyze the %d nearest hunters or darting "
				+ "food within %d µm for %.1f s. ") % [
					targets(level), reach(id, level) * um, hold(id, level)] + tail
		"flash":
			return ("Tap Flash: a burst of light dazzles hunters within %d µm for 1 s, "
				+ "and no hunter can find you for %d s. ") % [
					reach(id, level) * um, hold(id, level)] + tail
	return ""
