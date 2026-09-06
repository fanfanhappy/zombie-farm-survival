class_name MainMenu
extends Control

@onready var continue_button: Button = $Center/Menu/Margin/Content/ContinueButton
@onready var save_hint: Label = $Center/Menu/Margin/Content/SaveHint


func _ready() -> void:
	continue_button.disabled = not SaveSystem.has_save()
	save_hint.text = "检测到存档，可以继续上次进度" if SaveSystem.has_save() else "尚无存档，请开始新游戏"
	$Center/Menu/Margin/Content/NewGameButton.pressed.connect(_start_new_game)
	continue_button.pressed.connect(_continue_game)
	$Center/Menu/Margin/Content/QuitButton.pressed.connect(get_tree().quit)
	$Center/Menu/Margin/Content/NewGameButton.grab_focus()


func _start_new_game() -> void:
	SaveSystem.request_start(false)
	get_tree().change_scene_to_file("res://scenes/game/game_world.tscn")


func _continue_game() -> void:
	SaveSystem.request_start(true)
	get_tree().change_scene_to_file("res://scenes/game/game_world.tscn")
