class_name TraitRows
extends VBoxContainer
## The population screen's trait table: one row per trait with a bar for the
## species average, its change this generation, and the value in real units.

const BAR_WIDTH := 200.0
const FONT := 24
const UP := UiTheme.GAIN
const DOWN := UiTheme.LOSS


func _init(stats: GenerationStats) -> void:
	add_theme_constant_override("separation", 4)
	var typical := StatSheet.typical(stats.end_averages)
	for t in Genome.TRAITS:
		var value: float = stats.end_averages.get(t, 0.0)
		_add_row(t, value, stats.change(t), StatSheet.trait_text(t, typical))


func _add_row(trait_name: String, value: float, change: float, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	var name_label := _label(TraitNames.of(trait_name))
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)

	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.12)
	track.custom_minimum_size = Vector2(BAR_WIDTH, 22)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(track)
	var fill := ColorRect.new()
	fill.color = Color(0.45, 0.85, 1.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size = Vector2(BAR_WIDTH * clampf(value, 0.0, 1.0), 22)
	track.add_child(fill)

	var moved := absf(change) >= 0.005
	var delta_label := _label("%+.2f" % (change if moved else 0.0))
	if moved:
		delta_label.add_theme_color_override("font_color", UP if change > 0.0 else DOWN)
	delta_label.custom_minimum_size = Vector2(76, 0)
	row.add_child(delta_label)
	var detail_label := _label(detail)
	detail_label.add_theme_color_override("font_color", UiTheme.DIM)
	row.add_child(detail_label)


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT)
	return label
