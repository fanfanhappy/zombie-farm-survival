class_name SettingsUI
extends Control

signal closed

@onready var fullscreen_button: Button = $Dimmer/Center/Panel/Margin/Content/FullscreenButton
@onready var back_button: Button = $Dimmer/Center/Panel/Margin/Content/BackButton
@onready var master_slider: HSlider = $Dimmer/Center/Panel/Margin/Content/AudioGrid/MasterSlider
@onready var music_slider: HSlider = $Dimmer/Center/Panel/Margin/Content/AudioGrid/MusicSlider
@onready var sfx_slider: HSlider = $Dimmer/Center/Panel/Margin/Content/AudioGrid/SFXSlider
@onready var audio_manager: Node = get_node("/root/AudioManager")


func _ready() -> void:
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	back_button.pressed.connect(close)
	_setup_volume_slider(master_slider, &"Master")
	_setup_volume_slider(music_slider, &"Music")
	_setup_volume_slider(sfx_slider, &"SFX")
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


func _setup_volume_slider(slider: HSlider, bus_name: StringName) -> void:
	slider.set_meta("bus_name", bus_name)
	slider.value = audio_manager.get_bus_volume_percent(bus_name) * 100.0
	slider.value_changed.connect(_on_volume_changed.bind(slider))
	_update_volume_label(slider)


func _on_volume_changed(value: float, slider: HSlider) -> void:
	audio_manager.set_bus_volume_percent(slider.get_meta("bus_name"), value / 100.0)
	_update_volume_label(slider)


func _update_volume_label(slider: HSlider) -> void:
	var value_label := slider.get_parent().get_node(slider.name.trim_suffix("Slider") + "Value") as Label
	value_label.text = "%d%%" % roundi(slider.value)
