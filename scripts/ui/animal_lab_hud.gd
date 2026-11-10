class_name AnimalLabHud
extends CanvasLayer
## Controls for the stage 3 feel-test lab: the joystick on the left, the
## look pad on the right, a status line (the body, the frame rate and the
## LandGoals progress), short notices (flash), New body, Customize (opens
## the AnimalEditor over the look pad), Nest here, Back, Call (kin come to
## the player) and, once the family is ready, Found a village.

signal new_body_pressed
signal nest_pressed
signal call_pressed
signal found_pressed
## The player finished a generation's evolving (begin with open_evolve).
signal evolve_finished
signal back_pressed
signal recipe_changed(recipe: AnimalRecipe)

var joystick := VirtualJoystick.new()
var look := LookPad.new()
var editor := AnimalEditor.new()
var tips := TipBanner.new()
## The status line's heading.
var title := "Stage 3 test"
var _test_only: Array[Button] = []
var _corners: Array[Button] = []
var _call: TouchButton
var _found: Button
var _can_found := false
var _status: Label
var _hint: Label
var _notice: Label
var _notice_time := 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.shared()
	add_child(root)
	root.add_child(joystick)
	root.add_child(look)
	_status = Label.new()
	_status.position = Vector2(24, 18)
	_status.size = Vector2(900, 180)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTheme.outline(_status, 26)
	root.add_child(_status)
	_hint = Label.new()
	_hint.text = "Left thumb: walk   ·   Right thumb: look around"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -70.0
	_hint.offset_left = -420.0
	_hint.offset_right = 420.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.outline(_hint, 24)
	root.add_child(_hint)
	_corner(root, "Back", 20.0, func() -> void: back_pressed.emit())
	_corner(root, "New body", 110.0, func() -> void: new_body_pressed.emit())
	_corner(root, "Free edit", 200.0, open_editor)
	_test_only = [_corners[1], _corners[2]]
	_corner(root, "Nest here", 290.0, func() -> void: nest_pressed.emit())
	_corner(root, "Found a village", 380.0, func() -> void: found_pressed.emit())
	_found = _corners[-1]
	_found.visible = false
	UiTheme.primary(_found)
	_call = TouchButton.new()
	_call.text = "Call"
	_call.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_call.offset_left = -200.0
	_call.offset_right = -40.0
	_call.offset_top = -200.0
	_call.offset_bottom = -40.0
	_call.tapped.connect(func() -> void: call_pressed.emit())
	root.add_child(_call)
	_notice = Label.new()
	_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_notice.offset_top = 200.0
	_notice.offset_left = -380.0
	_notice.offset_right = 380.0
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTheme.outline(_notice, 30)
	root.add_child(_notice)
	tips.lift = 150.0
	root.add_child(tips)
	editor.visible = false
	editor.changed.connect(func(recipe: AnimalRecipe) -> void: recipe_changed.emit(recipe))
	editor.closed.connect(close_editor)
	root.add_child(editor)


## Shows the customizer with its current recipe and puts that body on.
func open_editor() -> void:
	_show_editor(true)
	editor.refresh()
	recipe_changed.emit(editor.recipe)


## Opens the customizer to evolve between generations, `picks` changes.
func open_evolve(picks: int) -> void:
	open_editor()
	editor.begin_evolve(picks)


func close_editor() -> void:
	var evolving := not editor.budget.off
	editor.end_evolve()
	_show_editor(false)
	if evolving:
		evolve_finished.emit()


func _show_editor(on: bool) -> void:
	editor.visible = on
	look.enabled = not on
	_hint.visible = not on
	for button in _corners:
		button.visible = not on and not (button in _test_only and title != "Stage 3 test")
	_call.visible = not on
	_found.visible = not on and _can_found


## Part of a real run: the test tools (New body, Free edit) go away.
func set_run(subspecies: String) -> void:
	title = "Stage 3  ·  %s" % subspecies
	for button in _test_only:
		button.visible = false


## Shows Found a village once the family is big enough and at the nest.
func show_found(on: bool) -> void:
	_can_found = on
	_found.visible = on and not editor.visible


func steering() -> Vector2:
	return TouchSteer.read(joystick)


func show_status(body: AnimalBody, goals: String) -> void:
	_status.text = "%s  ·  %d FPS\n%s\n%s" % [title, roundi(Engine.get_frames_per_second()),
		body.describe(), goals]


## Shows a short notice near the top for a few seconds.
func flash(text: String) -> void:
	_notice.text = text
	_notice.visible = true
	_notice_time = 3.5


func _process(delta: float) -> void:
	_notice_time -= delta
	_notice.visible = _notice_time > 0.0


func _corner(root: Control, label: String, top: float, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -230.0
	button.offset_right = -20.0
	button.offset_top = top
	button.offset_bottom = top + 72.0
	button.pressed.connect(action)
	root.add_child(button)
	_corners.append(button)
