class_name AnimalWords
extends RefCounted
## Describes a stage 3 AnimalBody in one line for the lab's status text:
## its segments and how it moves, then its stand-out parts.


static func describe(body: AnimalBody) -> String:
	var parts := PackedStringArray()
	if body.symmetry != "two-sided":
		parts.append(body.symmetry)
	if body.head_at != "front":
		parts.append(body.head_at + " head")
	if body.mouth not in ["none", "smile"]:
		parts.append(body.mouth)
	if body.leg_build > 2.0 and body.pairs() > 0:
		parts.append("mighty legs")
	if body.neck > 0.0:
		parts.append("long neck" if body.neck > 1.2 else "neck")
	if body.arm_pairs > 0:
		parts.append("%d arms" % (body.arm_pairs * 2))
	if body.eyes != 2 or body.eye_set != "front":
		parts.append("%d %s eye%s" % [body.eyes, body.eye_set, "" if body.eyes == 1 else "s"])
	if body.horns > 0:
		parts.append("horns")
	if body.claw_side != 0:
		parts.append("big claw")
	if body.eye_stalks:
		parts.append("eye stalks")
	if body.tail != "":
		parts.append(body.tail + " tail")
	for top in body.tops:
		if top != "" and not (top + "s" in parts or top in parts):
			parts.append(top)
	var text := "%d segments, %s" % [body.segments(), AnimalGait.verb(body)]
	return text + (" · " + ", ".join(parts) if not parts.is_empty() else "")
