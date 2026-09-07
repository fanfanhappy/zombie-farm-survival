class_name StorageUI
extends CanvasLayer

signal storage_closed

const ITEM_ENTRY_SCENE := preload("res://scenes/ui/components/storage_item_entry.tscn")

var inventory: InventorySystem
var chest: StorageChest
@onready var overlay: ColorRect = $Overlay
@onready var backpack_grid: GridContainer = $Overlay/Center/Panel/Margin/Content/Columns/BackpackColumn/BackpackScroll/BackpackGrid
@onready var chest_grid: GridContainer = $Overlay/Center/Panel/Margin/Content/Columns/ChestColumn/ChestScroll/ChestGrid
@onready var capacity_label: Label = $Overlay/Center/Panel/Margin/Content/Header/Capacity
@onready var empty_backpack_label: Label = $Overlay/Center/Panel/Margin/Content/Columns/BackpackColumn/EmptyHint
@onready var empty_chest_label: Label = $Overlay/Center/Panel/Margin/Content/Columns/ChestColumn/EmptyHint


func _ready() -> void:
	overlay.visible = false
	$Overlay/Center/Panel/Margin/Content/Header/CloseButton.pressed.connect(close_storage)
	$Overlay/Center/Panel/Margin/Content/CloseButton.pressed.connect(close_storage)


func setup(inventory_system: InventorySystem) -> void:
	inventory = inventory_system
	inventory.inventory_changed.connect(refresh)


func open_storage(storage_chest: StorageChest) -> void:
	chest = storage_chest
	overlay.visible = true
	refresh()


func close_storage() -> void:
	overlay.visible = false
	chest = null
	storage_closed.emit()


func is_open() -> bool:
	return overlay.visible


func refresh() -> void:
	if inventory == null or not is_instance_valid(chest): return
	_clear(backpack_grid); _clear(chest_grid)
	capacity_label.text = "储物箱 %d/%d 格" % [chest.items.size(), StorageChest.SLOT_CAPACITY]
	var backpack_ids := inventory.get_sorted_item_ids()
	empty_backpack_label.visible = backpack_ids.is_empty()
	for item_id in backpack_ids:
		var entry := ITEM_ENTRY_SCENE.instantiate() as StorageItemEntry
		backpack_grid.add_child(entry)
		entry.configure(inventory.get_display_name(item_id), inventory.get_amount(item_id), "存入 1 个")
		entry.action_requested.connect(_store_one.bind(item_id))
	var chest_ids: Array[String] = []
	for item_id in chest.items: chest_ids.append(str(item_id))
	chest_ids.sort()
	empty_chest_label.visible = chest_ids.is_empty()
	for item_id in chest_ids:
		var entry := ITEM_ENTRY_SCENE.instantiate() as StorageItemEntry
		chest_grid.add_child(entry)
		entry.configure(inventory.get_display_name(item_id), int(chest.items[item_id]), "取出 1 个")
		entry.action_requested.connect(_take_one.bind(item_id))


func _store_one(item_id: String) -> void:
	if item_id == "storage_chest": return
	if chest.add_item(item_id, 1, inventory.get_stack_limit(item_id)) > 0: return
	inventory.remove_item(item_id, 1)
	refresh()


func _take_one(item_id: String) -> void:
	if not inventory.can_add_item(item_id, 1): return
	if chest.remove_item(item_id, 1): inventory.add_item(item_id, 1)
	refresh()


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
