class_name StorageChest
extends StaticBody2D

const SLOT_CAPACITY := 12
var items: Dictionary = {}


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactables")
	add_to_group("storage_chests")
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(42, 30)
	collision.shape = rectangle
	add_child(collision)
	queue_redraw()


func get_interaction_prompt() -> String:
	return "E 打开储物箱（%d/%d格）" % [items.size(), SLOT_CAPACITY]


func get_stamina_cost() -> float:
	return 0.0


func interact(game: Node) -> void:
	game.open_storage(self)


func add_item(item_id: String, amount := 1, stack_limit := 99) -> int:
	if not items.has(item_id) and items.size() >= SLOT_CAPACITY: return amount
	var accepted := mini(amount, maxi(stack_limit - int(items.get(item_id, 0)), 0))
	if accepted > 0: items[item_id] = int(items.get(item_id, 0)) + accepted
	return amount - accepted


func remove_item(item_id: String, amount := 1) -> bool:
	if int(items.get(item_id, 0)) < amount: return false
	items[item_id] = int(items[item_id]) - amount
	if int(items[item_id]) <= 0: items.erase(item_id)
	return true


func create_save_data() -> Dictionary:
	return {"x": position.x, "y": position.y, "rotation": rotation, "items": items.duplicate(true)}


func restore_items(saved_items: Dictionary) -> void:
	items = saved_items.duplicate(true)


func _draw() -> void:
	draw_rect(Rect2(-21, -14, 42, 28), Color("#765033"))
	draw_rect(Rect2(-21, -4, 42, 7), Color("#9b7044"))
	draw_rect(Rect2(-4, -2, 8, 10), Color("#d7b85b"))
	draw_line(Vector2(-19, -12), Vector2(19, -12), Color("#b18450"), 3.0)
