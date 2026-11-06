class_name GeneScreen
extends Control
## Base for the full-screen gene menus (gene trees, subspecies creator): a
## dark shade, the GeneGraph on the left and a side column on the right
## that ends in a GeneDetail text box. Nothing scrolls. Subclasses fill
## `side` in _build_side(), colour nodes in _style() and fill the detail
## box in _describe().

const SIDE_WIDTH := 430.0

var graph: GeneGraph
var side: VBoxContainer
var detail: GeneDetail


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.shared()
	var shade := ColorRect.new()
	shade.color = Color(UiTheme.SHADE, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	margin.add_child(columns)
	graph = GeneGraph.new()
	graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph.styler = _style
	graph.picked.connect(_pick)
	columns.add_child(graph)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PANEL, 14))
	# Wider phones give the text box more room, so less of it wraps.
	card.custom_minimum_size.x = clampf(get_viewport_rect().size.x * 0.36, SIDE_WIDTH, 600.0)
	columns.add_child(card)
	side = VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	card.add_child(side)
	_build_side()
	detail = GeneDetail.new()
	detail.acted.connect(_act)
	side.add_child(detail)
	_build_bottom()


## Re-colours the graph and refreshes the text box for the selected gene.
func redraw_genes() -> void:
	graph.restyle()
	if graph.selected != "":
		_describe(graph.selected)


func _pick(id: String) -> void:
	graph.selected = id
	redraw_genes()


func label(text: String, font_size: int, tint: Color = UiTheme.INK,
		parent: Control = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 120
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", tint)
	(parent if parent else side).add_child(l)
	return l


func button(text: String, action: Callable, parent: Control = null,
		height: float = 52.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(action)
	(parent if parent else side).add_child(b)
	return b


func row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	side.add_child(r)
	return r


## Side column content above the text box.
func _build_side() -> void:
	pass


## Side column content below the text box.
func _build_bottom() -> void:
	pass


func _style(_icon: GeneIcon) -> void:
	pass


func _describe(_id: String) -> void:
	pass


func _act(_id: String) -> void:
	pass
