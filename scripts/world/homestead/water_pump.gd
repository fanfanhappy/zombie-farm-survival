class_name WaterPump
extends StaticBody2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("mouse_action_targets")


func get_interaction_prompt() -> String:
	return "左键或E使用取水泵 / 选中水壶时装水"


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	if game.get_active_tool_type() == "watering_can": game.refill_watering_can()
	else: game.drink_from_water_pump()
