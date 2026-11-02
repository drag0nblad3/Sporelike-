class_name SwallowedFood
extends MeshInstance3D
## A piece of food an organism just ate: it is pulled inside the body, then
## shrinks away over a moment as it is absorbed.

## Seconds to be pulled in, and to be absorbed after that.
const PULL_TIME := 0.25
const ABSORB_TIME := 1.6
## Most pieces shown digesting inside one body at once.
const MAX_PER_BODY := 4

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _start_scale := 1.0
var _time := 0.0


## Copies the look of `item` into `org`'s body, where it then digests.
static func show_in(org: Organism, item: FoodItem) -> void:
	var inside := 0
	for child in org.get_children():
		if child is SwallowedFood:
			inside += 1
	if inside >= MAX_PER_BODY:
		return
	var piece := SwallowedFood.new()
	piece.mesh = item.mesh
	piece.material_override = item.material_override
	var size := org.radius()
	var offset := org.to_local(item.global_position)
	piece._from = Vector3(offset.x, 0.1, offset.z)
	var spot := Vector2.from_angle(randf() * TAU) * randf_range(0.0, 0.4)
	piece._to = Vector3(spot.x, 0.1, spot.y)
	piece._start_scale = minf(item.scale.x / size, 0.45)
	piece.position = piece._from
	piece.scale = Vector3.ONE * piece._start_scale
	org.add_child(piece)


func _process(delta: float) -> void:
	_time += delta
	if _time < PULL_TIME:
		position = _from.lerp(_to, _time / PULL_TIME)
		return
	position = _to
	var left := 1.0 - (_time - PULL_TIME) / ABSORB_TIME
	if left <= 0.0:
		queue_free()
		return
	scale = Vector3.ONE * _start_scale * left
	rotation.y += delta * 1.5
