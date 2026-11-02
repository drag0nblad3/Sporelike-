class_name PopulationScreen
extends Control
## Shown between generations while the game is paused: how the species
## changed, what killed it, and three mutations the player can encourage.

signal chosen(choice: MutationChoice)

const BAR_WIDTH := 260.0
const MARGIN := 24.0
const UP := UiTheme.GAIN
const DOWN := UiTheme.LOSS

var _card: PanelContainer
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

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PANEL, 28))
	add_child(_card)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	_card.add_child(_box)
	get_viewport().size_changed.connect(_fit)


func open(stats: GenerationStats, choices: Array[MutationChoice], you: Genome,
		heading: String) -> void:
	for child in _box.get_children():
		child.queue_free()

	var title := "Generation %d complete" % stats.number
	if stats.ended_by == "eaten":
		title = "You were eaten. Generation %d ends" % stats.number
	elif stats.ended_by == "starved":
		title = "You starved. Generation %d ends" % stats.number
	var title_label := _add_label(title, 36)
	title_label.add_theme_color_override("font_color",
		UiTheme.ACCENT if stats.ended_by == "time" else UiTheme.LOSS)
	_add_label("Population %d to %d   births %d   eaten %d   starved %d" % [
		stats.start_population, stats.end_population, stats.births,
		stats.deaths["eaten"], stats.deaths["starved"]], 22)

	var typical := StatSheet.typical(stats.end_averages)
	for t in Genome.TRAITS:
		_add_trait_row(t, stats.end_averages.get(t, 0.0), stats.change(t),
			StatSheet.trait_text(t, typical))

	_add_label("You gathered %d energy, %d%% of what your body burns in a generation:" % [
		roundi(stats.energy_gained), roundi(stats.fed_ratio() * 100.0)], 22)
	_add_label("your choice counts x%.1f" % stats.influence(), 22)
	if stats.progress_text != "":
		_add_label(stats.progress_text, 22)
	for line in [stats.habit_text, stats.adapt_text, stats.hunter_text, stats.rival_text]:
		if line != "":
			_add_label(line, 22)
	var ask := _add_label(heading, 26)
	ask.add_theme_color_override("font_color", UiTheme.GOLD)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(row)
	for c in choices:
		var button := PickCard.new(c.label(), c.effect(you, stats.influence()))
		button.add_icon(UpgradeIcon.make(c))
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
	_card.reset_size()
	var content := _card.get_combined_minimum_size()
	if content.x <= 0.0 or content.y <= 0.0:
		return
	var fit_x := (screen.x - MARGIN * 2.0) / content.x
	var fit_y := (screen.y - MARGIN * 2.0) / content.y
	var s := minf(1.0, minf(fit_x, fit_y))
	_card.scale = Vector2(s, s)
	_card.position = (screen - content * s) / 2.0


func _pick(choice: MutationChoice) -> void:
	visible = false
	chosen.emit(choice)


func _add_trait_row(trait_name: String, value: float, change: float, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_box.add_child(row)

	var name_label := _make_label(TraitNames.of(trait_name), 22)
	name_label.custom_minimum_size = Vector2(110, 0)
	row.add_child(name_label)

	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.12)
	track.custom_minimum_size = Vector2(BAR_WIDTH, 22)
	row.add_child(track)
	var fill := ColorRect.new()
	fill.color = Color(0.45, 0.85, 1.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(BAR_WIDTH * clampf(value, 0.0, 1.0), 22)
	track.add_child(fill)

	var shown := change if absf(change) >= 0.005 else 0.0
	var delta_label := _make_label("%+.2f" % shown, 22)
	if absf(change) >= 0.005:
		delta_label.modulate = UP if change > 0.0 else DOWN
	delta_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(delta_label)
	var detail_label := _make_label(detail, 22)
	detail_label.modulate = Color(1, 1, 1, 0.75)
	row.add_child(detail_label)


func _add_label(text: String, size: int) -> Label:
	var label := _make_label(text, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(label)
	return label


func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label
