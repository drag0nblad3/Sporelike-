class_name PopulationScreen
extends Control
## Shown between generations while the game is paused: how the species
## changed, what killed it, and three mutations the player can encourage.
## Rivals and hunters sit behind the "Other species" button (OtherSpeciesPanel).

signal chosen(choice: MutationChoice)

const MARGIN := 24.0
const NOTES_WIDTH := 520.0

var _card: PanelContainer
var _box: VBoxContainer
var _others: OtherSpeciesPanel
var _stats: GenerationStats


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
	_others = OtherSpeciesPanel.new()
	add_child(_others)
	get_viewport().size_changed.connect(_fit)


func open(stats: GenerationStats, choices: Array[MutationChoice], you: Genome,
		heading: String) -> void:
	_stats = stats
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()

	var title := "Generation %d complete" % stats.number
	if stats.ended_by == "eaten":
		title = "You were eaten. Generation %d ends" % stats.number
	elif stats.ended_by == "starved":
		title = "You starved. Generation %d ends" % stats.number
	var title_label := _add_label(title, 40)
	title_label.add_theme_color_override("font_color",
		UiTheme.ACCENT if stats.ended_by == "time" else UiTheme.LOSS)
	_add_label("Population %d to %d   births %d   eaten %d   starved %d" % [
		stats.start_population, stats.end_population, stats.births,
		stats.deaths["eaten"], stats.deaths["starved"]], 26)

	var middle := HBoxContainer.new()
	middle.add_theme_constant_override("separation", 32)
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(middle)
	middle.add_child(TraitRows.new(stats))
	middle.add_child(_notes(stats))

	var ask := _add_label(heading, 30)
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


## The right-hand column: how well the player fed, stage progress, habits,
## and a button that opens the other species' results.
func _notes(stats: GenerationStats) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lines: Array[String] = [
		"You gathered %d energy, %d%% of what your body burns. Your choice counts x%.1f" % [
			roundi(stats.energy_gained), roundi(stats.fed_ratio() * 100.0), stats.influence()],
		stats.progress_text, stats.adapt_text, stats.habit_text]
	for line in lines:
		if line != "":
			var label := _make_label(line, 24)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = NOTES_WIDTH
			column.add_child(label)
	if stats.rival_text != "" or stats.hunter_text != "":
		var others := Button.new()
		others.text = "Other species"
		others.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		others.pressed.connect(open_others)
		column.add_child(others)
	return column


## Shows how the rival species and hunters fared this generation.
func open_others() -> void:
	_others.open(_stats)


func close_others() -> void:
	_others.close()


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
	close_others()
	chosen.emit(choice)


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
