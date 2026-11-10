class_name VillageSite
extends RefCounted
## Picks where a stage 4 test village stands: the flattest dry spot within
## a short walk of the middle of the valley.


static func pick() -> Vector3:
	var best := Vector3(5.0, 0.0, 4.0)
	var best_score := INF
	for ring in 5:
		for k in 8:
			var a := TAU * k / 8.0 + ring * 0.4
			var x := sin(a) * ring * 14.0
			var z := cos(a) * ring * 14.0
			var slope := 0.0
			for d: Vector2 in [Vector2(8, 0), Vector2(-8, 0), Vector2(0, 8), Vector2(0, -8)]:
				slope += absf(LandHeight.at(x + d.x, z + d.y) - LandHeight.at(x, z))
			var score := slope + LandRiver.wet(x, z) * 100.0 + LandZone.crag(x, z) * 20.0
			if score < best_score:
				best_score = score
				best = Vector3(x, LandHeight.at(x, z), z)
	return best
