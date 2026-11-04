class_name SubspeciesCreator
extends GeneScreen
## Founding a new subspecies: give it a name, pick the Sea it starts in,
## take unlocked genes up to the gene slots (tap a node in the gene trees,
## then Take or Remove in the text box), open the gene trees to unlock
## more, then begin the run. All on one screen.

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
var _view := CreatorSide.new()


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
	graph.selected = _chosen[0] if not _chosen.is_empty() else ""
	_refresh()


func used_slots() -> int:
	var used := 0
	for id in _chosen:
		used += GeneCatalog.slots(id)
	return used


func _build_side() -> void:
	_view.build(self)


func _build_bottom() -> void:
	var bottom := row()
	_view.trees_button = button("", func() -> void: _open_trees(), bottom)
	button("Back", func() -> void: _leave(), bottom)
	var start := button("Begin the run", func() -> void: _begin())
	start.add_theme_color_override("font_color", UiTheme.ACCENT)


func _refresh() -> void:
	_view.show(_name, Sea.of(_seas[_sea_at]), used_slots(), bank)
	redraw_genes()
	if graph.selected == "":
		detail.show_hint("No genes unlocked yet. Runs earn gene points; spend them in the gene trees."
			if bank.unlocked.is_empty() else "Tap an unlocked gene to take it.")


func _style(icon: GeneIcon) -> void:
	var id := icon.gene
	var owned := bank.has(id)
	icon.lit = id in _chosen
	icon.check = icon.lit
	icon.dim = not owned
	icon.badge = str(GeneCatalog.slots(id)) if owned else ""
	icon.badge_color = UiTheme.ACCENT if _fits(id) else UiTheme.COST
	if icon.lit:
		icon.ring = UiTheme.GAIN
	elif owned:
		icon.ring = UiTheme.ACCENT if _fits(id) else Color(UiTheme.INK, 0.6)
	else:
		icon.ring = Color(UiTheme.DIM, 0.35)


func _describe(id: String) -> void:
	var slot_text := GeneText.slot_text(id)
	if id in _chosen:
		detail.show_gene(id, _style, "Taken. Founders are born with it.", UiTheme.GAIN,
			"Remove (frees %s)" % slot_text, true)
	elif not bank.has(id):
		detail.show_gene(id, _style, "Not unlocked yet. Unlock it in the gene trees.",
			UiTheme.LOSS, "", false)
	elif not _fits(id):
		detail.show_gene(id, _style, "Needs %s; %d of %d used." % [slot_text, used_slots(),
			bank.slots()], UiTheme.COST, "Not enough gene slots", false)
	else:
		var swap := _form_taken()
		var note := "Swaps out %s." % GeneText.label(swap) if swap != "" and GeneCatalog.is_form(id) \
			else "Free to take."
		detail.show_gene(id, _style, note, UiTheme.ACCENT, "Take (%s)" % slot_text, true)


func _act(id: String) -> void:
	_toggle(id)


func _fits(id: String) -> bool:
	if id in _chosen:
		return true
	return used_slots() + GeneCatalog.slots(id) - _form_slots(id) <= bank.slots()


## The body form already taken, or "".
func _form_taken() -> String:
	for other in _chosen:
		if GeneCatalog.is_form(other):
			return other
	return ""


## Slots freed if choosing this gene swaps out the current body form.
func _form_slots(id: String) -> int:
	var taken := _form_taken()
	return GeneCatalog.slots(taken) if GeneCatalog.is_form(id) and taken != "" else 0


func _toggle(id: String) -> void:
	graph.selected = id
	if id in _chosen:
		_chosen.erase(id)
		_refresh()
		return
	# Body forms exclude each other: picking one swaps out any other.
	if GeneCatalog.is_form(id) and _fits(id):
		_chosen.erase(_form_taken())
	if bank.has(id) and used_slots() + GeneCatalog.slots(id) <= bank.slots():
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


func reroll() -> void:
	_name = SubspeciesName.random(_rng)
	_refresh()


func next_sea() -> void:
	_sea_at = (_sea_at + 1) % _seas.size()
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
