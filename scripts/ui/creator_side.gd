class_name CreatorSide
extends RefCounted
## The subspecies creator's side column above the gene text box: title,
## the subspecies name with New name, the starting Sea with Other sea (its
## description shows in the text box), what does well there, and gene slots
## used. Built once; show() updates the text.

var trees_button: Button
## The top row, beside the title; the creator adds its Back button here.
var header: HBoxContainer
var _name: Label
var _sea: Label
var _favors: Label
var _slots: Label


func build(screen: SubspeciesCreator) -> void:
	header = screen.row()
	screen.label("Found a subspecies", 20, UiTheme.DIM, header)
	var names := screen.row()
	_name = screen.label("", 25, UiTheme.GOLD, names)
	side_button(screen.button("New name", func() -> void: screen.reroll(), names, 44.0))
	var seas := screen.row()
	_sea = screen.label("", 20, UiTheme.ACCENT, seas)
	side_button(screen.button("Other sea", func() -> void: screen.next_sea(), seas, 44.0))
	_favors = screen.label("", 18, UiTheme.GAIN)
	_slots = screen.label("", 22)


func show(subspecies: String, sea: Sea, used: int, bank: GeneBank) -> void:
	_name.text = subspecies
	_sea.text = sea.title
	_favors.text = "Does well here: %s" % sea.favors
	_slots.text = "Gene slots used: %d of %d" % [used, bank.slots()]
	_slots.add_theme_color_override("font_color",
		UiTheme.GAIN if used == bank.slots() else UiTheme.INK)
	if trees_button:
		trees_button.text = "Gene trees (%d)" % bank.points


## Buttons beside a label keep their width instead of sharing the row.
static func side_button(b: Button) -> void:
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.custom_minimum_size.x = 140
	b.add_theme_font_size_override("font_size", 20)
