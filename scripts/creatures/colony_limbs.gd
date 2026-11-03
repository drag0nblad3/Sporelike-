class_name ColonyLimbs
extends Node3D
## A colony's moving parts, posed every frame by inverse kinematics: a whip
## on each flagellated cell that beats out behind it, and on radial bodies a
## tentacle on each mouth cell that sways and reaches for food in range.

## (from: Vector3, reach: float) -> Vector3: the nearest food within reach,
## or Vector3.INF when there is none. Set by whoever owns the food.
var food_finder: Callable

var _colony: Colony
var _limbs: Array[IkLimb] = []
var _cells := PackedInt32Array()
var _tentacle := PackedByteArray()
var _time := 0.0


func build(colony: Colony) -> void:
	_colony = colony
	for limb in _limbs:
		limb.queue_free()
	_limbs.clear()
	_cells.clear()
	_tentacle.clear()
	var radial := colony.plan.symmetry == Symmetry.RADIAL
	for i in colony.plan.parts.size():
		var role := colony.plan.parts[i].role
		if role == "flagellum":
			_add(i, false, 7, 0.38, _limb_color(colony, role))
		elif role == "mouth" and radial:
			_add(i, true, 8, 0.45, _limb_color(colony, role))


## Tips of the tentacles, which can pick up food like a mouth.
func tentacle_tips() -> PackedVector3Array:
	var tips := PackedVector3Array()
	for k in _limbs.size():
		if _tentacle[k] == 1:
			tips.append(_limbs[k].tip())
	return tips


func update(delta: float) -> void:
	if _colony == null:
		return
	_time += delta
	var body := _colony.body
	var center := body.center()
	var back := Vector3.FORWARD.rotated(Vector3.UP, body.angle)
	var swimming := clampf(body.velocity().length() / 2.0, 0.3, 1.0)
	for k in _limbs.size():
		var root := body.pos[_cells[k]]
		var out := root - center
		out.y = 0.0
		out = out.normalized() if out.length() > 0.01 else back
		var reach := _limbs[k].length()
		var target: Vector3
		if _tentacle[k] == 1:
			# Tentacles grow from the mouth ring over the top of the body.
			root.y += 0.45
			target = _reach_for_food(root, out, reach, k)
		else:
			if _colony.plan.symmetry == Symmetry.BILATERAL:
				out = (out + back * 1.5).normalized()
			var side := out.cross(Vector3.UP)
			var beat := sin(_time * 10.0 * swimming + k * 1.7)
			target = root + out * reach * 0.85 + side * beat * reach * 0.45
		_limbs[k].pose(root, target, delta)


func _reach_for_food(root: Vector3, out: Vector3, reach: float, k: int) -> Vector3:
	if food_finder.is_valid():
		var food: Vector3 = food_finder.call(root, reach)
		if food != Vector3.INF:
			return food
	var sway := sin(_time * 1.8 + k * 2.1)
	return root + out * reach * 0.8 + out.cross(Vector3.UP) * sway * reach * 0.35


## Limbs share the species' colour, like a stage 1 cell's flagellum.
static func _limb_color(colony: Colony, role: String) -> Color:
	return Color(colony.tint.lerp(BodyPart.color(role), 0.25), 1.0)


func _add(cell: int, tentacle: bool, joints: int, segment: float, color: Color) -> void:
	var limb := IkLimb.new()
	limb.setup(joints, segment, 0.28 if tentacle else 0.2, color)
	add_child(limb)
	_limbs.append(limb)
	_cells.append(cell)
	_tentacle.append(1 if tentacle else 0)
