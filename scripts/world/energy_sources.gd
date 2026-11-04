class_name EnergySources
extends RefCounted
## Energy a cell makes without eating: Chloroplasts photosynthesize in
## sunlit algae meadows and Vent symbionts run on vent chemicals at shell
## beds; the Sea a cell is in (SeaMap) makes either stronger or weaker.
## Where a cell is gets checked a few times a second, not every frame, to
## stay cheap with a big population.

const CHECK_INTERVAL := 0.5
## Food kind growing where the light and the vents are.
const SUN_KIND := "algae"
const VENT_KIND := "shells"


## Energy per second per level of each organelle.
const SUN_PER_LEVEL := 0.08
const VENT_PER_LEVEL := 0.12


## Energy per second made by photosynthesis while over sunlit algae, in a
## sea of normal light.
static func sun_rate(g: Genome) -> float:
	return SUN_PER_LEVEL * g.feature("chloroplasts") * BodyForm.symbiont(g)


## Energy per second made by vent bacteria while over shell beds, in a
## sea of normal vent activity.
static func vent_rate(g: Genome) -> float:
	return VENT_PER_LEVEL * g.feature("vent_symbionts") * BodyForm.symbiont(g)


static func makes_energy(g: Genome) -> bool:
	return g.feature("chloroplasts") > 0 or g.feature("vent_symbionts") > 0


## Id of the food kind whose patch covers this point, or "" for bare sand.
static func kind_at(p: Vector2, patches: Array[FoodPatch]) -> String:
	for patch in patches:
		if p.distance_squared_to(patch.center) > pow(patch.radius * 1.5, 2.0):
			continue
		if patch.contains(p):
			return patch.kind.id
	return ""


## Energy per second this genome makes over ground of this food kind, in
## this sea.
static func rate(g: Genome, kind_id: String, sea: Sea) -> float:
	if kind_id == SUN_KIND:
		return sun_rate(g) * sea.light
	if kind_id == VENT_KIND:
		return vent_rate(g) * sea.vents
	return 0.0


## Called each physics frame for every living cell.
static func feed(org: Organism, patches: Array[FoodPatch], delta: float) -> void:
	if not makes_energy(org.genome):
		return
	org.ambient_timer -= delta
	if org.ambient_timer <= 0.0:
		org.ambient_timer = CHECK_INTERVAL
		var at := org.flat_pos()
		org.ambient_rate = rate(org.genome, kind_at(at, patches), SeaMap.at(at))
	if org.ambient_rate > 0.0:
		org.absorb(org.ambient_rate * delta)
