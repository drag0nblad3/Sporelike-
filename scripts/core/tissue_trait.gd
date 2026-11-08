class_name TissueTrait
extends RefCounted
## Tissue upgrades for the multicellular body, kept in BodyPlan.traits as
## id -> level (1 to MAX_LEVEL). Each refines one kind of cell, so it pays
## more the more of those cells the body has, or the whole body. A colony
## fed at least EARN_AT of what it burns gets one pick after its new cell.
## Holds every number; CellEffects, ColonySwim, ColonyAbility and
## ColonyWounds read them, and TissueText writes the cards.

const MAX_LEVEL := 3
## Fed share a generation needs to earn a tissue pick.
const EARN_AT := 1.0
## id -> [name, cell role it refines ("" = whole body), what it is]
const INFO := {
	"whips": ["Stronger whips", "flagellum", "Thicker whips with more motor proteins."],
	"cilia": ["Dense cilia", "skin", "Every skin cell grows a thicker coat of cilia."],
	"lens": ["Lensed eyespots", "eye", "A clear cap focuses light on each eyespot."],
	"plates": ["Mineral plates", "plate", "Plates harden with calcium carbonate."],
	"venom": ["Potent venom", "gland", "Stinging threads carry a stronger toxin."],
	"folds": ["Folded gut", "gut", "The gut lining folds to touch more of each meal."],
	"oil": ["Oil reserves", "storage", "Storage cells swell with oil droplets."],
	"lips": ["Ciliated lips", "mouth", "Cilia around each mouth cell sweep food in."],
	"healing": ["Stem cells", "", "Spare unspecialized cells replace lost ones."],
	"lean": ["Lean tissue", "", "Every cell runs on fewer mitochondria."],
}
## Per level: extra push per whip and per skin cell (a skin cell's cilia = 1).
const WHIP_PUSH := 1.0
const CILIA_PUSH := 0.3
## Per level: extra reach per eyespot (world units, 10 µm each).
const LENS_REACH := 2.0
## Per level: block chance on and beside a plate, and seconds of Curl.
const PLATE_BLOCK := 0.06
const NEAR_PLATE_BLOCK := 0.15
const CURL_TIME := 1.5
## Per level: seconds of stun, and energy added to each Sting.
const VENOM_STUN := 1.5
const VENOM_COST := 0.5
## Per level: meal share per digestive cell, and energy per storage cell.
const FOLD_DIGEST := 0.02
const OIL_ENERGY := 4.0
## Per level: extra mouth reach (world units).
const LIP_REACH := 0.3
## Per level: share of regrow time cut, and share of energy use cut.
const HEAL_SPEED := 0.25
const LEAN_UPKEEP := 0.1
## Tradeoffs per level. Extra energy use per refined cell (/s):
const CELL_UPKEEP := {"whips": 0.01, "cilia": 0.004, "lens": 0.01, "folds": 0.01, "lips": 0.01}
## Swimming push lost (plates and oil are heavy).
const PLATE_DRAG := 0.05
const OIL_DRAG := 0.03
## Whole-body energy use added by stem cells; energy store lost to lean tissue.
const HEAL_UPKEEP := 0.05
const LEAN_STORE := 0.08


static func level(plan: BodyPlan, id: String) -> int:
	return int(plan.traits.get(id, 0))


static func title(id: String) -> String:
	var row: Array = INFO[id]
	return row[0]


static func role(id: String) -> String:
	var row: Array = INFO[id]
	return row[1]


static func about(id: String) -> String:
	var row: Array = INFO[id]
	return row[2]


static func can_take(plan: BodyPlan, id: String) -> bool:
	var need := role(id)
	return level(plan, id) < MAX_LEVEL and (need == "" or plan.count(need) > 0)


## Raises `id` one level (up to MAX_LEVEL).
static func take(plan: BodyPlan, id: String) -> void:
	plan.traits[id] = mini(level(plan, id) + 1, MAX_LEVEL)


## Extra swimming push for one cell of `cell_role`.
static func extra_push(plan: BodyPlan, cell_role: String) -> float:
	match cell_role:
		"flagellum":
			return WHIP_PUSH * level(plan, "whips")
		"skin":
			return CILIA_PUSH * level(plan, "cilia")
	return 0.0


static func swim_factor(plan: BodyPlan) -> float:
	return (1.0 - PLATE_DRAG * level(plan, "plates")) * (1.0 - OIL_DRAG * level(plan, "oil"))


## Multiplies the energy every cell burns.
static func upkeep_factor(plan: BodyPlan) -> float:
	return (1.0 + HEAL_UPKEEP * level(plan, "healing")) * (1.0 - LEAN_UPKEEP * level(plan, "lean"))


## Energy per second the refined cells burn on top of their usual share.
static func extra_upkeep(plan: BodyPlan) -> float:
	var sum := 0.0
	for id in CELL_UPKEEP:
		sum += float(CELL_UPKEEP[id]) * level(plan, id) * plan.count(role(id))
	return sum


static func store_factor(plan: BodyPlan) -> float:
	return 1.0 - LEAN_STORE * level(plan, "lean")


static func regrow_factor(plan: BodyPlan) -> float:
	return 1.0 - HEAL_SPEED * level(plan, "healing")


## Up to `n` different upgrades the body can take, leaning toward the cells
## it has most of and the upgrades it already has, so picks compound.
static func offer(plan: BodyPlan, rng: RandomNumberGenerator, n: int) -> Array[String]:
	var pool: Array[String] = []
	var weights: Array[float] = []
	for id in INFO:
		if can_take(plan, id):
			pool.append(id)
			var need := role(id)
			var cells := 6.0 if need == "" else float(plan.count(need))
			weights.append(1.0 + cells / 4.0 + 1.5 * level(plan, id))
	var picked: Array[String] = []
	while picked.size() < n and not pool.is_empty():
		var total := 0.0
		for w in weights:
			total += w
		var roll := rng.randf() * total
		var i := 0
		while i < pool.size() - 1 and roll > weights[i]:
			roll -= weights[i]
			i += 1
		picked.append(pool[i])
		pool.remove_at(i)
		weights.remove_at(i)
	return picked


## Gives a rival `count` random upgrades.
static func add_random(plan: BodyPlan, rng: RandomNumberGenerator, count: int) -> void:
	for _i in count:
		var ids := offer(plan, rng, 1)
		if ids.is_empty():
			return
		take(plan, ids[0])
