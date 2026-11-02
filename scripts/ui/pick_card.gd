class_name PickCard
extends Button
## One mutation choice on the population screen: a big tappable card with
## the pick's name on top and each stat change on its own line below.
## Energy costs are tinted so the tradeoff stands out.

const WIDTH := 320.0

var _column: VBoxContainer


func _init(title: String, effect: String) -> void:
	custom_minimum_size = Vector2(WIDTH, 150)
	size_flags_vertical = Control.SIZE_FILL
	var column := VBoxContainer.new()
	_column = column
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 18.0
	column.offset_right = -18.0
	column.offset_top = 14.0
	column.offset_bottom = -14.0
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	var heading := _line(title, 26, UiTheme.ACCENT)
	column.add_child(heading)
	var rule := ColorRect.new()
	rule.color = Color(UiTheme.ACCENT, 0.3)
	rule.custom_minimum_size = Vector2(0, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	for line in effect.split("\n"):
		var tint := UiTheme.COST if line.begins_with("Energy use") else UiTheme.INK
		column.add_child(_line(line, 21, tint))


## Puts a drawing of the pick (UpgradeIcon) above the name.
func add_icon(icon: Control) -> void:
	_column.add_child(icon)
	_column.move_child(icon, 0)


## The button grows to fit the text it holds (a Button ignores its children).
func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y,
		_column.get_combined_minimum_size().y + 28.0)


func _line(words: String, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = WIDTH - 36.0
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
