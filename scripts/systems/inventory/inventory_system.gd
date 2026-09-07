class_name InventorySystem
extends Node

signal inventory_changed

const DEFAULT_ITEM_DATABASE := preload("res://resources/items/item_database.tres")

@export var item_database: ItemDatabase = DEFAULT_ITEM_DATABASE
@export var slot_capacity := 24
@export var hotbar_capacity := 7
var items: Dictionary = {}
var item_catalog: Dictionary = {}
var hotbar_slots: Array[String] = []


func _ready() -> void:
	_load_item_catalog()
	_reset_hotbar()


func initialize(starting_items: Dictionary) -> void:
	items.clear()
	for item_id in starting_items:
		var amount := int(starting_items[item_id])
		if amount > 0:
			items[item_id] = amount
	inventory_changed.emit()


func reset_for_new_game(starting_items: Dictionary) -> void:
	_reset_hotbar()
	initialize(starting_items)


func add_item(item_id: String, amount: int) -> int:
	if amount <= 0:
		return 0
	if not items.has(item_id) and get_used_slots() >= slot_capacity:
		return amount
	var stack_limit := get_stack_limit(item_id)
	var current := get_amount(item_id)
	var accepted := mini(amount, maxi(stack_limit - current, 0))
	if accepted > 0:
		items[item_id] = current + accepted
		inventory_changed.emit()
	return amount - accepted


func can_add_item(item_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if not items.has(item_id) and get_used_slots() >= slot_capacity:
		return false
	return get_amount(item_id) + amount <= get_stack_limit(item_id)


func remove_item(item_id: String, amount: int) -> bool:
	if amount <= 0 or get_amount(item_id) < amount:
		return false
	items[item_id] = get_amount(item_id) - amount
	if items[item_id] <= 0:
		items.erase(item_id)
	inventory_changed.emit()
	return true


func has_item(item_id: String, amount := 1) -> bool:
	return get_amount(item_id) >= amount


func get_amount(item_id: String) -> int:
	return int(items.get(item_id, 0))


func get_used_slots() -> int:
	return items.size()


func get_item_data(item_id: String) -> Dictionary:
	return item_catalog.get(item_id, {"name": item_id, "description": "暂无说明", "stack_limit": 99})


func get_display_name(item_id: String) -> String:
	return get_item_data(item_id).get("name", item_id)


func get_stack_limit(item_id: String) -> int:
	return int(get_item_data(item_id).get("stack_limit", 99))


func get_sorted_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for item_id in items:
		ids.append(item_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(get_item_data(a).get("sort_order", 999)) < int(get_item_data(b).get("sort_order", 999))
	)
	return ids


func assign_hotbar_item(slot_index: int, item_id: String) -> void:
	if slot_index < 0 or slot_index >= hotbar_capacity or not item_catalog.has(item_id):
		return
	# An item appears in only one shortcut slot. Moving it clears the old slot.
	for index in hotbar_slots.size():
		if hotbar_slots[index] == item_id:
			hotbar_slots[index] = ""
	hotbar_slots[slot_index] = item_id
	inventory_changed.emit()


func swap_hotbar_slots(from_index: int, to_index: int) -> void:
	if from_index < 0 or to_index < 0 or from_index >= hotbar_capacity or to_index >= hotbar_capacity:
		return
	var previous := hotbar_slots[to_index]
	hotbar_slots[to_index] = hotbar_slots[from_index]
	hotbar_slots[from_index] = previous
	inventory_changed.emit()


func clear_hotbar_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= hotbar_capacity:
		return
	hotbar_slots[slot_index] = ""
	inventory_changed.emit()


func get_hotbar_item(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= hotbar_capacity:
		return ""
	return hotbar_slots[slot_index]


func create_save_data() -> Dictionary:
	return {"items": items.duplicate(true), "hotbar": hotbar_slots.duplicate()}


func restore_save_data(saved_items: Dictionary) -> void:
	if saved_items.has("items"):
		var migrated_items: Dictionary = saved_items.get("items", {}).duplicate(true)
		_migrate_legacy_items(migrated_items)
		initialize(migrated_items)
		_reset_hotbar()
		var saved_hotbar: Array = saved_items.get("hotbar", [])
		for index in mini(saved_hotbar.size(), hotbar_capacity):
			hotbar_slots[index] = str(saved_hotbar[index])
		inventory_changed.emit()
	else:
		# Compatibility with inventory data saved before customizable hotbar slots.
		var migrated_items := saved_items.duplicate(true)
		_migrate_legacy_items(migrated_items)
		initialize(migrated_items)
		_reset_hotbar()


func _migrate_legacy_items(saved: Dictionary) -> void:
	if saved.has("seed"):
		saved["potato_seed"] = int(saved.get("potato_seed", 0)) + int(saved["seed"])
		saved.erase("seed")
	if saved.has("food"):
		saved["potato"] = int(saved.get("potato", 0)) + int(saved["food"])
		saved.erase("food")


func _reset_hotbar() -> void:
	hotbar_slots.clear()
	for index in hotbar_capacity:
		hotbar_slots.append("")


func _load_item_catalog() -> void:
	item_catalog.clear()
	if item_database == null:
		push_error("InventorySystem 未配置物品数据库")
		return
	item_catalog = item_database.build_catalog()
