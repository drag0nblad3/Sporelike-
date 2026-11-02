class_name StarterLump
extends RefCounted
## The lump of cells each symmetry starts the multicellular stage as: the
## beginnings of a digestive system (mouth cells around an opening into a
## cavity lined with digesting cells) wrapped in a ring of skin cells.
## Ring 1 is the six grid spots around the centre, ring 2 the twelve beyond.


static func fill(plan: BodyPlan) -> void:
	plan.parts.clear()
	plan.hollow.clear()
	plan.hollow.append(Vector2.ZERO)
	match plan.symmetry:
		Symmetry.RADIAL:
			_radial(plan)
		Symmetry.BIRADIAL:
			_biradial(plan)
		_:
			_bilateral(plan)


## A cavity in the middle, opening upward, ringed by 3 mouth cells and 3
## digesting cells in turn; 12 skin cells around them (18 cells).
static func _radial(plan: BodyPlan) -> void:
	for i in 6:
		_add(plan, "mouth" if i % 2 == 1 else "gut", _ring1(i))
	for spot in _ring2():
		_add(plan, "skin", spot)


## The mouth opens forward between 2 lip cells into a cavity lined by 5
## digesting cells; 9 skin cells cover the sides and back (16 cells).
static func _bilateral(plan: BodyPlan) -> void:
	var opening := _ring1(1)
	plan.hollow.append(BodyPlan.snap(opening))
	plan.hollow.append(BodyPlan.snap(opening * 2.0))
	for i in 6:
		if i != 1:
			_add(plan, "gut", _ring1(i))
	for spot in _ring2():
		if plan.is_taken(spot):
			continue
		var lip := spot.y > 1.2 and absf(spot.x) > 0.1
		_add(plan, "mouth" if lip else "skin", spot)


## A mouth cell at the front and one at the back of the cavity, each
## opening outward, 4 digesting cells at its sides, 10 skin cells around
## (16 cells).
static func _biradial(plan: BodyPlan) -> void:
	plan.hollow.append(BodyPlan.snap(_ring1(1) * 2.0))
	plan.hollow.append(BodyPlan.snap(_ring1(4) * 2.0))
	for i in 6:
		_add(plan, "mouth" if i == 1 or i == 4 else "gut", _ring1(i))
	for spot in _ring2():
		if not plan.is_taken(spot):
			_add(plan, "skin", spot)


static func _add(plan: BodyPlan, role: String, spot: Vector2) -> void:
	plan.parts.append(BodyPart.make(role, spot))


static func _ring1(i: int) -> Vector2:
	var dir: Vector2 = BodyPlan.DIRS[i % 6]
	return dir * BodyPlan.SPACING


static func _ring2() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for i in 6:
		spots.append(_ring1(i) * 2.0)
		spots.append(_ring1(i) + _ring1(i + 1))
	return spots
