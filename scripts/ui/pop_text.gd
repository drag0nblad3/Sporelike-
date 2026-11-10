class_name PopText
extends Label3D
## A short line of text that pops up over a spot in the sea, drifts up and
## fades out, such as "+12 energy" over a prize morsel.

const LIFE := 1.2

var _age := 0.0


static func show_at(parent: Node, at: Vector3, text_line: String, colour: Color) -> void:
	var pop := PopText.new()
	pop.text = text_line
	pop.modulate = colour
	pop.position = at + Vector3(0.0, 1.0, 0.0)
	parent.add_child(pop)


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fixed_size = true
	pixel_size = 0.0012
	font_size = 34
	outline_size = 10
	outline_modulate = Color(0.0, 0.05, 0.1, 0.8)
	no_depth_test = true


func _process(delta: float) -> void:
	_age += delta
	position.y += delta * 1.5
	modulate.a = clampf(1.5 * (1.0 - _age / LIFE), 0.0, 1.0)
	if _age >= LIFE:
		queue_free()
