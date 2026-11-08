class_name LandNoise
extends RefCounted
## The noise fields behind the stage 3 land, made once per seed and shared
## by LandHeight, LandZone and LandRiver so every lookup agrees.

static var hills: FastNoiseLite
static var bumps: FastNoiseLite
## Where crags (positive) and mesas (negative) sit.
static var zones: FastNoiseLite
## Where forests grow.
static var woods: FastNoiseLite
## Sharp ridges for crags.
static var ridges: FastNoiseLite
## The tiers of mesa cliffs.
static var tiers: FastNoiseLite
## River lines run where this crosses zero.
static var rivers: FastNoiseLite


static func ensure() -> void:
	if hills == null:
		make(1)


static func make(value: int) -> void:
	var s := LandHeight.SCALE
	hills = _noise(value, 0.012 / s, 3)
	bumps = _noise(value + 1, 0.09, 5)
	zones = _noise(value + 2, 0.008 / s, 2)
	woods = _noise(value + 3, 0.018 / s, 3)
	ridges = _noise(value + 4, 0.035 / s, 3)
	tiers = _noise(value + 5, 0.022 / s, 2)
	rivers = _noise(value + 6, 0.0055 / s, 2)


static func _noise(value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = value
	n.frequency = frequency
	n.fractal_octaves = octaves
	return n
