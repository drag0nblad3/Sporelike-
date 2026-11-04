class_name SeaMap
extends RefCounted
## Splits the endless sea into big regions, each one kind of Sea, from the
## world seed alone, so a place always comes back the same. Regions are
## cells of a Voronoi noise with wavy edges, a few chunks across. The run's
## starting sea always covers the center, where the subspecies arrives.

## Region spacing: about 1 / FREQUENCY units, roughly five chunks.
const FREQUENCY := 0.005
const EDGE_WARP := 35.0

## The map of the game in progress, or null (title screen, colony lab).
static var active: SeaMap

var _noise := FastNoiseLite.new()
var _seas: Array[Sea] = []
## Rotates which sea each region value means, so the center region is
## always the starting sea.
var _shift := 0


func _init(world_seed: int, start_id: String) -> void:
	_noise.seed = world_seed + 7
	_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_noise.frequency = FREQUENCY
	_noise.domain_warp_enabled = true
	_noise.domain_warp_amplitude = EDGE_WARP
	_noise.domain_warp_frequency = FREQUENCY * 2.0
	var ids := Sea.ids()
	for id in ids:
		_seas.append(Sea.of(id))
	_shift = posmod(maxi(ids.find(start_id), 0) - _raw_index(Vector2.ZERO), ids.size())


## The sea at this point of the game in progress; the starting sea when no
## game is running.
static func at(p: Vector2) -> Sea:
	return active.sea_at(p) if active else Sea.current()


func sea_at(p: Vector2) -> Sea:
	return _seas[(_raw_index(p) + _shift) % _seas.size()]


func _raw_index(p: Vector2) -> int:
	var v := _noise.get_noise_2d(p.x, p.y)
	return clampi(floori((v + 1.0) * 0.5 * _seas.size()), 0, _seas.size() - 1)
