class_name WaterPump
extends StaticBody2D


func _ready() -> void:
	add_to_group("interactables")


func get_interaction_prompt() -> String:
	return "E 使用取水泵饮水 / 给水壶装水"


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	if game.get_active_tool_type() == "watering_can": game.refill_watering_can()
	else: game.drink_from_water_pump()
