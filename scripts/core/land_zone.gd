class_name LandZone
extends RefCounted
## Which kind of country a stage 3 spot belongs to, as 0 to 1 weights that
## blend smoothly at the edges: crags (jagged rock peaks), mesas (flat
## tops ringed by cliffs) and forest. Rolling hills fill the gaps between.
## Nothing rises within about 15 units of the start, so a walker begins
## on open ground.


static func crag(x: float, z: float) -> float:
	LandNoise.ensure()
	return smoothstep(0.12, 0.3, LandNoise.zones.get_noise_2d(x, z)) * _away(x, z)


static func mesa(x: float, z: float) -> float:
	LandNoise.ensure()
	return smoothstep(0.12, 0.3, -LandNoise.zones.get_noise_2d(x, z)) * _away(x, z)


## Forest grows on gentler country, never on the crags.
static func forest(x: float, z: float) -> float:
	LandNoise.ensure()
	var w := smoothstep(0.02, 0.2, LandNoise.woods.get_noise_2d(x, z))
	return w * (1.0 - crag(x, z))


static func _away(x: float, z: float) -> float:
	return smoothstep(14.0, 32.0, Vector2(x, z).length())
