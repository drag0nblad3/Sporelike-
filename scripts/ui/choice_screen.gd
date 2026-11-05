class_name ChoiceScreen
extends Control
## A paused full-screen choice between a few big cards, each with a name,
## what it means and its numbers. Used for the colony's feeding style and
## its final body at the end of the multicellular stage.

signal chosen(id: String)

var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.shared()
	visible = false
	var shade := ColorRect.new()
	shade.color = UiTheme.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PANEL, 28))
	center.add_child(card)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	card.add_child(_box)


## cards: [id, name, text, colour] each.
func open(title: String, subtitle: String, cards: Array) -> void:
	for child in _box.get_children():
		child.queue_free()
	var heading := _label(title, 34)
	heading.add_theme_color_override("font_color", UiTheme.ACCENT)
	_label(subtitle, 22)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_box.add_child(row)
	for item in cards:
		var entry: Array = item
		row.add_child(_card(str(entry[0]), str(entry[1]), str(entry[2]), entry[3]))
	visible = true


func _card(id: String, title: String, text: String, tint: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(300, 260)
	button.add_theme_font_size_override("font_size", 21)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text = "%s\n%s" % [title, text]
	button.add_theme_color_override("font_color", tint.lightened(0.35))
	button.pressed.connect(func() -> void:
		visible = false
		chosen.emit(id))
	return button


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(940, 0)
	UiTheme.outline(label, size)
	_box.add_child(label)
	return label
