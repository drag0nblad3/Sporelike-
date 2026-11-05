class_name FinalBody
extends RefCounted
## The body a colony settles into at the end of the multicellular stage,
## once it has grown its full set of cells. Each is a real early animal
## body: a creeping sole (like Trichoplax), comb rows (like comb jellies)
## or a holdfast with a crown of tentacles (like a polyp). The pick ends the
## stage; the colony can keep playing with it afterwards.

const CRAWLER := "crawler"
const SWIMMER := "swimmer"
const ANCHOR := "anchor"
const ALL := [CRAWLER, SWIMMER, ANCHOR]

## id -> [name, what it is, colour]
const INFO := {
	CRAWLER: ["Creeping sole", "A flat underside of cilia glides over the sea floor. "
		+ "The first step toward crawling out of the water.", Color(0.55, 0.85, 0.6)],
	SWIMMER: ["Comb rows", "Rows of fused cilia beat in waves down the body, "
		+ "rowing it through open water.", Color(0.5, 0.75, 1.0)],
	ANCHOR: ["Holdfast", "A sticky stalk holds the body to rock while a crown "
		+ "of tentacles sweeps food in.", Color(0.95, 0.6, 0.5)],
}


static func title(id: String) -> String:
	var row: Array = INFO.get(id, ["", "", Color.WHITE])
	return row[0]


static func color(id: String) -> Color:
	var row: Array = INFO.get(id, ["", "", Color.WHITE])
	return row[2]


static func swim_factor(id: String) -> float:
	match id:
		SWIMMER:
			return 1.4
		ANCHOR:
			return 0.5
	return 1.0


static func upkeep_factor(id: String) -> float:
	return 0.75 if id == CRAWLER else 1.0


## Extra reach (world units) for every mouth cell.
static func reach_bonus(id: String) -> float:
	return 1.0 if id == ANCHOR else 0.0


static func card_text(id: String) -> String:
	var row: Array = INFO[id]
	var about: String = row[1]
	match id:
		CRAWLER:
			return about + "\nBody burns 25% less energy."
		SWIMMER:
			return about + "\nSwims 40% faster."
	return about + "\nMouths reach %d µm farther. Swims at half speed." % [
		reach_bonus(id) * StatSheet.MICRONS]
