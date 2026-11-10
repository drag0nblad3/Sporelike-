class_name DiscoveryPick
extends PanelContainer
## The stage 4 discovery screen: a villager has figured something out, and
## the player picks which of two discoveries from that job's line it was.
## Emits picked with the chosen Discovery id.

signal picked(id: String)

## The discoveries on offer now.
var offers: Array[String] = []
var _title := Label.new()
var _known := Label.new()
var _choices: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(860, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", UiTheme.ACCENT)
	box.add_child(_title)
	for k in 2:
		var choice := Button.new()
		choice.custom_minimum_size = Vector2(0, 130)
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.add_theme_font_size_override("font_size", 24)
		choice.pressed.connect(func() -> void: picked.emit(offers[k]))
		box.add_child(choice)
		_choices.append(choice)
	_known.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_known.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_known.add_theme_font_size_override("font_size", 20)
	_known.add_theme_color_override("font_color", UiTheme.DIM)
	box.add_child(_known)


func open(job: int, choices: Array[String], known: String) -> void:
	offers = choices
	_title.text = "A %s has figured something out! What was it?" % Discovery.learner(job)
	for k in _choices.size():
		_choices[k].visible = k < offers.size()
		if k < offers.size():
			_choices[k].text = "%s\n%s" % [Discovery.title(offers[k]), Discovery.text(offers[k])]
	_known.text = "Already known: " + known
	visible = true
