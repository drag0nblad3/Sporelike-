class_name GeneGraph
extends Control
## All five gene trees on one screen with no scrolling: each tree is two
## columns (its branches) of four GeneIcon nodes, tier 1 at the top, joined
## by lines. Sizes itself to whatever space it gets. The owning screen
## sets `styler` (Callable taking a GeneIcon) to colour the nodes and
## hears taps through `picked`.

signal picked(id: String)

const HEAD := 58.0
const TREE_GAP := 14.0

var styler: Callable
var selected := ""
var icons := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for tree in GeneCatalog.TREES:
		for branch in GeneCatalog.BRANCHES[tree]:
			for raw in branch[1]:
				var id := str(raw)
				var icon := GeneIcon.make(id)
				icon.pressed.connect(func() -> void: picked.emit(id))
				add_child(icon)
				icons[id] = icon
	resized.connect(_layout)
	_layout()


## Re-colours every node through `styler` and marks the selected one.
func restyle() -> void:
	for id in icons:
		var icon: GeneIcon = icons[id]
		if styler.is_valid():
			styler.call(icon)
		icon.selected = id == selected
		icon.queue_redraw()
	queue_redraw()


func _pitch() -> Vector2:
	var columns := GeneCatalog.TREES.size() * 2
	return Vector2((size.x - TREE_GAP * (GeneCatalog.TREES.size() - 1)) / columns,
		(size.y - HEAD) / 4.0)


func _column_x(tree_at: int, branch_at: int) -> float:
	var pitch := _pitch()
	return (tree_at * 2 + branch_at + 0.5) * pitch.x + tree_at * TREE_GAP


func _layout() -> void:
	var pitch := _pitch()
	var node := clampf(minf(pitch.x, pitch.y) * 0.84, 40.0, 110.0)
	for t in GeneCatalog.TREES.size():
		var branches: Array = GeneCatalog.BRANCHES[GeneCatalog.TREES[t]]
		for b in branches.size():
			var ids: Array = branches[b][1]
			for i in ids.size():
				var icon: GeneIcon = icons[str(ids[i])]
				var c := Vector2(_column_x(t, b), HEAD + pitch.y * (i + 0.5))
				icon.size = Vector2(node, node)
				icon.position = c - icon.size / 2.0
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var pitch := _pitch()
	for t in GeneCatalog.TREES.size():
		var tree: String = GeneCatalog.TREES[t]
		var left := _column_x(t, 0) - pitch.x / 2.0
		if t > 0:
			var x := left - TREE_GAP / 2.0
			draw_line(Vector2(x, 4.0), Vector2(x, size.y - 4.0), Color(UiTheme.EDGE, 0.2), 2.0)
		draw_string(font, Vector2(left, 24.0), str(GeneCatalog.TREE_NAMES[tree]),
			HORIZONTAL_ALIGNMENT_CENTER, pitch.x * 2.0, 22, UiTheme.ACCENT)
		var branches: Array = GeneCatalog.BRANCHES[tree]
		for b in branches.size():
			draw_string(font, Vector2(_column_x(t, b) - pitch.x / 2.0, 48.0),
				str(branches[b][0]), HORIZONTAL_ALIGNMENT_CENTER, pitch.x, 15, UiTheme.DIM)
			_draw_links(branches[b][1])


## Lines between tiers: green once both ends are owned, teal when the
## next one can be unlocked, faint otherwise.
func _draw_links(ids: Array) -> void:
	for i in ids.size() - 1:
		var a: GeneIcon = icons[str(ids[i])]
		var b: GeneIcon = icons[str(ids[i + 1])]
		var tint := Color(UiTheme.DIM, 0.25)
		if a.linked and b.linked:
			tint = UiTheme.GAIN
		elif a.linked and b.reach:
			tint = Color(UiTheme.ACCENT, 0.7)
		var from := a.position + Vector2(a.size.x / 2.0, a.size.y * 0.93)
		var to := b.position + Vector2(b.size.x / 2.0, b.size.y * 0.07)
		draw_line(from, to, tint, 4.0 if a.linked else 2.5, true)
