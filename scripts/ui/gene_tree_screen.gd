class_name GeneTreeScreen
extends GeneScreen
## The main species' gene trees: spend gene points from subspecies runs to
## unlock genes. All five trees show at once as rows of icons; tapping one
## fills the text box with what it gives, what it costs and what it needs,
## with an Unlock button. Saves the bank after every unlock.

signal closed

var bank: GeneBank
var _points: Label


func open(with_bank: GeneBank) -> void:
	bank = with_bank
	visible = true
	graph.selected = _first_open()
	redraw_genes()
	if graph.selected == "":
		detail.show_hint("Tap a gene to see what it does.")


func _build_side() -> void:
	label("Gene trees", 34, UiTheme.ACCENT)
	_points = label("", 20, UiTheme.GOLD)


func _build_bottom() -> void:
	button("Done", func() -> void: _close())


func redraw_genes() -> void:
	_points.text = "%d gene points to spend. %d earned in all, %d gene slots per subspecies." \
		% [bank.points, bank.lifetime, bank.slots()]
	super()


func _style(icon: GeneIcon) -> void:
	var id := icon.gene
	var needs := GeneCatalog.needs(id)
	var reachable := needs == "" or bank.has(needs)
	icon.lit = bank.has(id)
	icon.linked = icon.lit
	icon.reach = reachable
	icon.check = icon.lit
	icon.dim = not icon.lit and not reachable
	icon.badge = str(GeneCatalog.cost(id))
	if icon.lit:
		icon.ring = UiTheme.GAIN
	elif bank.can_unlock(id):
		icon.ring = UiTheme.ACCENT
		icon.badge_color = UiTheme.GOLD
	else:
		icon.ring = Color(UiTheme.DIM, 0.5)
		icon.badge_color = UiTheme.COST if reachable else UiTheme.DIM


func _describe(id: String) -> void:
	var cost := GeneCatalog.cost(id)
	var needs := GeneCatalog.needs(id)
	if bank.has(id):
		detail.show_gene(id, _style, "Unlocked. Choose it when founding a subspecies.",
			UiTheme.GAIN, "", false)
	elif needs != "" and not bank.has(needs):
		detail.show_gene(id, _style, "Needs %s first." % GeneText.label(needs),
			UiTheme.LOSS, "Locked", false)
	elif bank.points < cost:
		detail.show_gene(id, _style, "You have %d of %d gene points." % [bank.points, cost],
			UiTheme.COST, "Need %d gene points" % cost, false)
	else:
		detail.show_gene(id, _style, "Ready to unlock.", UiTheme.ACCENT,
			"Unlock for %d gene points" % cost, true)


func _act(id: String) -> void:
	if bank.unlock(id):
		bank.save()
	redraw_genes()


## The first gene that can be unlocked now, so the box starts useful.
func _first_open() -> String:
	for id in graph.icons:
		if bank.can_unlock(str(id)):
			return str(id)
	return ""


func _close() -> void:
	visible = false
	closed.emit()
