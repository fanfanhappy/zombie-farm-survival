class_name CraftingStation
extends StaticBody2D

var station_type := "workbench"
var display_name := "工作台"


func setup(type: String) -> void:
	# 生活设施只阻挡玩家，避免无寻路原型中的敌人被家具卡死。
	collision_layer = 2
	collision_mask = 0
	station_type = type
	display_name = "料理台" if type == "kitchen" else "工作台"
	add_to_group("interactables")
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(44, 32)
	collision.shape = rectangle
	add_child(collision)
	queue_redraw()


func get_interaction_prompt() -> String:
	return "E 使用%s" % display_name


func interact(game: Node) -> void:
	game.open_crafting(station_type, display_name)


func _draw() -> void:
	if station_type == "workbench":
		draw_rect(Rect2(-23, -10, 46, 20), Color("#79553b"))
		draw_rect(Rect2(-20, 10, 6, 17), Color("#513d30"))
		draw_rect(Rect2(14, 10, 6, 17), Color("#513d30"))
		draw_rect(Rect2(-9, -17, 18, 8), Color("#9ca1a0"))
	else:
		draw_rect(Rect2(-22, -14, 44, 28), Color("#575a55"))
		draw_circle(Vector2.ZERO, 12.0, Color("#262c2a"))
		draw_circle(Vector2.ZERO, 7.0, Color("#d47b3b"))
