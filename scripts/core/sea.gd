class_name Sea
extends RefCounted
## One kind of sea. The world is a patchwork of regions of each kind
## (SeaMap). Each one shifts which food dominates, how much sunlight and
## vent chemistry there is to live on, how often and how hard the currents
## run, how plentiful food is, and the colours of the water. The run's
## starting sea (current) also sets how many of each hunter swim.

const DEFAULT := "shelf"

static var _current: Sea

var id := ""
var title := ""
var blurb := ""
## Short hint of which genes do well here.
var favors := ""
## Region noise cutoffs: algae below the first, then plankton, then motes,
## then shells (see ChunkGenerator.region_kind).
var cutoffs: Array[float] = [-0.2, 0.15, 0.4]
## Food kind of the meadow the run starts on.
var start_kind := "algae"
## Below this channel noise a spot is bare sand; above hidden_above a
## patch is faint and hard to sense.
var gap_below := -0.35
var hidden_above := 0.5
## Multipliers on photosynthesis (Chloroplasts) and vent chemistry (Vent
## symbionts), and on how much food grows back.
var light := 1.0
var vents := 1.0
var food := 1.0
## Share of chunks holding a current, and a multiplier on its speed.
var current_chance := 0.5
var current_speed := 1.0
## Hunter kind -> how many swim at once, where it differs from HunterKind.
var hunters := {}
var water := Color(0.02, 0.07, 0.12)
var ambient := Color(0.3, 0.55, 0.65)
var sun := Color(0.75, 0.9, 1.0)
var sun_energy := 1.0
var floor_color := Color(0.05, 0.2, 0.25)


## The sea of the run in progress. The world reads it as it is built.
static func current() -> Sea:
	if _current == null:
		_current = Sea.of(DEFAULT)
	return _current


static func use(sea_id: String) -> void:
	_current = Sea.of(sea_id)


static func ids() -> Array[String]:
	var list: Array[String] = ["shelf", "lagoon", "vents", "upwelling", "deep"]
	return list


## The sea with this id; unknown ids (old saves) get the coastal shelf.
static func of(sea_id: String) -> Sea:
	var s := Sea.new()
	s.id = sea_id
	match sea_id:
		"lagoon":
			_lagoon(s)
		"vents":
			_vents(s)
		"upwelling":
			_upwelling(s)
		"deep":
			_deep(s)
		_:
			s.id = DEFAULT
			s.title = "Coastal shelf"
			s.blurb = "A bit of everything: algae meadows, plankton water, dark " \
				+ "trenches and vent beds, with gentle currents."
			s.favors = "Any build"
	return s


## How many hunters of this kind swim in this sea.
func hunter_count(kind: String) -> int:
	return int(hunters.get(kind, HunterKind.count(kind)))


static func _lagoon(s: Sea) -> void:
	s.title = "Sunlit lagoon"
	s.blurb = "Warm, shallow and bright. Algae meadows everywhere, still water, " \
		+ "and Heliozoa lying in wait among the food."
	s.favors = "Chloroplasts (1.6x sunlight), grazers"
	s.cutoffs = [0.05, 0.4, 0.6]
	s.light = 1.6
	s.vents = 0.8
	s.current_chance = 0.35
	s.current_speed = 0.8
	s.hunters = {HunterKind.AMBUSHER: 4, HunterKind.CHASER: 4}
	s.water = Color(0.04, 0.16, 0.17)
	s.ambient = Color(0.45, 0.75, 0.65)
	s.sun = Color(1.0, 0.97, 0.85)
	s.sun_energy = 1.4
	s.floor_color = Color(0.12, 0.3, 0.26)


static func _vents(s: Sea) -> void:
	s.title = "Hydrothermal vents"
	s.blurb = "Dark, hot water rising from cracks in the floor. Rich shell beds, " \
		+ "dim light, and a giant Stentor or two."
	s.favors = "Vent symbionts (1.6x), strong jaws"
	s.cutoffs = [-0.4, -0.05, 0.25]
	s.start_kind = "motes"
	s.light = 0.6
	s.vents = 1.6
	s.food = 0.95
	s.current_chance = 0.55
	s.current_speed = 1.05
	s.hunters = {HunterKind.CHASER: 4, HunterKind.FILTER: 2}
	s.water = Color(0.06, 0.03, 0.04)
	s.ambient = Color(0.55, 0.32, 0.25)
	s.sun = Color(1.0, 0.55, 0.35)
	s.sun_energy = 0.55
	s.floor_color = Color(0.13, 0.07, 0.06)


static func _upwelling(s: Sea) -> void:
	s.title = "Upwelling coast"
	s.blurb = "Cold, nutrient-rich water welling up from below feeds huge plankton " \
		+ "blooms. Strong currents everywhere, and swarms of dinoflagellates."
	s.favors = "Speed and agility, catching plankton"
	s.cutoffs = [-0.3, 0.25, 0.5]
	s.start_kind = "plankton"
	s.light = 1.1
	s.food = 1.05
	s.current_chance = 0.7
	s.current_speed = 1.25
	s.hunters = {HunterKind.PACK: 5, HunterKind.AMBUSHER: 3}
	s.water = Color(0.03, 0.09, 0.14)
	s.ambient = Color(0.35, 0.55, 0.75)
	s.sun = Color(0.85, 0.92, 1.0)
	s.floor_color = Color(0.06, 0.18, 0.28)


static func _deep(s: Sea) -> void:
	s.title = "Twilight deep"
	s.blurb = "Cold and dim, far below the sunlit water. Food is scarce and " \
		+ "often faint, but hunters are fewer."
	s.favors = "Keen senses, Food scent, low upkeep"
	s.cutoffs = [-0.45, 0.0, 0.5]
	s.start_kind = "motes"
	s.gap_below = -0.28
	s.hidden_above = 0.4
	s.light = 0.6
	s.food = 0.9
	s.current_chance = 0.4
	s.current_speed = 0.9
	s.hunters = {HunterKind.CHASER: 4, HunterKind.AMBUSHER: 2, HunterKind.PACK: 2}
	s.water = Color(0.01, 0.02, 0.06)
	s.ambient = Color(0.2, 0.3, 0.55)
	s.sun = Color(0.5, 0.6, 1.0)
	s.sun_energy = 0.45
	s.floor_color = Color(0.03, 0.06, 0.12)
