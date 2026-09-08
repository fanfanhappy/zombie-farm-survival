class_name SleepPoint
extends StaticBody2D


func _ready() -> void:
	add_to_group("interactables")


func get_interaction_prompt() -> String:
	return "E 在床铺休息到第二天"


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	game.try_sleep()
