class_name ShoreLook
extends Node3D
## How the shallows look: a long strip of sand that rises from the sea floor
## up past the waterline into a dry beach, darker where it stays wet, and a
## line of foam that moves in and out with the tide. The strip is rebuilt
## around the colony whenever it has moved far along the shore.

const FLOOR_Y := -1.4
const LENGTH := 240.0
const RECENTER := 40.0
const ROW := 3.0
## How far inland the sand reaches, past the edge of any view.
const INLAND := 90.0
const COLUMNS := 24
const DRY := Color(0.84, 0.77, 0.58)
const WET := Color(0.52, 0.48, 0.38)
const DEEP := Color(0.4, 0.42, 0.38)

var _line: ShoreLine
var _sand := MeshInstance3D.new()
var _foam := MeshInstance3D.new()
var _center := INF


func _ready() -> void:
	var sand_mat := StandardMaterial3D.new()
	sand_mat.vertex_color_use_as_albedo = true
	sand_mat.vertex_color_is_srgb = true
	sand_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sand_mat.roughness = 1.0
	_sand.material_override = sand_mat
	add_child(_sand)
	var foam_mat := StandardMaterial3D.new()
	foam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam_mat.albedo_color = Color(0.95, 0.98, 1.0, 0.6)
	foam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_foam.material_override = foam_mat
	add_child(_foam)


func show_line(line: ShoreLine) -> void:
	_line = line
	_center = INF
	visible = line != null


## Keeps the sand around `focus` and the foam on the tide's waterline.
func follow(focus: Vector2, water: float) -> void:
	if _line == null:
		return
	var s := _line.along(focus)
	if absf(s - _center) > RECENTER:
		_center = snappedf(s, RECENTER)
		_sand.mesh = _build_sand(_center)
		_foam.mesh = _build_foam(_center)
	var lift := ShoreLine.rise(water) + 0.06
	_foam.position = _line.inland3() * water + Vector3.UP * lift


func _build_sand(center: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low := -ShoreLine.SLOPE - ROW
	var rows := int((INLAND + ShoreLine.SLOPE + ROW) / ROW)
	var step := LENGTH / COLUMNS
	for r in rows:
		for c in COLUMNS:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
					Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var d := low + (r + corner.y) * ROW
				var s := center - LENGTH * 0.5 + (c + corner.x) * step
				st.set_color(_sand_color(d))
				st.add_vertex(_vertex(s, d))
	st.generate_normals()
	return st.commit()


func _vertex(s: float, d: float) -> Vector3:
	var p := _line.point(s, d)
	var y := FLOOR_Y + ShoreLine.rise(d)
	if d < -ShoreLine.SLOPE:
		y = FLOOR_Y - 0.3
	return Vector3(p.x, y, p.y)


func _sand_color(d: float) -> Color:
	if d < -ShoreLine.TIDE_RANGE:
		return DEEP.lerp(WET, clampf((d + ShoreLine.SLOPE) / ShoreLine.SLOPE, 0.0, 1.0))
	return WET.lerp(DRY, clampf((d + ShoreLine.TIDE_RANGE) / (3.0 * ShoreLine.TIDE_RANGE), 0.0, 1.0))


## A thin band along the mean waterline; follow slides it with the tide.
func _build_foam(center: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var a := center - LENGTH * 0.5
	var b := center + LENGTH * 0.5
	for p: Vector2 in [Vector2(a, -0.6), Vector2(b, -0.6), Vector2(b, 0.6),
			Vector2(a, -0.6), Vector2(b, 0.6), Vector2(a, 0.6)]:
		var q := _line.point(p.x, p.y)
		st.add_vertex(Vector3(q.x, FLOOR_Y, q.y))
	return st.commit()
