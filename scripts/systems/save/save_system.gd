class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://prototype_save.json"
static var load_on_game_start := false


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> bool:
	load_on_game_start = false
	if not has_save(): return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH)) == OK


static func request_start(load_existing_save: bool) -> void:
	load_on_game_start = load_existing_save


static func consume_load_request() -> bool:
	var requested := load_on_game_start
	load_on_game_start = false
	return requested


static func save_game(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
