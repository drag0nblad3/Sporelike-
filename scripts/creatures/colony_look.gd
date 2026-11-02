class_name ColonyLook
extends Node3D
## Draws a colony: one ball per cell, coloured by its job and squashed a
## little so the body reads as a soft sheet, plus dark hollows where the
## gut cavity and mouth opening are.

var _cells: BeadStrip
var _holes: BeadStrip


func build(plan: BodyPlan, tint: Color) -> void:
	for child in get_children():
		child.queue_free()
	_cells = BeadStrip.make(plan.parts.size(), 0.6, 12)
	for i in plan.parts.size():
		_cells.set_color(i, BodyPart.color(plan.parts[i].role).lerp(tint, 0.2))
	add_child(_cells)
	_holes = BeadStrip.make(plan.hollow.size(), 0.5, 8)
	for i in plan.hollow.size():
		_holes.set_color(i, Color(0.08, 0.03, 0.05))
	add_child(_holes)


## Places every cell where the soft body has it, and the hollows where the
## resting shape says they are right now.
func update(body: SoftBody, hollow_rest: PackedVector3Array) -> void:
	if _cells == null:
		return
	for i in mini(body.size(), _cells.count()):
		_cells.place(i, body.pos[i], 1.0, 0.75)
	for i in mini(hollow_rest.size(), _holes.count()):
		_holes.place(i, body.to_world(hollow_rest[i]) + Vector3(0.0, 0.25, 0.0), 1.0, 0.3)
