class_name VillagePanel
extends PanelContainer
## The overhead view's command panel in stage 4, down the right side:
## how many villagers Gather, Hunt and Guard (minus and plus), the four
## buildings to raise or upgrade, the Alarm, clearing the focus flag and
## going back to walking as the elder. Broad orders only.

signal job_changed(job: int, step: int)
signal build_pressed(id: String)
signal alarm_pressed
signal flag_cleared
signal walk_pressed

var _counts := {}
var _resting := Label.new()
var _builds := {}
var _alarm: Button


func _ready() -> void:
	anchor_left = 0.62
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 8.0
	offset_right = -12.0
	offset_top = 12.0
	offset_bottom = -12.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	add_child(box)
	for job in VillageJob.WORKING:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 26)
		row.add_child(label)
		row.add_child(_button("-", func() -> void: job_changed.emit(job, -1), 76))
		row.add_child(_button("+", func() -> void: job_changed.emit(job, 1), 76))
		box.add_child(row)
		_counts[job] = label
	_resting.add_theme_font_size_override("font_size", 20)
	_resting.add_theme_color_override("font_color", UiTheme.DIM)
	_resting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_resting)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	box.add_child(grid)
	for id in VillageBuilding.ALL:
		var build := _button("", func() -> void: build_pressed.emit(id), 0)
		build.custom_minimum_size = Vector2(0, 92)
		build.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		build.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		build.add_theme_font_size_override("font_size", 18)
		grid.add_child(build)
		_builds[id] = build
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	box.add_child(row)
	_alarm = _button("Alarm", func() -> void: alarm_pressed.emit(), 0)
	_alarm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_alarm)
	var clear := _button("Clear flag", func() -> void: flag_cleared.emit(), 0)
	clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(clear)
	var walk := _button("Walk as the elder", func() -> void: walk_pressed.emit(), 0)
	UiTheme.primary(walk)
	box.add_child(walk)


func refresh(village: Village) -> void:
	for job in VillageJob.WORKING:
		(_counts[job] as Label).text = "%s  %d" % [VillageJob.title(job), village.jobs.count(job)]
	var spare := village.villagers.size() - village.jobs.total()
	var doing := "building" if village.buildings.active != "" else "resting"
	_resting.text = "%d %s  ·  tap the map to set where to work%s" % [spare, doing,
		"" if village.flag == Vector3.INF else " (flag set)"]
	for id in VillageBuilding.ALL:
		var level := village.buildings.level(id)
		var button: Button = _builds[id]
		var next := VillageBuilding.next_effect(id, level)
		button.disabled = next == "" or village.buildings.active != ""
		var head := "%s  L%d" % [VillageBuilding.title(id), level]
		if id == village.buildings.active:
			button.text = "%s\nBuilding %d%%" % [head, roundi(village.buildings.share() * 100.0)]
		else:
			button.text = head + ("\nDone" if next == "" else "\n" + next)
	_alarm.text = "Alarm is ON" if village.alarm else "Alarm"


func _button(text: String, action: Callable, width: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 62)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	return button
