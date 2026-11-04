class_name CreatorSide
extends RefCounted
## The subspecies creator's side column above the gene text box: title,
## the subspecies name with New name, the starting Sea with Other sea, and
## gene slots used. Built once; show() updates the text.

var trees_button: Button
var _name: Label
var _sea: Label
var _blurb: Label
var _favors: Label
var _slots: Label


func build(screen: SubspeciesCreator) -> void:
	screen.label("Found a subspecies", 28, UiTheme.ACCENT)
	var names := screen.row()
	_name = screen.label("", 26, UiTheme.GOLD, names)
	_side_button(screen.button("New name", func() -> void: screen.reroll(), names))
	var seas := screen.row()
	_sea = screen.label("", 22, UiTheme.ACCENT, seas)
	_side_button(screen.button("Other sea", func() -> void: screen.next_sea(), seas))
	_blurb = screen.label("", 16, UiTheme.DIM)
	_favors = screen.label("", 16, UiTheme.GAIN)
	_slots = screen.label("", 21)


func show(subspecies: String, sea: Sea, used: int, bank: GeneBank) -> void:
	_name.text = subspecies
	_sea.text = "Sea: %s" % sea.title
	_blurb.text = sea.blurb
	_favors.text = "Does well here: %s" % sea.favors
	_slots.text = "Gene slots used: %d of %d" % [used, bank.slots()]
	_slots.add_theme_color_override("font_color",
		UiTheme.GAIN if used == bank.slots() else UiTheme.INK)
	if trees_button:
		trees_button.text = "Gene trees (%d)" % bank.points


## Buttons beside a label keep their width instead of sharing the row.
func _side_button(b: Button) -> void:
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.custom_minimum_size.x = 150
