class_name GeneTreeScreen
extends MenuPanel
## The main species' gene trees: spend gene points from subspecies runs to
## unlock genes. One tree shows at a time (tabs along the top), as two
## branches of four tiers; each gene says what it gives, what it costs, and
## what it needs first. Saves the
## bank after every unlock.

signal closed

var bank: GeneBank
var _tree := "body"


func open(with_bank: GeneBank) -> void:
	bank = with_bank
	visible = true
	_refresh()


func _refresh() -> void:
	clear()
	label("Gene trees", 36, UiTheme.ACCENT)
	label("%d gene points to spend. %d earned in all, %d gene slots per subspecies." % [
		bank.points, bank.lifetime, bank.slots()], 22, UiTheme.GOLD)
	var tabs := row()
	for tree in GeneCatalog.TREES:
		var t: String = tree
		var tab := button(str(GeneCatalog.TREE_NAMES[t]), func() -> void: _show_tree(t), tabs)
		tab.disabled = t == _tree
	for branch in GeneCatalog.BRANCHES[_tree]:
		label(str(branch[0]), 28, UiTheme.ACCENT)
		for raw in branch[1]:
			_add_gene(str(raw))
	button("Done", func() -> void: _close())


func _show_tree(tree: String) -> void:
	_tree = tree
	_refresh()


func _add_gene(id: String) -> void:
	var needs := GeneCatalog.needs(id)
	var state := ""
	if bank.has(id):
		state = "Unlocked"
	elif needs != "" and not bank.has(needs):
		state = "Needs %s first" % GeneText.label(needs)
	else:
		state = "Unlock for %d gene points" % GeneCatalog.cost(id)
	var text := "Tier %d: %s  (%s)\n%s\n%s" % [GeneCatalog.tier(id), GeneText.label(id),
		GeneText.slot_text(id), GeneText.effect(id), state]
	var b := button(text, func() -> void: _unlock(id))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 110
	b.add_theme_font_size_override("font_size", 20)
	b.disabled = not bank.can_unlock(id)
	if bank.has(id):
		b.add_theme_color_override("font_disabled_color", UiTheme.GAIN)


func _unlock(id: String) -> void:
	if bank.unlock(id):
		bank.save()
	_refresh()


func _close() -> void:
	visible = false
	closed.emit()
