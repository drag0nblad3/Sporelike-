class_name AnimalParts
extends RefCounted
## Shared meshes and materials for drawing stage 3 animals: one ball,
## one cone and one rod reused by every part, and a plain lit material per colour.

static var _ball: SphereMesh
static var _cone: CylinderMesh
static var _rod: CylinderMesh


static func ball() -> SphereMesh:
	if _ball == null:
		_ball = SphereMesh.new()
		_ball.radius = 1.0
		_ball.height = 2.0
		_ball.radial_segments = 14
		_ball.rings = 8
	return _ball


## Base radius 1 at -0.5, tip at +0.5 along y.
static func cone() -> CylinderMesh:
	if _cone == null:
		_cone = CylinderMesh.new()
		_cone.top_radius = 0.0
		_cone.bottom_radius = 1.0
		_cone.height = 1.0
		_cone.radial_segments = 8
		_cone.rings = 1
	return _cone


## Radius 1, from -0.5 to +0.5 along y.
static func rod() -> CylinderMesh:
	if _rod == null:
		_rod = CylinderMesh.new()
		_rod.top_radius = 1.0
		_rod.bottom_radius = 1.0
		_rod.height = 1.0
		_rod.radial_segments = 6
		_rod.rings = 1
	return _rod


static func material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.55
	return mat


static func node(mesh: Mesh, mat: Material, parent: Node) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat
	parent.add_child(n)
	return n


## A transform whose y axis runs from `a` to `b`, `width` wide: places the
## cone (or a ball) between two points.
static func span(a: Vector3, b: Vector3, width: float) -> Transform3D:
	var along := b - a
	var length := maxf(along.length(), 0.001)
	var y := along / length
	var other := Vector3.FORWARD if absf(y.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var x := y.cross(other).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x * width, y * length, z * width), (a + b) * 0.5)
