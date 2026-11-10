class_name AnimalEditRow
extends HBoxContainer
## One row of the stage 3 body customizer (AnimalEditor): the row's name,
## then < value > buttons that step through its options.

signal stepped(key: String, step: int)

var key := ""
var _value := Label.new()


func setup(row_key: String, label: String) -> void:
	key = row_key
	add_theme_constant_override("separation", 6)
	var name_label := Label.new()
	name_label.text = label
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", UiTheme.DIM)
	add_child(name_label)
	add_child(_arrow("<", -1))
	_value.custom_minimum_size = Vector2(130, 0)
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value.add_theme_font_size_override("font_size", 22)
	add_child(_value)
	add_child(_arrow(">", 1))


func show_value(text: String) -> void:
	_value.text = text


func _arrow(text: String, step: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(64, 54)
	button.pressed.connect(func() -> void: stepped.emit(key, step))
	return button
