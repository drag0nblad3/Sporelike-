class_name PopulationScreen
extends Control
## Shown between generations while the game is paused: how the species
## changed, what killed it, and three mutations the player can encourage.

signal chosen(choice: MutationChoice)

const BAR_WIDTH := 260.0
const MARGIN := 24.0
const UP := Color(0.5, 1.0, 0.55)
const DOWN := Color(1.0, 0.55, 0.45)

var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.03, 0.06, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	get_viewport().size_changed.connect(_fit)


func open(stats: GenerationStats, choices: Array[MutationChoice]) -> void:
	for child in _box.get_children():
		child.queue_free()

	var title := "Generation %d complete" % stats.number
	if stats.ended_by == "eaten":
		title = "You were eaten. Generation %d ends" % stats.number
	elif stats.ended_by == "starved":
		title = "You starved. Generation %d ends" % stats.number
	_add_label(title, 34)
	_add_label("Population %d to %d   births %d   eaten %d   starved %d" % [
		stats.start_population, stats.end_population, stats.births,
		stats.deaths["eaten"], stats.deaths["starved"]], 22)

	for t in Genome.TRAITS:
		_add_trait_row(t, stats.end_averages.get(t, 0.0), stats.change(t))

	_add_label("You ate %d food: your choice counts x%.1f" % [
		stats.food_eaten, stats.influence()], 22)
	if stats.progress_text != "":
		_add_label(stats.progress_text, 22)
	_add_label("Encourage a mutation in your species:", 24)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(row)
	for c in choices:
		var button := Button.new()
		button.text = c.label()
		button.custom_minimum_size = Vector2(250, 80)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(func() -> void: _pick(c))
		row.add_child(button)
	visible = true
	# Wait one frame for the layout to settle, then shrink it onto the screen.
	await get_tree().process_frame
	_fit()


## Scales the content down (never up) so all of it, buttons included, fits
## inside the visible screen with a margin, and centers it.
func _fit() -> void:
	if not visible:
		return
	var screen := get_viewport_rect().size
	_box.reset_size()
	var content := _box.get_combined_minimum_size()
	if content.x <= 0.0 or content.y <= 0.0:
		return
	var fit_x := (screen.x - MARGIN * 2.0) / content.x
	var fit_y := (screen.y - MARGIN * 2.0) / content.y
	var s := minf(1.0, minf(fit_x, fit_y))
	_box.scale = Vector2(s, s)
	_box.position = (screen - content * s) / 2.0


func _pick(choice: MutationChoice) -> void:
	visible = false
	chosen.emit(choice)


func _add_trait_row(trait_name: String, value: float, change: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_box.add_child(row)

	var name_label := _make_label(trait_name.capitalize(), 22)
	name_label.custom_minimum_size = Vector2(110, 0)
	row.add_child(name_label)

	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.12)
	track.custom_minimum_size = Vector2(BAR_WIDTH, 22)
	row.add_child(track)
	var fill := ColorRect.new()
	fill.color = Color(0.45, 0.85, 1.0)
	fill.size = Vector2(BAR_WIDTH * clampf(value, 0.0, 1.0), 22)
	track.add_child(fill)

	var delta_label := _make_label("%+.2f" % change, 22)
	if absf(change) >= 0.005:
		delta_label.modulate = UP if change > 0.0 else DOWN
	row.add_child(delta_label)


func _add_label(text: String, size: int) -> void:
	var label := _make_label(text, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(label)


func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label
