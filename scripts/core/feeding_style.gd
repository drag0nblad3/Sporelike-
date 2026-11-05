class_name FeedingStyle
extends RefCounted
## How a colony makes its living, picked once early in the multicellular
## stage: a filter feeder sweeps drifting food in from farther away, a
## grazer gets more from seaweed, a hunter swallows bigger cells and bites
## other colonies. Each pushes the body toward a niche and costs something.

const FILTER := "filter"
const GRAZER := "grazer"
const HUNTER := "hunter"
const ALL := [FILTER, GRAZER, HUNTER]
## The stage 2 generation whose pick screen offers the choice.
const OFFER_AT := 2

## id -> [name, what it is]
const INFO := {
	FILTER: ["Filter feeder", "Beating cilia around the mouth pull drifting food in."],
	GRAZER: ["Grazer", "A rasping mouth scrapes seaweed and the films on it."],
	HUNTER: ["Hunter", "A wide, muscular mouth grabs other living things."],
}


static func title(id: String) -> String:
	var row: Array = INFO.get(id, ["", ""])
	return row[0]


## How far past a mouth cell food is pulled in, in world units.
static func mouth_reach(id: String) -> float:
	return 1.6 if id == FILTER else 0.7


## Multiplies the colony's swimming push.
static func swim_factor(id: String) -> float:
	return 0.75 if id == FILTER else 1.0


## Multiplies energy from seaweed buds.
static func seaweed_factor(id: String) -> float:
	match id:
		GRAZER:
			return 2.0
		HUNTER:
			return 0.5
	return 1.0


## Multiplies energy from loose food in the water.
static func food_factor(id: String) -> float:
	return 0.5 if id == HUNTER else 1.0


## Largest single cell (radius) the mouth can swallow; 0 means none.
static func prey_radius(id: String) -> float:
	match id:
		GRAZER:
			return 0.0
		HUNTER:
			return 2.2
	return 1.4


## Extra energy for swallowing a whole cell.
static func prey_bonus(id: String) -> float:
	return 6.0 if id == HUNTER else 3.0


## Another colony can be bitten when it has at most this share of our cells.
static func bite_ratio(id: String) -> float:
	return 1.25 if id == HUNTER else 0.9


static func card_text(id: String) -> String:
	var um := StatSheet.MICRONS
	var row: Array = INFO[id]
	var about: String = row[1]
	match id:
		FILTER:
			return "%s\nMouths pull in food from %d µm (was %d µm). Swims 25%% slower." % [
				about, mouth_reach(id) * um, mouth_reach("") * um]
		GRAZER:
			return "%s\nSeaweed buds give 2x energy. Can no longer swallow single cells." % about
	return ("%s\nSwallows cells up to %d µm across with +%d bonus energy, and bites colonies "
		+ "up to 25%% bigger than you. Seaweed gives half, loose food gives half.") % [
			about, prey_radius(id) * 2.0 * um, prey_bonus(id)]
