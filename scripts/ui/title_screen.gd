class_name TitleScreen
extends CanvasLayer
## The first screen: the game's name, Continue (only when a save exists)
## and New Game. Starting a new game over a save asks to confirm first.

signal new_game
signal continue_game

var _continue: Button
var _new: Button
var _confirming := false
var _has_save := false


func _ready() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.08, 0.14)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
	add_child(column)

	var title := Label.new()
	title.text = "Sporelike"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.55, 0.95, 0.85))
	column.add_child(title)

	var tagline := Label.new()
	tagline.text = "Guide a species from a single cell upward."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 24)
	column.add_child(tagline)

	_continue = _button("Continue", func() -> void: continue_game.emit())
	column.add_child(_continue)
	_new = _button("New Game", _on_new_pressed)
	column.add_child(_new)


## Shows the title; Continue appears only when there is a save to load.
func open(has_save: bool) -> void:
	_has_save = has_save
	_confirming = false
	_continue.visible = has_save
	_new.text = "New Game"
	visible = true


func _on_new_pressed() -> void:
	if _has_save and not _confirming:
		_confirming = true
		_new.text = "Tap again: erase save"
		return
	new_game.emit()


func _button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(360, 84)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(action)
	return button
