class_name ColonyLab
extends Node3D
## Stage 2 preview, opened from the title screen: choose a symmetry, then
## swim a soft-bodied colony through a seaweed meadow, grow cells with the
## buttons and graze the seaweed's buds. A sandbox for tuning soft bodies,
## body plans, IK limbs and plants on a phone before they join Game.

signal back_requested

const PLANTS := 18
const FIELD := 28.0
## How close a mouth or tentacle tip must get to a bud to eat it.
const BITE_REACH := 0.9
## How far apart colony cells and seaweed cells are kept.
const CONTACT_GAP := 1.0

var colony: Colony
var plants: Array[Seaweed] = []
var camera: CameraRig
var hud: LabHud
## When not zero, steers the colony instead of the player (CI and the
## screenshot tour).
var autopilot := Vector2.ZERO
## False when a Game already supplies the sea's light and colour (CI).
var with_sea := true
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 7
	if with_sea:
		add_child(Arena.new())
	add_child(_floor())
	camera = CameraRig.new()
	add_child(camera)
	camera.snap_to(Vector3.ZERO)
	hud = LabHud.new()
	add_child(hud)
	hud.symmetry_chosen.connect(start)
	hud.grow_pressed.connect(grow)
	hud.back_pressed.connect(func() -> void: back_requested.emit())
	for i in PLANTS:
		var at := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(6.0, FIELD)
		var weed := Seaweed.new()
		weed.grow_at(Vector3(at.x, 0.0, at.y), rng)
		add_child(weed)
		plants.append(weed)


## Starts (or restarts) with a fresh starting lump of the chosen symmetry.
func start(kind: String) -> void:
	if is_instance_valid(colony):
		colony.queue_free()
	colony = Colony.new()
	colony.build(BodyPlan.starter(kind), Vector3.ZERO)
	colony.limbs.food_finder = nearest_food
	add_child(colony)
	hud.close_picker()
	camera.snap_to(colony.center())


func grow(role: String) -> void:
	if not is_instance_valid(colony):
		return
	var added := colony.grow(role)
	if added == 0:
		hud.flash("No room for another %s" % BodyPart.label(role).to_lower())
	else:
		hud.flash("+%d %s%s" % [added, BodyPart.label(role).to_lower(), "s" if added > 1 else ""])


## The nearest ripe bud within `reach` of `from`, or Vector3.INF.
func nearest_food(from: Vector3, reach: float) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for weed in plants:
		var k := weed.nearest_bud(from, reach)
		if k >= 0:
			var at := weed.bud_position(k)
			var d := at.distance_squared_to(from)
			if d < best_d:
				best_d = d
				best = at
	return best


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(colony):
		return
	colony.move_input = autopilot if autopilot != Vector2.ZERO else hud.steering()
	for weed in plants:
		SoftContact.separate(colony.body, weed.body, CONTACT_GAP)
	for point in colony.eat_points():
		for weed in plants:
			var k := weed.nearest_bud(point, BITE_REACH)
			if k >= 0:
				colony.feed(weed.take_bud(k))


func _process(delta: float) -> void:
	if not is_instance_valid(colony):
		return
	camera.follow(colony.center(), colony.reach() * 0.6, delta)
	hud.show_status(colony)


func _floor() -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(160.0, 160.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.19, 0.22)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(0.0, -0.8, 0.0)
	return ground
