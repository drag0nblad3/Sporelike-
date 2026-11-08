class_name AnimalEditor
extends PanelContainer
## The stage 3 body customizer: a panel down the right side of the screen
## with a scrolling list of AnimalEditRow (body, segments, legs, stance,
## arms, eyes, neck, colours...), plus Random and Done. Every change
## rebuilds the animal at once (changed), so the player sees it while
## picking. Holds the AnimalRecipe it edits. Options still locked by
## LandUnlocks are skipped, with a line saying where to unlock them, and
## Unlock all frees them for testing.

signal changed(recipe: AnimalRecipe)
signal closed

var recipe := AnimalRecipe.new()
var unlocks := LandUnlocks.new()
var _locked := Label.new()
var _rows: Array[AnimalEditRow] = []


func _ready() -> void:
	anchor_left = VirtualJoystick.ACTIVE_AREA
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 8.0
	offset_right = -12.0
	offset_top = 12.0
	offset_bottom = -12.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)
	var title := Label.new()
	title.text = "Customize"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	top.add_child(title)
	top.add_child(_button("Random", randomize_all))
	top.add_child(_button("Unlock all", func() -> void:
		unlocks.unlock_all()
		refresh()))
	var done := _button("Done", func() -> void: closed.emit())
	UiTheme.primary(done)
	top.add_child(done)
	_locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_locked.add_theme_font_size_override("font_size", 20)
	_locked.add_theme_color_override("font_color", UiTheme.DIM)
	box.add_child(_locked)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for row: Array in AnimalRecipe.ROWS:
		var line := AnimalEditRow.new()
		line.setup(row[0], row[1])
		line.stepped.connect(_on_stepped)
		list.add_child(line)
		_rows.append(line)
	refresh()


func randomize_all() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	recipe.roll(rng)
	unlocks.fix(recipe)
	refresh()
	changed.emit(recipe)


func _on_stepped(key: String, step: int) -> void:
	recipe.shift(key, step)
	var tries := 0
	while unlocks.is_locked(key, recipe.value(key)) and tries < 12:
		recipe.shift(key, step)
		tries += 1
	refresh()
	changed.emit(recipe)


func refresh() -> void:
	_locked.text = unlocks.locked_text()
	for line in _rows:
		line.show_value(recipe.value(line.key))


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 60)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	return button
