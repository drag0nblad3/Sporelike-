class_name LabHud
extends CanvasLayer
## Controls for the colony lab: the symmetry choice first, then a joystick,
## a button per kind of cell to grow, a status line and Back.

signal symmetry_chosen(kind: String)
signal grow_pressed(role: String)
signal back_pressed

const GROWABLE := ["flagellum", "eye", "plate", "gland", "gut", "storage", "mouth", "skin"]

var joystick := VirtualJoystick.new()
var picker := SymmetryPicker.new()
var _status: Label
var _note: Label
var _note_time := 0.0
var _grow_box: GridContainer


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.shared()
	add_child(root)
	root.add_child(joystick)

	_status = Label.new()
	_status.position = Vector2(24, 18)
	UiTheme.outline(_status, 26)
	root.add_child(_status)
	_note = Label.new()
	_note.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_note.offset_top = 70.0
	_note.offset_left = -400.0
	_note.offset_right = 400.0
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.outline(_note, 30)
	root.add_child(_note)

	var back := Button.new()
	back.text = "Back"
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back.offset_left = -190.0
	back.offset_right = -20.0
	back.offset_top = 20.0
	back.offset_bottom = 90.0
	back.pressed.connect(func() -> void: back_pressed.emit())
	root.add_child(back)

	_grow_box = GridContainer.new()
	_grow_box.columns = 2
	_grow_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_grow_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_grow_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_grow_box.offset_left = -20.0 - 510.0
	_grow_box.offset_top = -20.0 - 280.0
	_grow_box.offset_right = -20.0
	_grow_box.offset_bottom = -20.0
	_grow_box.visible = false
	for role in GROWABLE:
		_grow_box.add_child(_grow_button(role))
	root.add_child(_grow_box)

	root.add_child(picker)
	picker.chosen.connect(_on_chosen)


func close_picker() -> void:
	picker.visible = false
	_grow_box.visible = true


func open_picker() -> void:
	picker.visible = true
	_grow_box.visible = false


## Joystick when touched, otherwise arrow keys or WASD.
func steering() -> Vector2:
	if joystick.is_active():
		return joystick.output
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	keys.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	keys.y += float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	return keys.limit_length(1.0)


func show_status(colony: Colony) -> void:
	_status.text = "%s body  ·  %d cells  ·  Energy %.0f / %.0f  ·  Digests %d%%" % [
		Symmetry.label(colony.plan.symmetry), colony.plan.parts.size(), colony.energy,
		colony.max_energy(), roundi(colony.digest_share() * 100.0)]


func flash(text: String) -> void:
	_note.text = text
	_note_time = 2.0


func _process(delta: float) -> void:
	_note_time = maxf(_note_time - delta, 0.0)
	_note.modulate.a = minf(_note_time, 1.0)


func _on_chosen(kind: String) -> void:
	close_picker()
	symmetry_chosen.emit(kind)


func _grow_button(role: String) -> Button:
	var button := Button.new()
	button.text = "+ " + BodyPart.label(role)
	button.custom_minimum_size = Vector2(250, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", BodyPart.color(role).lightened(0.3))
	button.pressed.connect(func() -> void: grow_pressed.emit(role))
	return button
