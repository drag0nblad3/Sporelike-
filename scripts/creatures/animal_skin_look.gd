class_name AnimalSkinLook
extends MeshInstance3D
## One smooth skin over a stage 3 Animal's body, for a body that is not
## drawn as separate segments: a tube rebuilt every frame through the
## segment centres (a Catmull-Rom curve), as wide and tall as each segment
## and rounded off at both ends (for an upright biped the tube stands up).
## Stripes become coloured rings.

const SIDES := 12
const STEPS := 4
## Rings rounding off each end, as shares of the end segment's half length.
const CAP := [1.0, 0.94, 0.8, 0.55, 0.25]

var _body: AnimalBody
var _first := 0
var _upright := false
var _skin := Color.WHITE
var _stripe := Color.WHITE
var _mesh := ArrayMesh.new()
var _indices := PackedInt32Array()


## first: the first segment under the skin (1 when a neck holds the head apart).
func build(body: AnimalBody, first: int) -> void:
	_body = body
	_first = first
	_upright = body.posture == "upright"
	_skin = body.color()
	_stripe = body.color2() if body.pattern == "stripes" else body.color()
	mesh = _mesh
	material_override = AnimalSkinMaterial.make(body, Color.WHITE)


func update(frames: Array[Transform3D]) -> void:
	var centres := PackedVector3Array()
	var sizes := PackedVector2Array()
	var segs := PackedInt32Array()
	_samples(frames, centres, sizes, segs)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var n := centres.size()
	for s in n:
		var t := centres[mini(s + 1, n - 1)] - centres[maxi(s - 1, 0)]
		t = t.normalized() if t.length_squared() > 0.000001 else Vector3.BACK
		# A standing body runs straight up, so take its sides from the head.
		var across := frames[0].basis.z.normalized() if _upright else Vector3.UP
		var right := t.cross(across).normalized()
		var up := right.cross(t)
		var size := sizes[s]
		var tint := _stripe if segs[s] % 2 == 1 else _skin
		for a in SIDES:
			var angle := TAU * a / SIDES
			var c := cos(angle)
			var sn := sin(angle)
			verts.append(centres[s] + right * c * size.x + up * sn * size.y)
			normals.append((right * c / maxf(size.x, 0.001) + up * sn / maxf(size.y, 0.001)).normalized())
			colors.append(tint)
			uvs.append(Vector2(float(a) / SIDES, float(s) / STEPS * 0.5))
	if _indices.size() != (n - 1) * SIDES * 6:
		_make_indices(n)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = _indices
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


## Ring centres and sizes from the front tip to the back tip, and the
## segment each ring belongs to.
func _samples(frames: Array[Transform3D], centres: PackedVector3Array,
		sizes: PackedVector2Array, segs: PackedInt32Array) -> void:
	var last := frames.size() - 1
	for f: float in CAP:
		_cap_ring(frames[_first], f, 1.0, centres, sizes)
		segs.append(_first)
	for i in range(_first, last):
		for step in STEPS:
			var t := float(step) / STEPS
			var p0 := frames[maxi(i - 1, _first)].origin
			var p3 := frames[mini(i + 2, last)].origin
			centres.append(_curve(p0, frames[i].origin, frames[i + 1].origin, p3, t))
			sizes.append(_size(frames[i]).lerp(_size(frames[i + 1]), smoothstep(0.0, 1.0, t)))
			segs.append(i if t < 0.5 else i + 1)
	centres.append(frames[last].origin)
	sizes.append(_size(frames[last]))
	segs.append(last)
	for k in range(CAP.size() - 1, -1, -1):
		_cap_ring(frames[last], CAP[k], -1.0, centres, sizes)
		segs.append(last)


func _cap_ring(frame: Transform3D, f: float, way: float, centres: PackedVector3Array,
		sizes: PackedVector2Array) -> void:
	var axis := frame.basis.y if _upright else frame.basis.z
	centres.append(frame.origin + axis * f * way)
	sizes.append(_size(frame) * sqrt(maxf(1.0 - f * f, 0.0)))


func _size(frame: Transform3D) -> Vector2:
	var depth := frame.basis.z if _upright else frame.basis.y
	return Vector2(frame.basis.x.length(), depth.length())


func _curve(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)


func _make_indices(rings: int) -> void:
	_indices.clear()
	for s in rings - 1:
		for a in SIDES:
			var a1 := (a + 1) % SIDES
			var r0 := s * SIDES
			var r1 := r0 + SIDES
			_indices.append_array(PackedInt32Array([r0 + a, r0 + a1, r1 + a, r0 + a1, r1 + a1, r1 + a]))
