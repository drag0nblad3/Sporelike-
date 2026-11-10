class_name VillageSummary
extends PanelContainer
## The end of a stage 4 run: how it went (VillageRun.summary) with New
## valley (another run somewhere else) and Back to title.

signal new_valley
signal back_pressed

var _text := Label.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(760, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 28)
	box.add_child(_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	var again := Button.new()
	again.text = "New valley"
	again.custom_minimum_size = Vector2(260, 72)
	again.pressed.connect(func() -> void: new_valley.emit())
	UiTheme.primary(again)
	row.add_child(again)
	var back := Button.new()
	back.text = "Back to title"
	back.custom_minimum_size = Vector2(260, 72)
	back.pressed.connect(func() -> void: back_pressed.emit())
	row.add_child(back)


func open(text: String) -> void:
	_text.text = text
	visible = true
