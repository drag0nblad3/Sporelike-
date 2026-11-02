class_name GenerationReadout
extends PanelContainer
## Top-right HUD card: the generation number, seconds left, and how well fed
## the player is this generation (gold below 100%, green at or above).

var _title: Label
var _detail: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PANEL, 14))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -260.0
	offset_right = -20.0
	offset_top = 46.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)
	_title = _label(30, UiTheme.ACCENT)
	column.add_child(_title)
	_detail = _label(24, UiTheme.INK)
	column.add_child(_detail)


func show_generation(number: int, seconds_left: float, fed: float) -> void:
	_title.text = "Generation %d" % number
	_detail.text = "%ds left   Fed %d%%" % [ceili(maxf(seconds_left, 0.0)), roundi(fed * 100.0)]
	_detail.add_theme_color_override("font_color",
		UiTheme.GAIN if fed >= 1.0 else UiTheme.GOLD)


func _label(font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	return label
