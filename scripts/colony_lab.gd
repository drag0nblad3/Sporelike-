class_name ColonyLab
extends Node3D
## A sandbox for colonies outside the real game: choose a symmetry, then
## swim a soft-bodied colony through a seaweed meadow, grow cells with the
## buttons and graze the seaweed's buds. CI uses it to check soft bodies
## and the screenshot tour to show each body plan.

signal back_requested

const PLANTS := 18

var colony: Colony
var bed := SeaweedBed.new()
var camera: CameraRig
var hud: LabHud
## When not zero, steers the colony instead of the player (CI and the
## screenshot tour).
var autopilot := Vector2.ZERO
## False when a Game already supplies the sea's light and colour (CI).
var with_sea := true


func _ready() -> void:
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
	bed.follows = false
	bed.rng.seed = 7
	add_child(bed)
	bed.plant_around(Vector3.ZERO, PLANTS)


## Starts (or restarts) with a fresh starting lump of the chosen symmetry.
func start(kind: String) -> void:
	if is_instance_valid(colony):
		colony.queue_free()
	colony = Colony.new()
	colony.build(BodyPlan.starter(kind), Vector3.ZERO)
	colony.limbs.food_finder = bed.nearest_food
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


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(colony):
		return
	colony.move_input = autopilot if autopilot != Vector2.ZERO else hud.steering()
	var grazed := bed.touch(colony)
	if grazed > 0.0:
		colony.feed(grazed)


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
