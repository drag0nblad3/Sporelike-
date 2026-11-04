class_name GeneDetail
extends PanelContainer
## The text box beside the gene trees: the tapped gene's icon, name, tier,
## slots and cost, what it does in real numbers, its state, and one action
## button (unlock, take or remove). The owning screen fills it with show().

signal acted(id: String)

var gene := ""
var _icon: GeneIcon
var _name: Label
var _info: Label
var _effect: Label
var _state: Label
var _action: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel(Color(0.02, 0.07, 0.11, 0.9), 14))
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	box.add_child(top)
	_icon = GeneIcon.make("big_1")
	_icon.custom_minimum_size = Vector2(76, 76)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(names)
	_name = _label(names, 25, UiTheme.GOLD)
	_info = _label(names, 17, UiTheme.DIM)
	_effect = _label(box, 18, UiTheme.INK)
	_effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_state = _label(box, 18, UiTheme.DIM)
	_action = Button.new()
	_action.custom_minimum_size.y = 58
	_action.add_theme_font_size_override("font_size", 22)
	_action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action.pressed.connect(func() -> void: acted.emit(gene))
	box.add_child(_action)
	show_hint("Tap a gene to see what it does.")


## Shows a gene; `look` is the same icon styler the graph uses.
func show_gene(id: String, look: Callable, state: String, state_tint: Color,
		action: String, can_act: bool) -> void:
	gene = id
	_icon.visible = true
	_icon.gene = id
	look.call(_icon)
	_icon.selected = false
	_icon.queue_redraw()
	_name.text = GeneText.label(id)
	_info.text = "Tier %d · %s · %s · %d gene points" % [GeneCatalog.tier(id),
		GeneText.place(id), GeneText.slot_text(id), GeneCatalog.cost(id)]
	_effect.text = GeneText.effect(id)
	_state.text = state
	_state.add_theme_color_override("font_color", state_tint)
	_action.visible = action != ""
	_action.text = action
	_action.disabled = not can_act


func show_hint(text: String) -> void:
	gene = ""
	_icon.visible = false
	_name.text = ""
	_info.text = ""
	_effect.text = text
	_state.text = ""
	_action.visible = false


func _label(parent: Control, font_size: int, tint: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 120
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", tint)
	parent.add_child(l)
	return l
