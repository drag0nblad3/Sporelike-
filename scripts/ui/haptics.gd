class_name Haptics
extends RefCounted
## Short phone vibrations for game moments (eating, bites, jets, death).
## Does nothing off mobile. The Android export asks for the vibrate
## permission (export_presets.cfg).


static func pulse(ms: int, strength: float = -1.0) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms, strength)
