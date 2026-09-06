class_name GroundItem
extends Node2D

var item_id := ""
var amount := 1
var display_name := ""


func setup(id: String, quantity := 1, shown_name := "") -> void:
	item_id = id
	amount = quantity
	display_name = shown_name if not shown_name.is_empty() else id
	add_to_group("ground_items")
	add_to_group("interactables")
	queue_redraw()


func get_interaction_prompt() -> String:
	return "E 拾取%s ×%d" % [display_name, amount]


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	var before := amount
	amount = game.inventory.add_item(item_id, amount)
	var picked_up := before - amount
	if picked_up > 0:
		game.show_message("拾取 %s ×%d" % [game.inventory.get_display_name(item_id), picked_up])
	if amount <= 0:
		queue_free()
	else:
		game.show_message("背包已满，地上还剩%d个" % amount)
	queue_redraw()


func create_save_data() -> Dictionary:
	return {"item_id": item_id, "amount": amount, "x": position.x, "y": position.y}


func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color("#d9b76f"))
	draw_rect(Rect2(-8, -8, 16, 16), Color("#6f5134"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-5, 5), str(amount), HORIZONTAL_ALIGNMENT_CENTER, 10, 12, Color.WHITE)
