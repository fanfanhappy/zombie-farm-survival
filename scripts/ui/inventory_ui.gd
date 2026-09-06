class_name InventoryUI
extends CanvasLayer

signal item_use_requested(item_id: String)
signal item_drop_requested(item_id: String)
signal inventory_closed


class DraggableItemSlot extends Button:
	var inventory_ui: InventoryUI
	var slot_kind := "inventory"
	var slot_index := -1
	var item_id := ""

	func configure(ui: InventoryUI, kind: String, index: int, id: String) -> void:
		inventory_ui = ui
		slot_kind = kind
		slot_index = index
		item_id = id

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if item_id.is_empty():
			return null
		var preview := PanelContainer.new()
		var label := Label.new()
		label.text = "%s ×%d" % [inventory_ui.inventory.get_display_name(item_id), inventory_ui.inventory.get_amount(item_id)]
		label.add_theme_constant_override("outline_size", 4)
		preview.add_child(label)
		set_drag_preview(preview)
		return {"source": slot_kind, "slot_index": slot_index, "item_id": item_id}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return slot_kind == "hotbar" and data is Dictionary and data.has("item_id")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		inventory_ui.handle_hotbar_drop(slot_index, data)

	func _gui_input(event: InputEvent) -> void:
		if slot_kind == "hotbar" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			inventory_ui.clear_hotbar_slot(slot_index)
			accept_event()


@onready var hotbar: HBoxContainer = $HotbarPanel/Margin/Hotbar
@onready var backpack_panel: PanelContainer = $BackpackPanel
@onready var capacity_label: Label = $BackpackPanel/Margin/Content/Header/Capacity
@onready var item_grid: GridContainer = $BackpackPanel/Margin/Content/ItemGrid
@onready var detail_name: Label = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/ItemName
@onready var detail_description: Label = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/Description
@onready var use_button: Button = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/UseButton
@onready var drop_button: Button = $BackpackPanel/Margin/Content/DetailPanel/Margin/Detail/DropButton

var inventory: InventorySystem
var selected_item_id := ""
var selected_hotbar_index := -1


func setup(inventory_system: InventorySystem) -> void:
	inventory = inventory_system
	inventory.inventory_changed.connect(refresh)
	$BackpackPanel/Margin/Content/Header/CloseButton.pressed.connect(close_backpack)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	refresh()


func toggle_backpack() -> void:
	if backpack_panel.visible: close_backpack()
	else: open_backpack()


func open_backpack() -> void:
	backpack_panel.visible = true
	refresh()


func close_backpack() -> void:
	backpack_panel.visible = false
	inventory_closed.emit()


func is_backpack_open() -> bool:
	return backpack_panel.visible


func refresh() -> void:
	if inventory == null: return
	_refresh_hotbar()
	_refresh_backpack()


func handle_hotbar_drop(target_index: int, data: Dictionary) -> void:
	if data.get("source", "") == "hotbar":
		inventory.swap_hotbar_slots(int(data.get("slot_index", -1)), target_index)
	else:
		inventory.assign_hotbar_item(target_index, str(data.get("item_id", "")))
	selected_hotbar_index = target_index


func clear_hotbar_slot(slot_index: int) -> void:
	inventory.clear_hotbar_slot(slot_index)
	if selected_hotbar_index == slot_index: selected_hotbar_index = -1


func activate_hotbar_slot(slot_index: int) -> bool:
	var item_id := inventory.get_hotbar_item(slot_index)
	selected_hotbar_index = slot_index
	refresh()
	if item_id.is_empty():
		return false
	item_use_requested.emit(item_id)
	return true


func get_selected_hotbar_item_id() -> String:
	if selected_hotbar_index < 0: return ""
	return inventory.get_hotbar_item(selected_hotbar_index)


func _refresh_hotbar() -> void:
	_clear_container(hotbar)
	for index in inventory.hotbar_capacity:
		var item_id := inventory.get_hotbar_item(index)
		var slot := DraggableItemSlot.new()
		slot.custom_minimum_size = Vector2(104, 50)
		slot.configure(self, "hotbar", index, item_id)
		if item_id.is_empty():
			slot.text = "%s%d\n空槽位" % ["▶" if selected_hotbar_index == index else "", index + 1]
			slot.tooltip_text = "从背包拖动物品到这里"
		else:
			slot.text = "%s%d　%s\n×%d" % ["▶" if selected_hotbar_index == index else "", index + 1, inventory.get_display_name(item_id), inventory.get_amount(item_id)]
			slot.tooltip_text = "%s\n右键清空快捷槽" % inventory.get_item_data(item_id).get("description", "")
			slot.pressed.connect(_on_hotbar_slot_pressed.bind(item_id))
		hotbar.add_child(slot)


func _refresh_backpack() -> void:
	capacity_label.text = "%d / %d 格" % [inventory.get_used_slots(), inventory.slot_capacity]
	_clear_container(item_grid)
	for item_id in inventory.get_sorted_item_ids():
		var data := inventory.get_item_data(item_id)
		var slot := DraggableItemSlot.new()
		slot.custom_minimum_size = Vector2(122, 70)
		slot.text = "%s\n×%d / %d" % [data.get("name", item_id), inventory.get_amount(item_id), inventory.get_stack_limit(item_id)]
		slot.tooltip_text = "%s\n拖动到下方快捷栏" % data.get("description", "")
		slot.configure(self, "inventory", -1, item_id)
		slot.pressed.connect(_select_item.bind(item_id))
		item_grid.add_child(slot)
	if not selected_item_id.is_empty() and inventory.get_amount(selected_item_id) <= 0:
		selected_item_id = ""
	_update_detail()


func _select_item(item_id: String) -> void:
	selected_item_id = item_id
	_update_detail()


func _on_hotbar_slot_pressed(item_id: String) -> void:
	if backpack_panel.visible:
		_select_item(item_id)
	else:
		for index in inventory.hotbar_capacity:
			if inventory.get_hotbar_item(index) == item_id:
				activate_hotbar_slot(index)
				return


func _update_detail() -> void:
	if selected_item_id.is_empty():
		detail_name.text = "选择一个物品"
		detail_description.text = "点击物品查看说明，按住并拖动可放入快捷栏。"
		use_button.visible = false
		drop_button.visible = false
		return
	var data := inventory.get_item_data(selected_item_id)
	detail_name.text = "%s　×%d" % [data.get("name", selected_item_id), inventory.get_amount(selected_item_id)]
	detail_description.text = data.get("description", "暂无说明")
	use_button.visible = bool(data.get("usable", false))
	drop_button.visible = inventory.get_amount(selected_item_id) > 0
	match data.get("category", ""):
		"weapon": use_button.text = "装备"
		"tool": use_button.text = "放入快捷栏后选择"
		"placeable": use_button.text = "进入放置模式"
		"seed": use_button.text = "选中种子"
		_: use_button.text = "使用"


func _on_use_pressed() -> void:
	if not selected_item_id.is_empty(): item_use_requested.emit(selected_item_id)


func _on_drop_pressed() -> void:
	if not selected_item_id.is_empty(): item_drop_requested.emit(selected_item_id)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
