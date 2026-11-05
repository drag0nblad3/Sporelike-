class_name RegionNotice
extends RefCounted
## Names the sea region and what grows there whenever the colony swims
## into a new one, so each place feels distinct.

var _sea_id := ""
var _timer := 0.0


func check(at: Vector2, hud: Hud, delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 1.0
	var sea := SeaMap.at(at)
	if sea.id == _sea_id:
		return
	var first := _sea_id == ""
	_sea_id = sea.id
	if not first:
		hud.flash_message("%s: %s" % [sea.title, PlantKind.for_sea(sea.id).title.to_lower()], 3.0)
