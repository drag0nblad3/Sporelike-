class_name CellPickScreen
extends Control
## Shown between multicellular generations while the game is paused: how
## the colony fed, and three kinds of cell to grow next. Each choice says
## how many cells the body's symmetry adds and what they cost to run.

signal chosen(role: String)

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


func open(stats: GenerationStats, plan: BodyPlan, roles: Array[String]) -> void:
	for child in _box.get_children():
		child.queue_free()
	var title := "Generation %d complete" % stats.number
	if stats.ended_by == "starved":
		title = "Your colony starved. Generation %d ends" % stats.number
	var heading := _label(title, 34)
	heading.add_theme_color_override("font_color",
		UiTheme.ACCENT if stats.ended_by == "time" else UiTheme.LOSS)
	_label("%s body, %d cells. You gathered %d energy, %d%% of what your body burns." % [
		Symmetry.label(plan.symmetry), plan.parts.size(), roundi(stats.energy_gained),
		roundi(stats.fed_ratio() * 100.0)], 22)
	_label("Grow a new kind of cell:", 24)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_box.add_child(row)
	for role in roles:
		row.add_child(_choice(plan, role))
	var skip := Button.new()
	skip.text = "Keep the body as it is"
	skip.custom_minimum_size = Vector2(0, 60)
	skip.add_theme_color_override("font_color", UiTheme.DIM)
	skip.pressed.connect(func() -> void: chosen.emit(""))
	_box.add_child(skip)
	visible = true


func _choice(plan: BodyPlan, role: String) -> Button:
	var trial := BodyPlan.from_dict(plan.to_dict())
	var added := trial.grow(role)
	var row: Array = BodyPart.ROLES.get(role, BodyPart.ROLES["skin"])
	var about: String = row[1]
	var card: PickCard
	if added == 0:
		card = PickCard.new(BodyPart.label(role), "No room left on the body")
		card.disabled = true
	else:
		var lines: Array[String] = [about]
		var effect := CellEffects.card_line(role, plan, added)
		if effect != "":
			lines.append(effect)
		var ability := ColonyAbility.card_line(role, trial)
		if ability != "":
			lines.append(ability)
		lines.append("Energy use +%.2f/s" % (Colony.UPKEEP_PER_CELL * added))
		card = PickCard.new("+%d %s" % [added, BodyPart.label(role)], "\n".join(PackedStringArray(lines)))
	card.tint_title(BodyPart.color(role).lightened(0.35))
	card.pressed.connect(func() -> void: chosen.emit(role))
	return card


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(940, 0)
	UiTheme.outline(label, size)
	_box.add_child(label)
	return label
