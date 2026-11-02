class_name SpeciesReadout
extends PanelContainer
## Top-left HUD card: how many cells the species has, births this
## generation, and the typical member's traits in real units.

var _title: Label
var _traits: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PANEL, 14))
	position = Vector2(20, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(_title)
	_traits = Label.new()
	_traits.add_theme_font_size_override("font_size", 19)
	_traits.add_theme_color_override("font_color", UiTheme.DIM)
	column.add_child(_traits)


func show_species(population: int, births: int, averages: Dictionary) -> void:
	_title.text = "Your species: %d cells   +%d born" % [population, births]
	var parts := PackedStringArray()
	var typical := StatSheet.typical(averages)
	for t in ["size", "speed", "sense", "armor", "toxin", "jaw"]:
		parts.append(StatSheet.trait_text(t, typical))
	_traits.text = "%s\n%s" % ["   ".join(parts.slice(0, 3)), "   ".join(parts.slice(3))]
	reset_size()
