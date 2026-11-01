class_name BodyPart
extends RefCounted
## One cell in a multicellular body: what job it does and where it sits
## relative to the body's center. Groundwork for the multicellular stage.

## Each role and what it will do once the stage is playable.
const ROLES := {
	"core": "Holds the body together and stores energy.",
	"mouth": "Eats food it touches.",
	"flagellum": "Pushes the body forward.",
	"spike": "Deflects hunters' bites.",
	"eye": "Spots food and hunters from farther away.",
	"gland": "Makes toxin that stings hunters.",
}

var role := "core"
var offset := Vector2.ZERO


static func make(part_role: String, at: Vector2) -> BodyPart:
	var part := BodyPart.new()
	part.role = part_role if ROLES.has(part_role) else "core"
	part.offset = at
	return part


static func from_dict(data: Dictionary) -> BodyPart:
	var part_role: String = data.get("role", "core")
	return make(part_role, Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0))))


func to_dict() -> Dictionary:
	return {"role": role, "x": offset.x, "y": offset.y}
