class_name TipBanner
extends PanelContainer
## One-time teaching prompts: a small card low in the middle of the screen
## that explains something the moment it first matters (Tips remembers
## which have been shown). Tips queue up; each stays SHOW seconds or until
## tapped. Never pauses the game.

const SHOW := 11.0
const HALF_WIDTH := 300.0

## Pixels between the card and the bottom of the screen.
var lift := 96.0
var _label := Label.new()
var _queue: Array[String] = []
var _left := 0.0


func _ready() -> void:
	theme = UiTheme.shared()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -HALF_WIDTH
	offset_right = HALF_WIDTH
	offset_bottom = -lift
	offset_top = -lift - 90.0
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_theme_stylebox_override("panel", UiTheme.panel(Color(0.05, 0.16, 0.22, 0.93), 14))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size.x = HALF_WIDTH * 2.0 - 28.0
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", UiTheme.INK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false
	gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) \
				and event.is_pressed():
			_next())


## Shows `text` if the tip `id` has never been shown before.
func offer(id: String, text: String) -> void:
	if not Tips.take(id):
		return
	_queue.append(text)
	if not visible:
		_next()


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	if _left <= 0.0:
		_next()


func _next() -> void:
	if _queue.is_empty():
		visible = false
		return
	var text: String = _queue.pop_front()
	_label.text = "Tip: " + text
	_left = SHOW
	visible = true
