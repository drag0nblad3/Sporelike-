class_name SubspeciesCreator
extends MenuPanel
## Founding a new subspecies: give it a name, pick the Sea it colonizes,
## choose genes from the main species' unlocked ones up to the gene slots,
## open the gene trees to unlock more, then begin the run.

signal begin(subspecies_name: String, loadout: Array[String], sea_id: String)
signal back

var bank: GeneBank
var _name := ""
var _chosen: Array[String] = []
## Seas in a shuffled order; "Other sea" steps through them.
var _seas: Array[String] = []
var _sea_at := 0
var _rng := RandomNumberGenerator.new()
var _trees: GeneTreeScreen


func _ready() -> void:
	super()
	_rng.randomize()
	_trees = GeneTreeScreen.new()
	_trees.visible = false
	_trees.closed.connect(_refresh)
	add_child(_trees)


func open(with_bank: GeneBank) -> void:
	bank = with_bank
	_name = SubspeciesName.random(_rng)
	_chosen = bank.last_loadout.duplicate()
	_trim()
	_seas = Sea.ids()
	_seas.shuffle()
	_sea_at = 0
	visible = true
	_refresh()


func used_slots() -> int:
	var used := 0
	for id in _chosen:
		used += GeneCatalog.slots(id)
	return used


func _refresh() -> void:
	clear()
	label("Found a subspecies", 36, UiTheme.ACCENT)
	label("A group of your species drifts off to colonize a new sea. If it thrives, "
		+ "its genes flow back to the main species.", 20, UiTheme.DIM)
	var names := row()
	label(_name, 30, UiTheme.GOLD, names)
	var rename := button("New name", func() -> void: _reroll(), names)
	rename.size_flags_horizontal = Control.SIZE_SHRINK_END
	# Wrapping buttons in a row shrink to one letter per line without this.
	rename.custom_minimum_size.x = 200
	_add_sea()
	label("Gene slots used: %d of %d" % [used_slots(), bank.slots()], 24)
	if bank.unlocked.is_empty():
		label("No genes unlocked yet. Runs earn gene points; spend them in the gene trees.",
			20, UiTheme.DIM)
	for id in bank.unlocked:
		_add_gene(id)
	var bottom := row()
	button("Gene trees (%d points)" % bank.points, func() -> void: _open_trees(), bottom)
	button("Back", func() -> void: _leave(), bottom)
	var start := button("Begin the run", func() -> void: _begin())
	start.add_theme_color_override("font_color", UiTheme.ACCENT)


## The sea this subspecies heads for, with a button to try another.
func _add_sea() -> void:
	var sea := Sea.of(_seas[_sea_at])
	var top := row()
	label("New sea: %s" % sea.title, 26, UiTheme.ACCENT, top)
	var other := button("Other sea", func() -> void: _next_sea(), top)
	other.size_flags_horizontal = Control.SIZE_SHRINK_END
	other.custom_minimum_size.x = 200
	label(sea.blurb, 20, UiTheme.DIM)
	label("Does well here: %s" % sea.favors, 20, UiTheme.GAIN)


func _next_sea() -> void:
	_sea_at = (_sea_at + 1) % _seas.size()
	_refresh()


func _add_gene(id: String) -> void:
	var on := id in _chosen
	var mark := "[x] " if on else "[  ] "
	var b := button("%s%s  (%s)\n%s" % [mark, GeneText.label(id), GeneText.slot_text(id),
		GeneText.effect(id)], func() -> void: _toggle(id))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 96
	b.add_theme_font_size_override("font_size", 20)
	b.disabled = not on and used_slots() + GeneCatalog.slots(id) - _form_slots(id) > bank.slots()
	if on:
		b.add_theme_color_override("font_color", UiTheme.GAIN)


## Slots freed if choosing this gene swaps out the current body form.
func _form_slots(id: String) -> int:
	if not GeneCatalog.is_form(id):
		return 0
	var freed := 0
	for other in _chosen:
		if GeneCatalog.is_form(other):
			freed += GeneCatalog.slots(other)
	return freed


func _toggle(id: String) -> void:
	if id in _chosen:
		_chosen.erase(id)
		_refresh()
		return
	# Body forms exclude each other: picking one swaps out any other.
	if GeneCatalog.is_form(id):
		for other in _chosen.duplicate():
			if GeneCatalog.is_form(other):
				_chosen.erase(other)
	if used_slots() + GeneCatalog.slots(id) <= bank.slots():
		_chosen.append(id)
	_refresh()


## Drops remembered genes that no longer fit or are no longer unlocked.
func _trim() -> void:
	var kept: Array[String] = []
	var used := 0
	for id in _chosen:
		if bank.has(id) and used + GeneCatalog.slots(id) <= bank.slots():
			kept.append(id)
			used += GeneCatalog.slots(id)
	_chosen = kept


func _reroll() -> void:
	_name = SubspeciesName.random(_rng)
	_refresh()


func _open_trees() -> void:
	_trees.open(bank)


func _begin() -> void:
	bank.last_loadout = _chosen.duplicate()
	bank.save()
	visible = false
	begin.emit(_name, _chosen.duplicate(), _seas[_sea_at])


func _leave() -> void:
	visible = false
	back.emit()
