class_name GroundItem
extends Node2D

var item_id := ""
var amount := 1
var display_name := ""
@onready var item_label: Label = $ItemLabel
@onready var amount_label: Label = $AmountLabel


func setup(id: String, quantity := 1, shown_name := "") -> void:
	item_id = id
	amount = quantity
	display_name = shown_name if not shown_name.is_empty() else id
	add_to_group("ground_items")
	add_to_group("interactables")
	_update_visual()


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
	_update_visual()


func create_save_data() -> Dictionary:
	return {"item_id": item_id, "amount": amount, "x": position.x, "y": position.y}


func _update_visual() -> void:
	if not is_instance_valid(item_label):
		return
	item_label.text = display_name
	amount_label.text = str(amount)
