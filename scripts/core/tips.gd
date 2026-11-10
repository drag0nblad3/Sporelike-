class_name Tips
extends RefCounted
## Remembers which one-time teaching prompts the player has already seen
## (user://tips.json), so each TipBanner tip shows only the first time its
## moment comes up.

const PATH := "user://tips.json"

static var _seen := {}
static var _loaded := false


## True the first time `id` is asked for; marks it seen.
static func take(id: String) -> bool:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
			if parsed is Dictionary:
				_seen = parsed
	if _seen.has(id):
		return false
	_seen[id] = true
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_seen))
	return true


## Forgets every tip, so they all show again.
static func reset() -> void:
	_loaded = true
	_seen = {}
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
