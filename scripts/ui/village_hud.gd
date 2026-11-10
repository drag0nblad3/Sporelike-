class_name VillageHud
extends CanvasLayer
## Stage 4's controls. On foot: the joystick, the look pad, Rally, and
## Village view (plus Back). Overhead: the VillagePanel of broad orders
## and the map itself, where a tap sets the focus flag (map_tapped). Also
## the status lines, short notices (flash), the body customizer between
## generations and the end-of-run VillageSummary.

signal view_pressed
signal rally_pressed
signal back_pressed
## A tap on the overhead map, as shares of the screen (0 to 1), and the
## screen's width over its height.
signal map_tapped(share: Vector2, aspect: float)
signal evolve_finished
signal recipe_changed(recipe: AnimalRecipe)

var joystick := VirtualJoystick.new()
var look := LookPad.new()
var panel := VillagePanel.new()
var editor := AnimalEditor.new()
var summary := VillageSummary.new()
var overhead := false
var _map := Control.new()
var _foot: Array[Control] = []
var _rally: TouchButton
var _status := Label.new()
var _notice := Label.new()
var _notice_time := 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.shared()
	add_child(root)
	root.add_child(joystick)
	root.add_child(look)
	_map.anchor_right = 0.62
	_map.anchor_bottom = 1.0
	_map.gui_input.connect(_on_map_input)
	root.add_child(_map)
	_status.position = Vector2(24, 18)
	_status.size = Vector2(760, 200)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTheme.outline(_status, 24)
	root.add_child(_status)
	_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_notice.offset_top = 210.0
	_notice.offset_left = -400.0
	_notice.offset_right = 360.0
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTheme.outline(_notice, 30)
	root.add_child(_notice)
	_foot.append(TouchButton.corner(root, "Back", 20.0, func() -> void: back_pressed.emit()))
	_foot.append(TouchButton.corner(root, "Village view", 110.0,
		func() -> void: view_pressed.emit()))
	_rally = TouchButton.new()
	_rally.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_rally.offset_left = -220.0
	_rally.offset_right = -40.0
	_rally.offset_top = -220.0
	_rally.offset_bottom = -40.0
	_rally.add_theme_font_size_override("font_size", 30)
	_rally.tapped.connect(func() -> void: rally_pressed.emit())
	root.add_child(_rally)
	_foot.append(_rally)
	panel.walk_pressed.connect(func() -> void: view_pressed.emit())
	root.add_child(panel)
	editor.visible = false
	editor.changed.connect(func(recipe: AnimalRecipe) -> void: recipe_changed.emit(recipe))
	editor.closed.connect(_close_evolve)
	root.add_child(editor)
	summary.visible = false
	root.add_child(summary)
	set_overhead(false)


func set_overhead(on: bool) -> void:
	overhead = on
	_show_controls()


## Opens the customizer between generations, `picks` changes allowed.
func open_evolve(picks: int) -> void:
	editor.visible = true
	_show_controls()
	editor.refresh()
	recipe_changed.emit(editor.recipe)
	editor.begin_evolve(picks)


func steering() -> Vector2:
	return Vector2.ZERO if overhead or editor.visible else TouchSteer.read(joystick)


func show_status(text: String) -> void:
	_status.text = text


## Rally's button: ready, or the seconds until it is.
func show_rally(wait: float) -> void:
	_rally.text = "Rally" if wait <= 0.0 else "Rally\n%d s" % ceili(wait)
	_rally.modulate.a = 1.0 if wait <= 0.0 else 0.6


func show_summary(text: String) -> void:
	summary.open(text)
	_show_controls()


func flash(text: String) -> void:
	_notice.text = text
	_notice_time = 4.5


func _process(delta: float) -> void:
	_notice_time -= delta
	_notice.visible = _notice_time > 0.0


func _close_evolve() -> void:
	editor.end_evolve()
	editor.visible = false
	_show_controls()
	evolve_finished.emit()


func _show_controls() -> void:
	var busy := editor.visible or summary.visible
	var walking := not overhead and not busy
	for control in _foot:
		control.visible = walking
	look.enabled = walking
	joystick.set_process_input(walking)
	if not walking:
		joystick.release()
	panel.visible = overhead and not busy
	_map.visible = overhead and not busy


func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			var screen := get_viewport().get_visible_rect().size
			map_tapped.emit(click.global_position / screen, screen.x / screen.y)
