class_name BlipSounds
extends Node
## Little sound effects made in code at startup, so the game needs no audio
## files: soft chirps for eating, a sparkle for prize food, a gulp for
## swallowing a cell, a whoosh for the Jet and a thud for a bite.

const RATE := 22050
const VOICES := 4

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	# name: [start Hz, end Hz, seconds, volume, noise share]
	var specs := {
		"eat": [520.0, 880.0, 0.07, 0.35, 0.0],
		"prize": [880.0, 1760.0, 0.25, 0.4, 0.0],
		"swallow": [420.0, 120.0, 0.22, 0.5, 0.1],
		"jet": [300.0, 900.0, 0.18, 0.25, 0.7],
		"hit": [160.0, 60.0, 0.2, 0.6, 0.3],
		"death": [300.0, 50.0, 0.6, 0.5, 0.2],
	}
	for key in specs:
		var s: Array = specs[key]
		_sounds[key] = _tone(float(s[0]), float(s[1]), float(s[2]), float(s[3]), float(s[4]))
	for _i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## Plays a sound; pitch above 1 is higher (the eating streak climbs).
func play(sound: String, pitch: float = 1.0) -> void:
	if not _sounds.has(sound):
		return
	var player := _players[_next]
	_next = (_next + 1) % VOICES
	player.stream = _sounds[sound]
	player.pitch_scale = pitch * randf_range(0.95, 1.05)
	player.play()


static func _tone(f0: float, f1: float, seconds: float, volume: float,
		noise: float) -> AudioStreamWAV:
	var count := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += TAU * lerpf(f0, f1, t) / RATE
		# Quick fade in, then a smooth fall away.
		var env := minf(t * 25.0, 1.0) * (1.0 - t) * (1.0 - t)
		var wave := sin(phase) * (1.0 - noise) + randf_range(-1.0, 1.0) * noise
		data.encode_s16(i * 2, int(clampf(wave * env * volume, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
