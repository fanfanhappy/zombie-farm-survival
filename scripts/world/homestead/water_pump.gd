class_name WaterPump
extends StaticBody2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactables")
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(28, 38)
	collision.shape = rectangle
	add_child(collision)
	queue_redraw()


func get_interaction_prompt() -> String:
	return "E 使用取水泵饮水"


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	game.drink_from_water_pump()


func _draw() -> void:
	draw_rect(Rect2(-11, -18, 22, 36), Color("#65777a"))
	draw_rect(Rect2(-15, 13, 30, 7), Color("#414d4f"))
	draw_rect(Rect2(7, -13, 18, 6), Color("#82979a"))
	draw_line(Vector2(-5, -18), Vector2(-5, -29), Color("#8da1a3"), 5.0)
	draw_line(Vector2(-5, -28), Vector2(12, -28), Color("#8da1a3"), 5.0)
	draw_circle(Vector2(25, 0), 3.0, Color("#69b6d0"))
