class_name ColonyLook
extends Node3D
## Draws a colony in the same style as a stage 1 cell: every cell is a
## glowing, see-through membrane in the species' colour, overlapping its
## neighbours so the body reads as one soft lump, with a nucleus inside.
## A cell's job shows in a slight tint on its membrane and in its nucleus
## colour. Ordinary cells keep the species' diet-coloured nucleus. Cells
## pulse gently, out of step with each other. Dark hollows mark the gut
## cavity and mouth opening. Each part is a MultiMesh: one draw call.

## How much a cell's job tints its membrane.
const JOB_TINT := 0.18
const PLAIN_JOBS := ["skin", "gut", "mouth"]

var _cells: BeadStrip
var _nuclei: BeadStrip
var _holes: BeadStrip
var _time := 0.0


func build(plan: BodyPlan, tint: Color, nucleus: Color) -> void:
	for child in get_children():
		child.queue_free()
	var membrane := Color(tint, 1.0) * 0.5
	_cells = BeadStrip.make(plan.parts.size(), 0.7, 16, membrane, true)
	_nuclei = BeadStrip.make(plan.parts.size(), 0.2, 8, nucleus * 0.4)
	for i in plan.parts.size():
		var role := plan.parts[i].role
		var job := BodyPart.color(role)
		_cells.set_color(i, Color(tint.lerp(job, JOB_TINT), tint.a))
		_nuclei.set_color(i, nucleus if role in PLAIN_JOBS else job)
	add_child(_cells)
	add_child(_nuclei)
	_holes = BeadStrip.make(plan.hollow.size(), 0.42, 10, Color.BLACK, true)
	for i in plan.hollow.size():
		_holes.set_color(i, Color(tint.darkened(0.85), 0.85))
	add_child(_holes)
	_time = randf() * 10.0


## Places every cell where the soft body has it, and the hollows where the
## resting shape says they are right now.
func update(body: SoftBody, hollow_rest: PackedVector3Array, delta: float = 0.0) -> void:
	if _cells == null:
		return
	_time += delta
	for i in mini(body.size(), _cells.count()):
		var pulse := 1.0 + 0.05 * sin(_time * 4.0 + i * 0.9)
		_cells.place(i, body.pos[i], pulse, 0.75 / pulse)
		_nuclei.place(i, body.pos[i] + Vector3(0.12, 0.1, -0.08))
	for i in mini(hollow_rest.size(), _holes.count()):
		_holes.place(i, body.to_world(hollow_rest[i]) + Vector3(0.0, 0.2, 0.0), 1.0, 0.3)
