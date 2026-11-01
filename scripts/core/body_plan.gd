class_name BodyPlan
extends RefCounted
## The layout of a multicellular body: a list of BodyParts on a grid around
## the core cell. Groundwork for the multicellular stage, where the player
## will add parts between generations instead of nudging single traits.

const SPACING := 1.0

var parts: Array[BodyPart] = []


## A new colony: just the core cell the single-celled species grew from.
static func starter() -> BodyPlan:
	var plan := BodyPlan.new()
	plan.parts.append(BodyPart.make("core", Vector2.ZERO))
	return plan


static func from_dict(data: Dictionary) -> BodyPlan:
	var plan := BodyPlan.new()
	var list: Array = data.get("parts", [])
	for item in list:
		var entry: Dictionary = item
		plan.parts.append(BodyPart.from_dict(entry))
	if plan.parts.is_empty():
		return starter()
	return plan


func to_dict() -> Dictionary:
	var list: Array = []
	for part in parts:
		list.append(part.to_dict())
	return {"parts": list}


func count(role: String) -> int:
	var n := 0
	for part in parts:
		if part.role == role:
			n += 1
	return n


## Grid spots next to an existing part that are still empty.
func open_spots() -> Array[Vector2]:
	var taken := {}
	for part in parts:
		taken[part.offset] = true
	var spots: Array[Vector2] = []
	for part in parts:
		for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var spot: Vector2 = part.offset + dir * SPACING
			if not taken.has(spot) and not spot in spots:
				spots.append(spot)
	return spots


## Adds a part at a free spot touching the body. Returns false if taken.
func attach(role: String, at: Vector2) -> bool:
	if not at in open_spots():
		return false
	parts.append(BodyPart.make(role, at))
	return true
