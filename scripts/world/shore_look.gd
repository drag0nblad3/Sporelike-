class_name ShoreLook
extends Node3D
## How the shallows look: a long strip of sand that rises from the sea floor
## up past the waterline into a dry beach, darker where it stays wet, and a
## line of foam that moves in and out with the tide, pebbles and shells
## (BeachPebbles), ripples and caustics (SandShader). The strip is rebuilt
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
var _pebbles := BeachPebbles.new()
var _sand_mat := SandShader.material()
var _center := INF


func _ready() -> void:
	# Shallow water is bright even where the open sea around it is dim, so
	# the sand keeps its own colours, shaded by how steeply it climbs.
	_sand.material_override = _sand_mat
	add_child(_sand)
	add_child(_pebbles)
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
	if line:
		_sand_mat.set_shader_parameter("origin", line.origin)
		_sand_mat.set_shader_parameter("inland", line.inland)


## Keeps the sand around `focus` and the foam on the tide's waterline.
func follow(focus: Vector2, water: float) -> void:
	if _line == null:
		return
	var s := _line.along(focus)
	if absf(s - _center) > RECENTER:
		_center = snappedf(s, RECENTER)
		_sand.mesh = _build_sand(_center)
		_foam.mesh = _build_foam(_center)
		_pebbles.scatter(_line, _center, LENGTH * 0.6)
	var lift := ShoreLine.rise(water) + 0.06
	_foam.position = _line.inland3() * water + Vector3.UP * lift
	_sand_mat.set_shader_parameter("water", water)


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
				st.set_color(_sand_color(d) * _shade(d))
				st.set_normal(_normal(d))
				st.add_vertex(_vertex(s, d))
	return st.commit()


## Steeper sand faces the camera more and catches more light.
func _shade(d: float) -> Color:
	var slope := ShoreLine.rise(d + 0.5) - ShoreLine.rise(d - 0.5)
	var light := 0.85 + 0.35 * slope
	return Color(light, light, light, 1.0)


## Faces up and tilts seaward as steeply as the sand climbs.
func _normal(d: float) -> Vector3:
	var slope := (ShoreLine.rise(d + 0.5) - ShoreLine.rise(d - 0.5))
	return (Vector3.UP - _line.inland3() * slope).normalized()


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
