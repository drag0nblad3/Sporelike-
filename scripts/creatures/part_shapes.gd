class_name PartShapes
extends RefCounted
## CPU-side geometry for the small primitive shapes cells are built from
## (spheres, capsules, cones and cylinders, tori), so PartBaker can merge
## them without reading meshes back from the GPU. Each shape is
## [vertices, normals, indices] in the same local space as the matching
## Godot primitive mesh, cached by its proportions.

const CACHE_LIMIT := 256

static var _cache := {}


## A UV sphere of radius 1. `mid` > 0 pulls the halves apart along Y by
## that much each way, which turns it into a capsule.
static func sphere(radial: int, rings: int, mid := 0.0) -> Array:
	var key := "s%d_%d_%.3f" % [radial, rings, mid]
	if _cache.has(key):
		return _cache[key]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in rings + 1:
		var phi := PI * i / rings
		var y := cos(phi)
		var lift := signf(y) * mid if absf(y) > 0.001 else 0.0
		for j in radial + 1:
			var a := TAU * j / radial
			var n := Vector3(sin(a) * sin(phi), y, cos(a) * sin(phi))
			normals.append(n)
			verts.append(n + Vector3(0.0, lift, 0.0))
	return _store(key, verts, normals, _grid(verts, normals, rings, radial))


## A Y-axis cylinder like CylinderMesh: bottom radius at -height/2, top
## radius at +height/2 (0 makes a cone), with closed ends.
static func cylinder(top: float, bottom: float, height: float, radial: int) -> Array:
	var key := "c%.3f_%.3f_%.3f_%d" % [top, bottom, height, radial]
	if _cache.has(key):
		return _cache[key]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var half := height * 0.5
	var slope := (bottom - top) / maxf(height, 0.0001)
	for ring in 2:
		var r := top if ring == 0 else bottom
		var y := half if ring == 0 else -half
		for j in radial + 1:
			var a := TAU * j / radial
			verts.append(Vector3(sin(a) * r, y, cos(a) * r))
			normals.append(Vector3(sin(a), slope, cos(a)).normalized())
	var idx := _grid(verts, normals, 1, radial)
	for cap in 2:
		var r := top if cap == 0 else bottom
		if r <= 0.0:
			continue
		var y := half if cap == 0 else -half
		var n := Vector3(0.0, 1.0 if cap == 0 else -1.0, 0.0)
		var center := verts.size()
		verts.append(Vector3(0.0, y, 0.0))
		normals.append(n)
		for j in radial + 1:
			var a := TAU * j / radial
			verts.append(Vector3(sin(a) * r, y, cos(a) * r))
			normals.append(n)
		for j in radial:
			_tri(idx, verts, normals, center, center + 1 + j, center + 2 + j)
	return _store(key, verts, normals, idx)


## A ring around the Y axis like TorusMesh.
static func torus(inner: float, outer: float, rings: int, sides: int) -> Array:
	var key := "t%.3f_%.3f_%d_%d" % [inner, outer, rings, sides]
	if _cache.has(key):
		return _cache[key]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var major := (inner + outer) * 0.5
	var minor := (outer - inner) * 0.5
	for i in rings + 1:
		var u := TAU * i / rings
		var around := Vector3(sin(u), 0.0, cos(u))
		for j in sides + 1:
			var v := TAU * j / sides
			var n := around * cos(v) + Vector3(0.0, sin(v), 0.0)
			normals.append(n)
			verts.append(around * major + n * minor)
	return _store(key, verts, normals, _grid(verts, normals, rings, sides))


## Two triangles per cell of a (rows + 1) x (cols + 1) vertex grid.
static func _grid(verts: PackedVector3Array, normals: PackedVector3Array,
		rows: int, cols: int) -> PackedInt32Array:
	var idx := PackedInt32Array()
	for i in rows:
		for j in cols:
			var a := i * (cols + 1) + j
			var b := a + cols + 1
			_tri(idx, verts, normals, a, a + 1, b)
			_tri(idx, verts, normals, a + 1, b + 1, b)
	return idx


## Adds a triangle wound so its front faces the way its normals point
## (Godot draws clockwise triangles as front faces).
static func _tri(idx: PackedInt32Array, verts: PackedVector3Array,
		normals: PackedVector3Array, a: int, b: int, c: int) -> void:
	var face := (verts[b] - verts[a]).cross(verts[c] - verts[a])
	if face.dot(normals[a] + normals[b] + normals[c]) > 0.0:
		var swap := b
		b = c
		c = swap
	idx.append(a)
	idx.append(b)
	idx.append(c)


static func _store(key: String, verts: PackedVector3Array, normals: PackedVector3Array,
		idx: PackedInt32Array) -> Array:
	if _cache.size() >= CACHE_LIMIT:
		_cache.clear()
	var shape := [verts, normals, idx]
	_cache[key] = shape
	return shape
