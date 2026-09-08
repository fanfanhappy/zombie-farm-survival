class_name SettingsUI
extends Control

signal closed

@onready var fullscreen_button: Button = $Dimmer/Center/Panel/Margin/Content/FullscreenButton
@onready var back_button: Button = $Dimmer/Center/Panel/Margin/Content/BackButton


func _ready() -> void:
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	back_button.pressed.connect(close)
	_update_fullscreen_text()


func open() -> void:
	visible = true
	_update_fullscreen_text()
	back_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	DisplayManager.toggle_fullscreen()
	_update_fullscreen_text()


func _update_fullscreen_text() -> void:
	var is_fullscreen := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	fullscreen_button.text = "切换为窗口模式" if is_fullscreen else "切换为全屏模式"
