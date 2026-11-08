class_name BodyPlan
extends RefCounted
## The layout of a multicellular body: its symmetry, its cells (BodyParts)
## on a hex grid, and the spots that must stay empty (the gut cavity and
## the mouth opening). It starts as a lump with a mouth ring around a
## cavity lined with digesting cells (StarterLump); grow() adds a cell and
## its symmetric copies where that kind of cell belongs (CellPlacement).

const SPACING := 1.0
## Largest body, so the soft body stays cheap on a phone.
const MAX_CELLS := 60
## The six neighbouring grid directions; one points straight forward (+y).
const DIRS := [
	Vector2(0.8660254, 0.5), Vector2(0.0, 1.0), Vector2(-0.8660254, 0.5),
	Vector2(-0.8660254, -0.5), Vector2(0.0, -1.0), Vector2(0.8660254, -0.5),
]

var symmetry := Symmetry.BILATERAL
var parts: Array[BodyPart] = []
## Grid spots kept open: the gut cavity and the mouth opening.
var hollow: Array[Vector2] = []
## The FeedingStyle picked during the stage ("" until then).
var style := ""
## The FinalBody picked at the end of the stage ("" until then).
var final_body := ""
## TissueTrait upgrades: id -> level.
var traits := {}


## Rounds a grid position so the same spot always compares equal.
static func snap(p: Vector2) -> Vector2:
	return Vector2(snappedf(p.x, 0.001), snappedf(p.y, 0.001))


## A new colony: the starting lump for the chosen symmetry.
static func starter(kind: String = Symmetry.BILATERAL) -> BodyPlan:
	var plan := BodyPlan.new()
	plan.symmetry = kind if kind in Symmetry.ALL else Symmetry.BILATERAL
	StarterLump.fill(plan)
	return plan


static func from_dict(data: Dictionary) -> BodyPlan:
	var plan := BodyPlan.new()
	var kind: String = data.get("symmetry", Symmetry.BILATERAL)
	plan.symmetry = kind
	var list: Array = data.get("parts", [])
	for item in list:
		var entry: Dictionary = item
		plan.parts.append(BodyPart.from_dict(entry))
	var holes: Array = data.get("hollow", [])
	for item in holes:
		var pair: Array = item
		plan.hollow.append(snap(Vector2(float(pair[0]), float(pair[1]))))
	plan.style = str(data.get("style", ""))
	plan.final_body = str(data.get("final_body", ""))
	var saved: Dictionary = data.get("traits", {})
	for id in saved:
		if TissueTrait.INFO.has(id):
			plan.traits[str(id)] = clampi(int(saved[id]), 0, TissueTrait.MAX_LEVEL)
	if plan.parts.is_empty():
		return starter(kind)
	return plan


func copy() -> BodyPlan:
	return from_dict(to_dict())


func to_dict() -> Dictionary:
	var list: Array = []
	for part in parts:
		list.append(part.to_dict())
	var holes: Array = []
	for spot in hollow:
		holes.append([spot.x, spot.y])
	return {"symmetry": symmetry, "parts": list, "hollow": holes, "style": style,
		"final_body": final_body, "traits": traits.duplicate()}


func count(role: String) -> int:
	var n := 0
	for part in parts:
		if part.role == role:
			n += 1
	return n


func is_taken(spot: Vector2) -> bool:
	var at := snap(spot)
	if at in hollow:
		return true
	for part in parts:
		if part.offset == at:
			return true
	return false


## Grid spots touching the body that are neither cells nor kept open.
func open_spots() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for part in parts:
		for item in DIRS:
			var dir: Vector2 = item
			var spot := snap(part.offset + dir * SPACING)
			if not spot in spots and not is_taken(spot):
				spots.append(spot)
	return spots


func part_at(spot: Vector2) -> BodyPart:
	var at := snap(spot)
	for part in parts:
		if part.offset == at:
			return part
	return null


## Grows `role` cells where they belong, copied by the symmetry. A cell may
## take over a skin cell and push new skin outward (see CellPlacement).
## Returns how many `role` cells were added (0 when there is no room).
func grow(role: String) -> int:
	if parts.size() >= MAX_CELLS:
		return 0
	var choice := CellPlacement.choose(self, role)
	if choice.is_empty():
		return 0
	var spot: Vector2 = choice[0]
	var takes_over: bool = choice[1]
	var added := 0
	for copy in Symmetry.copies(symmetry, spot):
		if takes_over:
			var part := part_at(copy)
			if part and part.role == "skin":
				part.role = role
				added += 1
		elif parts.size() < MAX_CELLS and not is_taken(copy):
			parts.append(BodyPart.make(role, copy))
			added += 1
	if takes_over:
		_push_out_skin(added)
	return added


## Replaces skin cells that took on another job with fresh skin outside.
func _push_out_skin(count: int) -> void:
	var grown := 0
	while grown < count and parts.size() < MAX_CELLS:
		var more := grow("skin")
		if more == 0:
			return
		grown += more
