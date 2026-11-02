class_name SymmetryPicker
extends Control
## The choice that opens the multicellular stage: radial, bilateral or
## biradial, each with what it means for play and how many cells it starts
## with and grows at a time.

signal chosen(kind: String)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = UiTheme.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	column.add_child(_text("Your cells stay stuck together", 44, UiTheme.ACCENT))
	column.add_child(_text("Choose how your body is arranged. It shapes where every new cell grows.",
		24, UiTheme.DIM))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	column.add_child(row)
	for kind in Symmetry.ALL:
		row.add_child(_card(kind))


func _card(kind: String) -> Control:
	var card := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var button := Button.new()
	button.text = Symmetry.label(kind)
	button.custom_minimum_size = Vector2(320, 76)
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(func() -> void: chosen.emit(kind))
	box.add_child(button)
	var start := BodyPlan.starter(kind)
	var grows := Symmetry.copies(kind, Vector2(1.732, 1.0)).size()
	var about := _text("%s\n\nStarts as %d cells; each new cell grows up to %d copies." % [
		Symmetry.blurb(kind), start.parts.size(), grows], 21, UiTheme.INK)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size = Vector2(320, 0)
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(about)
	return card


func _text(words: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	UiTheme.outline(label, size)
	return label
