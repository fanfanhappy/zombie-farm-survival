class_name DisplayManager
extends RefCounted


static func toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	if current_mode in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_center_window()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


static func _center_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var window_size := DisplayServer.window_get_size()
	DisplayServer.window_set_position(usable_rect.position + (usable_rect.size - window_size) / 2)
