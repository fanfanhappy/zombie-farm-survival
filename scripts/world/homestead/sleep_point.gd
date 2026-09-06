class_name SleepPoint
extends StaticBody2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactables")
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 24)
	collision.shape = rectangle
	add_child(collision)
	queue_redraw()


func get_interaction_prompt() -> String:
	return "E 在床铺休息到第二天"


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	game.try_sleep()


func _draw() -> void:
	draw_rect(Rect2(-20, -12, 40, 24), Color("#725644"))
	draw_rect(Rect2(-17, -9, 34, 18), Color("#d6caa8"))
	draw_rect(Rect2(-15, -7, 13, 8), Color("#eee5ce"))
