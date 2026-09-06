class_name StorageUI
extends CanvasLayer

signal storage_closed

var inventory: InventorySystem
var chest: StorageChest
var overlay: ColorRect
var backpack_grid: GridContainer
var chest_grid: GridContainer
var capacity_label: Label


func _ready() -> void:
	layer = 3
	_build_interface()
	overlay.visible = false


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
	for item_id in inventory.get_sorted_item_ids():
		var button := Button.new()
		button.custom_minimum_size = Vector2(145, 50)
		button.text = "%s ×%d\n点击存入1个" % [inventory.get_display_name(item_id), inventory.get_amount(item_id)]
		button.pressed.connect(_store_one.bind(item_id))
		backpack_grid.add_child(button)
	var chest_ids: Array[String] = []
	for item_id in chest.items: chest_ids.append(str(item_id))
	chest_ids.sort()
	for item_id in chest_ids:
		var button := Button.new()
		button.custom_minimum_size = Vector2(145, 50)
		button.text = "%s ×%d\n点击取出1个" % [inventory.get_display_name(item_id), int(chest.items[item_id])]
		button.pressed.connect(_take_one.bind(item_id))
		chest_grid.add_child(button)


func _store_one(item_id: String) -> void:
	if item_id == "storage_chest": return
	if chest.add_item(item_id, 1, inventory.get_stack_limit(item_id)) > 0: return
	inventory.remove_item(item_id, 1)
	refresh()


func _take_one(item_id: String) -> void:
	if not inventory.can_add_item(item_id, 1): return
	if chest.remove_item(item_id, 1): inventory.add_item(item_id, 1)
	refresh()


func _build_interface() -> void:
	overlay = ColorRect.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.color = Color(0.02, 0.025, 0.023, 0.72); add_child(overlay)
	var panel := PanelContainer.new(); panel.set_anchors_preset(Control.PRESET_CENTER); panel.position = Vector2(-355, -230); panel.size = Vector2(710, 460); overlay.add_child(panel)
	var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", 20); margin.add_theme_constant_override("margin_top", 18); margin.add_theme_constant_override("margin_right", 20); margin.add_theme_constant_override("margin_bottom", 18); panel.add_child(margin)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation", 12); margin.add_child(content)
	var header := HBoxContainer.new(); content.add_child(header)
	var title := Label.new(); title.text = "基地储物箱"; title.add_theme_font_size_override("font_size", 25); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	capacity_label = Label.new(); capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; capacity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(capacity_label)
	var columns := HBoxContainer.new(); columns.size_flags_vertical = Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation", 18); content.add_child(columns)
	var backpack_column := VBoxContainer.new(); backpack_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; columns.add_child(backpack_column)
	var backpack_title := Label.new(); backpack_title.text = "随身背包"; backpack_column.add_child(backpack_title)
	var backpack_scroll := ScrollContainer.new(); backpack_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; backpack_column.add_child(backpack_scroll)
	backpack_grid = GridContainer.new(); backpack_grid.columns = 2; backpack_scroll.add_child(backpack_grid)
	var chest_column := VBoxContainer.new(); chest_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; columns.add_child(chest_column)
	var chest_title := Label.new(); chest_title.text = "箱内物品"; chest_column.add_child(chest_title)
	var chest_scroll := ScrollContainer.new(); chest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; chest_column.add_child(chest_scroll)
	chest_grid = GridContainer.new(); chest_grid.columns = 2; chest_scroll.add_child(chest_grid)
	var close_button := Button.new(); close_button.text = "关闭（Esc）"; close_button.custom_minimum_size.y = 42; close_button.pressed.connect(close_storage); content.add_child(close_button)


func _clear(container: Container) -> void:
	for child in container.get_children(): child.queue_free()
