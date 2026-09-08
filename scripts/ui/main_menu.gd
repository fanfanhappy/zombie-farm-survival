class_name MainMenu
extends Control

@onready var continue_button: Button = $Center/Menu/Margin/Content/ContinueButton
@onready var save_hint: Label = $Center/Menu/Margin/Content/SaveHint
@onready var settings_ui: SettingsUI = $SettingsUI
var overwrite_confirmation: ConfirmationDialog


func _ready() -> void:
	overwrite_confirmation = ConfirmationDialog.new()
	overwrite_confirmation.title = "开始新游戏"
	overwrite_confirmation.dialog_text = "开始新游戏将删除上一局存档。\n确定要重新开始吗？"
	overwrite_confirmation.ok_button_text = "删除旧存档并开始"
	overwrite_confirmation.cancel_button_text = "取消"
	overwrite_confirmation.confirmed.connect(_confirm_new_game)
	add_child(overwrite_confirmation)
	continue_button.disabled = not SaveSystem.has_save()
	save_hint.text = "检测到存档，可以继续上次进度" if SaveSystem.has_save() else "尚无存档，请开始新游戏"
	$Center/Menu/Margin/Content/NewGameButton.pressed.connect(_start_new_game)
	continue_button.pressed.connect(_continue_game)
	$Center/Menu/Margin/Content/SettingsButton.pressed.connect(settings_ui.open)
	settings_ui.closed.connect($Center/Menu/Margin/Content/SettingsButton.grab_focus)
	$Center/Menu/Margin/Content/QuitButton.pressed.connect(get_tree().quit)
	$Center/Menu/Margin/Content/NewGameButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		DisplayManager.toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _start_new_game() -> void:
	if SaveSystem.has_save():
		overwrite_confirmation.popup_centered(Vector2i(430, 180))
		return
	_confirm_new_game()


func _confirm_new_game() -> void:
	if not SaveSystem.delete_save():
		save_hint.text = "无法删除旧存档，请检查文件权限"
		return
	SaveSystem.request_start(false)
	get_tree().change_scene_to_file("res://scenes/game/game_world.tscn")


func _continue_game() -> void:
	SaveSystem.request_start(true)
	get_tree().change_scene_to_file("res://scenes/game/game_world.tscn")
