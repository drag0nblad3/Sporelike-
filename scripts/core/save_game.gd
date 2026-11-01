class_name SaveGame
extends RefCounted
## Reads and writes the single save file. The contents are a plain
## Dictionary built by GameSaver; this class only handles the file.

const PATH := "user://save.json"
const VERSION := 1


static func exists() -> bool:
	return not load_data().is_empty()


static func write(data: Dictionary) -> void:
	data["version"] = VERSION
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))


## The saved Dictionary, or an empty one if there is no usable save.
static func load_data() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != VERSION:
		return {}
	return data


static func delete() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
