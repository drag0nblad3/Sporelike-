class_name PauseMenu
extends Control
## Pauses the game and shows the glossary of in-game terms. Opened from the
## HUD's pause button or Esc; Resume (or Esc again) closes it.

signal quit_requested

const MARGIN := 32

var _text: RichTextLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.03, 0.06, 0.9)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var frame := MarginContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	frame.add_child(column)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	buttons.add_child(_button("Resume", close))
	buttons.add_child(_button("Save and quit", _on_quit))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 22)
	_text.add_theme_font_size_override("bold_font_size", 22)
	_text.text = Glossary.TEXT
	scroll.add_child(_text)


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
	visible = true


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
	button.custom_minimum_size = Vector2(240, 72)
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(action)
	return button
