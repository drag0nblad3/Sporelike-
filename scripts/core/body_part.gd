class_name BodyPart
extends RefCounted
## One cell in a multicellular body: what job it does and where it sits.
## `offset` is its spot on the body plan's flat grid (x left-right, y
## back-front); `layer` is its height above or below that sheet, kept so
## bodies can grow in layers later even though play is flat for now.

const LAYER_HEIGHT := 0.8

## role -> [label, what it does, colour]
const ROLES := {
	"mouth": ["Mouth cell", "Rings the mouth and takes in food it touches.", Color(1.0, 0.55, 0.5)],
	"gut": ["Digestive cell", "Lines the gut cavity; more of them get more from every meal.",
		Color(0.95, 0.72, 0.32)],
	"skin": ["Skin cell", "Covers the body; its cilia help it swim.", Color(0.45, 0.8, 0.85)],
	"flagellum": ["Flagellated cell", "Beats a whip that pushes the body along.",
		Color(0.5, 0.62, 1.0)],
	"plate": ["Plate cell", "A tough flat cell that guards its side.", Color(0.72, 0.7, 0.6)],
	"eye": ["Eyespot cell", "A light-sensing spot that sees farther from where it sits.",
		Color(0.9, 0.28, 0.35)],
	"gland": ["Stinging cell", "Fires a toxic thread at whatever brushes it.",
		Color(0.78, 0.45, 0.95)],
	"storage": ["Storage cell", "Holds spare food as oil for lean times.", Color(1.0, 0.92, 0.6)],
}

var role := "skin"
var offset := Vector2.ZERO
var layer := 0


static func make(part_role: String, at: Vector2, at_layer: int = 0) -> BodyPart:
	var part := BodyPart.new()
	part.role = part_role if ROLES.has(part_role) else "skin"
	part.offset = BodyPlan.snap(at)
	part.layer = at_layer
	return part


static func label(part_role: String) -> String:
	var row: Array = ROLES.get(part_role, ROLES["skin"])
	return row[0]


static func color(part_role: String) -> Color:
	var row: Array = ROLES.get(part_role, ROLES["skin"])
	return row[2]


static func from_dict(data: Dictionary) -> BodyPart:
	var part_role: String = data.get("role", "skin")
	var at := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	return make(part_role, at, int(data.get("layer", 0)))


func to_dict() -> Dictionary:
	return {"role": role, "x": offset.x, "y": offset.y, "layer": layer}


## Where the cell sits in the body's own 3D space (+z is the front).
func local_position() -> Vector3:
	return Vector3(offset.x, layer * LAYER_HEIGHT, offset.y)
