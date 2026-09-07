class_name CraftingStation
extends StaticBody2D

@export_enum("workbench", "kitchen") var station_type := "workbench"
@export var display_name := "工作台"


func _ready() -> void:
	# 外观和碰撞由对应的设施场景维护，脚本只负责交互行为。
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactables")


func setup(type: String) -> void:
	station_type = type
	display_name = "料理台" if type == "kitchen" else "工作台"


func get_interaction_prompt() -> String:
	return "E 使用%s" % display_name


func interact(game: Node) -> void:
	game.open_crafting(station_type, display_name)
