class_name OtherSpeciesPanel
extends MenuPanel
## Opened from the population screen's "Other species" button: how the rival
## species and each kind of hunter fared this generation, in large text.


func _ready() -> void:
	super._ready()
	visible = false


func open(stats: GenerationStats) -> void:
	clear()
	label("Other species this generation", 36, UiTheme.ACCENT)
	_section("Rival species", stats.rival_text.trim_prefix("Rival species: "))
	_section("Hunters", stats.hunter_text)
	button("Back", close)
	visible = true


func close() -> void:
	visible = false


func _section(heading: String, text: String) -> void:
	if text == "":
		return
	label(heading, 30, UiTheme.GOLD)
	for line in text.split("\n"):
		label(line, 26)
