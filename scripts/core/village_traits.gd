class_name VillageTraits
extends RefCounted
## What the body designed in stage 3 gives the whole village in stage 4:
## mighty legs haul more, claws and blades hit harder, many eyes warn of
## raids sooner, a sail or feathers widen the elder's aura, plates and
## quills shrug off damage, and bodies with hands (upright, or with arms)
## use tools as buildings go up. Read from the tribe's current body.

const AURA := 8.0
const WORK_BOOST := 1.3
const DAMAGE_BOOST := 1.2

var haul := 1
var attack := 1.0
var warning := 0.0
var aura := AURA
var hurt := 1.0
var hands := false
var words: Array[String] = []


static func of(body: AnimalBody) -> VillageTraits:
	var t := VillageTraits.new()
	if body.leg_build >= 2.5:
		t.haul = 2
		t.words.append("Mighty legs: carry 2 food a trip")
	if body.foot == "claw" or body.claw_side != 0 \
			or (body.arm_pairs > 0 and body.arm_tip != "hand") or body.mouth == "tusks":
		t.attack = 1.25
		t.words.append("Claws and blades: +25% damage")
	if body.eyes >= 4 or body.eye_stalks:
		t.warning = 10.0
		t.words.append("Sharp eyes: raids seen 10 s sooner")
	if body.tops.has("sail") or body.covering.contains("feathers"):
		t.aura = 12.0
		t.words.append("Display: elder's aura reaches 12 m")
	if body.tops.has("plates") or body.tops.has("spikes") or body.covering == "quills":
		t.hurt = 0.75
		t.words.append("Armour: 25% less damage taken")
	t.hands = body.posture == "upright" or body.arm_pairs > 0
	if t.hands:
		t.words.append("Hands: tools from the store (+1 food) and wall (+25% damage)")
	return t


## Adds the tools that buildings unlock for a body with hands.
func with_tools(store: int, wall: int) -> VillageTraits:
	var t := VillageTraits.new()
	t.haul = haul + (1 if hands and store > 0 else 0)
	t.attack = attack * (1.25 if hands and wall > 0 else 1.0)
	t.warning = warning
	t.aura = aura
	t.hurt = hurt
	t.hands = hands
	t.words = words
	return t


func text() -> String:
	return "No village traits yet" if words.is_empty() else "\n".join(PackedStringArray(words))
