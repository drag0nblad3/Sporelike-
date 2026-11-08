class_name TitleScreen
extends CanvasLayer
## The first screen: the game's name, Continue (only when a save exists),
## New subspecies (opens the SubspeciesCreator) and Test stage 2 (a
## made-up evolved species that goes straight to the multicellular switch,
## without touching the save) and Test stage 3 (the land animal feel test,
## AnimalLab). Starting a new run over a save asks to confirm first.

signal new_game
signal continue_game
signal test_stage_two
signal test_stage_three

var _continue: Button
var _new: Button
var _confirming := false
var _has_save := false


func _ready() -> void:
	add_child(TitleBackdrop.new())

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	column.theme = UiTheme.shared()
	add_child(column)

	var title := Label.new()
	title.text = "Sporelike"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	UiTheme.outline(title, 96)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.2, 0.22, 0.9))
	title.add_theme_constant_override("outline_size", 10)
	column.add_child(title)

	var tagline := Label.new()
	tagline.text = "Guide a species from a single cell upward."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 26)
	tagline.add_theme_color_override("font_color", UiTheme.DIM)
	column.add_child(tagline)

	_continue = _button("Continue", func() -> void: continue_game.emit())
	column.add_child(_continue)
	_new = _button("New subspecies", _on_new_pressed)
	column.add_child(_new)
	var test := _button("Test stage 2", func() -> void: test_stage_two.emit())
	test.custom_minimum_size = Vector2(300, 64)
	test.add_theme_font_size_override("font_size", 24)
	test.modulate = Color(1, 1, 1, 0.75)
	column.add_child(test)
	var land := _button("Test stage 3", func() -> void: test_stage_three.emit())
	land.custom_minimum_size = Vector2(300, 64)
	land.add_theme_font_size_override("font_size", 24)
	land.modulate = Color(1, 1, 1, 0.75)
	column.add_child(land)

	var footer := Label.new()
	footer.text = "Early playtest build"
	footer.add_theme_font_size_override("font_size", 18)
	footer.add_theme_color_override("font_color", Color(UiTheme.DIM, 0.5))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.offset_right = -24.0
	footer.offset_bottom = -16.0
	footer.offset_left = -24.0
	footer.offset_top = -16.0
	add_child(footer)


## Shows the title; Continue appears only when there is a save to load.
func open(has_save: bool) -> void:
	_has_save = has_save
	_confirming = false
	_continue.visible = has_save
	_new.text = "New subspecies"
	# The main way forward is filled in: Continue when there is a save.
	UiTheme.primary(_continue)
	if has_save:
		UiTheme.plain(_new)
	else:
		UiTheme.primary(_new)
	visible = true


func _on_new_pressed() -> void:
	if _has_save and not _confirming:
		_confirming = true
		_new.text = "Tap again: abandon run"
		return
	new_game.emit()


func _button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(380, 90)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(action)
	return button
