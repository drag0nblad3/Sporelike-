extends Node3D
## First playable: steer a cell around a patch of ocean and eat food.
## Everything is built in code so the project can be edited without the
## Godot editor.

const ARENA_RADIUS := 30.0
const FOOD_COUNT := 45
const FOOD_RADIUS := 0.22
const GROWTH_PER_FOOD := 0.03
const CAMERA_OFFSET := Vector3(0.0, 16.0, 8.0)

var player: Cell
var camera: Camera3D
var joystick: VirtualJoystick
var food_root: Node3D
var food_mesh: SphereMesh
var food_material: StandardMaterial3D
var score_label: Label
var hint_label: Label
var debug_label: Label
var food_eaten := 0
var rng := RandomNumberGenerator.new()
var _time := 0.0


func _ready() -> void:
	rng.randomize()
	_build_environment()
	_build_arena()

	player = Cell.new()
	player.arena_radius = ARENA_RADIUS
	add_child(player)

	food_root = Node3D.new()
	add_child(food_root)
	food_mesh = SphereMesh.new()
	food_mesh.radius = FOOD_RADIUS
	food_mesh.height = FOOD_RADIUS * 2.0
	food_material = StandardMaterial3D.new()
	food_material.albedo_color = Color(0.5, 1.0, 0.45)
	food_material.emission_enabled = true
	food_material.emission = Color(0.3, 0.9, 0.3)
	food_material.emission_energy_multiplier = 1.5
	for _i in FOOD_COUNT:
		_spawn_food()

	_build_camera()
	_build_hud()


func _process(delta: float) -> void:
	_time += delta
	player.move_input = _read_move_input()
	_eat_nearby_food()
	_bob_food()
	_follow_camera(delta)
	hint_label.visible = food_eaten == 0 and not joystick.is_active()
	debug_label.text = "FPS %d  |  size %.2f" % [Engine.get_frames_per_second(), player.radius]


func _read_move_input() -> Vector2:
	if joystick.is_active():
		return joystick.output
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		keys.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		keys.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		keys.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		keys.y += 1.0
	return keys.limit_length(1.0)


func _eat_nearby_food() -> void:
	var reach := player.radius + FOOD_RADIUS
	for food in food_root.get_children():
		var f := food as Node3D
		var dx := f.position.x - player.position.x
		var dz := f.position.z - player.position.z
		if dx * dx + dz * dz < reach * reach:
			f.queue_free()
			food_eaten += 1
			player.grow(GROWTH_PER_FOOD)
			score_label.text = "Food eaten: %d" % food_eaten
			_spawn_food()


func _bob_food() -> void:
	for food in food_root.get_children():
		var f := food as Node3D
		f.position.y = 0.15 * sin(_time * 2.0 + f.position.x)


func _spawn_food() -> void:
	var food := MeshInstance3D.new()
	food.mesh = food_mesh
	food.material_override = food_material
	var angle := rng.randf_range(0.0, TAU)
	var dist := sqrt(rng.randf()) * (ARENA_RADIUS - 1.0)
	food.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	food_root.add_child(food)


func _follow_camera(delta: float) -> void:
	var target := player.position + CAMERA_OFFSET * (0.8 + player.radius * 0.35)
	camera.position = camera.position.lerp(target, minf(4.0 * delta, 1.0))
	camera.look_at(camera.position - CAMERA_OFFSET)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.07, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.55, 0.65)
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60.0, 30.0, 0.0)
	sun.light_color = Color(0.75, 0.9, 1.0)
	add_child(sun)


func _build_arena() -> void:
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = ARENA_RADIUS
	floor_mesh.bottom_radius = ARENA_RADIUS
	floor_mesh.height = 0.2
	floor_mesh.radial_segments = 64
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.05, 0.2, 0.25)
	var ocean_floor := MeshInstance3D.new()
	ocean_floor.mesh = floor_mesh
	ocean_floor.material_override = floor_mat
	ocean_floor.position.y = -1.0
	add_child(ocean_floor)

	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = ARENA_RADIUS - 0.25
	rim_mesh.outer_radius = ARENA_RADIUS + 0.25
	rim_mesh.rings = 64
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.2, 0.6, 0.7)
	rim_mat.emission_enabled = true
	rim_mat.emission = Color(0.1, 0.4, 0.5)
	var rim := MeshInstance3D.new()
	rim.mesh = rim_mesh
	rim.material_override = rim_mat
	rim.position.y = -0.8
	add_child(rim)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 55.0
	add_child(camera)
	camera.position = player.position + CAMERA_OFFSET
	camera.look_at(player.position)
	camera.make_current()


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	joystick = VirtualJoystick.new()
	hud.add_child(joystick)

	score_label = _make_label(Vector2(24, 20), 34)
	score_label.text = "Food eaten: 0"
	hud.add_child(score_label)

	debug_label = _make_label(Vector2(24, 66), 20)
	debug_label.modulate = Color(1, 1, 1, 0.6)
	hud.add_child(debug_label)

	hint_label = Label.new()
	hint_label.text = "Touch and drag on the left side to swim. Eat the green food."
	hint_label.add_theme_font_size_override("font_size", 28)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.offset_top = -90.0
	hint_label.offset_left = -500.0
	hint_label.offset_right = 500.0
	hud.add_child(hint_label)


func _make_label(at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	return label
