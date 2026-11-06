class_name PauseMenu
extends Control
## Pauses the game and shows the glossary of in-game terms. Opened from the
## HUD's pause button or Esc; Resume (or Esc again) closes it. "Save this
## cell" keeps the player's current cell in the OrganismCollection.

signal quit_requested
signal save_cell_requested

const MARGIN := 32

var _text: RichTextLabel
var _note: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.shared()
	visible = false

	var shade := ColorRect.new()
	shade.color = UiTheme.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	frame.add_child(column)

	var heading := Label.new()
	heading.text = "Paused"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 40)
	heading.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(heading)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_font_size_override("font_size", 24)
	_note.add_theme_color_override("font_color", UiTheme.GAIN)
	column.add_child(_note)
	var resume := _button("Resume", close)
	UiTheme.primary(resume)
	buttons.add_child(resume)
	buttons.add_child(_button("Save this cell", func() -> void: save_cell_requested.emit()))
	buttons.add_child(_button("Save and quit", _on_quit))

	# The label scrolls itself. (A fit_content label inside a ScrollContainer
	# that starts hidden never got a height, so the text did not show.)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 24)
	_text.add_theme_font_size_override("bold_font_size", 24)
	_text.add_theme_color_override("default_color", UiTheme.INK)
	_text.get_v_scroll_bar().custom_minimum_size.x = 40.0
	_text.text = Glossary.TEXT
	var page := PanelContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PANEL, 22))
	page.add_child(_text)
	column.add_child(page)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


## Pauses the game, unless something else (the population screen) already has.
func open() -> void:
	if visible or get_tree().paused:
		return
	get_tree().paused = true
	# Fill the screen explicitly: anchors alone left this menu zero-sized
	# on device, which hid the shade and squashed the text to nothing.
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_note.text = ""
	visible = true


## A short line under the buttons, such as "Cell saved".
func show_note(text: String) -> void:
	_note.text = text


## Height of the glossary text as laid out; CI checks it is not blank.
func text_height() -> int:
	return _text.get_content_height()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func _on_quit() -> void:
	visible = false
	quit_requested.emit()


func _button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(250, 80)
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(action)
	return button
