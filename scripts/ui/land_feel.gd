class_name LandFeel
extends Node
## Makes moments on the land felt (stages 3 and 4): a sound, a buzz of the
## phone and, when given a line, pop-up text over the spot. Each kind of
## cue has a shortest gap so a held bite ticks instead of droning.

## kind: [sound, pitch, buzz ms, buzz strength, shortest gap in seconds]
const CUES := {
	"pick": ["eat", 1.2, 10, 0.3, 0.0],
	"deliver": ["eat", 0.8, 20, 0.4, 0.0],
	"egg": ["chime", 1.0, 60, 0.7, 0.0],
	"bite": ["hit", 1.4, 18, 0.5, 0.35],
	"kill": ["swallow", 1.0, 80, 0.8, 0.0],
	"hurt": ["hit", 0.8, 140, 1.0, 0.5],
	"alarm": ["horn", 1.0, 200, 1.0, 2.0],
	"call": ["horn", 1.7, 30, 0.5, 0.0],
	"learn": ["prize", 0.8, 80, 0.7, 0.0],
	"build": ["knock", 1.0, 40, 0.6, 0.0],
	"born": ["chime", 1.3, 40, 0.5, 0.3],
	"landmark": ["prize", 1.0, 120, 0.8, 0.0],
	"hatch": ["chime", 0.8, 90, 0.8, 0.0],
}
const GOOD := Color(0.6, 1.0, 0.7)
const BAD := Color(1.0, 0.6, 0.5)
const GOLD := Color(1.0, 0.85, 0.3)

## Where pop-up text goes (the parent when that is a Node3D).
var pops: Node3D
var _sounds := BlipSounds.new()
var _last := {}


func _ready() -> void:
	add_child(_sounds)
	if pops == null and get_parent() is Node3D:
		pops = get_parent()


## Plays the cue `kind`; with a line, pops it up over `at`.
func cue(kind: String, at: Vector3 = Vector3.INF, line: String = "",
		colour: Color = GOOD) -> void:
	if not CUES.has(kind):
		return
	var spec: Array = CUES[kind]
	var now := Time.get_ticks_msec() / 1000.0
	var last: float = _last.get(kind, -100.0)
	if now - last < float(spec[4]):
		return
	_last[kind] = now
	_sounds.play(str(spec[0]), float(spec[1]))
	Haptics.pulse(int(spec[2]), float(spec[3]))
	if line != "" and at != Vector3.INF and pops != null:
		PopText.show_at(pops, at + Vector3.UP * 1.5, line, colour)
