class_name LandBody
extends RefCounted
## What a stage 3 body's parts are good for on the land: sharp parts
## (claws, pincers, blades, tusks, mandibles, a beak) bite harder, hands or
## a trunk carry more food, and showy or spiky parts (horns, spikes, a
## sail, quills, anything oversized) frighten egg thieves away.

const BITE := 2.4
const SHARP_BITE := 3.6
const CARRY := 3
const HANDS_CARRY := 5
const SCARE := 11.0

## Damage per second to whatever the animal walks into.
var bite := BITE
## Pieces of food carried at once.
var carry := CARRY
## Egg thieves flee when the animal is this close (0: only when bitten).
var scare := 0.0


static func of(body: AnimalBody) -> LandBody:
	var powers := LandBody.new()
	var sharp_arms := body.arm_pairs > 0 and body.arm_tip != "hand"
	if body.foot == "claw" or body.claw_side != 0 or sharp_arms \
			or body.mouth in ["tusks", "mandibles", "beak"]:
		powers.bite = SHARP_BITE
	if (body.arm_pairs > 0 and body.arm_tip == "hand") or body.mouth == "trunk":
		powers.carry = HANDS_CARRY
	if body.horns > 0 or body.tops.has("spikes") or body.tops.has("sail") \
			or body.covering == "quills" or body.oversize != "none":
		powers.scare = SCARE
	return powers


func text() -> String:
	var line := "Bite %.1f/s%s  ·  Carries %d%s" % [bite, " (sharp parts)" if bite > BITE else "",
		carry, " (hands or trunk)" if carry > CARRY else ""]
	if scare > 0.0:
		line += "  ·  Frightens thieves at %d m" % roundi(scare)
	return line
