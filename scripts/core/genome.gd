class_name Genome
extends RefCounted
## Heritable traits of one organism. Each trait is stored as 0..1 so mutation
## stays simple; the getters turn them into gameplay numbers.

const TRAITS := ["size", "speed", "agility", "sense", "armor", "toxin", "diet", "jaw"]
const MUTATION_CHANCE := 0.4
const MUTATION_STEP := 0.08
## Scales energy burned per second by every trait. Lower = slower starvation.
const UPKEEP_RATE := 0.75
const FULL_ENERGY := 12.0
const STORE_PER_LEVEL := 5.0
## How far food hardness can exceed the jaw and still be chewed through.
const CHEW_MARGIN := 0.2

## diet: 0 = eats plants well, 1 = eats animals well. jaw cracks shells.
var values := {
	"size": 0.3, "speed": 0.5, "agility": 0.3, "sense": 0.4,
	"armor": 0.1, "toxin": 0.0, "diet": 0.3, "jaw": 0.1,
}
## Branching upgrades (see Feature): id -> level. Inherited unchanged.
var features := {}
## 0..1, hidden: grows when generations go badly; lowers upkeep up to 30%.
var efficiency := 0.0


## Average of each trait across several genomes (all zeros when empty).
static func average(genomes: Array[Genome]) -> Dictionary:
	var sums := {}
	for t in TRAITS:
		sums[t] = 0.0
	for g in genomes:
		for t in TRAITS:
			sums[t] += g.value_of(t)
	if not genomes.is_empty():
		for t in TRAITS:
			sums[t] /= genomes.size()
	return sums


## Rebuilds a genome saved with to_dict(); missing traits keep defaults.
static func from_dict(data: Dictionary) -> Genome:
	var g := Genome.new()
	for t in TRAITS:
		if data.has(t):
			g.values[t] = clampf(float(data[t]), 0.0, 1.0)
	var saved_features: Dictionary = data.get("features", {})
	for id in saved_features:
		if Feature.ALL.has(id):
			g.features[id] = int(saved_features[id])
	g.efficiency = clampf(float(data.get("efficiency", 0.0)), 0.0, 1.0)
	return g


func to_dict() -> Dictionary:
	var data := values.duplicate()
	data["features"] = features.duplicate()
	data["efficiency"] = efficiency
	return data


func copy() -> Genome:
	var g := Genome.new()
	g.values = values.duplicate()
	g.features = features.duplicate()
	g.efficiency = efficiency
	return g


func feature(id: String) -> int:
	return features.get(id, 0)


## Most energy this body can hold: a full stomach plus any fat store.
func max_energy() -> float:
	return FULL_ENERGY + STORE_PER_LEVEL * feature("fat_store")


## Extra eating reach from grabbing cilia.
func grab_reach() -> float:
	return 0.5 * feature("grabbing_cilia")


## A child genome: each trait has a chance to drift a little up or down.
func mutated(rng: RandomNumberGenerator) -> Genome:
	var child := copy()
	for t in TRAITS:
		if rng.randf() < MUTATION_CHANCE:
			child.values[t] = clampf(child.values[t] + rng.randfn(0.0, MUTATION_STEP), 0.0, 1.0)
	return child


func value_of(trait_name: String) -> float:
	return values.get(trait_name, 0.0)


func radius() -> float:
	return lerpf(0.35, 1.2, value_of("size"))


## Armor plates and a twitchy, agile body both cost top speed.
func max_speed() -> float:
	return lerpf(2.5, 8.0, value_of("speed")) * lerpf(1.0, 0.7, value_of("armor")) \
		* lerpf(1.0, 0.85, value_of("agility")) * (1.0 + 0.12 * feature("tail_bud"))


## How hard the cell can push: high agility means quick starts and turns.
func acceleration() -> float:
	return max_speed() * lerpf(1.2, 4.5, value_of("agility"))


func turn_rate() -> float:
	return lerpf(4.0, 14.0, value_of("agility"))


func sense_range() -> float:
	return lerpf(3.0, 12.0, value_of("sense")) * (1.0 + 0.25 * feature("eye_cluster"))


## Chance (0..1) to survive a predator's bite.
func armor() -> float:
	return value_of("armor") * 0.6


## Chance (0..1) a biting predator is stung and lets go.
func toxin() -> float:
	return value_of("toxin") * 0.8


## Energy burned per second. Every advantage has a running cost.
func upkeep() -> float:
	var cost := 0.25 + 0.35 * value_of("size") + 0.3 * value_of("speed") \
		+ 0.2 * value_of("agility") + 0.2 * value_of("sense") + 0.15 * value_of("armor") \
		+ 0.35 * value_of("toxin") + 0.2 * value_of("jaw") \
		+ 0.08 * feature("tail_bud") + 0.04 * feature("fat_store") \
		+ 0.04 * feature("grabbing_cilia") + 0.04 * feature("eye_cluster")
	return cost * UPKEEP_RATE * lerpf(1.0, 0.7, efficiency)


## Whether the jaw is strong enough for food of this hardness.
func can_crack(hardness: float) -> bool:
	return value_of("jaw") >= hardness


## Seconds of holding still on food this hard before breaking through:
## 0 if the jaw cracks it at once, INF if it is too far beyond the jaw.
## Bigger bodies grind through faster.
func crack_time(hardness: float) -> float:
	var gap := hardness - value_of("jaw")
	if gap <= 0.0:
		return 0.0
	if gap > CHEW_MARGIN:
		return INF
	return (0.5 + gap * 10.0) / (0.7 + value_of("size"))


## Energy gained from food worth `energy`, after digestive efficiency.
func digest(energy: float, is_plant: bool) -> float:
	var efficiency := lerpf(1.0, 0.3, value_of("diet")) if is_plant \
		else lerpf(0.3, 1.0, value_of("diet"))
	return energy * efficiency


## How far away food this visible (0..1) can be noticed.
func notice_range(visibility: float) -> float:
	return sense_range() * visibility


func color() -> Color:
	var hue: float = 0.5 + 0.12 * (value_of("speed") - value_of("armor"))
	var base := Color.from_hsv(hue, 0.55 + 0.3 * value_of("sense"), 1.0, 0.6)
	# Toxic cells shift toward a warning orange.
	return base.lerp(Color(1.0, 0.55, 0.1, 0.7), value_of("toxin"))
