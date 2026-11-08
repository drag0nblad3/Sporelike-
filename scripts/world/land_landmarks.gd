class_name LandLandmarks
extends Node3D
## Stage 3's three landmarks, found in the land itself when it is made: a
## river ford (the nearest deep river), a crag summit (the highest crag
## peak near the start) and the forest heart (the thickest forest). Each
## has a tall glowing beacon until the animal reaches it, which unlocks a
## LandUnlocks part family (reached).

signal reached(id: String)

## Searched out to this far from the start, every STEP units.
const SEARCH := 200.0
const STEP := 5.0
## Counts as reached this close (flat distance).
const REACH := 9.0
const COLORS := {"ford": Color(0.35, 0.7, 1.0), "summit": Color(1.0, 0.85, 0.4),
	"forest": Color(0.5, 1.0, 0.45)}
const BEAMS := {"ford": "blue", "summit": "gold", "forest": "green"}

## Landmark id -> its spot on the ground.
var spots := {}
var _beacons := {}


static func title(id: String) -> String:
	match id:
		LandUnlocks.FORD:
			return "river ford"
		LandUnlocks.SUMMIT:
			return "crag summit"
	return "forest heart"


func _ready() -> void:
	_find()
	for id: String in spots:
		var beacon := _beacon(COLORS[id])
		beacon.position = spots[id]
		add_child(beacon)
		_beacons[id] = beacon


## Checks the animal against every landmark not yet reached.
func check(at: Vector3, unlocks: LandUnlocks) -> void:
	for id: String in spots:
		if id in unlocks.reached:
			continue
		var spot: Vector3 = spots[id]
		if Vector2(at.x - spot.x, at.z - spot.z).length() < REACH:
			unlocks.unlock(id)
			var beacon: Node3D = _beacons[id]
			beacon.visible = false
			reached.emit(id)


## "crag summit (gold beam) 140 m" for the nearest landmark not yet reached.
func nearest_text(at: Vector3, unlocks: LandUnlocks) -> String:
	var best := ""
	var best_d := INF
	for id: String in spots:
		var spot: Vector3 = spots[id]
		var d := Vector2(at.x - spot.x, at.z - spot.z).length()
		if not id in unlocks.reached and d < best_d:
			best = id
			best_d = d
	if best == "":
		return ""
	return "%s (%s beam) %d m" % [title(best), BEAMS[best], roundi(best_d)]


func _find() -> void:
	var ford := Vector3.INF
	var summit := Vector3.ZERO
	var summit_h := -INF
	var woods := Vector3.ZERO
	var woods_w := 0.0
	var steps := int(SEARCH / STEP)
	for i in range(-steps, steps + 1):
		for j in range(-steps, steps + 1):
			var x := i * STEP
			var z := j * STEP
			var d := Vector2(x, z).length()
			if d > SEARCH or d < 30.0:
				continue
			if LandRiver.wet(x, z) > 0.95 and d < Vector2(ford.x, ford.z).length():
				ford = Vector3(x, LandRiver.surface(x, z), z)
			if LandZone.crag(x, z) > 0.6:
				var h := LandHeight.at(x, z) - d * 0.05
				if h > summit_h:
					summit_h = h
					summit = Vector3(x, LandHeight.at(x, z), z)
			var w := LandZone.forest(x, z) - d * 0.001
			if w > woods_w:
				woods_w = w
				woods = Vector3(x, LandHeight.at(x, z), z)
	if ford != Vector3.INF:
		spots[LandUnlocks.FORD] = ford
	if summit_h > -INF:
		spots[LandUnlocks.SUMMIT] = summit
	if woods_w > 0.3:
		spots[LandUnlocks.FOREST] = woods


func _beacon(tint: Color) -> Node3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(tint, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.set("disable_fog", true)
	var beam := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.6
	mesh.bottom_radius = 1.2
	mesh.height = 60.0
	mesh.radial_segments = 8
	mesh.rings = 1
	mesh.material = mat
	beam.mesh = mesh
	beam.position.y = 30.0
	var node := Node3D.new()
	node.add_child(beam)
	return node

