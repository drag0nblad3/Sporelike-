class_name BeadStrip
extends MultiMeshInstance3D
## Draws many coloured balls in one draw call (a MultiMesh): the cells of a
## colony, the joints of a limb, the cells of a seaweed. Callers place each
## ball every frame with place().


## `count` balls of `radius`, each tinted with set_color(). `glow` makes
## them shine with that colour, and see_through lets the colours' alpha
## show what is inside, like a stage 1 cell's membrane.
static func make(count: int, radius: float, segments: int = 10,
		glow := Color.BLACK, see_through := false) -> BeadStrip:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = segments
	sphere.rings = maxi(int(segments / 2.0), 3)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sphere
	mm.instance_count = count
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.45
	if see_through:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = glow
	var strip := BeadStrip.new()
	strip.multimesh = mm
	strip.material_override = mat
	return strip


func count() -> int:
	return multimesh.instance_count


func set_color(i: int, color: Color) -> void:
	multimesh.set_instance_color(i, color)


func place(i: int, at: Vector3, size: float = 1.0, squash: float = 1.0) -> void:
	var basis := Basis.from_scale(Vector3(size, size * squash, size))
	multimesh.set_instance_transform(i, Transform3D(basis, at))


## Stretches ball `i` into a capsule-ish segment from `from` to `to`, with
## its ends tucked into the neighbouring balls, so a row of them reads as
## one continuous stalk rather than a string of beads.
func place_between(i: int, from: Vector3, to: Vector3,
		size: float = 1.0, squash: float = 1.0) -> void:
	var along := to - from
	var length := along.length()
	if length < 0.001:
		place(i, from, size, squash)
		return
	var radius := (multimesh.mesh as SphereMesh).radius
	var z := along / length
	var x := Vector3.UP.cross(z)
	x = x.normalized() if x.length() > 0.001 else Vector3.RIGHT
	var y := z.cross(x)
	var stretch := maxf((length * 0.5) / radius + 0.35 * size, size)
	var basis := Basis(x * size, y * size * squash, z * stretch)
	multimesh.set_instance_transform(i, Transform3D(basis, (from + to) * 0.5))
