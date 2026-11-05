class_name SenseCues
extends Control
## What the player's senses feel just past the screen edge: a glow in the
## colour of each prominent nearby food field, and a bright red "!" toward
## each nearby hunter. How far out depends on SenseReach.

const RECHECK := 0.25
## At most this many food glows at once, the most prominent first.
const MAX_GLOWS := 6
const GLOW_RADIUS := 230.0
const MARK_INSET := 64.0
const MARK_SIZE := 64
const DANGER := Color(1.0, 0.12, 0.08)
## Reach (world units) at which senses count as fully keen: bigger, brighter cues.
const KEEN_REACH := 20.0

var _camera: Camera3D
var _view := ViewFootprint.new()
var _timer := 0.0
## 0..1 from the body's sense reach; scales every cue's size and brightness.
var _keen := 0.0
## [world position, colour, strength 0..1] per food glow.
var _glows: Array = []
## [hunter, strength 0..1] per danger mark.
var _marks: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func clear() -> void:
	if _glows.is_empty() and _marks.is_empty():
		return
	_glows.clear()
	_marks.clear()
	queue_redraw()


## Called every frame by PlayerDirector while the player is alive.
func track(player: Organism, eco: Ecosystem, camera: Camera3D, delta: float) -> void:
	track_reach(SenseReach.beyond_screen(player.genome), player.genome.feature("food_scent") > 0,
		eco, camera, delta)


## The same for any body (a colony): reach is how far past the screen edge
## it feels, tastes whether it finds hidden food fields.
func track_reach(reach: float, tastes: bool, eco: Ecosystem, camera: Camera3D,
		delta: float) -> void:
	_camera = camera
	_timer -= delta
	if _timer <= 0.0:
		_timer = RECHECK
		_scan(reach, tastes, eco)
	queue_redraw()


func _scan(reach: float, tastes: bool, eco: Ecosystem) -> void:
	_glows.clear()
	_marks.clear()
	if reach <= 0.0:
		return
	_keen = clampf(reach / KEEN_REACH, 0.0, 1.0)
	_view.update(_camera)
	var found: Array = []
	for patch in eco.food.patches:
		if patch.count < FoodScent.MIN_PIECES or (patch.hidden and not tastes):
			continue
		var d := _view.outside_by(patch.center) - patch.radius
		if d <= 0.0 or d > reach:
			continue
		var strength := 1.0 - d / reach
		var weight := patch.count * patch.kind.energy * strength
		found.append([patch.center, patch.kind.color, strength, weight])
	found.sort_custom(func(a: Array, b: Array) -> bool: return float(a[3]) > float(b[3]))
	_glows = found.slice(0, MAX_GLOWS)
	for hunter in eco.predators:
		if not is_instance_valid(hunter) or not hunter.alive:
			continue
		var d := _view.outside_by(hunter.flat_pos()) - hunter.radius()
		if d > 0.0 and d <= reach:
			_marks.append([hunter, 1.0 - d / reach])


func _draw() -> void:
	if _camera == null:
		return
	var rect := get_viewport_rect()
	for glow in _glows:
		var spot: Vector2 = glow[0]
		var tint: Color = glow[1]
		var strength: float = glow[2]
		_draw_glow(_at_edge(spot, rect, 0.0), tint, strength)
	var pulse := 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.008)
	for mark in _marks:
		var hunter: Organism = mark[0]
		if is_instance_valid(hunter):
			var strength: float = mark[1]
			var grow := lerpf(0.55, 1.0, strength) * lerpf(0.7, 1.15, _keen)
			var alpha := lerpf(0.5, 1.0, strength) * lerpf(0.75, 1.0, _keen) * pulse
			_draw_mark(_at_edge(hunter.flat_pos(), rect, MARK_INSET * grow), grow, alpha)


## The world point's screen position, pulled in to `inset` from the edge.
func _at_edge(world: Vector2, rect: Rect2, inset: float) -> Vector2:
	var screen := _camera.unproject_position(Vector3(world.x, 0.0, world.y))
	var center := rect.size * 0.5
	var v := screen - center
	var half := center - Vector2(inset, inset)
	var t := 1.0
	if absf(v.x) > half.x:
		t = minf(t, half.x / absf(v.x))
	if absf(v.y) > half.y:
		t = minf(t, half.y / absf(v.y))
	return center + v * t


func _draw_glow(at: Vector2, tint: Color, strength: float) -> void:
	var r := GLOW_RADIUS * lerpf(0.35, 1.0, strength) * lerpf(0.6, 1.2, _keen)
	var inner := Color(tint.r, tint.g, tint.b, 0.65 * strength * lerpf(0.45, 1.0, _keen))
	var outer := Color(tint.r, tint.g, tint.b, 0.0)
	var steps := 20
	for i in steps:
		var a := Vector2.from_angle(TAU * i / steps) * r
		var b := Vector2.from_angle(TAU * (i + 1) / steps) * r
		draw_polygon(PackedVector2Array([at, at + a, at + b]),
			PackedColorArray([inner, outer, outer]))


## A red "!" in a dark disc; grow 1 is MARK_SIZE pixels tall.
func _draw_mark(at: Vector2, grow: float, alpha: float) -> void:
	var px := int(MARK_SIZE * grow)
	var ring := 34.0 * grow
	draw_circle(at, ring, Color(0.3, 0.0, 0.0, 0.55 * alpha))
	draw_arc(at, ring, 0.0, TAU, 32, Color(DANGER, alpha), 4.0 * grow)
	var font := ThemeDB.fallback_font
	var base := at + Vector2(-ring * 1.2, px * 0.36)
	draw_string_outline(font, base, "!", HORIZONTAL_ALIGNMENT_CENTER, ring * 2.4, px,
		int(8 * grow), Color(0.0, 0.0, 0.0, alpha))
	draw_string(font, base, "!", HORIZONTAL_ALIGNMENT_CENTER, ring * 2.4, px, Color(DANGER, alpha))
