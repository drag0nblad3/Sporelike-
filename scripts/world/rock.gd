class_name Rock
extends Node3D
## A rock outcrop on the sea floor: a lump of fixed points that swimmers
## bump into and can shelter against. Its size and colour come from the
## sea it sits in: big reef rocks on the upwelling coast, small pebbles in
## the lagoon, and dark vent chimneys that give off warm, mineral-rich water.
## It is drawn as one solid stone (ColonySkin with StoneShader).

const STONE := 0.0

var body := SoftBody.new()
var chimney := false
var _look: ColonySkin


func build(at: Vector3, sea_id: String, rng: RandomNumberGenerator) -> void:
	body = SoftBody.new()
	body.anchored = true
	body.anchor = at
	chimney = sea_id == "vents"
	var rings := 1
	match sea_id:
		"upwelling":
			rings = rng.randi_range(2, 3)
		"lagoon":
			rings = 1
		_:
			rings = rng.randi_range(1, 2)
	var spots: Array[Vector3] = [Vector3.ZERO]
	for ring in range(1, rings + 1):
		var around := 6 * ring
		for k in around:
			var a := TAU * k / float(around) + rng.randf_range(-0.15, 0.15)
			spots.append(Vector3(cos(a), 0.0, sin(a)) * ring * 0.9)
	for spot in spots:
		body.add_point(at + spot, spot, STONE)
	_build_look(sea_id, rng)


## Whether any of `other`'s points is within `gap` of this rock.
func touches(other: SoftBody, gap: float) -> bool:
	var room := body.reach() + other.reach() + gap
	if body.anchor.distance_squared_to(other.center()) > room * room:
		return false
	for p in other.pos:
		for q in body.pos:
			if p.distance_squared_to(q) < gap * gap:
				return true
	return false


func _build_look(sea_id: String, rng: RandomNumberGenerator) -> void:
	var tint := Color(0.42, 0.42, 0.45)
	match sea_id:
		"vents":
			tint = Color(0.18, 0.14, 0.13)
		"lagoon":
			tint = Color(0.75, 0.7, 0.55)
		"upwelling":
			tint = Color(0.35, 0.38, 0.33)
		"deep":
			tint = Color(0.2, 0.22, 0.3)
	# One lumpy stone rising from the floor, shaped round its points.
	var glow := Color(0.6, 0.25, 0.05) * 0.5 if chimney else Color.BLACK
	var stone := StoneShader.material(tint.lightened(rng.randf_range(-0.05, 0.1)), glow)
	_look = ColonySkin.new()
	_look.build(body.rest, tint, stone)
	stone.set_shader_parameter("base", -1.4)
	stone.set_shader_parameter("height", 3.6 if chimney else 1.4 + rng.randf_range(0.2, 0.6))
	add_child(_look)
	_look.update(body, rng.randf() * 10.0)
